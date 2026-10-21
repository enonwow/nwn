// Campaign database name used by all Haunted Armory queries
const string HAUNT_DB = "haunted_armory";

void HauntCreateTables()
{
    sqlquery q = SqlPrepareQueryCampaign(HAUNT_DB,
        "CREATE TABLE IF NOT EXISTS haunt_weapons ("
        "item_uuid     TEXT    PRIMARY KEY,"
        "kill_count    INTEGER DEFAULT 0,"
        "haunt_level   INTEGER DEFAULT 0,"
        "is_embraced   INTEGER DEFAULT 0,"
        "first_kill_at INTEGER DEFAULT 0,"
        "last_kill_at  INTEGER DEFAULT 0"
        ")");
    SqlStep(q);

    q = SqlPrepareQueryCampaign(HAUNT_DB,
        "CREATE TABLE IF NOT EXISTS haunt_kills ("
        "id          INTEGER PRIMARY KEY AUTOINCREMENT,"
        "item_uuid   TEXT    NOT NULL,"
        "victim_name TEXT    DEFAULT '',"
        "victim_race INTEGER DEFAULT 0,"
        "kill_at     INTEGER DEFAULT 0"
        ")");
    SqlStep(q);

    q = SqlPrepareQueryCampaign(HAUNT_DB,
        "CREATE INDEX IF NOT EXISTS idx_hk_uuid ON haunt_kills(item_uuid)");
    SqlStep(q);
}

// Returns 1 when a row exists for this weapon.
int HauntWeaponExists(string sUUID)
{
    sqlquery q = SqlPrepareQueryCampaign(HAUNT_DB,
        "SELECT COUNT(*) FROM haunt_weapons WHERE item_uuid = @uuid");
    SqlBindString(q, "@uuid", sUUID);
    if(SqlStep(q)) return SqlGetInt(q, 0);
    return 0;
}

// Increments kill counter, inserts kill record, recalculates level.
void HauntRecordKillSQL(string sItemUUID, string sVictimName, int nVictimRace)
{
    sqlquery q = SqlPrepareQueryCampaign(HAUNT_DB,
        "INSERT INTO haunt_weapons "
        "(item_uuid, kill_count, haunt_level, first_kill_at, last_kill_at) "
        "VALUES (@uuid, 1, 0, strftime('%s','now'), strftime('%s','now')) "
        "ON CONFLICT(item_uuid) DO UPDATE SET "
        "  kill_count  = kill_count + 1,"
        "  last_kill_at = strftime('%s','now')");
    SqlBindString(q, "@uuid", sItemUUID);
    SqlStep(q);

    q = SqlPrepareQueryCampaign(HAUNT_DB,
        "INSERT INTO haunt_kills (item_uuid, victim_name, victim_race, kill_at) "
        "VALUES (@uuid, @name, @race, strftime('%s','now'))");
    SqlBindString(q, "@uuid", sItemUUID);
    SqlBindString(q, "@name", sVictimName);
    SqlBindInt   (q, "@race", nVictimRace);
    SqlStep(q);

    // Recalculate level from kill count using a CASE expression.
    q = SqlPrepareQueryCampaign(HAUNT_DB,
        "UPDATE haunt_weapons SET haunt_level = "
        "  CASE"
        "    WHEN kill_count >= 300 THEN 5"
        "    WHEN kill_count >= 150 THEN 4"
        "    WHEN kill_count >= 75  THEN 3"
        "    WHEN kill_count >= 30  THEN 2"
        "    WHEN kill_count >= 10  THEN 1"
        "    ELSE 0"
        "  END "
        "WHERE item_uuid = @uuid");
    SqlBindString(q, "@uuid", sItemUUID);
    SqlStep(q);

    // Keep only the newest 50 kill records per weapon to cap table growth.
    q = SqlPrepareQueryCampaign(HAUNT_DB,
        "DELETE FROM haunt_kills "
        "WHERE item_uuid = @uuid "
        "  AND id NOT IN ("
        "    SELECT id FROM haunt_kills "
        "    WHERE item_uuid = @uuid "
        "    ORDER BY id DESC LIMIT 50"
        "  )");
    SqlBindString(q, "@uuid", sItemUUID);
    SqlStep(q);
}

