// SQLite schema and queries for Runic Forge.
// Campaign DB: "runic_forge"

void RFCreateTables()
{
    sqlquery q = SqlPrepareQueryCampaign("runic_forge",
        "CREATE TABLE IF NOT EXISTS rf_enchants ("
        "  id           INTEGER PRIMARY KEY AUTOINCREMENT,"
        "  pc_uuid      TEXT    NOT NULL,"
        "  item_uuid    TEXT    NOT NULL,"
        "  rune_id      INTEGER NOT NULL,"
        "  level        INTEGER NOT NULL DEFAULT 1,"
        "  enchanted_at INTEGER DEFAULT 0,"
        "  UNIQUE(item_uuid, rune_id)"
        ")");
    SqlStep(q);
}

// Returns current enchant level for this item+rune (0 = not yet enchanted).
int RFGetEnchantLevel(string sItemUuid, int nRuneId)
{
    sqlquery q = SqlPrepareQueryCampaign("runic_forge",
        "SELECT level FROM rf_enchants WHERE item_uuid=@item AND rune_id=@rune");
    SqlBindString(q, "@item", sItemUuid);
    SqlBindInt(q,    "@rune", nRuneId);
    if(SqlStep(q)) return SqlGetInt(q, 0);
    return 0;
}

// Insert or update enchant record (upsert).
void RFUpsertEnchant(string sPcUuid, string sItemUuid, int nRuneId, int nLevel)
{
    sqlquery q = SqlPrepareQueryCampaign("runic_forge",
        "INSERT INTO rf_enchants (pc_uuid, item_uuid, rune_id, level, enchanted_at)"
        " VALUES (@pc, @item, @rune, @lvl, strftime('%s','now'))"
        " ON CONFLICT(item_uuid, rune_id) DO UPDATE SET"
        "   level=@lvl, pc_uuid=@pc, enchanted_at=strftime('%s','now')");
    SqlBindString(q, "@pc",   sPcUuid);
    SqlBindString(q, "@item", sItemUuid);
    SqlBindInt(q,    "@rune", nRuneId);
    SqlBindInt(q,    "@lvl",  nLevel);
    SqlStep(q);
}

// Returns JsonArray of {rune_id, level} for all enchants on an item.
json RFGetItemEnchants(string sItemUuid)
{
    json jResult = JsonArray();
    sqlquery q = SqlPrepareQueryCampaign("runic_forge",
        "SELECT rune_id, level FROM rf_enchants WHERE item_uuid=@item ORDER BY rune_id");
    SqlBindString(q, "@item", sItemUuid);
    while(SqlStep(q))
    {
        json jEntry = JsonObject();
        jEntry = JsonObjectSet(jEntry, "rune_id", JsonInt(SqlGetInt(q, 0)));
        jEntry = JsonObjectSet(jEntry, "level",   JsonInt(SqlGetInt(q, 1)));
        jResult = JsonArrayInsert(jResult, jEntry);
    }
    return jResult;
}
