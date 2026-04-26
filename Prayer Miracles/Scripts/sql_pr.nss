// Prayer & Miracles — persistence (campaign DB "pr")

const string PR_DB = "pr";

void PrCreateTables()
{
    sqlquery q = SqlPrepareQueryCampaign(PR_DB,
        "CREATE TABLE IF NOT EXISTS pr_devotion ("
        "uuid TEXT PRIMARY KEY, "
        "char_name TEXT DEFAULT '', "
        "deity_id INTEGER DEFAULT -1, "
        "favor INTEGER DEFAULT 0, "
        "last_prayed_at INTEGER DEFAULT 0, "
        "miracles_cast INTEGER DEFAULT 0, "
        "created_at INTEGER DEFAULT 0)");
    SqlStep(q);
}

void PrEnsureRow(object oPC)
{
    sqlquery q = SqlPrepareQueryCampaign(PR_DB,
        "INSERT OR IGNORE INTO pr_devotion (uuid, char_name, created_at) "
        "VALUES (@u, @n, strftime('%s','now'))");
    SqlBindString(q, "@u", GetObjectUUID(oPC));
    SqlBindString(q, "@n", GetName(oPC));
    SqlStep(q);
}

int PrGetDeity(string sUuid)
{
    sqlquery q = SqlPrepareQueryCampaign(PR_DB,
        "SELECT deity_id FROM pr_devotion WHERE uuid = @u");
    SqlBindString(q, "@u", sUuid);
    if(SqlStep(q)) return SqlGetInt(q, 0);
    return -1;
}

int PrGetFavor(string sUuid)
{
    sqlquery q = SqlPrepareQueryCampaign(PR_DB,
        "SELECT favor FROM pr_devotion WHERE uuid = @u");
    SqlBindString(q, "@u", sUuid);
    if(SqlStep(q)) return SqlGetInt(q, 0);
    return 0;
}

int PrGetLastPrayedAt(string sUuid)
{
    sqlquery q = SqlPrepareQueryCampaign(PR_DB,
        "SELECT last_prayed_at FROM pr_devotion WHERE uuid = @u");
    SqlBindString(q, "@u", sUuid);
    if(SqlStep(q)) return SqlGetInt(q, 0);
    return 0;
}

int PrGetNowSeconds()
{
    sqlquery q = SqlPrepareQueryCampaign(PR_DB,
        "SELECT CAST(strftime('%s','now') AS INTEGER)");
    if(SqlStep(q)) return SqlGetInt(q, 0);
    return 0;
}

void PrSetDeity(string sUuid, int nDeity)
{
    sqlquery q = SqlPrepareQueryCampaign(PR_DB,
        "UPDATE pr_devotion SET deity_id = @d WHERE uuid = @u");
    SqlBindInt   (q, "@d", nDeity);
    SqlBindString(q, "@u", sUuid);
    SqlStep(q);
}

void PrAdjustFavor(string sUuid, int nDelta, int nMin, int nMax)
{
    sqlquery q = SqlPrepareQueryCampaign(PR_DB,
        "UPDATE pr_devotion SET favor = MAX(@lo, MIN(@hi, favor + @d)) WHERE uuid = @u");
    SqlBindInt   (q, "@lo", nMin);
    SqlBindInt   (q, "@hi", nMax);
    SqlBindInt   (q, "@d",  nDelta);
    SqlBindString(q, "@u",  sUuid);
    SqlStep(q);
}

void PrMarkPrayed(string sUuid)
{
    sqlquery q = SqlPrepareQueryCampaign(PR_DB,
        "UPDATE pr_devotion SET last_prayed_at = strftime('%s','now') WHERE uuid = @u");
    SqlBindString(q, "@u", sUuid);
    SqlStep(q);
}

void PrIncMiraclesCast(string sUuid)
{
    sqlquery q = SqlPrepareQueryCampaign(PR_DB,
        "UPDATE pr_devotion SET miracles_cast = miracles_cast + 1 WHERE uuid = @u");
    SqlBindString(q, "@u", sUuid);
    SqlStep(q);
}

int PrGetMiraclesCast(string sUuid)
{
    sqlquery q = SqlPrepareQueryCampaign(PR_DB,
        "SELECT miracles_cast FROM pr_devotion WHERE uuid = @u");
    SqlBindString(q, "@u", sUuid);
    if(SqlStep(q)) return SqlGetInt(q, 0);
    return 0;
}
