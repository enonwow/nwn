// sql_brand.nss -- Database layer for Brand System
// Campaign DB: "brand"
//   brand_marks(uuid, location, type, name, origin, brander_name, is_concealed, is_scarred, applied_at)
//   brand_log  (brander_uuid, branded_uuid, location, type, applied_at)

const string BRAND_DB = "brand";

void BrandCreateTables()
{
    sqlquery q = SqlPrepareQueryCampaign(BRAND_DB,
        "CREATE TABLE IF NOT EXISTS brand_marks ("
        "  uuid         TEXT NOT NULL,"
        "  location     INTEGER NOT NULL,"
        "  type         INTEGER NOT NULL,"
        "  name         TEXT DEFAULT '',"
        "  origin       TEXT DEFAULT '',"
        "  brander_name TEXT DEFAULT '',"
        "  is_concealed INTEGER DEFAULT 0,"
        "  is_scarred   INTEGER DEFAULT 0,"
        "  applied_at   INTEGER DEFAULT 0,"
        "  PRIMARY KEY (uuid, location)"
        ")");
    SqlStep(q);

    q = SqlPrepareQueryCampaign(BRAND_DB,
        "CREATE TABLE IF NOT EXISTS brand_log ("
        "  id           INTEGER PRIMARY KEY AUTOINCREMENT,"
        "  brander_uuid TEXT DEFAULT '',"
        "  branded_uuid TEXT NOT NULL,"
        "  location     INTEGER NOT NULL,"
        "  type         INTEGER NOT NULL,"
        "  applied_at   INTEGER DEFAULT 0"
        ")");
    SqlStep(q);
}

// Returns JsonArray of all brands for a character.
// Each element: {location, type, name, origin, brander_name, is_concealed, is_scarred, applied_at}
json BrandGetAll(string sUuid)
{
    json jRows = JsonArray();
    sqlquery q = SqlPrepareQueryCampaign(BRAND_DB,
        "SELECT location, type, name, origin, brander_name, is_concealed, is_scarred, applied_at"
        " FROM brand_marks WHERE uuid = @uuid ORDER BY location");
    SqlBindString(q, "@uuid", sUuid);
    while(SqlStep(q))
    {
        json jRow = JsonObject();
        jRow = JsonObjectSet(jRow, "location",     JsonInt   (SqlGetInt   (q, 0)));
        jRow = JsonObjectSet(jRow, "type",         JsonInt   (SqlGetInt   (q, 1)));
        jRow = JsonObjectSet(jRow, "name",         JsonString(SqlGetString(q, 2)));
        jRow = JsonObjectSet(jRow, "origin",       JsonString(SqlGetString(q, 3)));
        jRow = JsonObjectSet(jRow, "brander_name", JsonString(SqlGetString(q, 4)));
        jRow = JsonObjectSet(jRow, "is_concealed", JsonInt   (SqlGetInt   (q, 5)));
        jRow = JsonObjectSet(jRow, "is_scarred",   JsonInt   (SqlGetInt   (q, 6)));
        jRow = JsonObjectSet(jRow, "applied_at",   JsonInt   (SqlGetInt   (q, 7)));
        jRows = JsonArrayInsert(jRows, jRow);
    }
    return jRows;
}

