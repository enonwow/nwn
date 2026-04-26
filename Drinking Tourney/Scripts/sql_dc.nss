// Drinking Tournament — persistence (campaign DB "dc")

const string DC_DB = "dc";

void DcCreateTables()
{
    sqlquery q = SqlPrepareQueryCampaign(DC_DB,
        "CREATE TABLE IF NOT EXISTS dc_tournaments ("
        "id INTEGER PRIMARY KEY AUTOINCREMENT, "
        "creator_uuid TEXT NOT NULL, "
        "creator_name TEXT DEFAULT '', "
        "size INTEGER NOT NULL, "
        "entry_fee INTEGER DEFAULT 0, "
        "status INTEGER DEFAULT 0, "
        "winner_uuid TEXT DEFAULT '', "
        "winner_name TEXT DEFAULT '', "
        "prize_pool INTEGER DEFAULT 0, "
        "created_at INTEGER DEFAULT 0, "
        "finished_at INTEGER DEFAULT 0)");
    SqlStep(q);

    q = SqlPrepareQueryCampaign(DC_DB,
        "CREATE TABLE IF NOT EXISTS dc_entries ("
        "id INTEGER PRIMARY KEY AUTOINCREMENT, "
        "tournament_id INTEGER NOT NULL, "
        "pc_uuid TEXT NOT NULL, "
        "pc_name TEXT DEFAULT '', "
        "seat INTEGER NOT NULL, "
        "joined_at INTEGER DEFAULT 0, "
        "eliminated INTEGER DEFAULT 0)");
    SqlStep(q);

    q = SqlPrepareQueryCampaign(DC_DB,
        "CREATE TABLE IF NOT EXISTS dc_matches ("
        "id INTEGER PRIMARY KEY AUTOINCREMENT, "
        "tournament_id INTEGER NOT NULL, "
        "round_idx INTEGER NOT NULL, "
        "match_idx INTEGER NOT NULL, "
        "a_uuid TEXT DEFAULT '', "
        "a_name TEXT DEFAULT '', "
        "b_uuid TEXT DEFAULT '', "
        "b_name TEXT DEFAULT '', "
        "winner_uuid TEXT DEFAULT '', "
        "winner_name TEXT DEFAULT '', "
        "shots_played INTEGER DEFAULT 0, "
        "status INTEGER DEFAULT 0, "
        "resolved_at INTEGER DEFAULT 0)");
    SqlStep(q);

    q = SqlPrepareQueryCampaign(DC_DB,
        "CREATE INDEX IF NOT EXISTS idx_dc_entries_t "
        "ON dc_entries(tournament_id, seat)");
    SqlStep(q);

    q = SqlPrepareQueryCampaign(DC_DB,
        "CREATE INDEX IF NOT EXISTS idx_dc_matches_t "
        "ON dc_matches(tournament_id, round_idx, match_idx)");
    SqlStep(q);
}

int DcCreateTournament(object oCreator, int nSize, int nFee)
{
    sqlquery q = SqlPrepareQueryCampaign(DC_DB,
        "INSERT INTO dc_tournaments (creator_uuid, creator_name, size, entry_fee, "
        "status, created_at) VALUES (@cu, @cn, @s, @f, 0, strftime('%s','now'))");
    SqlBindString(q, "@cu", GetObjectUUID(oCreator));
    SqlBindString(q, "@cn", GetName(oCreator));
    SqlBindInt   (q, "@s",  nSize);
    SqlBindInt   (q, "@f",  nFee);
    SqlStep(q);

    sqlquery qId = SqlPrepareQueryCampaign(DC_DB, "SELECT last_insert_rowid()");
    if(SqlStep(qId)) return SqlGetInt(qId, 0);
    return 0;
}

json DcGetTournament(int nId)
{
    sqlquery q = SqlPrepareQueryCampaign(DC_DB,
        "SELECT id, creator_uuid, creator_name, size, entry_fee, status, "
        "winner_uuid, winner_name, prize_pool, created_at, finished_at "
        "FROM dc_tournaments WHERE id = @id");
    SqlBindInt(q, "@id", nId);
    if(!SqlStep(q)) return JsonNull();
    json j = JsonObject();
    j = JsonObjectSet(j, "id",            JsonInt   (SqlGetInt   (q, 0)));
    j = JsonObjectSet(j, "creator_uuid",  JsonString(SqlGetString(q, 1)));
    j = JsonObjectSet(j, "creator_name",  JsonString(SqlGetString(q, 2)));
    j = JsonObjectSet(j, "size",          JsonInt   (SqlGetInt   (q, 3)));
    j = JsonObjectSet(j, "entry_fee",     JsonInt   (SqlGetInt   (q, 4)));
    j = JsonObjectSet(j, "status",        JsonInt   (SqlGetInt   (q, 5)));
    j = JsonObjectSet(j, "winner_uuid",   JsonString(SqlGetString(q, 6)));
    j = JsonObjectSet(j, "winner_name",   JsonString(SqlGetString(q, 7)));
    j = JsonObjectSet(j, "prize_pool",    JsonInt   (SqlGetInt   (q, 8)));
    j = JsonObjectSet(j, "created_at",    JsonInt   (SqlGetInt   (q, 9)));
    j = JsonObjectSet(j, "finished_at",   JsonInt   (SqlGetInt   (q, 10)));
    return j;
}

