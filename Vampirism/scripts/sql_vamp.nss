// Persistent storage for the Vampirism system.
// Campaign DB name: "vampirism"
// One row per infected character; non-vampires have no row.

void VampCreateTables()
{
    sqlquery q = SqlPrepareQueryCampaign("vampirism",
        "CREATE TABLE IF NOT EXISTS vamp_infected ("
        "  uuid           TEXT PRIMARY KEY,"
        "  blood_level    INTEGER NOT NULL DEFAULT 75,"
        "  infected_at    INTEGER NOT NULL DEFAULT 0,"
        "  cure_attempts  INTEGER NOT NULL DEFAULT 0"
        ")");
    SqlStep(q);
}

int VampIsVampire(object oPC)
{
    sqlquery q = SqlPrepareQueryCampaign("vampirism",
        "SELECT 1 FROM vamp_infected WHERE uuid = @uuid");
    SqlBindString(q, "@uuid", GetObjectUUID(oPC));
    return SqlStep(q);
}

// Returns blood level 0-100, or -1 if not a vampire.
int VampGetBlood(object oPC)
{
    sqlquery q = SqlPrepareQueryCampaign("vampirism",
        "SELECT blood_level FROM vamp_infected WHERE uuid = @uuid");
    SqlBindString(q, "@uuid", GetObjectUUID(oPC));
    if(SqlStep(q)) return SqlGetInt(q, 0);
    return -1;
}

void VampSetBlood(object oPC, int nBlood)
{
    if(nBlood < 0)   nBlood = 0;
    if(nBlood > 100) nBlood = 100;
    sqlquery q = SqlPrepareQueryCampaign("vampirism",
        "UPDATE vamp_infected SET blood_level = @blood WHERE uuid = @uuid");
    SqlBindInt   (q, "@blood", nBlood);
    SqlBindString(q, "@uuid",  GetObjectUUID(oPC));
    SqlStep(q);
}

void VampInfect(object oPC)
{
    sqlquery q = SqlPrepareQueryCampaign("vampirism",
        "INSERT OR IGNORE INTO vamp_infected (uuid, blood_level, infected_at)"
        " VALUES (@uuid, 75, strftime('%s','now'))");
    SqlBindString(q, "@uuid", GetObjectUUID(oPC));
    SqlStep(q);
}

void VampCure(object oPC)
{
    sqlquery q = SqlPrepareQueryCampaign("vampirism",
        "DELETE FROM vamp_infected WHERE uuid = @uuid");
    SqlBindString(q, "@uuid", GetObjectUUID(oPC));
    SqlStep(q);
}

int VampGetCureAttempts(object oPC)
{
    sqlquery q = SqlPrepareQueryCampaign("vampirism",
        "SELECT cure_attempts FROM vamp_infected WHERE uuid = @uuid");
    SqlBindString(q, "@uuid", GetObjectUUID(oPC));
    if(SqlStep(q)) return SqlGetInt(q, 0);
    return 0;
}

void VampIncrementCureAttempts(object oPC)
{
    sqlquery q = SqlPrepareQueryCampaign("vampirism",
        "UPDATE vamp_infected SET cure_attempts = cure_attempts + 1 WHERE uuid = @uuid");
    SqlBindString(q, "@uuid", GetObjectUUID(oPC));
    SqlStep(q);
}

// Returns the number of currently infected online players (for GM/debug).
int VampGetInfectedCount()
{
    sqlquery q = SqlPrepareQueryCampaign("vampirism",
        "SELECT COUNT(*) FROM vamp_infected");
    if(SqlStep(q)) return SqlGetInt(q, 0);
    return 0;
}
