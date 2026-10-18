// ----------------------------------------------------------------
// SQLite schema and queries for Kartomancer.
// Campaign DB name: "carto"
// Table: carto_maps
// ----------------------------------------------------------------

void CartoInitDB()
{
    sqlquery q = SqlPrepareQueryCampaign("carto",
        "CREATE TABLE IF NOT EXISTS carto_maps ("
        "  id          INTEGER PRIMARY KEY AUTOINCREMENT,"
        "  player_uuid TEXT    NOT NULL,"
        "  area_tag    TEXT    NOT NULL,"
        "  area_name   TEXT    NOT NULL DEFAULT '',"
        "  danger      INTEGER NOT NULL DEFAULT 1,"
        "  notes       TEXT    NOT NULL DEFAULT '',"
        "  has_herbs   INTEGER NOT NULL DEFAULT 0,"
        "  has_ore     INTEGER NOT NULL DEFAULT 0,"
        "  has_water   INTEGER NOT NULL DEFAULT 0,"
        "  has_ruins   INTEGER NOT NULL DEFAULT 0,"
        "  has_shrine  INTEGER NOT NULL DEFAULT 0,"
        "  is_sold     INTEGER NOT NULL DEFAULT 0,"
        "  created_at  INTEGER NOT NULL DEFAULT (strftime('%s','now')),"
        "  UNIQUE(player_uuid, area_tag)"
        ")");
    SqlStep(q);
}

// Upsert a map record (insert or update).
void CartoSaveMap(
    object oPC,
    string sAreaTag,
    string sAreaName,
    int    nDanger,
    string sNotes,
    int    nHerbs,
    int    nOre,
    int    nWater,
    int    nRuins,
    int    nShrine)
{
    sqlquery q = SqlPrepareQueryCampaign("carto",
        "INSERT INTO carto_maps"
        " (player_uuid, area_tag, area_name, danger, notes,"
        "  has_herbs, has_ore, has_water, has_ruins, has_shrine, is_sold)"
        " VALUES(@uuid, @tag, @name, @danger, @notes,"
        "        @herbs, @ore, @water, @ruins, @shrine, 0)"
        " ON CONFLICT(player_uuid, area_tag) DO UPDATE SET"
        "  area_name  = excluded.area_name,"
        "  danger     = excluded.danger,"
        "  notes      = excluded.notes,"
        "  has_herbs  = excluded.has_herbs,"
        "  has_ore    = excluded.has_ore,"
        "  has_water  = excluded.has_water,"
        "  has_ruins  = excluded.has_ruins,"
        "  has_shrine = excluded.has_shrine,"
        "  is_sold    = 0");
    SqlBindString(q, "@uuid",   GetObjectUUID(oPC));
    SqlBindString(q, "@tag",    sAreaTag);
    SqlBindString(q, "@name",   sAreaName);
    SqlBindInt   (q, "@danger", nDanger);
    SqlBindString(q, "@notes",  sNotes);
    SqlBindInt   (q, "@herbs",  nHerbs);
    SqlBindInt   (q, "@ore",    nOre);
    SqlBindInt   (q, "@water",  nWater);
    SqlBindInt   (q, "@ruins",  nRuins);
    SqlBindInt   (q, "@shrine", nShrine);
    SqlStep(q);
}

// Returns a single map record as JsonObject, or JsonNull.
json CartoGetMap(object oPC, string sAreaTag)
{
    sqlquery q = SqlPrepareQueryCampaign("carto",
        "SELECT id, area_name, danger, notes,"
        "       has_herbs, has_ore, has_water, has_ruins, has_shrine, is_sold"
        " FROM carto_maps WHERE player_uuid = @uuid AND area_tag = @tag");
    SqlBindString(q, "@uuid", GetObjectUUID(oPC));
    SqlBindString(q, "@tag",  sAreaTag);
    if(!SqlStep(q)) return JsonNull();

    json j = JsonObject();
    j = JsonObjectSet(j, "id",         JsonInt   (SqlGetInt   (q, 0)));
    j = JsonObjectSet(j, "area_name",  JsonString(SqlGetString(q, 1)));
    j = JsonObjectSet(j, "danger",     JsonInt   (SqlGetInt   (q, 2)));
    j = JsonObjectSet(j, "notes",      JsonString(SqlGetString(q, 3)));
    j = JsonObjectSet(j, "has_herbs",  JsonInt   (SqlGetInt   (q, 4)));
    j = JsonObjectSet(j, "has_ore",    JsonInt   (SqlGetInt   (q, 5)));
    j = JsonObjectSet(j, "has_water",  JsonInt   (SqlGetInt   (q, 6)));
    j = JsonObjectSet(j, "has_ruins",  JsonInt   (SqlGetInt   (q, 7)));
    j = JsonObjectSet(j, "has_shrine", JsonInt   (SqlGetInt   (q, 8)));
    j = JsonObjectSet(j, "is_sold",    JsonInt   (SqlGetInt   (q, 9)));
    j = JsonObjectSet(j, "area_tag",   JsonString(sAreaTag));
    return j;
}

