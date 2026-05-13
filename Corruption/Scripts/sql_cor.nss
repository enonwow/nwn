// sql_cor.nss  –  Corruption: SQLite schema and queries
// Campaign DB: "corruption"

void CorCreateTables()
{
    sqlquery q = SqlPrepareQueryCampaign("corruption",
        "CREATE TABLE IF NOT EXISTS cor_chars ("
        "uuid         TEXT    PRIMARY KEY, "
        "char_name    TEXT    DEFAULT '', "
        "corruption   INTEGER DEFAULT 0, "
        "last_ritual  INTEGER DEFAULT 0"
        ")");
    SqlStep(q);
}

// Returns stored corruption (0 if not yet registered).
int CorDbGetCorruption(object oPC)
{
    sqlquery q = SqlPrepareQueryCampaign("corruption",
        "SELECT corruption FROM cor_chars WHERE uuid = @uuid");
    SqlBindString(q, "@uuid", GetObjectUUID(oPC));
    if(SqlStep(q)) return SqlGetInt(q, 0);
    return 0;
}

// Writes corruption (clamped to 0-100 by caller).
void CorDbSetCorruption(object oPC, int nValue)
{
    sqlquery q = SqlPrepareQueryCampaign("corruption",
        "INSERT INTO cor_chars (uuid, char_name, corruption, last_ritual) "
        "VALUES (@uuid, @name, @val, 0) "
        "ON CONFLICT(uuid) DO UPDATE SET char_name = @name, corruption = @val");
    SqlBindString(q, "@uuid", GetObjectUUID(oPC));
    SqlBindString(q, "@name", GetName(oPC));
    SqlBindInt   (q, "@val",  nValue);
    SqlStep(q);
}

// Returns unix timestamp of last cleansing ritual (0 if none).
int CorDbGetLastRitual(object oPC)
{
    sqlquery q = SqlPrepareQueryCampaign("corruption",
        "SELECT last_ritual FROM cor_chars WHERE uuid = @uuid");
    SqlBindString(q, "@uuid", GetObjectUUID(oPC));
    if(SqlStep(q)) return SqlGetInt(q, 0);
    return 0;
}

void CorDbSetLastRitual(object oPC)
{
    sqlquery q = SqlPrepareQueryCampaign("corruption",
        "UPDATE cor_chars SET last_ritual = strftime('%s','now') WHERE uuid = @uuid");
    SqlBindString(q, "@uuid", GetObjectUUID(oPC));
    SqlStep(q);
}

// Returns current unix timestamp via SQLite (avoids NWN time API quirks).
int CorDbNow()
{
    sqlquery q = SqlPrepareQueryCampaign("corruption",
        "SELECT CAST(strftime('%s','now') AS INTEGER)");
    if(SqlStep(q)) return SqlGetInt(q, 0);
    return 0;
}
