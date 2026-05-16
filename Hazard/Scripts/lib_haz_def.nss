// lib_haz_def.nss — constants, bind IDs, button IDs for Hazard module
#include "lib_nui"
#include "sql_haz"

void HazOpenWindow(object oPC);

// Window IDs
const string HAZ_WINDOW    = "HAZ_WINDOW";
const string HAZ_WIN_STATS = "HAZ_WIN_STATS";
const string HAZ_EV_SCRIPT = "lib_haz_ev";
const string HAZ_WIN_GEOM  = "haz_win_geom";

// Game phases stored in HAZ_LVAR_PHASE
const int HAZ_PHASE_BET    = 0;  // waiting for bet + first roll
const int HAZ_PHASE_ROLLED = 1;  // first roll done; can hold/reroll/stand
const int HAZ_PHASE_RESULT = 2;  // round over; new round button active

// Bind IDs — player dice face text + hold indicator
const string HAZ_BIND_D1_FACE = "haz_d1_face";
const string HAZ_BIND_D2_FACE = "haz_d2_face";
const string HAZ_BIND_D3_FACE = "haz_d3_face";
const string HAZ_BIND_D1_ENC  = "haz_d1_enc";
const string HAZ_BIND_D2_ENC  = "haz_d2_enc";
const string HAZ_BIND_D3_ENC  = "haz_d3_enc";

// Bind IDs — dealer dice
const string HAZ_BIND_DD1_FACE  = "haz_dd1";
const string HAZ_BIND_DD2_FACE  = "haz_dd2";
const string HAZ_BIND_DD3_FACE  = "haz_dd3";

// Bind IDs — hand labels + result
const string HAZ_BIND_HAND_LBL  = "haz_hand_lbl";
const string HAZ_BIND_HAND_COL  = "haz_hand_col";
const string HAZ_BIND_DHAND_LBL = "haz_dhand_lbl";
const string HAZ_BIND_DHAND_COL = "haz_dhand_col";
const string HAZ_BIND_RESULT    = "haz_result";
const string HAZ_BIND_RESULT_COL= "haz_res_col";

// Bind IDs — bet controls
const string HAZ_BIND_BET      = "haz_bet";
const string HAZ_BIND_BET_ENA  = "haz_bet_ena";
const string HAZ_BIND_BLOOD    = "haz_blood_chk";  // NuiCheckbox bind (bool)

// Bind IDs — button enabled states
const string HAZ_BIND_ROLL_ENA   = "haz_roll_ena";
const string HAZ_BIND_REROLL_ENA = "haz_reroll_ena";
const string HAZ_BIND_STAND_ENA  = "haz_stand_ena";
const string HAZ_BIND_NEW_ENA    = "haz_new_ena";

// Bind IDs — info labels
const string HAZ_BIND_GOLD_LBL  = "haz_gold_lbl";
const string HAZ_BIND_HINT_LBL  = "haz_hint_lbl";
const string HAZ_BIND_HINT_COL  = "haz_hint_col";

// Button IDs
const string HAZ_BTN_CLOSE  = "haz_btn_close";
const string HAZ_BTN_ROLL   = "haz_btn_roll";
const string HAZ_BTN_REROLL = "haz_btn_reroll";
const string HAZ_BTN_STAND  = "haz_btn_stand";
const string HAZ_BTN_NEW    = "haz_btn_new";
const string HAZ_BTN_STATS  = "haz_btn_stats";
const string HAZ_BTN_D1     = "haz_btn_d1";
const string HAZ_BTN_D2     = "haz_btn_d2";
const string HAZ_BTN_D3     = "haz_btn_d3";

// LVARs on PC (cleared on window close)
const string HAZ_LVAR_PHASE    = "HAZ_PHASE";
const string HAZ_LVAR_BET      = "HAZ_BET";
const string HAZ_LVAR_D1       = "HAZ_D1";
const string HAZ_LVAR_D2       = "HAZ_D2";
const string HAZ_LVAR_D3       = "HAZ_D3";
const string HAZ_LVAR_H1       = "HAZ_H1";
const string HAZ_LVAR_H2       = "HAZ_H2";
const string HAZ_LVAR_H3       = "HAZ_H3";
const string HAZ_LVAR_REROLLED = "HAZ_REROLLED";
const string HAZ_LVAR_BLOOD    = "HAZ_BLOOD";
// Dealer's rolled dice stored here after HazDealerPlayFull
const string HAZ_LVAR_DD1      = "HAZ_DD1";
const string HAZ_LVAR_DD2      = "HAZ_DD2";
const string HAZ_LVAR_DD3      = "HAZ_DD3";

// Game limits
const int   HAZ_BET_MIN = 10;
const int   HAZ_BET_MAX = 5000;

// Window dimensions
const float HAZ_W = 540.0;
const float HAZ_H = 510.0;
