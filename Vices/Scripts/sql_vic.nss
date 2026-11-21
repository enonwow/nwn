// sql_vic.nss — SQLite schema and queries for the Vices (Addiction) system.
// Campaign DB name: "vices"
// Table: vic_addiction (uuid, substance_id, level, last_dose, total_doses)

void VicCreateTables()
{
    sqlquery q = SqlPrepareQueryCampaign("vices",
        "CREATE TABLE IF NOT EXISTS vic_addiction ("
        " uuid          TEXT    NOT NULL,"
        " substance_id  INTEGER NOT NULL,"
        " level         INTEGER DEFAULT 1,"
        " last_dose     INTEGER DEFAULT 0,"
        " total_doses   INTEGER DEFAULT 0,"
        " PRIMARY KEY(uuid, substance_id))");
    SqlStep(q);
}

// Returns {level, last_dose, total_doses} or JsonNull() when no record exists.
json VicGetAddict(object oPC, int nSubstance)
{
    sqlquery q = SqlPrepareQueryCampaign("vices",
        "SELECT level, last_dose, total_doses"
        " FROM vic_addiction"
        " WHERE uuid = @uuid AND substance_id = @sid");
    SqlBindString(q, "@uuid", GetObjectUUID(oPC));
    SqlBindInt(q,    "@sid",  nSubstance);
    if(!SqlStep(q)) return JsonNull();
    json j = JsonObject();
    j = JsonObjectSet(j, "level",       JsonInt(SqlGetInt(q, 0)));
    j = JsonObjectSet(j, "last_dose",   JsonInt(SqlGetInt(q, 1)));
    j = JsonObjectSet(j, "total_doses", JsonInt(SqlGetInt(q, 2)));
    return j;
}

// Upsert: sets level and last_dose, increments total_doses.
void VicUpsertDose(object oPC, int nSubstance, int nNewLevel, int nNow)
{
    sqlquery q = SqlPrepareQueryCampaign("vices",
        "INSERT INTO vic_addiction (uuid, substance_id, level, last_dose, total_doses)"
        " VALUES (@uuid, @sid, @lvl, @now, 1)"
        " ON CONFLICT(uuid, substance_id) DO UPDATE SET"
        "  level = @lvl, last_dose = @now, total_doses = total_doses + 1");
    SqlBindString(q, "@uuid", GetObjectUUID(oPC));
    SqlBindInt(q,    "@sid",  nSubstance);
    SqlBindInt(q,    "@lvl",  nNewLevel);
    SqlBindInt(q,    "@now",  nNow);
    SqlStep(q);
}

// Update only the addiction level (used by detox and natural recovery).
void VicSetLevel(object oPC, int nSubstance, int nLevel)
{
    sqlquery q = SqlPrepareQueryCampaign("vices",
        "UPDATE vic_addiction SET level = @lvl"
        " WHERE uuid = @uuid AND substance_id = @sid");
    SqlBindInt(q,    "@lvl",  nLevel);
    SqlBindString(q, "@uuid", GetObjectUUID(oPC));
    SqlBindInt(q,    "@sid",  nSubstance);
    SqlStep(q);
}

// Returns current Unix timestamp via SQLite.
int VicGetNow()
{
    sqlquery q = SqlPrepareQueryCampaign("vices",
        "SELECT CAST(strftime('%s','now') AS INTEGER)");
    if(SqlStep(q)) return SqlGetInt(q, 0);
    return 0;
}

// Returns all addictions for a PC as a JsonArray of {substance_id, level, last_dose}.
json VicGetAllAddictions(object oPC)
{
    json jArr = JsonArray();
    sqlquery q = SqlPrepareQueryCampaign("vices",
        "SELECT substance_id, level, last_dose"
        " FROM vic_addiction"
        " WHERE uuid = @uuid AND level > 0"
        " ORDER BY substance_id");
    SqlBindString(q, "@uuid", GetObjectUUID(oPC));
    while(SqlStep(q))
    {
        json j = JsonObject();
        j = JsonObjectSet(j, "substance_id", JsonInt(SqlGetInt(q, 0)));
        j = JsonObjectSet(j, "level",        JsonInt(SqlGetInt(q, 1)));
        j = JsonObjectSet(j, "last_dose",    JsonInt(SqlGetInt(q, 2)));
        jArr = JsonArrayInsert(jArr, j);
    }
    return jArr;
}
