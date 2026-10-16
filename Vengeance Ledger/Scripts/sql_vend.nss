// Persistent grudge storage.
// Status: 0=active, 1=fulfilled (wrongdoer killed), 2=forsworn (released by victim).

const int VEND_OVERDUE_DAYS     = 21;
const int VEND_FULFILL_DURATION = 3600;
const int VEND_MAX_HISTORY      = 10;
const int VEND_FORSW_XP_PENALTY = 50;

void VendCreateTables()
{
    sqlquery q;
    q = SqlPrepareQueryCampaign("vend",
        "CREATE TABLE IF NOT EXISTS vend_grudges ("
        "  id             INTEGER PRIMARY KEY AUTOINCREMENT,"
        "  victim_uuid    TEXT    NOT NULL,"
        "  wrongdoer_uuid TEXT    NOT NULL,"
        "  wrongdoer_name TEXT    DEFAULT '',"
        "  wrong_type     INTEGER DEFAULT 1,"
        "  item_tag       TEXT    DEFAULT '',"
        "  created_at     INTEGER DEFAULT 0,"
        "  fulfilled_at   INTEGER DEFAULT 0,"
        "  forsworn_at    INTEGER DEFAULT 0,"
        "  status         INTEGER DEFAULT 0)");
    SqlStep(q);

    q = SqlPrepareQueryCampaign("vend",
        "CREATE TABLE IF NOT EXISTS vend_players ("
        "  uuid      TEXT PRIMARY KEY,"
        "  char_name TEXT DEFAULT '')");
    SqlStep(q);

    q = SqlPrepareQueryCampaign("vend",
        "CREATE INDEX IF NOT EXISTS vend_idx_victim ON vend_grudges (victim_uuid, status)");
    SqlStep(q);
}

void VendRegisterPlayer(object oPC)
{
    sqlquery q = SqlPrepareQueryCampaign("vend",
        "INSERT OR REPLACE INTO vend_players (uuid, char_name) VALUES (@uuid, @name)");
    SqlBindString(q, "@uuid", GetObjectUUID(oPC));
    SqlBindString(q, "@name", GetName(oPC));
    SqlStep(q);
}

int VendHasActiveGrudge(string sVictimUuid, string sWrongdoerUuid, int nWrongType)
{
    sqlquery q = SqlPrepareQueryCampaign("vend",
        "SELECT COUNT(*) FROM vend_grudges "
        "WHERE victim_uuid=@v AND wrongdoer_uuid=@w AND wrong_type=@t AND status=0");
    SqlBindString(q, "@v", sVictimUuid);
    SqlBindString(q, "@w", sWrongdoerUuid);
    SqlBindInt   (q, "@t", nWrongType);
    if (SqlStep(q)) return SqlGetInt(q, 0);
    return 0;
}

int VendAddGrudgeDB(string sVictimUuid, string sWrongdoerUuid, string sWrongdoerName,
                    int nWrongType, string sItemTag)
{
    sqlquery q = SqlPrepareQueryCampaign("vend",
        "INSERT INTO vend_grudges "
        "(victim_uuid, wrongdoer_uuid, wrongdoer_name, wrong_type, item_tag, created_at) "
        "VALUES (@v, @w, @wn, @t, @it, strftime('%s','now'))");
    SqlBindString(q, "@v",  sVictimUuid);
    SqlBindString(q, "@w",  sWrongdoerUuid);
    SqlBindString(q, "@wn", sWrongdoerName);
    SqlBindInt   (q, "@t",  nWrongType);
    SqlBindString(q, "@it", sItemTag);
    SqlStep(q);
    sqlquery qId = SqlPrepareQueryCampaign("vend", "SELECT last_insert_rowid()");
    if (SqlStep(qId)) return SqlGetInt(qId, 0);
    return 0;
}

// Returns JsonArray: [{id, wrongdoer_name, wrong_type, created_at, is_overdue}, ...]
json VendGetActiveGrudges(object oPC)
{
    json jRows = JsonArray();
    sqlquery q = SqlPrepareQueryCampaign("vend",
        "SELECT id, wrongdoer_name, wrong_type, created_at, "
        "  (strftime('%s','now') - created_at > @overdue) AS is_overdue "
        "FROM vend_grudges WHERE victim_uuid=@uuid AND status=0 ORDER BY created_at ASC");
    SqlBindString(q, "@uuid",    GetObjectUUID(oPC));
    SqlBindInt   (q, "@overdue", VEND_OVERDUE_DAYS * 86400);
    while (SqlStep(q))
    {
        json j = JsonObject();
        j = JsonObjectSet(j, "id",             JsonInt   (SqlGetInt   (q, 0)));
        j = JsonObjectSet(j, "wrongdoer_name", JsonString(SqlGetString(q, 1)));
        j = JsonObjectSet(j, "wrong_type",     JsonInt   (SqlGetInt   (q, 2)));
        j = JsonObjectSet(j, "created_at",     JsonInt   (SqlGetInt   (q, 3)));
        j = JsonObjectSet(j, "is_overdue",     JsonInt   (SqlGetInt   (q, 4)));
        jRows = JsonArrayInsert(jRows, j);
    }
    return jRows;
}

