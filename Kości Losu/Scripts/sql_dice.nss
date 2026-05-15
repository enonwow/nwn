// sql_dice.nss — SQLite schema and queries for Kości Losu

void DiceCreateTables()
{
    sqlquery q = SqlPrepareQueryCampaign("dice",
        "CREATE TABLE IF NOT EXISTS dice_records ("
        "  uuid        TEXT PRIMARY KEY,"
        "  char_name   TEXT    DEFAULT '',"
        "  wins        INTEGER DEFAULT 0,"
        "  losses      INTEGER DEFAULT 0,"
        "  gold_won    INTEGER DEFAULT 0,"
        "  gold_lost   INTEGER DEFAULT 0,"
        "  best_hand   INTEGER DEFAULT 0,"
        "  streak_best INTEGER DEFAULT 0"
        ")");
    SqlStep(q);

    // Single-row jackpot pool seeded at 200 gp
    q = SqlPrepareQueryCampaign("dice",
        "CREATE TABLE IF NOT EXISTS dice_jackpot (id INTEGER PRIMARY KEY, amount INTEGER DEFAULT 200)");
    SqlStep(q);

    q = SqlPrepareQueryCampaign("dice",
        "INSERT OR IGNORE INTO dice_jackpot (id, amount) VALUES (1, 200)");
    SqlStep(q);
}

void DiceRegisterPlayer(object oPC)
{
    sqlquery q = SqlPrepareQueryCampaign("dice",
        "INSERT OR IGNORE INTO dice_records (uuid, char_name) VALUES (@uuid, @name)");
    SqlBindString(q, "@uuid", GetObjectUUID(oPC));
    SqlBindString(q, "@name", GetName(oPC));
    SqlStep(q);

    // Always refresh char_name in case of rename
    q = SqlPrepareQueryCampaign("dice",
        "UPDATE dice_records SET char_name = @name WHERE uuid = @uuid");
    SqlBindString(q, "@name", GetName(oPC));
    SqlBindString(q, "@uuid", GetObjectUUID(oPC));
    SqlStep(q);
}

// nGoldDelta: positive = won, negative = lost
void DiceUpdateRecord(object oPC, int bWon, int nGoldDelta, int nHandRank, int nStreak)
{
    sqlquery q = SqlPrepareQueryCampaign("dice",
        "UPDATE dice_records SET"
        "  wins       = wins       + @w,"
        "  losses     = losses     + @l,"
        "  gold_won   = gold_won   + @gw,"
        "  gold_lost  = gold_lost  + @gl,"
        "  best_hand  = MAX(best_hand, @bh),"
        "  streak_best= MAX(streak_best, @sb)"
        " WHERE uuid = @uuid");
    SqlBindInt   (q, "@w",    bWon ? 1 : 0);
    SqlBindInt   (q, "@l",    bWon ? 0 : 1);
    SqlBindInt   (q, "@gw",   nGoldDelta > 0 ? nGoldDelta : 0);
    SqlBindInt   (q, "@gl",   nGoldDelta < 0 ? -nGoldDelta : 0);
    SqlBindInt   (q, "@bh",   nHandRank);
    SqlBindInt   (q, "@sb",   nStreak > 0 ? nStreak : 0);
    SqlBindString(q, "@uuid", GetObjectUUID(oPC));
    SqlStep(q);
}

// Returns json object: {wins, losses, gold_won, gold_lost, best_hand, streak_best}
json DiceGetRecord(object oPC)
{
    sqlquery q = SqlPrepareQueryCampaign("dice",
        "SELECT wins, losses, gold_won, gold_lost, best_hand, streak_best"
        " FROM dice_records WHERE uuid = @uuid");
    SqlBindString(q, "@uuid", GetObjectUUID(oPC));
    if(!SqlStep(q)) return JsonNull();

    json j = JsonObject();
    j = JsonObjectSet(j, "wins",        JsonInt(SqlGetInt(q, 0)));
    j = JsonObjectSet(j, "losses",      JsonInt(SqlGetInt(q, 1)));
    j = JsonObjectSet(j, "gold_won",    JsonInt(SqlGetInt(q, 2)));
    j = JsonObjectSet(j, "gold_lost",   JsonInt(SqlGetInt(q, 3)));
    j = JsonObjectSet(j, "best_hand",   JsonInt(SqlGetInt(q, 4)));
    j = JsonObjectSet(j, "streak_best", JsonInt(SqlGetInt(q, 5)));
    return j;
}

// Returns JsonArray of top players: [{char_name, wins, losses, gold_net}, ...]
json DiceGetLeaderboard(int nLimit)
{
    json jRows = JsonArray();
    sqlquery q = SqlPrepareQueryCampaign("dice",
        "SELECT char_name, wins, losses, (gold_won - gold_lost) AS gold_net"
        " FROM dice_records"
        " ORDER BY gold_net DESC, wins DESC"
        " LIMIT @lim");
    SqlBindInt(q, "@lim", nLimit);
    while(SqlStep(q))
    {
        json jRow = JsonObject();
        jRow = JsonObjectSet(jRow, "char_name", JsonString(SqlGetString(q, 0)));
        jRow = JsonObjectSet(jRow, "wins",      JsonInt   (SqlGetInt   (q, 1)));
        jRow = JsonObjectSet(jRow, "losses",    JsonInt   (SqlGetInt   (q, 2)));
        jRow = JsonObjectSet(jRow, "gold_net",  JsonInt   (SqlGetInt   (q, 3)));
        jRows = JsonArrayInsert(jRows, jRow);
    }
    return jRows;
}

int DiceGetJackpot()
{
    sqlquery q = SqlPrepareQueryCampaign("dice",
        "SELECT amount FROM dice_jackpot WHERE id = 1");
    if(SqlStep(q)) return SqlGetInt(q, 0);
    return 200;
}

void DiceAddToJackpot(int nAmount)
{
    sqlquery q = SqlPrepareQueryCampaign("dice",
        "UPDATE dice_jackpot SET amount = amount + @a WHERE id = 1");
    SqlBindInt(q, "@a", nAmount);
    SqlStep(q);
}

void DiceResetJackpot()
{
    sqlquery q = SqlPrepareQueryCampaign("dice",
        "UPDATE dice_jackpot SET amount = 200 WHERE id = 1");
    SqlStep(q);
}
