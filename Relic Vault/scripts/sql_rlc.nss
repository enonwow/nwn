const string RLC_DB              = "rlc";
const int    RLC_CURSE_MAX       = 5;
const int    RLC_CURSE_TICK_SECS = 600; // 10 real minutes between curse escalations

void RlcCreateTables()
{
    sqlquery q = SqlPrepareQueryCampaign(RLC_DB,
        "CREATE TABLE IF NOT EXISTS rlc_attunements ("
        "char_uuid TEXT PRIMARY KEY, "
        "char_name TEXT NOT NULL DEFAULT '', "
        "relic_id  INTEGER NOT NULL, "
        "curse_level INTEGER NOT NULL DEFAULT 0, "
        "attuned_at  INTEGER NOT NULL DEFAULT 0, "
        "last_tick   INTEGER NOT NULL DEFAULT 0)");
    SqlStep(q);
}

// Returns the relic_id the PC is currently attuned to, or 0 if none.
int RlcGetAttuned(object oPC)
{
    sqlquery q = SqlPrepareQueryCampaign(RLC_DB,
        "SELECT relic_id FROM rlc_attunements WHERE char_uuid = @uuid");
    SqlBindString(q, "@uuid", GetObjectUUID(oPC));
    if(SqlStep(q)) return SqlGetInt(q, 0);
    return 0;
}

int RlcGetCurseLevel(object oPC)
{
    sqlquery q = SqlPrepareQueryCampaign(RLC_DB,
        "SELECT curse_level FROM rlc_attunements WHERE char_uuid = @uuid");
    SqlBindString(q, "@uuid", GetObjectUUID(oPC));
    if(SqlStep(q)) return SqlGetInt(q, 0);
    return 0;
}

// Returns the character name of whoever holds this relic, "" if unoccupied.
string RlcGetHolder(int nRelicId)
{
    sqlquery q = SqlPrepareQueryCampaign(RLC_DB,
        "SELECT char_name FROM rlc_attunements WHERE relic_id = @rid");
    SqlBindInt(q, "@rid", nRelicId);
    if(SqlStep(q)) return SqlGetString(q, 0);
    return "";
}

void RlcAttuneRelic(object oPC, int nRelicId)
{
    sqlquery q = SqlPrepareQueryCampaign(RLC_DB,
        "INSERT INTO rlc_attunements "
        "(char_uuid, char_name, relic_id, curse_level, attuned_at, last_tick) "
        "VALUES (@uuid, @name, @rid, 0, strftime('%s','now'), strftime('%s','now'))");
    SqlBindString(q, "@uuid", GetObjectUUID(oPC));
    SqlBindString(q, "@name", GetName(oPC));
    SqlBindInt   (q, "@rid",  nRelicId);
    SqlStep(q);
}

void RlcReleaseRelic(object oPC)
{
    sqlquery q = SqlPrepareQueryCampaign(RLC_DB,
        "DELETE FROM rlc_attunements WHERE char_uuid = @uuid");
    SqlBindString(q, "@uuid", GetObjectUUID(oPC));
    SqlStep(q);
}

// Increments curse by 1 (capped at RLC_CURSE_MAX) and resets last_tick.
// Returns the new curse level, or -1 if the PC has no attunement.
int RlcTickCurse(object oPC)
{
    sqlquery qGet = SqlPrepareQueryCampaign(RLC_DB,
        "SELECT curse_level FROM rlc_attunements WHERE char_uuid = @uuid");
    SqlBindString(qGet, "@uuid", GetObjectUUID(oPC));
    if(!SqlStep(qGet)) return -1;

    int nCurrent = SqlGetInt(qGet, 0);
    int nNew     = (nCurrent < RLC_CURSE_MAX) ? nCurrent + 1 : RLC_CURSE_MAX;

    sqlquery qUp = SqlPrepareQueryCampaign(RLC_DB,
        "UPDATE rlc_attunements "
        "SET curse_level = @lvl, last_tick = strftime('%s','now') "
        "WHERE char_uuid = @uuid");
    SqlBindInt   (qUp, "@lvl",  nNew);
    SqlBindString(qUp, "@uuid", GetObjectUUID(oPC));
    SqlStep(qUp);
    return nNew;
}

// Reduces curse by 1 (min 0). Returns new level, or -1 if not attuned.
int RlcPurifyDB(object oPC)
{
    sqlquery qGet = SqlPrepareQueryCampaign(RLC_DB,
        "SELECT curse_level FROM rlc_attunements WHERE char_uuid = @uuid");
    SqlBindString(qGet, "@uuid", GetObjectUUID(oPC));
    if(!SqlStep(qGet)) return -1;

    int nCurrent = SqlGetInt(qGet, 0);
    int nNew     = (nCurrent > 0) ? nCurrent - 1 : 0;

    sqlquery qUp = SqlPrepareQueryCampaign(RLC_DB,
        "UPDATE rlc_attunements SET curse_level = @lvl WHERE char_uuid = @uuid");
    SqlBindInt   (qUp, "@lvl",  nNew);
    SqlBindString(qUp, "@uuid", GetObjectUUID(oPC));
    SqlStep(qUp);
    return nNew;
}

// Returns TRUE when enough real time has passed and the curse is not yet maxed.
int RlcNeedsCurseTick(object oPC)
{
    sqlquery q = SqlPrepareQueryCampaign(RLC_DB,
        "SELECT (strftime('%s','now') - last_tick) >= @secs AND curse_level < @max "
        "FROM rlc_attunements WHERE char_uuid = @uuid");
    SqlBindInt   (q, "@secs", RLC_CURSE_TICK_SECS);
    SqlBindInt   (q, "@max",  RLC_CURSE_MAX);
    SqlBindString(q, "@uuid", GetObjectUUID(oPC));
    if(SqlStep(q)) return SqlGetInt(q, 0);
    return FALSE;
}
