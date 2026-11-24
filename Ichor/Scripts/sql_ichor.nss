// sql_ichor.nss — DB schema + queries for the Ichor module.

void IchorCreateTables()
{
    sqlquery q;
    q = SqlPrepareQueryCampaign("ichor",
        "CREATE TABLE IF NOT EXISTS ichor_essences ("
        "  id       INTEGER PRIMARY KEY AUTOINCREMENT,"
        "  pc_uuid  TEXT    NOT NULL,"
        "  ctype    TEXT    NOT NULL,"
        "  cname    TEXT    NOT NULL DEFAULT '',"
        "  charges  INTEGER NOT NULL DEFAULT 3,"
        "  added_at INTEGER NOT NULL DEFAULT (strftime('%s','now'))"
        ")");
    SqlStep(q);

    q = SqlPrepareQueryCampaign("ichor",
        "CREATE TABLE IF NOT EXISTS ichor_active ("
        "  id         INTEGER PRIMARY KEY AUTOINCREMENT,"
        "  pc_uuid    TEXT    NOT NULL,"
        "  item_uuid  TEXT    NOT NULL,"
        "  slot_num   INTEGER NOT NULL,"
        "  effect_key TEXT    NOT NULL,"
        "  expires_at INTEGER NOT NULL"
        ")");
    SqlStep(q);

    q = SqlPrepareQueryCampaign("ichor",
        "CREATE INDEX IF NOT EXISTS idx_ess_pc ON ichor_essences(pc_uuid)");
    SqlStep(q);

    q = SqlPrepareQueryCampaign("ichor",
        "CREATE INDEX IF NOT EXISTS idx_act_pc ON ichor_active(pc_uuid)");
    SqlStep(q);
}

// Adds a fresh essence (3 charges) or increments charges on an existing stack of the same type.
void IchorAddEssence(string sPcUuid, string sCtype, string sCname)
{
    sqlquery q = SqlPrepareQueryCampaign("ichor",
        "INSERT INTO ichor_essences (pc_uuid, ctype, cname)"
        " VALUES (@uuid, @ctype, @cname)");
    SqlBindString(q, "@uuid",  sPcUuid);
    SqlBindString(q, "@ctype", sCtype);
    SqlBindString(q, "@cname", sCname);
    SqlStep(q);
}

// Returns JsonArray [{id, ctype, cname, charges, added_at}, ...] for one PC.
json IchorGetEssences(string sPcUuid)
{
    json jOut = JsonArray();
    sqlquery q = SqlPrepareQueryCampaign("ichor",
        "SELECT id, ctype, cname, charges, added_at"
        " FROM ichor_essences WHERE pc_uuid = @uuid"
        " ORDER BY added_at DESC");
    SqlBindString(q, "@uuid", sPcUuid);
    while(SqlStep(q))
    {
        json jRow = JsonObject();
        jRow = JsonObjectSet(jRow, "id",       JsonInt   (SqlGetInt   (q, 0)));
        jRow = JsonObjectSet(jRow, "ctype",    JsonString(SqlGetString(q, 1)));
        jRow = JsonObjectSet(jRow, "cname",    JsonString(SqlGetString(q, 2)));
        jRow = JsonObjectSet(jRow, "charges",  JsonInt   (SqlGetInt   (q, 3)));
        jRow = JsonObjectSet(jRow, "added_at", JsonInt   (SqlGetInt   (q, 4)));
        jOut = JsonArrayInsert(jOut, jRow);
    }
    return jOut;
}

// Consumes one charge; deletes the row if charges reach 0.
void IchorConsumeCharge(int nId)
{
    sqlquery q = SqlPrepareQueryCampaign("ichor",
        "UPDATE ichor_essences SET charges = charges - 1 WHERE id = @id");
    SqlBindInt(q, "@id", nId);
    SqlStep(q);

    q = SqlPrepareQueryCampaign("ichor",
        "DELETE FROM ichor_essences WHERE id = @id AND charges <= 0");
    SqlBindInt(q, "@id", nId);
    SqlStep(q);
}

