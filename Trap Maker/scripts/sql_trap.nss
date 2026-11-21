// ================================================================
// sql_trap.nss  —  SQLite schema and queries for Trap Maker
//
// Campaign DB ("trap"):  global placed-trap registry
// Object DB (oPC):       per-character crafting statistics
// ================================================================

struct TrapStats
{
    int nCrafted;
    int nTriggered;
    int nDisarmed;
};

// ----------------------------------------------------------------
// Schema
// ----------------------------------------------------------------

void TrapCreateTables()
{
    // Global registry of active placed traps
    sqlquery q = SqlPrepareQueryCampaign("trap",
        "CREATE TABLE IF NOT EXISTS trap_placed ("
        "    trap_uuid   TEXT PRIMARY KEY,"
        "    type        TEXT NOT NULL,"
        "    setter_uuid TEXT NOT NULL,"
        "    setter_name TEXT NOT NULL DEFAULT '',"
        "    area_tag    TEXT NOT NULL DEFAULT '',"
        "    placed_at   INTEGER NOT NULL"
        ")");
    SqlStep(q);

    // Per-character crafting stats (stored on oPC's object DB)
    // NB: we call this on OnModuleLoad so the PC object isn't available yet;
    //     the PC-side table is created lazily on first UPSERT.
}

void TrapInitPCStats(object oPC)
{
    sqlquery q = SqlPrepareQueryObject(oPC,
        "CREATE TABLE IF NOT EXISTS trap_stats ("
        "    pc_uuid   TEXT PRIMARY KEY,"
        "    crafted   INTEGER DEFAULT 0,"
        "    triggered INTEGER DEFAULT 0,"
        "    disarmed  INTEGER DEFAULT 0"
        ")");
    SqlStep(q);

    q = SqlPrepareQueryObject(oPC,
        "INSERT OR IGNORE INTO trap_stats (pc_uuid) VALUES (@uuid)");
    SqlBindString(q, "@uuid", GetObjectUUID(oPC));
    SqlStep(q);
}

// ----------------------------------------------------------------
// Placed-trap registry
// ----------------------------------------------------------------

void TrapRegisterPlaced(object oTrap, string sType, object oPC)
{
    sqlquery q = SqlPrepareQueryCampaign("trap",
        "INSERT OR REPLACE INTO trap_placed"
        " (trap_uuid, type, setter_uuid, setter_name, area_tag, placed_at)"
        " VALUES (@uuid, @type, @suuid, @sname, @area, strftime('%s','now'))");
    SqlBindString(q, "@uuid",  GetObjectUUID(oTrap));
    SqlBindString(q, "@type",  sType);
    SqlBindString(q, "@suuid", GetObjectUUID(oPC));
    SqlBindString(q, "@sname", GetName(oPC));
    SqlBindString(q, "@area",  GetTag(GetArea(oTrap)));
    SqlStep(q);
}

void TrapUnregisterPlaced(object oTrap)
{
    sqlquery q = SqlPrepareQueryCampaign("trap",
        "DELETE FROM trap_placed WHERE trap_uuid = @uuid");
    SqlBindString(q, "@uuid", GetObjectUUID(oTrap));
    SqlStep(q);
}

int TrapCountActivePlaced(object oPC)
{
    sqlquery q = SqlPrepareQueryCampaign("trap",
        "SELECT COUNT(*) FROM trap_placed WHERE setter_uuid = @uuid");
    SqlBindString(q, "@uuid", GetObjectUUID(oPC));
    if(SqlStep(q)) return SqlGetInt(q, 0);
    return 0;
}

// Purge stale entries older than nHours (called on module load)
void TrapPurgeStale(int nHours)
{
    sqlquery q = SqlPrepareQueryCampaign("trap",
        "DELETE FROM trap_placed WHERE placed_at < strftime('%s','now') - @secs");
    SqlBindInt(q, "@secs", nHours * 3600);
    SqlStep(q);
}

// ----------------------------------------------------------------
// Per-character stats
// ----------------------------------------------------------------

void TrapStatIncCrafted(object oPC)
{
    sqlquery q = SqlPrepareQueryObject(oPC,
        "UPDATE trap_stats SET crafted = crafted + 1 WHERE pc_uuid = @uuid");
    SqlBindString(q, "@uuid", GetObjectUUID(oPC));
    SqlStep(q);
}

void TrapStatIncTriggered(object oPC)
{
    sqlquery q = SqlPrepareQueryObject(oPC,
        "UPDATE trap_stats SET triggered = triggered + 1 WHERE pc_uuid = @uuid");
    SqlBindString(q, "@uuid", GetObjectUUID(oPC));
    SqlStep(q);
}

void TrapStatIncDisarmed(object oPC)
{
    sqlquery q = SqlPrepareQueryObject(oPC,
        "UPDATE trap_stats SET disarmed = disarmed + 1 WHERE pc_uuid = @uuid");
    SqlBindString(q, "@uuid", GetObjectUUID(oPC));
    SqlStep(q);
}

struct TrapStats TrapGetStats(object oPC)
{
    struct TrapStats s;
    sqlquery q = SqlPrepareQueryObject(oPC,
        "SELECT crafted, triggered, disarmed FROM trap_stats WHERE pc_uuid = @uuid");
    SqlBindString(q, "@uuid", GetObjectUUID(oPC));
    if(SqlStep(q))
    {
        s.nCrafted   = SqlGetInt(q, 0);
        s.nTriggered = SqlGetInt(q, 1);
        s.nDisarmed  = SqlGetInt(q, 2);
    }
    return s;
}
