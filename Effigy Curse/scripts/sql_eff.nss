#include "lib_eff_def"

// ----------------------------------------------------------------
// Schema
// ----------------------------------------------------------------

void EffCreateTables()
{
    sqlquery q = SqlPrepareQueryCampaign("effigy",
        "CREATE TABLE IF NOT EXISTS eff_players ("
        "  uuid TEXT PRIMARY KEY,"
        "  char_name TEXT DEFAULT '',"
        "  last_online INTEGER DEFAULT 0"
        ")");
    SqlStep(q);

    q = SqlPrepareQueryCampaign("effigy",
        "CREATE TABLE IF NOT EXISTS eff_effigies ("
        "  id INTEGER PRIMARY KEY AUTOINCREMENT,"
        "  creator_uuid TEXT NOT NULL,"
        "  target_uuid TEXT NOT NULL,"
        "  curse_type INTEGER NOT NULL,"
        "  created_at INTEGER DEFAULT 0,"
        "  is_active INTEGER DEFAULT 1,"
        "  smashed INTEGER DEFAULT 0"
        ")");
    SqlStep(q);

    // Tracks which effigies a PC has detected (so they can see them in the UI)
    q = SqlPrepareQueryCampaign("effigy",
        "CREATE TABLE IF NOT EXISTS eff_detections ("
        "  effigy_id INTEGER NOT NULL,"
        "  target_uuid TEXT NOT NULL,"
        "  detected_at INTEGER DEFAULT 0,"
        "  PRIMARY KEY (effigy_id, target_uuid)"
        ")");
    SqlStep(q);
}

// ----------------------------------------------------------------
// Players
// ----------------------------------------------------------------

void EffRegisterPlayerDb(object oPC)
{
    sqlquery q = SqlPrepareQueryCampaign("effigy",
        "INSERT OR REPLACE INTO eff_players (uuid, char_name, last_online) "
        "VALUES (@uuid, @name, strftime('%s','now'))");
    SqlBindString(q, "@uuid", GetObjectUUID(oPC));
    SqlBindString(q, "@name", GetName(oPC));
    SqlStep(q);
}

// Returns JsonArray of {uuid, char_name} for all known players except oPC
json EffGetKnownPlayers(object oPC)
{
    json jResult = JsonArray();
    sqlquery q = SqlPrepareQueryCampaign("effigy",
        "SELECT uuid, char_name FROM eff_players "
        "WHERE uuid != @self ORDER BY char_name ASC");
    SqlBindString(q, "@self", GetObjectUUID(oPC));
    while(SqlStep(q))
    {
        json jRow = JsonObject();
        jRow = JsonObjectSet(jRow, "uuid",      JsonString(SqlGetString(q, 0)));
        jRow = JsonObjectSet(jRow, "char_name", JsonString(SqlGetString(q, 1)));
        jResult = JsonArrayInsert(jResult, jRow);
    }
    return jResult;
}

string EffGetPlayerName(string sUuid)
{
    sqlquery q = SqlPrepareQueryCampaign("effigy",
        "SELECT char_name FROM eff_players WHERE uuid = @uuid");
    SqlBindString(q, "@uuid", sUuid);
    if(SqlStep(q)) return SqlGetString(q, 0);
    return "Nieznany";
}

// ----------------------------------------------------------------
// Effigies — creation / lookup
// ----------------------------------------------------------------

int EffCountActiveByCreator(string sCreatorUuid)
{
    sqlquery q = SqlPrepareQueryCampaign("effigy",
        "SELECT COUNT(*) FROM eff_effigies "
        "WHERE creator_uuid = @uuid AND is_active = 1");
    SqlBindString(q, "@uuid", sCreatorUuid);
    if(SqlStep(q)) return SqlGetInt(q, 0);
    return 0;
}

int EffCreateEffigy(string sCreatorUuid, string sTargetUuid, int nCurseType)
{
    sqlquery q = SqlPrepareQueryCampaign("effigy",
        "INSERT INTO eff_effigies (creator_uuid, target_uuid, curse_type, created_at) "
        "VALUES (@creator, @target, @type, strftime('%s','now'))");
    SqlBindString(q, "@creator", sCreatorUuid);
    SqlBindString(q, "@target",  sTargetUuid);
    SqlBindInt(q,    "@type",    nCurseType);
    SqlStep(q);

    q = SqlPrepareQueryCampaign("effigy",
        "SELECT last_insert_rowid()");
    if(SqlStep(q)) return SqlGetInt(q, 0);
    return 0;
}

// Returns JsonArray of active effigy rows for creator
json EffGetMyEffigies(string sCreatorUuid)
{
    json jResult = JsonArray();
    sqlquery q = SqlPrepareQueryCampaign("effigy",
        "SELECT e.id, p.char_name, e.curse_type, "
        "  CAST((strftime('%s','now') - e.created_at) / 86400 AS INTEGER) AS days_active "
        "FROM eff_effigies e "
        "LEFT JOIN eff_players p ON p.uuid = e.target_uuid "
        "WHERE e.creator_uuid = @uuid AND e.is_active = 1 "
        "ORDER BY e.created_at DESC");
    SqlBindString(q, "@uuid", sCreatorUuid);
    while(SqlStep(q))
    {
        json jRow = JsonObject();
        jRow = JsonObjectSet(jRow, "id",         JsonInt(SqlGetInt(q, 0)));
        jRow = JsonObjectSet(jRow, "target_name",JsonString(SqlGetString(q, 1)));
        jRow = JsonObjectSet(jRow, "curse_type", JsonInt(SqlGetInt(q, 2)));
        jRow = JsonObjectSet(jRow, "days",       JsonInt(SqlGetInt(q, 3)));
        jResult = JsonArrayInsert(jResult, jRow);
    }
    return jResult;
}

