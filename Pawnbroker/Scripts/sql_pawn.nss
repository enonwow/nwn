// Persistent storage for the Lombard (Pawnbroker) module.
// Campaign DB: "pawnbroker"

const int PAWN_EXPIRY_DAYS      = 7;
const int PAWN_INTEREST_PCT_DAY = 10;   // % of base loan per day elapsed
const int PAWN_MAX_ACTIVE       = 10;   // items a single PC may have in pawn at once

void PawnCreateTables()
{
    sqlquery q = SqlPrepareQueryCampaign("pawnbroker",
        "CREATE TABLE IF NOT EXISTS pawn_items ("
        "  id          INTEGER PRIMARY KEY AUTOINCREMENT,"
        "  owner_uuid  TEXT    NOT NULL,"
        "  item_json   TEXT    NOT NULL,"
        "  item_name   TEXT    DEFAULT '',"
        "  base_loan   INTEGER DEFAULT 0,"
        "  pawned_at   INTEGER DEFAULT 0,"
        "  is_redeemed INTEGER DEFAULT 0"
        ")");
    SqlStep(q);
}

int PawnInsert(string sOwnerUuid, json jItemJson, string sItemName, int nBaseLoan)
{
    sqlquery q = SqlPrepareQueryCampaign("pawnbroker",
        "INSERT INTO pawn_items"
        "  (owner_uuid, item_json, item_name, base_loan, pawned_at)"
        "  VALUES (@uuid, @item, @name, @loan, strftime('%s','now'))");
    SqlBindString(q, "@uuid", sOwnerUuid);
    SqlBindString(q, "@item", JsonDump(jItemJson));
    SqlBindString(q, "@name", sItemName);
    SqlBindInt   (q, "@loan", nBaseLoan);
    SqlStep(q);
    sqlquery qId = SqlPrepareQueryCampaign("pawnbroker", "SELECT last_insert_rowid()");
    if(SqlStep(qId)) return SqlGetInt(qId, 0);
    return 0;
}

// Returns JsonArray of active (not redeemed) pawns for a PC.
// Each element: {id, name, base_loan, redeem_cost, days_elapsed, days_left, is_expired}
json PawnGetActive(string sOwnerUuid)
{
    json jRows = JsonArray();
    sqlquery q = SqlPrepareQueryCampaign("pawnbroker",
        "SELECT id, item_name, base_loan, pawned_at,"
        "  CAST((strftime('%s','now') - pawned_at) / 86400 AS INTEGER) AS days_elapsed"
        " FROM pawn_items"
        " WHERE owner_uuid = @uuid AND is_redeemed = 0"
        " ORDER BY pawned_at ASC");
    SqlBindString(q, "@uuid", sOwnerUuid);
    while(SqlStep(q))
    {
        int nId        = SqlGetInt(q, 0);
        string sName   = SqlGetString(q, 1);
        int nLoan      = SqlGetInt(q, 2);
        int nDays      = SqlGetInt(q, 4);
        // Cost = loan + loan * interest_pct * days / 100 (minimum = loan)
        int nCost      = nLoan + nLoan * PAWN_INTEREST_PCT_DAY * nDays / 100;
        int nDaysLeft  = PAWN_EXPIRY_DAYS - nDays;
        int nExpired   = (nDays >= PAWN_EXPIRY_DAYS) ? 1 : 0;

        json jRow = JsonObject();
        jRow = JsonObjectSet(jRow, "id",           JsonInt   (nId));
        jRow = JsonObjectSet(jRow, "name",         JsonString(sName));
        jRow = JsonObjectSet(jRow, "base_loan",    JsonInt   (nLoan));
        jRow = JsonObjectSet(jRow, "redeem_cost",  JsonInt   (nCost));
        jRow = JsonObjectSet(jRow, "days_elapsed", JsonInt   (nDays));
        jRow = JsonObjectSet(jRow, "days_left",    JsonInt   (nDaysLeft));
        jRow = JsonObjectSet(jRow, "is_expired",   JsonInt   (nExpired));
        jRows = JsonArrayInsert(jRows, jRow);
    }
    return jRows;
}

