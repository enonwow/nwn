#include "lib_nui"
#include "sql_phy"

void PhyCreateWindow(object oPC);
void PhyFeedStatus(object oPC, int nToken);
void PhyFeedHistory(object oPC, int nToken);
void PhySwapToStatus(object oPC, int nToken);
void PhySwapToHistory(object oPC, int nToken);
void PhyHandleDeath(object oPC);
void PhyRespawnAndTeleport(object oPC);

// ----------------------------------------------------------------
// Window / group IDs
// ----------------------------------------------------------------

const string PHY_WINDOW          = "PHY_WINDOW";
const string PHY_EV_SCRIPT       = "lib_phy_ev";
const string PHY_GRP_SWAP        = "PHY_GRP_SWAP";
const string PHY_WIN_GEOM        = "phy_win_geom";

// Shatter confirmation popup
const string PHY_WIN_CONFIRM     = "PHY_WIN_CONFIRM";
const string PHY_BTN_CONF_YES    = "phy_conf_yes";
const string PHY_BTN_CONF_NO     = "phy_conf_no";

// ----------------------------------------------------------------
// Binds — status view
// ----------------------------------------------------------------

const string PHY_BIND_STATUS_LBL     = "phy_status_lbl";
const string PHY_BIND_STATUS_COLOR   = "phy_status_color";
const string PHY_BIND_CHARGES_LBL    = "phy_charges_lbl";
const string PHY_BIND_CHARGES_COLOR  = "phy_charges_color";
const string PHY_BIND_ANCHOR_LBL     = "phy_anchor_lbl";
const string PHY_BIND_ANCHOR_DATE    = "phy_anchor_date";
const string PHY_BIND_FLAVOR_TXT     = "phy_flavor_txt";
const string PHY_BIND_GOLD_LBL       = "phy_gold_lbl";

// Button enables
const string PHY_BIND_CREATE_ENA     = "phy_create_ena";
const string PHY_BIND_ANCHOR_ENA     = "phy_anchor_ena";
const string PHY_BIND_EMPOWER_ENA    = "phy_empower_ena";
const string PHY_BIND_SHATTER_ENA    = "phy_shatter_ena";
const string PHY_BIND_CREATE_LBL     = "phy_create_lbl";

// ----------------------------------------------------------------
// Binds — history view
// ----------------------------------------------------------------

const string PHY_BIND_HIST_DATE      = "phy_hist_date";
const string PHY_BIND_HIST_KILLER    = "phy_hist_killer";
const string PHY_BIND_HIST_AREA      = "phy_hist_area";
const string PHY_BIND_HIST_COLOR     = "phy_hist_color";
const string PHY_BIND_HIST_COUNT     = "phy_hist_count";

// ----------------------------------------------------------------
// Buttons
// ----------------------------------------------------------------

const string PHY_BTN_CLOSE           = "phy_btn_close";
const string PHY_BTN_CREATE          = "phy_btn_create";
const string PHY_BTN_ANCHOR          = "phy_btn_anchor";
const string PHY_BTN_EMPOWER         = "phy_btn_empower";
const string PHY_BTN_SHATTER         = "phy_btn_shatter";
const string PHY_BTN_TAB_STATUS      = "phy_tab_status";
const string PHY_BTN_TAB_HISTORY     = "phy_tab_history";

// ----------------------------------------------------------------
// LVAR keys stored on the PC
// ----------------------------------------------------------------

const string PHY_LVAR_VIEW           = "PHY_VIEW";   // "status" | "history"

// ----------------------------------------------------------------
// Layout constants
// ----------------------------------------------------------------

const float  PHY_W                   = 500.0;
const float  PHY_H                   = 520.0;
