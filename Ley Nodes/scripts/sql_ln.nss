const string LN_DB = "leynodes";

void LnCreateTables()
{
    sqlquery q;

    q = SqlPrepareQueryCampaign(LN_DB,
        "CREATE TABLE IF NOT EXISTS ln_nodes ("
        "  tag TEXT PRIMARY KEY, "
        "  name TEXT NOT NULL DEFAULT '', "
        "  node_type INTEGER NOT NULL DEFAULT 1, "
        "  charge INTEGER NOT NULL DEFAULT 100, "
        "  last_regen_at INTEGER NOT NULL DEFAULT (strftime('%s','now'))"
        ")");
    SqlStep(q);

    q = SqlPrepareQueryCampaign(LN_DB,
        "CREATE TABLE IF NOT EXISTS ln_attunements ("
        "  pc_uuid TEXT NOT NULL, "
        "  node_tag TEXT NOT NULL, "
        "  attuned_at INTEGER NOT NULL DEFAULT (strftime('%s','now')), "
        "  PRIMARY KEY (pc_uuid, node_tag)"
        ")");
    SqlStep(q);
}

void LnRegisterNode(string sTag, string sName, int nType)
{
    sqlquery q = SqlPrepareQueryCampaign(LN_DB,
        "INSERT OR IGNORE INTO ln_nodes (tag, name, node_type, charge, last_regen_at) "
        "VALUES (@tag, @name, @type, 100, strftime('%s','now'))");
    SqlBindString(q, "@tag",  sTag);
    SqlBindString(q, "@name", sName);
    SqlBindInt   (q, "@type", nType);
    SqlStep(q);
}

// Recalculates charge from elapsed time and persists; returns current charge.
int LnGetUpdatedCharge(string sTag, int nRegenPerMin, int nMax)
{
    sqlquery q = SqlPrepareQueryCampaign(LN_DB,
        "SELECT charge, CAST((strftime('%s','now') - last_regen_at) / 60 AS INTEGER) "
        "FROM ln_nodes WHERE tag = @tag");
    SqlBindString(q, "@tag", sTag);
    if(!SqlStep(q)) return 0;

    int nCharge = SqlGetInt(q, 0);
    int nMins   = SqlGetInt(q, 1);
    if(nMins <= 0) return nCharge;

    int nNew = nCharge + nMins * nRegenPerMin;
    if(nNew > nMax) nNew = nMax;

    // Advance last_regen_at by whole elapsed minutes so sub-minute progress persists.
    sqlquery qUpd = SqlPrepareQueryCampaign(LN_DB,
        "UPDATE ln_nodes "
        "SET charge = @charge, last_regen_at = last_regen_at + @mins * 60 "
        "WHERE tag = @tag");
    SqlBindInt   (qUpd, "@charge", nNew);
    SqlBindInt   (qUpd, "@mins",   nMins);
    SqlBindString(qUpd, "@tag",    sTag);
    SqlStep(qUpd);

    return nNew;
}

void LnDrainCharge(string sTag, int nAmount)
{
    sqlquery q = SqlPrepareQueryCampaign(LN_DB,
        "UPDATE ln_nodes SET charge = MAX(0, charge - @amount) WHERE tag = @tag");
    SqlBindInt   (q, "@amount", nAmount);
    SqlBindString(q, "@tag",    sTag);
    SqlStep(q);
}

int LnGetNodeType(string sTag)
{
    sqlquery q = SqlPrepareQueryCampaign(LN_DB,
        "SELECT node_type FROM ln_nodes WHERE tag = @tag");
    SqlBindString(q, "@tag", sTag);
    if(SqlStep(q)) return SqlGetInt(q, 0);
    return 0;
}

string LnGetNodeName(string sTag)
{
    sqlquery q = SqlPrepareQueryCampaign(LN_DB,
        "SELECT name FROM ln_nodes WHERE tag = @tag");
    SqlBindString(q, "@tag", sTag);
    if(SqlStep(q)) return SqlGetString(q, 0);
    return sTag;
}

void LnAddAttunement(object oPC, string sTag)
{
    sqlquery q = SqlPrepareQueryCampaign(LN_DB,
        "INSERT OR IGNORE INTO ln_attunements (pc_uuid, node_tag) VALUES (@uuid, @tag)");
    SqlBindString(q, "@uuid", GetObjectUUID(oPC));
    SqlBindString(q, "@tag",  sTag);
    SqlStep(q);
}

void LnRemoveAttunement(object oPC, string sTag)
{
    sqlquery q = SqlPrepareQueryCampaign(LN_DB,
        "DELETE FROM ln_attunements WHERE pc_uuid = @uuid AND node_tag = @tag");
    SqlBindString(q, "@uuid", GetObjectUUID(oPC));
    SqlBindString(q, "@tag",  sTag);
    SqlStep(q);
}

int LnIsAttuned(object oPC, string sTag)
{
    sqlquery q = SqlPrepareQueryCampaign(LN_DB,
        "SELECT 1 FROM ln_attunements WHERE pc_uuid = @uuid AND node_tag = @tag");
    SqlBindString(q, "@uuid", GetObjectUUID(oPC));
    SqlBindString(q, "@tag",  sTag);
    return SqlStep(q) ? 1 : 0;
}

int LnGetAttunementCount(object oPC)
{
    sqlquery q = SqlPrepareQueryCampaign(LN_DB,
        "SELECT COUNT(*) FROM ln_attunements WHERE pc_uuid = @uuid");
    SqlBindString(q, "@uuid", GetObjectUUID(oPC));
    if(SqlStep(q)) return SqlGetInt(q, 0);
    return 0;
}

// Returns JsonArray of {tag, name, node_type, charge} for all of oPC's attunements.
json LnGetAttunements(object oPC)
{
    json jRows = JsonArray();
    sqlquery q = SqlPrepareQueryCampaign(LN_DB,
        "SELECT a.node_tag, n.name, n.node_type, n.charge "
        "FROM ln_attunements a "
        "JOIN ln_nodes n ON n.tag = a.node_tag "
        "WHERE a.pc_uuid = @uuid "
        "ORDER BY a.attuned_at ASC");
    SqlBindString(q, "@uuid", GetObjectUUID(oPC));
    while(SqlStep(q))
    {
        json jRow = JsonObject();
        jRow = JsonObjectSet(jRow, "tag",    JsonString(SqlGetString(q, 0)));
        jRow = JsonObjectSet(jRow, "name",   JsonString(SqlGetString(q, 1)));
        jRow = JsonObjectSet(jRow, "type",   JsonInt   (SqlGetInt   (q, 2)));
        jRow = JsonObjectSet(jRow, "charge", JsonInt   (SqlGetInt   (q, 3)));
        jRows = JsonArrayInsert(jRows, jRow);
    }
    return jRows;
}
