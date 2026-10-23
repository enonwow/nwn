// SQL layer for Combat Stances.
// Campaign DB name: "stances"
// All per-character data is keyed by PC UUID.

void StnCreateTables()
{
    sqlquery q = SqlPrepareQueryCampaign("stances",
        "CREATE TABLE IF NOT EXISTS stn_chars ("
        "  uuid         TEXT PRIMARY KEY,"
        "  active       INTEGER DEFAULT 0,"
        "  unlocked     TEXT    DEFAULT '[0,1,2]'"
        ")");
    SqlStep(q);
}

// Returns {active: int, unlocked: json array} or NULL object if not found.
json StnGetChar(object oPC)
{
    sqlquery q = SqlPrepareQueryCampaign("stances",
        "SELECT active, unlocked FROM stn_chars WHERE uuid = @uuid");
    SqlBindString(q, "@uuid", GetObjectUUID(oPC));
    if(!SqlStep(q)) return JsonNull();

    json jRow = JsonObject();
    jRow = JsonObjectSet(jRow, "active",   JsonInt   (SqlGetInt   (q, 0)));
    jRow = JsonObjectSet(jRow, "unlocked", JsonParse (SqlGetString(q, 1)));
    return jRow;
}

// Upsert character row.
void StnSaveChar(object oPC, int nActive, json jUnlocked)
{
    sqlquery q = SqlPrepareQueryCampaign("stances",
        "INSERT INTO stn_chars (uuid, active, unlocked) VALUES (@uuid, @active, @unlocked) "
        "ON CONFLICT(uuid) DO UPDATE SET active = @active, unlocked = @unlocked");
    SqlBindString(q, "@uuid",     GetObjectUUID(oPC));
    SqlBindInt   (q, "@active",   nActive);
    SqlBindString(q, "@unlocked", JsonDump(jUnlocked));
    SqlStep(q);
}

void StnRegisterPlayer(object oPC)
{
    sqlquery q = SqlPrepareQueryCampaign("stances",
        "INSERT OR IGNORE INTO stn_chars (uuid, active, unlocked) VALUES (@uuid, 0, '[0,1,2]')");
    SqlBindString(q, "@uuid", GetObjectUUID(oPC));
    SqlStep(q);
}

int StnGetActiveStance(object oPC)
{
    json jRow = StnGetChar(oPC);
    if(JsonGetType(jRow) == JSON_TYPE_NULL) return 0;
    return JsonGetInt(JsonObjectGet(jRow, "active"));
}

void StnSetActiveStance(object oPC, int nStance)
{
    json jRow = StnGetChar(oPC);
    if(JsonGetType(jRow) == JSON_TYPE_NULL)
    {
        StnRegisterPlayer(oPC);
        jRow = StnGetChar(oPC);
    }
    json jUnlocked = JsonObjectGet(jRow, "unlocked");
    StnSaveChar(oPC, nStance, jUnlocked);
}

json StnGetUnlocked(object oPC)
{
    json jRow = StnGetChar(oPC);
    if(JsonGetType(jRow) == JSON_TYPE_NULL) return JsonParse("[0,1,2]");
    return JsonObjectGet(jRow, "unlocked");
}

// Returns 1 if stance nId is in the unlocked array, else 0.
int StnIsUnlocked(object oPC, int nId)
{
    json jUnlocked = StnGetUnlocked(oPC);
    int nCount = JsonGetLength(jUnlocked);
    int i;
    for(i = 0; i < nCount; i++)
    {
        if(JsonGetInt(JsonArrayGet(jUnlocked, i)) == nId)
            return 1;
    }
    return 0;
}

void StnUnlockStance(object oPC, int nId)
{
    json jRow = StnGetChar(oPC);
    if(JsonGetType(jRow) == JSON_TYPE_NULL)
    {
        StnRegisterPlayer(oPC);
        jRow = StnGetChar(oPC);
    }
    json jUnlocked = JsonObjectGet(jRow, "unlocked");
    int nActive    = JsonGetInt(JsonObjectGet(jRow, "active"));

    // Prevent duplicates
    if(StnIsUnlocked(oPC, nId)) return;

    jUnlocked = JsonArrayInsert(jUnlocked, JsonInt(nId));
    StnSaveChar(oPC, nActive, jUnlocked);
}
