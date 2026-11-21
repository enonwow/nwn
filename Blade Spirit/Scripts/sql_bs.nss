// Campaign DB name for all blade spirit data
const string BS_DB = "blade_spirit";

const int BS_CLASS_WARRIOR = 0;
const int BS_CLASS_MAGE    = 1;
const int BS_CLASS_ROGUE   = 2;
const int BS_CLASS_CLERIC  = 3;

const int BS_TIER_DORMANT    = 0;
const int BS_TIER_RESTLESS   = 1;
const int BS_TIER_ACTIVE     = 2;
const int BS_TIER_MANIFESTED = 3;

const int BS_KILLS_RESTLESS   = 10;
const int BS_KILLS_ACTIVE     = 25;
const int BS_KILLS_MANIFESTED = 50;

void BsCreateTables()
{
    sqlquery q = SqlPrepareQueryCampaign(BS_DB,
        "CREATE TABLE IF NOT EXISTS bs_spirits ("
        "item_uuid     TEXT PRIMARY KEY, "
        "spirit_name   TEXT NOT NULL DEFAULT '', "
        "spirit_class  INTEGER NOT NULL DEFAULT 0, "
        "kill_count    INTEGER NOT NULL DEFAULT 0, "
        "bound_at      INTEGER NOT NULL DEFAULT 0, "
        "appeased_at   INTEGER NOT NULL DEFAULT 0, "
        "manifested_at INTEGER NOT NULL DEFAULT 0)");
    SqlStep(q);
}

void BsBindSpirit(string sItemUUID, string sName, int nClass)
{
    sqlquery q = SqlPrepareQueryCampaign(BS_DB,
        "INSERT OR IGNORE INTO bs_spirits "
        "(item_uuid, spirit_name, spirit_class, bound_at) "
        "VALUES (@uuid, @name, @class, strftime('%s','now'))");
    SqlBindString(q, "@uuid",  sItemUUID);
    SqlBindString(q, "@name",  sName);
    SqlBindInt   (q, "@class", nClass);
    SqlStep(q);
}

json BsGetSpirit(string sItemUUID)
{
    sqlquery q = SqlPrepareQueryCampaign(BS_DB,
        "SELECT spirit_name, spirit_class, kill_count, bound_at, appeased_at, manifested_at "
        "FROM bs_spirits WHERE item_uuid = @uuid");
    SqlBindString(q, "@uuid", sItemUUID);
    if(!SqlStep(q)) return JsonNull();

    json j = JsonObject();
    j = JsonObjectSet(j, "spirit_name",   JsonString(SqlGetString(q, 0)));
    j = JsonObjectSet(j, "spirit_class",  JsonInt   (SqlGetInt   (q, 1)));
    j = JsonObjectSet(j, "kill_count",    JsonInt   (SqlGetInt   (q, 2)));
    j = JsonObjectSet(j, "bound_at",      JsonInt   (SqlGetInt   (q, 3)));
    j = JsonObjectSet(j, "appeased_at",   JsonInt   (SqlGetInt   (q, 4)));
    j = JsonObjectSet(j, "manifested_at", JsonInt   (SqlGetInt   (q, 5)));
    return j;
}

void BsIncrementKills(string sItemUUID)
{
    sqlquery q = SqlPrepareQueryCampaign(BS_DB,
        "UPDATE bs_spirits SET kill_count = kill_count + 1 WHERE item_uuid = @uuid");
    SqlBindString(q, "@uuid", sItemUUID);
    SqlStep(q);
}

void BsSetAppeased(string sItemUUID)
{
    sqlquery q = SqlPrepareQueryCampaign(BS_DB,
        "UPDATE bs_spirits SET appeased_at = strftime('%s','now') WHERE item_uuid = @uuid");
    SqlBindString(q, "@uuid", sItemUUID);
    SqlStep(q);
}

void BsSetManifested(string sItemUUID)
{
    sqlquery q = SqlPrepareQueryCampaign(BS_DB,
        "UPDATE bs_spirits SET manifested_at = strftime('%s','now') WHERE item_uuid = @uuid");
    SqlBindString(q, "@uuid", sItemUUID);
    SqlStep(q);
}

void BsDeleteSpirit(string sItemUUID)
{
    sqlquery q = SqlPrepareQueryCampaign(BS_DB,
        "DELETE FROM bs_spirits WHERE item_uuid = @uuid");
    SqlBindString(q, "@uuid", sItemUUID);
    SqlStep(q);
}

int BsGetTier(int nKills)
{
    if(nKills >= BS_KILLS_MANIFESTED) return BS_TIER_MANIFESTED;
    if(nKills >= BS_KILLS_ACTIVE)     return BS_TIER_ACTIVE;
    if(nKills >= BS_KILLS_RESTLESS)   return BS_TIER_RESTLESS;
    return BS_TIER_DORMANT;
}

// Returns TRUE if manifest was used within last 20 hours
int BsManifestOnCooldown(json jSpirit)
{
    int nAt = JsonGetInt(JsonObjectGet(jSpirit, "manifested_at"));
    if(nAt == 0) return FALSE;
    sqlquery q = SqlPrepareQueryCampaign(BS_DB,
        "SELECT (strftime('%s','now') - @ts) < 72000");
    SqlBindInt(q, "@ts", nAt);
    if(SqlStep(q)) return SqlGetInt(q, 0);
    return FALSE;
}

// Returns TRUE if spirit was appeased within last 6 hours
int BsIsAppeased(json jSpirit)
{
    int nAt = JsonGetInt(JsonObjectGet(jSpirit, "appeased_at"));
    if(nAt == 0) return FALSE;
    sqlquery q = SqlPrepareQueryCampaign(BS_DB,
        "SELECT (strftime('%s','now') - @ts) < 21600");
    SqlBindInt(q, "@ts", nAt);
    if(SqlStep(q)) return SqlGetInt(q, 0);
    return FALSE;
}

string BsSpiritClassName(int nClass)
{
    if(nClass == BS_CLASS_WARRIOR) return "Wojownik";
    if(nClass == BS_CLASS_MAGE)    return "Czarownik";
    if(nClass == BS_CLASS_ROGUE)   return "Łotrzyk";
    if(nClass == BS_CLASS_CLERIC)  return "Kapłan";
    return "Nieznany";
}

string BsTierName(int nTier)
{
    if(nTier == BS_TIER_DORMANT)    return "Uśpiony";
    if(nTier == BS_TIER_RESTLESS)   return "Niespokojny";
    if(nTier == BS_TIER_ACTIVE)     return "Aktywny";
    if(nTier == BS_TIER_MANIFESTED) return "Zmaterializowany";
    return "Nieznany";
}
