// sql_duel.nss
// Honor Duels - persistence layer (SQLite, campaign-scope).
// Three tables:
//   duels       - one row per challenge / duel
//   duel_honor  - aggregate stats per PC (honor, granular wins/losses)
//   duel_ui     - per-PC HUD window position

const string DUEL_DB = "duel";

// ============================================================
// Schema
// ============================================================

void DuelCreateTables()
{
    sqlquery q;

    q = SqlPrepareQueryCampaign(DUEL_DB,
        "CREATE TABLE IF NOT EXISTS duels ("
        + "id INTEGER PRIMARY KEY AUTOINCREMENT, "
        + "challenger_uuid TEXT NOT NULL, "
        + "challenger_name TEXT DEFAULT '', "
        + "challenged_uuid TEXT NOT NULL, "
        + "challenged_name TEXT DEFAULT '', "
        + "status INTEGER DEFAULT 0, "
        + "winner_uuid TEXT DEFAULT '', "
        + "loser_uuid TEXT DEFAULT '', "
        + "outcome_type INTEGER DEFAULT -1, "
        + "outcome_note TEXT DEFAULT '', "
        + "arena_x REAL DEFAULT 0, "
        + "arena_y REAL DEFAULT 0, "
        + "arena_z REAL DEFAULT 0, "
        + "arena_area TEXT DEFAULT '', "
        + "created_at INTEGER DEFAULT 0, "
        + "completed_at INTEGER DEFAULT 0)");
    SqlStep(q);

    q = SqlPrepareQueryCampaign(DUEL_DB,
        "CREATE TABLE IF NOT EXISTS duel_honor ("
        + "uuid TEXT PRIMARY KEY, "
        + "char_name TEXT DEFAULT '', "
        + "honor INTEGER DEFAULT 0, "
        + "declined INTEGER DEFAULT 0, "
        + "wins_by_kill INTEGER DEFAULT 0, "
        + "wins_by_flee INTEGER DEFAULT 0, "
        + "losses_by_kill INTEGER DEFAULT 0, "
        + "losses_by_flee INTEGER DEFAULT 0, "
        + "last_seen INTEGER DEFAULT 0)");
    SqlStep(q);

    q = SqlPrepareQueryCampaign(DUEL_DB,
        "CREATE TABLE IF NOT EXISTS duel_ui ("
        + "uuid TEXT PRIMARY KEY, "
        + "hud_x REAL DEFAULT 20.0, "
        + "hud_y REAL DEFAULT 60.0)");
    SqlStep(q);
}

// ============================================================
// Honor table
// ============================================================

void DuelRegisterHonor(object oPC)
{
    sqlquery q = SqlPrepareQueryCampaign(DUEL_DB,
        "INSERT OR IGNORE INTO duel_honor (uuid, char_name, last_seen) "
        + "VALUES (@uuid, @name, strftime('%s','now'))");
    SqlBindString(q, "@uuid", GetObjectUUID(oPC));
    SqlBindString(q, "@name", GetName(oPC));
    SqlStep(q);

    q = SqlPrepareQueryCampaign(DUEL_DB,
        "UPDATE duel_honor SET char_name = @name, last_seen = strftime('%s','now') "
        + "WHERE uuid = @uuid");
    SqlBindString(q, "@uuid", GetObjectUUID(oPC));
    SqlBindString(q, "@name", GetName(oPC));
    SqlStep(q);
}

int DuelGetHonor(string sUuid)
{
    sqlquery q = SqlPrepareQueryCampaign(DUEL_DB,
        "SELECT honor FROM duel_honor WHERE uuid = @uuid");
    SqlBindString(q, "@uuid", sUuid);
    if(SqlStep(q)) return SqlGetInt(q, 0);
    return 0;
}

// Returns full honor row + computed totals (wins, losses).
json DuelGetHonorRow(string sUuid)
{
    sqlquery q = SqlPrepareQueryCampaign(DUEL_DB,
        "SELECT char_name, honor, declined, "
        + "wins_by_kill, wins_by_flee, losses_by_kill, losses_by_flee "
        + "FROM duel_honor WHERE uuid = @uuid");
    SqlBindString(q, "@uuid", sUuid);
    if(!SqlStep(q)) return JsonNull();

    int nWk = SqlGetInt(q, 3);
    int nWf = SqlGetInt(q, 4);
    int nLk = SqlGetInt(q, 5);
    int nLf = SqlGetInt(q, 6);

    json j = JsonObject();
    j = JsonObjectSet(j, "char_name",       JsonString(SqlGetString(q, 0)));
    j = JsonObjectSet(j, "honor",           JsonInt   (SqlGetInt   (q, 1)));
    j = JsonObjectSet(j, "declined",        JsonInt   (SqlGetInt   (q, 2)));
    j = JsonObjectSet(j, "wins_by_kill",    JsonInt   (nWk));
    j = JsonObjectSet(j, "wins_by_flee",    JsonInt   (nWf));
    j = JsonObjectSet(j, "losses_by_kill",  JsonInt   (nLk));
    j = JsonObjectSet(j, "losses_by_flee",  JsonInt   (nLf));
    j = JsonObjectSet(j, "wins",            JsonInt   (nWk + nWf));
    j = JsonObjectSet(j, "losses",          JsonInt   (nLk + nLf));
    return j;
}

