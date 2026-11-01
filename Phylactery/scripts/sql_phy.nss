const int PHY_DEFAULT_CHARGES  = 3;
const int PHY_MAX_CHARGES      = 9;
const int PHY_CREATE_GOLD_COST = 250;
const int PHY_EMPOWER_GOLD_COST= 500;
const int PHY_HISTORY_MAX      = 10;
const int PHY_RESURRECT_HP_PCT = 25;
const int PHY_SHATTER_SAVES    = 2;
const int PHY_SHATTER_DURATION = 3600;

void PhyCreateTables()
{
    sqlquery q = SqlPrepareQueryCampaign("phylactery",
        "CREATE TABLE IF NOT EXISTS phy_phylacteries ("
        + "uuid TEXT PRIMARY KEY, "
        + "charges INTEGER DEFAULT 3, "
        + "max_charges INTEGER DEFAULT 9, "
        + "is_active INTEGER DEFAULT 0, "
        + "anchor_area TEXT DEFAULT '', "
        + "anchor_x REAL DEFAULT 0.0, "
        + "anchor_y REAL DEFAULT 0.0, "
        + "anchor_z REAL DEFAULT 0.0, "
        + "anchor_facing REAL DEFAULT 0.0, "
        + "anchor_area_name TEXT DEFAULT '', "
        + "created_at INTEGER DEFAULT 0, "
        + "anchor_at INTEGER DEFAULT 0)");
    SqlStep(q);

    q = SqlPrepareQueryCampaign("phylactery",
        "CREATE TABLE IF NOT EXISTS phy_resurrections ("
        + "id INTEGER PRIMARY KEY AUTOINCREMENT, "
        + "owner_uuid TEXT NOT NULL, "
        + "killed_by TEXT DEFAULT 'nieznane', "
        + "area_name TEXT DEFAULT '', "
        + "resurrect_at INTEGER DEFAULT 0)");
    SqlStep(q);
}

int PhyHasPhylactery(object oPC)
{
    sqlquery q = SqlPrepareQueryCampaign("phylactery",
        "SELECT is_active FROM phy_phylacteries WHERE uuid = @uuid");
    SqlBindString(q, "@uuid", GetObjectUUID(oPC));
    if(SqlStep(q)) return SqlGetInt(q, 0);
    return 0;
}

// Returns NULL json if no record exists
json PhyGetRecord(object oPC)
{
    sqlquery q = SqlPrepareQueryCampaign("phylactery",
        "SELECT charges, max_charges, is_active, anchor_area, anchor_x, anchor_y, anchor_z, "
        + "anchor_facing, anchor_area_name, created_at, anchor_at "
        + "FROM phy_phylacteries WHERE uuid = @uuid");
    SqlBindString(q, "@uuid", GetObjectUUID(oPC));
    if(!SqlStep(q)) return JsonNull();
    json j = JsonObject();
    j = JsonObjectSet(j, "charges",          JsonInt   (SqlGetInt   (q, 0)));
    j = JsonObjectSet(j, "max_charges",      JsonInt   (SqlGetInt   (q, 1)));
    j = JsonObjectSet(j, "is_active",        JsonInt   (SqlGetInt   (q, 2)));
    j = JsonObjectSet(j, "anchor_area",      JsonString(SqlGetString(q, 3)));
    j = JsonObjectSet(j, "anchor_x",         JsonFloat (SqlGetFloat (q, 4)));
    j = JsonObjectSet(j, "anchor_y",         JsonFloat (SqlGetFloat (q, 5)));
    j = JsonObjectSet(j, "anchor_z",         JsonFloat (SqlGetFloat (q, 6)));
    j = JsonObjectSet(j, "anchor_facing",    JsonFloat (SqlGetFloat (q, 7)));
    j = JsonObjectSet(j, "anchor_area_name", JsonString(SqlGetString(q, 8)));
    j = JsonObjectSet(j, "created_at",       JsonInt   (SqlGetInt   (q, 9)));
    j = JsonObjectSet(j, "anchor_at",        JsonInt   (SqlGetInt   (q, 10)));
    return j;
}

void PhyCreateRecord(object oPC)
{
    sqlquery q = SqlPrepareQueryCampaign("phylactery",
        "INSERT OR IGNORE INTO phy_phylacteries "
        + "(uuid, charges, max_charges, is_active, created_at) "
        + "VALUES (@uuid, @ch, @max, 1, strftime('%s','now'))");
    SqlBindString(q, "@uuid", GetObjectUUID(oPC));
    SqlBindInt   (q, "@ch",   PHY_DEFAULT_CHARGES);
    SqlBindInt   (q, "@max",  PHY_MAX_CHARGES);
    SqlStep(q);
}

