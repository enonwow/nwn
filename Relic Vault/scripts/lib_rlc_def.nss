#include "lib_nui"
#include "sql_rlc"

// ----------------------------------------------------------------
// Window & event script
// ----------------------------------------------------------------
const string RLC_WINDOW    = "RLC_WINDOW";
const string RLC_EV_SCRIPT = "lib_rlc_ev";
const string RLC_WIN_GEOM  = "rlc_win_geom";

// ----------------------------------------------------------------
// List-panel binds  (arrays, one entry per relic)
// ----------------------------------------------------------------
const string RLC_BIND_ROW_NAME   = "rlc_row_name";
const string RLC_BIND_ROW_STATUS = "rlc_row_status";
const string RLC_BIND_ROW_COLOR  = "rlc_row_color";
const string RLC_BIND_ROW_ENC    = "rlc_row_enc";

// ----------------------------------------------------------------
// Detail-panel binds
// ----------------------------------------------------------------
const string RLC_BIND_DET_NAME   = "rlc_det_name";
const string RLC_BIND_DET_LORE   = "rlc_det_lore";
const string RLC_BIND_DET_POWER  = "rlc_det_power";
const string RLC_BIND_DET_CURSE  = "rlc_det_curse";
const string RLC_BIND_CURSE_LBL  = "rlc_curse_lbl";
const string RLC_BIND_CURSE_PROG = "rlc_curse_prog";
const string RLC_BIND_HOLDER_LBL = "rlc_holder_lbl";
const string RLC_BIND_ATTUNE_ENA = "rlc_att_ena";
const string RLC_BIND_RELEAS_ENA = "rlc_rel_ena";
const string RLC_BIND_PURIFY_ENA = "rlc_pur_ena";

// ----------------------------------------------------------------
// Button IDs
// ----------------------------------------------------------------
const string RLC_BTN_CLOSE   = "rlc_close";
const string RLC_BTN_ROW     = "rlc_row";
const string RLC_BTN_ATTUNE  = "rlc_attune";
const string RLC_BTN_RELEASE = "rlc_release";
const string RLC_BTN_PURIFY  = "rlc_purify";

// ----------------------------------------------------------------
// Per-PC LVARs
// ----------------------------------------------------------------
const string RLC_LVAR_SEL = "RLC_SEL_ID"; // currently selected relic (1..6)

// ----------------------------------------------------------------
// Relic IDs
// ----------------------------------------------------------------
const int RLC_RELIC_EYE     = 1; // Oko Tyranów
const int RLC_RELIC_BLADE   = 2; // Miecz Zdrajcy
const int RLC_RELIC_CHALICE = 3; // Kielich Zatracenia
const int RLC_RELIC_CROWN   = 4; // Korona Popiołów
const int RLC_RELIC_SEAL    = 5; // Pieczęć Nicości
const int RLC_RELIC_CLAW    = 6; // Szpon Bestii
const int RLC_RELIC_COUNT   = 6;

// ----------------------------------------------------------------
// Economy
// ----------------------------------------------------------------
const int RLC_GOLD_ATTUNE  = 500;  // cost to attune
const int RLC_GOLD_RELEASE = 200;  // cost to voluntarily release
const int RLC_GOLD_PURIFY  = 1000; // cost per purification attempt
const int RLC_PURIFY_CHANCE = 60;  // % chance purification reduces curse by 1

// ----------------------------------------------------------------
// Layout
// ----------------------------------------------------------------
const float RLC_W = 780.0;
const float RLC_H = 530.0;

// ----------------------------------------------------------------
// Effect tags for clean removal
// ----------------------------------------------------------------
const string RLC_TAG_POWER = "RLC_POWER";
const string RLC_TAG_CURSE = "RLC_CURSE";
