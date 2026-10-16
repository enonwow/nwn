const int INS_EXPIRY_HOURS    = 72;
const int INS_BLOOD_MULT      = 3;
const int INS_BLESS_PERMANENT = 10;

void InsCreateTables()
{
    sqlquery q = SqlPrepareQueryCampaign("stone_inscriptions",
        "CREATE TABLE IF NOT EXISTS inscriptions ("
        "  id          INTEGER PRIMARY KEY AUTOINCREMENT,"
        "  tablet_tag  TEXT    NOT NULL DEFAULT '',"
        "  author_uuid TEXT    NOT NULL DEFAULT '',"
        "  author_name TEXT    NOT NULL DEFAULT '',"
        "  body        TEXT    NOT NULL DEFAULT '',"
        "  type        INTEGER NOT NULL DEFAULT 0,"
        "  is_blood    INTEGER NOT NULL DEFAULT 0,"
        "  blessings   INTEGER NOT NULL DEFAULT 0,"
        "  created_at  INTEGER NOT NULL DEFAULT 0,"
        "  expires_at  INTEGER NOT NULL DEFAULT 0"
        ")");
    SqlStep(q);

    q = SqlPrepareQueryCampaign("stone_inscriptions",
        "CREATE TABLE IF NOT EXISTS ins_votes ("
        "  inscription_id INTEGER NOT NULL,"
        "  voter_uuid     TEXT    NOT NULL,"
        "  PRIMARY KEY (inscription_id, voter_uuid)"
        ")");
    SqlStep(q);

    q = SqlPrepareQueryCampaign("stone_inscriptions",
        "CREATE TABLE IF NOT EXISTS ins_reads ("
        "  inscription_id INTEGER NOT NULL,"
        "  reader_uuid    TEXT    NOT NULL,"
        "  PRIMARY KEY (inscription_id, reader_uuid)"
        ")");
    SqlStep(q);

    q = SqlPrepareQueryCampaign("stone_inscriptions",
        "CREATE INDEX IF NOT EXISTS idx_ins_tablet"
        " ON inscriptions (tablet_tag, expires_at)");
    SqlStep(q);
}

void InsExpireOld()
{
    sqlquery q = SqlPrepareQueryCampaign("stone_inscriptions",
        "DELETE FROM inscriptions"
        " WHERE expires_at > 0 AND expires_at < strftime('%s','now')");
    SqlStep(q);

    q = SqlPrepareQueryCampaign("stone_inscriptions",
        "DELETE FROM ins_votes"
        " WHERE inscription_id NOT IN (SELECT id FROM inscriptions)");
    SqlStep(q);

    q = SqlPrepareQueryCampaign("stone_inscriptions",
        "DELETE FROM ins_reads"
        " WHERE inscription_id NOT IN (SELECT id FROM inscriptions)");
    SqlStep(q);
}

int InsAdd(string sTabletTag, string sAuthorUuid, string sAuthorName,
           string sBody, int nType, int bBlood)
{
    int nHours = bBlood ? INS_EXPIRY_HOURS * INS_BLOOD_MULT : INS_EXPIRY_HOURS;

    sqlquery q = SqlPrepareQueryCampaign("stone_inscriptions",
        "INSERT INTO inscriptions"
        " (tablet_tag, author_uuid, author_name, body, type, is_blood,"
        "  blessings, created_at, expires_at)"
        " VALUES (@tag, @auuid, @aname, @body, @type, @blood, 0,"
        " strftime('%s','now'), strftime('%s','now') + @hours * 3600)");
    SqlBindString(q, "@tag",   sTabletTag);
    SqlBindString(q, "@auuid", sAuthorUuid);
    SqlBindString(q, "@aname", sAuthorName);
    SqlBindString(q, "@body",  sBody);
    SqlBindInt   (q, "@type",  nType);
    SqlBindInt   (q, "@blood", bBlood);
    SqlBindInt   (q, "@hours", nHours);
    SqlStep(q);

    sqlquery qId = SqlPrepareQueryCampaign("stone_inscriptions",
        "SELECT last_insert_rowid()");
    if(SqlStep(qId)) return SqlGetInt(qId, 0);
    return 0;
}

int InsGetCount(string sTabletTag)
{
    sqlquery q = SqlPrepareQueryCampaign("stone_inscriptions",
        "SELECT COUNT(*) FROM inscriptions"
        " WHERE tablet_tag = @tag"
        " AND (expires_at = 0 OR expires_at > strftime('%s','now'))");
    SqlBindString(q, "@tag", sTabletTag);
    if(SqlStep(q)) return SqlGetInt(q, 0);
    return 0;
}

