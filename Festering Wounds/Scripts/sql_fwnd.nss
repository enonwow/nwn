// How many real seconds before an untreated wound progresses +1 severity
const int FWND_PROGRESS_INTERVAL = 600;

void FwndCreateTables()
{
    sqlquery q = SqlPrepareQueryCampaign("festering_wounds",
        "CREATE TABLE IF NOT EXISTS fwnd_wounds ("
        "id INTEGER PRIMARY KEY AUTOINCREMENT, "
        "pc_uuid TEXT NOT NULL, "
        "wound_type INTEGER NOT NULL DEFAULT 1, "
        "severity INTEGER NOT NULL DEFAULT 1, "
        "inflicted_at INTEGER NOT NULL DEFAULT 0, "
        "last_progressed INTEGER NOT NULL DEFAULT 0, "
        "source_name TEXT DEFAULT '')");
    SqlStep(q);
}

// If a wound of the same type already exists, worsen it instead of inserting.
void FwndInflictWound(object oPC, int nType, string sSource)
{
    sqlquery qCheck = SqlPrepareQueryCampaign("festering_wounds",
        "SELECT id, severity FROM fwnd_wounds "
        "WHERE pc_uuid = @uuid AND wound_type = @type LIMIT 1");
    SqlBindString(qCheck, "@uuid", GetObjectUUID(oPC));
    SqlBindInt   (qCheck, "@type", nType);
    if(SqlStep(qCheck))
    {
        int nId  = SqlGetInt(qCheck, 0);
        int nSev = SqlGetInt(qCheck, 1);
        if(nSev < 5)
        {
            sqlquery qUp = SqlPrepareQueryCampaign("festering_wounds",
                "UPDATE fwnd_wounds SET severity = @sev, source_name = @src "
                "WHERE id = @id");
            SqlBindInt   (qUp, "@sev", nSev + 1);
            SqlBindString(qUp, "@src", sSource);
            SqlBindInt   (qUp, "@id",  nId);
            SqlStep(qUp);
        }
        return;
    }

    sqlquery q = SqlPrepareQueryCampaign("festering_wounds",
        "INSERT INTO fwnd_wounds "
        "(pc_uuid, wound_type, severity, inflicted_at, last_progressed, source_name) "
        "VALUES (@uuid, @type, 1, strftime('%s','now'), strftime('%s','now'), @src)");
    SqlBindString(q, "@uuid", GetObjectUUID(oPC));
    SqlBindInt   (q, "@type", nType);
    SqlBindString(q, "@src",  sSource);
    SqlStep(q);
}

json FwndGetWounds(object oPC)
{
    json jRows = JsonArray();
    sqlquery q = SqlPrepareQueryCampaign("festering_wounds",
        "SELECT id, wound_type, severity, inflicted_at, last_progressed, source_name "
        "FROM fwnd_wounds WHERE pc_uuid = @uuid ORDER BY inflicted_at ASC");
    SqlBindString(q, "@uuid", GetObjectUUID(oPC));
    while(SqlStep(q))
    {
        json jRow = JsonObject();
        jRow = JsonObjectSet(jRow, "id",              JsonInt   (SqlGetInt   (q, 0)));
        jRow = JsonObjectSet(jRow, "wound_type",      JsonInt   (SqlGetInt   (q, 1)));
        jRow = JsonObjectSet(jRow, "severity",        JsonInt   (SqlGetInt   (q, 2)));
        jRow = JsonObjectSet(jRow, "inflicted_at",    JsonInt   (SqlGetInt   (q, 3)));
        jRow = JsonObjectSet(jRow, "last_progressed", JsonInt   (SqlGetInt   (q, 4)));
        jRow = JsonObjectSet(jRow, "source_name",     JsonString(SqlGetString(q, 5)));
        jRows = JsonArrayInsert(jRows, jRow);
    }
    return jRows;
}

json FwndGetWound(int nId)
{
    sqlquery q = SqlPrepareQueryCampaign("festering_wounds",
        "SELECT id, wound_type, severity, inflicted_at, last_progressed, source_name "
        "FROM fwnd_wounds WHERE id = @id");
    SqlBindInt(q, "@id", nId);
    if(!SqlStep(q)) return JsonNull();
    json jRow = JsonObject();
    jRow = JsonObjectSet(jRow, "id",              JsonInt   (SqlGetInt   (q, 0)));
    jRow = JsonObjectSet(jRow, "wound_type",      JsonInt   (SqlGetInt   (q, 1)));
    jRow = JsonObjectSet(jRow, "severity",        JsonInt   (SqlGetInt   (q, 2)));
    jRow = JsonObjectSet(jRow, "inflicted_at",    JsonInt   (SqlGetInt   (q, 3)));
    jRow = JsonObjectSet(jRow, "last_progressed", JsonInt   (SqlGetInt   (q, 4)));
    jRow = JsonObjectSet(jRow, "source_name",     JsonString(SqlGetString(q, 5)));
    return jRow;
}

// nNewSev <= 0 removes the wound entirely.
void FwndSetSeverity(int nId, int nNewSev)
{
    if(nNewSev <= 0)
    {
        sqlquery q = SqlPrepareQueryCampaign("festering_wounds",
            "DELETE FROM fwnd_wounds WHERE id = @id");
        SqlBindInt(q, "@id", nId);
        SqlStep(q);
        return;
    }
    sqlquery q = SqlPrepareQueryCampaign("festering_wounds",
        "UPDATE fwnd_wounds SET severity = @sev, last_progressed = strftime('%s','now') "
        "WHERE id = @id");
    SqlBindInt(q, "@sev", nNewSev);
    SqlBindInt(q, "@id",  nId);
    SqlStep(q);
}

int FwndCountWounds(object oPC)
{
    sqlquery q = SqlPrepareQueryCampaign("festering_wounds",
        "SELECT COUNT(*) FROM fwnd_wounds WHERE pc_uuid = @uuid");
    SqlBindString(q, "@uuid", GetObjectUUID(oPC));
    if(SqlStep(q)) return SqlGetInt(q, 0);
    return 0;
}

json FwndGetWoundsToProgress(object oPC)
{
    json jRows = JsonArray();
    sqlquery q = SqlPrepareQueryCampaign("festering_wounds",
        "SELECT id, wound_type, severity FROM fwnd_wounds "
        "WHERE pc_uuid = @uuid "
        "AND last_progressed < strftime('%s','now') - @interval "
        "AND severity < 5");
    SqlBindString(q, "@uuid",     GetObjectUUID(oPC));
    SqlBindInt   (q, "@interval", FWND_PROGRESS_INTERVAL);
    while(SqlStep(q))
    {
        json jRow = JsonObject();
        jRow = JsonObjectSet(jRow, "id",         JsonInt(SqlGetInt(q, 0)));
        jRow = JsonObjectSet(jRow, "wound_type", JsonInt(SqlGetInt(q, 1)));
        jRow = JsonObjectSet(jRow, "severity",   JsonInt(SqlGetInt(q, 2)));
        jRows = JsonArrayInsert(jRows, jRow);
    }
    return jRows;
}
