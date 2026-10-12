// sql_chim.nss
// Campaign DB name: "chimera"

void ChimCreateTable()
{
    sqlquery q = SqlPrepareQueryCampaign("chimera",
        "CREATE TABLE IF NOT EXISTS chim_grafts ("
        "  uuid       TEXT NOT NULL,"
        "  slot       TEXT NOT NULL,"
        "  graft_id   INTEGER NOT NULL,"
        "  applied_at INTEGER DEFAULT 0,"
        "  PRIMARY KEY (uuid, slot)"
        ")");
    SqlStep(q);
}

// Returns installed graft_id for the slot, or 0 if empty.
int ChimGetInstalledGraft(string sUuid, string sSlot)
{
    sqlquery q = SqlPrepareQueryCampaign("chimera",
        "SELECT graft_id FROM chim_grafts WHERE uuid = @uuid AND slot = @slot");
    SqlBindString(q, "@uuid", sUuid);
    SqlBindString(q, "@slot", sSlot);
    if(SqlStep(q)) return SqlGetInt(q, 0);
    return 0;
}

// Returns JsonArray of {slot, graft_id} rows for all installed grafts on this PC.
json ChimGetAllGrafts(string sUuid)
{
    json jResult = JsonArray();
    sqlquery q = SqlPrepareQueryCampaign("chimera",
        "SELECT slot, graft_id FROM chim_grafts WHERE uuid = @uuid");
    SqlBindString(q, "@uuid", sUuid);
    while(SqlStep(q))
    {
        json jRow = JsonObject();
        jRow = JsonObjectSet(jRow, "slot",     JsonString(SqlGetString(q, 0)));
        jRow = JsonObjectSet(jRow, "graft_id", JsonInt   (SqlGetInt   (q, 1)));
        jResult = JsonArrayInsert(jResult, jRow);
    }
    return jResult;
}

void ChimInstallGraft(string sUuid, string sSlot, int nGraftId)
{
    sqlquery q = SqlPrepareQueryCampaign("chimera",
        "INSERT OR REPLACE INTO chim_grafts (uuid, slot, graft_id, applied_at)"
        " VALUES (@uuid, @slot, @id, strftime('%s','now'))");
    SqlBindString(q, "@uuid", sUuid);
    SqlBindString(q, "@slot", sSlot);
    SqlBindInt   (q, "@id",   nGraftId);
    SqlStep(q);
}

void ChimRemoveGraft(string sUuid, string sSlot)
{
    sqlquery q = SqlPrepareQueryCampaign("chimera",
        "DELETE FROM chim_grafts WHERE uuid = @uuid AND slot = @slot");
    SqlBindString(q, "@uuid", sUuid);
    SqlBindString(q, "@slot", sSlot);
    SqlStep(q);
}
