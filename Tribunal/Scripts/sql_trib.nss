void TribCreateTables()
{
    sqlquery q = SqlPrepareQueryCampaign("tribunal",
        "CREATE TABLE IF NOT EXISTS trib_cases ("
        "id INTEGER PRIMARY KEY AUTOINCREMENT, "
        "defendant_uuid TEXT NOT NULL, "
        "defendant_name TEXT NOT NULL, "
        "accuser_uuid TEXT NOT NULL, "
        "accuser_name TEXT NOT NULL, "
        "charge TEXT DEFAULT '', "
        "evidence TEXT DEFAULT '', "
        "defense TEXT DEFAULT '', "
        "verdict INTEGER DEFAULT 0, "
        "sentence TEXT DEFAULT '', "
        "created_at INTEGER DEFAULT 0, "
        "resolved_at INTEGER DEFAULT 0)");
    SqlStep(q);

    q = SqlPrepareQueryCampaign("tribunal",
        "CREATE TABLE IF NOT EXISTS trib_players ("
        "uuid TEXT PRIMARY KEY, "
        "char_name TEXT DEFAULT '', "
        "last_online INTEGER DEFAULT 0)");
    SqlStep(q);
}

void TribRegisterPlayer(object oPC)
{
    sqlquery q = SqlPrepareQueryCampaign("tribunal",
        "INSERT OR REPLACE INTO trib_players (uuid, char_name, last_online) "
        "VALUES (@uuid, @name, strftime('%s','now'))");
    SqlBindString(q, "@uuid", GetObjectUUID(oPC));
    SqlBindString(q, "@name", GetName(oPC));
    SqlStep(q);
}

int TribCreateCase(string sDefUUID, string sDefName,
                   string sAccUUID, string sAccName,
                   string sCharge,  string sEvidence)
{
    sqlquery q = SqlPrepareQueryCampaign("tribunal",
        "INSERT INTO trib_cases "
        "(defendant_uuid, defendant_name, accuser_uuid, accuser_name, charge, evidence, created_at) "
        "VALUES (@duuid, @dname, @auuid, @aname, @charge, @evid, strftime('%s','now'))");
    SqlBindString(q, "@duuid",  sDefUUID);
    SqlBindString(q, "@dname",  sDefName);
    SqlBindString(q, "@auuid",  sAccUUID);
    SqlBindString(q, "@aname",  sAccName);
    SqlBindString(q, "@charge", sCharge);
    SqlBindString(q, "@evid",   sEvidence);
    SqlStep(q);
    sqlquery qId = SqlPrepareQueryCampaign("tribunal", "SELECT last_insert_rowid()");
    if(SqlStep(qId)) return SqlGetInt(qId, 0);
    return 0;
}

json TribGetAllCases()
{
    json jRows = JsonArray();
    sqlquery q = SqlPrepareQueryCampaign("tribunal",
        "SELECT id, defendant_name, accuser_name, charge, verdict "
        "FROM trib_cases ORDER BY verdict ASC, created_at DESC LIMIT 50");
    while(SqlStep(q))
    {
        json jRow = JsonObject();
        jRow = JsonObjectSet(jRow, "id",             JsonInt   (SqlGetInt   (q, 0)));
        jRow = JsonObjectSet(jRow, "defendant_name", JsonString(SqlGetString(q, 1)));
        jRow = JsonObjectSet(jRow, "accuser_name",   JsonString(SqlGetString(q, 2)));
        jRow = JsonObjectSet(jRow, "charge",         JsonString(SqlGetString(q, 3)));
        jRow = JsonObjectSet(jRow, "verdict",        JsonInt   (SqlGetInt   (q, 4)));
        jRows = JsonArrayInsert(jRows, jRow);
    }
    return jRows;
}

