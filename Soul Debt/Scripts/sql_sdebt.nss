void SDebtCreateTables()
{
    sqlquery q = SqlPrepareQueryCampaign("soul_debt",
        "CREATE TABLE IF NOT EXISTS sd_debts ("
        "  id             INTEGER PRIMARY KEY AUTOINCREMENT,"
        "  creditor_uuid  TEXT    NOT NULL,"
        "  creditor_name  TEXT    DEFAULT '',"
        "  debtor_uuid    TEXT    NOT NULL,"
        "  debtor_name    TEXT    DEFAULT '',"
        "  description    TEXT    DEFAULT '',"
        "  sealed_at      INTEGER DEFAULT 0,"
        "  status         TEXT    DEFAULT 'pending',"
        "  invoked_at     INTEGER DEFAULT 0"
        ")");
    SqlStep(q);

    q = SqlPrepareQueryCampaign("soul_debt",
        "CREATE TABLE IF NOT EXISTS sd_players ("
        "  uuid        TEXT PRIMARY KEY,"
        "  char_name   TEXT    DEFAULT '',"
        "  last_online INTEGER DEFAULT 0"
        ")");
    SqlStep(q);
}

void SDebtRegisterPlayer(object oPC)
{
    sqlquery q = SqlPrepareQueryCampaign("soul_debt",
        "INSERT OR REPLACE INTO sd_players (uuid, char_name, last_online) "
        "VALUES (@uuid, @name, strftime('%s','now'))");
    SqlBindString(q, "@uuid", GetObjectUUID(oPC));
    SqlBindString(q, "@name", GetName(oPC));
    SqlStep(q);
}

int SDebtCreate(string sCredUuid, string sCredName, string sDebtUuid, string sDebtName, string sDesc)
{
    sqlquery q = SqlPrepareQueryCampaign("soul_debt",
        "INSERT INTO sd_debts (creditor_uuid, creditor_name, debtor_uuid, debtor_name, description, sealed_at, status) "
        "VALUES (@cuuid, @cname, @duuid, @dname, @desc, strftime('%s','now'), 'pending')");
    SqlBindString(q, "@cuuid", sCredUuid);
    SqlBindString(q, "@cname", sCredName);
    SqlBindString(q, "@duuid", sDebtUuid);
    SqlBindString(q, "@dname", sDebtName);
    SqlBindString(q, "@desc",  sDesc);
    SqlStep(q);
    sqlquery qId = SqlPrepareQueryCampaign("soul_debt", "SELECT last_insert_rowid()");
    if(SqlStep(qId)) return SqlGetInt(qId, 0);
    return 0;
}

void SDebtSetStatus(int nId, string sStatus)
{
    sqlquery q = SqlPrepareQueryCampaign("soul_debt",
        "UPDATE sd_debts SET status = @status WHERE id = @id");
    SqlBindString(q, "@status", sStatus);
    SqlBindInt   (q, "@id",     nId);
    SqlStep(q);
}

void SDebtAccept(int nId)
{
    sqlquery q = SqlPrepareQueryCampaign("soul_debt",
        "UPDATE sd_debts SET status = 'active', sealed_at = strftime('%s','now') WHERE id = @id");
    SqlBindInt(q, "@id", nId);
    SqlStep(q);
}

void SDebtInvoke(int nId)
{
    sqlquery q = SqlPrepareQueryCampaign("soul_debt",
        "UPDATE sd_debts SET status = 'invoked', invoked_at = strftime('%s','now') WHERE id = @id");
    SqlBindInt(q, "@id", nId);
    SqlStep(q);
}

json SDebtRowFromQuery(sqlquery q)
{
    json jRow = JsonObject();
    jRow = JsonObjectSet(jRow, "id",            JsonInt   (SqlGetInt   (q, 0)));
    jRow = JsonObjectSet(jRow, "creditor_uuid", JsonString(SqlGetString(q, 1)));
    jRow = JsonObjectSet(jRow, "creditor_name", JsonString(SqlGetString(q, 2)));
    jRow = JsonObjectSet(jRow, "debtor_uuid",   JsonString(SqlGetString(q, 3)));
    jRow = JsonObjectSet(jRow, "debtor_name",   JsonString(SqlGetString(q, 4)));
    jRow = JsonObjectSet(jRow, "description",   JsonString(SqlGetString(q, 5)));
    jRow = JsonObjectSet(jRow, "sealed_at",     JsonInt   (SqlGetInt   (q, 6)));
    jRow = JsonObjectSet(jRow, "status",        JsonString(SqlGetString(q, 7)));
    jRow = JsonObjectSet(jRow, "invoked_at",    JsonInt   (SqlGetInt   (q, 8)));
    return jRow;
}

