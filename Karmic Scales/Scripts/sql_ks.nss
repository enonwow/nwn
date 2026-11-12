// SQLite schema and query layer for Karmic Scales.
// All queries use campaign DB "karmic_scales".

void KsCreateTables()
{
    sqlquery q;

    q = SqlPrepareQueryCampaign("karmic_scales",
        "CREATE TABLE IF NOT EXISTS ks_karma ("
        "  uuid TEXT PRIMARY KEY,"
        "  karma INTEGER NOT NULL DEFAULT 0"
        ")");
    SqlStep(q);

    q = SqlPrepareQueryCampaign("karmic_scales",
        "CREATE TABLE IF NOT EXISTS ks_log ("
        "  id INTEGER PRIMARY KEY AUTOINCREMENT,"
        "  uuid TEXT NOT NULL,"
        "  delta INTEGER NOT NULL,"
        "  reason TEXT NOT NULL DEFAULT '',"
        "  logged_at INTEGER NOT NULL DEFAULT 0"
        ")");
    SqlStep(q);

    q = SqlPrepareQueryCampaign("karmic_scales",
        "CREATE TABLE IF NOT EXISTS ks_cooldowns ("
        "  uuid TEXT PRIMARY KEY,"
        "  ritual_at INTEGER NOT NULL DEFAULT 0"
        ")");
    SqlStep(q);
}

int KsGetKarma(object oPC)
{
    sqlquery q = SqlPrepareQueryCampaign("karmic_scales",
        "SELECT karma FROM ks_karma WHERE uuid = @uuid");
    SqlBindString(q, "@uuid", GetObjectUUID(oPC));
    if(SqlStep(q)) return SqlGetInt(q, 0);
    return 0;
}

void KsSaveKarma(object oPC, int nKarma)
{
    sqlquery q = SqlPrepareQueryCampaign("karmic_scales",
        "INSERT OR REPLACE INTO ks_karma (uuid, karma) VALUES (@uuid, @karma)");
    SqlBindString(q, "@uuid",  GetObjectUUID(oPC));
    SqlBindInt   (q, "@karma", nKarma);
    SqlStep(q);
}

// Clamps to [-100, 100] and saves. Returns new value.
int KsAddKarma(object oPC, int nDelta)
{
    int nNew = KsGetKarma(oPC) + nDelta;
    if(nNew >  100) nNew =  100;
    if(nNew < -100) nNew = -100;
    KsSaveKarma(oPC, nNew);
    return nNew;
}

void KsLogEvent(object oPC, int nDelta, string sReason)
{
    sqlquery q = SqlPrepareQueryCampaign("karmic_scales",
        "INSERT INTO ks_log (uuid, delta, reason, logged_at) "
        "VALUES (@uuid, @delta, @reason, strftime('%s','now'))");
    SqlBindString(q, "@uuid",   GetObjectUUID(oPC));
    SqlBindInt   (q, "@delta",  nDelta);
    SqlBindString(q, "@reason", sReason);
    SqlStep(q);

    // Prune: keep at most 50 entries per player
    sqlquery qClean = SqlPrepareQueryCampaign("karmic_scales",
        "DELETE FROM ks_log WHERE uuid = @uuid AND id NOT IN ("
        "  SELECT id FROM ks_log WHERE uuid = @uuid2 "
        "  ORDER BY logged_at DESC LIMIT 50"
        ")");
    SqlBindString(qClean, "@uuid",  GetObjectUUID(oPC));
    SqlBindString(qClean, "@uuid2", GetObjectUUID(oPC));
    SqlStep(qClean);
}

// Returns JsonArray of {delta, reason, logged_at} newest-first, up to 7 rows.
json KsGetLog(object oPC)
{
    json jRows = JsonArray();
    sqlquery q = SqlPrepareQueryCampaign("karmic_scales",
        "SELECT delta, reason, logged_at FROM ks_log "
        "WHERE uuid = @uuid ORDER BY logged_at DESC LIMIT 7");
    SqlBindString(q, "@uuid", GetObjectUUID(oPC));
    while(SqlStep(q))
    {
        json jRow = JsonObject();
        jRow = JsonObjectSet(jRow, "delta",     JsonInt   (SqlGetInt   (q, 0)));
        jRow = JsonObjectSet(jRow, "reason",    JsonString(SqlGetString(q, 1)));
        jRow = JsonObjectSet(jRow, "logged_at", JsonInt   (SqlGetInt   (q, 2)));
        jRows = JsonArrayInsert(jRows, jRow);
    }
    return jRows;
}

// Returns unix timestamp of last ritual, or 0 if none.
int KsGetLastRitualAt(object oPC)
{
    sqlquery q = SqlPrepareQueryCampaign("karmic_scales",
        "SELECT ritual_at FROM ks_cooldowns WHERE uuid = @uuid");
    SqlBindString(q, "@uuid", GetObjectUUID(oPC));
    if(SqlStep(q)) return SqlGetInt(q, 0);
    return 0;
}

void KsSetRitualAt(object oPC)
{
    sqlquery q = SqlPrepareQueryCampaign("karmic_scales",
        "INSERT OR REPLACE INTO ks_cooldowns (uuid, ritual_at) "
        "VALUES (@uuid, strftime('%s','now'))");
    SqlBindString(q, "@uuid", GetObjectUUID(oPC));
    SqlStep(q);
}

// Returns current unix timestamp from SQLite.
int KsGetUnixNow()
{
    sqlquery q = SqlPrepareQueryCampaign("karmic_scales",
        "SELECT strftime('%s','now')");
    if(SqlStep(q)) return SqlGetInt(q, 0);
    return 0;
}
