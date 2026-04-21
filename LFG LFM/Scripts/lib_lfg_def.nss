// lib_lfg_def.nss
// LFG/LFM system - constants, data storage, CRUD, validation, cleanup

// ============================================================
// Constants - window
// ============================================================
const string LFG_WINDOW    = "LFG_WINDOW";
const string LFG_EV_SCRIPT = "lib_lfg_ev";

// ============================================================
// Constants - NuiSetGroupLayout swap group ID
// ============================================================
const string LFG_SWAP_GROUP = "LFG_SWAP_GROUP";

// ============================================================
// Constants - storage keys (LocalJson on GetModule())
// ============================================================
const string LFG_GROUPS_KEY     = "LFG_GROUPS";
const string LFG_APPLICANTS_KEY = "LFG_APPLICANTS";

// ============================================================
// Constants - categories
// ============================================================
const string LFG_CAT_EXP     = "EXP";
const string LFG_CAT_DUNGEON = "Dungeon";
const string LFG_CAT_RP      = "RP";
const string LFG_CAT_PVP     = "PvP";
const string LFG_CAT_ALL     = "";

const int LFG_CAT_COUNT = 4;

// ============================================================
// Constants - group JSON fields
// ============================================================
const string LFG_FIELD_UUID        = "uuid";
const string LFG_FIELD_LEADER_NAME = "leader_name";
const string LFG_FIELD_NAME        = "name";
const string LFG_FIELD_DESC        = "desc";
const string LFG_FIELD_LIMIT       = "limit";
const string LFG_FIELD_LEVEL_MIN   = "level_min";
const string LFG_FIELD_LEVEL_MAX   = "level_max";
const string LFG_FIELD_CATEGORY    = "category";
const string LFG_FIELD_CLASSES     = "classes";
const string LFG_FIELD_PENDING     = "pending";

// ============================================================
// Constants - limits
// ============================================================
const int LFG_MAX_APPLICATIONS = 3;
const int LFG_TICK_SECONDS     = 6;

// ============================================================
// Constants - LVAR on PC
// ============================================================
const string LFG_LVAR_TOKEN    = "LFG_LVAR_TOKEN";
const string LFG_LVAR_CATEGORY = "LFG_LVAR_CATEGORY";
const string LFG_LVAR_MODE     = "LFG_LVAR_MODE";
const string LFG_LVAR_SEL_UUID  = "LFG_LVAR_SEL_UUID";
const string LFG_LVAR_PREV_VIEW = "LFG_PREV";

// ============================================================
// Constants - modes
// ============================================================
const string LFG_MODE_LFG = "LFG";
const string LFG_MODE_LFM = "LFM";

// ============================================================
// Constants - resrefs
// ============================================================
const string LFG_RES_BG      = "lfg_lfm_bg";
const string LFG_RES_LFM     = "lfg_lfm_1";
const string LFG_RES_LFG     = "lfg_lfm_2";
const string LFG_RES_EXP     = "lfg_lfm_3";
const string LFG_RES_DUNGEON = "lfg_lfm_4";
const string LFG_RES_RP      = "lfg_lfm_5";
const string LFG_RES_PVP     = "lfg_lfm_6";
const string LFG_RES_LIST    = "lfg_lfm_7";
const string LFG_RES_ALL     = "lfg_lfm_8";
const string LFG_RES_BACK    = "lfg_lfm_back";
const string LFG_RES_CLOSE   = "lfg_lfm_close";

// ============================================================
// Constants - tooltips
// ============================================================
const string LFG_TIP_LFM     = "Looking for More - create a group listing";
const string LFG_TIP_LFG     = "Looking for Group - browse available groups";
const string LFG_TIP_LIST    = "My listings - view your active applications or group";
const string LFG_TIP_EXP     = "Leveling";
const string LFG_TIP_DUNGEON = "Dungeons";
const string LFG_TIP_RP      = "RP";
const string LFG_TIP_PVP     = "PvP";
const string LFG_TIP_ALL     = "All categories";
const string LFG_TIP_BACK    = "Back to previous view";
const string LFG_TIP_CLOSE   = "Close window (listing stays active)";

// ============================================================
// Constants - window dimensions
// ============================================================
const float LFG_WINDOW_W = 1536.0;
const float LFG_WINDOW_H = 1024.0;

