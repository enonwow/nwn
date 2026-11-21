// SQL schema and queries for the Bonfire system.
// Campaign DB name: "bonfire"

void BfireCreateTables()
{
    sqlquery q;

    q = SqlPrepareQueryCampaign("bonfire",
        "CREATE TABLE IF NOT EXISTS bfire_lit ("
        "  tag       TEXT PRIMARY KEY,"
        "  area_name TEXT DEFAULT '',"
        "  lit_by    TEXT DEFAULT '',"
        "  lit_at    INTEGER DEFAULT 0"
        ")");
    SqlStep(q);

    q = SqlPrepareQueryCampaign("bonfire",
        "CREATE TABLE IF NOT EXISTS bfire_messages ("
        "  id           INTEGER PRIMARY KEY AUTOINCREMENT,"
        "  bonfire_tag  TEXT NOT NULL,"
        "  author_name  TEXT DEFAULT '',"
        "  message      TEXT DEFAULT '',"
        "  posted_at    INTEGER DEFAULT 0"
        ")");
    SqlStep(q);

    // per-PC data: flask count and last rest timestamp
    q = SqlPrepareQueryCampaign("bonfire",
        "CREATE TABLE IF NOT EXISTS bfire_pc ("
        "  pc_uuid      TEXT PRIMARY KEY,"
        "  flasks       INTEGER DEFAULT 5,"
        "  last_rest_at INTEGER DEFAULT 0"
        ")");
    SqlStep(q);
}

// ----------------------------------------------------------------
// Bonfire lit state
// ----------------------------------------------------------------

int BfireIsLit(string sTag)
{
    sqlquery q = SqlPrepareQueryCampaign("bonfire",
        "SELECT 1 FROM bfire_lit WHERE tag = @tag");
    SqlBindString(q, "@tag", sTag);
    return SqlStep(q);
}

void BfireLightBonfire(string sTag, string sAreaName, string sLighterName)
{
    sqlquery q = SqlPrepareQueryCampaign("bonfire",
        "INSERT OR REPLACE INTO bfire_lit (tag, area_name, lit_by, lit_at) "
        "VALUES (@tag, @area, @name, strftime('%s','now'))");
    SqlBindString(q, "@tag",  sTag);
    SqlBindString(q, "@area", sAreaName);
    SqlBindString(q, "@name", sLighterName);
    SqlStep(q);
}

// Returns JsonArray of {tag, area_name} for all lit bonfires, ordered newest first.
json BfireGetLitList()
{
    json jList = JsonArray();
    sqlquery q = SqlPrepareQueryCampaign("bonfire",
        "SELECT tag, area_name FROM bfire_lit ORDER BY lit_at DESC");
    while(SqlStep(q))
    {
        json jEntry = JsonObject();
        jEntry = JsonObjectSet(jEntry, "tag",       JsonString(SqlGetString(q, 0)));
        jEntry = JsonObjectSet(jEntry, "area_name", JsonString(SqlGetString(q, 1)));
        jList  = JsonArrayInsert(jList, jEntry);
    }
    return jList;
}

// ----------------------------------------------------------------
// Messages / Echoes
// ----------------------------------------------------------------

void BfireAddMessage(string sBonfireTag, string sAuthorName, string sMessage)
{
    sqlquery q = SqlPrepareQueryCampaign("bonfire",
        "INSERT INTO bfire_messages (bonfire_tag, author_name, message, posted_at) "
        "VALUES (@tag, @author, @msg, strftime('%s','now'))");
    SqlBindString(q, "@tag",    sBonfireTag);
    SqlBindString(q, "@author", sAuthorName);
    SqlBindString(q, "@msg",    sMessage);
    SqlStep(q);
}

// Returns JsonArray of last BFIRE_MAX_MSGS messages: {author_name, message, posted_at}.
json BfireGetMessages(string sBonfireTag, int nLimit)
{
    json jList = JsonArray();
    sqlquery q = SqlPrepareQueryCampaign("bonfire",
        "SELECT author_name, message, posted_at "
        "FROM bfire_messages WHERE bonfire_tag = @tag "
        "ORDER BY posted_at DESC LIMIT @lim");
    SqlBindString(q, "@tag", sBonfireTag);
    SqlBindInt   (q, "@lim", nLimit);
    while(SqlStep(q))
    {
        json jEntry = JsonObject();
        jEntry = JsonObjectSet(jEntry, "author_name", JsonString(SqlGetString(q, 0)));
        jEntry = JsonObjectSet(jEntry, "message",     JsonString(SqlGetString(q, 1)));
        jEntry = JsonObjectSet(jEntry, "posted_at",   JsonInt   (SqlGetInt   (q, 2)));
        jList  = JsonArrayInsert(jList, jEntry);
    }
    return jList;
}

// ----------------------------------------------------------------
// Per-PC data
// ----------------------------------------------------------------

void BfireEnsurePC(string sUUID)
{
    sqlquery q = SqlPrepareQueryCampaign("bonfire",
        "INSERT OR IGNORE INTO bfire_pc (pc_uuid) VALUES (@uuid)");
    SqlBindString(q, "@uuid", sUUID);
    SqlStep(q);
}

int BfireGetFlasks(string sUUID)
{
    BfireEnsurePC(sUUID);
    sqlquery q = SqlPrepareQueryCampaign("bonfire",
        "SELECT flasks FROM bfire_pc WHERE pc_uuid = @uuid");
    SqlBindString(q, "@uuid", sUUID);
    if(SqlStep(q)) return SqlGetInt(q, 0);
    return 5;
}

void BfireSetFlasks(string sUUID, int nFlasks)
{
    BfireEnsurePC(sUUID);
    sqlquery q = SqlPrepareQueryCampaign("bonfire",
        "UPDATE bfire_pc SET flasks = @n WHERE pc_uuid = @uuid");
    SqlBindInt   (q, "@n",    nFlasks);
    SqlBindString(q, "@uuid", sUUID);
    SqlStep(q);
}

int BfireGetLastRest(string sUUID)
{
    BfireEnsurePC(sUUID);
    sqlquery q = SqlPrepareQueryCampaign("bonfire",
        "SELECT last_rest_at FROM bfire_pc WHERE pc_uuid = @uuid");
    SqlBindString(q, "@uuid", sUUID);
    if(SqlStep(q)) return SqlGetInt(q, 0);
    return 0;
}

void BfireSetLastRest(string sUUID)
{
    BfireEnsurePC(sUUID);
    sqlquery q = SqlPrepareQueryCampaign("bonfire",
        "UPDATE bfire_pc SET last_rest_at = strftime('%s','now') WHERE pc_uuid = @uuid");
    SqlBindString(q, "@uuid", sUUID);
    SqlStep(q);
}

// Returns "HH:MM DD.MM" for a unix timestamp via SQLite.
string BfireFormatDate(int nUnix)
{
    sqlquery q = SqlPrepareQueryCampaign("bonfire",
        "SELECT strftime('%H:%M %d.%m', @ts, 'unixepoch')");
    SqlBindInt(q, "@ts", nUnix);
    if(SqlStep(q)) return SqlGetString(q, 0);
    return "";
}

// Returns seconds since epoch via SQLite.
int BfireNow()
{
    sqlquery q = SqlPrepareQueryCampaign("bonfire",
        "SELECT strftime('%s','now')");
    if(SqlStep(q)) return SqlGetInt(q, 0);
    return 0;
}
