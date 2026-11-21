// sql_fac.nss - Faction Reputation: SQL schema and data access layer
//
// Campaign DB: "factions" (separate from other modules)
// Per-character rep stored keyed by PC UUID + faction ID.
// History table for audit log (DM panel, optional telemetry).

// ================================================================
// Table creation (idempotent)
// ================================================================

void FacCreateTables()
{
    sqlquery q;

    q = SqlPrepareQueryCampaign("factions",
        "CREATE TABLE IF NOT EXISTS fac_reputation ("
        "  uuid       TEXT    NOT NULL,"
        "  faction_id INTEGER NOT NULL,"
        "  points     INTEGER NOT NULL DEFAULT 0,"
        "  PRIMARY KEY (uuid, faction_id)"
        ")");
    SqlStep(q);

    q = SqlPrepareQueryCampaign("factions",
        "CREATE TABLE IF NOT EXISTS fac_history ("
        "  id         INTEGER PRIMARY KEY AUTOINCREMENT,"
        "  uuid       TEXT    NOT NULL,"
        "  faction_id INTEGER NOT NULL,"
        "  delta      INTEGER NOT NULL,"
        "  reason     TEXT    DEFAULT '',"
        "  ts         INTEGER DEFAULT 0"
        ")");
    SqlStep(q);
}

// ================================================================
// CRUD
// ================================================================

int FacSqlGetPoints(object oPC, int nFactionId)
{
    sqlquery q = SqlPrepareQueryCampaign("factions",
        "SELECT points FROM fac_reputation WHERE uuid = @uuid AND faction_id = @fid");
    SqlBindString(q, "@uuid", GetObjectUUID(oPC));
    SqlBindInt   (q, "@fid",  nFactionId);
    if(SqlStep(q)) return SqlGetInt(q, 0);
    return 0;
}

void FacSqlSetPoints(object oPC, int nFactionId, int nPoints)
{
    sqlquery q = SqlPrepareQueryCampaign("factions",
        "INSERT OR REPLACE INTO fac_reputation (uuid, faction_id, points)"
        " VALUES (@uuid, @fid, @pts)");
    SqlBindString(q, "@uuid", GetObjectUUID(oPC));
    SqlBindInt   (q, "@fid",  nFactionId);
    SqlBindInt   (q, "@pts",  nPoints);
    SqlStep(q);
}

// Returns JsonArray of {faction_id, points} for all factions.
json FacSqlGetAllPoints(object oPC)
{
    json jArr = JsonArray();
    sqlquery q = SqlPrepareQueryCampaign("factions",
        "SELECT faction_id, points FROM fac_reputation WHERE uuid = @uuid");
    SqlBindString(q, "@uuid", GetObjectUUID(oPC));
    while(SqlStep(q))
    {
        json jRow = JsonObject();
        jRow = JsonObjectSet(jRow, "faction_id", JsonInt(SqlGetInt(q, 0)));
        jRow = JsonObjectSet(jRow, "points",     JsonInt(SqlGetInt(q, 1)));
        jArr = JsonArrayInsert(jArr, jRow);
    }
    return jArr;
}

void FacSqlLogHistory(object oPC, int nFactionId, int nDelta, string sReason)
{
    sqlquery q = SqlPrepareQueryCampaign("factions",
        "INSERT INTO fac_history (uuid, faction_id, delta, reason, ts)"
        " VALUES (@uuid, @fid, @delta, @reason, strftime('%s','now'))");
    SqlBindString(q, "@uuid",   GetObjectUUID(oPC));
    SqlBindInt   (q, "@fid",    nFactionId);
    SqlBindInt   (q, "@delta",  nDelta);
    SqlBindString(q, "@reason", sReason);
    SqlStep(q);
}
