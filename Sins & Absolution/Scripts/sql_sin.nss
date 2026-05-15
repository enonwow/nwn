void SinCreateTables()
{
    sqlquery q = SqlPrepareQueryCampaign("sins",
        "CREATE TABLE IF NOT EXISTS sin_chars ("
        "  uuid         TEXT    PRIMARY KEY,"
        "  char_name    TEXT    DEFAULT '',"
        "  sin_score    INTEGER DEFAULT 0,"
        "  is_embraced  INTEGER DEFAULT 0,"
        "  last_updated INTEGER DEFAULT 0"
        ")");
    SqlStep(q);

    q = SqlPrepareQueryCampaign("sins",
        "CREATE TABLE IF NOT EXISTS sin_log ("
        "  id          INTEGER PRIMARY KEY AUTOINCREMENT,"
        "  uuid        TEXT    NOT NULL,"
        "  sin_type    INTEGER DEFAULT 0,"
        "  amount      INTEGER DEFAULT 0,"
        "  description TEXT    DEFAULT '',"
        "  logged_at   INTEGER DEFAULT 0"
        ")");
    SqlStep(q);

    q = SqlPrepareQueryCampaign("sins",
        "CREATE INDEX IF NOT EXISTS idx_sinlog_uuid ON sin_log (uuid, logged_at DESC)");
    SqlStep(q);
}

void SinRegisterChar(object oPC)
{
    sqlquery q = SqlPrepareQueryCampaign("sins",
        "INSERT OR IGNORE INTO sin_chars (uuid, char_name, last_updated) "
        "VALUES (@uuid, @name, strftime('%s','now'))");
    SqlBindString(q, "@uuid", GetObjectUUID(oPC));
    SqlBindString(q, "@name", GetName(oPC));
    SqlStep(q);
}

int SinGetScore(object oPC)
{
    sqlquery q = SqlPrepareQueryCampaign("sins",
        "SELECT sin_score FROM sin_chars WHERE uuid = @uuid");
    SqlBindString(q, "@uuid", GetObjectUUID(oPC));
    if (SqlStep(q)) return SqlGetInt(q, 0);
    return 0;
}

int SinIsEmbraced(object oPC)
{
    sqlquery q = SqlPrepareQueryCampaign("sins",
        "SELECT is_embraced FROM sin_chars WHERE uuid = @uuid");
    SqlBindString(q, "@uuid", GetObjectUUID(oPC));
    if (SqlStep(q)) return SqlGetInt(q, 0);
    return 0;
}

void SinSetScore(object oPC, int nScore)
{
    if (nScore < 0) nScore = 0;
    sqlquery q = SqlPrepareQueryCampaign("sins",
        "UPDATE sin_chars SET sin_score = @score, last_updated = strftime('%s','now') "
        "WHERE uuid = @uuid");
    SqlBindInt(q,    "@score", nScore);
    SqlBindString(q, "@uuid",  GetObjectUUID(oPC));
    SqlStep(q);
}

void SinSetEmbraced(object oPC, int bEmbraced)
{
    sqlquery q = SqlPrepareQueryCampaign("sins",
        "UPDATE sin_chars SET is_embraced = @val, last_updated = strftime('%s','now') "
        "WHERE uuid = @uuid");
    SqlBindInt(q,    "@val",  bEmbraced);
    SqlBindString(q, "@uuid", GetObjectUUID(oPC));
    SqlStep(q);
}

void SinLogEntry(object oPC, int nSinType, int nAmount, string sDesc)
{
    sqlquery q = SqlPrepareQueryCampaign("sins",
        "INSERT INTO sin_log (uuid, sin_type, amount, description, logged_at) "
        "VALUES (@uuid, @type, @amt, @desc, strftime('%s','now'))");
    SqlBindString(q, "@uuid", GetObjectUUID(oPC));
    SqlBindInt(q,    "@type", nSinType);
    SqlBindInt(q,    "@amt",  nAmount);
    SqlBindString(q, "@desc", sDesc);
    SqlStep(q);
}

void SinClearLog(object oPC)
{
    sqlquery q = SqlPrepareQueryCampaign("sins",
        "DELETE FROM sin_log WHERE uuid = @uuid");
    SqlBindString(q, "@uuid", GetObjectUUID(oPC));
    SqlStep(q);
}

// Returns JsonArray of {sin_type, amount, description, date} ordered newest first.
json SinGetLog(object oPC, int nLimit)
{
    json jLog = JsonArray();
    sqlquery q = SqlPrepareQueryCampaign("sins",
        "SELECT sin_type, amount, description, "
        "  strftime('%d.%m', logged_at, 'unixepoch') AS dt "
        "FROM sin_log WHERE uuid = @uuid ORDER BY logged_at DESC LIMIT @lim");
    SqlBindString(q, "@uuid", GetObjectUUID(oPC));
    SqlBindInt(q,    "@lim",  nLimit);
    while (SqlStep(q))
    {
        json jRow = JsonObject();
        jRow = JsonObjectSet(jRow, "sin_type",    JsonInt(SqlGetInt(q, 0)));
        jRow = JsonObjectSet(jRow, "amount",      JsonInt(SqlGetInt(q, 1)));
        jRow = JsonObjectSet(jRow, "description", JsonString(SqlGetString(q, 2)));
        jRow = JsonObjectSet(jRow, "date",        JsonString(SqlGetString(q, 3)));
        jLog = JsonArrayInsert(jLog, jRow);
    }
    return jLog;
}
