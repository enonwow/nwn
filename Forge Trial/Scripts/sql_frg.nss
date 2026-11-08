// SQL schema and queries for the Forge Trial module.
// Uses SqlPrepareQueryCampaign("forge") for persistent item enhancement data.

void FrgCreateTables()
{
    sqlquery q = SqlPrepareQueryCampaign("forge",
        "CREATE TABLE IF NOT EXISTS frg_items ("
        "  item_uuid    TEXT PRIMARY KEY,"
        "  owner_uuid   TEXT NOT NULL DEFAULT '',"
        "  forge_level  INTEGER NOT NULL DEFAULT 0,"
        "  total_strikes INTEGER NOT NULL DEFAULT 0,"
        "  last_forged  INTEGER NOT NULL DEFAULT 0"
        ")");
    SqlStep(q);
}

int FrgDBGetLevel(string sItemUuid)
{
    sqlquery q = SqlPrepareQueryCampaign("forge",
        "SELECT forge_level FROM frg_items WHERE item_uuid = @uuid");
    SqlBindString(q, "@uuid", sItemUuid);
    if(SqlStep(q)) return SqlGetInt(q, 0);
    return 0;
}

int FrgDBGetLastForged(string sItemUuid)
{
    sqlquery q = SqlPrepareQueryCampaign("forge",
        "SELECT last_forged FROM frg_items WHERE item_uuid = @uuid");
    SqlBindString(q, "@uuid", sItemUuid);
    if(SqlStep(q)) return SqlGetInt(q, 0);
    return 0;
}

int FrgDBGetTotalStrikes(string sItemUuid)
{
    sqlquery q = SqlPrepareQueryCampaign("forge",
        "SELECT total_strikes FROM frg_items WHERE item_uuid = @uuid");
    SqlBindString(q, "@uuid", sItemUuid);
    if(SqlStep(q)) return SqlGetInt(q, 0);
    return 0;
}

void FrgDBUpsertItem(string sItemUuid, string sOwnerUuid, int nLevel, int nStrikeDelta)
{
    sqlquery q = SqlPrepareQueryCampaign("forge",
        "INSERT INTO frg_items (item_uuid, owner_uuid, forge_level, total_strikes, last_forged)"
        "  VALUES (@uuid, @owner, @lvl, @strikes, strftime('%s','now'))"
        "  ON CONFLICT(item_uuid) DO UPDATE SET"
        "    owner_uuid   = excluded.owner_uuid,"
        "    forge_level  = excluded.forge_level,"
        "    total_strikes = total_strikes + @delta,"
        "    last_forged  = strftime('%s','now')");
    SqlBindString(q, "@uuid",    sItemUuid);
    SqlBindString(q, "@owner",   sOwnerUuid);
    SqlBindInt(q,    "@lvl",     nLevel);
    SqlBindInt(q,    "@strikes", nStrikeDelta);
    SqlBindInt(q,    "@delta",   nStrikeDelta);
    SqlStep(q);
}

// Returns TRUE if the forge cooldown for this item has passed.
int FrgDBCanForge(string sItemUuid)
{
    int nLast = FrgDBGetLastForged(sItemUuid);
    if(nLast == 0) return TRUE;

    sqlquery q = SqlPrepareQueryCampaign("forge",
        "SELECT (strftime('%s','now') - @last) >= 3600");
    SqlBindInt(q, "@last", nLast);
    if(SqlStep(q)) return SqlGetInt(q, 0);
    return FALSE;
}

// Returns seconds remaining on the cooldown (0 if none).
int FrgDBCooldownRemaining(string sItemUuid)
{
    int nLast = FrgDBGetLastForged(sItemUuid);
    if(nLast == 0) return 0;

    sqlquery q = SqlPrepareQueryCampaign("forge",
        "SELECT MAX(0, 3600 - (strftime('%s','now') - @last))");
    SqlBindInt(q, "@last", nLast);
    if(SqlStep(q)) return SqlGetInt(q, 0);
    return 0;
}
