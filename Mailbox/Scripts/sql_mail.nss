const int MAIL_EXPIRY_DAYS = 30; // 0 = disabled

void MailCreateTables()
{
    sqlquery q = SqlPrepareQueryCampaign("mail",
        "CREATE TABLE IF NOT EXISTS mail_messages (id INTEGER PRIMARY KEY AUTOINCREMENT, sender_name TEXT DEFAULT '', sender_uuid TEXT DEFAULT '', recipient_uuid TEXT NOT NULL, subject TEXT DEFAULT '', body TEXT DEFAULT '', items_json TEXT DEFAULT '[]', gold INTEGER DEFAULT 0, sent_at INTEGER DEFAULT 0, is_read INTEGER DEFAULT 0, is_claimed INTEGER DEFAULT 0)");
    SqlStep(q);

    q = SqlPrepareQueryCampaign("mail",
        "CREATE TABLE IF NOT EXISTS mail_players (uuid TEXT PRIMARY KEY, char_name TEXT DEFAULT '', last_online INTEGER DEFAULT 0)");
    SqlStep(q);
}

void MailRegisterPlayer(object oPC)
{
    sqlquery q = SqlPrepareQueryCampaign("mail",
        "INSERT OR REPLACE INTO mail_players (uuid, char_name, last_online) VALUES (@uuid, @name, strftime('%s','now'))");
    SqlBindString(q, "@uuid", GetObjectUUID(oPC));
    SqlBindString(q, "@name", GetName(oPC));
    SqlStep(q);
}

void MailExpireOld()
{
    if(MAIL_EXPIRY_DAYS <= 0) return;
    sqlquery q = SqlPrepareQueryCampaign("mail",
        "DELETE FROM mail_messages WHERE sent_at < strftime('%s','now') - @days * 86400");
    SqlBindInt(q, "@days", MAIL_EXPIRY_DAYS);
    SqlStep(q);
}

int MailGetUnreadCount(object oPC)
{
    sqlquery q = SqlPrepareQueryCampaign("mail",
        "SELECT COUNT(*) FROM mail_messages WHERE recipient_uuid = @uuid AND is_read = 0");
    SqlBindString(q, "@uuid", GetObjectUUID(oPC));
    if(SqlStep(q)) return SqlGetInt(q, 0);
    return 0;
}

int MailGetInboxCount(object oPC)
{
    sqlquery q = SqlPrepareQueryCampaign("mail",
        "SELECT COUNT(*) FROM mail_messages WHERE recipient_uuid = @uuid");
    SqlBindString(q, "@uuid", GetObjectUUID(oPC));
    if(SqlStep(q)) return SqlGetInt(q, 0);
    return 0;
}

int MailGetRecipientCount(string sUuid)
{
    sqlquery q = SqlPrepareQueryCampaign("mail",
        "SELECT COUNT(*) FROM mail_messages WHERE recipient_uuid = @uuid");
    SqlBindString(q, "@uuid", sUuid);
    if(SqlStep(q)) return SqlGetInt(q, 0);
    return 0;
}

// Returns JsonArray of search results: [{uuid, char_name}, ...]
json MailSearchPlayers(string sQuery, object oPC)
{
    json jResults = JsonArray();
    sqlquery q = SqlPrepareQueryCampaign("mail",
        "SELECT uuid, char_name FROM mail_players WHERE LOWER(char_name) LIKE LOWER('%' || @query || '%') AND uuid != @self LIMIT 5");
    SqlBindString(q, "@query", sQuery);
    SqlBindString(q, "@self",  GetObjectUUID(oPC));
    while(SqlStep(q))
    {
        json jEntry = JsonObject();
        jEntry = JsonObjectSet(jEntry, "uuid",      JsonString(SqlGetString(q, 0)));
        jEntry = JsonObjectSet(jEntry, "char_name", JsonString(SqlGetString(q, 1)));
        jResults = JsonArrayInsert(jResults, jEntry);
    }
    return jResults;
}

