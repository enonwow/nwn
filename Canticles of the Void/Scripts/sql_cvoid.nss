// sql_cvoid.nss — SQL schema and queries for Canticles of the Void

const string CVOID_DB = "cvoid";

void CvoidCreateTables()
{
    sqlquery q = SqlPrepareQueryCampaign(CVOID_DB,
        "CREATE TABLE IF NOT EXISTS void_taint ("
        "  pc_uuid TEXT PRIMARY KEY,"
        "  taint INTEGER DEFAULT 0,"
        "  last_modified INTEGER DEFAULT 0"
        ")");
    SqlStep(q);

    q = SqlPrepareQueryCampaign(CVOID_DB,
        "CREATE TABLE IF NOT EXISTS void_cooldowns ("
        "  pc_uuid TEXT NOT NULL,"
        "  canticle_id INTEGER NOT NULL,"
        "  expires INTEGER NOT NULL,"
        "  PRIMARY KEY (pc_uuid, canticle_id)"
        ")");
    SqlStep(q);

    q = SqlPrepareQueryCampaign(CVOID_DB,
        "CREATE TABLE IF NOT EXISTS void_purify_cd ("
        "  pc_uuid TEXT PRIMARY KEY,"
        "  expires INTEGER NOT NULL"
        ")");
    SqlStep(q);
}

// ----------------------------------------------------------------
// Taint
// ----------------------------------------------------------------

int CvoidGetTaint(object oPC)
{
    sqlquery q = SqlPrepareQueryCampaign(CVOID_DB,
        "SELECT taint FROM void_taint WHERE pc_uuid = @uuid");
    SqlBindString(q, "@uuid", GetObjectUUID(oPC));
    if(SqlStep(q)) return SqlGetInt(q, 0);
    return 0;
}

void CvoidSetTaint(object oPC, int nTaint)
{
    if(nTaint < 0) nTaint = 0;
    if(nTaint > 100) nTaint = 100;
    sqlquery q = SqlPrepareQueryCampaign(CVOID_DB,
        "INSERT OR REPLACE INTO void_taint (pc_uuid, taint, last_modified) "
        "VALUES (@uuid, @taint, strftime('%s','now'))");
    SqlBindString(q, "@uuid",  GetObjectUUID(oPC));
    SqlBindInt   (q, "@taint", nTaint);
    SqlStep(q);
}

int CvoidAddTaint(object oPC, int nGain)
{
    int nOld = CvoidGetTaint(oPC);
    int nNew = nOld + nGain;
    if(nNew > 100) nNew = 100;
    CvoidSetTaint(oPC, nNew);
    return nNew;
}

// Natural decay: 1 taint per elapsed day, applied on login
void CvoidTickDailyDecay(object oPC)
{
    sqlquery q = SqlPrepareQueryCampaign(CVOID_DB,
        "UPDATE void_taint "
        "SET taint = MAX(0, taint - CAST((strftime('%s','now') - last_modified) / 86400 AS INTEGER)),"
        "    last_modified = strftime('%s','now') "
        "WHERE pc_uuid = @uuid AND last_modified < strftime('%s','now') - 86400");
    SqlBindString(q, "@uuid", GetObjectUUID(oPC));
    SqlStep(q);
}

// ----------------------------------------------------------------
// Cooldowns
// ----------------------------------------------------------------

// Returns seconds remaining on cooldown (0 = ready)
int CvoidGetCdRemaining(object oPC, int nCanticle)
{
    sqlquery q = SqlPrepareQueryCampaign(CVOID_DB,
        "SELECT MAX(0, CAST(expires - strftime('%s','now') AS INTEGER)) "
        "FROM void_cooldowns "
        "WHERE pc_uuid = @uuid AND canticle_id = @id");
    SqlBindString(q, "@uuid", GetObjectUUID(oPC));
    SqlBindInt   (q, "@id",   nCanticle);
    if(SqlStep(q)) return SqlGetInt(q, 0);
    return 0;
}

void CvoidSetCooldown(object oPC, int nCanticle, int nDurationSecs)
{
    sqlquery q = SqlPrepareQueryCampaign(CVOID_DB,
        "INSERT OR REPLACE INTO void_cooldowns (pc_uuid, canticle_id, expires) "
        "VALUES (@uuid, @id, strftime('%s','now') + @dur)");
    SqlBindString(q, "@uuid", GetObjectUUID(oPC));
    SqlBindInt   (q, "@id",   nCanticle);
    SqlBindInt   (q, "@dur",  nDurationSecs);
    SqlStep(q);
}

// ----------------------------------------------------------------
// Purification cooldown
// ----------------------------------------------------------------

int CvoidGetPurifyCdRemaining(object oPC)
{
    sqlquery q = SqlPrepareQueryCampaign(CVOID_DB,
        "SELECT MAX(0, CAST(expires - strftime('%s','now') AS INTEGER)) "
        "FROM void_purify_cd WHERE pc_uuid = @uuid");
    SqlBindString(q, "@uuid", GetObjectUUID(oPC));
    if(SqlStep(q)) return SqlGetInt(q, 0);
    return 0;
}

void CvoidSetPurifyCooldown(object oPC, int nDurationSecs)
{
    sqlquery q = SqlPrepareQueryCampaign(CVOID_DB,
        "INSERT OR REPLACE INTO void_purify_cd (pc_uuid, expires) "
        "VALUES (@uuid, strftime('%s','now') + @dur)");
    SqlBindString(q, "@uuid", GetObjectUUID(oPC));
    SqlBindInt   (q, "@dur",  nDurationSecs);
    SqlStep(q);
}