// Adjust honor + outcome counters in one update.
// Pass deltas as 0/1 - they accumulate.
void DuelAdjustHonor(string sUuid, string sName, int nDelta,
                     int bWinKill, int bWinFlee,
                     int bLossKill, int bLossFlee, int bDecline)
{
    sqlquery qIns = SqlPrepareQueryCampaign(DUEL_DB,
        "INSERT OR IGNORE INTO duel_honor (uuid, char_name) VALUES (@uuid, @name)");
    SqlBindString(qIns, "@uuid", sUuid);
    SqlBindString(qIns, "@name", sName);
    SqlStep(qIns);

    sqlquery q = SqlPrepareQueryCampaign(DUEL_DB,
        "UPDATE duel_honor SET "
        + "honor          = honor + @delta, "
        + "declined       = declined + @bd, "
        + "wins_by_kill   = wins_by_kill + @bwk, "
        + "wins_by_flee   = wins_by_flee + @bwf, "
        + "losses_by_kill = losses_by_kill + @blk, "
        + "losses_by_flee = losses_by_flee + @blf, "
        + "char_name      = @name "
        + "WHERE uuid = @uuid");
    SqlBindString(q, "@uuid",  sUuid);
    SqlBindString(q, "@name",  sName);
    SqlBindInt   (q, "@delta", nDelta);
    SqlBindInt   (q, "@bd",    bDecline);
    SqlBindInt   (q, "@bwk",   bWinKill);
    SqlBindInt   (q, "@bwf",   bWinFlee);
    SqlBindInt   (q, "@blk",   bLossKill);
    SqlBindInt   (q, "@blf",   bLossFlee);
    SqlStep(q);
}

// ============================================================
// Duel CRUD
// ============================================================

int DuelCreate(object oChallenger, object oChallenged)
{
    location lLoc = GetLocation(oChallenger);
    vector vPos   = GetPositionFromLocation(lLoc);

    sqlquery q = SqlPrepareQueryCampaign(DUEL_DB,
        "INSERT INTO duels ("
        + "challenger_uuid, challenger_name, challenged_uuid, challenged_name, "
        + "status, arena_x, arena_y, arena_z, arena_area, created_at) "
        + "VALUES (@cu, @cn, @du, @dn, 0, @x, @y, @z, @area, strftime('%s','now'))");
    SqlBindString(q, "@cu",   GetObjectUUID(oChallenger));
    SqlBindString(q, "@cn",   GetName(oChallenger));
    SqlBindString(q, "@du",   GetObjectUUID(oChallenged));
    SqlBindString(q, "@dn",   GetName(oChallenged));
    SqlBindFloat (q, "@x",    vPos.x);
    SqlBindFloat (q, "@y",    vPos.y);
    SqlBindFloat (q, "@z",    vPos.z);
    SqlBindString(q, "@area", GetResRef(GetAreaFromLocation(lLoc)));
    SqlStep(q);

    sqlquery qId = SqlPrepareQueryCampaign(DUEL_DB, "SELECT last_insert_rowid()");
    if(SqlStep(qId)) return SqlGetInt(qId, 0);
    return 0;
}

json DuelGetById(int nId)
{
    sqlquery q = SqlPrepareQueryCampaign(DUEL_DB,
        "SELECT id, challenger_uuid, challenger_name, challenged_uuid, challenged_name, "
        + "status, winner_uuid, loser_uuid, outcome_type, outcome_note, "
        + "arena_x, arena_y, arena_z, arena_area, created_at, completed_at "
        + "FROM duels WHERE id = @id");
    SqlBindInt(q, "@id", nId);
    if(!SqlStep(q)) return JsonNull();

    json j = JsonObject();
    j = JsonObjectSet(j, "id",              JsonInt   (SqlGetInt   (q,  0)));
    j = JsonObjectSet(j, "challenger_uuid", JsonString(SqlGetString(q,  1)));
    j = JsonObjectSet(j, "challenger_name", JsonString(SqlGetString(q,  2)));
    j = JsonObjectSet(j, "challenged_uuid", JsonString(SqlGetString(q,  3)));
    j = JsonObjectSet(j, "challenged_name", JsonString(SqlGetString(q,  4)));
    j = JsonObjectSet(j, "status",          JsonInt   (SqlGetInt   (q,  5)));
    j = JsonObjectSet(j, "winner_uuid",     JsonString(SqlGetString(q,  6)));
    j = JsonObjectSet(j, "loser_uuid",      JsonString(SqlGetString(q,  7)));
    j = JsonObjectSet(j, "outcome_type",    JsonInt   (SqlGetInt   (q,  8)));
    j = JsonObjectSet(j, "outcome_note",    JsonString(SqlGetString(q,  9)));
    j = JsonObjectSet(j, "arena_x",         JsonFloat (SqlGetFloat (q, 10)));
    j = JsonObjectSet(j, "arena_y",         JsonFloat (SqlGetFloat (q, 11)));
    j = JsonObjectSet(j, "arena_z",         JsonFloat (SqlGetFloat (q, 12)));
    j = JsonObjectSet(j, "arena_area",      JsonString(SqlGetString(q, 13)));
    j = JsonObjectSet(j, "created_at",      JsonInt   (SqlGetInt   (q, 14)));
    j = JsonObjectSet(j, "completed_at",    JsonInt   (SqlGetInt   (q, 15)));
    return j;
}

