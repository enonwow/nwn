// Persistent storage for Pilgrim's Curse.
// All queries target campaign DB "plg".

const string PLG_DB = "plg";

void PlgCreateTables()
{
    sqlquery q = SqlPrepareQueryCampaign(PLG_DB,
        "CREATE TABLE IF NOT EXISTS plg_shrines ("
        "  id           INTEGER PRIMARY KEY AUTOINCREMENT,"
        "  tag          TEXT NOT NULL UNIQUE,"
        "  name         TEXT DEFAULT '',"
        "  lore         TEXT DEFAULT '',"
        "  burden_type  TEXT DEFAULT 'shadow',"
        "  burden_val   INTEGER DEFAULT 1)");
    SqlStep(q);

    q = SqlPrepareQueryCampaign(PLG_DB,
        "CREATE TABLE IF NOT EXISTS plg_pilgrims ("
        "  uuid          TEXT PRIMARY KEY,"
        "  char_name     TEXT DEFAULT '',"
        "  burden_shadow INTEGER DEFAULT 0,"
        "  burden_blood  INTEGER DEFAULT 0,"
        "  burden_death  INTEGER DEFAULT 0,"
        "  burden_chaos  INTEGER DEFAULT 0,"
        "  total_visits  INTEGER DEFAULT 0,"
        "  circuits_done INTEGER DEFAULT 0)");
    SqlStep(q);

    q = SqlPrepareQueryCampaign(PLG_DB,
        "CREATE TABLE IF NOT EXISTS plg_visits ("
        "  uuid       TEXT NOT NULL,"
        "  shrine_id  INTEGER NOT NULL,"
        "  visited_at INTEGER DEFAULT 0,"
        "  PRIMARY KEY (uuid, shrine_id))");
    SqlStep(q);
}

// Idempotent — uses INSERT OR IGNORE so re-running on_load is safe.
void PlgRegisterShrine(string sTag, string sName, string sLore, string sType, int nVal)
{
    sqlquery q = SqlPrepareQueryCampaign(PLG_DB,
        "INSERT OR IGNORE INTO plg_shrines (tag, name, lore, burden_type, burden_val) "
        "VALUES (@tag, @name, @lore, @type, @val)");
    SqlBindString(q, "@tag",  sTag);
    SqlBindString(q, "@name", sName);
    SqlBindString(q, "@lore", sLore);
    SqlBindString(q, "@type", sType);
    SqlBindInt   (q, "@val",  nVal);
    SqlStep(q);
}

void PlgRegisterPlayer(object oPC)
{
    sqlquery q = SqlPrepareQueryCampaign(PLG_DB,
        "INSERT OR IGNORE INTO plg_pilgrims (uuid, char_name) VALUES (@uuid, @name)");
    SqlBindString(q, "@uuid", GetObjectUUID(oPC));
    SqlBindString(q, "@name", GetName(oPC));
    SqlStep(q);

    // Refresh display name on each login.
    q = SqlPrepareQueryCampaign(PLG_DB,
        "UPDATE plg_pilgrims SET char_name = @name WHERE uuid = @uuid");
    SqlBindString(q, "@name", GetName(oPC));
    SqlBindString(q, "@uuid", GetObjectUUID(oPC));
    SqlStep(q);
}

// Returns JsonNull if the player has never been registered.
json PlgGetPilgrim(object oPC)
{
    sqlquery q = SqlPrepareQueryCampaign(PLG_DB,
        "SELECT uuid, char_name, burden_shadow, burden_blood, burden_death, burden_chaos, "
        "       total_visits, circuits_done "
        "FROM plg_pilgrims WHERE uuid = @uuid");
    SqlBindString(q, "@uuid", GetObjectUUID(oPC));
    if(!SqlStep(q)) return JsonNull();
    json j = JsonObject();
    j = JsonObjectSet(j, "uuid",          JsonString(SqlGetString(q, 0)));
    j = JsonObjectSet(j, "char_name",     JsonString(SqlGetString(q, 1)));
    j = JsonObjectSet(j, "burden_shadow", JsonInt   (SqlGetInt   (q, 2)));
    j = JsonObjectSet(j, "burden_blood",  JsonInt   (SqlGetInt   (q, 3)));
    j = JsonObjectSet(j, "burden_death",  JsonInt   (SqlGetInt   (q, 4)));
    j = JsonObjectSet(j, "burden_chaos",  JsonInt   (SqlGetInt   (q, 5)));
    j = JsonObjectSet(j, "total_visits",  JsonInt   (SqlGetInt   (q, 6)));
    j = JsonObjectSet(j, "circuits_done", JsonInt   (SqlGetInt   (q, 7)));
    return j;
}

