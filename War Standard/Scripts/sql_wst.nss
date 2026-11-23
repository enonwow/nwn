// =============================================================================
// sql_wst.nss
// =============================================================================
// Campaign SQLite persistence for the War Standard system.
//
// Tables:
//   wst_standards — one row per active standard, keyed by auto-increment id.
//                   Rows are removed when a standard expires or is destroyed.
//
// Design: standards are restored from DB on module load by recreating their
// placeables at stored positions. Each placeable carries WST_LVAR_ID so that
// heartbeat and event scripts can join back to the DB row.
// =============================================================================

const string WST_DB      = "war_standard";
const string WST_TBL_STD = "wst_standards";

// =============================================================================
// Schema
// =============================================================================
void WstCreateTables()
{
    sqlquery sql = SqlPrepareQueryCampaign(WST_DB,
        "CREATE TABLE IF NOT EXISTS " + WST_TBL_STD + " ("
        + "id INTEGER PRIMARY KEY AUTOINCREMENT, "
        + "area_tag TEXT NOT NULL, "
        + "x REAL NOT NULL, "
        + "y REAL NOT NULL, "
        + "z REAL NOT NULL, "
        + "owner_uuid TEXT NOT NULL, "
        + "owner_name TEXT NOT NULL, "
        + "type INTEGER NOT NULL DEFAULT 0, "
        + "inscription TEXT NOT NULL DEFAULT '', "
        + "hp INTEGER NOT NULL DEFAULT 20, "
        + "placed_at INTEGER NOT NULL, "
        + "expires_at INTEGER NOT NULL);");
    SqlStep(sql);
}

// =============================================================================
// Time helper
// =============================================================================
int WstNowUnix()
{
    sqlquery sql = SqlPrepareQueryCampaign(WST_DB, "SELECT strftime('%s', 'now');");
    SqlStep(sql);
    return SqlGetInt(sql, 0);
}

// =============================================================================
// Insert / Delete
// =============================================================================
int WstInsertStandard(string sAreaTag, float fX, float fY, float fZ,
                      string sOwnerUUID, string sOwnerName,
                      int nType, string sInscription, int nPlacedAt, int nExpiresAt)
{
    sqlquery sql = SqlPrepareQueryCampaign(WST_DB,
        "INSERT INTO " + WST_TBL_STD + " "
        + "(area_tag, x, y, z, owner_uuid, owner_name, type, inscription, placed_at, expires_at) "
        + "VALUES (@area, @x, @y, @z, @uuid, @nm, @ty, @ins, @pat, @exp);");
    SqlBindString(sql, "@area", sAreaTag);
    SqlBindFloat(sql,  "@x",    fX);
    SqlBindFloat(sql,  "@y",    fY);
    SqlBindFloat(sql,  "@z",    fZ);
    SqlBindString(sql, "@uuid", sOwnerUUID);
    SqlBindString(sql, "@nm",   sOwnerName);
    SqlBindInt(sql,    "@ty",   nType);
    SqlBindString(sql, "@ins",  sInscription);
    SqlBindInt(sql,    "@pat",  nPlacedAt);
    SqlBindInt(sql,    "@exp",  nExpiresAt);
    SqlStep(sql);

    sql = SqlPrepareQueryCampaign(WST_DB, "SELECT last_insert_rowid();");
    SqlStep(sql);
    return SqlGetInt(sql, 0);
}

void WstDeleteStandard(int nId)
{
    sqlquery sql = SqlPrepareQueryCampaign(WST_DB,
        "DELETE FROM " + WST_TBL_STD + " WHERE id = @id;");
    SqlBindInt(sql, "@id", nId);
    SqlStep(sql);
}

// =============================================================================
// Update
// =============================================================================
void WstSetStandardHp(int nId, int nHp)
{
    sqlquery sql = SqlPrepareQueryCampaign(WST_DB,
        "UPDATE " + WST_TBL_STD + " SET hp = @hp WHERE id = @id;");
    SqlBindInt(sql, "@hp", nHp);
    SqlBindInt(sql, "@id", nId);
    SqlStep(sql);
}

// =============================================================================
// Queries
// =============================================================================
struct WstRow
{
    int    id;
    string areaTag;
    float  x;
    float  y;
    float  z;
    string ownerUUID;
    string ownerName;
    int    nType;
    string inscription;
    int    hp;
    int    placedAt;
    int    expiresAt;
};

struct WstRow WstGetStandard(int nId)
{
    struct WstRow s;
    s.id = 0;

    sqlquery sql = SqlPrepareQueryCampaign(WST_DB,
        "SELECT area_tag, x, y, z, owner_uuid, owner_name, type, inscription, hp, placed_at, expires_at "
        + "FROM " + WST_TBL_STD + " WHERE id = @id;");
    SqlBindInt(sql, "@id", nId);
    if(SqlStep(sql))
    {
        s.id          = nId;
        s.areaTag     = SqlGetString(sql, 0);
        s.x           = SqlGetFloat(sql,  1);
        s.y           = SqlGetFloat(sql,  2);
        s.z           = SqlGetFloat(sql,  3);
        s.ownerUUID   = SqlGetString(sql, 4);
        s.ownerName   = SqlGetString(sql, 5);
        s.nType       = SqlGetInt(sql,    6);
        s.inscription = SqlGetString(sql, 7);
        s.hp          = SqlGetInt(sql,    8);
        s.placedAt    = SqlGetInt(sql,    9);
        s.expiresAt   = SqlGetInt(sql,    10);
    }
    return s;
}

// Returns all standard IDs, oldest first.
sqlquery WstQueryAllIds()
{
    return SqlPrepareQueryCampaign(WST_DB,
        "SELECT id FROM " + WST_TBL_STD + " ORDER BY placed_at ASC;");
}

// Returns all standards placed in a specific area.
sqlquery WstQueryByArea(string sAreaTag)
{
    sqlquery sql = SqlPrepareQueryCampaign(WST_DB,
        "SELECT id, type, x, y, z FROM " + WST_TBL_STD
        + " WHERE area_tag = @area ORDER BY placed_at ASC;");
    SqlBindString(sql, "@area", sAreaTag);
    return sql;
}

// Returns IDs of standards that have passed their expiry time.
sqlquery WstQueryExpired(int nNow)
{
    sqlquery sql = SqlPrepareQueryCampaign(WST_DB,
        "SELECT id FROM " + WST_TBL_STD + " WHERE expires_at <= @now;");
    SqlBindInt(sql, "@now", nNow);
    return sql;
}

int WstCountInArea(string sAreaTag)
{
    sqlquery sql = SqlPrepareQueryCampaign(WST_DB,
        "SELECT COUNT(*) FROM " + WST_TBL_STD + " WHERE area_tag = @area;");
    SqlBindString(sql, "@area", sAreaTag);
    if(SqlStep(sql)) return SqlGetInt(sql, 0);
    return 0;
}

// Returns all distinct area tags that have at least one active standard.
sqlquery WstQueryActiveAreas()
{
    return SqlPrepareQueryCampaign(WST_DB,
        "SELECT DISTINCT area_tag FROM " + WST_TBL_STD + ";");
}
