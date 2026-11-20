// Familiar Bond — persistent storage layer.
// Campaign DB name: "familiar"

const int FAM_MOURN_DURATION = 86400; // 24h real-time seconds
const int FAM_BOND_MAX       = 500;   // 5 levels × 100 XP each
const int FAM_BOND_STEPS     = 100;

void FamCreateTables()
{
    sqlquery q = SqlPrepareQueryCampaign("familiar",
        "CREATE TABLE IF NOT EXISTS fam_familiar ("
        "uuid          TEXT    PRIMARY KEY, "
        "fam_type      INTEGER DEFAULT 0, "
        "bond_xp       INTEGER DEFAULT 0, "
        "hp            INTEGER DEFAULT 20, "
        "max_hp        INTEGER DEFAULT 20, "
        "task          INTEGER DEFAULT 0, "
        "task_started  INTEGER DEFAULT 0, "
        "vigil_until   INTEGER DEFAULT 0, "
        "mourning_until INTEGER DEFAULT 0, "
        "dismissed     INTEGER DEFAULT 0, "
        "carry_json    TEXT    DEFAULT '' "
        ")");
    SqlStep(q);

    q = SqlPrepareQueryCampaign("familiar",
        "CREATE TABLE IF NOT EXISTS fam_log ("
        "id         INTEGER PRIMARY KEY AUTOINCREMENT, "
        "uuid       TEXT    NOT NULL, "
        "event_type TEXT    NOT NULL, "
        "detail     TEXT    DEFAULT '', "
        "logged_at  INTEGER DEFAULT (strftime('%s','now')) "
        ")");
    SqlStep(q);
}

int FamExists(object oPC)
{
    sqlquery q = SqlPrepareQueryCampaign("familiar",
        "SELECT 1 FROM fam_familiar WHERE uuid = @uuid");
    SqlBindString(q, "@uuid", GetObjectUUID(oPC));
    return SqlStep(q);
}

void FamCreate(object oPC, int nType)
{
    sqlquery q = SqlPrepareQueryCampaign("familiar",
        "INSERT OR IGNORE INTO fam_familiar (uuid, fam_type, bond_xp, hp, max_hp) "
        "VALUES (@uuid, @type, 0, 20, 20)");
    SqlBindString(q, "@uuid", GetObjectUUID(oPC));
    SqlBindInt   (q, "@type", nType);
    SqlStep(q);
}

json FamGet(object oPC)
{
    sqlquery q = SqlPrepareQueryCampaign("familiar",
        "SELECT fam_type, bond_xp, hp, max_hp, task, task_started, "
        "vigil_until, mourning_until, dismissed, carry_json "
        "FROM fam_familiar WHERE uuid = @uuid");
    SqlBindString(q, "@uuid", GetObjectUUID(oPC));
    if(!SqlStep(q)) return JsonNull();

    json j = JsonObject();
    j = JsonObjectSet(j, "fam_type",      JsonInt   (SqlGetInt   (q, 0)));
    j = JsonObjectSet(j, "bond_xp",       JsonInt   (SqlGetInt   (q, 1)));
    j = JsonObjectSet(j, "hp",            JsonInt   (SqlGetInt   (q, 2)));
    j = JsonObjectSet(j, "max_hp",        JsonInt   (SqlGetInt   (q, 3)));
    j = JsonObjectSet(j, "task",          JsonInt   (SqlGetInt   (q, 4)));
    j = JsonObjectSet(j, "task_started",  JsonInt   (SqlGetInt   (q, 5)));
    j = JsonObjectSet(j, "vigil_until",   JsonInt   (SqlGetInt   (q, 6)));
    j = JsonObjectSet(j, "mourning_until",JsonInt   (SqlGetInt   (q, 7)));
    j = JsonObjectSet(j, "dismissed",     JsonInt   (SqlGetInt   (q, 8)));
    j = JsonObjectSet(j, "carry_json",    JsonString(SqlGetString(q, 9)));
    return j;
}

void FamSetTask(object oPC, int nTask)
{
    sqlquery q = SqlPrepareQueryCampaign("familiar",
        "UPDATE fam_familiar "
        "SET task = @task, task_started = strftime('%s','now') "
        "WHERE uuid = @uuid");
    SqlBindInt   (q, "@task", nTask);
    SqlBindString(q, "@uuid", GetObjectUUID(oPC));
    SqlStep(q);
}