// Returns a JSON object: {kill_count, haunt_level, is_embraced, first_kill_at, last_kill_at}
// or JsonNull() when no record exists.
json HauntGetWeaponData(string sUUID)
{
    sqlquery q = SqlPrepareQueryCampaign(HAUNT_DB,
        "SELECT kill_count, haunt_level, is_embraced, first_kill_at, last_kill_at "
        "FROM haunt_weapons WHERE item_uuid = @uuid");
    SqlBindString(q, "@uuid", sUUID);
    if(!SqlStep(q)) return JsonNull();

    json jD = JsonObject();
    jD = JsonObjectSet(jD, "kill_count",    JsonInt(SqlGetInt(q, 0)));
    jD = JsonObjectSet(jD, "haunt_level",   JsonInt(SqlGetInt(q, 1)));
    jD = JsonObjectSet(jD, "is_embraced",   JsonInt(SqlGetInt(q, 2)));
    jD = JsonObjectSet(jD, "first_kill_at", JsonInt(SqlGetInt(q, 3)));
    jD = JsonObjectSet(jD, "last_kill_at",  JsonInt(SqlGetInt(q, 4)));
    return jD;
}

// Returns a JSON array of up to nLimit kill records, newest first.
json HauntGetKillHistory(string sUUID, int nLimit)
{
    json jRows = JsonArray();
    sqlquery q = SqlPrepareQueryCampaign(HAUNT_DB,
        "SELECT victim_name, victim_race, kill_at "
        "FROM haunt_kills WHERE item_uuid = @uuid "
        "ORDER BY id DESC LIMIT @lim");
    SqlBindString(q, "@uuid", sUUID);
    SqlBindInt   (q, "@lim",  nLimit);
    while(SqlStep(q))
    {
        json jRow = JsonObject();
        jRow = JsonObjectSet(jRow, "victim_name", JsonString(SqlGetString(q, 0)));
        jRow = JsonObjectSet(jRow, "victim_race", JsonInt   (SqlGetInt   (q, 1)));
        jRow = JsonObjectSet(jRow, "kill_at",     JsonInt   (SqlGetInt   (q, 2)));
        jRows = JsonArrayInsert(jRows, jRow);
    }
    return jRows;
}

void HauntSetEmbraced(string sUUID, int bEmbraced)
{
    sqlquery q = SqlPrepareQueryCampaign(HAUNT_DB,
        "UPDATE haunt_weapons SET is_embraced = @val WHERE item_uuid = @uuid");
    SqlBindInt   (q, "@val",  bEmbraced);
    SqlBindString(q, "@uuid", sUUID);
    SqlStep(q);
}

// Resets all haunting data for a weapon (does NOT delete the row).
void HauntCleanse(string sUUID)
{
    sqlquery q = SqlPrepareQueryCampaign(HAUNT_DB,
        "UPDATE haunt_weapons "
        "SET kill_count = 0, haunt_level = 0, is_embraced = 0, "
        "    first_kill_at = 0, last_kill_at = 0 "
        "WHERE item_uuid = @uuid");
    SqlBindString(q, "@uuid", sUUID);
    SqlStep(q);

    q = SqlPrepareQueryCampaign(HAUNT_DB,
        "DELETE FROM haunt_kills WHERE item_uuid = @uuid");
    SqlBindString(q, "@uuid", sUUID);
    SqlStep(q);
}

string HauntFormatDate(int nUnix)
{
    if(nUnix <= 0) return "--";
    sqlquery q = SqlPrepareQueryCampaign(HAUNT_DB,
        "SELECT strftime('%d.%m', @ts, 'unixepoch')");
    SqlBindInt(q, "@ts", nUnix);
    if(SqlStep(q)) return SqlGetString(q, 0);
    return "--";
}
