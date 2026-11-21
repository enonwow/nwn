// ----------------------------------------------------------------
// Schema
// ----------------------------------------------------------------

void BmtCreateTables()
{
    sqlquery q;

    q = SqlPrepareQueryCampaign("blackmarket",
        "CREATE TABLE IF NOT EXISTS bmt_catalog ("
        "id        INTEGER PRIMARY KEY AUTOINCREMENT, "
        "resref    TEXT    NOT NULL, "
        "item_name TEXT    NOT NULL, "
        "flavor    TEXT    DEFAULT '', "
        "base_gold INTEGER DEFAULT 100, "
        "max_stack INTEGER DEFAULT 1)");
    SqlStep(q);

    q = SqlPrepareQueryCampaign("blackmarket",
        "CREATE TABLE IF NOT EXISTS bmt_stock ("
        "id             INTEGER PRIMARY KEY AUTOINCREMENT, "
        "catalog_id     INTEGER NOT NULL, "
        "qty_available  INTEGER DEFAULT 1, "
        "expires_at     INTEGER DEFAULT 0)");
    SqlStep(q);

    q = SqlPrepareQueryCampaign("blackmarket",
        "CREATE TABLE IF NOT EXISTS bmt_player ("
        "uuid       TEXT    PRIMARY KEY, "
        "heat       INTEGER DEFAULT 0, "
        "last_decay INTEGER DEFAULT 0)");
    SqlStep(q);
}

// Populates bmt_catalog with starter items; idempotent (skips if already seeded).
// All resrefs below are from standard NWN — replace with hak items as needed.
void BmtSeedCatalog()
{
    sqlquery qc = SqlPrepareQueryCampaign("blackmarket",
        "SELECT COUNT(*) FROM bmt_catalog");
    if(SqlStep(qc) && SqlGetInt(qc, 0) > 0) return;

    sqlquery q;
    q = SqlPrepareQueryCampaign("blackmarket",
        "INSERT INTO bmt_catalog (resref,item_name,flavor,base_gold,max_stack) VALUES "
        "('nw_it_mpotion001','Wywar z Czarnego Lotosu',"
        "'Zostawia ciemna plame na ustach. Nikt nie pyta po co.',80,3)");
    SqlStep(q);

    q = SqlPrepareQueryCampaign("blackmarket",
        "INSERT INTO bmt_catalog (resref,item_name,flavor,base_gold,max_stack) VALUES "
        "('nw_it_mpotion002','Eliksir Nocnego Widzenia',"
        "'Zrenice rozszerzaja sie jak przepasc. Dzialanie kilka godzin.',60,5)");
    SqlStep(q);

    q = SqlPrepareQueryCampaign("blackmarket",
        "INSERT INTO bmt_catalog (resref,item_name,flavor,base_gold,max_stack) VALUES "
        "('nw_it_mpotion007','Wywar Zelaznej Woli',"
        "'Smakuje jak rdza i krew wrogow.',120,2)");
    SqlStep(q);

    q = SqlPrepareQueryCampaign("blackmarket",
        "INSERT INTO bmt_catalog (resref,item_name,flavor,base_gold,max_stack) VALUES "
        "('nw_it_mpotion010','Mikstura Czarnej Krwi',"
        "'Lepka. Gesta. Obiecuje rzeczy, ktorych legalny handel nie moze.',150,3)");
    SqlStep(q);

    q = SqlPrepareQueryCampaign("blackmarket",
        "INSERT INTO bmt_catalog (resref,item_name,flavor,base_gold,max_stack) VALUES "
        "('nw_it_mpotion014','Wyciag z Pajaka Cieni',"
        "'Bol mija. Refleks zostaje.',110,4)");
    SqlStep(q);

    q = SqlPrepareQueryCampaign("blackmarket",
        "INSERT INTO bmt_catalog (resref,item_name,flavor,base_gold,max_stack) VALUES "
        "('nw_it_mpotion018','Eliksir Odwagi Tchórza',"
        "'Dziala przez piec minut. Czasem.',50,5)");
    SqlStep(q);

    q = SqlPrepareQueryCampaign("blackmarket",
        "INSERT INTO bmt_catalog (resref,item_name,flavor,base_gold,max_stack) VALUES "
        "('nw_it_sparscr009','Zwoj Lewitacji',"
        "'Skradzione z biblioteki klasztornej. Pieczen jeszcze niemal nienaruszona.',70,2)");
    SqlStep(q);

    q = SqlPrepareQueryCampaign("blackmarket",
        "INSERT INTO bmt_catalog (resref,item_name,flavor,base_gold,max_stack) VALUES "
        "('nw_it_sparscr010','Zwoj Niewidzialnosci',"
        "'Nielegalny w dziewieciu miastach. W dziesiatym - drogi.',200,1)");
    SqlStep(q);

    q = SqlPrepareQueryCampaign("blackmarket",
        "INSERT INTO bmt_catalog (resref,item_name,flavor,base_gold,max_stack) VALUES "
        "('nw_it_sparscr013','Zwoj Ciemnosci',"
        "'Mrok mozna kupic za odpowiednia cene.',90,2)");
    SqlStep(q);

    q = SqlPrepareQueryCampaign("blackmarket",
        "INSERT INTO bmt_catalog (resref,item_name,flavor,base_gold,max_stack) VALUES "
        "('nw_it_sparscr503','Zwoj Przywolania Cienia',"
        "'Pergamin drzacy. Atrament brazowy od rdzy lub czegos gorszego.',180,1)");
    SqlStep(q);

    q = SqlPrepareQueryCampaign("blackmarket",
        "INSERT INTO bmt_catalog (resref,item_name,flavor,base_gold,max_stack) VALUES "
        "('nw_it_mpotion019','Antidotum Plemienna',"
        "'Warzone przez wioskowego szamana. Skuteczne. Bez certyfikatu.',65,4)");
    SqlStep(q);

    q = SqlPrepareQueryCampaign("blackmarket",
        "INSERT INTO bmt_catalog (resref,item_name,flavor,base_gold,max_stack) VALUES "
        "('nw_it_mpotion008','Trunek Szepczacego Boga',"
        "'Smak popiolu i obietnicy. Kaplani protestowali.',250,1)");
    SqlStep(q);
}

