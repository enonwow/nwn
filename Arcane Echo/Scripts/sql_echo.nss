// ----------------------------------------------------------------
// SQL layer for Arcane Echo
// Campaign DB: "echo"
// ----------------------------------------------------------------

void EchoCreateTables()
{
    sqlquery q;

    q = SqlPrepareQueryCampaign("echo",
        "CREATE TABLE IF NOT EXISTS echo_traces ("
        "  id            INTEGER PRIMARY KEY AUTOINCREMENT,"
        "  area_tag      TEXT    NOT NULL,"
        "  caster_uuid   TEXT    NOT NULL DEFAULT '',"
        "  caster_mask   TEXT    NOT NULL DEFAULT '',"
        "  spell_id      INTEGER NOT NULL DEFAULT 0,"
        "  spell_school  INTEGER NOT NULL DEFAULT 0,"
        "  spell_name    TEXT    NOT NULL DEFAULT '',"
        "  caster_level  INTEGER NOT NULL DEFAULT 1,"
        "  cast_at       INTEGER NOT NULL DEFAULT 0"
        ")");
    SqlStep(q);

    q = SqlPrepareQueryCampaign("echo",
        "CREATE INDEX IF NOT EXISTS idx_echo_area ON echo_traces (area_tag, cast_at DESC)");
    SqlStep(q);
}

// Insert a new trace when a spell is cast
void EchoInsertTrace(
    string sAreaTag,
    string sCasterUuid,
    string sCasterMask,
    int    nSpellId,
    int    nSpellSchool,
    string sSpellName,
    int    nCasterLevel)
{
    sqlquery q = SqlPrepareQueryCampaign("echo",
        "INSERT INTO echo_traces "
        "(area_tag, caster_uuid, caster_mask, spell_id, spell_school, spell_name, caster_level, cast_at) "
        "VALUES (@area, @cuuid, @cmask, @sid, @sschool, @sname, @clvl, strftime('%s','now'))");
    SqlBindString(q, "@area",    sAreaTag);
    SqlBindString(q, "@cuuid",   sCasterUuid);
    SqlBindString(q, "@cmask",   sCasterMask);
    SqlBindInt   (q, "@sid",     nSpellId);
    SqlBindInt   (q, "@sschool", nSpellSchool);
    SqlBindString(q, "@sname",   sSpellName);
    SqlBindInt   (q, "@clvl",    nCasterLevel);
    SqlStep(q);
}

// Delete traces older than ECHO_DECAY_HOURS from a given area
void EchoDecayArea(string sAreaTag, int nDecayHours)
{
    sqlquery q = SqlPrepareQueryCampaign("echo",
        "DELETE FROM echo_traces "
        "WHERE area_tag = @area AND cast_at < strftime('%s','now') - @decay");
    SqlBindString(q, "@area",  sAreaTag);
    SqlBindInt   (q, "@decay", nDecayHours * 3600);
    SqlStep(q);
}

// Global decay pass (called on module load)
void EchoDecayAll(int nDecayHours)
{
    sqlquery q = SqlPrepareQueryCampaign("echo",
        "DELETE FROM echo_traces WHERE cast_at < strftime('%s','now') - @decay");
    SqlBindInt(q, "@decay", nDecayHours * 3600);
    SqlStep(q);
}

