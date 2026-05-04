// Pantheon - persistence (campaign DB "pan")

const string PAN_DB = "pan";

void PanCreateTables()
{
    sqlquery q;

    q = SqlPrepareQueryCampaign(PAN_DB,
        "CREATE TABLE IF NOT EXISTS pan_devotion ("
        + "uuid TEXT PRIMARY KEY, "
        + "char_name TEXT DEFAULT '', "
        + "deity_id INTEGER DEFAULT -1, "
        + "favor INTEGER DEFAULT 0, "
        + "last_prayed_at INTEGER DEFAULT 0, "
        + "miracles_cast INTEGER DEFAULT 0, "
        + "created_at INTEGER DEFAULT 0)");
    SqlStep(q);

    q = SqlPrepareQueryCampaign(PAN_DB,
        "CREATE TABLE IF NOT EXISTS pan_cooldowns ("
        + "uuid TEXT, "
        + "miracle_id INTEGER, "
        + "ready_at INTEGER, "
        + "PRIMARY KEY (uuid, miracle_id))");
    SqlStep(q);
}

void PanEnsureRow(object oPC)
{
    sqlquery q = SqlPrepareQueryCampaign(PAN_DB,
        "INSERT OR IGNORE INTO pan_devotion (uuid, char_name, created_at) "
        + "VALUES (@u, @n, strftime('%s','now'))");
    SqlBindString(q, "@u", GetObjectUUID(oPC));
    SqlBindString(q, "@n", GetName(oPC));
    SqlStep(q);
}

int PanGetNowSeconds()
{
    sqlquery q = SqlPrepareQueryCampaign(PAN_DB,
        "SELECT CAST(strftime('%s','now') AS INTEGER)");
    if(SqlStep(q)) return SqlGetInt(q, 0);
    return 0;
}

int PanGetDeity(string sUuid)
{
    sqlquery q = SqlPrepareQueryCampaign(PAN_DB,
        "SELECT deity_id FROM pan_devotion WHERE uuid = @u");
    SqlBindString(q, "@u", sUuid);
    if(SqlStep(q)) return SqlGetInt(q, 0);
    return -1;
}

int PanGetFavor(string sUuid)
{
    sqlquery q = SqlPrepareQueryCampaign(PAN_DB,
        "SELECT favor FROM pan_devotion WHERE uuid = @u");
    SqlBindString(q, "@u", sUuid);
    if(SqlStep(q)) return SqlGetInt(q, 0);
    return 0;
}

int PanGetLastPrayedAt(string sUuid)
{
    sqlquery q = SqlPrepareQueryCampaign(PAN_DB,
        "SELECT last_prayed_at FROM pan_devotion WHERE uuid = @u");
    SqlBindString(q, "@u", sUuid);
    if(SqlStep(q)) return SqlGetInt(q, 0);
    return 0;
}

void PanSetDeity(string sUuid, int nDeity)
{
    sqlquery q = SqlPrepareQueryCampaign(PAN_DB,
        "UPDATE pan_devotion SET deity_id = @d WHERE uuid = @u");
    SqlBindInt   (q, "@d", nDeity);
    SqlBindString(q, "@u", sUuid);
    SqlStep(q);
}

void PanSetFavor(string sUuid, int nFavor)
{
    sqlquery q = SqlPrepareQueryCampaign(PAN_DB,
        "UPDATE pan_devotion SET favor = @f WHERE uuid = @u");
    SqlBindInt   (q, "@f", nFavor);
    SqlBindString(q, "@u", sUuid);
    SqlStep(q);
}

void PanMarkPrayed(string sUuid)
{
    sqlquery q = SqlPrepareQueryCampaign(PAN_DB,
        "UPDATE pan_devotion SET last_prayed_at = strftime('%s','now') WHERE uuid = @u");
    SqlBindString(q, "@u", sUuid);
    SqlStep(q);
}

void PanIncMiraclesCast(string sUuid)
{
    sqlquery q = SqlPrepareQueryCampaign(PAN_DB,
        "UPDATE pan_devotion SET miracles_cast = miracles_cast + 1 WHERE uuid = @u");
    SqlBindString(q, "@u", sUuid);
    SqlStep(q);
}

int PanGetCooldownReadyAt(string sUuid, int nMir)
{
    sqlquery q = SqlPrepareQueryCampaign(PAN_DB,
        "SELECT ready_at FROM pan_cooldowns WHERE uuid = @u AND miracle_id = @m");
    SqlBindString(q, "@u", sUuid);
    SqlBindInt   (q, "@m", nMir);
    if(SqlStep(q)) return SqlGetInt(q, 0);
    return 0;
}

void PanSetCooldown(string sUuid, int nMir, int nReadyAt)
{
    sqlquery q = SqlPrepareQueryCampaign(PAN_DB,
        "INSERT OR REPLACE INTO pan_cooldowns (uuid, miracle_id, ready_at) "
        + "VALUES (@u, @m, @r)");
    SqlBindString(q, "@u", sUuid);
    SqlBindInt   (q, "@m", nMir);
    SqlBindInt   (q, "@r", nReadyAt);
    SqlStep(q);
}
