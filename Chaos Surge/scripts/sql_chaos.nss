// sql_chaos.nss — DB schema and raw queries for the Chaos Surge system.
// No includes from this module to keep the dependency graph acyclic.

void ChaosCreateTables()
{
    sqlquery q = SqlPrepareQueryCampaign("chaos",
        "CREATE TABLE IF NOT EXISTS chaos_state ("
        "uuid TEXT PRIMARY KEY, "
        "chaos_points INTEGER DEFAULT 0, "
        "total_surges INTEGER DEFAULT 0, "
        "log_json TEXT DEFAULT '[]', "
        "updated_at INTEGER DEFAULT 0)");
    SqlStep(q);
}

// Persist per-character state. All values are primitives to avoid
// including lib_chaos_def.nss here (which would create a circular dep).
void ChaosSave(string sUuid, int nCP, int nTotal, string sLogJson)
{
    sqlquery q = SqlPrepareQueryCampaign("chaos",
        "INSERT OR REPLACE INTO chaos_state "
        "(uuid, chaos_points, total_surges, log_json, updated_at) "
        "VALUES (@uuid, @cp, @tot, @log, strftime('%s','now'))");
    SqlBindString(q, "@uuid", sUuid);
    SqlBindInt   (q, "@cp",   nCP);
    SqlBindInt   (q, "@tot",  nTotal);
    SqlBindString(q, "@log",  sLogJson);
    SqlStep(q);
}

// Returns a JSON object {cp, total, log} or JsonNull() when not found.
json ChaosLoad(string sUuid)
{
    sqlquery q = SqlPrepareQueryCampaign("chaos",
        "SELECT chaos_points, total_surges, log_json "
        "FROM chaos_state WHERE uuid = @uuid");
    SqlBindString(q, "@uuid", sUuid);

    if(!SqlStep(q)) return JsonNull();

    json jData = JsonObject();
    jData = JsonObjectSet(jData, "cp",    JsonInt   (SqlGetInt   (q, 0)));
    jData = JsonObjectSet(jData, "total", JsonInt   (SqlGetInt   (q, 1)));
    jData = JsonObjectSet(jData, "log",   JsonString(SqlGetString(q, 2)));
    return jData;
}