const string SD_SELECT_COLS =
    "id, creditor_uuid, creditor_name, debtor_uuid, debtor_name, description, sealed_at, status, invoked_at";

json SDebtGetAsCreditor(string sCredUuid)
{
    json jRows = JsonArray();
    sqlquery q = SqlPrepareQueryCampaign("soul_debt",
        "SELECT " + SD_SELECT_COLS + " FROM sd_debts "
        "WHERE creditor_uuid = @uuid AND status NOT IN ('repaid','renounced','forgiven') "
        "ORDER BY sealed_at DESC");
    SqlBindString(q, "@uuid", sCredUuid);
    while(SqlStep(q))
        jRows = JsonArrayInsert(jRows, SDebtRowFromQuery(q));
    return jRows;
}

json SDebtGetAsDebtor(string sDebtUuid)
{
    json jRows = JsonArray();
    sqlquery q = SqlPrepareQueryCampaign("soul_debt",
        "SELECT " + SD_SELECT_COLS + " FROM sd_debts "
        "WHERE debtor_uuid = @uuid AND status NOT IN ('repaid','renounced','forgiven') "
        "ORDER BY sealed_at DESC");
    SqlBindString(q, "@uuid", sDebtUuid);
    while(SqlStep(q))
        jRows = JsonArrayInsert(jRows, SDebtRowFromQuery(q));
    return jRows;
}

json SDebtGetById(int nId)
{
    sqlquery q = SqlPrepareQueryCampaign("soul_debt",
        "SELECT " + SD_SELECT_COLS + " FROM sd_debts WHERE id = @id");
    SqlBindInt(q, "@id", nId);
    if(!SqlStep(q)) return JsonNull();
    return SDebtRowFromQuery(q);
}

json SDebtGetPendingForDebtor(string sDebtUuid)
{
    json jRows = JsonArray();
    sqlquery q = SqlPrepareQueryCampaign("soul_debt",
        "SELECT id, creditor_name, description, sealed_at FROM sd_debts "
        "WHERE debtor_uuid = @uuid AND status = 'pending'");
    SqlBindString(q, "@uuid", sDebtUuid);
    while(SqlStep(q))
    {
        json jRow = JsonObject();
        jRow = JsonObjectSet(jRow, "id",            JsonInt   (SqlGetInt   (q, 0)));
        jRow = JsonObjectSet(jRow, "creditor_name", JsonString(SqlGetString(q, 1)));
        jRow = JsonObjectSet(jRow, "description",   JsonString(SqlGetString(q, 2)));
        jRow = JsonObjectSet(jRow, "sealed_at",     JsonInt   (SqlGetInt   (q, 3)));
        jRows = JsonArrayInsert(jRows, jRow);
    }
    return jRows;
}

int SDebtGetInvokedCount(string sDebtUuid)
{
    sqlquery q = SqlPrepareQueryCampaign("soul_debt",
        "SELECT COUNT(*) FROM sd_debts WHERE debtor_uuid = @uuid AND status = 'invoked'");
    SqlBindString(q, "@uuid", sDebtUuid);
    if(SqlStep(q)) return SqlGetInt(q, 0);
    return 0;
}

json SDebtGetOnlinePlayers(object oExclude)
{
    json jList = JsonArray();
    object oPC = GetFirstPC();
    while(GetIsObjectValid(oPC))
    {
        if(oPC != oExclude)
        {
            json jEntry = JsonObject();
            jEntry = JsonObjectSet(jEntry, "uuid", JsonString(GetObjectUUID(oPC)));
            jEntry = JsonObjectSet(jEntry, "name", JsonString(GetName(oPC)));
            jList  = JsonArrayInsert(jList, jEntry);
        }
        oPC = GetNextPC();
    }
    return jList;
}

string SDebtFormatDate(int nUnix)
{
    if(nUnix <= 0) return "—";
    sqlquery q = SqlPrepareQueryCampaign("soul_debt",
        "SELECT strftime('%d.%m', @ts, 'unixepoch')");
    SqlBindInt(q, "@ts", nUnix);
    if(SqlStep(q)) return SqlGetString(q, 0);
    return "—";
}
