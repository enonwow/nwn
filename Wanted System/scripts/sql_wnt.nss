// =============================================================================
// sql_wnt.nss
// =============================================================================
// Campaign SQLite persistence for the Wanted system.
//
// Design: timestamp-based decay identical in shape to the Rations module.
// We store stored_heat (value at last_decay_at) and compute effective heat
// on demand:
//
//     effective = stored_heat - (now - last_decay_at) * WNT_DECAY_PER_SEC
//
// On any crime or payment, we snapshot the current effective value as the new
// stored_heat and update last_decay_at = now. This avoids per-tick writes.
//
// Tables:
//   wnt_state(uuid, stored_heat, last_decay_at, last_level, crimes_committed)
//   wnt_ui   (uuid, x, y)
// =============================================================================

const string WNT_DB        = "wanted";
const string WNT_TBL_STATE = "wnt_state";
const string WNT_TBL_UI    = "wnt_ui";

// ---------------------------------------------------------------------------
// Time helper
// ---------------------------------------------------------------------------
int WantedNowUnix()
{
    sqlquery sql = SqlPrepareQueryCampaign(WNT_DB, "SELECT strftime('%s', 'now');");
    SqlStep(sql);
    return SqlGetInt(sql, 0);
}

// ---------------------------------------------------------------------------
// Table creation (idempotent)
// ---------------------------------------------------------------------------
void WantedCreateTables()
{
    sqlquery sql = SqlPrepareQueryCampaign(WNT_DB,
        "CREATE TABLE IF NOT EXISTS " + WNT_TBL_STATE + " ("
        + "uuid             TEXT    PRIMARY KEY, "
        + "stored_heat      INTEGER DEFAULT 0, "
        + "last_decay_at    INTEGER NOT NULL, "
        + "last_level       INTEGER DEFAULT 0, "
        + "crimes_committed INTEGER DEFAULT 0);");
    SqlStep(sql);

    sql = SqlPrepareQueryCampaign(WNT_DB,
        "CREATE TABLE IF NOT EXISTS " + WNT_TBL_UI + " ("
        + "uuid TEXT PRIMARY KEY, "
        + "x    REAL DEFAULT -1.0, "
        + "y    REAL DEFAULT -1.0);");
    SqlStep(sql);
}

// ---------------------------------------------------------------------------
// Row bootstrap
// ---------------------------------------------------------------------------
void WantedEnsureRow(object oPC)
{
    string sUuid = GetObjectUUID(oPC);
    int    nNow  = WantedNowUnix();

    sqlquery sql = SqlPrepareQueryCampaign(WNT_DB,
        "INSERT OR IGNORE INTO " + WNT_TBL_STATE
        + " (uuid, stored_heat, last_decay_at) VALUES (@u, 0, @t);");
    SqlBindString(sql, "@u", sUuid);
    SqlBindInt(sql,    "@t", nNow);
    SqlStep(sql);

    sql = SqlPrepareQueryCampaign(WNT_DB,
        "INSERT OR IGNORE INTO " + WNT_TBL_UI + " (uuid) VALUES (@u);");
    SqlBindString(sql, "@u", sUuid);
    SqlStep(sql);
}

// ---------------------------------------------------------------------------
// State struct
// ---------------------------------------------------------------------------
struct WantedState
{
    int stored_heat;
    int last_decay_at;
    int last_level;
    int crimes_committed;
};

struct WantedState WantedGetState(string sUuid)
{
    struct WantedState r;
    r.stored_heat      = 0;
    r.last_decay_at    = WantedNowUnix();
    r.last_level       = 0;
    r.crimes_committed = 0;

    sqlquery sql = SqlPrepareQueryCampaign(WNT_DB,
        "SELECT stored_heat, last_decay_at, last_level, crimes_committed "
        + "FROM " + WNT_TBL_STATE + " WHERE uuid = @u;");
    SqlBindString(sql, "@u", sUuid);
    if(SqlStep(sql))
    {
        r.stored_heat      = SqlGetInt(sql, 0);
        r.last_decay_at    = SqlGetInt(sql, 1);
        r.last_level       = SqlGetInt(sql, 2);
        r.crimes_committed = SqlGetInt(sql, 3);
    }
    return r;
}

// ---------------------------------------------------------------------------
// Heat writes
// ---------------------------------------------------------------------------
void WantedWriteHeat(string sUuid, int nHeat, int nNow)
{
    sqlquery sql = SqlPrepareQueryCampaign(WNT_DB,
        "UPDATE " + WNT_TBL_STATE
        + " SET stored_heat = @h, last_decay_at = @t WHERE uuid = @u;");
    SqlBindString(sql, "@u", sUuid);
    SqlBindInt(sql,    "@h", nHeat);
    SqlBindInt(sql,    "@t", nNow);
    SqlStep(sql);
}

void WantedWriteLastLevel(string sUuid, int nLvl)
{
    sqlquery sql = SqlPrepareQueryCampaign(WNT_DB,
        "UPDATE " + WNT_TBL_STATE + " SET last_level = @v WHERE uuid = @u;");
    SqlBindString(sql, "@u", sUuid);
    SqlBindInt(sql,    "@v", nLvl);
    SqlStep(sql);
}

// ---------------------------------------------------------------------------
// Crime counter
// ---------------------------------------------------------------------------
void WantedIncrementCrimes(string sUuid)
{
    sqlquery sql = SqlPrepareQueryCampaign(WNT_DB,
        "UPDATE " + WNT_TBL_STATE
        + " SET crimes_committed = crimes_committed + 1 WHERE uuid = @u;");
    SqlBindString(sql, "@u", sUuid);
    SqlStep(sql);
}

void WantedResetCrimes(string sUuid)
{
    sqlquery sql = SqlPrepareQueryCampaign(WNT_DB,
        "UPDATE " + WNT_TBL_STATE + " SET crimes_committed = 0 WHERE uuid = @u;");
    SqlBindString(sql, "@u", sUuid);
    SqlStep(sql);
}

// ---------------------------------------------------------------------------
// UI position
// ---------------------------------------------------------------------------
struct WantedUiPos
{
    float x;
    float y;
};

struct WantedUiPos WantedGetUiPos(string sUuid)
{
    struct WantedUiPos r;
    r.x = -1.0;
    r.y = -1.0;

    sqlquery sql = SqlPrepareQueryCampaign(WNT_DB,
        "SELECT x, y FROM " + WNT_TBL_UI + " WHERE uuid = @u;");
    SqlBindString(sql, "@u", sUuid);
    if(SqlStep(sql))
    {
        r.x = SqlGetFloat(sql, 0);
        r.y = SqlGetFloat(sql, 1);
    }
    return r;
}

void WantedSetUiPos(string sUuid, float fX, float fY)
{
    sqlquery sql = SqlPrepareQueryCampaign(WNT_DB,
        "UPDATE " + WNT_TBL_UI + " SET x = @x, y = @y WHERE uuid = @u;");
    SqlBindString(sql, "@u", sUuid);
    SqlBindFloat(sql,  "@x", fX);
    SqlBindFloat(sql,  "@y", fY);
    SqlStep(sql);
}
