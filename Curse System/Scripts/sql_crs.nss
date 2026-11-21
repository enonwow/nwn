// Persistent curse storage.
// One row per (char_uuid, curse_id) pair; unique constraint prevents duplicates.
// tick_count drives stage progression: after CRS_TICKS_PER_STAGE ticks stage++, max 3.

void CrsCreateTables()
{
    sqlquery sql = SqlPrepareQueryCampaign("curses",
        "CREATE TABLE IF NOT EXISTS crs_active ("
        "  id         INTEGER PRIMARY KEY AUTOINCREMENT,"
        "  char_uuid  TEXT    NOT NULL,"
        "  curse_id   INTEGER NOT NULL,"
        "  stage      INTEGER NOT NULL DEFAULT 1,"
        "  tick_count INTEGER NOT NULL DEFAULT 0,"
        "  applied_at INTEGER NOT NULL,"
        "  UNIQUE(char_uuid, curse_id)"
        ");"
    );
    SqlStep(sql);
}

// Returns TRUE if oPC already has nCurseId active.
int CrsHasCurse(object oPC, int nCurseId)
{
    string sUUID = GetObjectUUID(oPC);
    sqlquery sql = SqlPrepareQueryCampaign("curses",
        "SELECT id FROM crs_active WHERE char_uuid=@uuid AND curse_id=@cid LIMIT 1;"
    );
    SqlBindString(sql, "@uuid", sUUID);
    SqlBindInt   (sql, "@cid",  nCurseId);
    return SqlStep(sql);
}

// Adds the curse at stage 1. If already present, does nothing.
void CrsAddCurse(object oPC, int nCurseId)
{
    string sUUID = GetObjectUUID(oPC);
    int nNow     = GetCalendarYear() * 525600
                   + GetCalendarMonth() * 43800
                   + GetCalendarDay()   * 1440
                   + GetTimeHour()      * 60
                   + GetTimeMinute();
    sqlquery sql = SqlPrepareQueryCampaign("curses",
        "INSERT OR IGNORE INTO crs_active (char_uuid, curse_id, stage, tick_count, applied_at)"
        " VALUES (@uuid, @cid, 1, 0, @ts);"
    );
    SqlBindString(sql, "@uuid", sUUID);
    SqlBindInt   (sql, "@cid",  nCurseId);
    SqlBindInt   (sql, "@ts",   nNow);
    SqlStep(sql);
}

// Removes the curse record for oPC.
void CrsDeleteCurse(object oPC, int nCurseId)
{
    sqlquery sql = SqlPrepareQueryCampaign("curses",
        "DELETE FROM crs_active WHERE char_uuid=@uuid AND curse_id=@cid;"
    );
    SqlBindString(sql, "@uuid", GetObjectUUID(oPC));
    SqlBindInt   (sql, "@cid",  nCurseId);
    SqlStep(sql);
}

// Returns json array of {curse_id, stage, tick_count}, sorted by curse_id.
json CrsGetAllCurses(object oPC)
{
    sqlquery sql = SqlPrepareQueryCampaign("curses",
        "SELECT curse_id, stage, tick_count FROM crs_active"
        " WHERE char_uuid=@uuid ORDER BY curse_id ASC;"
    );
    SqlBindString(sql, "@uuid", GetObjectUUID(oPC));

    json jResult = JsonArray();
    while(SqlStep(sql))
    {
        json jRow = JsonObject();
        jRow = JsonObjectSet(jRow, "curse_id",   JsonInt(SqlGetInt(sql, 0)));
        jRow = JsonObjectSet(jRow, "stage",      JsonInt(SqlGetInt(sql, 1)));
        jRow = JsonObjectSet(jRow, "tick_count", JsonInt(SqlGetInt(sql, 2)));
        jResult = JsonArrayInsert(jResult, jRow);
    }
    return jResult;
}

// Returns {curse_id, stage, tick_count} for a specific curse, or JSON_NULL if absent.
json CrsGetCurse(object oPC, int nCurseId)
{
    sqlquery sql = SqlPrepareQueryCampaign("curses",
        "SELECT curse_id, stage, tick_count FROM crs_active"
        " WHERE char_uuid=@uuid AND curse_id=@cid LIMIT 1;"
    );
    SqlBindString(sql, "@uuid", GetObjectUUID(oPC));
    SqlBindInt   (sql, "@cid",  nCurseId);

    if(!SqlStep(sql)) return JsonNull();

    json jRow = JsonObject();
    jRow = JsonObjectSet(jRow, "curse_id",   JsonInt(SqlGetInt(sql, 0)));
    jRow = JsonObjectSet(jRow, "stage",      JsonInt(SqlGetInt(sql, 1)));
    jRow = JsonObjectSet(jRow, "tick_count", JsonInt(SqlGetInt(sql, 2)));
    return jRow;
}

// Increments tick_count for all of oPC's curses.
// Returns json array of {curse_id, old_stage, new_stage} for curses that progressed.
json CrsTickAllCurses(object oPC, int nTicksPerStage)
{
    json jProgressed = JsonArray();
    json jAll = CrsGetAllCurses(oPC);
    int nCount = JsonGetLength(jAll);
    int i;
    for(i = 0; i < nCount; i++)
    {
        json jRow      = JsonArrayGet(jAll, i);
        int nCurseId   = JsonGetInt(JsonObjectGet(jRow, "curse_id"));
        int nStage     = JsonGetInt(JsonObjectGet(jRow, "stage"));
        int nTicks     = JsonGetInt(JsonObjectGet(jRow, "tick_count"));

        if(nStage >= 3)
        {
            // Already at max stage; keep ticking so UI still fires, but no DB write needed
            continue;
        }

        int nNewTicks = nTicks + 1;
        int nNewStage = nStage;
        if(nNewTicks >= nTicksPerStage)
        {
            nNewTicks = 0;
            nNewStage = nStage + 1;
            if(nNewStage > 3) nNewStage = 3;
        }

        sqlquery sql = SqlPrepareQueryCampaign("curses",
            "UPDATE crs_active SET tick_count=@tc, stage=@st"
            " WHERE char_uuid=@uuid AND curse_id=@cid;"
        );
        SqlBindInt   (sql, "@tc",   nNewTicks);
        SqlBindInt   (sql, "@st",   nNewStage);
        SqlBindString(sql, "@uuid", GetObjectUUID(oPC));
        SqlBindInt   (sql, "@cid",  nCurseId);
        SqlStep(sql);

        if(nNewStage != nStage)
        {
            json jProg = JsonObject();
            jProg = JsonObjectSet(jProg, "curse_id",  JsonInt(nCurseId));
            jProg = JsonObjectSet(jProg, "old_stage", JsonInt(nStage));
            jProg = JsonObjectSet(jProg, "new_stage", JsonInt(nNewStage));
            jProgressed = JsonArrayInsert(jProgressed, jProg);
        }
    }
    return jProgressed;
}
