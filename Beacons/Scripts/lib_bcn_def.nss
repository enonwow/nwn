#include "lib_nui"
#include "sql_bcn"

void BcnOpenWindow(object oPC, object oBeacon);

// ----------------------------------------------------------------
// Window / event
// ----------------------------------------------------------------

const string BCN_WINDOW    = "BCN_WINDOW";
const string BCN_EV_SCRIPT = "lib_bcn_ev";
const string BCN_WIN_GEOM  = "bcn_win_geom";

// ----------------------------------------------------------------
// Beacon types (stored in BCN_VAR_TYPE on the placeable)
// ----------------------------------------------------------------

const string BCN_TYPE_FIRE   = "fire";
const string BCN_TYPE_SHADOW = "shadow";
const string BCN_TYPE_SPIRIT = "spirit";
const string BCN_TYPE_BLOOD  = "blood";
const string BCN_TYPE_STONE  = "stone";

// ----------------------------------------------------------------
// Placeable local variables set by the builder in the toolset
// ----------------------------------------------------------------

const string BCN_VAR_TYPE = "BCN_TYPE";   // one of the BCN_TYPE_* strings
const string BCN_VAR_NAME = "BCN_NAME";   // display name shown in UI

// ----------------------------------------------------------------
// NUI bind names
// ----------------------------------------------------------------

// Status panel
const string BCN_BIND_BEACON_NAME  = "bcn_name";
const string BCN_BIND_TYPE_LBL     = "bcn_type";
const string BCN_BIND_STATUS_LBL   = "bcn_status";
const string BCN_BIND_STATUS_COL   = "bcn_status_col";
const string BCN_BIND_KINDLER_LBL  = "bcn_kindler";
const string BCN_BIND_BUFF_DESC    = "bcn_buff_desc";
const string BCN_BIND_FUEL_DESC    = "bcn_fuel_desc";
const string BCN_BIND_COOLDOWN_LBL = "bcn_cooldown";

// Action button states
const string BCN_BIND_KINDLE_ENA   = "bcn_kindle_ena";
const string BCN_BIND_REST_ENA     = "bcn_rest_ena";
const string BCN_BIND_PURIFY_ENA   = "bcn_purify_ena";

// Known list (array binds, one entry per row)
const string BCN_BIND_KNOWN_CNT    = "bcn_known_cnt";
const string BCN_BIND_KNOWN_TYPE   = "bcn_known_type";
const string BCN_BIND_KNOWN_AREA   = "bcn_known_area";
const string BCN_BIND_KNOWN_ST     = "bcn_known_st";
const string BCN_BIND_KNOWN_COL    = "bcn_known_col";
const string BCN_BIND_KNOWN_ENC    = "bcn_known_enc";

// ----------------------------------------------------------------
// Button IDs
// ----------------------------------------------------------------

const string BCN_BTN_CLOSE     = "bcn_btn_close";
const string BCN_BTN_KINDLE    = "bcn_btn_kindle";
const string BCN_BTN_REST      = "bcn_btn_rest";
const string BCN_BTN_PURIFY    = "bcn_btn_purify";
const string BCN_BTN_KNOWN_ROW = "bcn_btn_known";

// ----------------------------------------------------------------
// Local variable names stored on the PC object
// ----------------------------------------------------------------

const string BCN_LVAR_BEACON_OBJ = "BCN_BEACON_OBJ";

// ----------------------------------------------------------------
// Item tags for kindling materials (resrefs set by the builder)
// ----------------------------------------------------------------

const string BCN_ITEM_TINDER     = "bcn_tinder";       // fire beacon fuel
const string BCN_ITEM_SHADOW_ASH = "bcn_shadow_ash";   // shadow beacon fuel
const string BCN_ITEM_INCENSE    = "bcn_incense";       // spirit beacon fuel
const string BCN_ITEM_BLOOD_VIAL = "bcn_blood_vial";   // blood beacon fuel
const string BCN_ITEM_QUARTZ     = "bcn_quartz";        // stone beacon fuel
const string BCN_ITEM_HOLY_WATER = "bcn_holy_water";   // purification reagent

// HP drained when kindling a blood beacon
const int BCN_BLOOD_HP_COST = 15;

// ----------------------------------------------------------------
// Timing
// ----------------------------------------------------------------

// Minimum real seconds between rests at the same beacon
const int BCN_REST_COOLDOWN_SEC = 3600;

// Buff duration applied on rest (real seconds, ~2 hours)
const int BCN_BUFF_DURATION_SEC = 7200;

// ----------------------------------------------------------------
// Layout
// ----------------------------------------------------------------

const float BCN_W = 500.0;
const float BCN_H = 490.0;
