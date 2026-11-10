// MIT_POISON_COUNT must be declared before this file is included; it lives in lib_mit_def.nss.
// Include order: lib_mit_def.nss -> sql_mit.nss (via its own include chain).

void MitCreateTables()
{
    sqlquery q = SqlPrepareQueryCampaign("mithridate",
        "CREATE TABLE IF NOT EXISTS mit_tolerance ("
        "  char_uuid    TEXT    NOT NULL,"
        "  poison_id    INTEGER NOT NULL,"
        "  tolerance    INTEGER DEFAULT 0,"
        "  success_doses INTEGER DEFAULT 0,"
        "  total_doses  INTEGER DEFAULT 0,"
        "  overdoses    INTEGER DEFAULT 0,"
        "  last_dosed_at INTEGER DEFAULT 0,"
        "  PRIMARY KEY (char_uuid, poison_id)"
        ")");
    SqlStep(q);
}

json MitGetTolerance(object oPC, int nPoisonId)
{
    string sUuid = GetObjectUUID(oPC);
    sqlquery q = SqlPrepareQueryCampaign("mithridate",
        "SELECT tolerance, success_doses, total_doses, overdoses, last_dosed_at "
        "FROM mit_tolerance WHERE char_uuid = @uuid AND poison_id = @pid");
    SqlBindString(q, "@uuid", sUuid);
    SqlBindInt   (q, "@pid",  nPoisonId);
    if(SqlStep(q))
    {
        json j = JsonObject();
        j = JsonObjectSet(j, "tolerance",     JsonInt(SqlGetInt(q, 0)));
        j = JsonObjectSet(j, "success_doses", JsonInt(SqlGetInt(q, 1)));
        j = JsonObjectSet(j, "total_doses",   JsonInt(SqlGetInt(q, 2)));
        j = JsonObjectSet(j, "overdoses",     JsonInt(SqlGetInt(q, 3)));
        j = JsonObjectSet(j, "last_dosed_at", JsonInt(SqlGetInt(q, 4)));
        return j;
    }
    json j = JsonObject();
    j = JsonObjectSet(j, "tolerance",     JsonInt(0));
    j = JsonObjectSet(j, "success_doses", JsonInt(0));
    j = JsonObjectSet(j, "total_doses",   JsonInt(0));
    j = JsonObjectSet(j, "overdoses",     JsonInt(0));
    j = JsonObjectSet(j, "last_dosed_at", JsonInt(0));
    return j;
}

// Returns array of 10 tolerance rows indexed by poison_id.
json MitGetAllTolerances(object oPC)
{
    string sUuid = GetObjectUUID(oPC);
    json jResult = JsonArray();
    int i;
    for(i = 0; i < 10; i++)
    {
        json jRow = JsonObject();
        jRow = JsonObjectSet(jRow, "tolerance",     JsonInt(0));
        jRow = JsonObjectSet(jRow, "success_doses", JsonInt(0));
        jRow = JsonObjectSet(jRow, "total_doses",   JsonInt(0));
        jRow = JsonObjectSet(jRow, "overdoses",     JsonInt(0));
        jRow = JsonObjectSet(jRow, "last_dosed_at", JsonInt(0));
        jResult = JsonArrayInsert(jResult, jRow);
    }

    sqlquery q = SqlPrepareQueryCampaign("mithridate",
        "SELECT poison_id, tolerance, success_doses, total_doses, overdoses, last_dosed_at "
        "FROM mit_tolerance WHERE char_uuid = @uuid ORDER BY poison_id");
    SqlBindString(q, "@uuid", sUuid);
    while(SqlStep(q))
    {
        int nPid = SqlGetInt(q, 0);
        if(nPid < 0 || nPid >= 10) continue;
        json jRow = JsonObject();
        jRow = JsonObjectSet(jRow, "tolerance",     JsonInt(SqlGetInt(q, 1)));
        jRow = JsonObjectSet(jRow, "success_doses", JsonInt(SqlGetInt(q, 2)));
        jRow = JsonObjectSet(jRow, "total_doses",   JsonInt(SqlGetInt(q, 3)));
        jRow = JsonObjectSet(jRow, "overdoses",     JsonInt(SqlGetInt(q, 4)));
        jRow = JsonObjectSet(jRow, "last_dosed_at", JsonInt(SqlGetInt(q, 5)));
        jResult = JsonArraySet(jResult, nPid, jRow);
    }
    return jResult;
}

// Logs one dose attempt: increments total_doses, optionally success_doses and overdoses.
void MitUpsertDoseResult(object oPC, int nPoisonId, int bSuccess, int bOverdose)
{
    string sUuid = GetObjectUUID(oPC);
    sqlquery q = SqlPrepareQueryCampaign("mithridate",
        "INSERT INTO mit_tolerance (char_uuid, poison_id, tolerance, success_doses, total_doses, overdoses, last_dosed_at) "
        "VALUES (@uuid, @pid, 0, @suc, 1, @od, strftime('%s','now')) "
        "ON CONFLICT(char_uuid, poison_id) DO UPDATE SET "
        "  success_doses = success_doses + @suc,"
        "  total_doses   = total_doses   + 1,"
        "  overdoses     = overdoses     + @od,"
        "  last_dosed_at = strftime('%s','now')");
    SqlBindString(q, "@uuid", sUuid);
    SqlBindInt   (q, "@pid",  nPoisonId);
    SqlBindInt   (q, "@suc",  bSuccess  ? 1 : 0);
    SqlBindInt   (q, "@od",   bOverdose ? 1 : 0);
    SqlStep(q);
}

void MitSetTolerance(object oPC, int nPoisonId, int nNewLevel)
{
    string sUuid = GetObjectUUID(oPC);
    sqlquery q = SqlPrepareQueryCampaign("mithridate",
        "INSERT INTO mit_tolerance (char_uuid, poison_id, tolerance) "
        "VALUES (@uuid, @pid, @lvl) "
        "ON CONFLICT(char_uuid, poison_id) DO UPDATE SET tolerance = @lvl");
    SqlBindString(q, "@uuid", sUuid);
    SqlBindInt   (q, "@pid",  nPoisonId);
    SqlBindInt   (q, "@lvl",  nNewLevel);
    SqlStep(q);
}

void MitSetSuccessDoses(object oPC, int nPoisonId, int nNewVal)
{
    string sUuid = GetObjectUUID(oPC);
    sqlquery q = SqlPrepareQueryCampaign("mithridate",
        "UPDATE mit_tolerance SET success_doses = @sd "
        "WHERE char_uuid = @uuid AND poison_id = @pid");
    SqlBindString(q, "@uuid", sUuid);
    SqlBindInt   (q, "@pid",  nPoisonId);
    SqlBindInt   (q, "@sd",   nNewVal);
    SqlStep(q);
}

// Returns remaining cooldown in seconds; 0 means ready.
int MitGetCooldownRemaining(object oPC, int nPoisonId)
{
    string sUuid = GetObjectUUID(oPC);
    sqlquery q = SqlPrepareQueryCampaign("mithridate",
        "SELECT MAX(0, @cd - CAST(strftime('%s','now') AS INTEGER) + last_dosed_at) "
        "FROM mit_tolerance WHERE char_uuid = @uuid AND poison_id = @pid");
    SqlBindString(q, "@uuid", sUuid);
    SqlBindInt   (q, "@pid",  nPoisonId);
    SqlBindInt   (q, "@cd",   3600);
    if(SqlStep(q)) return SqlGetInt(q, 0);
    return 0;
}
