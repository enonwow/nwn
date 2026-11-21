// Divination - persistence (campaign DB "divination")

const string DIV_DB = "divination";

void DivInitTables()
{
    sqlquery q = SqlPrepareQueryCampaign(DIV_DB,
        "CREATE TABLE IF NOT EXISTS div_players ("
        + "uuid TEXT PRIMARY KEY, "
        + "char_name TEXT DEFAULT '', "
        + "last_reading_at INTEGER DEFAULT 0, "
        + "effects_json TEXT DEFAULT '[]', "
        + "total_readings INTEGER DEFAULT 0)");
    SqlStep(q);
}

int DivGetNow()
{
    sqlquery q = SqlPrepareQueryCampaign(DIV_DB,
        "SELECT CAST(strftime('%s','now') AS INTEGER)");
    if(SqlStep(q)) return SqlGetInt(q, 0);
    return 0;
}

void DivEnsureRow(object oPC)
{
    sqlquery q = SqlPrepareQueryCampaign(DIV_DB,
        "INSERT OR IGNORE INTO div_players (uuid, char_name) VALUES (@u, @n)");
    SqlBindString(q, "@u", GetObjectUUID(oPC));
    SqlBindString(q, "@n", GetName(oPC));
    SqlStep(q);
}

int DivGetLastReadingAt(object oPC)
{
    sqlquery q = SqlPrepareQueryCampaign(DIV_DB,
        "SELECT last_reading_at FROM div_players WHERE uuid = @u");
    SqlBindString(q, "@u", GetObjectUUID(oPC));
    if(SqlStep(q)) return SqlGetInt(q, 0);
    return 0;
}

void DivSetLastReadingAt(object oPC, int nNow)
{
    sqlquery q = SqlPrepareQueryCampaign(DIV_DB,
        "UPDATE div_players "
        + "SET last_reading_at = @t, total_readings = total_readings + 1 "
        + "WHERE uuid = @u");
    SqlBindInt   (q, "@t", nNow);
    SqlBindString(q, "@u", GetObjectUUID(oPC));
    SqlStep(q);
}

string DivGetEffectsJson(object oPC)
{
    sqlquery q = SqlPrepareQueryCampaign(DIV_DB,
        "SELECT effects_json FROM div_players WHERE uuid = @u");
    SqlBindString(q, "@u", GetObjectUUID(oPC));
    if(SqlStep(q)) return SqlGetString(q, 0);
    return "[]";
}

void DivSetEffectsJson(object oPC, string sJson)
{
    sqlquery q = SqlPrepareQueryCampaign(DIV_DB,
        "UPDATE div_players SET effects_json = @j WHERE uuid = @u");
    SqlBindString(q, "@j", sJson);
    SqlBindString(q, "@u", GetObjectUUID(oPC));
    SqlStep(q);
}
