#include "lib_alch_def"

// ----------------------------------------------------------------
// Schema
// Per-PC known recipes stored in the campaign database "alchemy".
// ----------------------------------------------------------------

void AlchCreateTables()
{
    sqlquery q = SqlPrepareQueryCampaign("alchemy",
        "CREATE TABLE IF NOT EXISTS alch_known ("
        "  pc_uuid    TEXT    NOT NULL,"
        "  recipe_id  INTEGER NOT NULL,"
        "  learned_at INTEGER DEFAULT 0,"
        "  brew_count INTEGER DEFAULT 0,"
        "  PRIMARY KEY (pc_uuid, recipe_id)"
        ")");
    SqlStep(q);
}

// ----------------------------------------------------------------
// Recipe knowledge
// ----------------------------------------------------------------

int AlchIsRecipeKnown(object oPC, int nRecipeId)
{
    sqlquery q = SqlPrepareQueryCampaign("alchemy",
        "SELECT 1 FROM alch_known WHERE pc_uuid = @uuid AND recipe_id = @rid");
    SqlBindString(q, "@uuid", GetObjectUUID(oPC));
    SqlBindInt   (q, "@rid",  nRecipeId);
    return SqlStep(q);
}

void AlchLearnRecipe(object oPC, int nRecipeId)
{
    sqlquery q = SqlPrepareQueryCampaign("alchemy",
        "INSERT OR IGNORE INTO alch_known (pc_uuid, recipe_id, learned_at) "
        "VALUES (@uuid, @rid, strftime('%s','now'))");
    SqlBindString(q, "@uuid", GetObjectUUID(oPC));
    SqlBindInt   (q, "@rid",  nRecipeId);
    SqlStep(q);
}

void AlchIncrementBrewCount(object oPC, int nRecipeId)
{
    sqlquery q = SqlPrepareQueryCampaign("alchemy",
        "UPDATE alch_known SET brew_count = brew_count + 1 "
        "WHERE pc_uuid = @uuid AND recipe_id = @rid");
    SqlBindString(q, "@uuid", GetObjectUUID(oPC));
    SqlBindInt   (q, "@rid",  nRecipeId);
    SqlStep(q);
}

int AlchGetBrewCount(object oPC, int nRecipeId)
{
    sqlquery q = SqlPrepareQueryCampaign("alchemy",
        "SELECT brew_count FROM alch_known WHERE pc_uuid = @uuid AND recipe_id = @rid");
    SqlBindString(q, "@uuid", GetObjectUUID(oPC));
    SqlBindInt   (q, "@rid",  nRecipeId);
    if(SqlStep(q)) return SqlGetInt(q, 0);
    return 0;
}

int AlchGetKnownCount(object oPC)
{
    sqlquery q = SqlPrepareQueryCampaign("alchemy",
        "SELECT COUNT(*) FROM alch_known WHERE pc_uuid = @uuid");
    SqlBindString(q, "@uuid", GetObjectUUID(oPC));
    if(SqlStep(q)) return SqlGetInt(q, 0);
    return 0;
}

// Returns JsonArray of known recipe_ids for this PC.
json AlchGetKnownRecipeIds(object oPC)
{
    json jIds = JsonArray();
    sqlquery q = SqlPrepareQueryCampaign("alchemy",
        "SELECT recipe_id FROM alch_known WHERE pc_uuid = @uuid ORDER BY recipe_id ASC");
    SqlBindString(q, "@uuid", GetObjectUUID(oPC));
    while(SqlStep(q))
        jIds = JsonArrayInsert(jIds, JsonInt(SqlGetInt(q, 0)));
    return jIds;
}
