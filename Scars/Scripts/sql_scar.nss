void ScarCreateTables()
{
    sqlquery q = SqlPrepareQueryCampaign("scar",
        "CREATE TABLE IF NOT EXISTS scar_wounds ("
        " id INTEGER PRIMARY KEY AUTOINCREMENT,"
        " pc_uuid TEXT NOT NULL,"
        " wound_type INTEGER NOT NULL DEFAULT 0,"
        " location INTEGER NOT NULL DEFAULT 0,"
        " status INTEGER NOT NULL DEFAULT 0,"
        " gained_at INTEGER NOT NULL DEFAULT (strftime('%s','now')),"
        " healed_at INTEGER DEFAULT NULL"
        ")");
    SqlStep(q);

    q = SqlPrepareQueryCampaign("scar",
        "CREATE INDEX IF NOT EXISTS idx_scar_pc ON scar_wounds (pc_uuid)");
    SqlStep(q);
}

json ScarDbGetWounds(object oPC)
{
    json jRows = JsonArray();
    sqlquery q = SqlPrepareQueryCampaign("scar",
        "SELECT id, wound_type, location, status, gained_at, healed_at "
        "FROM scar_wounds WHERE pc_uuid = @uuid ORDER BY gained_at DESC");
    SqlBindString(q, "@uuid", GetObjectUUID(oPC));
    while(SqlStep(q))
    {
        json jRow = JsonObject();
        jRow = JsonObjectSet(jRow, "id",         JsonInt(SqlGetInt(q, 0)));
        jRow = JsonObjectSet(jRow, "wound_type", JsonInt(SqlGetInt(q, 1)));
        jRow = JsonObjectSet(jRow, "location",   JsonInt(SqlGetInt(q, 2)));
        jRow = JsonObjectSet(jRow, "status",     JsonInt(SqlGetInt(q, 3)));
        jRow = JsonObjectSet(jRow, "gained_at",  JsonInt(SqlGetInt(q, 4)));
        jRow = JsonObjectSet(jRow, "healed_at",  JsonInt(SqlGetInt(q, 5)));
        jRows = JsonArrayInsert(jRows, jRow);
    }
    return jRows;
}

int ScarDbAddWound(object oPC, int nType, int nLoc)
{
    sqlquery q = SqlPrepareQueryCampaign("scar",
        "INSERT INTO scar_wounds (pc_uuid, wound_type, location, status) VALUES (@uuid, @type, @loc, 0)");
    SqlBindString(q, "@uuid", GetObjectUUID(oPC));
    SqlBindInt(q, "@type", nType);
    SqlBindInt(q, "@loc",  nLoc);
    SqlStep(q);
    sqlquery qId = SqlPrepareQueryCampaign("scar", "SELECT last_insert_rowid()");
    if(SqlStep(qId)) return SqlGetInt(qId, 0);
    return -1;
}

void ScarDbTreatWound(int nId)
{
    sqlquery q = SqlPrepareQueryCampaign("scar",
        "UPDATE scar_wounds SET status = 1, healed_at = strftime('%s','now') WHERE id = @id AND status = 0");
    SqlBindInt(q, "@id", nId);
    SqlStep(q);
}

// Promotes HEALING wounds to SCARRED once the heal window has elapsed
void ScarDbFinalizeHealed(object oPC, int nHealSeconds)
{
    sqlquery q = SqlPrepareQueryCampaign("scar",
        "UPDATE scar_wounds SET status = 2 "
        "WHERE pc_uuid = @uuid AND status = 1 "
        "AND healed_at IS NOT NULL "
        "AND healed_at + @secs <= strftime('%s','now')");
    SqlBindString(q, "@uuid", GetObjectUUID(oPC));
    SqlBindInt(q, "@secs", nHealSeconds);
    SqlStep(q);
}

int ScarDbCountOpen(object oPC)
{
    sqlquery q = SqlPrepareQueryCampaign("scar",
        "SELECT COUNT(*) FROM scar_wounds WHERE pc_uuid = @uuid AND status = 0");
    SqlBindString(q, "@uuid", GetObjectUUID(oPC));
    if(SqlStep(q)) return SqlGetInt(q, 0);
    return 0;
}

int ScarDbCountAll(object oPC)
{
    sqlquery q = SqlPrepareQueryCampaign("scar",
        "SELECT COUNT(*) FROM scar_wounds WHERE pc_uuid = @uuid");
    SqlBindString(q, "@uuid", GetObjectUUID(oPC));
    if(SqlStep(q)) return SqlGetInt(q, 0);
    return 0;
}
