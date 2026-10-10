const string ASTR_CAMPAIGN = "astral";

void AstrCreateTables()
{
    sqlquery q = SqlPrepareQueryCampaign(ASTR_CAMPAIGN,
        "CREATE TABLE IF NOT EXISTS astr_log ("
        + "uuid TEXT PRIMARY KEY, "
        + "char_name TEXT DEFAULT '', "
        + "total_sessions INTEGER DEFAULT 0, "
        + "total_secs INTEGER DEFAULT 0, "
        + "max_secs INTEGER DEFAULT 0, "
        + "last_entry INTEGER DEFAULT 0)");
    SqlStep(q);
}

void AstrEnsureRow(object oPC)
{
    sqlquery q = SqlPrepareQueryCampaign(ASTR_CAMPAIGN,
        "INSERT OR IGNORE INTO astr_log (uuid, char_name) VALUES (@uuid, @name)");
    SqlBindString(q, "@uuid", GetObjectUUID(oPC));
    SqlBindString(q, "@name", GetName(oPC));
    SqlStep(q);
}

// Persists one completed session. nSecsSpent = actual time spent in projection.
void AstrRecordSession(object oPC, int nSecsSpent)
{
    AstrEnsureRow(oPC);
    sqlquery q = SqlPrepareQueryCampaign(ASTR_CAMPAIGN,
        "UPDATE astr_log SET "
        + "total_sessions = total_sessions + 1, "
        + "total_secs = total_secs + @secs, "
        + "max_secs = MAX(max_secs, @secs), "
        + "char_name = @name, "
        + "last_entry = strftime('%s','now') "
        + "WHERE uuid = @uuid");
    SqlBindInt   (q, "@secs", nSecsSpent);
    SqlBindString(q, "@name", GetName(oPC));
    SqlBindString(q, "@uuid", GetObjectUUID(oPC));
    SqlStep(q);
}

// Returns JsonObject: {total_sessions, total_secs, max_secs}
json AstrGetStats(object oPC)
{
    AstrEnsureRow(oPC);
    sqlquery q = SqlPrepareQueryCampaign(ASTR_CAMPAIGN,
        "SELECT total_sessions, total_secs, max_secs FROM astr_log WHERE uuid = @uuid");
    SqlBindString(q, "@uuid", GetObjectUUID(oPC));
    if(!SqlStep(q)) return JsonObject();
    json j = JsonObject();
    j = JsonObjectSet(j, "total_sessions", JsonInt(SqlGetInt(q, 0)));
    j = JsonObjectSet(j, "total_secs",     JsonInt(SqlGetInt(q, 1)));
    j = JsonObjectSet(j, "max_secs",       JsonInt(SqlGetInt(q, 2)));
    return j;
}
