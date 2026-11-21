#include "lib_nui"
#include "sql_vamp"

// ----------------------------------------------------------------
// Forward declarations
// ----------------------------------------------------------------

void CreateVampWindow(object oPC);
void VampUpdateUI(object oPC, int nToken);
void VampApplyEffects(object oPC, int nBlood);
void VampRemoveEffects(object oPC);
void VampFeedOnTarget(object oPC, object oTarget);
void VampInfectPC(object oPC);
void VampCurePC(object oPC);
void VampOnHeartbeat(object oPC);

// ----------------------------------------------------------------
// NUI window / bind names  (prefix: vamp_)
// ----------------------------------------------------------------

const string VAMP_WINDOW        = "VAMP_WINDOW";
const string VAMP_EV_SCRIPT     = "lib_vamp_ev";
const string VAMP_WIN_GEOM      = "vamp_win_geom";

const string VAMP_BIND_BLOOD_VAL  = "vamp_blood_val";    // float 0.0-1.0 for NuiProgress
const string VAMP_BIND_BLOOD_LBL  = "vamp_blood_lbl";    // "Krew: 67/100"
const string VAMP_BIND_STATUS_LBL = "vamp_status_lbl";   // hunger tier name
const string VAMP_BIND_STATUS_COL = "vamp_status_col";   // tier colour (json color)
const string VAMP_BIND_EFFECTS_LBL= "vamp_effects_lbl";  // active modifiers line
const string VAMP_BIND_SUN_LBL    = "vamp_sun_lbl";      // daylight hazard line
const string VAMP_BIND_SUN_COL    = "vamp_sun_col";      // daylight colour
const string VAMP_BIND_FEED_ENA   = "vamp_feed_ena";
const string VAMP_BIND_CURE_LBL   = "vamp_cure_lbl";
const string VAMP_BIND_CURE_ENA   = "vamp_cure_ena";

// ----------------------------------------------------------------
// Button IDs
// ----------------------------------------------------------------

const string VAMP_BTN_CLOSE = "vamp_btn_close";
const string VAMP_BTN_FEED  = "vamp_btn_feed";
const string VAMP_BTN_CURE  = "vamp_btn_cure";

// ----------------------------------------------------------------
// Local variable keys on PC object
// ----------------------------------------------------------------

const string VAMP_LVAR_IS_FEEDING = "VAMP_IS_FEEDING"; // 1 while targeting mode active
const string VAMP_LVAR_TIER       = "VAMP_TIER";       // last applied tier (0-5)

// ----------------------------------------------------------------
// Effect tags — allows removing only our effects
// ----------------------------------------------------------------

const string VAMP_TAG_BUFF   = "VAMP_BUFF";
const string VAMP_TAG_DEBUFF = "VAMP_DEBUFF";
const string VAMP_TAG_HEAVY  = "VAMP_HEAVY";   // frenzy + blood-zero debuffs

// ----------------------------------------------------------------
// Blood level tier boundaries
// ----------------------------------------------------------------

const int VAMP_TIER_SATED    = 75;  // 75-100 → buffs
const int VAMP_TIER_FED      = 50;  // 50-74  → minor buffs
const int VAMP_TIER_NEUTRAL  = 25;  // 25-49  → no modifiers
const int VAMP_TIER_STARVING = 10;  // 10-24  → minor debuffs
                                    //  1-9   → heavy debuffs + slow (frenzy)
                                    //  0     → incapacitating debuffs

// ----------------------------------------------------------------
// Tuning
// ----------------------------------------------------------------

const int   VAMP_FEED_BLOOD_GAIN = 25;  // blood gained per successful feed
const int   VAMP_FEED_HP_DRAIN   = 15;  // HP drained from target per feed
const int   VAMP_HB_DRAIN        = 1;   // blood lost per 6 s heartbeat tick
const float VAMP_FEED_RANGE      = 3.5; // max metres to feed

// ----------------------------------------------------------------
// Cure item
// ----------------------------------------------------------------

const string VAMP_CURE_ITEM_TAG = "vamp_holy_blood"; // resref / tag of consumable

// ----------------------------------------------------------------
// Window dimensions
// ----------------------------------------------------------------

const float VAMP_W = 360.0;
const float VAMP_H = 310.0;
