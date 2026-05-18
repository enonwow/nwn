void PrisonCreateTables()
{
    sqlquery q;

    q = SqlPrepareQueryCampaign("prison",
        "CREATE TABLE IF NOT EXISTS prison_active ("
        "  uuid          TEXT PRIMARY KEY,"
        "  char_name     TEXT    DEFAULT '',"
        "  crime_level   INTEGER DEFAULT 1,"
        "  crime_desc    TEXT    DEFAULT '',"
        "  arrested_at   INTEGER DEFAULT 0,"
        "  sentence_sec  INTEGER DEFAULT 0,"
        "  esc_attempts  INTEGER DEFAULT 0"
        ")");
    SqlStep(q);

    q = SqlPrepareQueryCampaign("prison",
        "CREATE TABLE IF NOT EXISTS prison_records ("
        "  id           INTEGER PRIMARY KEY AUTOINCREMENT,"
        "  uuid         TEXT    NOT NULL,"
        "  char_name    TEXT    DEFAULT '',"
        "  crime_desc   TEXT    DEFAULT '',"
        "  crime_level  INTEGER DEFAULT 0,"
        "  arrested_at  INTEGER DEFAULT 0,"
        "  sentence_sec INTEGER DEFAULT 0,"
        "  outcome      TEXT    DEFAULT 'served',"
        "  released_at  INTEGER DEFAULT 0"
        ")");
    SqlStep(q);

    q = SqlPrepareQueryCampaign("prison",
        "CREATE TABLE IF NOT EXISTS prison_warrants ("
        "  uuid        TEXT PRIMARY KEY,"
        "  char_name   TEXT    DEFAULT '',"
        "  crime_level INTEGER DEFAULT 0,"
        "  crime_desc  TEXT    DEFAULT '',"
        "  issued_at   INTEGER DEFAULT 0"
        ")");
    SqlStep(q);
}

void PrisonWriteActive(object oPC, int nCrimeLevel, string sCrimeDesc, int nSentenceSec)
{
    sqlquery q = SqlPrepareQueryCampaign("prison",
        "INSERT OR REPLACE INTO prison_active "
        "(uuid, char_name, crime_level, crime_desc, arrested_at, sentence_sec, esc_attempts) "
        "VALUES (@uuid, @name, @lvl, @desc, CAST(strftime('%s','now') AS INTEGER), @sent, 0)");
    SqlBindString(q, "@uuid",  GetObjectUUID(oPC));
    SqlBindString(q, "@name",  GetName(oPC));
    SqlBindInt   (q, "@lvl",   nCrimeLevel);
    SqlBindString(q, "@desc",  sCrimeDesc);
    SqlBindInt   (q, "@sent",  nSentenceSec);
    SqlStep(q);
}

int PrisonIsActive(object oPC)
{
    sqlquery q = SqlPrepareQueryCampaign("prison",
        "SELECT COUNT(*) FROM prison_active WHERE uuid = @uuid");
    SqlBindString(q, "@uuid", GetObjectUUID(oPC));
    if(SqlStep(q)) return SqlGetInt(q, 0);
    return 0;
}

json PrisonGetActiveRecord(object oPC)
{
    sqlquery q = SqlPrepareQueryCampaign("prison",
        "SELECT uuid, char_name, crime_level, crime_desc, arrested_at, sentence_sec, esc_attempts "
        "FROM prison_active WHERE uuid = @uuid");
    SqlBindString(q, "@uuid", GetObjectUUID(oPC));
    if(!SqlStep(q)) return JsonNull();
    json j = JsonObject();
    j = JsonObjectSet(j, "uuid",         JsonString(SqlGetString(q, 0)));
    j = JsonObjectSet(j, "char_name",    JsonString(SqlGetString(q, 1)));
    j = JsonObjectSet(j, "crime_level",  JsonInt   (SqlGetInt   (q, 2)));
    j = JsonObjectSet(j, "crime_desc",   JsonString(SqlGetString(q, 3)));
    j = JsonObjectSet(j, "arrested_at",  JsonInt   (SqlGetInt   (q, 4)));
    j = JsonObjectSet(j, "sentence_sec", JsonInt   (SqlGetInt   (q, 5)));
    j = JsonObjectSet(j, "esc_attempts", JsonInt   (SqlGetInt   (q, 6)));
    return j;
}

void PrisonIncrEscapeAttempts(object oPC)
{
    sqlquery q = SqlPrepareQueryCampaign("prison",
        "UPDATE prison_active SET esc_attempts = esc_attempts + 1 WHERE uuid = @uuid");
    SqlBindString(q, "@uuid", GetObjectUUID(oPC));
    SqlStep(q);
}

void PrisonAddExtraTime(object oPC, int nExtraSec)
{
    sqlquery q = SqlPrepareQueryCampaign("prison",
        "UPDATE prison_active SET sentence_sec = sentence_sec + @extra WHERE uuid = @uuid");
    SqlBindString(q, "@uuid",  GetObjectUUID(oPC));
    SqlBindInt   (q, "@extra", nExtraSec);
    SqlStep(q);
}

