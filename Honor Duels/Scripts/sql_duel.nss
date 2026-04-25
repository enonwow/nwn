// ----------------------------------------------------------------
// Honor Duels — persistence layer (SQLite via NWNX, campaign-scope)
// ----------------------------------------------------------------

const string DUEL_DB = "duel";

void DuelCreateTables()
{
    sqlquery q = SqlPrepareQueryCampaign(DUEL_DB,
        "CREATE TABLE IF NOT EXISTS duels ("
        "id INTEGER PRIMARY KEY AUTOINCREMENT, "
        "challenger_uuid TEXT NOT NULL, "
        "challenger_name TEXT DEFAULT '', "
        "challenged_uuid TEXT NOT NULL, "
        "challenged_name TEXT DEFAULT '', "
        "rules_mask INTEGER DEFAULT 0, "
        "win_cond INTEGER DEFAULT 0, "
        "stake_gold INTEGER DEFAULT 0, "
        "status INTEGER DEFAULT 0, "
        "winner_uuid TEXT DEFAULT '', "
        "loser_uuid TEXT DEFAULT '', "
        "outcome_note TEXT DEFAULT '', "
        "arena_x REAL DEFAULT 0, "
        "arena_y REAL DEFAULT 0, "
        "arena_z REAL DEFAULT 0, "
        "arena_area TEXT DEFAULT '', "
        "created_at INTEGER DEFAULT 0, "
        "completed_at INTEGER DEFAULT 0)");
    SqlStep(q);

    q = SqlPrepareQueryCampaign(DUEL_DB,
        "CREATE TABLE IF NOT EXISTS duel_honor ("
        "uuid TEXT PRIMARY KEY, "
        "char_name TEXT DEFAULT '', "
        "honor INTEGER DEFAULT 0, "
        "wins INTEGER DEFAULT 0, "
        "losses INTEGER DEFAULT 0, "
        "declined INTEGER DEFAULT 0, "
        "forfeits INTEGER DEFAULT 0, "
        "kills INTEGER DEFAULT 0, "
        "last_seen INTEGER DEFAULT 0)");
    SqlStep(q);
}

