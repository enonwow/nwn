// Corruption tiers used by BcnIsKindled and callers
const int BCN_CORR_CLEAN = 0;
const int BCN_CORR_FAINT = 1;
const int BCN_CORR_HEAVY = 2;
const int BCN_CORR_OUT   = 3;

void BcnCreateTables()
{
    sqlquery q = SqlPrepareQueryCampaign("beacons",
        "CREATE TABLE IF NOT EXISTS bcn_beacons ("
        "  tag TEXT PRIMARY KEY,"
        "  area_name TEXT DEFAULT '',"
        "  beacon_type TEXT DEFAULT 'fire',"
        "  kindled_by TEXT DEFAULT '',"
        "  kindle_time INTEGER DEFAULT 0,"
        "  corruption INTEGER DEFAULT 0,"
        "  is_active INTEGER DEFAULT 1"
        ")");
    SqlStep(q);

    q = SqlPrepareQueryCampaign("beacons",
        "CREATE TABLE IF NOT EXISTS bcn_known ("
        "  player_uuid TEXT NOT NULL,"
        "  beacon_tag TEXT NOT NULL,"
        "  first_visited INTEGER DEFAULT 0,"
        "  rest_count INTEGER DEFAULT 0,"
        "  last_rest INTEGER DEFAULT 0,"
        "  PRIMARY KEY (player_uuid, beacon_tag)"
        ")");
    SqlStep(q);
}

// Returns JSON object with beacon row, or JsonNull() when not found
json BcnGetBeacon(string sTag)
{
    sqlquery q = SqlPrepareQueryCampaign("beacons",
        "SELECT tag, area_name, beacon_type, kindled_by, kindle_time, corruption, is_active "
        "FROM bcn_beacons WHERE tag = @tag");
    SqlBindString(q, "@tag", sTag);
    if(!SqlStep(q)) return JsonNull();

    json jB = JsonObject();
    jB = JsonObjectSet(jB, "tag",         JsonString(SqlGetString(q, 0)));
    jB = JsonObjectSet(jB, "area_name",   JsonString(SqlGetString(q, 1)));
    jB = JsonObjectSet(jB, "beacon_type", JsonString(SqlGetString(q, 2)));
    jB = JsonObjectSet(jB, "kindled_by",  JsonString(SqlGetString(q, 3)));
    jB = JsonObjectSet(jB, "kindle_time", JsonInt   (SqlGetInt   (q, 4)));
    jB = JsonObjectSet(jB, "corruption",  JsonInt   (SqlGetInt   (q, 5)));
    jB = JsonObjectSet(jB, "is_active",   JsonInt   (SqlGetInt   (q, 6)));
    return jB;
}

// Creates the row if it does not exist yet; idempotent
void BcnEnsureRecord(string sTag, string sAreaName, string sType)
{
    sqlquery q = SqlPrepareQueryCampaign("beacons",
        "INSERT OR IGNORE INTO bcn_beacons (tag, area_name, beacon_type) "
        "VALUES (@tag, @area, @type)");
    SqlBindString(q, "@tag",  sTag);
    SqlBindString(q, "@area", sAreaName);
    SqlBindString(q, "@type", sType);
    SqlStep(q);
}

void BcnKindle(string sTag, string sPlayerName)
{
    sqlquery q = SqlPrepareQueryCampaign("beacons",
        "UPDATE bcn_beacons "
        "SET kindled_by = @name, kindle_time = strftime('%s','now'), corruption = 0 "
        "WHERE tag = @tag");
    SqlBindString(q, "@name", sPlayerName);
    SqlBindString(q, "@tag",  sTag);
    SqlStep(q);
}

// Advances corruption by 1 step, capped at BCN_CORR_OUT
void BcnCorrupt(string sTag)
{
    sqlquery q = SqlPrepareQueryCampaign("beacons",
        "UPDATE bcn_beacons SET corruption = MIN(corruption + 1, 3) WHERE tag = @tag");
    SqlBindString(q, "@tag", sTag);
    SqlStep(q);
}