// ============================================================
// Helper - category name by index
// ============================================================
string LfgCatByIndex(int nIdx)
{
    if(nIdx == 0) return LFG_CAT_EXP;
    if(nIdx == 1) return LFG_CAT_DUNGEON;
    if(nIdx == 2) return LFG_CAT_RP;
    if(nIdx == 3) return LFG_CAT_PVP;
    return "";
}

// Returns resref for a category icon
string LfgCatResref(string sCat)
{
    if(sCat == LFG_CAT_EXP)     return LFG_RES_EXP;
    if(sCat == LFG_CAT_DUNGEON) return LFG_RES_DUNGEON;
    if(sCat == LFG_CAT_RP)      return LFG_RES_RP;
    if(sCat == LFG_CAT_PVP)     return LFG_RES_PVP;
    return LFG_RES_ALL;
}

// ============================================================
// Storage - groups
// ============================================================

json LfgGetGroups()
{
    json jGroups = GetLocalJson(GetModule(), LFG_GROUPS_KEY);
    if(JsonGetType(jGroups) != JSON_TYPE_OBJECT)
    {
        jGroups = JsonObject();
        jGroups = JsonObjectSet(jGroups, LFG_CAT_EXP,     JsonArray());
        jGroups = JsonObjectSet(jGroups, LFG_CAT_DUNGEON,  JsonArray());
        jGroups = JsonObjectSet(jGroups, LFG_CAT_RP,       JsonArray());
        jGroups = JsonObjectSet(jGroups, LFG_CAT_PVP,      JsonArray());
    }
    return jGroups;
}

void LfgSetGroups(json jGroups)
{
    SetLocalJson(GetModule(), LFG_GROUPS_KEY, jGroups);
}

// ============================================================
// Storage - applicants tracking
// ============================================================

json LfgGetApplicants()
{
    json j = GetLocalJson(GetModule(), LFG_APPLICANTS_KEY);
    if(JsonGetType(j) != JSON_TYPE_OBJECT) j = JsonObject();
    return j;
}

void LfgSetApplicants(json j)
{
    SetLocalJson(GetModule(), LFG_APPLICANTS_KEY, j);
}

// ============================================================
// Internal helper - find group index in category list
// Returns index >= 0 if found, -1 otherwise
// ============================================================
int LfgFindGroupIndex(json jCatList, string sLeaderUuid)
{
    int i;
    int nLen = JsonGetLength(jCatList);
    for(i = 0; i < nLen; i++)
    {
        json jG = JsonArrayGet(jCatList, i);
        if(JsonGetString(JsonObjectGet(jG, LFG_FIELD_UUID)) == sLeaderUuid)
            return i;
    }
    return -1;
}

// ============================================================
// Group CRUD
// ============================================================

void LfgGroupCreate(
    string sLeaderUuid,
    string sLeaderName,
    string sName,
    string sDesc,
    int    nLimit,
    int    nLevelMin,
    int    nLevelMax,
    string sCategory,
    json   jClasses)
{
    json jGroup = JsonObject();
    jGroup = JsonObjectSet(jGroup, LFG_FIELD_UUID,        JsonString(sLeaderUuid));
    jGroup = JsonObjectSet(jGroup, LFG_FIELD_LEADER_NAME, JsonString(sLeaderName));
    jGroup = JsonObjectSet(jGroup, LFG_FIELD_NAME,        JsonString(sName));
    jGroup = JsonObjectSet(jGroup, LFG_FIELD_DESC,        JsonString(sDesc));
    jGroup = JsonObjectSet(jGroup, LFG_FIELD_LIMIT,       JsonInt(nLimit));
    jGroup = JsonObjectSet(jGroup, LFG_FIELD_LEVEL_MIN,   JsonInt(nLevelMin));
    jGroup = JsonObjectSet(jGroup, LFG_FIELD_LEVEL_MAX,   JsonInt(nLevelMax));
    jGroup = JsonObjectSet(jGroup, LFG_FIELD_CATEGORY,    JsonString(sCategory));
    jGroup = JsonObjectSet(jGroup, LFG_FIELD_CLASSES,     jClasses);
    jGroup = JsonObjectSet(jGroup, LFG_FIELD_PENDING,     JsonArray());

    json jGroups  = LfgGetGroups();
    json jCatList = JsonObjectGet(jGroups, sCategory);
    jCatList = JsonArrayInsert(jCatList, jGroup);
    jGroups = JsonObjectSet(jGroups, sCategory, jCatList);
    LfgSetGroups(jGroups);
}

