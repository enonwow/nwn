// sql_hom.nss — persistence layer for the Homunculus module
// Campaign DB name: "homunculus"

void HomCreateTables()
{
    sqlquery q = SqlPrepareQueryCampaign("homunculus",
        "CREATE TABLE IF NOT EXISTS hom_companions ("
        " owner_uuid TEXT PRIMARY KEY,"
        " name       TEXT    DEFAULT 'Bezimienny',"
        " bond_level INTEGER DEFAULT 1,"
        " last_fed   INTEGER DEFAULT 0,"
        " last_used  INTEGER DEFAULT 0,"
        " tasks_done INTEGER DEFAULT 0,"
        " created_at INTEGER DEFAULT 0,"
        " is_alive   INTEGER DEFAULT 1"
        ")");
    SqlStep(q);

    q = SqlPrepareQueryCampaign("homunculus",
        "CREATE TABLE IF NOT EXISTS hom_log ("
        " id         INTEGER PRIMARY KEY AUTOINCREMENT,"
        " owner_uuid TEXT    NOT NULL,"
        " entry      TEXT    DEFAULT '',"
        " logged_at  INTEGER DEFAULT 0"
        ")");
    SqlStep(q);
}

// Returns a JsonObject with all fields, or JsonNull() if the player has no companion.
json HomGetData(object oPC)
{
    sqlquery q = SqlPrepareQueryCampaign("homunculus",
        "SELECT name, bond_level, last_fed, last_used, tasks_done, created_at, is_alive"
        " FROM hom_companions WHERE owner_uuid = @uuid");
    SqlBindString(q, "@uuid", GetObjectUUID(oPC));
    if(!SqlStep(q)) return JsonNull();

    json j = JsonObject();
    j = JsonObjectSet(j, "name",       JsonString(SqlGetString(q, 0)));
    j = JsonObjectSet(j, "bond_level", JsonInt(SqlGetInt(q, 1)));
    j = JsonObjectSet(j, "last_fed",   JsonInt(SqlGetInt(q, 2)));
    j = JsonObjectSet(j, "last_used",  JsonInt(SqlGetInt(q, 3)));
    j = JsonObjectSet(j, "tasks_done", JsonInt(SqlGetInt(q, 4)));
    j = JsonObjectSet(j, "created_at", JsonInt(SqlGetInt(q, 5)));
    j = JsonObjectSet(j, "is_alive",   JsonInt(SqlGetInt(q, 6)));
    return j;
}

// Returns TRUE if the player has a living companion.
int HomExists(object oPC)
{
    sqlquery q = SqlPrepareQueryCampaign("homunculus",
        "SELECT 1 FROM hom_companions WHERE owner_uuid = @uuid AND is_alive = 1");
    SqlBindString(q, "@uuid", GetObjectUUID(oPC));
    return SqlStep(q);
}

// Creates a new companion record. Replaces any dead one.
void HomCreate(object oPC, string sName)
{
    sqlquery q = SqlPrepareQueryCampaign("homunculus",
        "INSERT OR REPLACE INTO hom_companions"
        " (owner_uuid, name, bond_level, last_fed, last_used, tasks_done, created_at, is_alive)"
        " VALUES (@uuid, @name, 1, strftime('%s','now'), 0, 0, strftime('%s','now'), 1)");
    SqlBindString(q, "@uuid", GetObjectUUID(oPC));
    SqlBindString(q, "@name", sName);
    SqlStep(q);
}

void HomSetName(object oPC, string sName)
{
    sqlquery q = SqlPrepareQueryCampaign("homunculus",
        "UPDATE hom_companions SET name = @name WHERE owner_uuid = @uuid");
    SqlBindString(q, "@name", sName);
    SqlBindString(q, "@uuid", GetObjectUUID(oPC));
    SqlStep(q);
}

// Refreshes the last_fed timestamp to now.
void HomFeed(object oPC)
{
    sqlquery q = SqlPrepareQueryCampaign("homunculus",
        "UPDATE hom_companions SET last_fed = strftime('%s','now') WHERE owner_uuid = @uuid");
    SqlBindString(q, "@uuid", GetObjectUUID(oPC));
    SqlStep(q);
}

void HomMarkAbilityUsed(object oPC)
{
    sqlquery q = SqlPrepareQueryCampaign("homunculus",
        "UPDATE hom_companions"
        " SET last_used = strftime('%s','now'), tasks_done = tasks_done + 1"
        " WHERE owner_uuid = @uuid");
    SqlBindString(q, "@uuid", GetObjectUUID(oPC));
    SqlStep(q);
}

