void InkCreateTables()
{
    sqlquery q;

    q = SqlPrepareQueryCampaign("inscription",
        "CREATE TABLE IF NOT EXISTS ink_formulas ("
        "  pc_uuid    TEXT    NOT NULL,"
        "  formula_id INTEGER NOT NULL,"
        "  learned_at INTEGER DEFAULT 0,"
        "  PRIMARY KEY (pc_uuid, formula_id)"
        ")");
    SqlStep(q);

    q = SqlPrepareQueryCampaign("inscription",
        "CREATE TABLE IF NOT EXISTS ink_craft_log ("
        "  id         INTEGER PRIMARY KEY AUTOINCREMENT,"
        "  pc_uuid    TEXT    NOT NULL,"
        "  formula_id INTEGER NOT NULL,"
        "  outcome    TEXT    DEFAULT '',"
        "  crafted_at INTEGER DEFAULT 0"
        ")");
    SqlStep(q);
}

void InkLearnFormula(object oPC, int nFormulaId)
{
    sqlquery q = SqlPrepareQueryCampaign("inscription",
        "INSERT OR IGNORE INTO ink_formulas (pc_uuid, formula_id, learned_at)"
        " VALUES (@uuid, @fid, strftime('%s','now'))");
    SqlBindString(q, "@uuid", GetObjectUUID(oPC));
    SqlBindInt   (q, "@fid",  nFormulaId);
    SqlStep(q);
}

int InkIsFormulaKnown(object oPC, int nFormulaId)
{
    sqlquery q = SqlPrepareQueryCampaign("inscription",
        "SELECT 1 FROM ink_formulas WHERE pc_uuid = @uuid AND formula_id = @fid");
    SqlBindString(q, "@uuid", GetObjectUUID(oPC));
    SqlBindInt   (q, "@fid",  nFormulaId);
    return SqlStep(q) ? 1 : 0;
}

void InkLogCraft(object oPC, int nFormulaId, string sOutcome)
{
    sqlquery q = SqlPrepareQueryCampaign("inscription",
        "INSERT INTO ink_craft_log (pc_uuid, formula_id, outcome, crafted_at)"
        " VALUES (@uuid, @fid, @out, strftime('%s','now'))");
    SqlBindString(q, "@uuid", GetObjectUUID(oPC));
    SqlBindInt   (q, "@fid",  nFormulaId);
    SqlBindString(q, "@out",  sOutcome);
    SqlStep(q);

    // Trim to last 15 entries per player
    q = SqlPrepareQueryCampaign("inscription",
        "DELETE FROM ink_craft_log"
        " WHERE pc_uuid = @uuid AND id NOT IN ("
        "   SELECT id FROM ink_craft_log"
        "   WHERE pc_uuid = @uuid ORDER BY id DESC LIMIT 15"
        " )");
    SqlBindString(q, "@uuid", GetObjectUUID(oPC));
    SqlStep(q);
}

json InkGetHistory(object oPC)
{
    json jRows = JsonArray();
    sqlquery q = SqlPrepareQueryCampaign("inscription",
        "SELECT formula_id, outcome, crafted_at"
        " FROM ink_craft_log WHERE pc_uuid = @uuid"
        " ORDER BY id DESC LIMIT 15");
    SqlBindString(q, "@uuid", GetObjectUUID(oPC));
    while(SqlStep(q))
    {
        json jRow = JsonObject();
        jRow = JsonObjectSet(jRow, "formula_id", JsonInt   (SqlGetInt   (q, 0)));
        jRow = JsonObjectSet(jRow, "outcome",    JsonString(SqlGetString(q, 1)));
        jRow = JsonObjectSet(jRow, "crafted_at", JsonInt   (SqlGetInt   (q, 2)));
        jRows = JsonArrayInsert(jRows, jRow);
    }
    return jRows;
}

string InkFormatDate(int nUnix)
{
    sqlquery q = SqlPrepareQueryCampaign("inscription",
        "SELECT strftime('%d.%m', @ts, 'unixepoch')");
    SqlBindInt(q, "@ts", nUnix);
    if(SqlStep(q)) return SqlGetString(q, 0);
    return "--";
}