// Returns a single pawn record with the serialised item, or JsonNull().
json PawnGetItem(int nId)
{
    sqlquery q = SqlPrepareQueryCampaign("pawnbroker",
        "SELECT id, owner_uuid, item_json, item_name, base_loan, pawned_at,"
        "  CAST((strftime('%s','now') - pawned_at) / 86400 AS INTEGER) AS days_elapsed"
        " FROM pawn_items WHERE id = @id AND is_redeemed = 0");
    SqlBindInt(q, "@id", nId);
    if(!SqlStep(q)) return JsonNull();

    int nDays = SqlGetInt(q, 6);
    int nLoan = SqlGetInt(q, 4);
    int nCost = nLoan + nLoan * PAWN_INTEREST_PCT_DAY * nDays / 100;

    json jItem = JsonObject();
    jItem = JsonObjectSet(jItem, "id",           JsonInt   (SqlGetInt   (q, 0)));
    jItem = JsonObjectSet(jItem, "owner_uuid",   JsonString(SqlGetString(q, 1)));
    jItem = JsonObjectSet(jItem, "item_json",    JsonParse (SqlGetString(q, 2)));
    jItem = JsonObjectSet(jItem, "item_name",    JsonString(SqlGetString(q, 3)));
    jItem = JsonObjectSet(jItem, "base_loan",    JsonInt   (nLoan));
    jItem = JsonObjectSet(jItem, "redeem_cost",  JsonInt   (nCost));
    jItem = JsonObjectSet(jItem, "days_elapsed", JsonInt   (nDays));
    jItem = JsonObjectSet(jItem, "is_expired",   JsonInt   ((nDays >= PAWN_EXPIRY_DAYS) ? 1 : 0));
    return jItem;
}

void PawnMarkRedeemed(int nId)
{
    sqlquery q = SqlPrepareQueryCampaign("pawnbroker",
        "UPDATE pawn_items SET is_redeemed = 1 WHERE id = @id");
    SqlBindInt(q, "@id", nId);
    SqlStep(q);
}

int PawnCountActive(string sOwnerUuid)
{
    sqlquery q = SqlPrepareQueryCampaign("pawnbroker",
        "SELECT COUNT(*) FROM pawn_items WHERE owner_uuid = @uuid AND is_redeemed = 0");
    SqlBindString(q, "@uuid", sOwnerUuid);
    if(SqlStep(q)) return SqlGetInt(q, 0);
    return 0;
}

// Returns all unredeemed items across all players (DM view).
json PawnGetAll()
{
    json jRows = JsonArray();
    sqlquery q = SqlPrepareQueryCampaign("pawnbroker",
        "SELECT id, owner_uuid, item_name, base_loan, pawned_at,"
        "  CAST((strftime('%s','now') - pawned_at) / 86400 AS INTEGER) AS days_elapsed"
        " FROM pawn_items WHERE is_redeemed = 0"
        " ORDER BY pawned_at ASC");
    while(SqlStep(q))
    {
        int nDays = SqlGetInt(q, 5);
        int nLoan = SqlGetInt(q, 3);
        json jRow = JsonObject();
        jRow = JsonObjectSet(jRow, "id",           JsonInt   (SqlGetInt   (q, 0)));
        jRow = JsonObjectSet(jRow, "owner_uuid",   JsonString(SqlGetString(q, 1)));
        jRow = JsonObjectSet(jRow, "name",         JsonString(SqlGetString(q, 2)));
        jRow = JsonObjectSet(jRow, "base_loan",    JsonInt   (nLoan));
        jRow = JsonObjectSet(jRow, "days_elapsed", JsonInt   (nDays));
        jRow = JsonObjectSet(jRow, "is_expired",   JsonInt   ((nDays >= PAWN_EXPIRY_DAYS) ? 1 : 0));
        jRows = JsonArrayInsert(jRows, jRow);
    }
    return jRows;
}
