// sql_nec.nss — Necromancy: SQL schema and data-access layer
// Campaign DB name: "nec"

void NecCreateTables()
{
    sqlquery q;

    q = SqlPrepareQueryCampaign("nec",
        "CREATE TABLE IF NOT EXISTS nec_servants ("
        "  id           INTEGER PRIMARY KEY AUTOINCREMENT,"
        "  owner_uuid   TEXT    NOT NULL,"
        "  servant_tag  TEXT    NOT NULL,"
        "  servant_name TEXT    NOT NULL DEFAULT 'Sługa',"
        "  servant_type INTEGER NOT NULL DEFAULT 0,"
        "  hp_current   INTEGER NOT NULL DEFAULT 10,"
        "  hp_max       INTEGER NOT NULL DEFAULT 10,"
        "  essence      INTEGER NOT NULL DEFAULT 100,"
        "  raised_at    INTEGER NOT NULL DEFAULT 0,"
        "  is_active    INTEGER NOT NULL DEFAULT 1"
        ")");
    SqlStep(q);

    q = SqlPrepareQueryCampaign("nec",
        "CREATE TABLE IF NOT EXISTS nec_essence ("
        "  owner_uuid   TEXT    PRIMARY KEY,"
        "  essence      INTEGER NOT NULL DEFAULT 0,"
        "  total_souls  INTEGER NOT NULL DEFAULT 0"
        ")");
    SqlStep(q);
}

void NecRegisterPC(object oPC)
{
    sqlquery q = SqlPrepareQueryCampaign("nec",
        "INSERT OR IGNORE INTO nec_essence (owner_uuid, essence, total_souls) "
        "VALUES (@uuid, 0, 0)");
    SqlBindString(q, "@uuid", GetObjectUUID(oPC));
    SqlStep(q);
}

int NecGetEssencePool(object oPC)
{
    sqlquery q = SqlPrepareQueryCampaign("nec",
        "SELECT essence FROM nec_essence WHERE owner_uuid = @uuid");
    SqlBindString(q, "@uuid", GetObjectUUID(oPC));
    if (SqlStep(q)) return SqlGetInt(q, 0);
    return 0;
}

void NecAddEssenceToPool(object oPC, int nAmount)
{
    sqlquery q = SqlPrepareQueryCampaign("nec",
        "UPDATE nec_essence "
        "SET essence = MIN(essence + @amt, 9999), total_souls = total_souls + 1 "
        "WHERE owner_uuid = @uuid");
    SqlBindInt(q,    "@amt",  nAmount);
    SqlBindString(q, "@uuid", GetObjectUUID(oPC));
    SqlStep(q);
}

// Returns 1 if enough essence was available and was spent, 0 otherwise.
int NecSpendEssenceFromPool(object oPC, int nAmount)
{
    sqlquery q = SqlPrepareQueryCampaign("nec",
        "UPDATE nec_essence "
        "SET essence = essence - @amt "
        "WHERE owner_uuid = @uuid AND essence >= @amt");
    SqlBindInt(q,    "@amt",  nAmount);
    SqlBindString(q, "@uuid", GetObjectUUID(oPC));
    SqlStep(q);
    return SqlGetAffectedRows(q);
}

json NecGetServants(object oPC)
{
    json jRows = JsonArray();
    sqlquery q = SqlPrepareQueryCampaign("nec",
        "SELECT id, servant_tag, servant_name, servant_type, hp_current, hp_max, essence "
        "FROM nec_servants "
        "WHERE owner_uuid = @uuid AND is_active = 1 "
        "ORDER BY id");
    SqlBindString(q, "@uuid", GetObjectUUID(oPC));
    while (SqlStep(q))
    {
        json jRow = JsonObject();
        jRow = JsonObjectSet(jRow, "id",           JsonInt   (SqlGetInt   (q, 0)));
        jRow = JsonObjectSet(jRow, "servant_tag",  JsonString(SqlGetString(q, 1)));
        jRow = JsonObjectSet(jRow, "servant_name", JsonString(SqlGetString(q, 2)));
        jRow = JsonObjectSet(jRow, "servant_type", JsonInt   (SqlGetInt   (q, 3)));
        jRow = JsonObjectSet(jRow, "hp_current",   JsonInt   (SqlGetInt   (q, 4)));
        jRow = JsonObjectSet(jRow, "hp_max",       JsonInt   (SqlGetInt   (q, 5)));
        jRow = JsonObjectSet(jRow, "essence",      JsonInt   (SqlGetInt   (q, 6)));
        jRows = JsonArrayInsert(jRows, jRow);
    }
    return jRows;
}