// Reduces corruption by 1 step, floored at BCN_CORR_CLEAN
void BcnPurify(string sTag)
{
    sqlquery q = SqlPrepareQueryCampaign("beacons",
        "UPDATE bcn_beacons SET corruption = MAX(corruption - 1, 0) WHERE tag = @tag");
    SqlBindString(q, "@tag", sTag);
    SqlStep(q);
}

// Returns TRUE when beacon has been kindled and is not yet extinguished
int BcnIsKindled(string sTag)
{
    sqlquery q = SqlPrepareQueryCampaign("beacons",
        "SELECT kindle_time, corruption FROM bcn_beacons WHERE tag = @tag");
    SqlBindString(q, "@tag", sTag);
    if(!SqlStep(q)) return FALSE;
    return (SqlGetInt(q, 0) > 0 && SqlGetInt(q, 1) < BCN_CORR_OUT);
}

// Registers first visit; second call is a no-op due to INSERT OR IGNORE
void BcnLearnBeacon(string sPlayerUuid, string sTag)
{
    if(sTag == "") return;
    sqlquery q = SqlPrepareQueryCampaign("beacons",
        "INSERT OR IGNORE INTO bcn_known (player_uuid, beacon_tag, first_visited) "
        "VALUES (@uuid, @tag, strftime('%s','now'))");
    SqlBindString(q, "@uuid", sPlayerUuid);
    SqlBindString(q, "@tag",  sTag);
    SqlStep(q);
}

// Returns UTC unix timestamp of the last rest, or 0 if never rested
int BcnGetLastRest(string sPlayerUuid, string sTag)
{
    sqlquery q = SqlPrepareQueryCampaign("beacons",
        "SELECT last_rest FROM bcn_known WHERE player_uuid = @uuid AND beacon_tag = @tag");
    SqlBindString(q, "@uuid", sPlayerUuid);
    SqlBindString(q, "@tag",  sTag);
    if(SqlStep(q)) return SqlGetInt(q, 0);
    return 0;
}

void BcnRecordRest(string sPlayerUuid, string sTag)
{
    sqlquery q = SqlPrepareQueryCampaign("beacons",
        "UPDATE bcn_known "
        "SET last_rest = strftime('%s','now'), rest_count = rest_count + 1 "
        "WHERE player_uuid = @uuid AND beacon_tag = @tag");
    SqlBindString(q, "@uuid", sPlayerUuid);
    SqlBindString(q, "@tag",  sTag);
    SqlStep(q);
}

// Returns JSON array of known beacons for a player, ordered by first visit
// Each element: {tag, area_name, beacon_type, kindled_by, corruption, rest_count}
json BcnGetKnownBeacons(string sPlayerUuid)
{
    json jRows = JsonArray();
    sqlquery q = SqlPrepareQueryCampaign("beacons",
        "SELECT b.tag, b.area_name, b.beacon_type, b.kindled_by, b.corruption, k.rest_count "
        "FROM bcn_known k JOIN bcn_beacons b ON k.beacon_tag = b.tag "
        "WHERE k.player_uuid = @uuid ORDER BY k.first_visited ASC");
    SqlBindString(q, "@uuid", sPlayerUuid);
    while(SqlStep(q))
    {
        json jRow = JsonObject();
        jRow = JsonObjectSet(jRow, "tag",         JsonString(SqlGetString(q, 0)));
        jRow = JsonObjectSet(jRow, "area_name",   JsonString(SqlGetString(q, 1)));
        jRow = JsonObjectSet(jRow, "beacon_type", JsonString(SqlGetString(q, 2)));
        jRow = JsonObjectSet(jRow, "kindled_by",  JsonString(SqlGetString(q, 3)));
        jRow = JsonObjectSet(jRow, "corruption",  JsonInt   (SqlGetInt   (q, 4)));
        jRow = JsonObjectSet(jRow, "rest_count",  JsonInt   (SqlGetInt   (q, 5)));
        jRows = JsonArrayInsert(jRows, jRow);
    }
    return jRows;
}

// Returns current UTC unix timestamp from SQLite
int BcnNow()
{
    sqlquery q = SqlPrepareQueryCampaign("beacons", "SELECT strftime('%s','now')");
    if(SqlStep(q)) return SqlGetInt(q, 0);
    return 0;
}