// Returns the group JsonObject for a leader UUID (searches all categories)
// Returns JsonNull() if not found
json LfgGroupGet(string sLeaderUuid)
{
    json jGroups = LfgGetGroups();
    int c;
    for(c = 0; c < LFG_CAT_COUNT; c++)
    {
        string sCat   = LfgCatByIndex(c);
        json jCatList = JsonObjectGet(jGroups, sCat);
        int idx       = LfgFindGroupIndex(jCatList, sLeaderUuid);
        if(idx >= 0) return JsonArrayGet(jCatList, idx);
    }
    return JsonNull();
}

// Returns category string of a leader's group, or "" if not found
string LfgGroupGetCategory(string sLeaderUuid)
{
    json jGroups = LfgGetGroups();
    int c;
    for(c = 0; c < LFG_CAT_COUNT; c++)
    {
        string sCat   = LfgCatByIndex(c);
        json jCatList = JsonObjectGet(jGroups, sCat);
        if(LfgFindGroupIndex(jCatList, sLeaderUuid) >= 0) return sCat;
    }
    return "";
}

// Returns TRUE if a group for sLeaderUuid already exists
int LfgGroupExists(string sLeaderUuid)
{
    return JsonGetType(LfgGroupGet(sLeaderUuid)) != JSON_TYPE_NULL;
}

void LfgGroupRemove(string sLeaderUuid)
{
    json jGroups = LfgGetGroups();
    int c;
    for(c = 0; c < LFG_CAT_COUNT; c++)
    {
        string sCat   = LfgCatByIndex(c);
        json jCatList = JsonObjectGet(jGroups, sCat);
        int idx       = LfgFindGroupIndex(jCatList, sLeaderUuid);
        if(idx >= 0)
        {
            jCatList = JsonArrayDel(jCatList, idx);
            jGroups  = JsonObjectSet(jGroups, sCat, jCatList);
            LfgSetGroups(jGroups);
            return;
        }
    }
}

// Returns list of groups for a category (LFG_CAT_ALL = all categories merged)
json LfgGetGroupList(string sFilter)
{
    json jGroups = LfgGetGroups();
    if(sFilter != LFG_CAT_ALL)
        return JsonObjectGet(jGroups, sFilter);

    // Merge all categories
    json jAll = JsonArray();
    int c;
    for(c = 0; c < LFG_CAT_COUNT; c++)
    {
        string sCat   = LfgCatByIndex(c);
        json jCatList = JsonObjectGet(jGroups, sCat);
        int i, nLen   = JsonGetLength(jCatList);
        for(i = 0; i < nLen; i++)
            jAll = JsonArrayInsert(jAll, JsonArrayGet(jCatList, i));
    }
    return jAll;
}

// ============================================================
// Pending (join requests on a group)
// ============================================================

void LfgPendingAdd(string sLeaderUuid, string sApplicantUuid)
{
    json jGroups = LfgGetGroups();
    int c;
    for(c = 0; c < LFG_CAT_COUNT; c++)
    {
        string sCat   = LfgCatByIndex(c);
        json jCatList = JsonObjectGet(jGroups, sCat);
        int idx       = LfgFindGroupIndex(jCatList, sLeaderUuid);
        if(idx >= 0)
        {
            json jGroup   = JsonArrayGet(jCatList, idx);
            json jPending = JsonObjectGet(jGroup, LFG_FIELD_PENDING);
            jPending = JsonArrayInsert(jPending, JsonString(sApplicantUuid));
            jGroup   = JsonObjectSet(jGroup, LFG_FIELD_PENDING, jPending);
            jCatList = JsonArraySet(jCatList, idx, jGroup);
            jGroups  = JsonObjectSet(jGroups, sCat, jCatList);
            LfgSetGroups(jGroups);
            return;
        }
    }
}