int NecGetServantCount(object oPC)
{
    sqlquery q = SqlPrepareQueryCampaign("nec",
        "SELECT COUNT(*) FROM nec_servants "
        "WHERE owner_uuid = @uuid AND is_active = 1");
    SqlBindString(q, "@uuid", GetObjectUUID(oPC));
    if (SqlStep(q)) return SqlGetInt(q, 0);
    return 0;
}

// Inserts a new servant row; returns the new row id (0 on failure).
int NecInsertServant(object oPC, string sTag, string sName, int nType, int nHPMax, int nEssence)
{
    sqlquery q = SqlPrepareQueryCampaign("nec",
        "INSERT INTO nec_servants "
        "(owner_uuid, servant_tag, servant_name, servant_type, "
        " hp_current, hp_max, essence, raised_at, is_active) "
        "VALUES (@uuid, @tag, @name, @type, @hp, @hp, @ess, strftime('%s','now'), 1)");
    SqlBindString(q, "@uuid", GetObjectUUID(oPC));
    SqlBindString(q, "@tag",  sTag);
    SqlBindString(q, "@name", sName);
    SqlBindInt(q,    "@type", nType);
    SqlBindInt(q,    "@hp",   nHPMax);
    SqlBindInt(q,    "@ess",  nEssence);
    SqlStep(q);
    sqlquery qId = SqlPrepareQueryCampaign("nec", "SELECT last_insert_rowid()");
    if (SqlStep(qId)) return SqlGetInt(qId, 0);
    return 0;
}

void NecDismissServant(int nId)
{
    sqlquery q = SqlPrepareQueryCampaign("nec",
        "UPDATE nec_servants SET is_active = 0 WHERE id = @id");
    SqlBindInt(q, "@id", nId);
    SqlStep(q);
}

void NecUpdateServantEssence(int nId, int nEssence)
{
    sqlquery q = SqlPrepareQueryCampaign("nec",
        "UPDATE nec_servants SET essence = @ess WHERE id = @id");
    SqlBindInt(q, "@ess", nEssence);
    SqlBindInt(q, "@id",  nId);
    SqlStep(q);
}

void NecUpdateServantHP(int nId, int nHP)
{
    // If hp reaches 0 the servant is also deactivated.
    sqlquery q = SqlPrepareQueryCampaign("nec",
        "UPDATE nec_servants "
        "SET hp_current = @hp, "
        "    is_active  = CASE WHEN @hp <= 0 THEN 0 ELSE is_active END "
        "WHERE id = @id");
    SqlBindInt(q, "@hp", nHP);
    SqlBindInt(q, "@id", nId);
    SqlStep(q);
}

void NecFeedServantEssence(int nId, int nAmount, int nCap)
{
    sqlquery q = SqlPrepareQueryCampaign("nec",
        "UPDATE nec_servants SET essence = MIN(essence + @amt, @cap) WHERE id = @id");
    SqlBindInt(q, "@amt", nAmount);
    SqlBindInt(q, "@cap", nCap);
    SqlBindInt(q, "@id",  nId);
    SqlStep(q);
}

json NecGetServant(int nId)
{
    sqlquery q = SqlPrepareQueryCampaign("nec",
        "SELECT id, servant_tag, servant_name, servant_type, hp_current, hp_max, essence "
        "FROM nec_servants WHERE id = @id");
    SqlBindInt(q, "@id", nId);
    if (!SqlStep(q)) return JsonNull();
    json jRow = JsonObject();
    jRow = JsonObjectSet(jRow, "id",           JsonInt   (SqlGetInt   (q, 0)));
    jRow = JsonObjectSet(jRow, "servant_tag",  JsonString(SqlGetString(q, 1)));
    jRow = JsonObjectSet(jRow, "servant_name", JsonString(SqlGetString(q, 2)));
    jRow = JsonObjectSet(jRow, "servant_type", JsonInt   (SqlGetInt   (q, 3)));
    jRow = JsonObjectSet(jRow, "hp_current",   JsonInt   (SqlGetInt   (q, 4)));
    jRow = JsonObjectSet(jRow, "hp_max",       JsonInt   (SqlGetInt   (q, 5)));
    jRow = JsonObjectSet(jRow, "essence",      JsonInt   (SqlGetInt   (q, 6)));
    return jRow;
}
