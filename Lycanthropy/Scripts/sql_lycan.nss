// sql_lycan.nss — SQLite schema + queries for the Lycanthropy module.
// Campaign DB name: "lycanthropy".

void LycanCreateTables()
{
    sqlquery q;

    q = SqlPrepareQueryCampaign("lycanthropy",
        "CREATE TABLE IF NOT EXISTS lycan_infected ("
        "  pc_uuid      TEXT PRIMARY KEY,"
        "  pc_name      TEXT NOT NULL DEFAULT '',"
        "  stage        INTEGER NOT NULL DEFAULT 1,"
        "  infected_at  INTEGER NOT NULL DEFAULT 0,"
        "  last_transform INTEGER NOT NULL DEFAULT 0"
        ")");
    SqlStep(q);

    // Tracks the start of the current moon cycle (unix epoch).
    // Seeded once at module load; persists across restarts.
    q = SqlPrepareQueryCampaign("lycanthropy",
        "CREATE TABLE IF NOT EXISTS lycan_moon ("
        "  id           INTEGER PRIMARY KEY DEFAULT 1,"
        "  cycle_start  INTEGER NOT NULL DEFAULT 0"
        ")");
    SqlStep(q);

    // Seed moon cycle only on first ever run.
    q = SqlPrepareQueryCampaign("lycanthropy",
        "INSERT OR IGNORE INTO lycan_moon (id, cycle_start) VALUES (1, strftime('%s','now'))");
    SqlStep(q);
}

// -----------------------------------------------------------------------
// Reads
// -----------------------------------------------------------------------

int LycanGetInfectionStage(object oPC)
{
    sqlquery q = SqlPrepareQueryCampaign("lycanthropy",
        "SELECT stage FROM lycan_infected WHERE pc_uuid = @uuid");
    SqlBindString(q, "@uuid", GetObjectUUID(oPC));
    if(SqlStep(q)) return SqlGetInt(q, 0);
    return 0;
}

int LycanGetInfectedAt(object oPC)
{
    sqlquery q = SqlPrepareQueryCampaign("lycanthropy",
        "SELECT infected_at FROM lycan_infected WHERE pc_uuid = @uuid");
    SqlBindString(q, "@uuid", GetObjectUUID(oPC));
    if(SqlStep(q)) return SqlGetInt(q, 0);
    return 0;
}

// Returns elapsed real-time days since infection.
int LycanGetDaysSinceInfection(object oPC)
{
    sqlquery q = SqlPrepareQueryCampaign("lycanthropy",
        "SELECT CAST((strftime('%s','now') - infected_at) / 86400.0 AS INTEGER) "
        "FROM lycan_infected WHERE pc_uuid = @uuid");
    SqlBindString(q, "@uuid", GetObjectUUID(oPC));
    if(SqlStep(q)) return SqlGetInt(q, 0);
    return 0;
}

int LycanGetMoonCycleStart()
{
    sqlquery q = SqlPrepareQueryCampaign("lycanthropy",
        "SELECT cycle_start FROM lycan_moon WHERE id = 1");
    if(SqlStep(q)) return SqlGetInt(q, 0);
    return 0;
}

// -----------------------------------------------------------------------
// Writes
// -----------------------------------------------------------------------

// nStage == 0 removes the infection record entirely.
void LycanSetInfection(object oPC, int nStage)
{
    sqlquery q;
    if(nStage <= 0)
    {
        q = SqlPrepareQueryCampaign("lycanthropy",
            "DELETE FROM lycan_infected WHERE pc_uuid = @uuid");
        SqlBindString(q, "@uuid", GetObjectUUID(oPC));
        SqlStep(q);
        return;
    }

    q = SqlPrepareQueryCampaign("lycanthropy",
        "INSERT INTO lycan_infected (pc_uuid, pc_name, stage, infected_at) "
        "VALUES (@uuid, @name, @stage, strftime('%s','now')) "
        "ON CONFLICT(pc_uuid) DO UPDATE SET stage = @stage, pc_name = @name");
    SqlBindString(q, "@uuid",  GetObjectUUID(oPC));
    SqlBindString(q, "@name",  GetName(oPC));
    SqlBindInt   (q, "@stage", nStage);
    SqlStep(q);
}

// Records the unix time of the most recent transformation.
void LycanRecordTransform(object oPC)
{
    sqlquery q = SqlPrepareQueryCampaign("lycanthropy",
        "UPDATE lycan_infected SET last_transform = strftime('%s','now') WHERE pc_uuid = @uuid");
    SqlBindString(q, "@uuid", GetObjectUUID(oPC));
    SqlStep(q);
}
