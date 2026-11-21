// sql_syn.nss — Szynkarz DB schema and queries
// Campaign DB name: "szynkarz"

void SynCreateTables()
{
    sqlquery q = SqlPrepareQueryCampaign("szynkarz",
        "CREATE TABLE IF NOT EXISTS syn_intox ("
        "  uuid    TEXT    PRIMARY KEY,"
        "  level   INTEGER NOT NULL DEFAULT 0"
        ")");
    SqlStep(q);

    q = SqlPrepareQueryCampaign("szynkarz",
        "CREATE TABLE IF NOT EXISTS syn_cellar ("
        "  id        INTEGER PRIMARY KEY AUTOINCREMENT,"
        "  uuid      TEXT    NOT NULL,"
        "  recipe_id INTEGER NOT NULL,"
        "  qty       INTEGER NOT NULL DEFAULT 1"
        ")");
    SqlStep(q);
}

// ----------------------------------------------------------------
// Intoxication
// ----------------------------------------------------------------

int SynGetIntox(object oPC)
{
    sqlquery q = SqlPrepareQueryCampaign("szynkarz",
        "SELECT level FROM syn_intox WHERE uuid = @uuid");
    SqlBindString(q, "@uuid", GetObjectUUID(oPC));
    if(SqlStep(q)) return SqlGetInt(q, 0);
    return 0;
}

void SynSetIntox(object oPC, int nLevel)
{
    if(nLevel < 0)   nLevel = 0;
    if(nLevel > 100) nLevel = 100;
    sqlquery q = SqlPrepareQueryCampaign("szynkarz",
        "INSERT OR REPLACE INTO syn_intox (uuid, level) VALUES (@uuid, @lvl)");
    SqlBindString(q, "@uuid", GetObjectUUID(oPC));
    SqlBindInt   (q, "@lvl",  nLevel);
    SqlStep(q);
    SetLocalInt(oPC, "SYN_INTOX_CACHE", nLevel);
}

void SynAddIntox(object oPC, int nPoints)
{
    int nCurrent = SynGetIntox(oPC);
    SynSetIntox(oPC, nCurrent + nPoints);
}

// Decrements intox by 1; no-op if already 0.
void SynDecayIntox(object oPC)
{
    int nLevel = GetLocalInt(oPC, "SYN_INTOX_CACHE");
    if(nLevel <= 0) return;
    SynSetIntox(oPC, nLevel - 1);
}

// ----------------------------------------------------------------
// Cellar (stored brewed drinks per character)
// ----------------------------------------------------------------

// Returns JsonArray of {id, recipe_id, qty}
json SynGetCellar(object oPC)
{
    json jRows = JsonArray();
    sqlquery q = SqlPrepareQueryCampaign("szynkarz",
        "SELECT id, recipe_id, qty FROM syn_cellar"
        " WHERE uuid = @uuid AND qty > 0 ORDER BY recipe_id");
    SqlBindString(q, "@uuid", GetObjectUUID(oPC));
    while(SqlStep(q))
    {
        json jRow = JsonObject();
        jRow = JsonObjectSet(jRow, "id",        JsonInt(SqlGetInt(q, 0)));
        jRow = JsonObjectSet(jRow, "recipe_id", JsonInt(SqlGetInt(q, 1)));
        jRow = JsonObjectSet(jRow, "qty",       JsonInt(SqlGetInt(q, 2)));
        jRows = JsonArrayInsert(jRows, jRow);
    }
    return jRows;
}

void SynAddCellarDrink(object oPC, int nRecipeId)
{
    // Find existing row
    sqlquery q = SqlPrepareQueryCampaign("szynkarz",
        "SELECT id, qty FROM syn_cellar WHERE uuid = @uuid AND recipe_id = @rid");
    SqlBindString(q, "@uuid", GetObjectUUID(oPC));
    SqlBindInt   (q, "@rid",  nRecipeId);

    if(SqlStep(q))
    {
        int nId  = SqlGetInt(q, 0);
        int nQty = SqlGetInt(q, 1);
        sqlquery qu = SqlPrepareQueryCampaign("szynkarz",
            "UPDATE syn_cellar SET qty = @qty WHERE id = @id");
        SqlBindInt(qu, "@qty", nQty + 1);
        SqlBindInt(qu, "@id",  nId);
        SqlStep(qu);
    }
    else
    {
        sqlquery qi = SqlPrepareQueryCampaign("szynkarz",
            "INSERT INTO syn_cellar (uuid, recipe_id, qty) VALUES (@uuid, @rid, 1)");
        SqlBindString(qi, "@uuid", GetObjectUUID(oPC));
        SqlBindInt   (qi, "@rid",  nRecipeId);
        SqlStep(qi);
    }
}

void SynRemoveCellarDrink(object oPC, int nRowId)
{
    sqlquery q = SqlPrepareQueryCampaign("szynkarz",
        "UPDATE syn_cellar SET qty = qty - 1 WHERE id = @id AND uuid = @uuid");
    SqlBindInt   (q, "@id",   nRowId);
    SqlBindString(q, "@uuid", GetObjectUUID(oPC));
    SqlStep(q);

    q = SqlPrepareQueryCampaign("szynkarz",
        "DELETE FROM syn_cellar WHERE id = @id AND qty <= 0");
    SqlBindInt(q, "@id", nRowId);
    SqlStep(q);
}
