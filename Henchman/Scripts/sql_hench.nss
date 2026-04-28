// sql_hench.nss
// SQL for the henchman system - Campaign SQLite, zero includes

const string HENCH_DB         = "henchman";
const string HENCH_TABLE      = "henchman_active";

void HenchCreateTable()
{
    string sCreate =
        "CREATE TABLE IF NOT EXISTS " + HENCH_TABLE + " ("
        + "pc_uuid       TEXT PRIMARY KEY, "
        + "hench_resref  TEXT NOT NULL, "
        + "hench_json    TEXT, "
        + "is_dead       INT DEFAULT 0"
        + ")";
    sqlquery q = SqlPrepareQueryCampaign(HENCH_DB, sCreate);
    SqlStep(q);

    // Migrations: add new columns to an existing DB.
    // ALTER returns an error if the column already exists - we ignore it.
    q = SqlPrepareQueryCampaign(HENCH_DB,
        "ALTER TABLE " + HENCH_TABLE + " ADD COLUMN hench_json TEXT");
    SqlStep(q);

    q = SqlPrepareQueryCampaign(HENCH_DB,
        "ALTER TABLE " + HENCH_TABLE + " ADD COLUMN is_dead INT DEFAULT 0");
    SqlStep(q);
}

// Persists active henchman for the PC (full creature serialization in hench_json).
void HenchSaveRecord(string sPcUuid, string sResRef, string sJson, int nIsDead = 0)
{
    string sQuery =
        "INSERT INTO " + HENCH_TABLE + " (pc_uuid, hench_resref, hench_json, is_dead) "
        + "VALUES (@uuid, @resref, @json, @dead) "
        + "ON CONFLICT(pc_uuid) DO UPDATE SET "
        + "hench_resref = excluded.hench_resref, "
        + "hench_json   = excluded.hench_json, "
        + "is_dead      = excluded.is_dead";

    sqlquery q = SqlPrepareQueryCampaign(HENCH_DB, sQuery);
    SqlBindString(q, "@uuid",   sPcUuid);
    SqlBindString(q, "@resref", sResRef);
    SqlBindString(q, "@json",   sJson);
    SqlBindInt   (q, "@dead",   nIsDead);
    SqlStep(q);
}

// Returns JsonObject {resref, hench_json, is_dead} or JsonNull if no record.
json HenchLoadRecord(string sPcUuid)
{
    string sQuery =
        "SELECT hench_resref, hench_json, is_dead "
        + "FROM " + HENCH_TABLE + " "
        + "WHERE pc_uuid = @uuid "
        + "LIMIT 1";

    sqlquery q = SqlPrepareQueryCampaign(HENCH_DB, sQuery);
    SqlBindString(q, "@uuid", sPcUuid);

    if(!SqlStep(q))
        return JsonNull();

    json jResult = JsonObject();
    jResult = JsonObjectSet(jResult, "resref",     JsonString(SqlGetString(q, 0)));
    jResult = JsonObjectSet(jResult, "hench_json", JsonString(SqlGetString(q, 1)));
    jResult = JsonObjectSet(jResult, "is_dead",    JsonInt   (SqlGetInt   (q, 2)));
    return jResult;
}

// Updates only the is_dead flag (used by OnDeath and Resurrect).
void HenchSetDeadFlag(string sPcUuid, int nIsDead)
{
    string sQuery =
        "UPDATE " + HENCH_TABLE + " SET is_dead = @dead WHERE pc_uuid = @uuid";

    sqlquery q = SqlPrepareQueryCampaign(HENCH_DB, sQuery);
    SqlBindInt   (q, "@dead", nIsDead);
    SqlBindString(q, "@uuid", sPcUuid);
    SqlStep(q);
}

// Removes the record - call when firing the henchman.
void HenchDeleteRecord(string sPcUuid)
{
    string sQuery =
        "DELETE FROM " + HENCH_TABLE + " WHERE pc_uuid = @uuid";

    sqlquery q = SqlPrepareQueryCampaign(HENCH_DB, sQuery);
    SqlBindString(q, "@uuid", sPcUuid);
    SqlStep(q);
}

// ============================================================
// UI settings - per-PC, independent of henchman state
// ============================================================
const string HENCH_UI_TABLE = "henchman_ui";

void HenchUiCreateTable()
{
    string sCreate =
        "CREATE TABLE IF NOT EXISTS " + HENCH_UI_TABLE + " ("
        + "pc_uuid TEXT PRIMARY KEY, "
        + "cmd_x   REAL, "
        + "cmd_y   REAL"
        + ")";
    sqlquery q = SqlPrepareQueryCampaign(HENCH_DB, sCreate);
    SqlStep(q);
}

void HenchUiSavePosition(string sPcUuid, float fX, float fY)
{
    string sQuery =
        "INSERT INTO " + HENCH_UI_TABLE + " (pc_uuid, cmd_x, cmd_y) "
        + "VALUES (@uuid, @x, @y) "
        + "ON CONFLICT(pc_uuid) DO UPDATE SET "
        + "cmd_x = excluded.cmd_x, cmd_y = excluded.cmd_y";

    sqlquery q = SqlPrepareQueryCampaign(HENCH_DB, sQuery);
    SqlBindString(q, "@uuid", sPcUuid);
    SqlBindFloat (q, "@x",    fX);
    SqlBindFloat (q, "@y",    fY);
    SqlStep(q);
}

// Returns JsonObject {x, y} or JsonNull if no record.
json HenchUiLoadPosition(string sPcUuid)
{
    string sQuery =
        "SELECT cmd_x, cmd_y FROM " + HENCH_UI_TABLE + " WHERE pc_uuid = @uuid LIMIT 1";

    sqlquery q = SqlPrepareQueryCampaign(HENCH_DB, sQuery);
    SqlBindString(q, "@uuid", sPcUuid);

    if(!SqlStep(q)) return JsonNull();

    json jResult = JsonObject();
    jResult = JsonObjectSet(jResult, "x", JsonFloat(SqlGetFloat(q, 0)));
    jResult = JsonObjectSet(jResult, "y", JsonFloat(SqlGetFloat(q, 1)));
    return jResult;
}
