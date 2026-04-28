// sql_san.nss — SQLite schema and data access for the Sanity module.

const string SAN_DB            = "sanity";
const int    SAN_MAX           = 100;
const int    SAN_EVENT_LOG_MAX = 8;    // rows kept in recent-events display

void SanCreateTables()
{
    sqlquery q = SqlPrepareQueryCampaign(SAN_DB,
        "CREATE TABLE IF NOT EXISTS san_chars ("
        "  uuid           TEXT PRIMARY KEY,"
        "  sanity         INTEGER NOT NULL DEFAULT 100,"
        "  last_meditate  INTEGER NOT NULL DEFAULT 0,"
        "  last_seen      INTEGER NOT NULL DEFAULT 0"
        ")");
    SqlStep(q);

    q = SqlPrepareQueryCampaign(SAN_DB,
        "CREATE TABLE IF NOT EXISTS san_events ("
        "  id     INTEGER PRIMARY KEY AUTOINCREMENT,"
        "  uuid   TEXT    NOT NULL,"
        "  delta  INTEGER NOT NULL,"
        "  reason TEXT    NOT NULL DEFAULT '',"
        "  ts     INTEGER NOT NULL DEFAULT (strftime('%s','now'))"
        ")");
    SqlStep(q);
}

void SanEnsureChar(object oPC)
{
    sqlquery q = SqlPrepareQueryCampaign(SAN_DB,
        "INSERT OR IGNORE INTO san_chars (uuid, sanity, last_meditate, last_seen)"
        " VALUES (@uuid, 100, 0, strftime('%s','now'))");
    SqlBindString(q, "@uuid", GetObjectUUID(oPC));
    SqlStep(q);
}

int SanGetSanity(object oPC)
{
    SanEnsureChar(oPC);
    sqlquery q = SqlPrepareQueryCampaign(SAN_DB,
        "SELECT sanity FROM san_chars WHERE uuid = @uuid");
    SqlBindString(q, "@uuid", GetObjectUUID(oPC));
    if(SqlStep(q)) return SqlGetInt(q, 0);
    return SAN_MAX;
}

void SanSetSanity(object oPC, int nValue)
{
    if(nValue < 0)       nValue = 0;
    if(nValue > SAN_MAX) nValue = SAN_MAX;
    sqlquery q = SqlPrepareQueryCampaign(SAN_DB,
        "UPDATE san_chars SET sanity = @san, last_seen = strftime('%s','now')"
        " WHERE uuid = @uuid");
    SqlBindInt   (q, "@san",  nValue);
    SqlBindString(q, "@uuid", GetObjectUUID(oPC));
    SqlStep(q);
}

// Returns 1 if the meditate cooldown has elapsed.
int SanCanMeditate(object oPC, int nCooldownSecs)
{
    SanEnsureChar(oPC);
    sqlquery q = SqlPrepareQueryCampaign(SAN_DB,
        "SELECT CASE WHEN strftime('%s','now') - last_meditate >= @cd THEN 1 ELSE 0 END"
        " FROM san_chars WHERE uuid = @uuid");
    SqlBindInt   (q, "@cd",   nCooldownSecs);
    SqlBindString(q, "@uuid", GetObjectUUID(oPC));
    if(SqlStep(q)) return SqlGetInt(q, 0);
    return 1;
}

void SanRecordMeditate(object oPC)
{
    sqlquery q = SqlPrepareQueryCampaign(SAN_DB,
        "UPDATE san_chars SET last_meditate = strftime('%s','now') WHERE uuid = @uuid");
    SqlBindString(q, "@uuid", GetObjectUUID(oPC));
    SqlStep(q);
}

void SanLogEvent(object oPC, int nDelta, string sReason)
{
    sqlquery q = SqlPrepareQueryCampaign(SAN_DB,
        "INSERT INTO san_events (uuid, delta, reason) VALUES (@uuid, @delta, @reason)");
    SqlBindString(q, "@uuid",   GetObjectUUID(oPC));
    SqlBindInt   (q, "@delta",  nDelta);
    SqlBindString(q, "@reason", sReason);
    SqlStep(q);

    // Trim to last 50 rows per character to prevent unbounded growth.
    q = SqlPrepareQueryCampaign(SAN_DB,
        "DELETE FROM san_events WHERE uuid = @uuid AND id NOT IN"
        " (SELECT id FROM san_events WHERE uuid = @uuid ORDER BY id DESC LIMIT 50)");
    SqlBindString(q, "@uuid", GetObjectUUID(oPC));
    SqlStep(q);
}

// Returns JsonArray of {delta, reason, ts}, newest first, up to nLimit entries.
json SanGetRecentEvents(object oPC, int nLimit)
{
    json jRows = JsonArray();
    sqlquery q = SqlPrepareQueryCampaign(SAN_DB,
        "SELECT delta, reason, ts FROM san_events"
        " WHERE uuid = @uuid ORDER BY id DESC LIMIT @lim");
    SqlBindString(q, "@uuid", GetObjectUUID(oPC));
    SqlBindInt   (q, "@lim",  nLimit);
    while(SqlStep(q))
    {
        json jRow = JsonObject();
        jRow = JsonObjectSet(jRow, "delta",  JsonInt   (SqlGetInt   (q, 0)));
        jRow = JsonObjectSet(jRow, "reason", JsonString(SqlGetString(q, 1)));
        jRow = JsonObjectSet(jRow, "ts",     JsonInt   (SqlGetInt   (q, 2)));
        jRows = JsonArrayInsert(jRows, jRow);
    }
    return jRows;
}

// Adjusts sanity by nDelta, logs the event, and returns the new value.
// Returns -1 if the value did not change (already at boundary).
int SanAdjust(object oPC, int nDelta, string sReason)
{
    SanEnsureChar(oPC);
    int nOld = SanGetSanity(oPC);
    int nNew = nOld + nDelta;
    if(nNew < 0)       nNew = 0;
    if(nNew > SAN_MAX) nNew = SAN_MAX;
    if(nNew == nOld)   return -1;
    SanSetSanity(oPC, nNew);
    SanLogEvent(oPC, nNew - nOld, sReason);
    return nNew;
}
