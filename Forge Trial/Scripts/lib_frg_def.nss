// Constants, bind names, and forward declarations for the Forge Trial module.

#include "lib_nui"
#include "sql_frg"

// Forward declarations
void FrgOpenWindow(object oPC);
void FrgFeedSlots(object oPC, int nToken);
void FrgFeedSelectedItem(object oPC, int nToken);
void FrgFeedMeterZone(object oPC, int nToken, int nPos);
void FrgStartMeter(object oPC, int nToken);
void FrgStopMeter(object oPC);
void FrgExecuteStrike(object oPC, int nToken);
void FrgApplyForgeLevel(object oItem, int nLevel);
void FrgTickMeter(object oPC, int nToken);

// NUI window identifier
const string FRG_WINDOW         = "FRG_WINDOW";
const string FRG_EV_SCRIPT      = "lib_frg_ev";

// --- Bind names ---
// Per-slot binds: append "0", "1", or "2" to these prefixes
const string FRG_BIND_SLOT_ICON  = "frg_sl_icon";
const string FRG_BIND_SLOT_NAME  = "frg_sl_name";
const string FRG_BIND_SLOT_LVL   = "frg_sl_lvl";
const string FRG_BIND_SLOT_ENC   = "frg_sl_enc";
const string FRG_BIND_SLOT_ENA   = "frg_sl_ena";

// Selected item info area
const string FRG_BIND_ITEM_NAME  = "frg_item_name";
const string FRG_BIND_ITEM_INFO  = "frg_item_info";
const string FRG_BIND_ITEM_COST  = "frg_item_cost";

// Heat meter
const string FRG_BIND_METER_VAL  = "frg_meter_val";
const string FRG_BIND_ZONE_LBL   = "frg_zone_lbl";
const string FRG_BIND_ZONE_COLOR = "frg_zone_col";

// Result and controls
const string FRG_BIND_RESULT_TXT = "frg_result_txt";
const string FRG_BIND_RESULT_COL = "frg_result_col";
const string FRG_BIND_STRIKES    = "frg_strikes";
const string FRG_BIND_STRIKE_ENA = "frg_strike_ena";

// --- Button IDs ---
const string FRG_BTN_CLOSE    = "frg_close";
const string FRG_BTN_SLOT     = "frg_slot";      // append slot index
const string FRG_BTN_STRIKE   = "frg_strike";

// --- LVARs on PC ---
const string FRG_LVAR_SEL_SLOT   = "FRG_SEL_SLOT";
const string FRG_LVAR_METER_POS  = "FRG_METER_POS";
const string FRG_LVAR_METER_DIR  = "FRG_METER_DIR";
const string FRG_LVAR_METER_RUN  = "FRG_METER_RUN";
const string FRG_LVAR_STRIKES    = "FRG_STRIKES";

// --- Window size ---
const float FRG_W    = 540.0;
const float FRG_H    = 480.0;

// --- Game constants ---
const int   FRG_SLOT_COUNT    = 3;
const int   FRG_STRIKES_MAX   = 3;
const int   FRG_MAX_LEVEL     = 5;

// Strike zone boundaries (meter is int 0-100):
//  0-20   : Zbyt Zimna     (Too Cold)      — no effect
// 21-40   : Ciepła         (Warm)          — weak result (50% chance)
// 41-70   : Żar Kuźni      (Prime Heat)    — always succeeds
// 71-85   : Zbyt Gorąca    (Too Hot)       — weak result (50% chance)
// 86-100  : Płomień Zagłady (Ruin)         — degrades item
const int FRG_ZONE_COLD_HI   = 20;
const int FRG_ZONE_WARM_HI   = 40;
const int FRG_ZONE_SWEET_HI  = 70;
const int FRG_ZONE_HOT_HI    = 85;
// 86-100 → ruin

// Meter oscillation: advance this many units per FRG_METER_TICK seconds.
// Speed increases with current forge level, making higher improvements harder.
const float FRG_METER_TICK    = 0.2;   // seconds between ticks
const int   FRG_SPEED_BASE    = 3;     // base speed at forge level 0
// final speed = FRG_SPEED_BASE + current_forge_level * 2

// Gold cost per strike attempt: (forge_level + 1) * FRG_GOLD_BASE
const int   FRG_GOLD_BASE     = 100;