void DuelRegisterHonor(object oPC)
{
    sqlquery q = SqlPrepareQueryCampaign(DUEL_DB,
        "INSERT OR IGNORE INTO duel_honor (uuid, char_name, last_seen) "
        "VALUES (@uuid, @name, strftime('%s','now'))");
    SqlBindString(q, "@uuid", GetObjectUUID(oPC));
    SqlBindString(q, "@name", GetName(oPC));
    SqlStep(q);

    q = SqlPrepareQueryCampaign(DUEL_DB,
        "UPDATE duel_honor SET char_name = @name, last_seen = strftime('%s','now') WHERE uuid = @uuid");
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

json DuelGetHonorRow(string sUuid)
{
    sqlquery q = SqlPrepareQueryCampaign(DUEL_DB,
        "SELECT char_name, honor, wins, losses, declined, forfeits, kills "
        "FROM duel_honor WHERE uuid = @uuid");
    SqlBindString(q, "@uuid", sUuid);
    if(!SqlStep(q)) return JsonNull();
    json j = JsonObject();
    j = JsonObjectSet(j, "char_name", JsonString(SqlGetString(q, 0)));
    j = JsonObjectSet(j, "honor",     JsonInt   (SqlGetInt   (q, 1)));
    j = JsonObjectSet(j, "wins",      JsonInt   (SqlGetInt   (q, 2)));
    j = JsonObjectSet(j, "losses",    JsonInt   (SqlGetInt   (q, 3)));
    j = JsonObjectSet(j, "declined",  JsonInt   (SqlGetInt   (q, 4)));
    j = JsonObjectSet(j, "forfeits",  JsonInt   (SqlGetInt   (q, 5)));
    j = JsonObjectSet(j, "kills",     JsonInt   (SqlGetInt   (q, 6)));
    return j;
}

void DuelAdjustHonor(string sUuid, string sName, int nDelta,
                     int bWin, int bLoss, int bDecline, int bForfeit, int bKill)
{
    // Ensure row exists.
    sqlquery qIns = SqlPrepareQueryCampaign(DUEL_DB,
        "INSERT OR IGNORE INTO duel_honor (uuid, char_name) VALUES (@uuid, @name)");
    SqlBindString(qIns, "@uuid", sUuid);
    SqlBindString(qIns, "@name", sName);
    SqlStep(qIns);

    sqlquery q = SqlPrepareQueryCampaign(DUEL_DB,
        "UPDATE duel_honor SET "
        "honor = honor + @delta, "
        "wins = wins + @w, "
        "losses = losses + @l, "
        "declined = declined + @d, "
        "forfeits = forfeits + @f, "
        "kills = kills + @k, "
        "char_name = @name "
        "WHERE uuid = @uuid");
    SqlBindString(q, "@uuid",  sUuid);
    SqlBindString(q, "@name",  sName);
    SqlBindInt   (q, "@delta", nDelta);
    SqlBindInt   (q, "@w",     bWin);
    SqlBindInt   (q, "@l",     bLoss);
    SqlBindInt   (q, "@d",     bDecline);
    SqlBindInt   (q, "@f",     bForfeit);
    SqlBindInt   (q, "@k",     bKill);
    SqlStep(q);
}

// ----------------------------------------------------------------
// Duel CRUD
// ----------------------------------------------------------------

int DuelCreate(object oChallenger, object oChallenged,
               int nRules, int nWinCond, int nStake)
{
    location lLoc = GetLocation(oChallenger);
    vector vPos  = GetPositionFromLocation(lLoc);

    sqlquery q = SqlPrepareQueryCampaign(DUEL_DB,
        "INSERT INTO duels (challenger_uuid, challenger_name, challenged_uuid, challenged_name, "
        "rules_mask, win_cond, stake_gold, status, arena_x, arena_y, arena_z, arena_area, created_at) "
        "VALUES (@cu, @cn, @du, @dn, @r, @w, @s, 0, @x, @y, @z, @area, strftime('%s','now'))");
    SqlBindString(q, "@cu",   GetObjectUUID(oChallenger));
    SqlBindString(q, "@cn",   GetName(oChallenger));
    SqlBindString(q, "@du",   GetObjectUUID(oChallenged));
    SqlBindString(q, "@dn",   GetName(oChallenged));
    SqlBindInt   (q, "@r",    nRules);
    SqlBindInt   (q, "@w",    nWinCond);
    SqlBindInt   (q, "@s",    nStake);
    SqlBindFloat (q, "@x",    vPos.x);
    SqlBindFloat (q, "@y",    vPos.y);
    SqlBindFloat (q, "@z",    vPos.z);
    SqlBindString(q, "@area", GetTag(GetAreaFromLocation(lLoc)));
    SqlStep(q);

    sqlquery qId = SqlPrepareQueryCampaign(DUEL_DB, "SELECT last_insert_rowid()");
    if(SqlStep(qId)) return SqlGetInt(qId, 0);
    return 0;
}

json DuelGetById(int nId)
{
    sqlquery q = SqlPrepareQueryCampaign(DUEL_DB,
        "SELECT id, challenger_uuid, challenger_name, challenged_uuid, challenged_name, "
        "rules_mask, win_cond, stake_gold, status, winner_uuid, loser_uuid, outcome_note, "
        "arena_x, arena_y, arena_z, arena_area, created_at, completed_at "
        "FROM duels WHERE id = @id");
    SqlBindInt(q, "@id", nId);
    if(!SqlStep(q)) return JsonNull();

    json j = JsonObject();
    j = JsonObjectSet(j, "id",              JsonInt   (SqlGetInt   (q,  0)));
    j = JsonObjectSet(j, "challenger_uuid", JsonString(SqlGetString(q,  1)));
    j = JsonObjectSet(j, "challenger_name", JsonString(SqlGetString(q,  2)));
    j = JsonObjectSet(j, "challenged_uuid", JsonString(SqlGetString(q,  3)));
    j = JsonObjectSet(j, "challenged_name", JsonString(SqlGetString(q,  4)));
    j = JsonObjectSet(j, "rules_mask",      JsonInt   (SqlGetInt   (q,  5)));
    j = JsonObjectSet(j, "win_cond",        JsonInt   (SqlGetInt   (q,  6)));
    j = JsonObjectSet(j, "stake_gold",      JsonInt   (SqlGetInt   (q,  7)));
    j = JsonObjectSet(j, "status",          JsonInt   (SqlGetInt   (q,  8)));
    j = JsonObjectSet(j, "winner_uuid",     JsonString(SqlGetString(q,  9)));
    j = JsonObjectSet(j, "loser_uuid",      JsonString(SqlGetString(q, 10)));
    j = JsonObjectSet(j, "outcome_note",    JsonString(SqlGetString(q, 11)));
    j = JsonObjectSet(j, "arena_x",         JsonFloat (SqlGetFloat (q, 12)));
    j = JsonObjectSet(j, "arena_y",         JsonFloat (SqlGetFloat (q, 13)));
    j = JsonObjectSet(j, "arena_z",         JsonFloat (SqlGetFloat (q, 14)));
    j = JsonObjectSet(j, "arena_area",      JsonString(SqlGetString(q, 15)));
    j = JsonObjectSet(j, "created_at",      JsonInt   (SqlGetInt   (q, 16)));
    j = JsonObjectSet(j, "completed_at",    JsonInt   (SqlGetInt   (q, 17)));
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

void DuelSetOutcome(int nId, int nStatus, string sWinnerUuid, string sLoserUuid, string sNote)
{
    sqlquery q = SqlPrepareQueryCampaign(DUEL_DB,
        "UPDATE duels SET status = @s, winner_uuid = @w, loser_uuid = @l, "
        "outcome_note = @n, completed_at = strftime('%s','now') WHERE id = @id");
    SqlBindInt   (q, "@s",  nStatus);
    SqlBindString(q, "@w",  sWinnerUuid);
    SqlBindString(q, "@l",  sLoserUuid);
    SqlBindString(q, "@n",  sNote);
    SqlBindInt   (q, "@id", nId);
    SqlStep(q);
}

void DuelExpireOld(int nTtlSeconds)
{
    sqlquery q = SqlPrepareQueryCampaign(DUEL_DB,
        "UPDATE duels SET status = 5, completed_at = strftime('%s','now') "
        "WHERE status = 0 AND created_at < strftime('%s','now') - @ttl");
    SqlBindInt(q, "@ttl", nTtlSeconds);
    SqlStep(q);
}

int DuelHasActiveBetween(string sA, string sB)
{
    sqlquery q = SqlPrepareQueryCampaign(DUEL_DB,
        "SELECT COUNT(*) FROM duels WHERE status IN (0,1,2) AND "
        "((challenger_uuid = @a AND challenged_uuid = @b) OR "
        " (challenger_uuid = @b AND challenged_uuid = @a))");
    SqlBindString(q, "@a", sA);
    SqlBindString(q, "@b", sB);
    if(SqlStep(q)) return SqlGetInt(q, 0);
    return 0;
}

int DuelHasAnyActive(string sUuid)
{
    sqlquery q = SqlPrepareQueryCampaign(DUEL_DB,
        "SELECT id FROM duels WHERE status IN (1,2) AND "
        "(challenger_uuid = @u OR challenged_uuid = @u) LIMIT 1");
    SqlBindString(q, "@u", sUuid);
    if(SqlStep(q)) return SqlGetInt(q, 0);
    return 0;
}

// Returns array of pending challenges TO this PC: [{id, challenger_name, rules_mask, win_cond, stake_gold, created_at}, ...]
json DuelGetIncoming(string sUuid)
{
    json jRows = JsonArray();
    sqlquery q = SqlPrepareQueryCampaign(DUEL_DB,
        "SELECT id, challenger_name, challenger_uuid, rules_mask, win_cond, stake_gold, created_at, status "
        "FROM duels WHERE status IN (0,1) AND challenged_uuid = @u ORDER BY created_at DESC");
    SqlBindString(q, "@u", sUuid);
    while(SqlStep(q))
    {
        json j = JsonObject();
        j = JsonObjectSet(j, "id",               JsonInt   (SqlGetInt   (q, 0)));
        j = JsonObjectSet(j, "challenger_name",  JsonString(SqlGetString(q, 1)));
        j = JsonObjectSet(j, "challenger_uuid",  JsonString(SqlGetString(q, 2)));
        j = JsonObjectSet(j, "rules_mask",       JsonInt   (SqlGetInt   (q, 3)));
        j = JsonObjectSet(j, "win_cond",         JsonInt   (SqlGetInt   (q, 4)));
        j = JsonObjectSet(j, "stake_gold",       JsonInt   (SqlGetInt   (q, 5)));
        j = JsonObjectSet(j, "created_at",       JsonInt   (SqlGetInt   (q, 6)));
        j = JsonObjectSet(j, "status",           JsonInt   (SqlGetInt   (q, 7)));
        j = JsonObjectSet(j, "direction",        JsonString("in"));
        jRows = JsonArrayInsert(jRows, j);
    }

    // Also include outgoing pending challenges so the user can cancel them.
    q = SqlPrepareQueryCampaign(DUEL_DB,
        "SELECT id, challenged_name, challenged_uuid, rules_mask, win_cond, stake_gold, created_at, status "
        "FROM duels WHERE status = 0 AND challenger_uuid = @u ORDER BY created_at DESC");
    SqlBindString(q, "@u", sUuid);
    while(SqlStep(q))
    {
        json j = JsonObject();
        j = JsonObjectSet(j, "id",               JsonInt   (SqlGetInt   (q, 0)));
        j = JsonObjectSet(j, "challenger_name",  JsonString(SqlGetString(q, 1)));
        j = JsonObjectSet(j, "challenger_uuid",  JsonString(SqlGetString(q, 2)));
        j = JsonObjectSet(j, "rules_mask",       JsonInt   (SqlGetInt   (q, 3)));
        j = JsonObjectSet(j, "win_cond",         JsonInt   (SqlGetInt   (q, 4)));
        j = JsonObjectSet(j, "stake_gold",       JsonInt   (SqlGetInt   (q, 5)));
        j = JsonObjectSet(j, "created_at",       JsonInt   (SqlGetInt   (q, 6)));
        j = JsonObjectSet(j, "status",           JsonInt   (SqlGetInt   (q, 7)));
        j = JsonObjectSet(j, "direction",        JsonString("out"));
        jRows = JsonArrayInsert(jRows, j);
    }
    return jRows;
}

json DuelGetHistory(string sUuid, int nLimit)
{
    json jRows = JsonArray();
    sqlquery q = SqlPrepareQueryCampaign(DUEL_DB,
        "SELECT id, challenger_uuid, challenger_name, challenged_uuid, challenged_name, "
        "winner_uuid, status, win_cond, rules_mask, stake_gold, completed_at, outcome_note "
        "FROM duels WHERE status IN (3,4,5,6) AND "
        "(challenger_uuid = @u OR challenged_uuid = @u) "
        "ORDER BY COALESCE(completed_at, created_at) DESC LIMIT @lim");
    SqlBindString(q, "@u",   sUuid);
    SqlBindInt   (q, "@lim", nLimit);
    while(SqlStep(q))
    {
        json j = JsonObject();
        j = JsonObjectSet(j, "id",              JsonInt   (SqlGetInt   (q,  0)));
        j = JsonObjectSet(j, "challenger_uuid", JsonString(SqlGetString(q,  1)));
        j = JsonObjectSet(j, "challenger_name", JsonString(SqlGetString(q,  2)));
        j = JsonObjectSet(j, "challenged_uuid", JsonString(SqlGetString(q,  3)));
        j = JsonObjectSet(j, "challenged_name", JsonString(SqlGetString(q,  4)));
        j = JsonObjectSet(j, "winner_uuid",     JsonString(SqlGetString(q,  5)));
        j = JsonObjectSet(j, "status",          JsonInt   (SqlGetInt   (q,  6)));
        j = JsonObjectSet(j, "win_cond",        JsonInt   (SqlGetInt   (q,  7)));
        j = JsonObjectSet(j, "rules_mask",      JsonInt   (SqlGetInt   (q,  8)));
        j = JsonObjectSet(j, "stake_gold",      JsonInt   (SqlGetInt   (q,  9)));
        j = JsonObjectSet(j, "completed_at",    JsonInt   (SqlGetInt   (q, 10)));
        j = JsonObjectSet(j, "outcome_note",    JsonString(SqlGetString(q, 11)));
        jRows = JsonArrayInsert(jRows, j);
    }
    return jRows;
}

json DuelGetRanking(int nLimit)
{
    json jRows = JsonArray();
    sqlquery q = SqlPrepareQueryCampaign(DUEL_DB,
        "SELECT char_name, honor, wins, losses, kills FROM duel_honor "
        "WHERE wins + losses + forfeits > 0 ORDER BY honor DESC, wins DESC LIMIT @lim");
    SqlBindInt(q, "@lim", nLimit);
    while(SqlStep(q))
    {
        json j = JsonObject();
        j = JsonObjectSet(j, "char_name", JsonString(SqlGetString(q, 0)));
        j = JsonObjectSet(j, "honor",     JsonInt   (SqlGetInt   (q, 1)));
        j = JsonObjectSet(j, "wins",      JsonInt   (SqlGetInt   (q, 2)));
        j = JsonObjectSet(j, "losses",    JsonInt   (SqlGetInt   (q, 3)));
        j = JsonObjectSet(j, "kills",     JsonInt   (SqlGetInt   (q, 4)));
        jRows = JsonArrayInsert(jRows, j);
    }
    return jRows;
}

string DuelFormatDateSQL(int nUnix)
{
    sqlquery q = SqlPrepareQueryCampaign(DUEL_DB,
        "SELECT strftime('%d.%m %H:%M', @ts, 'unixepoch')");
    SqlBindInt(q, "@ts", nUnix);
    if(SqlStep(q)) return SqlGetString(q, 0);
    return "";
}
