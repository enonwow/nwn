// =============================================================================
// sql_rations.nss
// =============================================================================
// Campaign SQLite persistence for the Rations system (hunger & thirst).
//
// Design: timestamp-based decay. We store last_meal_at / last_drink_at as Unix
// timestamps; current value is recomputed on demand:
//
//     current = MAX - (now - last_at) * decay_per_second
//
// This avoids per-tick SQL writes and survives logout naturally.
//
// Tables:
//   rations_state(uuid, last_meal_at, last_drink_at, last_th_h, last_th_t)
//   rations_ui(uuid, x, y, visible)
// =============================================================================

const string RAT_DB        = "rations";
const string RAT_TBL_STATE = "rations_state";
const string RAT_TBL_UI    = "rations_ui";

// -----------------------------------------------------------------------------
// Helpers
// -----------------------------------------------------------------------------
int RationsNowUnix()
{
    sqlquery sql = SqlPrepareQueryCampaign(RAT_DB, "SELECT strftime('%s', 'now');");
    SqlStep(sql);
    return SqlGetInt(sql, 0);
}

// -----------------------------------------------------------------------------
// Table creation
// -----------------------------------------------------------------------------
void RationsCreateTables()
{
    sqlquery sql = SqlPrepareQueryCampaign(RAT_DB,
        "CREATE TABLE IF NOT EXISTS " + RAT_TBL_STATE + " ("
        + "uuid TEXT PRIMARY KEY, "
        + "last_meal_at INTEGER NOT NULL, "
        + "last_drink_at INTEGER NOT NULL, "
        + "last_th_h INTEGER DEFAULT 2, "
        + "last_th_t INTEGER DEFAULT 2);");
    SqlStep(sql);

    sql = SqlPrepareQueryCampaign(RAT_DB,
        "CREATE TABLE IF NOT EXISTS " + RAT_TBL_UI + " ("
        + "uuid TEXT PRIMARY KEY, "
        + "x REAL DEFAULT -1.0, "
        + "y REAL DEFAULT -1.0, "
        + "visible INTEGER DEFAULT 1);");
    SqlStep(sql);
}

// -----------------------------------------------------------------------------
// State row
// -----------------------------------------------------------------------------
void RationsEnsureRow(object oPC)
{
    string sUuid = GetObjectUUID(oPC);
    int    nNow  = RationsNowUnix();

    sqlquery sql = SqlPrepareQueryCampaign(RAT_DB,
        "INSERT OR IGNORE INTO " + RAT_TBL_STATE
        + " (uuid, last_meal_at, last_drink_at) VALUES (@u, @t, @t);");
    SqlBindString(sql, "@u", sUuid);
    SqlBindInt(sql, "@t", nNow);
    SqlStep(sql);

    sql = SqlPrepareQueryCampaign(RAT_DB,
        "INSERT OR IGNORE INTO " + RAT_TBL_UI + " (uuid) VALUES (@u);");
    SqlBindString(sql, "@u", sUuid);
    SqlStep(sql);
}

int RationsGetLastMealAt(string sUuid)
{
    sqlquery sql = SqlPrepareQueryCampaign(RAT_DB,
        "SELECT last_meal_at FROM " + RAT_TBL_STATE + " WHERE uuid = @u;");
    SqlBindString(sql, "@u", sUuid);
    if(SqlStep(sql)) return SqlGetInt(sql, 0);
    return RationsNowUnix();
}

int RationsGetLastDrinkAt(string sUuid)
{
    sqlquery sql = SqlPrepareQueryCampaign(RAT_DB,
        "SELECT last_drink_at FROM " + RAT_TBL_STATE + " WHERE uuid = @u;");
    SqlBindString(sql, "@u", sUuid);
    if(SqlStep(sql)) return SqlGetInt(sql, 0);
    return RationsNowUnix();
}