// Fills bmt_stock with a random draw from catalog; noop if stock is still valid.
void BmtRefreshStock()
{
    sqlquery qExp = SqlPrepareQueryCampaign("blackmarket",
        "SELECT COUNT(*) FROM bmt_stock "
        "WHERE qty_available > 0 AND expires_at > strftime('%s','now')");
    if(SqlStep(qExp) && SqlGetInt(qExp, 0) > 0) return;

    SqlStep(SqlPrepareQueryCampaign("blackmarket", "DELETE FROM bmt_stock"));

    sqlquery qFill = SqlPrepareQueryCampaign("blackmarket",
        "INSERT INTO bmt_stock (catalog_id, qty_available, expires_at) "
        "SELECT id, max_stack, strftime('%s','now') + @secs "
        "FROM bmt_catalog ORDER BY RANDOM() LIMIT @cnt");
    SqlBindInt(qFill, "@secs", BMT_REFRESH_SECS);
    SqlBindInt(qFill, "@cnt",  BMT_STOCK_COUNT);
    SqlStep(qFill);
}

// Returns JsonArray [{id, item_name, flavor, base_gold, qty}, ...] for current stock.
json BmtGetStock()
{
    json jRows = JsonArray();
    sqlquery q = SqlPrepareQueryCampaign("blackmarket",
        "SELECT s.id, c.item_name, c.flavor, c.base_gold, s.qty_available "
        "FROM bmt_stock s JOIN bmt_catalog c ON s.catalog_id = c.id "
        "WHERE s.qty_available > 0 AND s.expires_at > strftime('%s','now') "
        "ORDER BY s.id");
    while(SqlStep(q))
    {
        json jRow = JsonObject();
        jRow = JsonObjectSet(jRow, "id",        JsonInt   (SqlGetInt   (q, 0)));
        jRow = JsonObjectSet(jRow, "item_name", JsonString(SqlGetString(q, 1)));
        jRow = JsonObjectSet(jRow, "flavor",    JsonString(SqlGetString(q, 2)));
        jRow = JsonObjectSet(jRow, "base_gold", JsonInt   (SqlGetInt   (q, 3)));
        jRow = JsonObjectSet(jRow, "qty",       JsonInt   (SqlGetInt   (q, 4)));
        jRows = JsonArrayInsert(jRows, jRow);
    }
    return jRows;
}

