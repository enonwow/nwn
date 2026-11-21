// Master & Apprentice — persistence (campaign DB "ma")

const string MA_DB = "ma";

void MaCreateTables()
{
    sqlquery q = SqlPrepareQueryCampaign(MA_DB,
        "CREATE TABLE IF NOT EXISTS ma_bonds ("
        "id INTEGER PRIMARY KEY AUTOINCREMENT, "
        "master_uuid TEXT NOT NULL, "
        "master_name TEXT DEFAULT '', "
        "apprentice_uuid TEXT NOT NULL, "
        "apprentice_name TEXT DEFAULT '', "
        "created_at INTEGER DEFAULT 0, "
        "broken_at INTEGER DEFAULT 0, "
        "broken_reason TEXT DEFAULT '', "
        "xp_shared_total INTEGER DEFAULT 0)");
    SqlStep(q);

    q = SqlPrepareQueryCampaign(MA_DB,
        "CREATE INDEX IF NOT EXISTS idx_ma_master "
        "ON ma_bonds(master_uuid, broken_at)");
    SqlStep(q);

    q = SqlPrepareQueryCampaign(MA_DB,
        "CREATE INDEX IF NOT EXISTS idx_ma_apprentice "
        "ON ma_bonds(apprentice_uuid, broken_at)");
    SqlStep(q);
}

int MaCountActiveApprentices(string sMasterUuid)
{
    sqlquery q = SqlPrepareQueryCampaign(MA_DB,
        "SELECT COUNT(*) FROM ma_bonds "
        "WHERE master_uuid = @u AND broken_at = 0");
    SqlBindString(q, "@u", sMasterUuid);
    if(SqlStep(q)) return SqlGetInt(q, 0);
    return 0;
}

int MaHasMaster(string sApprenticeUuid)
{
    sqlquery q = SqlPrepareQueryCampaign(MA_DB,
        "SELECT COUNT(*) FROM ma_bonds "
        "WHERE apprentice_uuid = @u AND broken_at = 0");
    SqlBindString(q, "@u", sApprenticeUuid);
    if(SqlStep(q)) return SqlGetInt(q, 0) > 0;
    return 0;
}

string MaGetMasterUuid(string sApprenticeUuid)
{
    sqlquery q = SqlPrepareQueryCampaign(MA_DB,
        "SELECT master_uuid FROM ma_bonds "
        "WHERE apprentice_uuid = @u AND broken_at = 0 LIMIT 1");
    SqlBindString(q, "@u", sApprenticeUuid);
    if(SqlStep(q)) return SqlGetString(q, 0);
    return "";
}

string MaGetMasterName(string sApprenticeUuid)
{
    sqlquery q = SqlPrepareQueryCampaign(MA_DB,
        "SELECT master_name FROM ma_bonds "
        "WHERE apprentice_uuid = @u AND broken_at = 0 LIMIT 1");
    SqlBindString(q, "@u", sApprenticeUuid);
    if(SqlStep(q)) return SqlGetString(q, 0);
    return "";
}

int MaCreateBond(object oMaster, object oApprentice)
{
    sqlquery q = SqlPrepareQueryCampaign(MA_DB,
        "INSERT INTO ma_bonds (master_uuid, master_name, apprentice_uuid, apprentice_name, created_at) "
        "VALUES (@mu, @mn, @au, @an, strftime('%s','now'))");
    SqlBindString(q, "@mu", GetObjectUUID(oMaster));
    SqlBindString(q, "@mn", GetName(oMaster));
    SqlBindString(q, "@au", GetObjectUUID(oApprentice));
    SqlBindString(q, "@an", GetName(oApprentice));
    SqlStep(q);
    sqlquery qId = SqlPrepareQueryCampaign(MA_DB, "SELECT last_insert_rowid()");
    if(SqlStep(qId)) return SqlGetInt(qId, 0);
    return 0;
}

void MaBreakBond(int nId, string sReason)
{
    sqlquery q = SqlPrepareQueryCampaign(MA_DB,
        "UPDATE ma_bonds SET broken_at = strftime('%s','now'), broken_reason = @r "
        "WHERE id = @id AND broken_at = 0");
    SqlBindString(q, "@r", sReason);
    SqlBindInt   (q, "@id", nId);
    SqlStep(q);
}

void MaBreakBondByApprentice(string sApprenticeUuid, string sReason)
{
    sqlquery q = SqlPrepareQueryCampaign(MA_DB,
        "UPDATE ma_bonds SET broken_at = strftime('%s','now'), broken_reason = @r "
        "WHERE apprentice_uuid = @u AND broken_at = 0");
    SqlBindString(q, "@r", sReason);
    SqlBindString(q, "@u", sApprenticeUuid);
    SqlStep(q);
}

void MaAddSharedXp(int nId, int nDelta)
{
    sqlquery q = SqlPrepareQueryCampaign(MA_DB,
        "UPDATE ma_bonds SET xp_shared_total = xp_shared_total + @d WHERE id = @id");
    SqlBindInt(q, "@d",  nDelta);
    SqlBindInt(q, "@id", nId);
    SqlStep(q);
}

int MaGetActiveBondId(string sMasterUuid, string sApprenticeUuid)
{
    sqlquery q = SqlPrepareQueryCampaign(MA_DB,
        "SELECT id FROM ma_bonds WHERE master_uuid = @m AND apprentice_uuid = @a "
        "AND broken_at = 0 LIMIT 1");
    SqlBindString(q, "@m", sMasterUuid);
    SqlBindString(q, "@a", sApprenticeUuid);
    if(SqlStep(q)) return SqlGetInt(q, 0);
    return 0;
}

// Returns array of {id, apprentice_uuid, apprentice_name, xp_shared_total, created_at}
json MaGetApprentices(string sMasterUuid)
{
    json jRows = JsonArray();
    sqlquery q = SqlPrepareQueryCampaign(MA_DB,
        "SELECT id, apprentice_uuid, apprentice_name, xp_shared_total, created_at "
        "FROM ma_bonds WHERE master_uuid = @u AND broken_at = 0 "
        "ORDER BY created_at ASC");
    SqlBindString(q, "@u", sMasterUuid);
    while(SqlStep(q))
    {
        json j = JsonObject();
        j = JsonObjectSet(j, "id",              JsonInt   (SqlGetInt   (q, 0)));
        j = JsonObjectSet(j, "uuid",            JsonString(SqlGetString(q, 1)));
        j = JsonObjectSet(j, "name",            JsonString(SqlGetString(q, 2)));
        j = JsonObjectSet(j, "xp_shared_total", JsonInt   (SqlGetInt   (q, 3)));
        j = JsonObjectSet(j, "created_at",      JsonInt   (SqlGetInt   (q, 4)));
        jRows = JsonArrayInsert(jRows, j);
    }
    return jRows;
}

int MaGetActiveBondIdForApprentice(string sApprenticeUuid)
{
    sqlquery q = SqlPrepareQueryCampaign(MA_DB,
        "SELECT id FROM ma_bonds WHERE apprentice_uuid = @u AND broken_at = 0 LIMIT 1");
    SqlBindString(q, "@u", sApprenticeUuid);
    if(SqlStep(q)) return SqlGetInt(q, 0);
    return 0;
}