void DuelSetStatus(int nId, int nStatus)
{
    sqlquery q = SqlPrepareQueryCampaign(DUEL_DB,
        "UPDATE duels SET status = @s WHERE id = @id");
    SqlBindInt(q, "@s",  nStatus);
    SqlBindInt(q, "@id", nId);
    SqlStep(q);
}

void DuelSetOutcome(int nId, int nStatus,
                    string sWinnerUuid, string sLoserUuid,
                    int nOutcomeType, string sNote)
{
    sqlquery q = SqlPrepareQueryCampaign(DUEL_DB,
        "UPDATE duels SET status = @s, winner_uuid = @w, loser_uuid = @l, "
        + "outcome_type = @ot, outcome_note = @n, completed_at = strftime('%s','now') "
        + "WHERE id = @id");
    SqlBindInt   (q, "@s",  nStatus);
    SqlBindString(q, "@w",  sWinnerUuid);
    SqlBindString(q, "@l",  sLoserUuid);
    SqlBindInt   (q, "@ot", nOutcomeType);
    SqlBindString(q, "@n",  sNote);
    SqlBindInt   (q, "@id", nId);
    SqlStep(q);
}

// Marks pending challenges older than nTtlSeconds as expired.
void DuelExpireOld(int nTtlSeconds)
{
    sqlquery q = SqlPrepareQueryCampaign(DUEL_DB,
        "UPDATE duels SET status = 5, outcome_type = 4, "
        + "outcome_note = 'Expired without response.', "
        + "completed_at = strftime('%s','now') "
        + "WHERE status = 0 AND created_at < strftime('%s','now') - @ttl");
    SqlBindInt(q, "@ttl", nTtlSeconds);
    SqlStep(q);
}

// Wipes any in-progress duels left over from a server crash / restart.
void DuelClearStaleActive()
{
    sqlquery q = SqlPrepareQueryCampaign(DUEL_DB,
        "UPDATE duels SET status = 5, outcome_type = 4, "
        + "outcome_note = 'Server restart.', "
        + "completed_at = strftime('%s','now') "
        + "WHERE status IN (1, 2)");
    SqlStep(q);
}

// Active = PENDING / ACCEPTED / IN_PROGRESS for given player (any side).
int DuelHasAnyActive(string sUuid)
{
    sqlquery q = SqlPrepareQueryCampaign(DUEL_DB,
        "SELECT id FROM duels WHERE status IN (0,1,2) AND "
        + "(challenger_uuid = @u OR challenged_uuid = @u) LIMIT 1");
    SqlBindString(q, "@u", sUuid);
    if(SqlStep(q)) return SqlGetInt(q, 0);
    return 0;
}

// ============================================================
// Lists for UI
// ============================================================

// Returns the duel ID of any pending challenge incoming to this PC, or 0.
// Used by sys_on_enter to notify the player on login.
int DuelGetIncomingPendingId(string sUuid)
{
    sqlquery q = SqlPrepareQueryCampaign(DUEL_DB,
        "SELECT id FROM duels WHERE status = 0 AND challenged_uuid = @u LIMIT 1");
    SqlBindString(q, "@u", sUuid);
    if(SqlStep(q)) return SqlGetInt(q, 0);
    return 0;
}

