// Campaign DB identifier
const string DUR_DB = "durability";

void DurCreateTables()
{
    sqlquery q = SqlPrepareQueryCampaign(DUR_DB,
        "CREATE TABLE IF NOT EXISTS dur_items ("
        "item_uuid     TEXT PRIMARY KEY, "
        "owner_uuid    TEXT DEFAULT '', "
        "inv_slot      INTEGER DEFAULT -1, "
        "durability    INTEGER DEFAULT 100, "
        "max_durability INTEGER DEFAULT 100, "
        "last_decay    INTEGER DEFAULT 0)");
    SqlStep(q);
}

// Returns current durability; 100 if item not yet tracked (treated as fresh)
int DurGetDurability(object oItem)
{
    if(!GetIsObjectValid(oItem)) return 100;
    sqlquery q = SqlPrepareQueryCampaign(DUR_DB,
        "SELECT durability FROM dur_items WHERE item_uuid = @uuid");
    SqlBindString(q, "@uuid", GetObjectUUID(oItem));
    if(SqlStep(q)) return SqlGetInt(q, 0);
    return 100;
}

int DurGetMaxDurability(object oItem)
{
    if(!GetIsObjectValid(oItem)) return 100;
    sqlquery q = SqlPrepareQueryCampaign(DUR_DB,
        "SELECT max_durability FROM dur_items WHERE item_uuid = @uuid");
    SqlBindString(q, "@uuid", GetObjectUUID(oItem));
    if(SqlStep(q)) return SqlGetInt(q, 0);
    return 100;
}

// Creates row if absent; idempotent
void DurEnsureItem(object oItem, object oOwner, int nSlot)
{
    if(!GetIsObjectValid(oItem)) return;
    sqlquery q = SqlPrepareQueryCampaign(DUR_DB,
        "INSERT OR IGNORE INTO dur_items (item_uuid, owner_uuid, inv_slot) "
        "VALUES (@uuid, @owner, @slot)");
    SqlBindString(q, "@uuid",  GetObjectUUID(oItem));
    SqlBindString(q, "@owner", GetObjectUUID(oOwner));
    SqlBindInt   (q, "@slot",  nSlot);
    SqlStep(q);
}

void DurSetDurability(object oItem, int nVal)
{
    if(!GetIsObjectValid(oItem)) return;
    if(nVal < 0)   nVal = 0;
    if(nVal > 100) nVal = 100;
    sqlquery q = SqlPrepareQueryCampaign(DUR_DB,
        "UPDATE dur_items SET durability = @val WHERE item_uuid = @uuid");
    SqlBindInt   (q, "@val",  nVal);
    SqlBindString(q, "@uuid", GetObjectUUID(oItem));
    SqlStep(q);
}

void DurDecayItem(object oItem, int nAmount)
{
    if(!GetIsObjectValid(oItem) || nAmount <= 0) return;
    sqlquery q = SqlPrepareQueryCampaign(DUR_DB,
        "UPDATE dur_items "
        "SET durability = MAX(0, durability - @amt), "
        "    last_decay = strftime('%s','now') "
        "WHERE item_uuid = @uuid");
    SqlBindInt   (q, "@amt",  nAmount);
    SqlBindString(q, "@uuid", GetObjectUUID(oItem));
    SqlStep(q);
}

void DurRepairItem(object oItem, int nAmount)
{
    if(!GetIsObjectValid(oItem) || nAmount <= 0) return;
    sqlquery q = SqlPrepareQueryCampaign(DUR_DB,
        "UPDATE dur_items "
        "SET durability = MIN(max_durability, durability + @amt) "
        "WHERE item_uuid = @uuid");
    SqlBindInt   (q, "@amt",  nAmount);
    SqlBindString(q, "@uuid", GetObjectUUID(oItem));
    SqlStep(q);
}

void DurFullRepair(object oItem)
{
    if(!GetIsObjectValid(oItem)) return;
    sqlquery q = SqlPrepareQueryCampaign(DUR_DB,
        "UPDATE dur_items SET durability = max_durability WHERE item_uuid = @uuid");
    SqlBindString(q, "@uuid", GetObjectUUID(oItem));
    SqlStep(q);
}

// Returns 1 if this item has an entry, 0 otherwise
int DurItemExists(object oItem)
{
    if(!GetIsObjectValid(oItem)) return 0;
    sqlquery q = SqlPrepareQueryCampaign(DUR_DB,
        "SELECT 1 FROM dur_items WHERE item_uuid = @uuid");
    SqlBindString(q, "@uuid", GetObjectUUID(oItem));
    return SqlStep(q);
}
