// sql_balt.nss — Blood Altar: SQLite schema i zapytania

const string BALT_DB          = "blood_altar";
const int    BALT_CORRUPT_MAX = 100;

void BaltCreateTables()
{
    sqlquery q = SqlPrepareQueryCampaign(BALT_DB,
        "CREATE TABLE IF NOT EXISTS balt_corruption "
        "(player_uuid TEXT PRIMARY KEY, corruption INTEGER DEFAULT 0, "
        "last_sacrifice INTEGER DEFAULT 0)");
    SqlStep(q);

    q = SqlPrepareQueryCampaign(BALT_DB,
        "CREATE TABLE IF NOT EXISTS balt_log "
        "(id INTEGER PRIMARY KEY AUTOINCREMENT, player_uuid TEXT NOT NULL, "
        "altar_tag TEXT NOT NULL, sac_idx INTEGER NOT NULL, "
        "epoch INTEGER DEFAULT (strftime('%s','now')))");
    SqlStep(q);
}

int BaltGetCorruption(object oPC)
{
    sqlquery q = SqlPrepareQueryCampaign(BALT_DB,
        "SELECT corruption FROM balt_corruption WHERE player_uuid = @uuid");
    SqlBindString(q, "@uuid", GetObjectUUID(oPC));
    if(SqlStep(q)) return SqlGetInt(q, 0);
    return 0;
}

void BaltSetCorruption(object oPC, int nCorruption)
{
    if(nCorruption < 0)             nCorruption = 0;
    if(nCorruption > BALT_CORRUPT_MAX) nCorruption = BALT_CORRUPT_MAX;

    sqlquery q = SqlPrepareQueryCampaign(BALT_DB,
        "INSERT INTO balt_corruption (player_uuid, corruption, last_sacrifice) "
        "VALUES (@uuid, @corr, strftime('%s','now')) "
        "ON CONFLICT(player_uuid) DO UPDATE SET corruption = @corr, "
        "last_sacrifice = strftime('%s','now')");
    SqlBindString(q, "@uuid", GetObjectUUID(oPC));
    SqlBindInt   (q, "@corr", nCorruption);
    SqlStep(q);
}

// Adds nDelta to corruption (clamped 0..BALT_CORRUPT_MAX), returns new value.
int BaltAddCorruption(object oPC, int nDelta)
{
    int nCurrent = BaltGetCorruption(oPC);
    int nNew     = nCurrent + nDelta;
    if(nNew < 0)                 nNew = 0;
    if(nNew > BALT_CORRUPT_MAX)  nNew = BALT_CORRUPT_MAX;
    BaltSetCorruption(oPC, nNew);
    return nNew;
}

// Called on OnClientEnter — decays corruption if enough time passed since last sacrifice.
void BaltDecayOnEnter(object oPC)
{
    sqlquery q = SqlPrepareQueryCampaign(BALT_DB,
        "SELECT corruption, last_sacrifice FROM balt_corruption WHERE player_uuid = @uuid");
    SqlBindString(q, "@uuid", GetObjectUUID(oPC));
    if(!SqlStep(q)) return;

    int nCorruption    = SqlGetInt(q, 0);
    int nLastSacrifice = SqlGetInt(q, 1);
    if(nCorruption <= 0) return;

    sqlquery qNow = SqlPrepareQueryCampaign(BALT_DB, "SELECT strftime('%s','now')");
    if(!SqlStep(qNow)) return;
    int nNow        = StringToInt(SqlGetString(qNow, 0));
    int nSecondsAgo = nNow - nLastSacrifice;

    int nDecay = 0;
    if(nSecondsAgo >= 172800)     nDecay = 15; // 48h+
    else if(nSecondsAgo >= 86400) nDecay =  8; // 24h+
    else if(nSecondsAgo >= 43200) nDecay =  3; // 12h+

    if(nDecay > 0)
        BaltSetCorruption(oPC, nCorruption - nDecay);
}

void BaltLogSacrifice(object oPC, string sAltarTag, int nSacIdx)
{
    sqlquery q = SqlPrepareQueryCampaign(BALT_DB,
        "INSERT INTO balt_log (player_uuid, altar_tag, sac_idx) "
        "VALUES (@uuid, @tag, @idx)");
    SqlBindString(q, "@uuid", GetObjectUUID(oPC));
    SqlBindString(q, "@tag",  sAltarTag);
    SqlBindInt   (q, "@idx",  nSacIdx);
    SqlStep(q);
}