json DuelGetHistory(string sUuid, int nLimit)
{
    json jRows = JsonArray();
    sqlquery q = SqlPrepareQueryCampaign(DUEL_DB,
        "SELECT id, challenger_uuid, challenger_name, challenged_uuid, challenged_name, "
        + "winner_uuid, status, outcome_type, outcome_note, completed_at "
        + "FROM duels WHERE status IN (3,4,5,6) AND "
        + "(challenger_uuid = @u OR challenged_uuid = @u) "
        + "ORDER BY COALESCE(completed_at, created_at) DESC LIMIT @lim");
    SqlBindString(q, "@u",   sUuid);
    SqlBindInt   (q, "@lim", nLimit);
    while(SqlStep(q))
    {
        json j = JsonObject();
        j = JsonObjectSet(j, "id",              JsonInt   (SqlGetInt   (q, 0)));
        j = JsonObjectSet(j, "challenger_uuid", JsonString(SqlGetString(q, 1)));
        j = JsonObjectSet(j, "challenger_name", JsonString(SqlGetString(q, 2)));
        j = JsonObjectSet(j, "challenged_uuid", JsonString(SqlGetString(q, 3)));
        j = JsonObjectSet(j, "challenged_name", JsonString(SqlGetString(q, 4)));
        j = JsonObjectSet(j, "winner_uuid",     JsonString(SqlGetString(q, 5)));
        j = JsonObjectSet(j, "status",          JsonInt   (SqlGetInt   (q, 6)));
        j = JsonObjectSet(j, "outcome_type",    JsonInt   (SqlGetInt   (q, 7)));
        j = JsonObjectSet(j, "outcome_note",    JsonString(SqlGetString(q, 8)));
        j = JsonObjectSet(j, "completed_at",    JsonInt   (SqlGetInt   (q, 9)));
        jRows = JsonArrayInsert(jRows, j);
    }
    return jRows;
}

// Top N by honor. Only includes PCs with at least one resolved duel.
json DuelGetRanking(int nLimit)
{
    json jRows = JsonArray();
    sqlquery q = SqlPrepareQueryCampaign(DUEL_DB,
        "SELECT char_name, honor, "
        + "wins_by_kill, wins_by_flee, losses_by_kill, losses_by_flee "
        + "FROM duel_honor "
        + "WHERE wins_by_kill + wins_by_flee + losses_by_kill + losses_by_flee + declined > 0 "
        + "ORDER BY honor DESC, wins_by_kill + wins_by_flee DESC LIMIT @lim");
    SqlBindInt(q, "@lim", nLimit);
    while(SqlStep(q))
    {
        int nWk = SqlGetInt(q, 2);
        int nWf = SqlGetInt(q, 3);
        int nLk = SqlGetInt(q, 4);
        int nLf = SqlGetInt(q, 5);

        json j = JsonObject();
        j = JsonObjectSet(j, "char_name",      JsonString(SqlGetString(q, 0)));
        j = JsonObjectSet(j, "honor",          JsonInt   (SqlGetInt   (q, 1)));
        j = JsonObjectSet(j, "wins_by_kill",   JsonInt   (nWk));
        j = JsonObjectSet(j, "wins_by_flee",   JsonInt   (nWf));
        j = JsonObjectSet(j, "losses_by_kill", JsonInt   (nLk));
        j = JsonObjectSet(j, "losses_by_flee", JsonInt   (nLf));
        j = JsonObjectSet(j, "wins",           JsonInt   (nWk + nWf));
        j = JsonObjectSet(j, "losses",         JsonInt   (nLk + nLf));
        jRows = JsonArrayInsert(jRows, j);
    }
    return jRows;
}

string DuelFormatDateSQL(int nUnix)
{
    sqlquery q = SqlPrepareQueryCampaign(DUEL_DB,
        "SELECT strftime('%d.%m %H:%M', @ts, 'unixepoch', 'localtime')");
    SqlBindInt(q, "@ts", nUnix);
    if(SqlStep(q)) return SqlGetString(q, 0);
    return "";
}

// ============================================================
// HUD position persistence
// ============================================================

void DuelUiSavePosition(string sUuid, float fX, float fY)
{
    sqlquery q = SqlPrepareQueryCampaign(DUEL_DB,
        "INSERT INTO duel_ui (uuid, hud_x, hud_y) VALUES (@u, @x, @y) "
        + "ON CONFLICT(uuid) DO UPDATE SET hud_x = @x, hud_y = @y");
    SqlBindString(q, "@u", sUuid);
    SqlBindFloat (q, "@x", fX);
    SqlBindFloat (q, "@y", fY);
    SqlStep(q);
}

json DuelUiLoadPosition(string sUuid)
{
    sqlquery q = SqlPrepareQueryCampaign(DUEL_DB,
        "SELECT hud_x, hud_y FROM duel_ui WHERE uuid = @u");
    SqlBindString(q, "@u", sUuid);
    if(!SqlStep(q)) return JsonNull();
    json j = JsonObject();
    j = JsonObjectSet(j, "x", JsonFloat(SqlGetFloat(q, 0)));
    j = JsonObjectSet(j, "y", JsonFloat(SqlGetFloat(q, 1)));
    return j;
}
