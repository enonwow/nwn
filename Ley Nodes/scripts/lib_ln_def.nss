#include "lib_nui"
#include "sql_ln"

// ------------------------------------------------------------------
// Node types — set as local int "LN_TYPE" on each node placeable.
// ------------------------------------------------------------------
const int LN_TYPE_ARCANE  = 1;
const int LN_TYPE_MARTIAL = 2;
const int LN_TYPE_VITAL   = 3;
const int LN_TYPE_SHADOW  = 4;

// ------------------------------------------------------------------
// Tuneable constants
// ------------------------------------------------------------------
const int   LN_CHARGE_MAX      = 100;
const int   LN_CHARGE_REGEN    = 1;    // points per real minute
const int   LN_DRAW_COST       = 25;   // charge consumed per siphon
const int   LN_ATTUNE_COST     = 100;  // gold for attunement ritual
const float LN_ATTUNE_RANGE    = 5.0;  // metres
const int   LN_BOOST_DURATION  = 600;  // seconds (10 minutes)
const int   LN_MAX_ATTUNEMENTS = 5;

// ------------------------------------------------------------------
// NUI identifiers — window names
// ------------------------------------------------------------------
const string LN_WINDOW    = "LN_WINDOW";
const string LN_EV_SCRIPT = "lib_ln_ev";
const string LN_WIN_GEOM  = "ln_win_geom";

// List-column bind names (per-row arrays fed into NuiList)
const string LN_BIND_ROW_NAME   = "ln_row_name";
const string LN_BIND_ROW_TYPE   = "ln_row_type";
const string LN_BIND_ROW_CHARGE = "ln_row_charge";
const string LN_BIND_ROW_ENC    = "ln_row_enc";
const string LN_BIND_ROW_COLOR  = "ln_row_color";
const string LN_BIND_ROW_COUNT  = "ln_rowcount";

// Detail-panel binds
const string LN_BIND_DET_NAME    = "ln_det_name";
const string LN_BIND_DET_TYPE    = "ln_det_type";
const string LN_BIND_DET_CHARGE  = "ln_det_charge";
const string LN_BIND_DET_PBAR    = "ln_det_pbar";
const string LN_BIND_DET_STATUS  = "ln_det_status";
const string LN_BIND_SIPHON_ENA  = "ln_siphon_ena";
const string LN_BIND_RELEASE_ENA = "ln_release_ena";
const string LN_BIND_ATTUNE_ENA  = "ln_attune_ena";
const string LN_BIND_ATTUNE_VIS  = "ln_attune_vis";

// Button IDs
const string LN_BTN_ROW     = "ln_btn_row";
const string LN_BTN_SIPHON  = "ln_btn_siphon";
const string LN_BTN_RELEASE = "ln_btn_release";
const string LN_BTN_ATTUNE  = "ln_btn_attune";
const string LN_BTN_CLOSE   = "ln_btn_close";

// Local variables stored on the PC object
const string LN_LVAR_SEL_TAG   = "LN_SEL_TAG";    // tag of node shown in detail panel
const string LN_LVAR_BOOST_TYPE= "LN_BOOST_TYPE"; // active boost type (0 = none)

// ------------------------------------------------------------------
// Layout dimensions (pre-scale)
// ------------------------------------------------------------------
const float LN_W      = 620.0;
const float LN_H      = 400.0;
const float LN_LIST_W = 210.0;

// ------------------------------------------------------------------
// Forward declarations
// ------------------------------------------------------------------
void LnOpenPanel(object oPC);
void LnFeedList(object oPC, int nToken);
void LnFeedDetail(object oPC, int nToken, string sTag);
void LnSiphonPower(object oPC, int nToken);
void LnAttuneSelected(object oPC, int nToken);
void LnReleaseAttunement(object oPC, int nToken);
void LnApplyBoost(object oPC, int nType);
void LnEnsureNodeRegistered(object oNode);
int  LnCheckProximity(object oPC, string sTag);
string LnGetTypeName(int nType);
string LnGetTypeGlyph(int nType);
string LnGetBoostDesc(int nType);
