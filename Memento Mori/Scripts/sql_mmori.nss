// No dependencies — purely SQL helpers for Memento Mori.

void MmoriCreateTables()
{
    sqlquery q = SqlPrepareQueryCampaign("mmori",
        "CREATE TABLE IF NOT EXISTS mmori_marks ("
        "id INTEGER PRIMARY KEY AUTOINCREMENT,"
        "player_uuid TEXT NOT NULL,"
        "player_name TEXT NOT NULL,"
        "area_tag TEXT NOT NULL,"
        "area_name TEXT NOT NULL,"
        "pos_x REAL DEFAULT 0.0,"
        "pos_y REAL DEFAULT 0.0,"
        "pos_z REAL DEFAULT 0.0,"
        "last_words TEXT DEFAULT '',"
        "died_at INTEGER DEFAULT 0,"
        "mourner_count INTEGER DEFAULT 0,"
        "is_legendary INTEGER DEFAULT 0,"
        "is_active INTEGER DEFAULT 1)");
    SqlStep(q);

    q = SqlPrepareQueryCampaign("mmori",
        "CREATE TABLE IF NOT EXISTS mmori_mourners ("
        "mark_id INTEGER NOT NULL,"
        "mourner_uuid TEXT NOT NULL,"
        "mourned_at INTEGER DEFAULT 0,"
        "PRIMARY KEY(mark_id, mourner_uuid))");
    SqlStep(q);
}

int MmoriInsertMark(string sPlayerUuid, string sPlayerName,
                    string sAreaTag, string sAreaName,
                    float fX, float fY, float fZ,
                    string sWords)
{
    sqlquery q = SqlPrepareQueryCampaign("mmori",
        "INSERT INTO mmori_marks "
        "(player_uuid, player_name, area_tag, area_name, pos_x, pos_y, pos_z, last_words, died_at) "
        "VALUES (@uuid, @name, @atag, @aname, @x, @y, @z, @words, strftime('%s','now'))");
    SqlBindString(q, "@uuid",  sPlayerUuid);
    SqlBindString(q, "@name",  sPlayerName);
    SqlBindString(q, "@atag",  sAreaTag);
    SqlBindString(q, "@aname", sAreaName);
    SqlBindFloat (q, "@x",     fX);
    SqlBindFloat (q, "@y",     fY);
    SqlBindFloat (q, "@z",     fZ);
    SqlBindString(q, "@words", sWords);
    SqlStep(q);
    sqlquery qId = SqlPrepareQueryCampaign("mmori", "SELECT last_insert_rowid()");
    if(SqlStep(qId)) return SqlGetInt(qId, 0);
    return 0;
}

json MmoriGetMark(int nId)
{
    sqlquery q = SqlPrepareQueryCampaign("mmori",
        "SELECT id, player_uuid, player_name, area_tag, area_name, "
        "pos_x, pos_y, pos_z, last_words, died_at, mourner_count, is_legendary "
        "FROM mmori_marks WHERE id = @id AND is_active = 1");
    SqlBindInt(q, "@id", nId);
    if(!SqlStep(q)) return JsonNull();
    json jM = JsonObject();
    jM = JsonObjectSet(jM, "id",            JsonInt   (SqlGetInt   (q, 0)));
    jM = JsonObjectSet(jM, "player_uuid",   JsonString(SqlGetString(q, 1)));
    jM = JsonObjectSet(jM, "player_name",   JsonString(SqlGetString(q, 2)));
    jM = JsonObjectSet(jM, "area_tag",      JsonString(SqlGetString(q, 3)));
    jM = JsonObjectSet(jM, "area_name",     JsonString(SqlGetString(q, 4)));
    jM = JsonObjectSet(jM, "pos_x",         JsonFloat (SqlGetFloat (q, 5)));
    jM = JsonObjectSet(jM, "pos_y",         JsonFloat (SqlGetFloat (q, 6)));
    jM = JsonObjectSet(jM, "pos_z",         JsonFloat (SqlGetFloat (q, 7)));
    jM = JsonObjectSet(jM, "last_words",    JsonString(SqlGetString(q, 8)));
    jM = JsonObjectSet(jM, "died_at",       JsonInt   (SqlGetInt   (q, 9)));
    jM = JsonObjectSet(jM, "mourner_count", JsonInt   (SqlGetInt   (q, 10)));
    jM = JsonObjectSet(jM, "is_legendary",  JsonInt   (SqlGetInt   (q, 11)));
    return jM;
}