// Return traces for an area as JsonArray of objects, newest first, limited
// Each row: {id, caster_uuid, caster_mask, spell_id, spell_school, spell_name, caster_level, seconds_old}
json EchoGetAreaTraces(string sAreaTag, int nLimit)
{
    json jRows = JsonArray();
    sqlquery q = SqlPrepareQueryCampaign("echo",
        "SELECT id, caster_uuid, caster_mask, spell_id, spell_school, spell_name, caster_level, "
        "       CAST(strftime('%s','now') AS INTEGER) - cast_at AS seconds_old "
        "FROM echo_traces "
        "WHERE area_tag = @area "
        "ORDER BY cast_at DESC "
        "LIMIT @lim");
    SqlBindString(q, "@area", sAreaTag);
    SqlBindInt   (q, "@lim",  nLimit);
    while(SqlStep(q))
    {
        json jRow = JsonObject();
        jRow = JsonObjectSet(jRow, "id",           JsonInt   (SqlGetInt   (q, 0)));
        jRow = JsonObjectSet(jRow, "caster_uuid",  JsonString(SqlGetString(q, 1)));
        jRow = JsonObjectSet(jRow, "caster_mask",  JsonString(SqlGetString(q, 2)));
        jRow = JsonObjectSet(jRow, "spell_id",     JsonInt   (SqlGetInt   (q, 3)));
        jRow = JsonObjectSet(jRow, "spell_school", JsonInt   (SqlGetInt   (q, 4)));
        jRow = JsonObjectSet(jRow, "spell_name",   JsonString(SqlGetString(q, 5)));
        jRow = JsonObjectSet(jRow, "caster_level", JsonInt   (SqlGetInt   (q, 6)));
        jRow = JsonObjectSet(jRow, "seconds_old",  JsonInt   (SqlGetInt   (q, 7)));
        jRows = JsonArrayInsert(jRows, jRow);
    }
    return jRows;
}

// Fetch single trace by id
json EchoGetTrace(int nId)
{
    sqlquery q = SqlPrepareQueryCampaign("echo",
        "SELECT id, caster_uuid, caster_mask, spell_id, spell_school, spell_name, caster_level, "
        "       CAST(strftime('%s','now') AS INTEGER) - cast_at AS seconds_old "
        "FROM echo_traces WHERE id = @id");
    SqlBindInt(q, "@id", nId);
    if(!SqlStep(q)) return JsonNull();
    json jRow = JsonObject();
    jRow = JsonObjectSet(jRow, "id",           JsonInt   (SqlGetInt   (q, 0)));
    jRow = JsonObjectSet(jRow, "caster_uuid",  JsonString(SqlGetString(q, 1)));
    jRow = JsonObjectSet(jRow, "caster_mask",  JsonString(SqlGetString(q, 2)));
    jRow = JsonObjectSet(jRow, "spell_id",     JsonInt   (SqlGetInt   (q, 3)));
    jRow = JsonObjectSet(jRow, "spell_school", JsonInt   (SqlGetInt   (q, 4)));
    jRow = JsonObjectSet(jRow, "spell_name",   JsonString(SqlGetString(q, 5)));
    jRow = JsonObjectSet(jRow, "caster_level", JsonInt   (SqlGetInt   (q, 6)));
    jRow = JsonObjectSet(jRow, "seconds_old",  JsonInt   (SqlGetInt   (q, 7)));
    return jRow;
}

// Delete a specific trace by id
void EchoDeleteTrace(int nId)
{
    sqlquery q = SqlPrepareQueryCampaign("echo",
        "DELETE FROM echo_traces WHERE id = @id");
    SqlBindInt(q, "@id", nId);
    SqlStep(q);
}

// Delete all traces by a specific caster in a specific area
void EchoEraseCasterTraces(string sAreaTag, string sCasterUuid)
{
    sqlquery q = SqlPrepareQueryCampaign("echo",
        "DELETE FROM echo_traces WHERE area_tag = @area AND caster_uuid = @cuuid");
    SqlBindString(q, "@area",  sAreaTag);
    SqlBindString(q, "@cuuid", sCasterUuid);
    SqlStep(q);
}

// Count how many traces a caster has in an area (for cost calculation)
int EchoCasterTraceCount(string sAreaTag, string sCasterUuid)
{
    sqlquery q = SqlPrepareQueryCampaign("echo",
        "SELECT COUNT(*) FROM echo_traces WHERE area_tag = @area AND caster_uuid = @cuuid");
    SqlBindString(q, "@area",  sAreaTag);
    SqlBindString(q, "@cuuid", sCasterUuid);
    if(SqlStep(q)) return SqlGetInt(q, 0);
    return 0;
}