// Returns last VEND_MAX_HISTORY resolved entries, newest first.
json VendGetHistoryGrudges(object oPC)
{
    json jRows = JsonArray();
    sqlquery q = SqlPrepareQueryCampaign("vend",
        "SELECT wrongdoer_name, wrong_type, fulfilled_at, forsworn_at, status "
        "FROM vend_grudges WHERE victim_uuid=@uuid AND status>0 "
        "ORDER BY CASE WHEN status=1 THEN fulfilled_at ELSE forsworn_at END DESC "
        "LIMIT @lim");
    SqlBindString(q, "@uuid", GetObjectUUID(oPC));
    SqlBindInt   (q, "@lim",  VEND_MAX_HISTORY);
    while (SqlStep(q))
    {
        json j = JsonObject();
        j = JsonObjectSet(j, "wrongdoer_name", JsonString(SqlGetString(q, 0)));
        j = JsonObjectSet(j, "wrong_type",     JsonInt   (SqlGetInt   (q, 1)));
        j = JsonObjectSet(j, "fulfilled_at",   JsonInt   (SqlGetInt   (q, 2)));
        j = JsonObjectSet(j, "forsworn_at",    JsonInt   (SqlGetInt   (q, 3)));
        j = JsonObjectSet(j, "status",         JsonInt   (SqlGetInt   (q, 4)));
        jRows = JsonArrayInsert(jRows, j);
    }
    return jRows;
}

int VendGetActiveCount(object oPC)
{
    sqlquery q = SqlPrepareQueryCampaign("vend",
        "SELECT COUNT(*) FROM vend_grudges WHERE victim_uuid=@uuid AND status=0");
    SqlBindString(q, "@uuid", GetObjectUUID(oPC));
    if (SqlStep(q)) return SqlGetInt(q, 0);
    return 0;
}

int VendGetOverdueCount(object oPC)
{
    sqlquery q = SqlPrepareQueryCampaign("vend",
        "SELECT COUNT(*) FROM vend_grudges "
        "WHERE victim_uuid=@uuid AND status=0 "
        "AND (strftime('%s','now') - created_at) > @overdue");
    SqlBindString(q, "@uuid",    GetObjectUUID(oPC));
    SqlBindInt   (q, "@overdue", VEND_OVERDUE_DAYS * 86400);
    if (SqlStep(q)) return SqlGetInt(q, 0);
    return 0;
}

// Marks all active grudges of sAvengerUuid against sWrongdoerUuid as fulfilled.
// Returns count of rows updated.
int VendFulfillGrudgesAgainst(string sAvengerUuid, string sWrongdoerUuid)
{
    sqlquery q = SqlPrepareQueryCampaign("vend",
        "UPDATE vend_grudges SET status=1, fulfilled_at=strftime('%s','now') "
        "WHERE victim_uuid=@v AND wrongdoer_uuid=@w AND status=0");
    SqlBindString(q, "@v", sAvengerUuid);
    SqlBindString(q, "@w", sWrongdoerUuid);
    SqlStep(q);
    sqlquery qCnt = SqlPrepareQueryCampaign("vend", "SELECT changes()");
    if (SqlStep(qCnt)) return SqlGetInt(qCnt, 0);
    return 0;
}

void VendForswearGrudge(int nId)
{
    sqlquery q = SqlPrepareQueryCampaign("vend",
        "UPDATE vend_grudges SET status=2, forsworn_at=strftime('%s','now') "
        "WHERE id=@id AND status=0");
    SqlBindInt(q, "@id", nId);
    SqlStep(q);
}

string VendFormatDate(int nUnix)
{
    sqlquery q = SqlPrepareQueryCampaign("vend",
        "SELECT strftime('%d.%m', @ts, 'unixepoch')");
    SqlBindInt(q, "@ts", nUnix);
    if (SqlStep(q)) return SqlGetString(q, 0);
    return "??";
}
