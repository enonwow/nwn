#include "lib_btrk_def"

void BtrkCreateTables()
{
    sqlquery q = SqlPrepareQueryCampaign(BTRK_CAMPAIGN_DB,
        "CREATE TABLE IF NOT EXISTS blood_trails ("
        "  id          INTEGER PRIMARY KEY AUTOINCREMENT,"
        "  area_tag    TEXT    NOT NULL DEFAULT '',"
        "  pos_x       REAL    NOT NULL DEFAULT 0,"
        "  pos_y       REAL    NOT NULL DEFAULT 0,"
        "  pos_z       REAL    NOT NULL DEFAULT 0,"
        "  source_uuid TEXT    NOT NULL DEFAULT '',"
        "  source_name TEXT    NOT NULL DEFAULT '',"
        "  blood_amt   INTEGER NOT NULL DEFAULT 0,"
        "  created_at  INTEGER NOT NULL DEFAULT (strftime('%s','now')),"
        "  expires_at  INTEGER NOT NULL DEFAULT 0"
        ")");
    SqlStep(q);

    q = SqlPrepareQueryCampaign(BTRK_CAMPAIGN_DB,
        "CREATE INDEX IF NOT EXISTS idx_btrk_area ON blood_trails (area_tag, expires_at)");
    SqlStep(q);

    q = SqlPrepareQueryCampaign(BTRK_CAMPAIGN_DB,
        "CREATE TABLE IF NOT EXISTS btrk_discoveries ("
        "  tracker_uuid TEXT    NOT NULL,"
        "  trail_id     INTEGER NOT NULL,"
        "  found_at     INTEGER NOT NULL DEFAULT (strftime('%s','now')),"
        "  PRIMARY KEY (tracker_uuid, trail_id)"
        ")");
    SqlStep(q);
}

void BtrkInsertTrail(string sAreaTag, float fX, float fY, float fZ,
                     string sUUID, string sName, int nDamage)
{
    sqlquery q = SqlPrepareQueryCampaign(BTRK_CAMPAIGN_DB,
        "INSERT INTO blood_trails (area_tag, pos_x, pos_y, pos_z, source_uuid, source_name, blood_amt, expires_at) "
        "VALUES (@area, @x, @y, @z, @uuid, @name, @dmg, strftime('%s','now') + @exp)");
    SqlBindString(q, "@area", sAreaTag);
    SqlBindFloat (q, "@x",    fX);
    SqlBindFloat (q, "@y",    fY);
    SqlBindFloat (q, "@z",    fZ);
    SqlBindString(q, "@uuid", sUUID);
    SqlBindString(q, "@name", sName);
    SqlBindInt   (q, "@dmg",  nDamage);
    SqlBindInt   (q, "@exp",  BTRK_DECAY_COLD);
    SqlStep(q);
}

void BtrkDecayExpired()
{
    sqlquery q = SqlPrepareQueryCampaign(BTRK_CAMPAIGN_DB,
        "DELETE FROM blood_trails WHERE expires_at < strftime('%s','now')");
    SqlStep(q);

    // Orphaned discovery records after trail deletion
    q = SqlPrepareQueryCampaign(BTRK_CAMPAIGN_DB,
        "DELETE FROM btrk_discoveries "
        "WHERE trail_id NOT IN (SELECT id FROM blood_trails)");
    SqlStep(q);
}