void LfgPendingRemove(string sLeaderUuid, string sApplicantUuid)
{
    json jGroups = LfgGetGroups();
    int c;
    for(c = 0; c < LFG_CAT_COUNT; c++)
    {
        string sCat   = LfgCatByIndex(c);
        json jCatList = JsonObjectGet(jGroups, sCat);
        int idx       = LfgFindGroupIndex(jCatList, sLeaderUuid);
        if(idx >= 0)
        {
            json jGroup   = JsonArrayGet(jCatList, idx);
            json jPending = JsonObjectGet(jGroup, LFG_FIELD_PENDING);
            int i, nLen = JsonGetLength(jPending);
            for(i = 0; i < nLen; i++)
            {
                if(JsonGetString(JsonArrayGet(jPending, i)) == sApplicantUuid)
                {
                    jPending = JsonArrayDel(jPending, i);
                    break;
                }
            }
            jGroup   = JsonObjectSet(jGroup, LFG_FIELD_PENDING, jPending);
            jCatList = JsonArraySet(jCatList, idx, jGroup);
            jGroups  = JsonObjectSet(jGroups, sCat, jCatList);
            LfgSetGroups(jGroups);
            return;
        }
    }
}

int LfgPendingHas(string sLeaderUuid, string sApplicantUuid)
{
    json jGroup = LfgGroupGet(sLeaderUuid);
    if(JsonGetType(jGroup) == JSON_TYPE_NULL) return FALSE;
    json jPending = JsonObjectGet(jGroup, LFG_FIELD_PENDING);
    int i, nLen = JsonGetLength(jPending);
    for(i = 0; i < nLen; i++)
    {
        if(JsonGetString(JsonArrayGet(jPending, i)) == sApplicantUuid)
            return TRUE;
    }
    return FALSE;
}

// ============================================================
// Applicants tracking (per-player list of groups applied to)
// ============================================================

void LfgApplicantAdd(string sApplicantUuid, string sLeaderUuid)
{
    json jApplicants = LfgGetApplicants();
    json jList = JsonObjectGet(jApplicants, sApplicantUuid);
    if(JsonGetType(jList) != JSON_TYPE_ARRAY) jList = JsonArray();
    jList = JsonArrayInsert(jList, JsonString(sLeaderUuid));
    jApplicants = JsonObjectSet(jApplicants, sApplicantUuid, jList);
    LfgSetApplicants(jApplicants);
}

void LfgApplicantRemove(string sApplicantUuid, string sLeaderUuid)
{
    json jApplicants = LfgGetApplicants();
    json jList = JsonObjectGet(jApplicants, sApplicantUuid);
    if(JsonGetType(jList) != JSON_TYPE_ARRAY) return;
    int i, nLen = JsonGetLength(jList);
    for(i = 0; i < nLen; i++)
    {
        if(JsonGetString(JsonArrayGet(jList, i)) == sLeaderUuid)
        {
            jList = JsonArrayDel(jList, i);
            break;
        }
    }
    jApplicants = JsonObjectSet(jApplicants, sApplicantUuid, jList);
    LfgSetApplicants(jApplicants);
}

int LfgApplicantGetCount(string sApplicantUuid)
{
    json jApplicants = LfgGetApplicants();
    json jList = JsonObjectGet(jApplicants, sApplicantUuid);
    if(JsonGetType(jList) != JSON_TYPE_ARRAY) return 0;
    return JsonGetLength(jList);
}

int LfgApplicantHasApplied(string sApplicantUuid, string sLeaderUuid)
{
    json jApplicants = LfgGetApplicants();
    json jList = JsonObjectGet(jApplicants, sApplicantUuid);
    if(JsonGetType(jList) != JSON_TYPE_ARRAY) return FALSE;
    int i, nLen = JsonGetLength(jList);
    for(i = 0; i < nLen; i++)
    {
        if(JsonGetString(JsonArrayGet(jList, i)) == sLeaderUuid)
            return TRUE;
    }
    return FALSE;
}

// Returns JsonArray of leader UUIDs the player has applied to
json LfgApplicantGetList(string sApplicantUuid)
{
    json jApplicants = LfgGetApplicants();
    json jList = JsonObjectGet(jApplicants, sApplicantUuid);
    if(JsonGetType(jList) != JSON_TYPE_ARRAY) return JsonArray();
    return jList;
}