// Returns -1 when tag is unknown.
int PlgGetShrineId(string sTag)
{
    sqlquery q = SqlPrepareQueryCampaign(PLG_DB,
        "SELECT id FROM plg_shrines WHERE tag = @tag");
    SqlBindString(q, "@tag", sTag);
    if(SqlStep(q)) return SqlGetInt(q, 0);
    return -1;
}

json PlgGetShrine(int nId)
{
    sqlquery q = SqlPrepareQueryCampaign(PLG_DB,
        "SELECT id, tag, name, lore, burden_type, burden_val "
        "FROM plg_shrines WHERE id = @id");
    SqlBindInt(q, "@id", nId);
    if(!SqlStep(q)) return JsonNull();
    json j = JsonObject();
    j = JsonObjectSet(j, "id",          JsonInt   (SqlGetInt   (q, 0)));
    j = JsonObjectSet(j, "tag",         JsonString(SqlGetString(q, 1)));
    j = JsonObjectSet(j, "name",        JsonString(SqlGetString(q, 2)));
    j = JsonObjectSet(j, "lore",        JsonString(SqlGetString(q, 3)));
    j = JsonObjectSet(j, "burden_type", JsonString(SqlGetString(q, 4)));
    j = JsonObjectSet(j, "burden_val",  JsonInt   (SqlGetInt   (q, 5)));
    return j;
}

int PlgHasVisited(object oPC, int nShrineId)
{
    sqlquery q = SqlPrepareQueryCampaign(PLG_DB,
        "SELECT COUNT(*) FROM plg_visits WHERE uuid = @uuid AND shrine_id = @id");
    SqlBindString(q, "@uuid", GetObjectUUID(oPC));
    SqlBindInt   (q, "@id",   nShrineId);
    if(SqlStep(q)) return SqlGetInt(q, 0) > 0;
    return 0;
}

// Returns JsonArray of {id, name, lore, burden_type, burden_val, visited} for all shrines.
json PlgGetAllShrines(object oPC)
{
    json jResult = JsonArray();
    sqlquery q = SqlPrepareQueryCampaign(PLG_DB,
        "SELECT s.id, s.name, s.lore, s.burden_type, s.burden_val,"
        "  CASE WHEN v.uuid IS NOT NULL THEN 1 ELSE 0 END AS visited "
        "FROM plg_shrines s "
        "LEFT JOIN plg_visits v ON v.shrine_id = s.id AND v.uuid = @uuid "
        "ORDER BY s.burden_type, s.name");
    SqlBindString(q, "@uuid", GetObjectUUID(oPC));
    while(SqlStep(q))
    {
        json j = JsonObject();
        j = JsonObjectSet(j, "id",          JsonInt   (SqlGetInt   (q, 0)));
        j = JsonObjectSet(j, "name",        JsonString(SqlGetString(q, 1)));
        j = JsonObjectSet(j, "lore",        JsonString(SqlGetString(q, 2)));
        j = JsonObjectSet(j, "burden_type", JsonString(SqlGetString(q, 3)));
        j = JsonObjectSet(j, "burden_val",  JsonInt   (SqlGetInt   (q, 4)));
        j = JsonObjectSet(j, "visited",     JsonInt   (SqlGetInt   (q, 5)));
        jResult = JsonArrayInsert(jResult, j);
    }
    return jResult;
}

