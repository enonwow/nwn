#include "lib_nui"
#include "sql_herb"

// ----------------------------------------------------------------
// Herb types (1-indexed; 0 = none/invalid)
// ----------------------------------------------------------------

const int HERB_BLOODMOSS     = 1;
const int HERB_NIGHTSHADE    = 2;
const int HERB_SUNROOT       = 3;
const int HERB_GHOSTWEED     = 4;
const int HERB_IRONBARK      = 5;
const int HERB_GRAVEMINT     = 6;
const int HERB_VOIDFERN      = 7;
const int HERB_WITCH_CLOVER  = 8;
const int HERB_TYPE_COUNT    = 8;

// Seasons (aligned with NWN months 1-12):
//   Spring: 3-5 | Summer: 6-8 | Autumn: 9-11 | Winter: 12,1,2
const int SEASON_SPRING  = 0;
const int SEASON_SUMMER  = 1;
const int SEASON_AUTUMN  = 2;
const int SEASON_WINTER  = 3;

// Effect duration in seconds (10 real minutes)
const float HERB_EFFECT_DUR  = 600.0;

// Node config
const int HERB_NODE_CHARGES  = 3;
const int HERB_REGEN_SECS    = 86400;  // one real day per charge regen

// ----------------------------------------------------------------
// NUI — window IDs
// ----------------------------------------------------------------

const string HERB_WIN_HARVEST  = "HERB_WIN_HARVEST";
const string HERB_WIN_JOURNAL  = "HERB_WIN_JOURNAL";
const string HERB_EV           = "lib_herb_ev";

// ----------------------------------------------------------------
// NUI — harvest window binds
// ----------------------------------------------------------------

const string HERB_BIND_H_GEOM  = "herb_h_geom";
const string HERB_BIND_H_NAME  = "herb_h_name";
const string HERB_BIND_H_DESC  = "herb_h_desc";
const string HERB_BIND_H_CHRG  = "herb_h_chrg";
const string HERB_BIND_H_BONUS = "herb_h_bonus";
const string HERB_BIND_H_ENA   = "herb_h_ena";

// ----------------------------------------------------------------
// NUI — journal window binds
// ----------------------------------------------------------------

const string HERB_BIND_J_GEOM  = "herb_j_geom";
const string HERB_BIND_J_RNAME = "herb_j_rname";
const string HERB_BIND_J_RCNT  = "herb_j_rcnt";
const string HERB_BIND_J_RSEAS = "herb_j_rseas";
const string HERB_BIND_J_RENC  = "herb_j_renc";
const string HERB_BIND_J_RCOL  = "herb_j_rcol";
const string HERB_BIND_J_ROWS  = "herb_j_rows";
const string HERB_BIND_LORE_N  = "herb_lore_n";
const string HERB_BIND_LORE_T  = "herb_lore_t";
const string HERB_BIND_LORE_P  = "herb_lore_p";
const string HERB_BIND_USE_ENA = "herb_use_ena";
const string HERB_BIND_USE_LBL = "herb_use_lbl";

// ----------------------------------------------------------------
// NUI — button IDs
// ----------------------------------------------------------------

const string HERB_BTN_HARVEST  = "herb_btn_harv";
const string HERB_BTN_JOURNAL  = "herb_btn_jour";
const string HERB_BTN_CLOSE_H  = "herb_btn_clh";
const string HERB_BTN_ROW      = "herb_btn_row";
const string HERB_BTN_USE      = "herb_btn_use";
const string HERB_BTN_CLOSE_J  = "herb_btn_clj";

// ----------------------------------------------------------------
// Local vars on PC
// ----------------------------------------------------------------

const string HERB_LVAR_NODE    = "HERB_NODE_TAG";
const string HERB_LVAR_NTYPE   = "HERB_NODE_TYPE";
const string HERB_LVAR_SEL     = "HERB_SEL_TYPE";

// ----------------------------------------------------------------
// Window dimensions (pre-scale)
// ----------------------------------------------------------------

const float HERB_HW = 400.0;
const float HERB_HH = 240.0;
const float HERB_JW = 580.0;
const float HERB_JH = 480.0;