int DcCountEntries(int nTournamentId)
{
    sqlquery q = SqlPrepareQueryCampaign(DC_DB,
        "SELECT COUNT(*) FROM dc_entries WHERE tournament_id = @t");
    SqlBindInt(q, "@t", nTournamentId);
    if(SqlStep(q)) return SqlGetInt(q, 0);
    return 0;
}

int DcIsEntered(int nTournamentId, string sUuid)
{
    sqlquery q = SqlPrepareQueryCampaign(DC_DB,
        "SELECT COUNT(*) FROM dc_entries WHERE tournament_id = @t AND pc_uuid = @u");
    SqlBindInt   (q, "@t", nTournamentId);
    SqlBindString(q, "@u", sUuid);
    if(SqlStep(q)) return SqlGetInt(q, 0) > 0;
    return 0;
}

void DcAddEntry(int nTournamentId, object oPC, int nSeat)
{
    sqlquery q = SqlPrepareQueryCampaign(DC_DB,
        "INSERT INTO dc_entries (tournament_id, pc_uuid, pc_name, seat, joined_at) "
        "VALUES (@t, @u, @n, @s, strftime('%s','now'))");
    SqlBindInt   (q, "@t", nTournamentId);
    SqlBindString(q, "@u", GetObjectUUID(oPC));
    SqlBindString(q, "@n", GetName(oPC));
    SqlBindInt   (q, "@s", nSeat);
    SqlStep(q);
}

json DcGetEntries(int nTournamentId)
{
    json jRows = JsonArray();
    sqlquery q = SqlPrepareQueryCampaign(DC_DB,
        "SELECT seat, pc_uuid, pc_name, eliminated FROM dc_entries "
        "WHERE tournament_id = @t ORDER BY seat ASC");
    SqlBindInt(q, "@t", nTournamentId);
    while(SqlStep(q))
    {
        json j = JsonObject();
        j = JsonObjectSet(j, "seat",       JsonInt   (SqlGetInt   (q, 0)));
        j = JsonObjectSet(j, "uuid",       JsonString(SqlGetString(q, 1)));
        j = JsonObjectSet(j, "name",       JsonString(SqlGetString(q, 2)));
        j = JsonObjectSet(j, "eliminated", JsonInt   (SqlGetInt   (q, 3)));
        jRows = JsonArrayInsert(jRows, j);
    }
    return jRows;
}

void DcSetTournamentStatus(int nId, int nStatus, int nPrizePool)
{
    sqlquery q = SqlPrepareQueryCampaign(DC_DB,
        "UPDATE dc_tournaments SET status = @s, prize_pool = @p WHERE id = @id");
    SqlBindInt(q, "@s",  nStatus);
    SqlBindInt(q, "@p",  nPrizePool);
    SqlBindInt(q, "@id", nId);
    SqlStep(q);
}

void DcSetWinner(int nId, string sUuid, string sName, int nPrize)
{
    sqlquery q = SqlPrepareQueryCampaign(DC_DB,
        "UPDATE dc_tournaments SET status = 2, winner_uuid = @u, winner_name = @n, "
        "prize_pool = @p, finished_at = strftime('%s','now') WHERE id = @id");
    SqlBindString(q, "@u", sUuid);
    SqlBindString(q, "@n", sName);
    SqlBindInt   (q, "@p", nPrize);
    SqlBindInt   (q, "@id", nId);
    SqlStep(q);
}

void DcMarkEliminated(int nTournamentId, string sUuid)
{
    sqlquery q = SqlPrepareQueryCampaign(DC_DB,
        "UPDATE dc_entries SET eliminated = 1 "
        "WHERE tournament_id = @t AND pc_uuid = @u");
    SqlBindInt   (q, "@t", nTournamentId);
    SqlBindString(q, "@u", sUuid);
    SqlStep(q);
}

int DcCreateMatch(int nTournamentId, int nRoundIdx, int nMatchIdx,
                  string sAUuid, string sAName, string sBUuid, string sBName)
{
    sqlquery q = SqlPrepareQueryCampaign(DC_DB,
        "INSERT INTO dc_matches (tournament_id, round_idx, match_idx, "
        "a_uuid, a_name, b_uuid, b_name) VALUES (@t, @r, @m, @au, @an, @bu, @bn)");
    SqlBindInt   (q, "@t",  nTournamentId);
    SqlBindInt   (q, "@r",  nRoundIdx);
    SqlBindInt   (q, "@m",  nMatchIdx);
    SqlBindString(q, "@au", sAUuid);
    SqlBindString(q, "@an", sAName);
    SqlBindString(q, "@bu", sBUuid);
    SqlBindString(q, "@bn", sBName);
    SqlStep(q);
    sqlquery qId = SqlPrepareQueryCampaign(DC_DB, "SELECT last_insert_rowid()");
    if(SqlStep(qId)) return SqlGetInt(qId, 0);
    return 0;
}