void PhyAnchorLocation(object oPC, object oArea, float fX, float fY, float fZ, float fFacing)
{
    sqlquery q = SqlPrepareQueryCampaign("phylactery",
        "UPDATE phy_phylacteries SET "
        + "anchor_area = @area, anchor_x = @x, anchor_y = @y, anchor_z = @z, "
        + "anchor_facing = @facing, anchor_area_name = @aname, "
        + "anchor_at = strftime('%s','now') "
        + "WHERE uuid = @uuid");
    SqlBindString(q, "@uuid",   GetObjectUUID(oPC));
    SqlBindString(q, "@area",   GetTag(oArea));
    SqlBindFloat (q, "@x",      fX);
    SqlBindFloat (q, "@y",      fY);
    SqlBindFloat (q, "@z",      fZ);
    SqlBindFloat (q, "@facing", fFacing);
    SqlBindString(q, "@aname",  GetName(oArea));
    SqlStep(q);
}

// Returns TRUE if a charge was consumed, FALSE if phylactery is inactive/empty
int PhyConsumeCharge(object oPC)
{
    json jRec = PhyGetRecord(oPC);
    if(JsonGetType(jRec) == JSON_TYPE_NULL)                return FALSE;
    if(!JsonGetInt(JsonObjectGet(jRec, "is_active")))      return FALSE;
    if(!JsonGetInt(JsonObjectGet(jRec, "charges")))        return FALSE;
    if(JsonGetString(JsonObjectGet(jRec, "anchor_area")) == "") return FALSE;

    int nNew    = JsonGetInt(JsonObjectGet(jRec, "charges")) - 1;
    int nActive = (nNew > 0) ? 1 : 0;
    sqlquery q = SqlPrepareQueryCampaign("phylactery",
        "UPDATE phy_phylacteries SET charges = @ch, is_active = @act WHERE uuid = @uuid");
    SqlBindInt   (q, "@ch",   nNew);
    SqlBindInt   (q, "@act",  nActive);
    SqlBindString(q, "@uuid", GetObjectUUID(oPC));
    SqlStep(q);
    return TRUE;
}

void PhyAddCharge(object oPC, int nCount)
{
    sqlquery q = SqlPrepareQueryCampaign("phylactery",
        "UPDATE phy_phylacteries "
        + "SET charges = MIN(charges + @n, @max), is_active = 1 "
        + "WHERE uuid = @uuid");
    SqlBindInt   (q, "@n",    nCount);
    SqlBindInt   (q, "@max",  PHY_MAX_CHARGES);
    SqlBindString(q, "@uuid", GetObjectUUID(oPC));
    SqlStep(q);
}

void PhyDestroyRecord(object oPC)
{
    sqlquery q = SqlPrepareQueryCampaign("phylactery",
        "DELETE FROM phy_phylacteries WHERE uuid = @uuid");
    SqlBindString(q, "@uuid", GetObjectUUID(oPC));
    SqlStep(q);
}

void PhyLogResurrection(object oPC, string sKilledBy, string sAreaName)
{
    sqlquery q = SqlPrepareQueryCampaign("phylactery",
        "INSERT INTO phy_resurrections (owner_uuid, killed_by, area_name, resurrect_at) "
        + "VALUES (@uuid, @killer, @area, strftime('%s','now'))");
    SqlBindString(q, "@uuid",   GetObjectUUID(oPC));
    SqlBindString(q, "@killer", sKilledBy);
    SqlBindString(q, "@area",   sAreaName);
    SqlStep(q);
}

json PhyGetResurrectionHistory(object oPC)
{
    json jRows = JsonArray();
    sqlquery q = SqlPrepareQueryCampaign("phylactery",
        "SELECT killed_by, area_name, resurrect_at "
        + "FROM phy_resurrections WHERE owner_uuid = @uuid "
        + "ORDER BY resurrect_at DESC LIMIT @lim");
    SqlBindString(q, "@uuid", GetObjectUUID(oPC));
    SqlBindInt   (q, "@lim",  PHY_HISTORY_MAX);
    while(SqlStep(q))
    {
        json jRow = JsonObject();
        jRow = JsonObjectSet(jRow, "killed_by",    JsonString(SqlGetString(q, 0)));
        jRow = JsonObjectSet(jRow, "area_name",    JsonString(SqlGetString(q, 1)));
        jRow = JsonObjectSet(jRow, "resurrect_at", JsonInt   (SqlGetInt   (q, 2)));
        jRows = JsonArrayInsert(jRows, jRow);
    }
    return jRows;
}

string PhyFormatDate(int nUnix)
{
    if(nUnix <= 0) return "-";
    sqlquery q = SqlPrepareQueryCampaign("phylactery",
        "SELECT strftime('%d.%m %H:%M', @ts, 'unixepoch')");
    SqlBindInt(q, "@ts", nUnix);
    if(SqlStep(q)) return SqlGetString(q, 0);
    return "-";
}
