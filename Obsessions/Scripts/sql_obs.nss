void ObsCreateTables()
{
    sqlquery q = SqlPrepareQueryCampaign("obsessions",
        "CREATE TABLE IF NOT EXISTS obs_data ("
        "  pc_uuid TEXT NOT NULL,"
        "  category TEXT NOT NULL,"
        "  points INTEGER DEFAULT 0,"
        "  trigger_count INTEGER DEFAULT 0,"
        "  suppressed_until INTEGER DEFAULT 0,"
        "  PRIMARY KEY (pc_uuid, category)"
        ")");
    SqlStep(q);
}

void ObsEnsureRow(string sUuid, string sCategory)
{
    sqlquery q = SqlPrepareQueryCampaign("obsessions",
        "INSERT OR IGNORE INTO obs_data (pc_uuid, category) VALUES (@uuid, @cat)");
    SqlBindString(q, "@uuid", sUuid);
    SqlBindString(q, "@cat", sCategory);
    SqlStep(q);
}

int ObsGetPoints(object oPC, string sCategory)
{
    string sUuid = GetObjectUUID(oPC);
    sqlquery q = SqlPrepareQueryCampaign("obsessions",
        "SELECT points FROM obs_data WHERE pc_uuid = @uuid AND category = @cat");
    SqlBindString(q, "@uuid", sUuid);
    SqlBindString(q, "@cat", sCategory);
    if(SqlStep(q)) return SqlGetInt(q, 0);
    return 0;
}

// nDelta is clamped so total never exceeds 125
void ObsAddPoints(object oPC, string sCategory, int nDelta)
{
    if(nDelta <= 0) return;
    string sUuid = GetObjectUUID(oPC);
    ObsEnsureRow(sUuid, sCategory);
    sqlquery q = SqlPrepareQueryCampaign("obsessions",
        "UPDATE obs_data SET points = MIN(points + @delta, 125)"
        " WHERE pc_uuid = @uuid AND category = @cat");
    SqlBindInt(q, "@delta", nDelta);
    SqlBindString(q, "@uuid", sUuid);
    SqlBindString(q, "@cat", sCategory);
    SqlStep(q);
}

// Returns JsonObject keyed by category: { "UNDEAD": {points, trigger_count, suppressed_until}, ... }
json ObsGetAllJson(object oPC)
{
    string sUuid = GetObjectUUID(oPC);
    sqlquery q = SqlPrepareQueryCampaign("obsessions",
        "SELECT category, points, trigger_count, suppressed_until"
        " FROM obs_data WHERE pc_uuid = @uuid");
    SqlBindString(q, "@uuid", sUuid);
    json jResult = JsonObject();
    while(SqlStep(q))
    {
        string sCat = SqlGetString(q, 0);
        json jEntry = JsonObject();
        jEntry = JsonObjectSet(jEntry, "points",           JsonInt(SqlGetInt(q, 1)));
        jEntry = JsonObjectSet(jEntry, "trigger_count",    JsonInt(SqlGetInt(q, 2)));
        jEntry = JsonObjectSet(jEntry, "suppressed_until", JsonInt(SqlGetInt(q, 3)));
        jResult = JsonObjectSet(jResult, sCat, jEntry);
    }
    return jResult;
}

int ObsIsSuppressed(object oPC, string sCategory)
{
    string sUuid = GetObjectUUID(oPC);
    sqlquery q = SqlPrepareQueryCampaign("obsessions",
        "SELECT suppressed_until FROM obs_data WHERE pc_uuid = @uuid AND category = @cat");
    SqlBindString(q, "@uuid", sUuid);
    SqlBindString(q, "@cat", sCategory);
    if(SqlStep(q))
        return (SqlGetInt(q, 0) > GetUnixTimeStamp());
    return FALSE;
}

void ObsSuppressCategory(object oPC, string sCategory, int nDurationSeconds)
{
    string sUuid = GetObjectUUID(oPC);
    ObsEnsureRow(sUuid, sCategory);
    int nUntil = GetUnixTimeStamp() + nDurationSeconds;
    sqlquery q = SqlPrepareQueryCampaign("obsessions",
        "UPDATE obs_data SET suppressed_until = @until"
        " WHERE pc_uuid = @uuid AND category = @cat");
    SqlBindInt(q, "@until", nUntil);
    SqlBindString(q, "@uuid", sUuid);
    SqlBindString(q, "@cat", sCategory);
    SqlStep(q);
}

void ObsIncrementTrigger(object oPC, string sCategory)
{
    string sUuid = GetObjectUUID(oPC);
    ObsEnsureRow(sUuid, sCategory);
    sqlquery q = SqlPrepareQueryCampaign("obsessions",
        "UPDATE obs_data SET trigger_count = trigger_count + 1"
        " WHERE pc_uuid = @uuid AND category = @cat");
    SqlBindString(q, "@uuid", sUuid);
    SqlBindString(q, "@cat", sCategory);
    SqlStep(q);
}
