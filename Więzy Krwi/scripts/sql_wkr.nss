#include "lib_wkr_def"

void WkrCreateTables()
{
    sqlquery q = SqlPrepareQueryCampaign("wkr",
        "CREATE TABLE IF NOT EXISTS wkr_bonds ("
        "id              INTEGER PRIMARY KEY AUTOINCREMENT, "
        "initiator_uuid  TEXT NOT NULL, "
        "initiator_name  TEXT DEFAULT '', "
        "partner_uuid    TEXT NOT NULL, "
        "partner_name    TEXT DEFAULT '', "
        "bond_type       INTEGER NOT NULL DEFAULT 1, "
        "status          INTEGER NOT NULL DEFAULT 0, "
        "terms_json      TEXT NOT NULL DEFAULT '{}', "
        "sealed_at       INTEGER DEFAULT 0, "
        "expires_at      INTEGER DEFAULT 0"
        ")");
    SqlStep(q);

    q = SqlPrepareQueryCampaign("wkr",
        "CREATE INDEX IF NOT EXISTS idx_wkr_init ON wkr_bonds(initiator_uuid)");
    SqlStep(q);

    q = SqlPrepareQueryCampaign("wkr",
        "CREATE INDEX IF NOT EXISTS idx_wkr_part ON wkr_bonds(partner_uuid)");
    SqlStep(q);
}

// Returns all non-terminal bonds involving this PC.
json WkrGetBonds(string sUuid)
{
    json jRows = JsonArray();
    sqlquery q = SqlPrepareQueryCampaign("wkr",
        "SELECT id, initiator_uuid, initiator_name, partner_uuid, partner_name, "
        "bond_type, status, terms_json, sealed_at, expires_at "
        "FROM wkr_bonds "
        "WHERE (initiator_uuid = @uuid OR partner_uuid = @uuid) "
        "  AND status NOT IN (3, 4) "
        "ORDER BY id DESC");
    SqlBindString(q, "@uuid", sUuid);
    while(SqlStep(q))
    {
        json jR = JsonObject();
        jR = JsonObjectSet(jR, "id",             JsonInt   (SqlGetInt   (q, 0)));
        jR = JsonObjectSet(jR, "initiator_uuid", JsonString(SqlGetString(q, 1)));
        jR = JsonObjectSet(jR, "initiator_name", JsonString(SqlGetString(q, 2)));
        jR = JsonObjectSet(jR, "partner_uuid",   JsonString(SqlGetString(q, 3)));
        jR = JsonObjectSet(jR, "partner_name",   JsonString(SqlGetString(q, 4)));
        jR = JsonObjectSet(jR, "bond_type",      JsonInt   (SqlGetInt   (q, 5)));
        jR = JsonObjectSet(jR, "status",         JsonInt   (SqlGetInt   (q, 6)));
        jR = JsonObjectSet(jR, "terms_json",     JsonString(SqlGetString(q, 7)));
        jR = JsonObjectSet(jR, "sealed_at",      JsonInt   (SqlGetInt   (q, 8)));
        jR = JsonObjectSet(jR, "expires_at",     JsonInt   (SqlGetInt   (q, 9)));
        jRows = JsonArrayInsert(jRows, jR);
    }
    return jRows;
}

json WkrGetBond(int nId)
{
    sqlquery q = SqlPrepareQueryCampaign("wkr",
        "SELECT id, initiator_uuid, initiator_name, partner_uuid, partner_name, "
        "bond_type, status, terms_json, sealed_at, expires_at "
        "FROM wkr_bonds WHERE id = @id");
    SqlBindInt(q, "@id", nId);
    if(!SqlStep(q)) return JsonNull();
    json jR = JsonObject();
    jR = JsonObjectSet(jR, "id",             JsonInt   (SqlGetInt   (q, 0)));
    jR = JsonObjectSet(jR, "initiator_uuid", JsonString(SqlGetString(q, 1)));
    jR = JsonObjectSet(jR, "initiator_name", JsonString(SqlGetString(q, 2)));
    jR = JsonObjectSet(jR, "partner_uuid",   JsonString(SqlGetString(q, 3)));
    jR = JsonObjectSet(jR, "partner_name",   JsonString(SqlGetString(q, 4)));
    jR = JsonObjectSet(jR, "bond_type",      JsonInt   (SqlGetInt   (q, 5)));
    jR = JsonObjectSet(jR, "status",         JsonInt   (SqlGetInt   (q, 6)));
    jR = JsonObjectSet(jR, "terms_json",     JsonString(SqlGetString(q, 7)));
    jR = JsonObjectSet(jR, "sealed_at",      JsonInt   (SqlGetInt   (q, 8)));
    jR = JsonObjectSet(jR, "expires_at",     JsonInt   (SqlGetInt   (q, 9)));
    return jR;
}