int RationsGetLastThH(string sUuid)
{
    sqlquery sql = SqlPrepareQueryCampaign(RAT_DB,
        "SELECT last_th_h FROM " + RAT_TBL_STATE + " WHERE uuid = @u;");
    SqlBindString(sql, "@u", sUuid);
    if(SqlStep(sql)) return SqlGetInt(sql, 0);
    return 2;
}

int RationsGetLastThT(string sUuid)
{
    sqlquery sql = SqlPrepareQueryCampaign(RAT_DB,
        "SELECT last_th_t FROM " + RAT_TBL_STATE + " WHERE uuid = @u;");
    SqlBindString(sql, "@u", sUuid);
    if(SqlStep(sql)) return SqlGetInt(sql, 0);
    return 2;
}

void RationsSetLastMealAt(string sUuid, int nUnix)
{
    sqlquery sql = SqlPrepareQueryCampaign(RAT_DB,
        "UPDATE " + RAT_TBL_STATE + " SET last_meal_at = @t WHERE uuid = @u;");
    SqlBindString(sql, "@u", sUuid);
    SqlBindInt(sql, "@t", nUnix);
    SqlStep(sql);
}

void RationsSetLastDrinkAt(string sUuid, int nUnix)
{
    sqlquery sql = SqlPrepareQueryCampaign(RAT_DB,
        "UPDATE " + RAT_TBL_STATE + " SET last_drink_at = @t WHERE uuid = @u;");
    SqlBindString(sql, "@u", sUuid);
    SqlBindInt(sql, "@t", nUnix);
    SqlStep(sql);
}

void RationsSetLastThH(string sUuid, int nLvl)
{
    sqlquery sql = SqlPrepareQueryCampaign(RAT_DB,
        "UPDATE " + RAT_TBL_STATE + " SET last_th_h = @v WHERE uuid = @u;");
    SqlBindString(sql, "@u", sUuid);
    SqlBindInt(sql, "@v", nLvl);
    SqlStep(sql);
}

void RationsSetLastThT(string sUuid, int nLvl)
{
    sqlquery sql = SqlPrepareQueryCampaign(RAT_DB,
        "UPDATE " + RAT_TBL_STATE + " SET last_th_t = @v WHERE uuid = @u;");
    SqlBindString(sql, "@u", sUuid);
    SqlBindInt(sql, "@v", nLvl);
    SqlStep(sql);
}

// -----------------------------------------------------------------------------
// UI row (HUD geometry)
// -----------------------------------------------------------------------------
struct RationsUi
{
    float x;
    float y;
    int   visible;
};

struct RationsUi RationsGetUi(string sUuid)
{
    struct RationsUi r;
    r.x = -1.0;
    r.y = -1.0;
    r.visible = 1;

    sqlquery sql = SqlPrepareQueryCampaign(RAT_DB,
        "SELECT x, y, visible FROM " + RAT_TBL_UI + " WHERE uuid = @u;");
    SqlBindString(sql, "@u", sUuid);
    if(SqlStep(sql))
    {
        r.x = SqlGetFloat(sql, 0);
        r.y = SqlGetFloat(sql, 1);
        r.visible = SqlGetInt(sql, 2);
    }
    return r;
}

void RationsSetUiPos(string sUuid, float fX, float fY)
{
    sqlquery sql = SqlPrepareQueryCampaign(RAT_DB,
        "UPDATE " + RAT_TBL_UI + " SET x = @x, y = @y WHERE uuid = @u;");
    SqlBindString(sql, "@u", sUuid);
    SqlBindFloat(sql, "@x", fX);
    SqlBindFloat(sql, "@y", fY);
    SqlStep(sql);
}

void RationsSetUiVisible(string sUuid, int bVis)
{
    sqlquery sql = SqlPrepareQueryCampaign(RAT_DB,
        "UPDATE " + RAT_TBL_UI + " SET visible = @v WHERE uuid = @u;");
    SqlBindString(sql, "@u", sUuid);
    SqlBindInt(sql, "@v", bVis);
    SqlStep(sql);
}