// Raises bond by 1, capped at 10.
void HomRaiseBond(object oPC)
{
    sqlquery q = SqlPrepareQueryCampaign("homunculus",
        "UPDATE hom_companions SET bond_level = MIN(bond_level + 1, 10)"
        " WHERE owner_uuid = @uuid AND is_alive = 1");
    SqlBindString(q, "@uuid", GetObjectUUID(oPC));
    SqlStep(q);
}

// Lowers bond by 1. If bond reaches 0, companion dies.
void HomLowerBond(object oPC)
{
    sqlquery q = SqlPrepareQueryCampaign("homunculus",
        "UPDATE hom_companions SET bond_level = MAX(bond_level - 1, 0)"
        " WHERE owner_uuid = @uuid AND is_alive = 1");
    SqlBindString(q, "@uuid", GetObjectUUID(oPC));
    SqlStep(q);

    // Kill companion if bond collapsed.
    q = SqlPrepareQueryCampaign("homunculus",
        "UPDATE hom_companions SET is_alive = 0"
        " WHERE owner_uuid = @uuid AND is_alive = 1 AND bond_level = 0");
    SqlBindString(q, "@uuid", GetObjectUUID(oPC));
    SqlStep(q);
}

void HomKill(object oPC)
{
    sqlquery q = SqlPrepareQueryCampaign("homunculus",
        "UPDATE hom_companions SET is_alive = 0, bond_level = 0 WHERE owner_uuid = @uuid");
    SqlBindString(q, "@uuid", GetObjectUUID(oPC));
    SqlStep(q);
}

// Appends an event log entry; trims the log to the last 20 entries.
void HomAddLog(object oPC, string sEntry)
{
    sqlquery q = SqlPrepareQueryCampaign("homunculus",
        "INSERT INTO hom_log (owner_uuid, entry, logged_at)"
        " VALUES (@uuid, @entry, strftime('%s','now'))");
    SqlBindString(q, "@uuid",  GetObjectUUID(oPC));
    SqlBindString(q, "@entry", sEntry);
    SqlStep(q);

    q = SqlPrepareQueryCampaign("homunculus",
        "DELETE FROM hom_log WHERE owner_uuid = @uuid AND id NOT IN"
        " (SELECT id FROM hom_log WHERE owner_uuid = @uuid ORDER BY logged_at DESC LIMIT 20)");
    SqlBindString(q, "@uuid", GetObjectUUID(oPC));
    SqlStep(q);
}

// Returns a JsonArray of the last nLimit log entries (newest first).
json HomGetLog(object oPC, int nLimit)
{
    json jLog = JsonArray();
    sqlquery q = SqlPrepareQueryCampaign("homunculus",
        "SELECT entry FROM hom_log WHERE owner_uuid = @uuid"
        " ORDER BY logged_at DESC LIMIT @lim");
    SqlBindString(q, "@uuid", GetObjectUUID(oPC));
    SqlBindInt(q,   "@lim",  nLimit);
    while(SqlStep(q))
        jLog = JsonArrayInsert(jLog, JsonString(SqlGetString(q, 0)));
    return jLog;
}

int HomGetBondLevel(object oPC)
{
    sqlquery q = SqlPrepareQueryCampaign("homunculus",
        "SELECT bond_level FROM hom_companions WHERE owner_uuid = @uuid AND is_alive = 1");
    SqlBindString(q, "@uuid", GetObjectUUID(oPC));
    if(SqlStep(q)) return SqlGetInt(q, 0);
    return 0;
}

// Seconds elapsed since the companion was last fed. Returns a large number if no record exists.
int HomSecondsSinceFed(object oPC)
{
    sqlquery q = SqlPrepareQueryCampaign("homunculus",
        "SELECT CAST(strftime('%s','now') AS INTEGER) - last_fed"
        " FROM hom_companions WHERE owner_uuid = @uuid");
    SqlBindString(q, "@uuid", GetObjectUUID(oPC));
    if(SqlStep(q)) return SqlGetInt(q, 0);
    return 999999;
}

// Returns TRUE if the daily ability has already been used today.
int HomAbilityOnCooldown(object oPC)
{
    sqlquery q = SqlPrepareQueryCampaign("homunculus",
        "SELECT 1 FROM hom_companions WHERE owner_uuid = @uuid"
        "  AND last_used > CAST(strftime('%s','now') AS INTEGER) - 86400");
    SqlBindString(q, "@uuid", GetObjectUUID(oPC));
    return SqlStep(q);
}