// Remove all applications for a player (e.g. on LFM create or player leave)
void LfgApplicantClear(string sApplicantUuid)
{
    json jList = LfgApplicantGetList(sApplicantUuid);
    int i, nLen = JsonGetLength(jList);
    for(i = 0; i < nLen; i++)
    {
        string sLdrUuid = JsonGetString(JsonArrayGet(jList, i));
        LfgPendingRemove(sLdrUuid, sApplicantUuid);
    }
    json jApplicants = LfgGetApplicants();
    jApplicants = JsonObjectDel(jApplicants, sApplicantUuid);
    LfgSetApplicants(jApplicants);
}

// ============================================================
// Validation
// ============================================================

// Returns TRUE if oApplicant's party satisfies class restrictions
// jGroupClasses = JsonArray of class IDs (empty = no restrictions)
int LfgClassesMatch(object oApplicant, json jGroupClasses)
{
    if(JsonGetLength(jGroupClasses) == 0) return TRUE;

    // Work on a copy - remove matched classes to prevent double-matching
    json jReqs = jGroupClasses;

    object oMember = GetFirstFactionMember(oApplicant, TRUE);
    while(GetIsObjectValid(oMember))
    {
        int bMatched = FALSE;
        int i, nLen  = JsonGetLength(jReqs);
        for(i = 0; i < nLen; i++)
        {
            int nClassId = JsonGetInt(JsonArrayGet(jReqs, i));
            if(GetLevelByClass(nClassId, oMember) > 0)
            {
                jReqs    = JsonArrayDel(jReqs, i);
                bMatched = TRUE;
                break;
            }
        }
        // Party member has no matching class
        if(!bMatched) return FALSE;
        oMember = GetNextFactionMember(oApplicant, TRUE);
    }
    return TRUE;
}

// Returns TRUE if all party members of oApplicant are within [nMin, nMax] level range
int LfgLevelMatch(object oApplicant, int nMin, int nMax)
{
    object oMember = GetFirstFactionMember(oApplicant, TRUE);
    while(GetIsObjectValid(oMember))
    {
        int nLvl = GetHitDice(oMember);
        if(nLvl < nMin || nLvl > nMax) return FALSE;
        oMember = GetNextFactionMember(oApplicant, TRUE);
    }
    return TRUE;
}

// Returns TRUE if player can apply to a group (not over max applications)
int LfgCanApply(object oApplicant)
{
    if(!GetIsPC(oApplicant)) return FALSE;
    return LfgApplicantGetCount(GetObjectUUID(oApplicant)) < LFG_MAX_APPLICATIONS;
}

// Returns TRUE if player has an active LFM group
int LfgIsLeader(object oPC)
{
    return LfgGroupExists(GetObjectUUID(oPC));
}

// ============================================================
// Accept/Reject application
// ============================================================

void LfgAcceptApplication(string sLeaderUuid, string sApplicantUuid)
{
    object oLeader    = GetObjectByUUID(sLeaderUuid);
    object oApplicant = GetObjectByUUID(sApplicantUuid);

    if(!GetIsObjectValid(oLeader) || !GetIsObjectValid(oApplicant)) return;

    // Collect member UUIDs first (AddToParty changes faction mid-iteration)
    json jMembers = JsonArray();
    object oMember = GetFirstFactionMember(oApplicant, TRUE);
    while(GetIsObjectValid(oMember))
    {
        jMembers = JsonArrayInsert(jMembers, JsonString(GetObjectUUID(oMember)));
        oMember = GetNextFactionMember(oApplicant, TRUE);
    }

    // Add all collected members to leader's party
    int nJoined = JsonGetLength(jMembers);
    int m;
    for(m = 0; m < nJoined; m++)
        AddToParty(GetObjectByUUID(JsonGetString(JsonArrayGet(jMembers, m))), oLeader);

    // Destroy applicant's LFG window if open
    int nAppToken = GetLocalInt(oApplicant, LFG_LVAR_TOKEN);
    if(nAppToken != 0)
        NuiDestroy(oApplicant, nAppToken);

    // Clean up pending/applicant tracking
    LfgPendingRemove(sLeaderUuid, sApplicantUuid);
    LfgApplicantRemove(sApplicantUuid, sLeaderUuid);

    // Decrement limit - remove group if full
    json jGroups = LfgGetGroups();
    int c;
    for(c = 0; c < LFG_CAT_COUNT; c++)
    {
        string sCat   = LfgCatByIndex(c);
        json jCatList = JsonObjectGet(jGroups, sCat);
        int idx       = LfgFindGroupIndex(jCatList, sLeaderUuid);
        if(idx >= 0)
        {
            json jGroup = JsonArrayGet(jCatList, idx);
            int nLimit  = JsonGetInt(JsonObjectGet(jGroup, LFG_FIELD_LIMIT)) - nJoined;
            if(nLimit <= 0)
            {
                jCatList = JsonArrayDel(jCatList, idx);
                jGroups  = JsonObjectSet(jGroups, sCat, jCatList);
                LfgSetGroups(jGroups);
                SendMessageToPC(oLeader, "Your group is now full and has been removed from the LFM list.");
            }
            else
            {
                jGroup   = JsonObjectSet(jGroup, LFG_FIELD_LIMIT, JsonInt(nLimit));
                jCatList = JsonArraySet(jCatList, idx, jGroup);
                jGroups  = JsonObjectSet(jGroups, sCat, jCatList);
                LfgSetGroups(jGroups);
            }
            return;
        }
    }
}

