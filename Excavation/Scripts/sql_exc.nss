const string EXC_DB            = "exc";
const int    EXC_SITE_MAX_TRIES = 7;

void ExcCreateTables()
{
    sqlquery q = SqlPrepareQueryCampaign(EXC_DB,
        "CREATE TABLE IF NOT EXISTS exc_shards ("
        "  pc_uuid TEXT NOT NULL, era INTEGER NOT NULL, cnt INTEGER DEFAULT 0,"
        "  PRIMARY KEY (pc_uuid, era))");
    SqlStep(q);

    q = SqlPrepareQueryCampaign(EXC_DB,
        "CREATE TABLE IF NOT EXISTS exc_relics ("
        "  pc_uuid TEXT NOT NULL, era INTEGER NOT NULL, cnt INTEGER DEFAULT 0,"
        "  PRIMARY KEY (pc_uuid, era))");
    SqlStep(q);

    q = SqlPrepareQueryCampaign(EXC_DB,
        "CREATE TABLE IF NOT EXISTS exc_sites ("
        "  pc_uuid TEXT NOT NULL, site_tag TEXT NOT NULL,"
        "  era INTEGER DEFAULT 0, remaining INTEGER DEFAULT 7, progress INTEGER DEFAULT 0,"
        "  PRIMARY KEY (pc_uuid, site_tag))");
    SqlStep(q);
}

// INSERT OR IGNORE — safe to call multiple times for the same site
void ExcInitSite(object oPC, string sSiteTag, int nEra)
{
    sqlquery q = SqlPrepareQueryCampaign(EXC_DB,
        "INSERT OR IGNORE INTO exc_sites (pc_uuid, site_tag, era, remaining, progress)"
        " VALUES (@uuid, @tag, @era, @max, 0)");
    SqlBindString(q, "@uuid", GetObjectUUID(oPC));
    SqlBindString(q, "@tag",  sSiteTag);
    SqlBindInt   (q, "@era",  nEra);
    SqlBindInt   (q, "@max",  EXC_SITE_MAX_TRIES);
    SqlStep(q);
}

// Returns TRUE and populates out-params on success
int ExcGetSiteData(object oPC, string sSiteTag, int &nEra, int &nRemaining, int &nProgress)
{
    sqlquery q = SqlPrepareQueryCampaign(EXC_DB,
        "SELECT era, remaining, progress FROM exc_sites"
        " WHERE pc_uuid = @uuid AND site_tag = @tag");
    SqlBindString(q, "@uuid", GetObjectUUID(oPC));
    SqlBindString(q, "@tag",  sSiteTag);
    if(!SqlStep(q)) return FALSE;
    nEra       = SqlGetInt(q, 0);
    nRemaining = SqlGetInt(q, 1);
    nProgress  = SqlGetInt(q, 2);
    return TRUE;
}

void ExcUpdateSite(object oPC, string sSiteTag, int nRemaining, int nProgress)
{
    sqlquery q = SqlPrepareQueryCampaign(EXC_DB,
        "UPDATE exc_sites SET remaining = @rem, progress = @prog"
        " WHERE pc_uuid = @uuid AND site_tag = @tag");
    SqlBindInt   (q, "@rem",  nRemaining);
    SqlBindInt   (q, "@prog", nProgress);
    SqlBindString(q, "@uuid", GetObjectUUID(oPC));
    SqlBindString(q, "@tag",  sSiteTag);
    SqlStep(q);
}

int ExcGetShards(object oPC, int nEra)
{
    sqlquery q = SqlPrepareQueryCampaign(EXC_DB,
        "SELECT cnt FROM exc_shards WHERE pc_uuid = @uuid AND era = @era");
    SqlBindString(q, "@uuid", GetObjectUUID(oPC));
    SqlBindInt   (q, "@era",  nEra);
    if(SqlStep(q)) return SqlGetInt(q, 0);
    return 0;
}

void ExcSetShards(object oPC, int nEra, int nCount)
{
    sqlquery q = SqlPrepareQueryCampaign(EXC_DB,
        "INSERT OR REPLACE INTO exc_shards (pc_uuid, era, cnt) VALUES (@uuid, @era, @cnt)");
    SqlBindString(q, "@uuid", GetObjectUUID(oPC));
    SqlBindInt   (q, "@era",  nEra);
    SqlBindInt   (q, "@cnt",  nCount);
    SqlStep(q);
}

int ExcGetRelics(object oPC, int nEra)
{
    sqlquery q = SqlPrepareQueryCampaign(EXC_DB,
        "SELECT cnt FROM exc_relics WHERE pc_uuid = @uuid AND era = @era");
    SqlBindString(q, "@uuid", GetObjectUUID(oPC));
    SqlBindInt   (q, "@era",  nEra);
    if(SqlStep(q)) return SqlGetInt(q, 0);
    return 0;
}

void ExcSetRelics(object oPC, int nEra, int nCount)
{
    sqlquery q = SqlPrepareQueryCampaign(EXC_DB,
        "INSERT OR REPLACE INTO exc_relics (pc_uuid, era, cnt) VALUES (@uuid, @era, @cnt)");
    SqlBindString(q, "@uuid", GetObjectUUID(oPC));
    SqlBindInt   (q, "@era",  nEra);
    SqlBindInt   (q, "@cnt",  nCount);
    SqlStep(q);
}
