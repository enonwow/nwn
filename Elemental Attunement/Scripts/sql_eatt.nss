// sql_eatt.nss — SQL layer for Elemental Attunement

void EattCreateTables()
{
    sqlquery q = SqlPrepareQueryCampaign("eatt",
        "CREATE TABLE IF NOT EXISTS eatt_attunement ("
        "uuid TEXT NOT NULL, "
        "elem INTEGER NOT NULL, "
        "points INTEGER DEFAULT 0, "
        "PRIMARY KEY (uuid, elem))");
    SqlStep(q);
}

void EattEnsureRow(string sUUID, int nElem)
{
    sqlquery q = SqlPrepareQueryCampaign("eatt",
        "INSERT OR IGNORE INTO eatt_attunement (uuid, elem, points) VALUES (@uuid, @elem, 0)");
    SqlBindString(q, "@uuid", sUUID);
    SqlBindInt   (q, "@elem", nElem);
    SqlStep(q);
}

int EattGetPoints(string sUUID, int nElem)
{
    EattEnsureRow(sUUID, nElem);
    sqlquery q = SqlPrepareQueryCampaign("eatt",
        "SELECT points FROM eatt_attunement WHERE uuid = @uuid AND elem = @elem");
    SqlBindString(q, "@uuid", sUUID);
    SqlBindInt   (q, "@elem", nElem);
    if (SqlStep(q)) return SqlGetInt(q, 0);
    return 0;
}

void EattAddPointsDB(string sUUID, int nElem, int nAdd, int nCap)
{
    EattEnsureRow(sUUID, nElem);
    sqlquery q = SqlPrepareQueryCampaign("eatt",
        "UPDATE eatt_attunement SET points = MIN(points + @add, @cap) WHERE uuid = @uuid AND elem = @elem");
    SqlBindString(q, "@uuid", sUUID);
    SqlBindInt   (q, "@elem", nElem);
    SqlBindInt   (q, "@add",  nAdd);
    SqlBindInt   (q, "@cap",  nCap);
    SqlStep(q);
}

void EattResetPoints(string sUUID, int nElem)
{
    sqlquery q = SqlPrepareQueryCampaign("eatt",
        "UPDATE eatt_attunement SET points = 0 WHERE uuid = @uuid AND elem = @elem");
    SqlBindString(q, "@uuid", sUUID);
    SqlBindInt   (q, "@elem", nElem);
    SqlStep(q);
}
