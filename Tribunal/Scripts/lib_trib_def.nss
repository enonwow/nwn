#include "lib_nui"
#include "sql_trib"

// Forward declarations
void TribOpenWindow(object oPC);
void SwapToCaseListView(object oPC, int nToken);
void SwapToCaseDetailView(object oPC, int nToken, int nCaseId);
void SwapToAccuseView(object oPC, int nToken);
void FeedCaseList(object oPC, int nToken);
void FeedCaseDetail(object oPC, int nToken, int nCaseId);
void FeedAccuseView(object oPC, int nToken);
void TribApplyVerdict(object oPC, int nCaseId, int nVerdict, string sSentence);
void TribShowSearchPopup(object oPC, json jResults);

// ----------------------------------------------------------------
// Window / group identifiers
// ----------------------------------------------------------------

const string TRIB_WINDOW        = "TRIB_WINDOW";
const string TRIB_EV_SCRIPT     = "lib_trib_ev";
const string TRIB_GRP_SWAP      = "TRIB_GRP_SWAP";
const string TRIB_WIN_GEOM      = "trib_win_geom";
const string TRIB_WIN_SEARCH    = "TRIB_WIN_SEARCH";

// ----------------------------------------------------------------
// Case-list bind names
// ----------------------------------------------------------------

const string TRIB_BIND_LIST_NAME    = "trib_lst_name";
const string TRIB_BIND_LIST_CHARGE  = "trib_lst_charge";
const string TRIB_BIND_LIST_STATUS  = "trib_lst_status";
const string TRIB_BIND_LIST_COLOR   = "trib_lst_color";
const string TRIB_BIND_LIST_ENC     = "trib_lst_enc";
const string TRIB_BIND_LIST_COUNT   = "trib_lst_cnt";

// ----------------------------------------------------------------
// Case-detail bind names
// ----------------------------------------------------------------

const string TRIB_BIND_DETAIL_HDR   = "trib_det_hdr";
const string TRIB_BIND_DETAIL_CHARGE= "trib_det_charge";
const string TRIB_BIND_DETAIL_ACC   = "trib_det_acc";
const string TRIB_BIND_EVIDENCE_TXT = "trib_evid_txt";
const string TRIB_BIND_DEFENSE_TXT  = "trib_def_txt";
const string TRIB_BIND_DEF_ENA      = "trib_def_ena";
const string TRIB_BIND_SENTENCE_TXT = "trib_sent_txt";
const string TRIB_BIND_VERDICT_ENA  = "trib_verd_ena";
const string TRIB_BIND_STATUS_LBL   = "trib_stat_lbl";

// ----------------------------------------------------------------
// Accuse-view bind names
// ----------------------------------------------------------------

const string TRIB_BIND_SEARCH_TXT   = "trib_srch_txt";
const string TRIB_BIND_TARGET_LBL   = "trib_tgt_lbl";
const string TRIB_BIND_CHARGE_TXT   = "trib_chg_txt";
const string TRIB_BIND_EVID2_TXT    = "trib_evid2_txt";
const string TRIB_BIND_SUBMIT_ENA   = "trib_sub_ena";

// ----------------------------------------------------------------
// Search-popup bind names
// ----------------------------------------------------------------

const string TRIB_BIND_SRCH_NAME    = "trib_sn";
const string TRIB_BIND_SRCH_ENC     = "trib_se";
const string TRIB_BIND_SRCH_COUNT   = "trib_sc";

// ----------------------------------------------------------------
// Button identifiers
// ----------------------------------------------------------------

const string TRIB_BTN_CLOSE         = "trib_btn_close";
const string TRIB_BTN_ACCUSE        = "trib_btn_accuse";
const string TRIB_BTN_BACK          = "trib_btn_back";
const string TRIB_BTN_SUBMIT_DEF    = "trib_btn_subdef";
const string TRIB_BTN_SUBMIT_EVID   = "trib_btn_subevid";
const string TRIB_BTN_GUILTY_JAIL   = "trib_btn_jail";
const string TRIB_BTN_GUILTY_EXILE  = "trib_btn_exile";
const string TRIB_BTN_GUILTY_DEATH  = "trib_btn_death";
const string TRIB_BTN_INNOCENT      = "trib_btn_innocent";
const string TRIB_BTN_ROW           = "trib_btn_row";
const string TRIB_BTN_SEARCH        = "trib_btn_srch";
const string TRIB_BTN_SUBMIT_ACC    = "trib_btn_subacc";
const string TRIB_BTN_SRCH_ROW      = "trib_srow";

// ----------------------------------------------------------------
// PC local-variable keys
// ----------------------------------------------------------------

const string TRIB_LVAR_CASE_ID      = "TRIB_CASE_ID";
const string TRIB_LVAR_TARGET_UUID  = "TRIB_TARGET_UUID";
const string TRIB_LVAR_TARGET_NAME  = "TRIB_TARGET_NAME";
const string TRIB_LVAR_SEARCH_RES   = "TRIB_SEARCH_RES";

// Persistent verdict state (read by other systems, e.g. Prison module)
const string TRIB_LVAR_IMPRISONED   = "TRIB_IMPRISONED";
const string TRIB_LVAR_DEATH_MARK   = "TRIB_DEATH_MARK";
const string TRIB_LVAR_EXILED       = "TRIB_EXILED";

// ----------------------------------------------------------------
// Verdict codes
// ----------------------------------------------------------------

const int    TRIB_VERDICT_PENDING   = 0;
const int    TRIB_VERDICT_INNOCENT  = 1;
const int    TRIB_VERDICT_JAIL      = 2;
const int    TRIB_VERDICT_EXILE     = 3;
const int    TRIB_VERDICT_DEATH     = 4;

// ----------------------------------------------------------------
// Field limits
// ----------------------------------------------------------------

const int    TRIB_MAX_CHARGE        = 120;
const int    TRIB_MAX_EVIDENCE      = 800;
const int    TRIB_MAX_DEFENSE       = 800;
const int    TRIB_MAX_SENTENCE      = 120;
const int    TRIB_MAX_OPEN_PER_DEF  = 3;

// ----------------------------------------------------------------
// Layout
// ----------------------------------------------------------------

const float  TRIB_W                 = 720.0;
const float  TRIB_H                 = 540.0;

// Tag of the waypoint / placeable used as exile landing point
const string TRIB_EXILE_AREA_TAG    = "TRIB_EXILE_AREA";
