// lib_rit_def.nss - Ritual Circles: constants, ritual data, participant helpers

#include "lib_nui"
#include "sql_rit"

// ============================================================
// Forward declarations
// ============================================================

void RitOpenWindow(object oPC, object oCircle);
void RitFeedWindow(object oPC, int nToken, string sTag);
void RitUpdateAllWindows(string sTag);
void RitNotifyParticipants(string sTag, string sMsg);
void RitJoin(object oPC, string sTag);
void RitLeave(object oPC, string sTag);
void RitSetType(object oPC, string sTag, int nType);
void RitBegin(object oPC, string sTag);
void RitCancel(object oPC, string sTag);
void RitComplete(string sTag, int nType, json jParts);
void RitProcessHeartbeat();

// ============================================================
// Window / event IDs
// ============================================================

const string RIT_WINDOW    = "RIT_WINDOW";
const string RIT_EV_SCRIPT = "lib_rit_ev";

// ============================================================
// NUI bind names
// ============================================================

const string RIT_BIND_HEADER       = "rit_header";      // window title label
const string RIT_BIND_STATUS       = "rit_status";      // state label
const string RIT_BIND_FLAVOR       = "rit_flavor";      // flavor text
const string RIT_BIND_REQ_LABEL    = "rit_req_lbl";     // requirements text
const string RIT_BIND_TYPE_NAMES   = "rit_type_names";  // JsonArray<string> for type list
const string RIT_BIND_TYPE_ENC     = "rit_type_enc";    // JsonArray<bool>  for type list
const string RIT_BIND_TYPE_VIS     = "rit_type_vis";    // bool: show type list group
const string RIT_BIND_PART_HEADER  = "rit_part_hdr";    // "Uczestnicy (n/min):"
const string RIT_BIND_PART_NAMES   = "rit_part_names";  // JsonArray<string>
const string RIT_BIND_PART_COLORS  = "rit_part_colors"; // JsonArray<json NuiColor>
const string RIT_BIND_PART_LEN     = "rit_part_len";    // JsonInt row count
const string RIT_BIND_PROGRESS     = "rit_progress";    // float 0.0-1.0
const string RIT_BIND_PROG_VIS     = "rit_prog_vis";    // bool
const string RIT_BIND_PROG_LABEL   = "rit_prog_lbl";    // "X sek. pozostało"
const string RIT_BIND_JOIN_ENA     = "rit_join_ena";
const string RIT_BIND_LEAVE_ENA    = "rit_leave_ena";
const string RIT_BIND_BEGIN_ENA    = "rit_begin_ena";
const string RIT_BIND_CANCEL_ENA   = "rit_cancel_ena";

// ============================================================
// Button / element IDs
// ============================================================

const string RIT_BTN_CLOSE    = "rit_close";
const string RIT_BTN_JOIN     = "rit_join";
const string RIT_BTN_LEAVE    = "rit_leave";
const string RIT_BTN_BEGIN    = "rit_begin";
const string RIT_BTN_CANCEL   = "rit_cancel";
const string RIT_BTN_TYPE_ROW = "rit_type_row"; // NuiList row button

// ============================================================
// PC local variables
// ============================================================

const string RIT_LVAR_CIRCLE = "RIT_CIRCLE"; // tag of currently tracked circle

// ============================================================
// Window dimensions
// ============================================================

const float RIT_W = 480.0;
const float RIT_H = 560.0;

// ============================================================
// Timing
// ============================================================

const int RIT_CASTING_SEC  = 60;  // channeling duration
const int RIT_COOLDOWN_SEC = 600; // cooldown after completion

// ============================================================
// Ritual type IDs  (0 = none/unset)
// ============================================================

const int RIT_TYPE_NONE          = 0;
const int RIT_TYPE_DARK_BLESSING = 1;
const int RIT_TYPE_BLOOD_BINDING = 2;
const int RIT_TYPE_SOUL_CALLING  = 3;
const int RIT_TYPE_CURSE_WEAVING = 4;
const int RIT_TYPE_COUNT         = 4;

// ============================================================
// Circle state IDs
// ============================================================

const int RIT_STATE_IDLE      = 0;
const int RIT_STATE_GATHERING = 1;
const int RIT_STATE_CASTING   = 2;
const int RIT_STATE_COOLDOWN  = 3;

// ============================================================
// Ritual data
// ============================================================

string RitTypeName(int nType)
{
    switch(nType)
    {
        case RIT_TYPE_DARK_BLESSING: return "Błogosławieństwo Mroku";
        case RIT_TYPE_BLOOD_BINDING: return "Pakt Krwi";
        case RIT_TYPE_SOUL_CALLING:  return "Przywołanie Ducha";
        case RIT_TYPE_CURSE_WEAVING: return "Splot Klątwy";
    }
    return "—";
}