// Marks the visit and adds burden points.  NWScript can't bind column names so
// we branch on sType to build the correct UPDATE statement.
void PlgRecordVisit(object oPC, int nShrineId, string sType, int nVal)
{
    sqlquery q = SqlPrepareQueryCampaign(PLG_DB,
        "INSERT OR IGNORE INTO plg_visits (uuid, shrine_id, visited_at) "
        "VALUES (@uuid, @id, strftime('%s','now'))");
    SqlBindString(q, "@uuid", GetObjectUUID(oPC));
    SqlBindInt   (q, "@id",   nShrineId);
    SqlStep(q);

    string sSql = "";
    if(sType == "shadow")
        sSql = "UPDATE plg_pilgrims SET burden_shadow = burden_shadow + @val,"
               " total_visits = total_visits + 1 WHERE uuid = @uuid";
    else if(sType == "blood")
        sSql = "UPDATE plg_pilgrims SET burden_blood = burden_blood + @val,"
               " total_visits = total_visits + 1 WHERE uuid = @uuid";
    else if(sType == "death")
        sSql = "UPDATE plg_pilgrims SET burden_death = burden_death + @val,"
               " total_visits = total_visits + 1 WHERE uuid = @uuid";
    else
        sSql = "UPDATE plg_pilgrims SET burden_chaos = burden_chaos + @val,"
               " total_visits = total_visits + 1 WHERE uuid = @uuid";

    q = SqlPrepareQueryCampaign(PLG_DB, sSql);
    SqlBindInt   (q, "@val",  nVal);
    SqlBindString(q, "@uuid", GetObjectUUID(oPC));
    SqlStep(q);
}

int PlgGetShrineCount()
{
    sqlquery q = SqlPrepareQueryCampaign(PLG_DB, "SELECT COUNT(*) FROM plg_shrines");
    if(SqlStep(q)) return SqlGetInt(q, 0);
    return 0;
}

int PlgGetVisitCount(object oPC)
{
    sqlquery q = SqlPrepareQueryCampaign(PLG_DB,
        "SELECT COUNT(*) FROM plg_visits WHERE uuid = @uuid");
    SqlBindString(q, "@uuid", GetObjectUUID(oPC));
    if(SqlStep(q)) return SqlGetInt(q, 0);
    return 0;
}

int PlgCheckCircuitCompletion(object oPC)
{
    int nTotal = PlgGetShrineCount();
    if(nTotal == 0) return 0;
    return PlgGetVisitCount(oPC) >= nTotal;
}

void PlgIncrementCircuits(object oPC)
{
    sqlquery q = SqlPrepareQueryCampaign(PLG_DB,
        "UPDATE plg_pilgrims SET circuits_done = circuits_done + 1 WHERE uuid = @uuid");
    SqlBindString(q, "@uuid", GetObjectUUID(oPC));
    SqlStep(q);
}

// Clears the visit log so the player can walk the circuit again.
void PlgResetVisits(object oPC)
{
    sqlquery q = SqlPrepareQueryCampaign(PLG_DB,
        "DELETE FROM plg_visits WHERE uuid = @uuid");
    SqlBindString(q, "@uuid", GetObjectUUID(oPC));
    SqlStep(q);
}

// Catharsis zeroes ALL burden but preserves visit history / circuits.
void PlgPerformCatharsis(object oPC)
{
    sqlquery q = SqlPrepareQueryCampaign(PLG_DB,
        "UPDATE plg_pilgrims"
        " SET burden_shadow = 0, burden_blood = 0, burden_death = 0, burden_chaos = 0"
        " WHERE uuid = @uuid");
    SqlBindString(q, "@uuid", GetObjectUUID(oPC));
    SqlStep(q);
}

// Top-10 by total burden for the leaderboard tab.
json PlgGetLeaderboard()
{
    json jResult = JsonArray();
    sqlquery q = SqlPrepareQueryCampaign(PLG_DB,
        "SELECT char_name, burden_shadow, burden_blood, burden_death, burden_chaos,"
        "  circuits_done,"
        "  (burden_shadow + burden_blood + burden_death + burden_chaos) AS total "
        "FROM plg_pilgrims "
        "WHERE (burden_shadow + burden_blood + burden_death + burden_chaos) > 0 "
        "ORDER BY total DESC LIMIT 10");
    while(SqlStep(q))
    {
        json j = JsonObject();
        j = JsonObjectSet(j, "char_name",     JsonString(SqlGetString(q, 0)));
        j = JsonObjectSet(j, "burden_shadow", JsonInt   (SqlGetInt   (q, 1)));
        j = JsonObjectSet(j, "burden_blood",  JsonInt   (SqlGetInt   (q, 2)));
        j = JsonObjectSet(j, "burden_death",  JsonInt   (SqlGetInt   (q, 3)));
        j = JsonObjectSet(j, "burden_chaos",  JsonInt   (SqlGetInt   (q, 4)));
        j = JsonObjectSet(j, "circuits_done", JsonInt   (SqlGetInt   (q, 5)));
        j = JsonObjectSet(j, "total",         JsonInt   (SqlGetInt   (q, 6)));
        jResult = JsonArrayInsert(jResult, j);
    }
    return jResult;
}
