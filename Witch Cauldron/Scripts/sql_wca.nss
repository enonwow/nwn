// sql_wca.nss — Witch Cauldron: SQLite schema and query helpers

void WcaCreateTables()
{
    sqlquery q;

    q = SqlPrepareQueryCampaign("witch_cauldron",
        "CREATE TABLE IF NOT EXISTS wca_known_recipes ("
        "  uuid      TEXT    NOT NULL,"
        "  recipe_id INTEGER NOT NULL,"
        "  learned_at INTEGER DEFAULT (strftime('%s','now')),"
        "  PRIMARY KEY (uuid, recipe_id)"
        ")");
    SqlStep(q);

    q = SqlPrepareQueryCampaign("witch_cauldron",
        "CREATE TABLE IF NOT EXISTS wca_brew_log ("
        "  id        INTEGER PRIMARY KEY AUTOINCREMENT,"
        "  uuid      TEXT    NOT NULL,"
        "  recipe_id INTEGER NOT NULL,"
        "  success   INTEGER DEFAULT 1,"
        "  brewed_at INTEGER DEFAULT (strftime('%s','now'))"
        ")");
    SqlStep(q);
}

int WcaHasRecipe(object oPC, int nRecipeId)
{
    sqlquery q = SqlPrepareQueryCampaign("witch_cauldron",
        "SELECT 1 FROM wca_known_recipes WHERE uuid = @uuid AND recipe_id = @id");
    SqlBindString(q, "@uuid", GetObjectUUID(oPC));
    SqlBindInt(q, "@id", nRecipeId);
    return SqlStep(q);
}

void WcaLearnRecipeDB(object oPC, int nRecipeId)
{
    sqlquery q = SqlPrepareQueryCampaign("witch_cauldron",
        "INSERT OR IGNORE INTO wca_known_recipes (uuid, recipe_id) VALUES (@uuid, @id)");
    SqlBindString(q, "@uuid", GetObjectUUID(oPC));
    SqlBindInt(q, "@id", nRecipeId);
    SqlStep(q);
}

// Returns JsonArray of known recipe IDs (as JsonInt) for this PC, ordered by recipe_id.
json WcaGetKnownRecipes(object oPC)
{
    sqlquery q = SqlPrepareQueryCampaign("witch_cauldron",
        "SELECT recipe_id FROM wca_known_recipes WHERE uuid = @uuid ORDER BY recipe_id");
    SqlBindString(q, "@uuid", GetObjectUUID(oPC));
    json jResult = JsonArray();
    while(SqlStep(q))
        jResult = JsonArrayInsert(jResult, JsonInt(SqlGetInt(q, 0)));
    return jResult;
}

int WcaGetKnownRecipeCount(object oPC)
{
    sqlquery q = SqlPrepareQueryCampaign("witch_cauldron",
        "SELECT COUNT(*) FROM wca_known_recipes WHERE uuid = @uuid");
    SqlBindString(q, "@uuid", GetObjectUUID(oPC));
    if(SqlStep(q)) return SqlGetInt(q, 0);
    return 0;
}

void WcaLogBrew(object oPC, int nRecipeId, int bSuccess)
{
    sqlquery q = SqlPrepareQueryCampaign("witch_cauldron",
        "INSERT INTO wca_brew_log (uuid, recipe_id, success) VALUES (@uuid, @id, @ok)");
    SqlBindString(q, "@uuid", GetObjectUUID(oPC));
    SqlBindInt(q, "@id", nRecipeId);
    SqlBindInt(q, "@ok", bSuccess);
    SqlStep(q);
}
