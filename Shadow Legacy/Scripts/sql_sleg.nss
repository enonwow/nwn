void SlegCreateTables()
{
    sqlquery q = SqlPrepareQueryCampaign("shadow_legacy",
        "CREATE TABLE IF NOT EXISTS sleg_records ("
        "  id            INTEGER PRIMARY KEY AUTOINCREMENT,"
        "  source_cdkey  TEXT    NOT NULL DEFAULT '',"
        "  source_uuid   TEXT    NOT NULL DEFAULT '',"
        "  source_name   TEXT    NOT NULL DEFAULT '',"
        "  legacy_type   INTEGER NOT NULL DEFAULT 0,"
        "  is_claimed    INTEGER NOT NULL DEFAULT 0,"
        "  claimed_uuid  TEXT    NOT NULL DEFAULT '',"
        "  recorded_at   INTEGER NOT NULL DEFAULT 0"
        ")");
    SqlStep(q);
}

// Store a new legacy record from a fallen character.
void SlegRecordLegacy(string sCDKey, string sCharUuid, string sCharName, int nType)
{
    sqlquery q = SqlPrepareQueryCampaign("shadow_legacy",
        "INSERT INTO sleg_records (source_cdkey, source_uuid, source_name, legacy_type, recorded_at)"
        " VALUES (@cdkey, @uuid, @name, @type, strftime('%s','now'))");
    SqlBindString(q, "@cdkey", sCDKey);
    SqlBindString(q, "@uuid",  sCharUuid);
    SqlBindString(q, "@name",  sCharName);
    SqlBindInt   (q, "@type",  nType);
    SqlStep(q);
}

// Returns all legacy records for a CD key as JsonArray [{id, source_name, legacy_type, is_claimed}].
json SlegGetLegacies(string sCDKey)
{
    json jRows = JsonArray();
    sqlquery q = SqlPrepareQueryCampaign("shadow_legacy",
        "SELECT id, source_name, legacy_type, is_claimed"
        " FROM sleg_records WHERE source_cdkey = @cdkey ORDER BY recorded_at DESC");
    SqlBindString(q, "@cdkey", sCDKey);
    while(SqlStep(q))
    {
        json jRow = JsonObject();
        jRow = JsonObjectSet(jRow, "id",          JsonInt   (SqlGetInt   (q, 0)));
        jRow = JsonObjectSet(jRow, "source_name", JsonString(SqlGetString(q, 1)));
        jRow = JsonObjectSet(jRow, "legacy_type", JsonInt   (SqlGetInt   (q, 2)));
        jRow = JsonObjectSet(jRow, "is_claimed",  JsonInt   (SqlGetInt   (q, 3)));
        jRows = JsonArrayInsert(jRows, jRow);
    }
    return jRows;
}

// Mark a legacy as claimed by the current character.
void SlegClaimLegacy(int nId, string sCharUuid)
{
    sqlquery q = SqlPrepareQueryCampaign("shadow_legacy",
        "UPDATE sleg_records SET is_claimed = 1, claimed_uuid = @uuid WHERE id = @id");
    SqlBindString(q, "@uuid", sCharUuid);
    SqlBindInt   (q, "@id",   nId);
    SqlStep(q);
}

// Returns the legacy type active on this character, or -1 if none.
int SlegGetActiveLegacyType(string sCharUuid)
{
    sqlquery q = SqlPrepareQueryCampaign("shadow_legacy",
        "SELECT legacy_type FROM sleg_records"
        " WHERE claimed_uuid = @uuid AND is_claimed = 1 LIMIT 1");
    SqlBindString(q, "@uuid", sCharUuid);
    if(SqlStep(q)) return SqlGetInt(q, 0);
    return -1;
}

// Returns single record by id, or JsonNull.
json SlegGetLegacyById(int nId)
{
    sqlquery q = SqlPrepareQueryCampaign("shadow_legacy",
        "SELECT id, source_name, legacy_type, is_claimed, claimed_uuid"
        " FROM sleg_records WHERE id = @id");
    SqlBindInt(q, "@id", nId);
    if(!SqlStep(q)) return JsonNull();
    json jRow = JsonObject();
    jRow = JsonObjectSet(jRow, "id",           JsonInt   (SqlGetInt   (q, 0)));
    jRow = JsonObjectSet(jRow, "source_name",  JsonString(SqlGetString(q, 1)));
    jRow = JsonObjectSet(jRow, "legacy_type",  JsonInt   (SqlGetInt   (q, 2)));
    jRow = JsonObjectSet(jRow, "is_claimed",   JsonInt   (SqlGetInt   (q, 3)));
    jRow = JsonObjectSet(jRow, "claimed_uuid", JsonString(SqlGetString(q, 4)));
    return jRow;
}

// True if this character has already claimed any legacy.
int SlegHasActiveLegacy(string sCharUuid)
{
    sqlquery q = SqlPrepareQueryCampaign("shadow_legacy",
        "SELECT COUNT(*) FROM sleg_records WHERE claimed_uuid = @uuid AND is_claimed = 1");
    SqlBindString(q, "@uuid", sCharUuid);
    if(SqlStep(q)) return SqlGetInt(q, 0) > 0;
    return FALSE;
}

// True if this character already has a recorded legacy (avoid duplicates on re-death).
int SlegHasRecord(string sCharUuid)
{
    sqlquery q = SqlPrepareQueryCampaign("shadow_legacy",
        "SELECT COUNT(*) FROM sleg_records WHERE source_uuid = @uuid");
    SqlBindString(q, "@uuid", sCharUuid);
    if(SqlStep(q)) return SqlGetInt(q, 0) > 0;
    return FALSE;
}

// Count of unclaimed legacies available for this CD key.
int SlegUnclaimedCount(string sCDKey)
{
    sqlquery q = SqlPrepareQueryCampaign("shadow_legacy",
        "SELECT COUNT(*) FROM sleg_records"
        " WHERE source_cdkey = @cdkey AND is_claimed = 0");
    SqlBindString(q, "@cdkey", sCDKey);
    if(SqlStep(q)) return SqlGetInt(q, 0);
    return 0;
}