// Returns JsonObject {id, resref, item_name, base_gold, qty} or JsonNull.
json BmtGetStockItem(int nStockId)
{
    sqlquery q = SqlPrepareQueryCampaign("blackmarket",
        "SELECT s.id, c.resref, c.item_name, c.base_gold, s.qty_available "
        "FROM bmt_stock s JOIN bmt_catalog c ON s.catalog_id = c.id "
        "WHERE s.id = @id");
    SqlBindInt(q, "@id", nStockId);
    if(!SqlStep(q)) return JsonNull();
    json j = JsonObject();
    j = JsonObjectSet(j, "id",        JsonInt   (SqlGetInt   (q, 0)));
    j = JsonObjectSet(j, "resref",    JsonString(SqlGetString(q, 1)));
    j = JsonObjectSet(j, "item_name", JsonString(SqlGetString(q, 2)));
    j = JsonObjectSet(j, "base_gold", JsonInt   (SqlGetInt   (q, 3)));
    j = JsonObjectSet(j, "qty",       JsonInt   (SqlGetInt   (q, 4)));
    return j;
}

void BmtDeductStock(int nStockId)
{
    sqlquery q = SqlPrepareQueryCampaign("blackmarket",
        "UPDATE bmt_stock SET qty_available = qty_available - 1 WHERE id = @id");
    SqlBindInt(q, "@id", nStockId);
    SqlStep(q);
}

// Returns seconds until stock expires; negative if already expired.
int BmtGetSecondsToRefresh()
{
    sqlquery q = SqlPrepareQueryCampaign("blackmarket",
        "SELECT CAST(MAX(expires_at) - strftime('%s','now') AS INTEGER) FROM bmt_stock");
    if(SqlStep(q)) return SqlGetInt(q, 0);
    return 0;
}

void BmtRegisterPlayer(string sUuid)
{
    sqlquery q = SqlPrepareQueryCampaign("blackmarket",
        "INSERT OR IGNORE INTO bmt_player (uuid, heat, last_decay) "
        "VALUES (@uuid, 0, strftime('%s','now'))");
    SqlBindString(q, "@uuid", sUuid);
    SqlStep(q);
}

int BmtGetHeat(string sUuid)
{
    sqlquery q = SqlPrepareQueryCampaign("blackmarket",
        "SELECT heat FROM bmt_player WHERE uuid = @uuid");
    SqlBindString(q, "@uuid", sUuid);
    if(SqlStep(q)) return SqlGetInt(q, 0);
    return 0;
}

void BmtAddHeat(string sUuid, int nAmount)
{
    sqlquery q = SqlPrepareQueryCampaign("blackmarket",
        "UPDATE bmt_player SET heat = MIN(100, heat + @amt) WHERE uuid = @uuid");
    SqlBindInt   (q, "@amt",  nAmount);
    SqlBindString(q, "@uuid", sUuid);
    SqlStep(q);
}

// Calculates real hours elapsed since last_decay, removes that heat, advances timestamp.
void BmtDecayHeat(string sUuid)
{
    sqlquery qEl = SqlPrepareQueryCampaign("blackmarket",
        "SELECT CAST((strftime('%s','now') - last_decay) / 3600 AS INTEGER) "
        "FROM bmt_player WHERE uuid = @uuid");
    SqlBindString(qEl, "@uuid", sUuid);
    if(!SqlStep(qEl)) return;
    int nHours = SqlGetInt(qEl, 0);
    if(nHours <= 0) return;

    sqlquery q = SqlPrepareQueryCampaign("blackmarket",
        "UPDATE bmt_player "
        "SET heat       = MAX(0, heat - @decay), "
        "    last_decay = last_decay + @hours * 3600 "
        "WHERE uuid = @uuid");
    SqlBindInt   (q, "@decay", nHours * BMT_HEAT_DECAY_HOUR);
    SqlBindInt   (q, "@hours", nHours);
    SqlBindString(q, "@uuid",  sUuid);
    SqlStep(q);
}
