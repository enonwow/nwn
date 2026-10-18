// Stronghold persistent data. Uses campaign DB "stronghold".
// Per-PC, per-building: level and optional upgrade finish timestamp.

void StrongholdCreateTables()
{
    sqlquery q = SqlPrepareQueryCampaign("stronghold",
        "CREATE TABLE IF NOT EXISTS sth_buildings ("
        "  pc_uuid          TEXT    NOT NULL,"
        "  building_id      INTEGER NOT NULL,"
        "  level            INTEGER NOT NULL DEFAULT 0,"
        "  upgrade_finish   INTEGER NOT NULL DEFAULT 0,"
        "  PRIMARY KEY (pc_uuid, building_id)"
        ")");
    SqlStep(q);
}

// ----------------------------------------------------------------
// Row access
// ----------------------------------------------------------------

// Returns {level, upgrade_finish} or {0, 0} if row not found.
json StrongholdGetBuilding(string sPcUuid, int nBldId)
{
    sqlquery q = SqlPrepareQueryCampaign("stronghold",
        "SELECT level, upgrade_finish FROM sth_buildings"
        " WHERE pc_uuid = @uuid AND building_id = @bid");
    SqlBindString(q, "@uuid", sPcUuid);
    SqlBindInt   (q, "@bid",  nBldId);

    json jRow = JsonObject();
    if(SqlStep(q))
    {
        jRow = JsonObjectSet(jRow, "level",          JsonInt(SqlGetInt(q, 0)));
        jRow = JsonObjectSet(jRow, "upgrade_finish", JsonInt(SqlGetInt(q, 1)));
    }
    else
    {
        jRow = JsonObjectSet(jRow, "level",          JsonInt(0));
        jRow = JsonObjectSet(jRow, "upgrade_finish", JsonInt(0));
    }
    return jRow;
}

int StrongholdGetLevel(string sPcUuid, int nBldId)
{
    json jRow = StrongholdGetBuilding(sPcUuid, nBldId);
    return JsonGetInt(JsonObjectGet(jRow, "level"));
}

int StrongholdGetUpgradeFinish(string sPcUuid, int nBldId)
{
    json jRow = StrongholdGetBuilding(sPcUuid, nBldId);
    return JsonGetInt(JsonObjectGet(jRow, "upgrade_finish"));
}

// ----------------------------------------------------------------
// Mutations
// ----------------------------------------------------------------

void StrongholdSetLevel(string sPcUuid, int nBldId, int nLevel)
{
    sqlquery q = SqlPrepareQueryCampaign("stronghold",
        "INSERT INTO sth_buildings (pc_uuid, building_id, level, upgrade_finish)"
        " VALUES (@uuid, @bid, @lvl, 0)"
        " ON CONFLICT(pc_uuid, building_id) DO UPDATE SET level = @lvl, upgrade_finish = 0");
    SqlBindString(q, "@uuid", sPcUuid);
    SqlBindInt   (q, "@bid",  nBldId);
    SqlBindInt   (q, "@lvl",  nLevel);
    SqlStep(q);
}

// Records that an upgrade is in progress; finish_ts is unix epoch.
void StrongholdStartUpgrade(string sPcUuid, int nBldId, int nFinishTs)
{
    sqlquery q = SqlPrepareQueryCampaign("stronghold",
        "INSERT INTO sth_buildings (pc_uuid, building_id, level, upgrade_finish)"
        " VALUES (@uuid, @bid, 0, @ts)"
        " ON CONFLICT(pc_uuid, building_id) DO UPDATE SET upgrade_finish = @ts");
    SqlBindString(q, "@uuid", sPcUuid);
    SqlBindInt   (q, "@bid",  nBldId);
    SqlBindInt   (q, "@ts",   nFinishTs);
    SqlStep(q);
}

// Cancels an in-progress upgrade (resets finish timestamp without touching level).
void StrongholdCancelUpgrade(string sPcUuid, int nBldId)
{
    sqlquery q = SqlPrepareQueryCampaign("stronghold",
        "UPDATE sth_buildings SET upgrade_finish = 0"
        " WHERE pc_uuid = @uuid AND building_id = @bid");
    SqlBindString(q, "@uuid", sPcUuid);
    SqlBindInt   (q, "@bid",  nBldId);
    SqlStep(q);
}

// Returns current unix epoch from the SQLite engine (server-side clock).
int StrongholdNow()
{
    sqlquery q = SqlPrepareQueryCampaign("stronghold",
        "SELECT CAST(strftime('%s','now') AS INTEGER)");
    if(SqlStep(q)) return SqlGetInt(q, 0);
    return 0;
}
