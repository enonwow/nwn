// Campaign database name used for all arena queries.
const string ARENA_DB = "arena";

void ArenaCreateTables()
{
    sqlquery q = SqlPrepareQueryCampaign(ARENA_DB,
        "CREATE TABLE IF NOT EXISTS arena_fighters ("
        "uuid         TEXT PRIMARY KEY, "
        "char_name    TEXT    DEFAULT '', "
        "total_wins   INTEGER DEFAULT 0, "
        "total_losses INTEGER DEFAULT 0, "
        "best_league  INTEGER DEFAULT 1, "
        "infamy       INTEGER DEFAULT 0, "
        "last_fought  INTEGER DEFAULT 0)");
    SqlStep(q);
}

void ArenaRegisterFighter(object oPC)
{
    string sUuid = GetObjectUUID(oPC);
    string sName = GetName(oPC);

    sqlquery q = SqlPrepareQueryCampaign(ARENA_DB,
        "INSERT OR IGNORE INTO arena_fighters (uuid, char_name) VALUES (@uuid, @name)");
    SqlBindString(q, "@uuid", sUuid);
    SqlBindString(q, "@name", sName);
    SqlStep(q);

    // Keep display name fresh (character renames, etc.)
    q = SqlPrepareQueryCampaign(ARENA_DB,
        "UPDATE arena_fighters SET char_name = @name WHERE uuid = @uuid");
    SqlBindString(q, "@name", sName);
    SqlBindString(q, "@uuid", sUuid);
    SqlStep(q);
}

// Returns JsonObject with keys total_wins, total_losses, best_league, infamy.
// Returns JsonNull() if the fighter is not registered yet.
json ArenaGetFighter(string sUuid)
{
    sqlquery q = SqlPrepareQueryCampaign(ARENA_DB,
        "SELECT total_wins, total_losses, best_league, infamy "
        "FROM arena_fighters WHERE uuid = @uuid");
    SqlBindString(q, "@uuid", sUuid);
    if(!SqlStep(q)) return JsonNull();

    json j = JsonObject();
    j = JsonObjectSet(j, "total_wins",   JsonInt(SqlGetInt(q, 0)));
    j = JsonObjectSet(j, "total_losses", JsonInt(SqlGetInt(q, 1)));
    j = JsonObjectSet(j, "best_league",  JsonInt(SqlGetInt(q, 2)));
    j = JsonObjectSet(j, "infamy",       JsonInt(SqlGetInt(q, 3)));
    return j;
}

void ArenaRecordWin(string sUuid, int nLeague, int nInfGain)
{
    sqlquery q = SqlPrepareQueryCampaign(ARENA_DB,
        "UPDATE arena_fighters SET "
        "total_wins  = total_wins + 1, "
        "infamy      = infamy + @inf, "
        "best_league = MAX(best_league, @league), "
        "last_fought = strftime('%s','now') "
        "WHERE uuid = @uuid");
    SqlBindInt   (q, "@inf",    nInfGain);
    SqlBindInt   (q, "@league", nLeague);
    SqlBindString(q, "@uuid",   sUuid);
    SqlStep(q);
}

void ArenaRecordLoss(string sUuid, int nInfPenalty)
{
    sqlquery q = SqlPrepareQueryCampaign(ARENA_DB,
        "UPDATE arena_fighters SET "
        "total_losses = total_losses + 1, "
        "infamy       = MAX(0, infamy - @pen), "
        "last_fought  = strftime('%s','now') "
        "WHERE uuid = @uuid");
    SqlBindInt   (q, "@pen",  nInfPenalty);
    SqlBindString(q, "@uuid", sUuid);
    SqlStep(q);
}

// Returns JsonArray of top-nLimit fighters ordered by infamy desc.
// Each element: {rank, char_name, best_league, total_wins, total_losses, infamy}
json ArenaGetLeaderboard(int nLimit)
{
    json jBoard = JsonArray();
    sqlquery q = SqlPrepareQueryCampaign(ARENA_DB,
        "SELECT char_name, best_league, total_wins, total_losses, infamy "
        "FROM arena_fighters "
        "ORDER BY infamy DESC, total_wins DESC "
        "LIMIT @n");
    SqlBindInt(q, "@n", nLimit);

    int nRank = 1;
    while(SqlStep(q))
    {
        json jRow = JsonObject();
        jRow = JsonObjectSet(jRow, "rank",         JsonInt   (nRank));
        jRow = JsonObjectSet(jRow, "char_name",    JsonString(SqlGetString(q, 0)));
        jRow = JsonObjectSet(jRow, "best_league",  JsonInt   (SqlGetInt   (q, 1)));
        jRow = JsonObjectSet(jRow, "total_wins",   JsonInt   (SqlGetInt   (q, 2)));
        jRow = JsonObjectSet(jRow, "total_losses", JsonInt   (SqlGetInt   (q, 3)));
        jRow = JsonObjectSet(jRow, "infamy",       JsonInt   (SqlGetInt   (q, 4)));
        jBoard = JsonArrayInsert(jBoard, jRow);
        nRank++;
    }
    return jBoard;
}

// Returns position of sUuid in the leaderboard (1-based), 0 if not found.
int ArenaGetRank(string sUuid)
{
    sqlquery q = SqlPrepareQueryCampaign(ARENA_DB,
        "SELECT COUNT(*) FROM arena_fighters f2 "
        "JOIN arena_fighters f1 ON f1.uuid = @uuid "
        "WHERE f2.infamy > f1.infamy OR (f2.infamy = f1.infamy AND f2.total_wins > f1.total_wins)");
    SqlBindString(q, "@uuid", sUuid);
    if(SqlStep(q)) return SqlGetInt(q, 0) + 1;
    return 0;
}
