// sql_alch.nss
// SQLite schema and CRUD for per-character recipe knowledge.
// Uses SqlPrepareQueryObject (per-PC) for recipe data.
// Campaign DB stores nothing; all data lives on the PC object
// so it travels with the character across server restarts.

// ----------------------------------------------------------------
// Schema
// ----------------------------------------------------------------

void AlchInitTables(object oPC)
{
    // Idempotent: safe to call on every login
    sqlquery q = SqlPrepareQueryObject(oPC,
        "CREATE TABLE IF NOT EXISTS alch_recipes ("
        "  recipe_id   INTEGER NOT NULL,"
        "  unlocked_at INTEGER NOT NULL DEFAULT 0,"
        "  PRIMARY KEY (recipe_id)"
        ");"
    );
    SqlStep(q);
}

// ----------------------------------------------------------------
// Recipe knowledge
// ----------------------------------------------------------------

int AlchHasRecipe(object oPC, int nRecipeId)
{
    sqlquery q = SqlPrepareQueryObject(oPC,
        "SELECT 1 FROM alch_recipes WHERE recipe_id = @id;"
    );
    SqlBindInt(q, "@id", nRecipeId);
    return SqlStep(q) ? 1 : 0;
}

void AlchUnlockRecipe(object oPC, int nRecipeId)
{
    sqlquery q = SqlPrepareQueryObject(oPC,
        "INSERT OR IGNORE INTO alch_recipes (recipe_id, unlocked_at)"
        " VALUES (@id, @now);"
    );
    SqlBindInt(q, "@id",  nRecipeId);
    SqlBindInt(q, "@now", GetCalendarDay() * 86400 + GetTimeHour() * 3600);
    SqlStep(q);
}

// Returns a JsonArray of integer recipe IDs the PC knows
json AlchGetUnlockedRecipes(object oPC)
{
    sqlquery q = SqlPrepareQueryObject(oPC,
        "SELECT recipe_id FROM alch_recipes ORDER BY recipe_id;"
    );
    json jResult = JsonArray();
    while(SqlStep(q))
        jResult = JsonArrayInsert(jResult, JsonInt(SqlGetInt(q, 0)));
    return jResult;
}

// Grants the two starter recipes (0 = Nalewka Gojąca, 1 = Odwar Mrocznego Wzroku)
void AlchGrantStarterRecipes(object oPC)
{
    AlchUnlockRecipe(oPC, 0);
    AlchUnlockRecipe(oPC, 1);
}