int WkrCreateBond(string sInitUuid, string sInitName,
                  string sPartUuid, string sPartName,
                  int nType, string sTerms, int nExpires)
{
    sqlquery q = SqlPrepareQueryCampaign("wkr",
        "INSERT INTO wkr_bonds "
        "(initiator_uuid, initiator_name, partner_uuid, partner_name, "
        " bond_type, status, terms_json, sealed_at, expires_at) "
        "VALUES (@iu, @in, @pu, @pn, @type, 0, @terms, 0, @exp)");
    SqlBindString(q, "@iu",    sInitUuid);
    SqlBindString(q, "@in",    sInitName);
    SqlBindString(q, "@pu",    sPartUuid);
    SqlBindString(q, "@pn",    sPartName);
    SqlBindInt   (q, "@type",  nType);
    SqlBindString(q, "@terms", sTerms);
    SqlBindInt   (q, "@exp",   nExpires);
    SqlStep(q);
    sqlquery qId = SqlPrepareQueryCampaign("wkr", "SELECT last_insert_rowid()");
    if(SqlStep(qId)) return SqlGetInt(qId, 0);
    return 0;
}

void WkrActivateBond(int nId)
{
    sqlquery q = SqlPrepareQueryCampaign("wkr",
        "UPDATE wkr_bonds SET status = 1, sealed_at = strftime('%s','now') WHERE id = @id");
    SqlBindInt(q, "@id", nId);
    SqlStep(q);
}

void WkrSetStatus(int nId, int nStatus)
{
    sqlquery q = SqlPrepareQueryCampaign("wkr",
        "UPDATE wkr_bonds SET status = @st WHERE id = @id");
    SqlBindInt(q, "@st", nStatus);
    SqlBindInt(q, "@id", nId);
    SqlStep(q);
}

void WkrUpdateTerms(int nId, string sTerms)
{
    sqlquery q = SqlPrepareQueryCampaign("wkr",
        "UPDATE wkr_bonds SET terms_json = @t WHERE id = @id");
    SqlBindString(q, "@t",  sTerms);
    SqlBindInt   (q, "@id", nId);
    SqlStep(q);
}

int WkrCountActive(string sUuid)
{
    sqlquery q = SqlPrepareQueryCampaign("wkr",
        "SELECT COUNT(*) FROM wkr_bonds "
        "WHERE (initiator_uuid = @uuid OR partner_uuid = @uuid) AND status IN (0,1)");
    SqlBindString(q, "@uuid", sUuid);
    if(SqlStep(q)) return SqlGetInt(q, 0);
    return 0;
}

// Fetch debt bonds that have passed their deadline and are still active.
json WkrGetOverdueDebts()
{
    json jRows = JsonArray();
    sqlquery q = SqlPrepareQueryCampaign("wkr",
        "SELECT id, initiator_uuid, initiator_name, partner_uuid, partner_name "
        "FROM wkr_bonds "
        "WHERE bond_type = 1 AND status = 1 "
        "  AND expires_at > 0 AND expires_at < strftime('%s','now')");
    while(SqlStep(q))
    {
        json jR = JsonObject();
        jR = JsonObjectSet(jR, "id",             JsonInt   (SqlGetInt   (q, 0)));
        jR = JsonObjectSet(jR, "initiator_uuid", JsonString(SqlGetString(q, 1)));
        jR = JsonObjectSet(jR, "initiator_name", JsonString(SqlGetString(q, 2)));
        jR = JsonObjectSet(jR, "partner_uuid",   JsonString(SqlGetString(q, 3)));
        jR = JsonObjectSet(jR, "partner_name",   JsonString(SqlGetString(q, 4)));
        jRows = JsonArrayInsert(jRows, jR);
    }
    return jRows;
}

// Returns "DD.MM.YYYY HH:MM" from a unix timestamp via SQLite.
string WkrFormatTs(int nTs)
{
    sqlquery q = SqlPrepareQueryCampaign("wkr",
        "SELECT strftime('%d.%m.%Y %H:%M', @ts, 'unixepoch')");
    SqlBindInt(q, "@ts", nTs);
    if(SqlStep(q)) return SqlGetString(q, 0);
    return "—";
}

// Returns current unix time from SQLite (avoids in-engine time drift).
int WkrNow()
{
    sqlquery q = SqlPrepareQueryCampaign("wkr", "SELECT strftime('%s','now')");
    if(SqlStep(q)) return SqlGetInt(q, 0);
    return 0;
}