void FamFinishTask(object oPC)
{
    sqlquery q = SqlPrepareQueryCampaign("familiar",
        "UPDATE fam_familiar SET task = 0, task_started = 0 WHERE uuid = @uuid");
    SqlBindString(q, "@uuid", GetObjectUUID(oPC));
    SqlStep(q);
}

void FamSetVigil(object oPC, int nUntil)
{
    sqlquery q = SqlPrepareQueryCampaign("familiar",
        "UPDATE fam_familiar SET vigil_until = @until, task = 0, task_started = 0 "
        "WHERE uuid = @uuid");
    SqlBindInt   (q, "@until", nUntil);
    SqlBindString(q, "@uuid",  GetObjectUUID(oPC));
    SqlStep(q);
}

void FamAddBondXp(object oPC, int nAmt)
{
    sqlquery q = SqlPrepareQueryCampaign("familiar",
        "UPDATE fam_familiar "
        "SET bond_xp = MIN(bond_xp + @amt, @max) "
        "WHERE uuid = @uuid");
    SqlBindInt   (q, "@amt",  nAmt);
    SqlBindInt   (q, "@max",  FAM_BOND_MAX);
    SqlBindString(q, "@uuid", GetObjectUUID(oPC));
    SqlStep(q);
}

void FamSetHp(object oPC, int nHp)
{
    sqlquery q = SqlPrepareQueryCampaign("familiar",
        "UPDATE fam_familiar SET hp = MAX(0, MIN(@hp, max_hp)) WHERE uuid = @uuid");
    SqlBindInt   (q, "@hp",   nHp);
    SqlBindString(q, "@uuid", GetObjectUUID(oPC));
    SqlStep(q);
}

void FamStartMourning(object oPC)
{
    sqlquery q = SqlPrepareQueryCampaign("familiar",
        "UPDATE fam_familiar "
        "SET mourning_until = strftime('%s','now') + @dur, hp = 0, task = 0, task_started = 0 "
        "WHERE uuid = @uuid");
    SqlBindInt   (q, "@dur",  FAM_MOURN_DURATION);
    SqlBindString(q, "@uuid", GetObjectUUID(oPC));
    SqlStep(q);
}

void FamEndMourning(object oPC)
{
    sqlquery q = SqlPrepareQueryCampaign("familiar",
        "UPDATE fam_familiar "
        "SET mourning_until = 0, hp = max_hp "
        "WHERE uuid = @uuid");
    SqlBindString(q, "@uuid", GetObjectUUID(oPC));
    SqlStep(q);
}

void FamDeleteBond(object oPC)
{
    sqlquery q = SqlPrepareQueryCampaign("familiar",
        "DELETE FROM fam_familiar WHERE uuid = @uuid");
    SqlBindString(q, "@uuid", GetObjectUUID(oPC));
    SqlStep(q);
}

void FamSetCarry(object oPC, string sItemJson)
{
    sqlquery q = SqlPrepareQueryCampaign("familiar",
        "UPDATE fam_familiar SET carry_json = @json WHERE uuid = @uuid");
    SqlBindString(q, "@json", sItemJson);
    SqlBindString(q, "@uuid", GetObjectUUID(oPC));
    SqlStep(q);
}

void FamSetDismissed(object oPC, int bDismissed)
{
    sqlquery q = SqlPrepareQueryCampaign("familiar",
        "UPDATE fam_familiar SET dismissed = @d WHERE uuid = @uuid");
    SqlBindInt   (q, "@d",    bDismissed);
    SqlBindString(q, "@uuid", GetObjectUUID(oPC));
    SqlStep(q);
}

void FamLogEvent(object oPC, string sEvent, string sDetail)
{
    sqlquery q = SqlPrepareQueryCampaign("familiar",
        "INSERT INTO fam_log (uuid, event_type, detail) VALUES (@uuid, @ev, @det)");
    SqlBindString(q, "@uuid", GetObjectUUID(oPC));
    SqlBindString(q, "@ev",   sEvent);
    SqlBindString(q, "@det",  sDetail);
    SqlStep(q);
}

int FamNowUnix()
{
    sqlquery q = SqlPrepareQueryCampaign("familiar", "SELECT strftime('%s','now')");
    if(SqlStep(q)) return SqlGetInt(q, 0);
    return 0;
}