// Returns a single brand at given location, or JsonNull if empty.
json BrandGetAtLoc(string sUuid, int nLoc)
{
    sqlquery q = SqlPrepareQueryCampaign(BRAND_DB,
        "SELECT location, type, name, origin, brander_name, is_concealed, is_scarred, applied_at"
        " FROM brand_marks WHERE uuid = @uuid AND location = @loc");
    SqlBindString(q, "@uuid", sUuid);
    SqlBindInt   (q, "@loc",  nLoc);
    if(!SqlStep(q)) return JsonNull();
    json jRow = JsonObject();
    jRow = JsonObjectSet(jRow, "location",     JsonInt   (SqlGetInt   (q, 0)));
    jRow = JsonObjectSet(jRow, "type",         JsonInt   (SqlGetInt   (q, 1)));
    jRow = JsonObjectSet(jRow, "name",         JsonString(SqlGetString(q, 2)));
    jRow = JsonObjectSet(jRow, "origin",       JsonString(SqlGetString(q, 3)));
    jRow = JsonObjectSet(jRow, "brander_name", JsonString(SqlGetString(q, 4)));
    jRow = JsonObjectSet(jRow, "is_concealed", JsonInt   (SqlGetInt   (q, 5)));
    jRow = JsonObjectSet(jRow, "is_scarred",   JsonInt   (SqlGetInt   (q, 6)));
    jRow = JsonObjectSet(jRow, "applied_at",   JsonInt   (SqlGetInt   (q, 7)));
    return jRow;
}

void BrandWrite(string sUuid, int nLoc, int nType, string sName, string sOrigin, string sBranderName)
{
    sqlquery q = SqlPrepareQueryCampaign(BRAND_DB,
        "INSERT OR REPLACE INTO brand_marks"
        " (uuid, location, type, name, origin, brander_name, is_concealed, is_scarred, applied_at)"
        " VALUES (@uuid, @loc, @type, @name, @origin, @brander, 0, 0, strftime('%s','now'))");
    SqlBindString(q, "@uuid",    sUuid);
    SqlBindInt   (q, "@loc",     nLoc);
    SqlBindInt   (q, "@type",    nType);
    SqlBindString(q, "@name",    sName);
    SqlBindString(q, "@origin",  sOrigin);
    SqlBindString(q, "@brander", sBranderName);
    SqlStep(q);
}

void BrandDeleteAtLoc(string sUuid, int nLoc)
{
    sqlquery q = SqlPrepareQueryCampaign(BRAND_DB,
        "DELETE FROM brand_marks WHERE uuid = @uuid AND location = @loc");
    SqlBindString(q, "@uuid", sUuid);
    SqlBindInt   (q, "@loc",  nLoc);
    SqlStep(q);
}

void BrandSetConcealed(string sUuid, int nLoc, int bConcealed)
{
    sqlquery q = SqlPrepareQueryCampaign(BRAND_DB,
        "UPDATE brand_marks SET is_concealed = @val WHERE uuid = @uuid AND location = @loc");
    SqlBindInt   (q, "@val",  bConcealed);
    SqlBindString(q, "@uuid", sUuid);
    SqlBindInt   (q, "@loc",  nLoc);
    SqlStep(q);
}

void BrandSetScarred(string sUuid, int nLoc)
{
    sqlquery q = SqlPrepareQueryCampaign(BRAND_DB,
        "UPDATE brand_marks SET is_scarred = 1 WHERE uuid = @uuid AND location = @loc");
    SqlBindString(q, "@uuid", sUuid);
    SqlBindInt   (q, "@loc",  nLoc);
    SqlStep(q);
}

void BrandLogEntry(string sBranderUuid, string sBrandedUuid, int nLoc, int nType)
{
    sqlquery q = SqlPrepareQueryCampaign(BRAND_DB,
        "INSERT INTO brand_log (brander_uuid, branded_uuid, location, type, applied_at)"
        " VALUES (@brander, @branded, @loc, @type, strftime('%s','now'))");
    SqlBindString(q, "@brander", sBranderUuid);
    SqlBindString(q, "@branded", sBrandedUuid);
    SqlBindInt   (q, "@loc",     nLoc);
    SqlBindInt   (q, "@type",    nType);
    SqlStep(q);
}

int BrandGetCount(string sUuid)
{
    sqlquery q = SqlPrepareQueryCampaign(BRAND_DB,
        "SELECT COUNT(*) FROM brand_marks WHERE uuid = @uuid");
    SqlBindString(q, "@uuid", sUuid);
    if(SqlStep(q)) return SqlGetInt(q, 0);
    return 0;
}
