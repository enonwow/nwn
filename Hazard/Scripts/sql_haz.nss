// sql_haz.nss — SQLite schema + queries for Hazard module

void HazCreateTables()
{
    sqlquery q = SqlPrepareQueryCampaign("haz",
        "CREATE TABLE IF NOT EXISTS haz_players ("
        " uuid       TEXT PRIMARY KEY,"
        " char_name  TEXT NOT NULL DEFAULT '',"
        " wins       INTEGER NOT NULL DEFAULT 0,"
        " losses     INTEGER NOT NULL DEFAULT 0,"
        " pushes     INTEGER NOT NULL DEFAULT 0,"
        " gold_won   INTEGER NOT NULL DEFAULT 0,"
        " gold_lost  INTEGER NOT NULL DEFAULT 0"
        ")");
    SqlStep(q);
}

void HazRegisterPlayer(object oPC)
{
    sqlquery q = SqlPrepareQueryCampaign("haz",
        "INSERT OR IGNORE INTO haz_players (uuid, char_name) VALUES (@uuid, @name)");
    SqlBindString(q, "@uuid", GetObjectUUID(oPC));
    SqlBindString(q, "@name", GetName(oPC));
    SqlStep(q);

    q = SqlPrepareQueryCampaign("haz",
        "UPDATE haz_players SET char_name = @name WHERE uuid = @uuid");
    SqlBindString(q, "@name", GetName(oPC));
    SqlBindString(q, "@uuid", GetObjectUUID(oPC));
    SqlStep(q);
}

void HazRecordWin(object oPC, int nGold)
{
    sqlquery q = SqlPrepareQueryCampaign("haz",
        "UPDATE haz_players SET wins = wins + 1, gold_won = gold_won + @g WHERE uuid = @uuid");
    SqlBindInt   (q, "@g",    nGold);
    SqlBindString(q, "@uuid", GetObjectUUID(oPC));
    SqlStep(q);
}

void HazRecordLoss(object oPC, int nGold)
{
    sqlquery q = SqlPrepareQueryCampaign("haz",
        "UPDATE haz_players SET losses = losses + 1, gold_lost = gold_lost + @g WHERE uuid = @uuid");
    SqlBindInt   (q, "@g",    nGold);
    SqlBindString(q, "@uuid", GetObjectUUID(oPC));
    SqlStep(q);
}

void HazRecordPush(object oPC)
{
    sqlquery q = SqlPrepareQueryCampaign("haz",
        "UPDATE haz_players SET pushes = pushes + 1 WHERE uuid = @uuid");
    SqlBindString(q, "@uuid", GetObjectUUID(oPC));
    SqlStep(q);
}

// Returns {wins, losses, pushes, gold_won, gold_lost} or empty object if unknown player
json HazGetStats(object oPC)
{
    sqlquery q = SqlPrepareQueryCampaign("haz",
        "SELECT wins, losses, pushes, gold_won, gold_lost"
        " FROM haz_players WHERE uuid = @uuid");
    SqlBindString(q, "@uuid", GetObjectUUID(oPC));
    json jStats = JsonObject();
    if(SqlStep(q))
    {
        jStats = JsonObjectSet(jStats, "wins",      JsonInt(SqlGetInt(q, 0)));
        jStats = JsonObjectSet(jStats, "losses",    JsonInt(SqlGetInt(q, 1)));
        jStats = JsonObjectSet(jStats, "pushes",    JsonInt(SqlGetInt(q, 2)));
        jStats = JsonObjectSet(jStats, "gold_won",  JsonInt(SqlGetInt(q, 3)));
        jStats = JsonObjectSet(jStats, "gold_lost", JsonInt(SqlGetInt(q, 4)));
    }
    return jStats;
}

// Returns JsonArray [{name, wins, losses, balance}, ...] — top 5 by wins
json HazGetLeaderboard()
{
    json jRows = JsonArray();
    sqlquery q = SqlPrepareQueryCampaign("haz",
        "SELECT char_name, wins, losses, gold_won - gold_lost AS balance"
        " FROM haz_players"
        " ORDER BY wins DESC, balance DESC"
        " LIMIT 5");
    while(SqlStep(q))
    {
        json jRow = JsonObject();
        jRow = JsonObjectSet(jRow, "name",    JsonString(SqlGetString(q, 0)));
        jRow = JsonObjectSet(jRow, "wins",    JsonInt   (SqlGetInt   (q, 1)));
        jRow = JsonObjectSet(jRow, "losses",  JsonInt   (SqlGetInt   (q, 2)));
        jRow = JsonObjectSet(jRow, "balance", JsonInt   (SqlGetInt   (q, 3)));
        jRows = JsonArrayInsert(jRows, jRow);
    }
    return jRows;
}