// Returns JsonArray of rows sorted by blessings DESC then newest first
json InsGetPage(string sTabletTag, int nOffset, int nLimit)
{
    json jRows = JsonArray();
    sqlquery q = SqlPrepareQueryCampaign("stone_inscriptions",
        "SELECT id, author_uuid, author_name, body, type, is_blood, blessings, created_at"
        " FROM inscriptions"
        " WHERE tablet_tag = @tag"
        " AND (expires_at = 0 OR expires_at > strftime('%s','now'))"
        " ORDER BY blessings DESC, created_at DESC"
        " LIMIT @lim OFFSET @off");
    SqlBindString(q, "@tag", sTabletTag);
    SqlBindInt   (q, "@lim", nLimit);
    SqlBindInt   (q, "@off", nOffset);
    while(SqlStep(q))
    {
        json jRow = JsonObject();
        jRow = JsonObjectSet(jRow, "id",          JsonInt   (SqlGetInt   (q, 0)));
        jRow = JsonObjectSet(jRow, "author_uuid", JsonString(SqlGetString(q, 1)));
        jRow = JsonObjectSet(jRow, "author_name", JsonString(SqlGetString(q, 2)));
        jRow = JsonObjectSet(jRow, "body",        JsonString(SqlGetString(q, 3)));
        jRow = JsonObjectSet(jRow, "type",        JsonInt   (SqlGetInt   (q, 4)));
        jRow = JsonObjectSet(jRow, "is_blood",    JsonInt   (SqlGetInt   (q, 5)));
        jRow = JsonObjectSet(jRow, "blessings",   JsonInt   (SqlGetInt   (q, 6)));
        jRow = JsonObjectSet(jRow, "created_at",  JsonInt   (SqlGetInt   (q, 7)));
        jRows = JsonArrayInsert(jRows, jRow);
    }
    return jRows;
}

json InsGetById(int nId)
{
    sqlquery q = SqlPrepareQueryCampaign("stone_inscriptions",
        "SELECT id, author_uuid, author_name, body, type, is_blood, blessings, created_at"
        " FROM inscriptions WHERE id = @id");
    SqlBindInt(q, "@id", nId);
    if(!SqlStep(q)) return JsonNull();
    json jRow = JsonObject();
    jRow = JsonObjectSet(jRow, "id",          JsonInt   (SqlGetInt   (q, 0)));
    jRow = JsonObjectSet(jRow, "author_uuid", JsonString(SqlGetString(q, 1)));
    jRow = JsonObjectSet(jRow, "author_name", JsonString(SqlGetString(q, 2)));
    jRow = JsonObjectSet(jRow, "body",        JsonString(SqlGetString(q, 3)));
    jRow = JsonObjectSet(jRow, "type",        JsonInt   (SqlGetInt   (q, 4)));
    jRow = JsonObjectSet(jRow, "is_blood",    JsonInt   (SqlGetInt   (q, 5)));
    jRow = JsonObjectSet(jRow, "blessings",   JsonInt   (SqlGetInt   (q, 6)));
    jRow = JsonObjectSet(jRow, "created_at",  JsonInt   (SqlGetInt   (q, 7)));
    return jRow;
}

int InsHasVoted(int nId, string sVoterUuid)
{
    sqlquery q = SqlPrepareQueryCampaign("stone_inscriptions",
        "SELECT 1 FROM ins_votes"
        " WHERE inscription_id = @id AND voter_uuid = @uuid");
    SqlBindInt   (q, "@id",   nId);
    SqlBindString(q, "@uuid", sVoterUuid);
    return SqlStep(q);
}

void InsBless(int nId, string sVoterUuid)
{
    sqlquery q = SqlPrepareQueryCampaign("stone_inscriptions",
        "INSERT OR IGNORE INTO ins_votes (inscription_id, voter_uuid)"
        " VALUES (@id, @uuid)");
    SqlBindInt   (q, "@id",   nId);
    SqlBindString(q, "@uuid", sVoterUuid);
    SqlStep(q);

    // Each blessing extends life by 1h; at threshold make permanent (expires_at=0)
    q = SqlPrepareQueryCampaign("stone_inscriptions",
        "UPDATE inscriptions"
        " SET blessings = blessings + 1,"
        "     expires_at = CASE WHEN blessings + 1 >= @perm THEN 0"
        "                       ELSE expires_at + 3600 END"
        " WHERE id = @id");
    SqlBindInt(q, "@perm", INS_BLESS_PERMANENT);
    SqlBindInt(q, "@id",   nId);
    SqlStep(q);
}

int InsHasReadBonus(int nId, string sUuid)
{
    sqlquery q = SqlPrepareQueryCampaign("stone_inscriptions",
        "SELECT 1 FROM ins_reads"
        " WHERE inscription_id = @id AND reader_uuid = @uuid");
    SqlBindInt   (q, "@id",   nId);
    SqlBindString(q, "@uuid", sUuid);
    return SqlStep(q);
}

void InsMarkReadBonus(int nId, string sUuid)
{
    sqlquery q = SqlPrepareQueryCampaign("stone_inscriptions",
        "INSERT OR IGNORE INTO ins_reads (inscription_id, reader_uuid)"
        " VALUES (@id, @uuid)");
    SqlBindInt   (q, "@id",   nId);
    SqlBindString(q, "@uuid", sUuid);
    SqlStep(q);
}

// Returns age as "Xh" / "Xd" / "dawno" using SQLite arithmetic
string InsFormatAge(int nCreatedAt)
{
    sqlquery q = SqlPrepareQueryCampaign("stone_inscriptions",
        "SELECT CAST((strftime('%s','now') - @ts) / 3600 AS INTEGER)");
    SqlBindInt(q, "@ts", nCreatedAt);
    if(!SqlStep(q)) return "?";
    int nHours = SqlGetInt(q, 0);
    if(nHours < 1)  return "<1h";
    if(nHours < 24) return IntToString(nHours) + "h";
    int nDays = nHours / 24;
    if(nDays < 30)  return IntToString(nDays) + "d";
    return "dawno";
}
