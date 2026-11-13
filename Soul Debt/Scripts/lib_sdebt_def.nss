#include "lib_nui"
#include "sql_sdebt"

void SDebtOpenWindow(object oPC);
void SDebtFeedAll(object oPC, int nToken);
void SDebtCheckOnLogin(object oPC);

// ----------------------------------------------------------------
// Window / UI IDs
// ----------------------------------------------------------------

const string SDEBT_WINDOW        = "SDEBT_WINDOW";
const string SDEBT_EV_SCRIPT     = "lib_sdebt_ev";
const string SDEBT_WIN_GEOM      = "sdebt_win_geom";
const string SDEBT_GRP_SWAP      = "SDEBT_GRP_SWAP";

// Tab buttons
const string SDEBT_BTN_TAB_CRED  = "sdebt_tab_cred";
const string SDEBT_BTN_TAB_DEBT  = "sdebt_tab_debt";
const string SDEBT_BTN_CLOSE     = "sdebt_btn_close";

// Row IDs (inside NuiList)
const string SDEBT_BTN_ROW_CRED  = "sdebt_row_cred";
const string SDEBT_BTN_ROW_DEBT  = "sdebt_row_debt";

// Action buttons – creditor view
const string SDEBT_BTN_INVOKE    = "sdebt_btn_invoke";
const string SDEBT_BTN_FORGIVE   = "sdebt_btn_forgive";
const string SDEBT_BTN_PROPOSE   = "sdebt_btn_propose";

// Action buttons – debtor view
const string SDEBT_BTN_ACCEPT    = "sdebt_btn_accept";
const string SDEBT_BTN_REPAY     = "sdebt_btn_repay";
const string SDEBT_BTN_RENOUNCE  = "sdebt_btn_renounce";

// Propose popup
const string SDEBT_WIN_PROPOSE      = "SDEBT_WIN_PROPOSE";
const string SDEBT_BTN_PROP_ROW     = "sdebt_prop_row";
const string SDEBT_BTN_PROP_CONFIRM = "sdebt_prop_ok";
const string SDEBT_BTN_PROP_CANCEL  = "sdebt_prop_cancel";
const string SDEBT_BIND_PROP_NAMES  = "sdebt_prop_names";
const string SDEBT_BIND_PROP_ENC    = "sdebt_prop_enc";
const string SDEBT_BIND_PROP_DESC   = "sdebt_prop_desc";

// Notification popup (proposal / invocation)
const string SDEBT_WIN_NOTIFY    = "SDEBT_WIN_NOTIFY";
const string SDEBT_BTN_NOTIF_ACC = "sdebt_notif_acc";
const string SDEBT_BTN_NOTIF_REJ = "sdebt_notif_rej";
const string SDEBT_BTN_NOTIF_OK  = "sdebt_notif_ok";

// Row binds – creditor view
const string SDEBT_BIND_C_DEBTOR = "sdebt_c_debtor";
const string SDEBT_BIND_C_STATUS = "sdebt_c_status";
const string SDEBT_BIND_C_DATE   = "sdebt_c_date";
const string SDEBT_BIND_C_DESC   = "sdebt_c_desc";
const string SDEBT_BIND_C_ENC    = "sdebt_c_enc";

// Row binds – debtor view
const string SDEBT_BIND_D_CRED   = "sdebt_d_cred";
const string SDEBT_BIND_D_STATUS = "sdebt_d_status";
const string SDEBT_BIND_D_DATE   = "sdebt_d_date";
const string SDEBT_BIND_D_DESC   = "sdebt_d_desc";
const string SDEBT_BIND_D_ENC    = "sdebt_d_enc";

// Detail text + header
const string SDEBT_BIND_DETAIL   = "sdebt_detail";
const string SDEBT_BIND_HEADER   = "sdebt_header_lbl";

// Single-value enabled binds for action buttons
const string SDEBT_BIND_INVOKE_ENA   = "sdebt_invoke_ena";
const string SDEBT_BIND_FORGIVE_ENA  = "sdebt_forgive_ena";
const string SDEBT_BIND_ACCEPT_ENA   = "sdebt_accept_ena";
const string SDEBT_BIND_REPAY_ENA    = "sdebt_repay_ena";
const string SDEBT_BIND_RENOUNCE_ENA = "sdebt_renounce_ena";

// LVARs on PC
const string SDEBT_LVAR_TAB         = "SDEBT_TAB";         // 0=cred 1=debt
const string SDEBT_LVAR_SEL_ID      = "SDEBT_SEL_ID";
const string SDEBT_LVAR_PROP_UUID   = "SDEBT_PROP_UUID";
const string SDEBT_LVAR_PROP_NAME   = "SDEBT_PROP_NAME";
const string SDEBT_LVAR_PROP_LIST   = "SDEBT_PROP_LIST";
const string SDEBT_LVAR_NOTIF_ID    = "SDEBT_NOTIF_ID";

// Gameplay constants
const int   SDEBT_REPAY_GOLD        = 500;
const int   SDEBT_INVOKE_DMG        = 3;    // HP per tick per active invocation
const int   SDEBT_RENOUNCE_DMG      = 15;   // HP lost on renounce
const int   SDEBT_CURSE_DURATION    = 86400; // 24h in seconds
const float SDEBT_INVOKE_TICK       = 300.0; // 5 minutes

// Window size
const float SDEBT_W                 = 680.0;
const float SDEBT_H                 = 480.0;
