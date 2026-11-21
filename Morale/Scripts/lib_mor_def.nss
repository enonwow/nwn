#include "lib_nui"

// ----------------------------------------------------------------
// Forward declarations
// ----------------------------------------------------------------
void MorOpenWindow(object oPC);
void MorFeedWindow(object oPC, int nToken);
int  MorGet(object oPC);
void MorSet(object oPC, int nValue);
void MorApplyPenalties(object oPC);
void MorRemovePenalties(object oPC);
void MorAddLog(object oPC, string sEntry);
void MorTick(object oPC);
void MorRestoreOnRest(object oPC);
void MorOnModuleLoad();

// ----------------------------------------------------------------
// Window identifiers
// ----------------------------------------------------------------
const string MOR_WINDOW           = "MOR_WINDOW";
const string MOR_EV_SCRIPT        = "lib_mor_ev";
const string MOR_WIN_GEOM         = "mor_win_geom";

// ----------------------------------------------------------------
// NUI bind names
// ----------------------------------------------------------------
const string MOR_BIND_STATE_LBL   = "mor_state_lbl";    // text: "Spokojny / Wzburzony / ..."
const string MOR_BIND_BAR_VAL     = "mor_bar_val";      // float 0.0-1.0 for progress bar
const string MOR_BIND_MORALE_NUM  = "mor_morale_num";   // "73 / 100"
const string MOR_BIND_LOG_ROWS    = "mor_log_rows";     // json array of log strings
const string MOR_BIND_LOG_ENC     = "mor_log_enc";      // json array bools (selected)
const string MOR_BIND_DEBUFF_LBL  = "mor_debuff_lbl";   // active penalties text
const string MOR_BIND_STEEL_ENA   = "mor_steel_ena";    // "Zahartuj się" button enabled
const string MOR_BIND_STEEL_TIP   = "mor_steel_tip";    // tooltip with cooldown info

// ----------------------------------------------------------------
// Button IDs
// ----------------------------------------------------------------
const string MOR_BTN_CLOSE        = "mor_btn_close";
const string MOR_BTN_STEEL        = "mor_btn_steel";    // "Zahartuj się" (restore 10 morale, costs gold, 60s cooldown)
const string MOR_BTN_REFRESH      = "mor_btn_refresh";

// ----------------------------------------------------------------
// Local variables on PC
// ----------------------------------------------------------------
const string MOR_LVAR_LOG         = "MOR_LOG_JSON";     // JsonArray of strings (last 8)
const string MOR_LVAR_PENALTY     = "MOR_PENALTY";      // 0=none 1=shaken 2=frightened 3=panicked 4=broken
const string MOR_LVAR_STEEL_TIME  = "MOR_STEEL_TIME";   // last time "Zahartuj się" was used
const string MOR_LVAR_FLEE_SENT   = "MOR_FLEE_SENT";    // seconds since last flee was forced
const string MOR_LVAR_HB_RUNNING  = "MOR_HB_RUNNING";   // 1 if personal heartbeat is active

// ----------------------------------------------------------------
// Effect tag — used to identify morale penalty effects
// ----------------------------------------------------------------
const string MOR_EFFECT_TAG       = "MOR_PENALTY_EFFECT";

// ----------------------------------------------------------------
// Morale thresholds
// ----------------------------------------------------------------
const int MOR_MAX                 = 100;
const int MOR_MIN                 = 0;
const int MOR_THRESHOLD_SHAKEN    = 74;   // below this -> shaken
const int MOR_THRESHOLD_FRIGHTENED= 49;   // below this -> frightened
const int MOR_THRESHOLD_PANICKED  = 24;   // below this -> panicked
const int MOR_THRESHOLD_BROKEN    = 9;    // below this -> broken

// ----------------------------------------------------------------
// Heartbeat interval (seconds, must be multiple of 6 for NWN heartbeats)
// ----------------------------------------------------------------
const float MOR_HB_DELAY          = 6.0;

// ----------------------------------------------------------------
// Terror trigger drain amounts (per heartbeat tick)
// ----------------------------------------------------------------
const int MOR_DRAIN_UNDEAD        = 3;
const int MOR_DRAIN_DARK          = 1;
const int MOR_DRAIN_OUTNUMBERED   = 2;
const int MOR_DRAIN_LOWHP         = 1;
const int MOR_RESTORE_PASSIVE     = 1;    // per tick when no triggers active

// ----------------------------------------------------------------
// Campaign DB name (for global data; per-PC uses object vars + this campaign)
// ----------------------------------------------------------------
const string MOR_DB               = "morale";

// ----------------------------------------------------------------
// Layout dimensions
// ----------------------------------------------------------------
const float MOR_WIN_W             = 340.0;
const float MOR_WIN_H             = 410.0;

// ----------------------------------------------------------------
// Gold cost for "Zahartuj się"
// ----------------------------------------------------------------
const int MOR_STEEL_GOLD_COST     = 10;
const int MOR_STEEL_MORALE_GAIN   = 15;
const int MOR_STEEL_COOLDOWN      = 60;  // seconds

