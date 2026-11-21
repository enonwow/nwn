// sql_poi.nss  — SQLite persistence for Poison Workshop
// Single table: poi_stock(char_uuid, item_id, quantity)
// item_id  0-7  = ingredient slot (POI_ING_*)
// item_id 100+  = poison vial slot (POI_POISON_OFFSET + POI_VIAL_*)

const int POI_ING_COUNT       = 8;
const int POI_VIAL_COUNT      = 6;
const int POI_POISON_OFFSET   = 100;

void PoiCreateTables()
{
    sqlquery q = SqlPrepareQueryCampaign("poi",
        "CREATE TABLE IF NOT EXISTS poi_stock ("
        "  char_uuid TEXT    NOT NULL, "
        "  item_id   INTEGER NOT NULL, "
        "  quantity  INTEGER DEFAULT 0, "
        "  PRIMARY KEY (char_uuid, item_id))");
    SqlStep(q);
}

int PoiGetStock(object oPC, int nItemId)
{
    sqlquery q = SqlPrepareQueryCampaign("poi",
        "SELECT quantity FROM poi_stock "
        "WHERE char_uuid = @uuid AND item_id = @id");
    SqlBindString(q, "@uuid", GetObjectUUID(oPC));
    SqlBindInt   (q, "@id",   nItemId);
    if(SqlStep(q)) return SqlGetInt(q, 0);
    return 0;
}

void PoiSetStock(object oPC, int nItemId, int nAmount)
{
    if(nAmount < 0) nAmount = 0;
    sqlquery q = SqlPrepareQueryCampaign("poi",
        "INSERT OR REPLACE INTO poi_stock (char_uuid, item_id, quantity) "
        "VALUES (@uuid, @id, @qty)");
    SqlBindString(q, "@uuid", GetObjectUUID(oPC));
    SqlBindInt   (q, "@id",   nItemId);
    SqlBindInt   (q, "@qty",  nAmount);
    SqlStep(q);
}

void PoiModifyStock(object oPC, int nItemId, int nDelta)
{
    int nCurrent = PoiGetStock(oPC, nItemId);
    PoiSetStock(oPC, nItemId, nCurrent + nDelta);
}

json PoiGetIngredientCounts(object oPC)
{
    json jOut = JsonArray();
    int i;
    for(i = 0; i < POI_ING_COUNT; i++)
        jOut = JsonArrayInsert(jOut, JsonInt(PoiGetStock(oPC, i)));
    return jOut;
}

json PoiGetPoisonCounts(object oPC)
{
    json jOut = JsonArray();
    int i;
    for(i = 0; i < POI_VIAL_COUNT; i++)
        jOut = JsonArrayInsert(jOut, JsonInt(PoiGetStock(oPC, POI_POISON_OFFSET + i)));
    return jOut;
}
