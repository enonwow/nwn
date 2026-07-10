#include "lib_nui"
#include "sql_vend"

// Forward declarations for cross-file use
void VendAddGrudge(object oVictim, object oWrongdoer, int nWrongType, string sItemTag);
void VendCheckFulfillment(object oAvenger, object oWrongdoer);
void ApplyVendEffects(object oPC);
void FeedVendWindow(object oPC, int nToken);

// ----------------------------------------------------------------
// Window / group identifiers
// ----------------------------------------------------------------

const string VEND_WINDOW            = "VEND_WINDOW";
const string VEND_EV_SCRIPT         = "lib_vend_ev";
const string VEND_WIN_GEOM          = "vend_win_geom";
const string VEND_WIN_CONFIRM       = "VEND_WIN_CONFIRM";

// ----------------------------------------------------------------
// Layout dimensions (pre-scale values)
// ----------------------------------------------------------------

const float  VEND_W                 = 580.0;
const float  VEND_H                 = 460.0;

// ----------------------------------------------------------------
// Wrong types
// ----------------------------------------------------------------

const int    VEND_WRONG_KILLED      = 1;
const int    VEND_WRONG_STOLEN      = 2;
const int    VEND_WRONG_CURSED      = 3;

// ----------------------------------------------------------------
// Mechanical limits and effect tags
// ----------------------------------------------------------------

const int    VEND_MAX_FURY          = 3;
const int    VEND_MAX_RESENT        = 3;

const string VEND_TAG_FURY          = "VEND_FURY";
const string VEND_TAG_RESENT        = "VEND_RESENT";
const string VEND_TAG_FULFILL       = "VEND_FULFILL";

// ----------------------------------------------------------------
// PC local variables
// ----------------------------------------------------------------

const string VEND_LVAR_SEL_ID       = "VEND_SEL_ID";
const string VEND_LVAR_PENDING_ID   = "VEND_PENDING_ID";

// ----------------------------------------------------------------
// NUI bind names — active grudge list
// ----------------------------------------------------------------

const string VEND_BIND_ACT_NAME     = "vend_act_name";
const string VEND_BIND_ACT_TYPE     = "vend_act_type";
const string VEND_BIND_ACT_DATE     = "vend_act_date";
const string VEND_BIND_ACT_OD       = "vend_act_od";
const string VEND_BIND_ACT_ODCOLOR  = "vend_act_odcolor";
const string VEND_BIND_ACT_ENC      = "vend_act_enc";
const string VEND_BIND_ACT_COUNT    = "vend_act_count";

// ----------------------------------------------------------------
// NUI bind names — history list
// ----------------------------------------------------------------

const string VEND_BIND_HIS_NAME     = "vend_his_name";
const string VEND_BIND_HIS_TYPE     = "vend_his_type";
const string VEND_BIND_HIS_DATE     = "vend_his_date";
const string VEND_BIND_HIS_STATUS   = "vend_his_status";
const string VEND_BIND_HIS_COLOR    = "vend_his_color";
const string VEND_BIND_HIS_COUNT    = "vend_his_count";

// ----------------------------------------------------------------
// NUI bind names — status bar
// ----------------------------------------------------------------

const string VEND_BIND_FURY_LBL     = "vend_fury_lbl";
const string VEND_BIND_FURY_COLOR   = "vend_fury_color";
const string VEND_BIND_RESENT_LBL   = "vend_resent_lbl";
const string VEND_BIND_RESENT_COLOR = "vend_resent_color";
const string VEND_BIND_FORSW_ENA    = "vend_forsw_ena";

// ----------------------------------------------------------------
// NUI button identifiers
// ----------------------------------------------------------------

const string VEND_BTN_CLOSE         = "vend_btn_close";
const string VEND_BTN_ROW_ACT       = "vend_btn_row_act";
const string VEND_BTN_FORSWEAR      = "vend_btn_forswear";
const string VEND_BTN_FORSW_OK      = "vend_btn_forsw_ok";
const string VEND_BTN_FORSW_CANCEL  = "vend_btn_forsw_cancel";

// ----------------------------------------------------------------
// Helpers
// ----------------------------------------------------------------

string VendWrongTypeName(int nType)
{
    if (nType == VEND_WRONG_KILLED) return "Morderstwo";
    if (nType == VEND_WRONG_STOLEN) return "Kradzież";
    if (nType == VEND_WRONG_CURSED) return "Klątwa";
    return "Zniewaga";
}
