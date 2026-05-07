// sql_plg.nss - Campaign SQLite schema for Plague v2
//
// Tabela plg_diseases:
//   - composite PK (uuid, disease_id) - gracz moze miec wiele chorob, tej samej nie 2x
//   - kolumny extension points dla fazy 2 (is_magical, master_uuid, source_id) - zarezerwowane

const string PLG_CAMPAIGN = "plague";

// ============================================================
// Schema
// ============================================================

void PlgCreateTables()
{
    // Extension points pod faze 2 (is_magical, master_uuid, source_id) - zarezerwowane.
    string sSql = "CREATE TABLE IF NOT EXISTS plg_diseases ("
        + "uuid TEXT NOT NULL,"
        + "disease_id INTEGER NOT NULL,"
        + "episode_id TEXT NOT NULL DEFAULT '',"
        + "phase INTEGER NOT NULL DEFAULT 0,"
        + "phase_start INTEGER NOT NULL DEFAULT 0,"
        + "phase_end INTEGER NOT NULL DEFAULT 0,"
        + "last_login INTEGER NOT NULL DEFAULT 0,"
        + "frozen_at_logout INTEGER NOT NULL DEFAULT 0,"
        + "diagnosed INTEGER NOT NULL DEFAULT 0,"
        + "is_magical INTEGER NOT NULL DEFAULT 0,"
        + "master_uuid TEXT NOT NULL DEFAULT '',"
        + "source_id INTEGER NOT NULL DEFAULT -1,"
        + "PRIMARY KEY (uuid, disease_id))";
    sqlquery q = SqlPrepareQueryCampaign(PLG_CAMPAIGN, sSql);
    SqlStep(q);

    // Migration for existing databases - add column if missing (silent fail if exists).
    sqlquery qAlter = SqlPrepareQueryCampaign(PLG_CAMPAIGN,
        "ALTER TABLE plg_diseases ADD COLUMN frozen_at_logout INTEGER NOT NULL DEFAULT 0");
    SqlStep(qAlter);
}

// Update frozen_at_logout flag for ALL diseases of player (one query).
void PlgUpdateFrozenAtLogout(object oPC, int bFrozen)
{
    sqlquery q = SqlPrepareQueryCampaign(PLG_CAMPAIGN,
        "UPDATE plg_diseases SET frozen_at_logout = @f WHERE uuid = @uuid");
    SqlBindString(q, "@uuid", GetObjectUUID(oPC));
    SqlBindInt(q, "@f", bFrozen);
    SqlStep(q);
}

// ============================================================
// CRUD per gracz per choroba
// ============================================================

// Returns JSON object lub JSON_TYPE_NULL.
json PlgGetState(object oPC, int nDiseaseId)
{
    string sSql = "SELECT episode_id, phase, phase_start, phase_end, last_login, "
        + "frozen_at_logout, diagnosed, is_magical, master_uuid, source_id "
        + "FROM plg_diseases WHERE uuid = @uuid AND disease_id = @did";
    sqlquery q = SqlPrepareQueryCampaign(PLG_CAMPAIGN, sSql);
    SqlBindString(q, "@uuid", GetObjectUUID(oPC));
    SqlBindInt(q, "@did", nDiseaseId);
    if(!SqlStep(q)) return JsonNull();

    json j = JsonObject();
    j = JsonObjectSet(j, "disease_id",       JsonInt(nDiseaseId));
    j = JsonObjectSet(j, "episode_id",       JsonString(SqlGetString(q, 0)));
    j = JsonObjectSet(j, "phase",            JsonInt(SqlGetInt(q, 1)));
    j = JsonObjectSet(j, "phase_start",      JsonInt(SqlGetInt(q, 2)));
    j = JsonObjectSet(j, "phase_end",        JsonInt(SqlGetInt(q, 3)));
    j = JsonObjectSet(j, "last_login",       JsonInt(SqlGetInt(q, 4)));
    j = JsonObjectSet(j, "frozen_at_logout", JsonInt(SqlGetInt(q, 5)));
    j = JsonObjectSet(j, "diagnosed",        JsonInt(SqlGetInt(q, 6)));
    j = JsonObjectSet(j, "is_magical",       JsonInt(SqlGetInt(q, 7)));
    j = JsonObjectSet(j, "master_uuid",      JsonString(SqlGetString(q, 8)));
    j = JsonObjectSet(j, "source_id",        JsonInt(SqlGetInt(q, 9)));
    return j;
}

