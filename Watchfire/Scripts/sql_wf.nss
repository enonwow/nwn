// sql_wf.nss — Watchfire: SQLite schema and queries (per-character data via SqlPrepareQueryObject)

void WfCreateTables(object oPC)
{
    sqlquery q = SqlPrepareQueryObject(oPC,
        "CREATE TABLE IF NOT EXISTS wf_sessions ("
        "  id        INTEGER PRIMARY KEY AUTOINCREMENT,"
        "  rest_type TEXT    DEFAULT 'long',"
        "  area_name TEXT    DEFAULT '',"
        "  encounter INTEGER DEFAULT 0,"
        "  meal_name TEXT    DEFAULT '',"
        "  rested_at INTEGER DEFAULT 0"
        ")");
    SqlStep(q);
}

// Logs a completed rest session to the PC's personal database
void WfLogSession(object oPC, string sRestType, string sAreaName, int nEncounter, string sMealName)
{
    WfCreateTables(oPC);
    sqlquery q = SqlPrepareQueryObject(oPC,
        "INSERT INTO wf_sessions (rest_type, area_name, encounter, meal_name, rested_at)"
        " VALUES (@rtype, @area, @enc, @meal, strftime('%s','now'))");
    SqlBindString(q, "@rtype", sRestType);
    SqlBindString(q, "@area",  sAreaName);
    SqlBindInt   (q, "@enc",   nEncounter);
    SqlBindString(q, "@meal",  sMealName);
    SqlStep(q);
}

// Returns a JsonArray of the last 12 sessions: [{rest_type, area_name, encounter, meal_name, rested_at}, ...]
json WfGetRecentSessions(object oPC)
{
    WfCreateTables(oPC);
    json jRows = JsonArray();
    sqlquery q = SqlPrepareQueryObject(oPC,
        "SELECT rest_type, area_name, encounter, meal_name,"
        "       strftime('%d.%m', rested_at, 'unixepoch') AS day"
        " FROM wf_sessions"
        " ORDER BY rested_at DESC"
        " LIMIT 12");
    while(SqlStep(q))
    {
        json jRow = JsonObject();
        jRow = JsonObjectSet(jRow, "rest_type", JsonString(SqlGetString(q, 0)));
        jRow = JsonObjectSet(jRow, "area_name", JsonString(SqlGetString(q, 1)));
        jRow = JsonObjectSet(jRow, "encounter", JsonInt   (SqlGetInt   (q, 2)));
        jRow = JsonObjectSet(jRow, "meal_name", JsonString(SqlGetString(q, 3)));
        jRow = JsonObjectSet(jRow, "day",       JsonString(SqlGetString(q, 4)));
        jRows = JsonArrayInsert(jRows, jRow);
    }
    return jRows;
}
