#include "lib_drm_def"

void DrmCreateTables()
{
    sqlquery q = SqlPrepareQueryCampaign("dreamcodex",
        "CREATE TABLE IF NOT EXISTS drm_sessions ("
        "  id          INTEGER PRIMARY KEY AUTOINCREMENT,"
        "  char_uuid   TEXT    NOT NULL,"
        "  vision_ids  TEXT    DEFAULT '[]',"
        "  accepted_ids TEXT   DEFAULT '[]',"
        "  session_at  INTEGER DEFAULT 0"
        ")");
    SqlStep(q);

    q = SqlPrepareQueryCampaign("dreamcodex",
        "CREATE TABLE IF NOT EXISTS drm_cooldowns ("
        "  char_uuid   TEXT    PRIMARY KEY,"
        "  last_trance INTEGER DEFAULT 0"
        ")");
    SqlStep(q);
}

// Returns unix timestamp of last trance for this PC, or 0 if never.
int DrmGetLastTrance(object oPC)
{
    sqlquery q = SqlPrepareQueryCampaign("dreamcodex",
        "SELECT last_trance FROM drm_cooldowns WHERE char_uuid = @uuid");
    SqlBindString(q, "@uuid", GetObjectUUID(oPC));
    if(SqlStep(q)) return SqlGetInt(q, 0);
    return 0;
}

// Returns TRUE if the cooldown has expired.
int DrmCooldownReady(object oPC)
{
    int nLast = DrmGetLastTrance(oPC);
    if(nLast == 0) return TRUE;
    sqlquery q = SqlPrepareQueryCampaign("dreamcodex",
        "SELECT (strftime('%s','now') - @last) >= @secs");
    SqlBindInt(q, "@last", nLast);
    SqlBindInt(q, "@secs", DRM_COOLDOWN_HOURS * 3600);
    if(SqlStep(q)) return SqlGetInt(q, 0);
    return FALSE;
}

// Returns seconds remaining on cooldown (0 if ready).
int DrmCooldownRemaining(object oPC)
{
    int nLast = DrmGetLastTrance(oPC);
    if(nLast == 0) return 0;
    int nCooldownSecs = DRM_COOLDOWN_HOURS * 3600;
    sqlquery q = SqlPrepareQueryCampaign("dreamcodex",
        "SELECT MAX(0, @secs - (strftime('%s','now') - @last))");
    SqlBindInt(q, "@secs", nCooldownSecs);
    SqlBindInt(q, "@last", nLast);
    if(SqlStep(q)) return SqlGetInt(q, 0);
    return 0;
}

void DrmSetCooldown(object oPC)
{
    sqlquery q = SqlPrepareQueryCampaign("dreamcodex",
        "INSERT OR REPLACE INTO drm_cooldowns (char_uuid, last_trance) "
        "VALUES (@uuid, strftime('%s','now'))");
    SqlBindString(q, "@uuid", GetObjectUUID(oPC));
    SqlStep(q);
}

void DrmSaveSession(object oPC, json jVisionIds, json jAcceptedIds)
{
    sqlquery q = SqlPrepareQueryCampaign("dreamcodex",
        "INSERT INTO drm_sessions (char_uuid, vision_ids, accepted_ids, session_at) "
        "VALUES (@uuid, @vids, @aids, strftime('%s','now'))");
    SqlBindString(q, "@uuid", GetObjectUUID(oPC));
    SqlBindString(q, "@vids", JsonDump(jVisionIds));
    SqlBindString(q, "@aids", JsonDump(jAcceptedIds));
    SqlStep(q);

    // Keep only DRM_JOURNAL_MAX most recent sessions per character.
    q = SqlPrepareQueryCampaign("dreamcodex",
        "DELETE FROM drm_sessions WHERE char_uuid = @uuid AND id NOT IN ("
        "  SELECT id FROM drm_sessions WHERE char_uuid = @uuid2 "
        "  ORDER BY session_at DESC LIMIT @max)");
    SqlBindString(q, "@uuid",  GetObjectUUID(oPC));
    SqlBindString(q, "@uuid2", GetObjectUUID(oPC));
    SqlBindInt   (q, "@max",   DRM_JOURNAL_MAX);
    SqlStep(q);
}

// Returns JsonArray of journal rows: [{id, session_at, vision_ids, accepted_ids}, ...]
json DrmGetJournal(object oPC)
{
    json jRows = JsonArray();
    sqlquery q = SqlPrepareQueryCampaign("dreamcodex",
        "SELECT id, session_at, vision_ids, accepted_ids FROM drm_sessions "
        "WHERE char_uuid = @uuid ORDER BY session_at DESC LIMIT @max");
    SqlBindString(q, "@uuid", GetObjectUUID(oPC));
    SqlBindInt   (q, "@max",  DRM_JOURNAL_MAX);
    while(SqlStep(q))
    {
        json jRow = JsonObject();
        jRow = JsonObjectSet(jRow, "id",          JsonInt   (SqlGetInt   (q, 0)));
        jRow = JsonObjectSet(jRow, "session_at",  JsonInt   (SqlGetInt   (q, 1)));
        jRow = JsonObjectSet(jRow, "vision_ids",  JsonString(SqlGetString(q, 2)));
        jRow = JsonObjectSet(jRow, "accepted_ids",JsonString(SqlGetString(q, 3)));
        jRows = JsonArrayInsert(jRows, jRow);
    }
    return jRows;
}

// Returns "DD.MM.RR HH:MM" from unix timestamp via SQLite.
string DrmFormatDate(int nUnix)
{
    sqlquery q = SqlPrepareQueryCampaign("dreamcodex",
        "SELECT strftime('%d.%m %H:%M', @ts, 'unixepoch')");
    SqlBindInt(q, "@ts", nUnix);
    if(SqlStep(q)) return SqlGetString(q, 0);
    return "??";
}
