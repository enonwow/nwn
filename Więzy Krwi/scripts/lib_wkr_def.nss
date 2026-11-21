#include "nw_inc_nui"

// Replicate the subset of lib_nui constants we need so this module is
// self-contained and does not depend on another module's lib_nui.nss.
const string EVENT_TYPE_WATCH    = "watch";
const string EVENT_TYPE_OPEN     = "open";
const string EVENT_TYPE_CLOSE    = "close";
const string EVENT_TYPE_CLICK    = "click";
const string EVENT_TYPE_MOUSEUP  = "mouseup";
const string EVENT_TYPE_MOUSEDOWN= "mousedown";
const string WINDOW_GEOMETRY     = "geometry";

const string WKR_WINDOW         = "WKR_WINDOW";
const string WKR_EV_SCRIPT      = "lib_wkr_ev";

// Bond types
const int WKR_TYPE_DEBT         = 1; // Dług Krwi — gold loan with deadline
const int WKR_TYPE_OATH         = 2; // Przysięga Krwi — loyalty oath, proximity bonus
const int WKR_TYPE_GUARD        = 3; // Straż Krwi — protector / ward roles

// Bond status
const int WKR_STATUS_PENDING    = 0;
const int WKR_STATUS_ACTIVE     = 1;
const int WKR_STATUS_VIOLATED   = 2;
const int WKR_STATUS_FULFILLED  = 3;
const int WKR_STATUS_DISSOLVED  = 4;

// Costs and limits
const int WKR_SEAL_HP_COST      = 5;
const int WKR_MAX_ACTIVE        = 5;
const float WKR_PROXIMITY_DIST  = 10.0; // meters for oath/guard bonuses

// Default debt lifetime: 720 in-game hours (30 days at 24h/day)
const int WKR_DEBT_HOURS        = 720;

// Effect tag prefixes
const string WKR_FX_PROX        = "WKR_PROX_";  // proximity bonus tag
const string WKR_FX_CURSE       = "WKR_CURSE_"; // violation curse tag

// List binds (arrays)
const string WKR_BIND_ROW_NAME  = "wkr_row_name";
const string WKR_BIND_ROW_INFO  = "wkr_row_info";
const string WKR_BIND_ROW_ENC   = "wkr_row_enc";
const string WKR_BIND_ROW_COUNT = "wkr_row_count";

// Detail panel binds
const string WKR_BIND_DTL_VIS   = "wkr_dtl_vis";
const string WKR_BIND_DTL_HDR   = "wkr_dtl_hdr";
const string WKR_BIND_DTL_PAR   = "wkr_dtl_par";
const string WKR_BIND_DTL_TERMS = "wkr_dtl_terms";
const string WKR_BIND_DTL_ST    = "wkr_dtl_st";
const string WKR_BIND_DTL_ST_COL= "wkr_dtl_st_col";
const string WKR_BIND_DTL_EXP   = "wkr_dtl_exp";
const string WKR_BIND_PAY_ENA   = "wkr_pay_ena";
const string WKR_BIND_PAY_LBL   = "wkr_pay_lbl";
const string WKR_BIND_DISS_ENA  = "wkr_diss_ena";

// Invite view binds
const string WKR_BIND_PNAME     = "wkr_pname";
const string WKR_BIND_GOLD_TXT  = "wkr_gold_txt";
const string WKR_BIND_TYPE_DESC = "wkr_type_desc";
const string WKR_BIND_SEAL_ENA  = "wkr_seal_ena";
const string WKR_BIND_PEND_LBL  = "wkr_pend_lbl";
const string WKR_BIND_ACC_ENA   = "wkr_acc_ena";

// Visibility toggles
const string WKR_BIND_VIS_LIST  = "wkr_vis_list";
const string WKR_BIND_VIS_INV   = "wkr_vis_inv";
const string WKR_BIND_SHOW_GOLD = "wkr_show_gold";
const string WKR_BIND_SHOW_ROLE = "wkr_show_role";

// Type selector toggles
const string WKR_BIND_T1_SEL    = "wkr_t1_sel";
const string WKR_BIND_T2_SEL    = "wkr_t2_sel";
const string WKR_BIND_T3_SEL    = "wkr_t3_sel";

// Guard role toggles
const string WKR_BIND_ROLE_G    = "wkr_role_g";
const string WKR_BIND_ROLE_W    = "wkr_role_w";

// Buttons
const string WKR_BTN_CLOSE      = "wkr_btn_close";
const string WKR_BTN_TAB_LIST   = "wkr_btn_tab_list";
const string WKR_BTN_TAB_INV    = "wkr_btn_tab_inv";
const string WKR_BTN_ROW        = "wkr_btn_row";
const string WKR_BTN_PAY        = "wkr_btn_pay";
const string WKR_BTN_DISSOLVE   = "wkr_btn_dissolve";
const string WKR_BTN_PICK       = "wkr_btn_pick";
const string WKR_BTN_SEAL       = "wkr_btn_seal";
const string WKR_BTN_ACCEPT     = "wkr_btn_accept";
const string WKR_BTN_TYPE_DEBT  = "wkr_btn_t1";
const string WKR_BTN_TYPE_OATH  = "wkr_btn_t2";
const string WKR_BTN_TYPE_GUARD = "wkr_btn_t3";
const string WKR_BTN_ROLE_GUARD = "wkr_btn_rg";
const string WKR_BTN_ROLE_WARD  = "wkr_btn_rw";

// Local variables on PC
const string WKR_LVAR_SEL_ID    = "WKR_SEL_ID";
const string WKR_LVAR_INV_TYPE  = "WKR_INV_TYPE";
const string WKR_LVAR_P_UUID    = "WKR_P_UUID";
const string WKR_LVAR_P_NAME    = "WKR_P_NAME";
const string WKR_LVAR_IS_GUARD  = "WKR_IS_GUARD";
const string WKR_LVAR_VIEW      = "WKR_VIEW"; // 0=list, 1=invite
const string WKR_LVAR_PEND_ID   = "WKR_PEND_ID";
const string WKR_LVAR_PEND_FROM = "WKR_PEND_FROM";
const string WKR_LVAR_BONDS_JSON= "WKR_BONDS_JSON";
const string WKR_LVAR_HB_TICK   = "WKR_HB_TICK";