void DcResolveMatch(int nMatchId, string sWinnerUuid, string sWinnerName, int nShotsPlayed)
{
    sqlquery q = SqlPrepareQueryCampaign(DC_DB,
        "UPDATE dc_matches SET winner_uuid = @u, winner_name = @n, "
        "shots_played = @s, status = 1, resolved_at = strftime('%s','now') WHERE id = @id");
    SqlBindString(q, "@u",  sWinnerUuid);
    SqlBindString(q, "@n",  sWinnerName);
    SqlBindInt   (q, "@s",  nShotsPlayed);
    SqlBindInt   (q, "@id", nMatchId);
    SqlStep(q);
}

json DcGetMatchesForRound(int nTournamentId, int nRoundIdx)
{
    json jRows = JsonArray();
    sqlquery q = SqlPrepareQueryCampaign(DC_DB,
        "SELECT id, match_idx, a_uuid, a_name, b_uuid, b_name, "
        "winner_uuid, winner_name, shots_played, status "
        "FROM dc_matches WHERE tournament_id = @t AND round_idx = @r "
        "ORDER BY match_idx ASC");
    SqlBindInt(q, "@t", nTournamentId);
    SqlBindInt(q, "@r", nRoundIdx);
    while(SqlStep(q))
    {
        json j = JsonObject();
        j = JsonObjectSet(j, "id",            JsonInt   (SqlGetInt   (q, 0)));
        j = JsonObjectSet(j, "match_idx",     JsonInt   (SqlGetInt   (q, 1)));
        j = JsonObjectSet(j, "a_uuid",        JsonString(SqlGetString(q, 2)));
        j = JsonObjectSet(j, "a_name",        JsonString(SqlGetString(q, 3)));
        j = JsonObjectSet(j, "b_uuid",        JsonString(SqlGetString(q, 4)));
        j = JsonObjectSet(j, "b_name",        JsonString(SqlGetString(q, 5)));
        j = JsonObjectSet(j, "winner_uuid",   JsonString(SqlGetString(q, 6)));
        j = JsonObjectSet(j, "winner_name",   JsonString(SqlGetString(q, 7)));
        j = JsonObjectSet(j, "shots_played",  JsonInt   (SqlGetInt   (q, 8)));
        j = JsonObjectSet(j, "status",        JsonInt   (SqlGetInt   (q, 9)));
        jRows = JsonArrayInsert(jRows, j);
    }
    return jRows;
}

json DcListByStatus(int nStatus, int nLimit)
{
    json jRows = JsonArray();
    sqlquery q = SqlPrepareQueryCampaign(DC_DB,
        "SELECT id, creator_name, size, entry_fee, status, prize_pool, "
        "winner_name, created_at, finished_at "
        "FROM dc_tournaments WHERE status = @s "
        "ORDER BY COALESCE(finished_at, created_at) DESC LIMIT @lim");
    SqlBindInt(q, "@s",   nStatus);
    SqlBindInt(q, "@lim", nLimit);
    while(SqlStep(q))
    {
        json j = JsonObject();
        j = JsonObjectSet(j, "id",            JsonInt   (SqlGetInt   (q, 0)));
        j = JsonObjectSet(j, "creator_name",  JsonString(SqlGetString(q, 1)));
        j = JsonObjectSet(j, "size",          JsonInt   (SqlGetInt   (q, 2)));
        j = JsonObjectSet(j, "entry_fee",     JsonInt   (SqlGetInt   (q, 3)));
        j = JsonObjectSet(j, "status",        JsonInt   (SqlGetInt   (q, 4)));
        j = JsonObjectSet(j, "prize_pool",    JsonInt   (SqlGetInt   (q, 5)));
        j = JsonObjectSet(j, "winner_name",   JsonString(SqlGetString(q, 6)));
        j = JsonObjectSet(j, "created_at",    JsonInt   (SqlGetInt   (q, 7)));
        j = JsonObjectSet(j, "finished_at",   JsonInt   (SqlGetInt   (q, 8)));
        jRows = JsonArrayInsert(jRows, j);
    }
    return jRows;
}

int DcGetActiveTournamentForPC(string sUuid)
{
    sqlquery q = SqlPrepareQueryCampaign(DC_DB,
        "SELECT t.id FROM dc_tournaments t JOIN dc_entries e ON e.tournament_id = t.id "
        "WHERE e.pc_uuid = @u AND t.status IN (0,1) ORDER BY t.id DESC LIMIT 1");
    SqlBindString(q, "@u", sUuid);
    if(SqlStep(q)) return SqlGetInt(q, 0);
    return 0;
}