// Returns JSON object for nearest undiscovered trail in area within BTRK_SEARCH_RANGE.
// Adds "dist" float field. Returns JsonNull() when nothing found.
json BtrkFindNearest(string sAreaTag, float fPX, float fPY, string sTrackerUUID)
{
    sqlquery q = SqlPrepareQueryCampaign(BTRK_CAMPAIGN_DB,
        "SELECT id, pos_x, pos_y, pos_z, source_name, source_uuid, blood_amt, created_at, "
        "       ((pos_x - @px) * (pos_x - @px) + (pos_y - @py) * (pos_y - @py)) AS dist2 "
        "FROM blood_trails "
        "WHERE area_tag = @area "
        "  AND expires_at > strftime('%s','now') "
        "  AND id NOT IN (SELECT trail_id FROM btrk_discoveries WHERE tracker_uuid = @tuuid) "
        "ORDER BY dist2 ASC "
        "LIMIT 1");
    SqlBindString(q, "@area",  sAreaTag);
    SqlBindFloat (q, "@px",    fPX);
    SqlBindFloat (q, "@py",    fPY);
    SqlBindString(q, "@tuuid", sTrackerUUID);

    if(!SqlStep(q)) return JsonNull();

    float fDX   = SqlGetFloat(q, 1) - fPX;
    float fDY   = SqlGetFloat(q, 2) - fPY;
    float fDist = sqrt(fDX * fDX + fDY * fDY);

    if(fDist > BTRK_SEARCH_RANGE) return JsonNull();

    json j = JsonObject();
    j = JsonObjectSet(j, "id",          JsonInt   (SqlGetInt   (q, 0)));
    j = JsonObjectSet(j, "pos_x",       JsonFloat (SqlGetFloat (q, 1)));
    j = JsonObjectSet(j, "pos_y",       JsonFloat (SqlGetFloat (q, 2)));
    j = JsonObjectSet(j, "pos_z",       JsonFloat (SqlGetFloat (q, 3)));
    j = JsonObjectSet(j, "source_name", JsonString(SqlGetString(q, 4)));
    j = JsonObjectSet(j, "source_uuid", JsonString(SqlGetString(q, 5)));
    j = JsonObjectSet(j, "blood_amt",   JsonInt   (SqlGetInt   (q, 6)));
    j = JsonObjectSet(j, "created_at",  JsonInt   (SqlGetInt   (q, 7)));
    j = JsonObjectSet(j, "dist",        JsonFloat (fDist));
    return j;
}

json BtrkGetTrailById(int nId)
{
    sqlquery q = SqlPrepareQueryCampaign(BTRK_CAMPAIGN_DB,
        "SELECT id, pos_x, pos_y, pos_z, source_name, source_uuid, blood_amt, created_at, area_tag "
        "FROM blood_trails WHERE id = @id AND expires_at > strftime('%s','now')");
    SqlBindInt(q, "@id", nId);
    if(!SqlStep(q)) return JsonNull();

    json j = JsonObject();
    j = JsonObjectSet(j, "id",          JsonInt   (SqlGetInt   (q, 0)));
    j = JsonObjectSet(j, "pos_x",       JsonFloat (SqlGetFloat (q, 1)));
    j = JsonObjectSet(j, "pos_y",       JsonFloat (SqlGetFloat (q, 2)));
    j = JsonObjectSet(j, "pos_z",       JsonFloat (SqlGetFloat (q, 3)));
    j = JsonObjectSet(j, "source_name", JsonString(SqlGetString(q, 4)));
    j = JsonObjectSet(j, "source_uuid", JsonString(SqlGetString(q, 5)));
    j = JsonObjectSet(j, "blood_amt",   JsonInt   (SqlGetInt   (q, 6)));
    j = JsonObjectSet(j, "created_at",  JsonInt   (SqlGetInt   (q, 7)));
    j = JsonObjectSet(j, "area_tag",    JsonString(SqlGetString(q, 8)));
    return j;
}

void BtrkMarkDiscovered(string sTrackerUUID, int nTrailId)
{
    sqlquery q = SqlPrepareQueryCampaign(BTRK_CAMPAIGN_DB,
        "INSERT OR IGNORE INTO btrk_discoveries (tracker_uuid, trail_id) VALUES (@uuid, @tid)");
    SqlBindString(q, "@uuid", sTrackerUUID);
    SqlBindInt   (q, "@tid",  nTrailId);
    SqlStep(q);
}

// Returns age in seconds using server-side SQLite clock for consistency.
int BtrkGetAgeSeconds(int nCreatedAt)
{
    sqlquery q = SqlPrepareQueryCampaign(BTRK_CAMPAIGN_DB,
        "SELECT CAST(strftime('%s','now') AS INTEGER) - @ts");
    SqlBindInt(q, "@ts", nCreatedAt);
    if(SqlStep(q)) return SqlGetInt(q, 0);
    return 0;
}

int BtrkTrailCountInArea(string sAreaTag)
{
    sqlquery q = SqlPrepareQueryCampaign(BTRK_CAMPAIGN_DB,
        "SELECT COUNT(*) FROM blood_trails WHERE area_tag = @area AND expires_at > strftime('%s','now')");
    SqlBindString(q, "@area", sAreaTag);
    if(SqlStep(q)) return SqlGetInt(q, 0);
    return 0;
}
