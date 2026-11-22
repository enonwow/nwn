#include "lib_nui"
#include "sql_fmask"

void FeedFmaskList(object oPC, int nToken);
void FeedFmaskDetail(object oPC, int nToken, int nMaskId);
void FmaskHandleFlayTarget(object oPC);

// ----------------------------------------------------------------
// Window / group IDs
// ----------------------------------------------------------------

const string FMASK_WINDOW       = "FMASK_WINDOW";
const string FMASK_EV_SCRIPT    = "lib_fmask_ev";
const string FMASK_GRP_DETAIL   = "FMASK_GRP_DETAIL";
const string FMASK_WIN_CONFIRM  = "FMASK_WIN_CONFIRM";
const string FMASK_WIN_GEOM     = "fmask_win_geom";

// ----------------------------------------------------------------
// List binds
// ----------------------------------------------------------------

const string FMASK_BIND_ROW_NAME  = "fmask_row_name";
const string FMASK_BIND_ROW_RACE  = "fmask_row_race";
const string FMASK_BIND_ROW_USES  = "fmask_row_uses";
const string FMASK_BIND_ROW_ENC   = "fmask_row_enc";
const string FMASK_BIND_ROW_COLOR = "fmask_row_color";
const string FMASK_BIND_ROW_UCOL  = "fmask_row_ucol";

// ----------------------------------------------------------------
// Detail binds
// ----------------------------------------------------------------

const string FMASK_BIND_DET_NAME   = "fmask_det_name";
const string FMASK_BIND_DET_FLAVOR = "fmask_det_flavor";
const string FMASK_BIND_DET_BONUS  = "fmask_det_bonus";
const string FMASK_BIND_DET_USES   = "fmask_det_uses";
const string FMASK_BIND_DET_CURSE  = "fmask_det_curse";
const string FMASK_BIND_WEAR_LBL   = "fmask_wear_lbl";
const string FMASK_BIND_WEAR_ENA   = "fmask_wear_ena";
const string FMASK_BIND_CNT_LBL    = "fmask_cnt_lbl";

// ----------------------------------------------------------------
// Buttons
// ----------------------------------------------------------------

const string FMASK_BTN_CLOSE     = "fmask_btn_close";
const string FMASK_BTN_ROW       = "fmask_btn_row";
const string FMASK_BTN_WEAR      = "fmask_btn_wear";
const string FMASK_BTN_FLAY      = "fmask_btn_flay";
const string FMASK_BTN_CONF_YES  = "fmask_conf_yes";
const string FMASK_BTN_CONF_NO   = "fmask_conf_no";

// ----------------------------------------------------------------
// LVARs on PC
// ----------------------------------------------------------------

const string FMASK_LVAR_SEL_ID    = "FMASK_SEL_ID";
const string FMASK_LVAR_WORN_ID   = "FMASK_WORN_ID";
const string FMASK_LVAR_ORIG_JSON = "FMASK_ORIG_JSON";
const string FMASK_LVAR_CONFIRM   = "FMASK_CONFIRM_MASK_ID";
const string FMASK_LVAR_TARGETING = "FMASK_TARGETING";

// Effect tag for the racial bonus effect
const string FMASK_EFFECT_TAG     = "FMASK_BONUS";

// ----------------------------------------------------------------
// Limits & timings
// ----------------------------------------------------------------

const int   FMASK_CURSE_WHISPER_MIN = 60;
const int   FMASK_CURSE_WHISPER_RND = 120;

// ----------------------------------------------------------------
// Layout
// ----------------------------------------------------------------

const float FMASK_W               = 640.0;
const float FMASK_H               = 480.0;
const float FMASK_LIST_W          = 240.0;