// Returns JsonArray of active effigies targeting sTargetUuid (all of them — for heartbeat)
json EffGetEffigiesTargeting(string sTargetUuid)
{
    json jResult = JsonArray();
    sqlquery q = SqlPrepareQueryCampaign("effigy",
        "SELECT id, creator_uuid, curse_type FROM eff_effigies "
        "WHERE target_uuid = @uuid AND is_active = 1");
    SqlBindString(q, "@uuid", sTargetUuid);
    while(SqlStep(q))
    {
        json jRow = JsonObject();
        jRow = JsonObjectSet(jRow, "id",           JsonInt(SqlGetInt(q, 0)));
        jRow = JsonObjectSet(jRow, "creator_uuid", JsonString(SqlGetString(q, 1)));
        jRow = JsonObjectSet(jRow, "curse_type",   JsonInt(SqlGetInt(q, 2)));
        jResult = JsonArrayInsert(jResult, jRow);
    }
    return jResult;
}

void EffDeactivateEffigy(int nEffigyId, int nSmashed)
{
    sqlquery q = SqlPrepareQueryCampaign("effigy",
        "UPDATE eff_effigies SET is_active = 0, smashed = @smashed "
        "WHERE id = @id");
    SqlBindInt(q, "@smashed", nSmashed);
    SqlBindInt(q, "@id",      nEffigyId);
    SqlStep(q);
}

// Gets a single effigy row (used for smash validation — must belong to creator)
json EffGetEffigyById(int nId, string sCreatorUuid)
{
    sqlquery q = SqlPrepareQueryCampaign("effigy",
        "SELECT id, target_uuid, curse_type, is_active FROM eff_effigies "
        "WHERE id = @id AND creator_uuid = @creator");
    SqlBindInt(q,    "@id",      nId);
    SqlBindString(q, "@creator", sCreatorUuid);
    if(SqlStep(q))
    {
        json jRow = JsonObject();
        jRow = JsonObjectSet(jRow, "id",         JsonInt(SqlGetInt(q, 0)));
        jRow = JsonObjectSet(jRow, "target_uuid",JsonString(SqlGetString(q, 1)));
        jRow = JsonObjectSet(jRow, "curse_type", JsonInt(SqlGetInt(q, 2)));
        jRow = JsonObjectSet(jRow, "is_active",  JsonInt(SqlGetInt(q, 3)));
        return jRow;
    }
    return JsonNull();
}

// ----------------------------------------------------------------
// Detections
// ----------------------------------------------------------------

void EffMarkDetected(int nEffigyId, string sTargetUuid)
{
    sqlquery q = SqlPrepareQueryCampaign("effigy",
        "INSERT OR IGNORE INTO eff_detections (effigy_id, target_uuid, detected_at) "
        "VALUES (@id, @uuid, strftime('%s','now'))");
    SqlBindInt(q,    "@id",   nEffigyId);
    SqlBindString(q, "@uuid", sTargetUuid);
    SqlStep(q);
}

int EffIsDetected(int nEffigyId, string sTargetUuid)
{
    sqlquery q = SqlPrepareQueryCampaign("effigy",
        "SELECT COUNT(*) FROM eff_detections "
        "WHERE effigy_id = @id AND target_uuid = @uuid");
    SqlBindInt(q,    "@id",   nEffigyId);
    SqlBindString(q, "@uuid", sTargetUuid);
    if(SqlStep(q)) return SqlGetInt(q, 0);
    return 0;
}

// Returns detected effigies affecting oPC (with creator names where detected)
json EffGetDetectedAffecting(string sTargetUuid)
{
    json jResult = JsonArray();
    sqlquery q = SqlPrepareQueryCampaign("effigy",
        "SELECT e.id, p.char_name, e.curse_type "
        "FROM eff_effigies e "
        "INNER JOIN eff_detections d ON d.effigy_id = e.id AND d.target_uuid = @uuid "
        "LEFT JOIN eff_players p ON p.uuid = e.creator_uuid "
        "WHERE e.target_uuid = @uuid AND e.is_active = 1");
    SqlBindString(q, "@uuid", sTargetUuid);
    while(SqlStep(q))
    {
        json jRow = JsonObject();
        jRow = JsonObjectSet(jRow, "id",           JsonInt(SqlGetInt(q, 0)));
        jRow = JsonObjectSet(jRow, "creator_name", JsonString(SqlGetString(q, 1)));
        jRow = JsonObjectSet(jRow, "curse_type",   JsonInt(SqlGetInt(q, 2)));
        jResult = JsonArrayInsert(jResult, jRow);
    }
    return jResult;
}

void EffDeleteDetection(int nEffigyId, string sTargetUuid)
{
    sqlquery q = SqlPrepareQueryCampaign("effigy",
        "DELETE FROM eff_detections WHERE effigy_id = @id AND target_uuid = @uuid");
    SqlBindInt(q,    "@id",   nEffigyId);
    SqlBindString(q, "@uuid", sTargetUuid);
    SqlStep(q);
}

int EffCountUndetectedAffecting(string sTargetUuid)
{
    sqlquery q = SqlPrepareQueryCampaign("effigy",
        "SELECT COUNT(*) FROM eff_effigies e "
        "WHERE e.target_uuid = @uuid AND e.is_active = 1 "
        "AND NOT EXISTS ("
        "  SELECT 1 FROM eff_detections d "
        "  WHERE d.effigy_id = e.id AND d.target_uuid = @uuid"
        ")");
    SqlBindString(q, "@uuid", sTargetUuid);
    if(SqlStep(q)) return SqlGetInt(q, 0);
    return 0;
}
