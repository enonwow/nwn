// ----------------------------------------------------------------
// Herbarium — SQL layer
// Campaign DB: "herbarium"
// ----------------------------------------------------------------

void HerbCreateTables()
{
    sqlquery q;

    q = SqlPrepareQueryCampaign("herbarium",
        "CREATE TABLE IF NOT EXISTS herb_nodes ("
        "  node_tag  TEXT    PRIMARY KEY,"
        "  herb_type INTEGER NOT NULL DEFAULT 1,"
        "  charges   INTEGER NOT NULL DEFAULT 3,"
        "  max_chrg  INTEGER NOT NULL DEFAULT 3,"
        "  last_harv INTEGER NOT NULL DEFAULT 0"
        ")");
    SqlStep(q);

    q = SqlPrepareQueryCampaign("herbarium",
        "CREATE TABLE IF NOT EXISTS herb_player ("
        "  player_uuid TEXT    NOT NULL,"
        "  herb_type   INTEGER NOT NULL,"
        "  total_count INTEGER NOT NULL DEFAULT 0,"
        "  known       INTEGER NOT NULL DEFAULT 0,"
        "  PRIMARY KEY (player_uuid, herb_type)"
        ")");
    SqlStep(q);
}

// Idempotent — safe to call on every node OnUsed
void HerbNodeEnsure(string sTag, int nType, int nMax)
{
    sqlquery q = SqlPrepareQueryCampaign("herbarium",
        "INSERT OR IGNORE INTO herb_nodes"
        "  (node_tag, herb_type, charges, max_chrg, last_harv)"
        "  VALUES (@tag, @type, @max, @max, 0)");
    SqlBindString(q, "@tag",  sTag);
    SqlBindInt   (q, "@type", nType);
    SqlBindInt   (q, "@max",  nMax);
    SqlStep(q);
}

int HerbNodeGetCharges(string sTag)
{
    sqlquery q = SqlPrepareQueryCampaign("herbarium",
        "SELECT charges FROM herb_nodes WHERE node_tag = @tag");
    SqlBindString(q, "@tag", sTag);
    if(SqlStep(q)) return SqlGetInt(q, 0);
    return 0;
}

int HerbNodeGetType(string sTag)
{
    sqlquery q = SqlPrepareQueryCampaign("herbarium",
        "SELECT herb_type FROM herb_nodes WHERE node_tag = @tag");
    SqlBindString(q, "@tag", sTag);
    if(SqlStep(q)) return SqlGetInt(q, 0);
    return 0;
}

// Restores one charge if enough real time has passed since last harvest
void HerbNodeRegen(string sTag, int nRegenSecs)
{
    sqlquery q = SqlPrepareQueryCampaign("herbarium",
        "UPDATE herb_nodes"
        "  SET charges   = MIN(max_chrg, charges + 1),"
        "      last_harv = strftime('%s','now')"
        "  WHERE node_tag = @tag"
        "    AND charges  < max_chrg"
        "    AND strftime('%s','now') - last_harv >= @regen");
    SqlBindString(q, "@tag",   sTag);
    SqlBindInt   (q, "@regen", nRegenSecs);
    SqlStep(q);
}

// Returns 1 on success, 0 if already depleted
int HerbNodeHarvest(string sTag)
{
    int nBefore = HerbNodeGetCharges(sTag);
    if(nBefore <= 0) return 0;

    sqlquery q = SqlPrepareQueryCampaign("herbarium",
        "UPDATE herb_nodes"
        "  SET charges   = charges - 1,"
        "      last_harv = strftime('%s','now')"
        "  WHERE node_tag = @tag AND charges > 0");
    SqlBindString(q, "@tag", sTag);
    SqlStep(q);
    return 1;
}

void HerbPlayerGive(object oPC, int nType, int nAmount)
{
    sqlquery q = SqlPrepareQueryCampaign("herbarium",
        "INSERT INTO herb_player (player_uuid, herb_type, total_count, known)"
        "  VALUES (@uuid, @type, @amt, 1)"
        "  ON CONFLICT(player_uuid, herb_type) DO UPDATE"
        "  SET total_count = total_count + @amt, known = 1");
    SqlBindString(q, "@uuid", GetObjectUUID(oPC));
    SqlBindInt   (q, "@type", nType);
    SqlBindInt   (q, "@amt",  nAmount);
    SqlStep(q);
}

void HerbPlayerConsume(object oPC, int nType, int nAmount)
{
    sqlquery q = SqlPrepareQueryCampaign("herbarium",
        "UPDATE herb_player"
        "  SET total_count = MAX(0, total_count - @amt)"
        "  WHERE player_uuid = @uuid AND herb_type = @type");
    SqlBindString(q, "@uuid", GetObjectUUID(oPC));
    SqlBindInt   (q, "@type", nType);
    SqlBindInt   (q, "@amt",  nAmount);
    SqlStep(q);
}

int HerbPlayerGetCount(object oPC, int nType)
{
    sqlquery q = SqlPrepareQueryCampaign("herbarium",
        "SELECT total_count FROM herb_player"
        "  WHERE player_uuid = @uuid AND herb_type = @type");
    SqlBindString(q, "@uuid", GetObjectUUID(oPC));
    SqlBindInt   (q, "@type", nType);
    if(SqlStep(q)) return SqlGetInt(q, 0);
    return 0;
}

// Returns JsonArray of {type, count, known} for all herbs the PC knows
json HerbPlayerGetAll(object oPC)
{
    json jRows = JsonArray();
    sqlquery q = SqlPrepareQueryCampaign("herbarium",
        "SELECT herb_type, total_count FROM herb_player"
        "  WHERE player_uuid = @uuid AND known = 1"
        "  ORDER BY herb_type");
    SqlBindString(q, "@uuid", GetObjectUUID(oPC));
    while(SqlStep(q))
    {
        json jRow = JsonObject();
        jRow = JsonObjectSet(jRow, "type",  JsonInt(SqlGetInt(q, 0)));
        jRow = JsonObjectSet(jRow, "count", JsonInt(SqlGetInt(q, 1)));
        jRows = JsonArrayInsert(jRows, jRow);
    }
    return jRows;
}
