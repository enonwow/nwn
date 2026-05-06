const string PLG_CAMPAIGN = "plague";

void PlgCreateTables()
{
    sqlquery q = SqlPrepareQueryCampaign(PLG_CAMPAIGN,
        "CREATE TABLE IF NOT EXISTS plg_diseases ("
        "  uuid        TEXT    PRIMARY KEY,"
        "  disease_id  INTEGER NOT NULL DEFAULT -1,"
        "  phase       INTEGER NOT NULL DEFAULT 0,"
        "  phase_start INTEGER NOT NULL DEFAULT 0,"
        "  phase_end   INTEGER NOT NULL DEFAULT 0"
        ")");
    SqlStep(q);
}

// Returns {disease_id, phase, phase_start, phase_end} or JSON_TYPE_NULL if no row.
json PlgGetState(object oPC)
{
    sqlquery q = SqlPrepareQueryCampaign(PLG_CAMPAIGN,
        "SELECT disease_id, phase, phase_start, phase_end "
        "FROM plg_diseases WHERE uuid = @uuid");
    SqlBindString(q, "@uuid", GetObjectUUID(oPC));
    if(!SqlStep(q)) return JsonNull();

    json j = JsonObject();
    j = JsonObjectSet(j, "disease_id",  JsonInt(SqlGetInt(q, 0)));
    j = JsonObjectSet(j, "phase",       JsonInt(SqlGetInt(q, 1)));
    j = JsonObjectSet(j, "phase_start", JsonInt(SqlGetInt(q, 2)));
    j = JsonObjectSet(j, "phase_end",   JsonInt(SqlGetInt(q, 3)));
    return j;
}

// Sets initial disease (phase 1 = incubation).
void PlgContractDisease(object oPC, int nDiseaseId, int nPhaseInterval)
{
    sqlquery q = SqlPrepareQueryCampaign(PLG_CAMPAIGN,
        "INSERT OR REPLACE INTO plg_diseases "
        "(uuid, disease_id, phase, phase_start, phase_end) "
        "VALUES (@uuid, @did, 1, strftime('%s','now'), strftime('%s','now') + @dur)");
    SqlBindString(q, "@uuid", GetObjectUUID(oPC));
    SqlBindInt   (q, "@did",  nDiseaseId);
    SqlBindInt   (q, "@dur",  nPhaseInterval);
    SqlStep(q);
}

// Advances to a new phase; phase_start = old phase_end, phase_end = phase_start + duration.
// Pass nNextInterval = 0 for phase 4 (critical – no further advance).
void PlgAdvancePhase(object oPC, int nNewPhase, int nOldPhaseEnd, int nNextInterval)
{
    int nNewEnd = (nNextInterval > 0) ? nOldPhaseEnd + nNextInterval : 0;
    sqlquery q = SqlPrepareQueryCampaign(PLG_CAMPAIGN,
        "UPDATE plg_diseases "
        "SET phase = @phase, phase_start = @ps, phase_end = @pe "
        "WHERE uuid = @uuid");
    SqlBindString(q, "@uuid",  GetObjectUUID(oPC));
    SqlBindInt   (q, "@phase", nNewPhase);
    SqlBindInt   (q, "@ps",    nOldPhaseEnd);
    SqlBindInt   (q, "@pe",    nNewEnd);
    SqlStep(q);
}

void PlgCureDisease(object oPC)
{
    sqlquery q = SqlPrepareQueryCampaign(PLG_CAMPAIGN,
        "DELETE FROM plg_diseases WHERE uuid = @uuid");
    SqlBindString(q, "@uuid", GetObjectUUID(oPC));
    SqlStep(q);
}

// Returns current unix time from SQLite (authoritative clock for phase checks).
int PlgUnixNow()
{
    sqlquery q = SqlPrepareQueryCampaign(PLG_CAMPAIGN, "SELECT strftime('%s','now')");
    if(SqlStep(q)) return SqlGetInt(q, 0);
    return 0;
}
