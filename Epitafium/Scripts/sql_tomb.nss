// sql_tomb.nss — SQLite schema and query wrappers for Epitafium

const int TOMB_EXPIRY_DAYS = 30;

void TombCreateTables()
{
    sqlquery q = SqlPrepareQueryCampaign("epitafium",
        "CREATE TABLE IF NOT EXISTS tomb_memorials ("
        "  id          INTEGER PRIMARY KEY AUTOINCREMENT,"
        "  char_uuid   TEXT    NOT NULL DEFAULT '',"
        "  char_name   TEXT    NOT NULL DEFAULT '',"
        "  area_tag    TEXT    NOT NULL DEFAULT '',"
        "  pos_x       REAL    NOT NULL DEFAULT 0,"
        "  pos_y       REAL    NOT NULL DEFAULT 0,"
        "  pos_z       REAL    NOT NULL DEFAULT 0,"
        "  cause       TEXT    NOT NULL DEFAULT '',"
        "  epitaph     TEXT    NOT NULL DEFAULT '',"
        "  tribute_cnt INTEGER NOT NULL DEFAULT 0,"
        "  died_at     INTEGER NOT NULL DEFAULT 0,"
        "  expires_at  INTEGER NOT NULL DEFAULT 0"
        ")");
    SqlStep(q);
}

// Returns newly inserted memorial id, or 0 on failure.
int TombInsertMemorial(
    string sCharUuid, string sCharName, string sAreaTag,
    float fX, float fY, float fZ,
    string sCause, string sEpitaph)
{
    sqlquery q = SqlPrepareQueryCampaign("epitafium",
        "INSERT INTO tomb_memorials "
        "  (char_uuid, char_name, area_tag, pos_x, pos_y, pos_z, cause, epitaph, died_at, expires_at) "
        "VALUES "
        "  (@uuid, @name, @area, @x, @y, @z, @cause, @epi, "
        "   strftime('%s','now'), strftime('%s','now') + @days * 86400)");
    SqlBindString(q, "@uuid",  sCharUuid);
    SqlBindString(q, "@name",  sCharName);
    SqlBindString(q, "@area",  sAreaTag);
    SqlBindFloat (q, "@x",     fX);
    SqlBindFloat (q, "@y",     fY);
    SqlBindFloat (q, "@z",     fZ);
    SqlBindString(q, "@cause", sCause);
    SqlBindString(q, "@epi",   sEpitaph);
    SqlBindInt   (q, "@days",  TOMB_EXPIRY_DAYS);
    SqlStep(q);

    sqlquery qId = SqlPrepareQueryCampaign("epitafium", "SELECT last_insert_rowid()");
    if(SqlStep(qId)) return SqlGetInt(qId, 0);
    return 0;
}

// Returns a json object {id, char_uuid, char_name, area_tag, pos_x, pos_y, pos_z,
//                        cause, epitaph, tribute_cnt, died_at, expires_at}
// or JSON_NULL if not found.
json TombGetMemorial(int nId)
{
    sqlquery q = SqlPrepareQueryCampaign("epitafium",
        "SELECT id, char_uuid, char_name, area_tag, pos_x, pos_y, pos_z, "
        "       cause, epitaph, tribute_cnt, died_at, expires_at "
        "FROM tomb_memorials WHERE id = @id");
    SqlBindInt(q, "@id", nId);
    if(!SqlStep(q)) return JsonNull();

    json j = JsonObject();
    j = JsonObjectSet(j, "id",          JsonInt   (SqlGetInt   (q, 0)));
    j = JsonObjectSet(j, "char_uuid",   JsonString(SqlGetString(q, 1)));
    j = JsonObjectSet(j, "char_name",   JsonString(SqlGetString(q, 2)));
    j = JsonObjectSet(j, "area_tag",    JsonString(SqlGetString(q, 3)));
    j = JsonObjectSet(j, "pos_x",       JsonFloat (SqlGetFloat (q, 4)));
    j = JsonObjectSet(j, "pos_y",       JsonFloat (SqlGetFloat (q, 5)));
    j = JsonObjectSet(j, "pos_z",       JsonFloat (SqlGetFloat (q, 6)));
    j = JsonObjectSet(j, "cause",       JsonString(SqlGetString(q, 7)));
    j = JsonObjectSet(j, "epitaph",     JsonString(SqlGetString(q, 8)));
    j = JsonObjectSet(j, "tribute_cnt", JsonInt   (SqlGetInt   (q, 9)));
    j = JsonObjectSet(j, "died_at",     JsonInt   (SqlGetInt   (q, 10)));
    j = JsonObjectSet(j, "expires_at",  JsonInt   (SqlGetInt   (q, 11)));
    return j;
}

// Returns JsonArray of all active (not expired) memorials.
json TombGetAllActive()
{
    json jRows = JsonArray();
    sqlquery q = SqlPrepareQueryCampaign("epitafium",
        "SELECT id, char_uuid, char_name, area_tag, pos_x, pos_y, pos_z, "
        "       cause, epitaph, tribute_cnt, died_at, expires_at "
        "FROM tomb_memorials "
        "WHERE expires_at > strftime('%s','now') "
        "ORDER BY died_at DESC");
    while(SqlStep(q))
    {
        json j = JsonObject();
        j = JsonObjectSet(j, "id",          JsonInt   (SqlGetInt   (q, 0)));
        j = JsonObjectSet(j, "char_uuid",   JsonString(SqlGetString(q, 1)));
        j = JsonObjectSet(j, "char_name",   JsonString(SqlGetString(q, 2)));
        j = JsonObjectSet(j, "area_tag",    JsonString(SqlGetString(q, 3)));
        j = JsonObjectSet(j, "pos_x",       JsonFloat (SqlGetFloat (q, 4)));
        j = JsonObjectSet(j, "pos_y",       JsonFloat (SqlGetFloat (q, 5)));
        j = JsonObjectSet(j, "pos_z",       JsonFloat (SqlGetFloat (q, 6)));
        j = JsonObjectSet(j, "cause",       JsonString(SqlGetString(q, 7)));
        j = JsonObjectSet(j, "epitaph",     JsonString(SqlGetString(q, 8)));
        j = JsonObjectSet(j, "tribute_cnt", JsonInt   (SqlGetInt   (q, 9)));
        j = JsonObjectSet(j, "died_at",     JsonInt   (SqlGetInt   (q, 10)));
        j = JsonObjectSet(j, "expires_at",  JsonInt   (SqlGetInt   (q, 11)));
        jRows = JsonArrayInsert(jRows, j);
    }
    return jRows;
}

void TombAddTribute(int nId, int nAmount)
{
    sqlquery q = SqlPrepareQueryCampaign("epitafium",
        "UPDATE tomb_memorials SET tribute_cnt = tribute_cnt + @n WHERE id = @id");
    SqlBindInt(q, "@n",  nAmount);
    SqlBindInt(q, "@id", nId);
    SqlStep(q);
}

// Removes memorials whose expires_at has passed.
void TombDeleteExpired()
{
    sqlquery q = SqlPrepareQueryCampaign("epitafium",
        "DELETE FROM tomb_memorials WHERE expires_at <= strftime('%s','now')");
    SqlStep(q);
}

// Formats a unix timestamp as "DD.MM.RRRR HH:MM" via SQLite.
string TombFormatDate(int nUnix)
{
    sqlquery q = SqlPrepareQueryCampaign("epitafium",
        "SELECT strftime('%d.%m.%Y %H:%M', @ts, 'unixepoch')");
    SqlBindInt(q, "@ts", nUnix);
    if(SqlStep(q)) return SqlGetString(q, 0);
    return "??";
}