void MmoriDeactivateMark(int nId)
{
    sqlquery q = SqlPrepareQueryCampaign("mmori",
        "UPDATE mmori_marks SET is_active = 0 WHERE id = @id");
    SqlBindInt(q, "@id", nId);
    SqlStep(q);
}

int MmoriHasMourned(int nMarkId, string sMournerUuid)
{
    sqlquery q = SqlPrepareQueryCampaign("mmori",
        "SELECT COUNT(*) FROM mmori_mourners WHERE mark_id = @mid AND mourner_uuid = @uuid");
    SqlBindInt   (q, "@mid",  nMarkId);
    SqlBindString(q, "@uuid", sMournerUuid);
    if(SqlStep(q)) return SqlGetInt(q, 0) > 0;
    return FALSE;
}

void MmoriAddMourner(int nMarkId, string sMournerUuid, int nLegendaryThreshold)
{
    sqlquery q = SqlPrepareQueryCampaign("mmori",
        "INSERT OR IGNORE INTO mmori_mourners (mark_id, mourner_uuid, mourned_at) "
        "VALUES (@mid, @uuid, strftime('%s','now'))");
    SqlBindInt   (q, "@mid",  nMarkId);
    SqlBindString(q, "@uuid", sMournerUuid);
    SqlStep(q);

    q = SqlPrepareQueryCampaign("mmori",
        "UPDATE mmori_marks "
        "SET mourner_count = mourner_count + 1, "
        "is_legendary = CASE WHEN mourner_count + 1 >= @thresh THEN 1 ELSE is_legendary END "
        "WHERE id = @id");
    SqlBindInt(q, "@thresh", nLegendaryThreshold);
    SqlBindInt(q, "@id",     nMarkId);
    SqlStep(q);
}

// Deactivates expired non-legendary marks; sExpiryDays passed in to avoid constant dependency.
void MmoriExpireOld(int nExpiryDays)
{
    if(nExpiryDays <= 0) return;
    sqlquery q = SqlPrepareQueryCampaign("mmori",
        "UPDATE mmori_marks SET is_active = 0 "
        "WHERE is_active = 1 AND is_legendary = 0 "
        "AND died_at < strftime('%s','now') - @days * 86400");
    SqlBindInt(q, "@days", nExpiryDays);
    SqlStep(q);
}

// Returns human-readable age in Polish.
string MmoriFormatAge(int nDiedAt)
{
    sqlquery q = SqlPrepareQueryCampaign("mmori",
        "SELECT CAST((strftime('%s','now') - @ts) / 3600 AS INTEGER)");
    SqlBindInt(q, "@ts", nDiedAt);
    if(!SqlStep(q)) return "dawno temu";
    int nHours = SqlGetInt(q, 0);
    if(nHours < 1)  return "przed chwilą";
    if(nHours < 24) return IntToString(nHours) + " godz. temu";
    int nDays = nHours / 24;
    if(nDays == 1)  return "wczoraj";
    return IntToString(nDays) + " dni temu";
}

// Returns count of currently active legendary marks (server-wide display).
int MmoriGetLegendaryCount()
{
    sqlquery q = SqlPrepareQueryCampaign("mmori",
        "SELECT COUNT(*) FROM mmori_marks WHERE is_active = 1 AND is_legendary = 1");
    if(SqlStep(q)) return SqlGetInt(q, 0);
    return 0;
}
