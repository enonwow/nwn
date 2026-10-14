// Idempotent schema and CRUD for the Forbidden Grimoire.
// Campaign DB name: "grimoire"

void GrimCreateTables()
{
    sqlquery q = SqlPrepareQueryCampaign("grimoire",
        "CREATE TABLE IF NOT EXISTS grim_known ("
        "  char_uuid  TEXT NOT NULL,"
        "  recipe_id  INTEGER NOT NULL,"
        "  uses       INTEGER DEFAULT 0,"
        "  mastered   INTEGER DEFAULT 0,"
        "  last_free  INTEGER DEFAULT 0,"
        "  PRIMARY KEY (char_uuid, recipe_id)"
        ")");
    SqlStep(q);
}

int GrimGetRecipeUses(object oPC, int nRecipeId)
{
    sqlquery q = SqlPrepareQueryCampaign("grimoire",
        "SELECT uses FROM grim_known WHERE char_uuid = @uuid AND recipe_id = @rid");
    SqlBindString(q, "@uuid", GetObjectUUID(oPC));
    SqlBindInt   (q, "@rid",  nRecipeId);
    if(SqlStep(q)) return SqlGetInt(q, 0);
    return 0;
}

int GrimGetRecipeMastered(object oPC, int nRecipeId)
{
    sqlquery q = SqlPrepareQueryCampaign("grimoire",
        "SELECT mastered FROM grim_known WHERE char_uuid = @uuid AND recipe_id = @rid");
    SqlBindString(q, "@uuid", GetObjectUUID(oPC));
    SqlBindInt   (q, "@rid",  nRecipeId);
    if(SqlStep(q)) return SqlGetInt(q, 0);
    return 0;
}

int GrimGetLastFreeCast(object oPC, int nRecipeId)
{
    sqlquery q = SqlPrepareQueryCampaign("grimoire",
        "SELECT last_free FROM grim_known WHERE char_uuid = @uuid AND recipe_id = @rid");
    SqlBindString(q, "@uuid", GetObjectUUID(oPC));
    SqlBindInt   (q, "@rid",  nRecipeId);
    if(SqlStep(q)) return SqlGetInt(q, 0);
    return 0;
}

int GrimGetCurrentTime()
{
    sqlquery q = SqlPrepareQueryCampaign("grimoire",
        "SELECT CAST(strftime('%s','now') AS INTEGER)");
    if(SqlStep(q)) return SqlGetInt(q, 0);
    return 0;
}

// Records a successful research; returns new use count.
int GrimRecordDiscovery(object oPC, int nRecipeId, int nMasteryThreshold)
{
    sqlquery q = SqlPrepareQueryCampaign("grimoire",
        "INSERT INTO grim_known (char_uuid, recipe_id, uses) VALUES (@uuid, @rid, 1)"
        " ON CONFLICT(char_uuid, recipe_id) DO UPDATE SET uses = uses + 1");
    SqlBindString(q, "@uuid", GetObjectUUID(oPC));
    SqlBindInt   (q, "@rid",  nRecipeId);
    SqlStep(q);

    int nUses = GrimGetRecipeUses(oPC, nRecipeId);
    if(nUses >= nMasteryThreshold && !GrimGetRecipeMastered(oPC, nRecipeId))
    {
        sqlquery qm = SqlPrepareQueryCampaign("grimoire",
            "UPDATE grim_known SET mastered = 1 WHERE char_uuid = @uuid AND recipe_id = @rid");
        SqlBindString(qm, "@uuid", GetObjectUUID(oPC));
        SqlBindInt   (qm, "@rid",  nRecipeId);
        SqlStep(qm);
    }
    return nUses;
}

void GrimSetLastFreeCast(object oPC, int nRecipeId)
{
    sqlquery q = SqlPrepareQueryCampaign("grimoire",
        "UPDATE grim_known SET last_free = CAST(strftime('%s','now') AS INTEGER)"
        " WHERE char_uuid = @uuid AND recipe_id = @rid");
    SqlBindString(q, "@uuid", GetObjectUUID(oPC));
    SqlBindInt   (q, "@rid",  nRecipeId);
    SqlStep(q);
}

// Returns JsonArray of known recipes: [{recipe_id, uses, mastered, last_free}, ...]
json GrimGetKnownRecipes(object oPC)
{
    json jRows = JsonArray();
    sqlquery q = SqlPrepareQueryCampaign("grimoire",
        "SELECT recipe_id, uses, mastered, last_free FROM grim_known"
        " WHERE char_uuid = @uuid ORDER BY recipe_id");
    SqlBindString(q, "@uuid", GetObjectUUID(oPC));
    while(SqlStep(q))
    {
        json jRow = JsonObject();
        jRow = JsonObjectSet(jRow, "recipe_id", JsonInt(SqlGetInt(q, 0)));
        jRow = JsonObjectSet(jRow, "uses",      JsonInt(SqlGetInt(q, 1)));
        jRow = JsonObjectSet(jRow, "mastered",  JsonInt(SqlGetInt(q, 2)));
        jRow = JsonObjectSet(jRow, "last_free", JsonInt(SqlGetInt(q, 3)));
        jRows = JsonArrayInsert(jRows, jRow);
    }
    return jRows;
}