// Returns JsonArray of all map records for this player, ordered by danger desc, name asc.
json CartoGetAllMaps(object oPC)
{
    json jRows = JsonArray();
    sqlquery q = SqlPrepareQueryCampaign("carto",
        "SELECT area_tag, area_name, danger,"
        "       has_herbs, has_ore, has_water, has_ruins, has_shrine, is_sold"
        " FROM carto_maps WHERE player_uuid = @uuid"
        " ORDER BY danger DESC, area_name ASC");
    SqlBindString(q, "@uuid", GetObjectUUID(oPC));
    while(SqlStep(q))
    {
        json j = JsonObject();
        j = JsonObjectSet(j, "area_tag",   JsonString(SqlGetString(q, 0)));
        j = JsonObjectSet(j, "area_name",  JsonString(SqlGetString(q, 1)));
        j = JsonObjectSet(j, "danger",     JsonInt   (SqlGetInt   (q, 2)));
        j = JsonObjectSet(j, "has_herbs",  JsonInt   (SqlGetInt   (q, 3)));
        j = JsonObjectSet(j, "has_ore",    JsonInt   (SqlGetInt   (q, 4)));
        j = JsonObjectSet(j, "has_water",  JsonInt   (SqlGetInt   (q, 5)));
        j = JsonObjectSet(j, "has_ruins",  JsonInt   (SqlGetInt   (q, 6)));
        j = JsonObjectSet(j, "has_shrine", JsonInt   (SqlGetInt   (q, 7)));
        j = JsonObjectSet(j, "is_sold",    JsonInt   (SqlGetInt   (q, 8)));
        jRows = JsonArrayInsert(jRows, j);
    }
    return jRows;
}

// Mark map as sold (irreversible until next save).
void CartoMarkSold(object oPC, string sAreaTag)
{
    sqlquery q = SqlPrepareQueryCampaign("carto",
        "UPDATE carto_maps SET is_sold = 1 WHERE player_uuid = @uuid AND area_tag = @tag");
    SqlBindString(q, "@uuid", GetObjectUUID(oPC));
    SqlBindString(q, "@tag",  sAreaTag);
    SqlStep(q);
}

// Permanently delete a map.
void CartoDeleteMap(object oPC, string sAreaTag)
{
    sqlquery q = SqlPrepareQueryCampaign("carto",
        "DELETE FROM carto_maps WHERE player_uuid = @uuid AND area_tag = @tag");
    SqlBindString(q, "@uuid", GetObjectUUID(oPC));
    SqlBindString(q, "@tag",  sAreaTag);
    SqlStep(q);
}

// Copy a map from one player to another (ignores sold status — recipient gets fresh unsold copy).
void CartoCopyMapTo(object oSrc, object oDst, string sAreaTag)
{
    json jMap = CartoGetMap(oSrc, sAreaTag);
    if(JsonGetType(jMap) == JSON_TYPE_NULL) return;

    int nCnt;
    sqlquery qCnt = SqlPrepareQueryCampaign("carto",
        "SELECT COUNT(*) FROM carto_maps WHERE player_uuid = @uuid");
    SqlBindString(qCnt, "@uuid", GetObjectUUID(oDst));
    if(SqlStep(qCnt)) nCnt = SqlGetInt(qCnt, 0);

    // Silently refuse if recipient has too many maps
    if(nCnt >= 50) return;

    sqlquery q = SqlPrepareQueryCampaign("carto",
        "INSERT OR IGNORE INTO carto_maps"
        " (player_uuid, area_tag, area_name, danger, notes,"
        "  has_herbs, has_ore, has_water, has_ruins, has_shrine, is_sold)"
        " VALUES(@uuid, @tag, @name, @danger, @notes,"
        "        @herbs, @ore, @water, @ruins, @shrine, 0)");
    SqlBindString(q, "@uuid",   GetObjectUUID(oDst));
    SqlBindString(q, "@tag",    sAreaTag);
    SqlBindString(q, "@name",   JsonGetString(JsonObjectGet(jMap, "area_name")));
    SqlBindInt   (q, "@danger", JsonGetInt   (JsonObjectGet(jMap, "danger")));
    SqlBindString(q, "@notes",  JsonGetString(JsonObjectGet(jMap, "notes")));
    SqlBindInt   (q, "@herbs",  JsonGetInt   (JsonObjectGet(jMap, "has_herbs")));
    SqlBindInt   (q, "@ore",    JsonGetInt   (JsonObjectGet(jMap, "has_ore")));
    SqlBindInt   (q, "@water",  JsonGetInt   (JsonObjectGet(jMap, "has_water")));
    SqlBindInt   (q, "@ruins",  JsonGetInt   (JsonObjectGet(jMap, "has_ruins")));
    SqlBindInt   (q, "@shrine", JsonGetInt   (JsonObjectGet(jMap, "has_shrine")));
    SqlStep(q);
}

// Returns total gold for selling all unsold maps.
int CartoGetSellAllGold(object oPC)
{
    sqlquery q = SqlPrepareQueryCampaign("carto",
        "SELECT SUM(CASE danger"
        "  WHEN 1 THEN 50 WHEN 2 THEN 120 WHEN 3 THEN 250"
        "  WHEN 4 THEN 400 WHEN 5 THEN 600 ELSE 50 END)"
        " FROM carto_maps WHERE player_uuid = @uuid AND is_sold = 0");
    SqlBindString(q, "@uuid", GetObjectUUID(oPC));
    if(SqlStep(q)) return SqlGetInt(q, 0);
    return 0;
}

// Mark all unsold maps as sold, returns total gold earned.
int CartoSellAll(object oPC)
{
    int nGold = CartoGetSellAllGold(oPC);
    sqlquery q = SqlPrepareQueryCampaign("carto",
        "UPDATE carto_maps SET is_sold = 1 WHERE player_uuid = @uuid AND is_sold = 0");
    SqlBindString(q, "@uuid", GetObjectUUID(oPC));
    SqlStep(q);
    return nGold;
}

// True if a map for this area_tag exists for this player.
int CartoHasMap(object oPC, string sAreaTag)
{
    sqlquery q = SqlPrepareQueryCampaign("carto",
        "SELECT 1 FROM carto_maps WHERE player_uuid = @uuid AND area_tag = @tag");
    SqlBindString(q, "@uuid", GetObjectUUID(oPC));
    SqlBindString(q, "@tag",  sAreaTag);
    return SqlStep(q);
}