json TribGetCase(int nId)
{
    sqlquery q = SqlPrepareQueryCampaign("tribunal",
        "SELECT id, defendant_uuid, defendant_name, accuser_uuid, accuser_name, "
        "charge, evidence, defense, verdict, sentence, created_at, resolved_at "
        "FROM trib_cases WHERE id = @id");
    SqlBindInt(q, "@id", nId);
    if(!SqlStep(q)) return JsonNull();
    json jCase = JsonObject();
    jCase = JsonObjectSet(jCase, "id",             JsonInt   (SqlGetInt   (q, 0)));
    jCase = JsonObjectSet(jCase, "defendant_uuid", JsonString(SqlGetString(q, 1)));
    jCase = JsonObjectSet(jCase, "defendant_name", JsonString(SqlGetString(q, 2)));
    jCase = JsonObjectSet(jCase, "accuser_uuid",   JsonString(SqlGetString(q, 3)));
    jCase = JsonObjectSet(jCase, "accuser_name",   JsonString(SqlGetString(q, 4)));
    jCase = JsonObjectSet(jCase, "charge",         JsonString(SqlGetString(q, 5)));
    jCase = JsonObjectSet(jCase, "evidence",       JsonString(SqlGetString(q, 6)));
    jCase = JsonObjectSet(jCase, "defense",        JsonString(SqlGetString(q, 7)));
    jCase = JsonObjectSet(jCase, "verdict",        JsonInt   (SqlGetInt   (q, 8)));
    jCase = JsonObjectSet(jCase, "sentence",       JsonString(SqlGetString(q, 9)));
    jCase = JsonObjectSet(jCase, "created_at",     JsonInt   (SqlGetInt   (q, 10)));
    jCase = JsonObjectSet(jCase, "resolved_at",    JsonInt   (SqlGetInt   (q, 11)));
    return jCase;
}

void TribUpdateEvidence(int nId, string sEvidence)
{
    sqlquery q = SqlPrepareQueryCampaign("tribunal",
        "UPDATE trib_cases SET evidence = @evid WHERE id = @id");
    SqlBindString(q, "@evid", sEvidence);
    SqlBindInt   (q, "@id",   nId);
    SqlStep(q);
}

void TribUpdateDefense(int nId, string sDefense)
{
    sqlquery q = SqlPrepareQueryCampaign("tribunal",
        "UPDATE trib_cases SET defense = @def WHERE id = @id");
    SqlBindString(q, "@def", sDefense);
    SqlBindInt   (q, "@id",  nId);
    SqlStep(q);
}

void TribSetVerdict(int nId, int nVerdict, string sSentence)
{
    sqlquery q = SqlPrepareQueryCampaign("tribunal",
        "UPDATE trib_cases SET verdict = @v, sentence = @s, "
        "resolved_at = strftime('%s','now') WHERE id = @id");
    SqlBindInt   (q, "@v",  nVerdict);
    SqlBindString(q, "@s",  sSentence);
    SqlBindInt   (q, "@id", nId);
    SqlStep(q);
}

json TribSearchPlayers(string sQuery, object oSelf)
{
    json jResults = JsonArray();
    sqlquery q = SqlPrepareQueryCampaign("tribunal",
        "SELECT uuid, char_name FROM trib_players "
        "WHERE LOWER(char_name) LIKE LOWER('%' || @q || '%') "
        "AND uuid != @self LIMIT 8");
    SqlBindString(q, "@q",    sQuery);
    SqlBindString(q, "@self", GetObjectUUID(oSelf));
    while(SqlStep(q))
    {
        json jEntry = JsonObject();
        jEntry = JsonObjectSet(jEntry, "uuid",      JsonString(SqlGetString(q, 0)));
        jEntry = JsonObjectSet(jEntry, "char_name", JsonString(SqlGetString(q, 1)));
        jResults = JsonArrayInsert(jResults, jEntry);
    }
    return jResults;
}

string TribFormatDateSQL(int nUnix)
{
    sqlquery q = SqlPrepareQueryCampaign("tribunal",
        "SELECT strftime('%d.%m.%Y', @ts, 'unixepoch')");
    SqlBindInt(q, "@ts", nUnix);
    if(SqlStep(q)) return SqlGetString(q, 0);
    return "";
}

int TribGetOpenCaseCountFor(string sDefUUID)
{
    sqlquery q = SqlPrepareQueryCampaign("tribunal",
        "SELECT COUNT(*) FROM trib_cases WHERE defendant_uuid = @uuid AND verdict = 0");
    SqlBindString(q, "@uuid", sDefUUID);
    if(SqlStep(q)) return SqlGetInt(q, 0);
    return 0;
}