void PrisonDeleteActive(object oPC)
{
    sqlquery q = SqlPrepareQueryCampaign("prison",
        "DELETE FROM prison_active WHERE uuid = @uuid");
    SqlBindString(q, "@uuid", GetObjectUUID(oPC));
    SqlStep(q);
}

void PrisonWriteRecord(object oPC, int nCrimeLevel, string sCrimeDesc,
                       int nArrestedAt, int nSentenceSec, string sOutcome)
{
    sqlquery q = SqlPrepareQueryCampaign("prison",
        "INSERT INTO prison_records "
        "(uuid, char_name, crime_desc, crime_level, arrested_at, sentence_sec, outcome, released_at) "
        "VALUES (@uuid, @name, @desc, @lvl, @arr, @sent, @out, CAST(strftime('%s','now') AS INTEGER))");
    SqlBindString(q, "@uuid", GetObjectUUID(oPC));
    SqlBindString(q, "@name", GetName(oPC));
    SqlBindString(q, "@desc", sCrimeDesc);
    SqlBindInt   (q, "@lvl",  nCrimeLevel);
    SqlBindInt   (q, "@arr",  nArrestedAt);
    SqlBindInt   (q, "@sent", nSentenceSec);
    SqlBindString(q, "@out",  sOutcome);
    SqlStep(q);
}

json PrisonGetHistory(object oPC)
{
    json jRows = JsonArray();
    sqlquery q = SqlPrepareQueryCampaign("prison",
        "SELECT crime_desc, crime_level, arrested_at, outcome "
        "FROM prison_records WHERE uuid = @uuid "
        "ORDER BY arrested_at DESC LIMIT 10");
    SqlBindString(q, "@uuid", GetObjectUUID(oPC));
    while(SqlStep(q))
    {
        json jRow = JsonObject();
        jRow = JsonObjectSet(jRow, "crime_desc",  JsonString(SqlGetString(q, 0)));
        jRow = JsonObjectSet(jRow, "crime_level", JsonInt   (SqlGetInt   (q, 1)));
        jRow = JsonObjectSet(jRow, "arrested_at", JsonInt   (SqlGetInt   (q, 2)));
        jRow = JsonObjectSet(jRow, "outcome",     JsonString(SqlGetString(q, 3)));
        jRows = JsonArrayInsert(jRows, jRow);
    }
    return jRows;
}

void PrisonIssueWarrant(object oPC, int nCrimeLevel, string sCrimeDesc)
{
    sqlquery q = SqlPrepareQueryCampaign("prison",
        "INSERT OR REPLACE INTO prison_warrants "
        "(uuid, char_name, crime_level, crime_desc, issued_at) "
        "VALUES (@uuid, @name, @lvl, @desc, CAST(strftime('%s','now') AS INTEGER))");
    SqlBindString(q, "@uuid", GetObjectUUID(oPC));
    SqlBindString(q, "@name", GetName(oPC));
    SqlBindInt   (q, "@lvl",  nCrimeLevel);
    SqlBindString(q, "@desc", sCrimeDesc);
    SqlStep(q);
}

void PrisonClearWarrant(object oPC)
{
    sqlquery q = SqlPrepareQueryCampaign("prison",
        "DELETE FROM prison_warrants WHERE uuid = @uuid");
    SqlBindString(q, "@uuid", GetObjectUUID(oPC));
    SqlStep(q);
}

int PrisonGetWarrantLevel(object oPC)
{
    sqlquery q = SqlPrepareQueryCampaign("prison",
        "SELECT crime_level FROM prison_warrants WHERE uuid = @uuid");
    SqlBindString(q, "@uuid", GetObjectUUID(oPC));
    if(SqlStep(q)) return SqlGetInt(q, 0);
    return 0;
}

// Returns seconds remaining in sentence (negative = overdue for release).
int PrisonGetSecondsRemaining(object oPC)
{
    sqlquery q = SqlPrepareQueryCampaign("prison",
        "SELECT (arrested_at + sentence_sec) - CAST(strftime('%s','now') AS INTEGER) "
        "FROM prison_active WHERE uuid = @uuid");
    SqlBindString(q, "@uuid", GetObjectUUID(oPC));
    if(SqlStep(q)) return SqlGetInt(q, 0);
    return -1;
}

string PrisonFormatSeconds(int nSec)
{
    if(nSec <= 0) return "0:00";
    int nMin = nSec / 60;
    int nS   = nSec - (nMin * 60);
    string sPad = (nS < 10) ? "0" : "";
    return IntToString(nMin) + ":" + sPad + IntToString(nS);
}

string PrisonFormatDateSQL(int nUnix)
{
    sqlquery q = SqlPrepareQueryCampaign("prison",
        "SELECT strftime('%d.%m.%Y', @ts, 'unixepoch')");
    SqlBindInt(q, "@ts", nUnix);
    if(SqlStep(q)) return SqlGetString(q, 0);
    return "";
}