string RitTypeDesc(int nType)
{
    switch(nType)
    {
        case RIT_TYPE_DARK_BLESSING:
            return "Ciemność zstępuje na uczestników. Wszyscy przez godzinę uderzają celniej "
                 + "i silniej — jak drapieżniki czerpiące moc ze zmroku.";
        case RIT_TYPE_BLOOD_BINDING:
            return "Krew zebranych miesza się w kręgu. Ból staje się siłą — rytuał leczy "
                 + "uczestników do 75% HP, kosztem 20% życia każdego z nich.";
        case RIT_TYPE_SOUL_CALLING:
            return "Głos lekceważących żywych dociera do zaświatów. Zjawa o niepojętej sile "
                 + "zostaje przywołana i służy liderowi przez pół godziny.";
        case RIT_TYPE_CURSE_WEAVING:
            return "Zbiorowa nienawiść uczestników zostaje spleciона w klątwę. "
                 + "Każdy niesie ją w sobie — wrogowie w pobliżu rzucają słabiej.";
    }
    return "";
}

int RitTypeMinParts(int nType)
{
    switch(nType)
    {
        case RIT_TYPE_DARK_BLESSING: return 2;
        case RIT_TYPE_BLOOD_BINDING: return 3;
        case RIT_TYPE_SOUL_CALLING:  return 4;
        case RIT_TYPE_CURSE_WEAVING: return 2;
    }
    return 2;
}

// Tag of item the leader must hold (consumed on ritual begin).
string RitTypeItemTag(int nType)
{
    switch(nType)
    {
        case RIT_TYPE_DARK_BLESSING: return "rit_candle_black";
        case RIT_TYPE_BLOOD_BINDING: return "rit_vial_blood";
        case RIT_TYPE_SOUL_CALLING:  return "rit_soul_gem";
        case RIT_TYPE_CURSE_WEAVING: return "rit_effigy";
    }
    return "";
}

string RitTypeItemName(int nType)
{
    switch(nType)
    {
        case RIT_TYPE_DARK_BLESSING: return "Czarna świeca";
        case RIT_TYPE_BLOOD_BINDING: return "Fiolka krwi";
        case RIT_TYPE_SOUL_CALLING:  return "Klejnot duszy";
        case RIT_TYPE_CURSE_WEAVING: return "Kukła ofiarna";
    }
    return "—";
}

string RitStateName(int nState)
{
    switch(nState)
    {
        case RIT_STATE_IDLE:      return "Krąg oczekuje";
        case RIT_STATE_GATHERING: return "Zbieranie uczestników";
        case RIT_STATE_CASTING:   return "Rytuał w toku";
        case RIT_STATE_COOLDOWN:  return "Krąg odpoczywa";
    }
    return "—";
}

// ============================================================
// Participant helpers
// ============================================================

int RitIsParticipant(object oPC, string sTag)
{
    json jData = RitGetCircle(sTag);
    if(JsonGetType(jData) == JSON_TYPE_NULL) return FALSE;
    json jParts = JsonParse(JsonGetString(JsonObjectGet(jData, "participants_json")));
    string sUUID = GetObjectUUID(oPC);
    int i, n = JsonGetLength(jParts);
    for(i = 0; i < n; i++)
        if(JsonGetString(JsonArrayGet(jParts, i)) == sUUID) return TRUE;
    return FALSE;
}

int RitIsLeader(object oPC, string sTag)
{
    json jData = RitGetCircle(sTag);
    if(JsonGetType(jData) == JSON_TYPE_NULL) return FALSE;
    return JsonGetString(JsonObjectGet(jData, "leader_uuid")) == GetObjectUUID(oPC);
}

int RitPartCount(string sTag)
{
    json jData = RitGetCircle(sTag);
    if(JsonGetType(jData) == JSON_TYPE_NULL) return 0;
    return JsonGetLength(JsonParse(JsonGetString(JsonObjectGet(jData, "participants_json"))));
}

// Resolve UUID to a name, checking online PCs first.
string RitGetNameByUUID(string sUUID)
{
    object oPC = GetFirstPC();
    while(GetIsObjectValid(oPC))
    {
        if(GetObjectUUID(oPC) == sUUID) return GetName(oPC);
        oPC = GetNextPC();
    }
    return "Nieobecny";
}

object RitGetPCByUUID(string sUUID)
{
    object oPC = GetFirstPC();
    while(GetIsObjectValid(oPC))
    {
        if(GetObjectUUID(oPC) == sUUID) return oPC;
        oPC = GetNextPC();
    }
    return OBJECT_INVALID;
}

// Returns TRUE if the leader is online and holds the required ritual item.
int RitLeaderHasItem(string sTag)
{
    json jData = RitGetCircle(sTag);
    if(JsonGetType(jData) == JSON_TYPE_NULL) return FALSE;
    string sLeaderUUID = JsonGetString(JsonObjectGet(jData, "leader_uuid"));
    if(sLeaderUUID == "") return FALSE;
    object oLeader = RitGetPCByUUID(sLeaderUUID);
    if(!GetIsObjectValid(oLeader)) return FALSE;
    int nType = JsonGetInt(JsonObjectGet(jData, "ritual_type"));
    string sItemTag = RitTypeItemTag(nType);
    if(sItemTag == "") return TRUE;
    return GetIsObjectValid(GetItemPossessedBy(oLeader, sItemTag));
}