// Returns JSON array wszystkich aktywnych chorob gracza.
json PlgGetStates(object oPC)
{
    string sSql = "SELECT disease_id, episode_id, phase, phase_start, phase_end, "
        + "last_login, frozen_at_logout, diagnosed, is_magical, master_uuid, source_id "
        + "FROM plg_diseases WHERE uuid = @uuid";
    sqlquery q = SqlPrepareQueryCampaign(PLG_CAMPAIGN, sSql);
    SqlBindString(q, "@uuid", GetObjectUUID(oPC));

    json jArr = JsonArray();
    while(SqlStep(q))
    {
        json j = JsonObject();
        j = JsonObjectSet(j, "disease_id",       JsonInt(SqlGetInt(q, 0)));
        j = JsonObjectSet(j, "episode_id",       JsonString(SqlGetString(q, 1)));
        j = JsonObjectSet(j, "phase",            JsonInt(SqlGetInt(q, 2)));
        j = JsonObjectSet(j, "phase_start",      JsonInt(SqlGetInt(q, 3)));
        j = JsonObjectSet(j, "phase_end",        JsonInt(SqlGetInt(q, 4)));
        j = JsonObjectSet(j, "last_login",       JsonInt(SqlGetInt(q, 5)));
        j = JsonObjectSet(j, "frozen_at_logout", JsonInt(SqlGetInt(q, 6)));
        j = JsonObjectSet(j, "diagnosed",        JsonInt(SqlGetInt(q, 7)));
        j = JsonObjectSet(j, "is_magical",       JsonInt(SqlGetInt(q, 8)));
        j = JsonObjectSet(j, "master_uuid",      JsonString(SqlGetString(q, 9)));
        j = JsonObjectSet(j, "source_id",        JsonInt(SqlGetInt(q, 10)));
        jArr = JsonArrayInsert(jArr, j);
    }
    return jArr;
}

// Returns TRUE jesli gracz ma te chorobe.
int PlgHasDisease(object oPC, int nDiseaseId)
{
    sqlquery q = SqlPrepareQueryCampaign(PLG_CAMPAIGN,
        "SELECT 1 FROM plg_diseases WHERE uuid = @uuid AND disease_id = @did LIMIT 1");
    // (single-line SQL OK)
    SqlBindString(q, "@uuid", GetObjectUUID(oPC));
    SqlBindInt(q, "@did", nDiseaseId);
    return SqlStep(q);
}

// INSERT - jezeli juz istnieje, no-op (PrimaryKey constraint).
void PlgInsertDisease(object oPC, int nDiseaseId, string sEpisodeId, int nPhaseInterval)
{
    string sSql = "INSERT OR IGNORE INTO plg_diseases "
        + "(uuid, disease_id, episode_id, phase, phase_start, phase_end, last_login) "
        + "VALUES (@uuid, @did, @eid, 1, strftime('%s','now'), "
        + "strftime('%s','now') + @dur, strftime('%s','now'))";
    sqlquery q = SqlPrepareQueryCampaign(PLG_CAMPAIGN, sSql);
    SqlBindString(q, "@uuid", GetObjectUUID(oPC));
    SqlBindInt(q, "@did", nDiseaseId);
    SqlBindString(q, "@eid", sEpisodeId);
    SqlBindInt(q, "@dur", nPhaseInterval);
    SqlStep(q);
}

