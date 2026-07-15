// Campaign DB: "observatory"

void ObsCreateTables()
{
    sqlquery q = SqlPrepareQueryCampaign("observatory",
        "CREATE TABLE IF NOT EXISTS obs_pcs ("
        "  uuid            TEXT    PRIMARY KEY,"
        "  birth_sign      INTEGER DEFAULT -1,"
        "  last_read_ts    INTEGER DEFAULT 0,"
        "  last_read_sign  INTEGER DEFAULT -1,"
        "  read_count      INTEGER DEFAULT 0"
        ")");
    SqlStep(q);
}

void ObsRegisterPC(object oPC)
{
    sqlquery q = SqlPrepareQueryCampaign("observatory",
        "INSERT OR IGNORE INTO obs_pcs (uuid) VALUES (@uuid)");
    SqlBindString(q, "@uuid", GetObjectUUID(oPC));
    SqlStep(q);
}

// Returns -1 if not set yet.
int ObsGetBirthSign(object oPC)
{
    sqlquery q = SqlPrepareQueryCampaign("observatory",
        "SELECT birth_sign FROM obs_pcs WHERE uuid = @uuid");
    SqlBindString(q, "@uuid", GetObjectUUID(oPC));
    if(SqlStep(q)) return SqlGetInt(q, 0);
    return -1;
}

void ObsSetBirthSign(object oPC, int nSign)
{
    sqlquery q = SqlPrepareQueryCampaign("observatory",
        "UPDATE obs_pcs SET birth_sign = @sign WHERE uuid = @uuid AND birth_sign = -1");
    SqlBindInt   (q, "@sign", nSign);
    SqlBindString(q, "@uuid", GetObjectUUID(oPC));
    SqlStep(q);
}

// Returns {last_read_ts, last_read_sign, read_count} or default zeros.
json ObsGetReadingData(object oPC)
{
    sqlquery q = SqlPrepareQueryCampaign("observatory",
        "SELECT last_read_ts, last_read_sign, read_count FROM obs_pcs WHERE uuid = @uuid");
    SqlBindString(q, "@uuid", GetObjectUUID(oPC));
    json jData = JsonObject();
    if(SqlStep(q))
    {
        jData = JsonObjectSet(jData, "ts",    JsonInt(SqlGetInt(q, 0)));
        jData = JsonObjectSet(jData, "sign",  JsonInt(SqlGetInt(q, 1)));
        jData = JsonObjectSet(jData, "count", JsonInt(SqlGetInt(q, 2)));
    }
    else
    {
        jData = JsonObjectSet(jData, "ts",    JsonInt(0));
        jData = JsonObjectSet(jData, "sign",  JsonInt(-1));
        jData = JsonObjectSet(jData, "count", JsonInt(0));
    }
    return jData;
}

// Record a successful star reading.
void ObsRecordReading(object oPC, int nSign)
{
    sqlquery q = SqlPrepareQueryCampaign("observatory",
        "UPDATE obs_pcs SET last_read_ts = strftime('%s','now'), last_read_sign = @sign,"
        " read_count = read_count + 1 WHERE uuid = @uuid");
    SqlBindInt   (q, "@sign", nSign);
    SqlBindString(q, "@uuid", GetObjectUUID(oPC));
    SqlStep(q);
}

// Returns current unix time from SQLite (avoids NWScript time quirks).
int ObsNowUnix()
{
    sqlquery q = SqlPrepareQueryCampaign("observatory", "SELECT strftime('%s','now')");
    if(SqlStep(q)) return SqlGetInt(q, 0);
    return 0;
}
