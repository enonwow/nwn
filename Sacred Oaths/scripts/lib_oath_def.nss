// lib_oath_def.nss — constants, bind IDs and forward declarations for Sacred Oaths

#include "lib_nui"
#include "sql_oath"

// ---- Forward declarations ----
void OathOpenWindow(object oPC);
void OathApplyEffects(object oPC, int nOathId);
void OathRemoveEffects(object oPC);
void OathBreak(object oPC, string sReason);
void OathCheckViolations(object oPC);
void OathRestoreOnLogin(object oPC);
void FeedOathDetail(object oPC, int nToken, int nOathId);
void FeedOathStatus(object oPC, int nToken);
void FeedOathRows(object oPC, int nToken, int nSelectedId);
void OathCreateConfirmPopup(object oPC, int nOathId, string sType);
void OathDoSwear(object oPC, int nOathId);
void OathDoRenounce(object oPC);
string OathGetName(int nId);
string OathGetBonusText(int nId);
string OathGetRestrText(int nId);
string OathGetLoreText(int nId);
int    OathGetCost(int nId);

// ---- Window IDs ----
const string OATH_WINDOW       = "OATH_WINDOW";
const string OATH_EV_SCRIPT    = "lib_oath_ev";
const string OATH_WIN_CONFIRM  = "OATH_WIN_CONFIRM";

// ---- Bind IDs ----
const string OATH_BIND_ACTIVE_LBL  = "oath_active_lbl";
const string OATH_BIND_ACTIVE_COL  = "oath_active_col";
const string OATH_BIND_DET_NAME    = "oath_det_name";
const string OATH_BIND_DET_BONUS   = "oath_det_bonus";
const string OATH_BIND_DET_RESTR   = "oath_det_restr";
const string OATH_BIND_DET_LORE    = "oath_det_lore";
const string OATH_BIND_DET_COST    = "oath_det_cost";
const string OATH_BIND_SWEAR_ENA   = "oath_swear_ena";
const string OATH_BIND_SWEAR_LBL   = "oath_swear_lbl";
const string OATH_BIND_REN_ENA     = "oath_ren_ena";
const string OATH_BIND_CONF_MSG    = "oath_conf_msg";

// Per-row binds: append IntToString(oath_id) to get the specific bind
const string OATH_BIND_ROW_ENC     = "oath_row_enc";  // + "1".."5"

// ---- Button IDs ----
const string OATH_BTN_CLOSE        = "oath_btn_close";
const string OATH_BTN_ROW          = "oath_btn_row";  // + "1".."5"
const string OATH_BTN_SWEAR        = "oath_btn_swear";
const string OATH_BTN_RENOUNCE     = "oath_btn_renounce";
const string OATH_BTN_YES          = "oath_btn_yes";
const string OATH_BTN_NO           = "oath_btn_no";
const string OATH_BTN_ATONE        = "oath_btn_atone";

// ---- LVARs on PC ----
const string OATH_LVAR_SEL         = "OATH_SEL";
const string OATH_LVAR_CONFIRM     = "OATH_CONFIRM";  // "swear" | "renounce" | "atone"
const string OATH_LVAR_HB_CNT      = "OATH_HB_CNT";

// ---- Layout ----
const float  OATH_W                = 680.0;
const float  OATH_H                = 480.0;

// ---- Oath IDs ----
const int    OATH_COUNT            = 5;
const int    OATH_POVERTY          = 1;
const int    OATH_IRON             = 2;
const int    OATH_VENGEANCE        = 3;
const int    OATH_BLOOD            = 4;
const int    OATH_SILENCE          = 5;

// ---- Oath costs (gold) ----
const int    OATH_COST_POVERTY     = 200;
const int    OATH_COST_IRON        = 150;
const int    OATH_COST_VENGEANCE   = 300;
const int    OATH_COST_BLOOD       = 0;
const int    OATH_COST_SILENCE     = 150;
const int    OATH_COST_ATONE       = 500;  // gold to lift the Oathbreaker curse

// ---- Mechanic parameters ----
const int    OATH_POVERTY_CAP      = 500;   // max gold for Poverty oath
const int    OATH_BLOOD_DRAIN_PCT  = 5;     // % max HP drained per violation check
const int    OATH_MAX_VIOLATIONS   = 3;     // violations before oath shatters
const int    OATH_HB_TICKS         = 10;    // module heartbeats between violation checks (~60 s)

const string OATH_EFFECT_TAG       = "SACRED_OATH";
const string OATH_CURSE_TAG        = "OATH_BREAKER";