void LfgRejectApplication(string sLeaderUuid, string sApplicantUuid)
{
    LfgPendingRemove(sLeaderUuid, sApplicantUuid);
    LfgApplicantRemove(sApplicantUuid, sLeaderUuid);

    object oApplicant = GetObjectByUUID(sApplicantUuid);
    if(GetIsObjectValid(oApplicant))
        SendMessageToPC(oApplicant, "Your join request was rejected.");
}

// ============================================================
// Cleanup on player leave (OnClientLeave)
// ============================================================

void LfgPlayerLeave(object oPC)
{
    string sUuid = GetObjectUUID(oPC);

    // If leader: clean up pending applicants' tracking, then remove group
    json jGroup = LfgGroupGet(sUuid);
    if(JsonGetType(jGroup) != JSON_TYPE_NULL)
    {
        json jPending = JsonObjectGet(jGroup, LFG_FIELD_PENDING);
        int i, nLen = JsonGetLength(jPending);
        for(i = 0; i < nLen; i++)
        {
            string sAppUuid = JsonGetString(JsonArrayGet(jPending, i));
            LfgApplicantRemove(sAppUuid, sUuid);
        }
        LfgGroupRemove(sUuid);
    }

    // If applicant: remove from all pending lists
    json jMyApps = LfgApplicantGetList(sUuid);
    int i, nLen = JsonGetLength(jMyApps);
    for(i = 0; i < nLen; i++)
    {
        string sLeaderUuid = JsonGetString(JsonArrayGet(jMyApps, i));
        LfgPendingRemove(sLeaderUuid, sUuid);
    }

    // Remove applicant entry
    json jApplicants = LfgGetApplicants();
    jApplicants = JsonObjectDel(jApplicants, sUuid);
    LfgSetApplicants(jApplicants);
}

// ============================================================
// Init (OnModuleLoad)
// ============================================================

void LfgInit()
{
    json jGroups = JsonObject();
    jGroups = JsonObjectSet(jGroups, LFG_CAT_EXP,     JsonArray());
    jGroups = JsonObjectSet(jGroups, LFG_CAT_DUNGEON,  JsonArray());
    jGroups = JsonObjectSet(jGroups, LFG_CAT_RP,       JsonArray());
    jGroups = JsonObjectSet(jGroups, LFG_CAT_PVP,      JsonArray());
    LfgSetGroups(jGroups);
    LfgSetApplicants(JsonObject());
}

// ============================================================
// Helper - player class list from classes.2da
// Returns JsonArray of class IDs where PlayerClass == "1"
// ============================================================
json LfgGetPlayerClassIds()
{
    json jResult = JsonArray();
    int i;
    int nCount = Get2DARowCount("classes");
    for(i = 0; i < nCount; i++)
    {
        if(Get2DAString("classes", "PlayerClass", i) != "1") continue;
        jResult = JsonArrayInsert(jResult, JsonInt(i));
    }
    return jResult;
}

// Returns display name for a class ID
string LfgGetClassName(int nClassId)
{
    return GetStringByStrRef(StringToInt(Get2DAString("classes", "Name", nClassId)));
}

// Returns icon resref for a class ID (Icon column from classes.2da)
string LfgGetClassIcon(int nClassId)
{
    return Get2DAString("classes", "Icon", nClassId);
}