// Aktualizuje phase + phase_start + phase_end.
void PlgSetPhase(object oPC, int nDiseaseId, int nPhase, int nPhaseStart, int nPhaseEnd)
{
    string sSql = "UPDATE plg_diseases SET phase = @phase, phase_start = @ps, phase_end = @pe "
        + "WHERE uuid = @uuid AND disease_id = @did";
    sqlquery q = SqlPrepareQueryCampaign(PLG_CAMPAIGN, sSql);
    SqlBindString(q, "@uuid", GetObjectUUID(oPC));
    SqlBindInt(q, "@did", nDiseaseId);
    SqlBindInt(q, "@phase", nPhase);
    SqlBindInt(q, "@ps", nPhaseStart);
    SqlBindInt(q, "@pe", nPhaseEnd);
    SqlStep(q);
}

void PlgSetDiagnosed(object oPC, int nDiseaseId, int bDiagnosed)
{
    string sSql = "UPDATE plg_diseases SET diagnosed = @d "
        + "WHERE uuid = @uuid AND disease_id = @did";
    sqlquery q = SqlPrepareQueryCampaign(PLG_CAMPAIGN, sSql);
    SqlBindString(q, "@uuid", GetObjectUUID(oPC));
    SqlBindInt(q, "@did", nDiseaseId);
    SqlBindInt(q, "@d", bDiagnosed);
    SqlStep(q);
}

// Aktualizuje last_login dla wszystkich chorob gracza (przy logout/login).
void PlgUpdateLastLogin(object oPC)
{
    sqlquery q = SqlPrepareQueryCampaign(PLG_CAMPAIGN,
        "UPDATE plg_diseases SET last_login = strftime('%s','now') WHERE uuid = @uuid");
    SqlBindString(q, "@uuid", GetObjectUUID(oPC));
    SqlStep(q);
}

void PlgDeleteDisease(object oPC, int nDiseaseId)
{
    sqlquery q = SqlPrepareQueryCampaign(PLG_CAMPAIGN,
        "DELETE FROM plg_diseases WHERE uuid = @uuid AND disease_id = @did");
    SqlBindString(q, "@uuid", GetObjectUUID(oPC));
    SqlBindInt(q, "@did", nDiseaseId);
    SqlStep(q);
}

// Usuwa wszystkie choroby gracza (rzadko - DM tool).
void PlgDeleteAllDiseases(object oPC)
{
    sqlquery q = SqlPrepareQueryCampaign(PLG_CAMPAIGN,
        "DELETE FROM plg_diseases WHERE uuid = @uuid");
    SqlBindString(q, "@uuid", GetObjectUUID(oPC));
    SqlStep(q);
}

// ============================================================
// Utilities
// ============================================================

// Returns current unix time z SQLite (autorytatywny zegar).
int PlgUnixNow()
{
    sqlquery q = SqlPrepareQueryCampaign(PLG_CAMPAIGN, "SELECT strftime('%s','now')");
    if(SqlStep(q)) return SqlGetInt(q, 0);
    return 0;
}

// Generuje UUID dla episode_id (RFC 4122 v4 format).
// NWN ma natywny GetRandomUUID() w EE - uzywamy go.
string PlgGenerateEpisodeId()
{
    return GetRandomUUID();
}

// ============================================================
// DM helpers - lista wszystkich zarazonych
// ============================================================

// Returns JSON array {uuid, char_name?, disease_id, phase}.
// Char name nie pamietamy w tej tabeli - DM panel sobie pobierze przez UUID->object lookup.
json PlgListAllInfected()
{
    string sSql = "SELECT uuid, disease_id, phase, phase_end FROM plg_diseases "
        + "ORDER BY uuid, disease_id";
    sqlquery q = SqlPrepareQueryCampaign(PLG_CAMPAIGN, sSql);

    json jArr = JsonArray();
    while(SqlStep(q))
    {
        json j = JsonObject();
        j = JsonObjectSet(j, "uuid",       JsonString(SqlGetString(q, 0)));
        j = JsonObjectSet(j, "disease_id", JsonInt(SqlGetInt(q, 1)));
        j = JsonObjectSet(j, "phase",      JsonInt(SqlGetInt(q, 2)));
        j = JsonObjectSet(j, "phase_end",  JsonInt(SqlGetInt(q, 3)));
        jArr = JsonArrayInsert(jArr, j);
    }
    return jArr;
}
