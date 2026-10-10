#include "lib_nui"
#include "sql_astr"

void AstrEnterProjection(object oPC);
void AstrExitProjection(object oPC, int bTimeout);
void AstrTickDown(object oPC);
void AstrPerceiveHidden(object oPC);
void AstrClearPerceiveCD(object oPC);

// ----------------------------------------------------------------
// Window / group IDs
// ----------------------------------------------------------------

const string ASTR_WINDOW    = "ASTR_WINDOW";
const string ASTR_EV_SCRIPT = "lib_astr_ev";
const string ASTR_WIN_GEOM  = "astr_win_geom";

// ----------------------------------------------------------------
// NUI bind IDs
// ----------------------------------------------------------------

const string ASTR_BIND_TIMER        = "astr_timer";
const string ASTR_BIND_STATUS       = "astr_status";
const string ASTR_BIND_PROGRESS     = "astr_progress";
const string ASTR_BIND_STATS        = "astr_stats";
const string ASTR_BIND_PERCEIVE_ENA = "astr_per_ena";
const string ASTR_BIND_PERCEIVE_LBL = "astr_per_lbl";

// ----------------------------------------------------------------
// Button IDs
// ----------------------------------------------------------------

const string ASTR_BTN_RETURN   = "astr_btn_return";
const string ASTR_BTN_PERCEIVE = "astr_btn_perceive";

// ----------------------------------------------------------------
// LVARs stored on the PC object
// ----------------------------------------------------------------

const string ASTR_LVAR_ACTIVE      = "ASTR_ACTIVE";
const string ASTR_LVAR_TIMER_SECS  = "ASTR_TIMER_SECS";
const string ASTR_LVAR_PERCEIVE_CD = "ASTR_PERCEIVE_CD";

// ----------------------------------------------------------------
// Effect tags — lets us remove only our effects without nuking others
// ----------------------------------------------------------------

const string ASTR_EFFECT_TAG     = "ASTR_GHOST";
const string ASTR_EXHAUSTION_TAG = "ASTR_EXHAUSTION";

// ----------------------------------------------------------------
// Tuning constants
// ----------------------------------------------------------------

const int   ASTR_MAX_DURATION     = 180;  // total seconds in projection
const int   ASTR_PERCEIVE_CD_SECS = 30;   // cooldown on Perceive ability
const int   ASTR_EXHAUSTION_DIV   = 30;   // secs per exhaustion tier (tier = secs / div)
const float ASTR_PERCEIVE_RADIUS  = 12.0; // placeable/trap scan radius
const float ASTR_SENSE_RADIUS     = 20.0; // creature sense radius
const float ASTR_W                = 290.0;
const float ASTR_H                = 220.0;
