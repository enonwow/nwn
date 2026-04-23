// sm_sequences: stored on PC's .bic via SqlPrepareQueryObject(oPC, ...)
// Schema:
//   seq_idx     INTEGER NOT NULL  -- slot 0-9
//   name        TEXT DEFAULT ''
//   spells_json TEXT DEFAULT '[]'  -- JsonArray of spell objects
//   icon        TEXT DEFAULT ''    -- resref of macro thumbnail icon
//   target_mode INTEGER DEFAULT 0  -- SM_TARGET_SELF/ALLY/ENEMY/AREA
//   PRIMARY KEY (seq_idx)

void SmCreateTable(object oPC)
{
    sqlquery q = SqlPrepareQueryObject(oPC,
        "CREATE TABLE IF NOT EXISTS sm_sequences (" +
        "seq_idx INTEGER NOT NULL, " +
        "name TEXT DEFAULT '', " +
        "spells_json TEXT DEFAULT '[]', " +
        "icon TEXT DEFAULT '', " +
        "target_mode INTEGER DEFAULT 0, " +
        "PRIMARY KEY (seq_idx))");
    SqlStep(q);
    // Migrate existing tables that lack target_mode column
    int bHas = FALSE;
    sqlquery qInfo = SqlPrepareQueryObject(oPC, "PRAGMA table_info(sm_sequences)");
    while(SqlStep(qInfo)) { if(SqlGetString(qInfo, 1) == "target_mode") { bHas = TRUE; break; } }
    if(!bHas)
    {
        sqlquery qAlt = SqlPrepareQueryObject(oPC,
            "ALTER TABLE sm_sequences ADD COLUMN target_mode INTEGER DEFAULT 0");
        SqlStep(qAlt);
    }
}

void SmSave(object oPC, int nIdx, string sName, json jSpells, string sIcon, int nTargetMode)
{
    sqlquery q = SqlPrepareQueryObject(oPC,
        "INSERT OR REPLACE INTO sm_sequences (seq_idx, name, spells_json, icon, target_mode) " +
        "VALUES (@idx, @name, @spells, @icon, @mode)");
    SqlBindInt(q, "@idx", nIdx);
    SqlBindString(q, "@name", sName);
    SqlBindString(q, "@spells", JsonDump(jSpells));
    SqlBindString(q, "@icon", sIcon);
    SqlBindInt(q, "@mode", nTargetMode);
    SqlStep(q);
}

void SmDelete(object oPC, int nIdx)
{
    sqlquery q = SqlPrepareQueryObject(oPC,
        "DELETE FROM sm_sequences WHERE seq_idx = @idx");
    SqlBindInt(q, "@idx", nIdx);
    SqlStep(q);
}

json SmLoadAll(object oPC)
{
    json jResult = JsonArray();
    sqlquery q = SqlPrepareQueryObject(oPC,
        "SELECT seq_idx, name, spells_json, icon, target_mode FROM sm_sequences ORDER BY seq_idx");
    while(SqlStep(q))
    {
        json jEntry = JsonObject();
        jEntry = JsonObjectSet(jEntry, "idx",         JsonInt(SqlGetInt(q, 0)));
        jEntry = JsonObjectSet(jEntry, "name",        JsonString(SqlGetString(q, 1)));
        jEntry = JsonObjectSet(jEntry, "spells",      JsonParse(SqlGetString(q, 2)));
        jEntry = JsonObjectSet(jEntry, "icon",        JsonString(SqlGetString(q, 3)));
        jEntry = JsonObjectSet(jEntry, "target_mode", JsonInt(SqlGetInt(q, 4)));
        jResult = JsonArrayInsert(jResult, jEntry);
    }
    return jResult;
}

int SmNextFreeIdx(object oPC)
{
    int i;
    for(i = 0; i < SM_MAX_SEQ; i++)
    {
        sqlquery q = SqlPrepareQueryObject(oPC,
            "SELECT COUNT(*) FROM sm_sequences WHERE seq_idx = @idx");
        SqlBindInt(q, "@idx", i);
        if(SqlStep(q) && SqlGetInt(q, 0) == 0) return i;
    }
    return -1;
}

json SmLoadByIdx(object oPC, int nIdx)
{
    sqlquery q = SqlPrepareQueryObject(oPC,
        "SELECT name, spells_json, icon, target_mode FROM sm_sequences WHERE seq_idx = @idx");
    SqlBindInt(q, "@idx", nIdx);
    if(SqlStep(q))
    {
        json jEntry = JsonObject();
        jEntry = JsonObjectSet(jEntry, "name",        JsonString(SqlGetString(q, 0)));
        jEntry = JsonObjectSet(jEntry, "spells",      JsonParse(SqlGetString(q, 1)));
        jEntry = JsonObjectSet(jEntry, "icon",        JsonString(SqlGetString(q, 2)));
        jEntry = JsonObjectSet(jEntry, "target_mode", JsonInt(SqlGetInt(q, 3)));
        return jEntry;
    }
    return JsonNull();
}