// Returns JsonArray of mail rows for inbox: [{id, sender_name, subject, sent_at, gold, items_json, is_read, is_claimed}, ...]
json MailGetInbox(object oPC)
{
    json jRows = JsonArray();
    sqlquery q = SqlPrepareQueryCampaign("mail",
        "SELECT id, sender_name, subject, sent_at, gold, items_json, is_read, is_claimed FROM mail_messages WHERE recipient_uuid = @uuid ORDER BY sent_at DESC");
    SqlBindString(q, "@uuid", GetObjectUUID(oPC));
    while(SqlStep(q))
    {
        json jRow = JsonObject();
        jRow = JsonObjectSet(jRow, "id",          JsonInt   (SqlGetInt   (q, 0)));
        jRow = JsonObjectSet(jRow, "sender_name", JsonString(SqlGetString(q, 1)));
        jRow = JsonObjectSet(jRow, "subject",     JsonString(SqlGetString(q, 2)));
        jRow = JsonObjectSet(jRow, "sent_at",     JsonInt   (SqlGetInt   (q, 3)));
        jRow = JsonObjectSet(jRow, "gold",        JsonInt   (SqlGetInt   (q, 4)));
        jRow = JsonObjectSet(jRow, "items_json",  JsonString(SqlGetString(q, 5)));
        jRow = JsonObjectSet(jRow, "is_read",     JsonInt   (SqlGetInt   (q, 6)));
        jRow = JsonObjectSet(jRow, "is_claimed",  JsonInt   (SqlGetInt   (q, 7)));
        jRows = JsonArrayInsert(jRows, jRow);
    }
    return jRows;
}

// Returns single mail with body field
json MailGetMessage(int nId)
{
    sqlquery q = SqlPrepareQueryCampaign("mail",
        "SELECT id, sender_name, subject, body, sent_at, gold, items_json, is_read, is_claimed FROM mail_messages WHERE id = @id");
    SqlBindInt(q, "@id", nId);
    if(!SqlStep(q)) return JsonNull();
    json jMsg = JsonObject();
    jMsg = JsonObjectSet(jMsg, "id",          JsonInt   (SqlGetInt   (q, 0)));
    jMsg = JsonObjectSet(jMsg, "sender_name", JsonString(SqlGetString(q, 1)));
    jMsg = JsonObjectSet(jMsg, "subject",     JsonString(SqlGetString(q, 2)));
    jMsg = JsonObjectSet(jMsg, "body",        JsonString(SqlGetString(q, 3)));
    jMsg = JsonObjectSet(jMsg, "sent_at",     JsonInt   (SqlGetInt   (q, 4)));
    jMsg = JsonObjectSet(jMsg, "gold",        JsonInt   (SqlGetInt   (q, 5)));
    jMsg = JsonObjectSet(jMsg, "items_json",  JsonString(SqlGetString(q, 6)));
    jMsg = JsonObjectSet(jMsg, "is_read",     JsonInt   (SqlGetInt   (q, 7)));
    jMsg = JsonObjectSet(jMsg, "is_claimed",  JsonInt   (SqlGetInt   (q, 8)));
    return jMsg;
}

void MailMarkRead(int nId)
{
    sqlquery q = SqlPrepareQueryCampaign("mail",
        "UPDATE mail_messages SET is_read = 1 WHERE id = @id");
    SqlBindInt(q, "@id", nId);
    SqlStep(q);
}

void MailMarkClaimed(int nId)
{
    sqlquery q = SqlPrepareQueryCampaign("mail",
        "UPDATE mail_messages SET is_claimed = 1 WHERE id = @id");
    SqlBindInt(q, "@id", nId);
    SqlStep(q);
}

void MailDelete(int nId)
{
    sqlquery q = SqlPrepareQueryCampaign("mail",
        "DELETE FROM mail_messages WHERE id = @id");
    SqlBindInt(q, "@id", nId);
    SqlStep(q);
}

int MailSend(object oSender, string sRecipientUuid, string sSubject, string sBody, json jItemsJson, int nGold)
{
    sqlquery q = SqlPrepareQueryCampaign("mail",
        "INSERT INTO mail_messages (sender_name, sender_uuid, recipient_uuid, subject, body, items_json, gold, sent_at) VALUES (@sname, @suuid, @ruuid, @subj, @body, @items, @gold, strftime('%s','now'))");
    SqlBindString(q, "@sname",  GetName(oSender));
    SqlBindString(q, "@suuid",  GetObjectUUID(oSender));
    SqlBindString(q, "@ruuid",  sRecipientUuid);
    SqlBindString(q, "@subj",   sSubject);
    SqlBindString(q, "@body",   sBody);
    SqlBindString(q, "@items",  JsonDump(jItemsJson));
    SqlBindInt   (q, "@gold",   nGold);
    SqlStep(q);
    sqlquery qId = SqlPrepareQueryCampaign("mail", "SELECT last_insert_rowid()");
    if(SqlStep(qId)) return SqlGetInt(qId, 0);
    return 0;
}

// Returns "DD.MM" by querying sqlite for a unix timestamp
string MailFormatDateSQL(int nUnix)
{
    sqlquery q = SqlPrepareQueryCampaign("mail",
        "SELECT strftime('%d.%m', @ts, 'unixepoch')");
    SqlBindInt(q, "@ts", nUnix);
    if(SqlStep(q)) return SqlGetString(q, 0);
    return "";
}