// Records that slot nSlot of item sItemUuid now has effect sKey (expires nExpires unix sec).
void IchorAddActive(string sPcUuid, string sItemUuid, int nSlot, string sKey, int nExpires)
{
    // Replace any existing record for the same item+slot.
    sqlquery q = SqlPrepareQueryCampaign("ichor",
        "DELETE FROM ichor_active"
        " WHERE pc_uuid = @uuid AND item_uuid = @item AND slot_num = @slot");
    SqlBindString(q, "@uuid", sPcUuid);
    SqlBindString(q, "@item", sItemUuid);
    SqlBindInt   (q, "@slot", nSlot);
    SqlStep(q);

    q = SqlPrepareQueryCampaign("ichor",
        "INSERT INTO ichor_active (pc_uuid, item_uuid, slot_num, effect_key, expires_at)"
        " VALUES (@uuid, @item, @slot, @key, @exp)");
    SqlBindString(q, "@uuid", sPcUuid);
    SqlBindString(q, "@item", sItemUuid);
    SqlBindInt   (q, "@slot", nSlot);
    SqlBindString(q, "@key",  sKey);
    SqlBindInt   (q, "@exp",  nExpires);
    SqlStep(q);
}

// Returns JsonArray [{id, item_uuid, slot_num, effect_key, expires_at}, ...] — only non-expired.
json IchorGetActive(string sPcUuid)
{
    json jOut = JsonArray();
    sqlquery q = SqlPrepareQueryCampaign("ichor",
        "SELECT id, item_uuid, slot_num, effect_key, expires_at"
        " FROM ichor_active"
        " WHERE pc_uuid = @uuid AND expires_at > strftime('%s','now')"
        " ORDER BY item_uuid, slot_num");
    SqlBindString(q, "@uuid", sPcUuid);
    while(SqlStep(q))
    {
        json jRow = JsonObject();
        jRow = JsonObjectSet(jRow, "id",         JsonInt   (SqlGetInt   (q, 0)));
        jRow = JsonObjectSet(jRow, "item_uuid",  JsonString(SqlGetString(q, 1)));
        jRow = JsonObjectSet(jRow, "slot_num",   JsonInt   (SqlGetInt   (q, 2)));
        jRow = JsonObjectSet(jRow, "effect_key", JsonString(SqlGetString(q, 3)));
        jRow = JsonObjectSet(jRow, "expires_at", JsonInt   (SqlGetInt   (q, 4)));
        jOut = JsonArrayInsert(jOut, jRow);
    }
    return jOut;
}

void IchorRemoveActiveById(int nId)
{
    sqlquery q = SqlPrepareQueryCampaign("ichor",
        "DELETE FROM ichor_active WHERE id = @id");
    SqlBindInt(q, "@id", nId);
    SqlStep(q);
}

// Deletes all expired records for a PC; called on area entry.
void IchorPruneExpired(string sPcUuid)
{
    sqlquery q = SqlPrepareQueryCampaign("ichor",
        "DELETE FROM ichor_active"
        " WHERE pc_uuid = @uuid AND expires_at <= strftime('%s','now')");
    SqlBindString(q, "@uuid", sPcUuid);
    SqlStep(q);
}

// Returns the DB row for a specific item+slot, or JSON_NULL if none / expired.
json IchorGetSlot(string sPcUuid, string sItemUuid, int nSlot)
{
    sqlquery q = SqlPrepareQueryCampaign("ichor",
        "SELECT id, effect_key, expires_at FROM ichor_active"
        " WHERE pc_uuid = @uuid AND item_uuid = @item AND slot_num = @slot"
        "   AND expires_at > strftime('%s','now')");
    SqlBindString(q, "@uuid", sPcUuid);
    SqlBindString(q, "@item", sItemUuid);
    SqlBindInt   (q, "@slot", nSlot);
    if(!SqlStep(q)) return JsonNull();
    json jRow = JsonObject();
    jRow = JsonObjectSet(jRow, "id",         JsonInt   (SqlGetInt   (q, 0)));
    jRow = JsonObjectSet(jRow, "effect_key", JsonString(SqlGetString(q, 1)));
    jRow = JsonObjectSet(jRow, "expires_at", JsonInt   (SqlGetInt   (q, 2)));
    return jRow;
}

// Returns current unix timestamp from SQLite (reliable cross-platform reference).
int IchorNow()
{
    sqlquery q = SqlPrepareQueryCampaign("ichor",
        "SELECT strftime('%s','now')");
    if(SqlStep(q)) return SqlGetInt(q, 0);
    return 0;
}
