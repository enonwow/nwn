#include "lib_nui"
#include "sql_smit"

void SmithOpenWindow(object oPC);
void SmithFeedRecipeList(object oPC, int nToken);
void SmithFeedForgePanel(object oPC, int nToken);
void SmithFeedHistoryPanel(object oPC, int nToken);

// ---- Window / group IDs ----
const string SMIT_WINDOW      = "SMIT_WINDOW";
const string SMIT_EV_SCRIPT   = "lib_smit_ev";
const string SMIT_GRP_CONTENT = "SMIT_GRP";
const string SMIT_WIN_GEOM    = "smit_win_geom";

// ---- Recipe list binds ----
const string SMIT_BIND_REC_NAME  = "smit_rec_name";
const string SMIT_BIND_REC_CAT   = "smit_rec_cat";
const string SMIT_BIND_REC_DC    = "smit_rec_dc";
const string SMIT_BIND_REC_ENC   = "smit_rec_enc";
const string SMIT_BIND_REC_COUNT = "smit_rec_cnt";

// ---- Forge panel binds ----
const string SMIT_BIND_FG_TITLE = "smit_fg_title";
const string SMIT_BIND_FG_CAT   = "smit_fg_cat";
const string SMIT_BIND_FG_DESC  = "smit_fg_desc";
const string SMIT_BIND_FG_DC    = "smit_fg_dc";
const string SMIT_BIND_FG_ENA   = "smit_fg_ena";
const string SMIT_BIND_FG_LBL   = "smit_fg_lbl";
const string SMIT_BIND_MAT_NAME = "smit_mat_name";
const string SMIT_BIND_MAT_HAVE = "smit_mat_have";
const string SMIT_BIND_MAT_COL  = "smit_mat_col";
const string SMIT_BIND_MAT_CNT  = "smit_mat_cnt";

// ---- History panel binds ----
const string SMIT_BIND_HI_NAME  = "smit_hi_name";
const string SMIT_BIND_HI_QUAL  = "smit_hi_qual";
const string SMIT_BIND_HI_DATE  = "smit_hi_date";
const string SMIT_BIND_HI_COL   = "smit_hi_col";
const string SMIT_BIND_HI_COUNT = "smit_hi_cnt";

// ---- Buttons ----
const string SMIT_BTN_CLOSE   = "smit_btn_close";
const string SMIT_BTN_HISTORY = "smit_btn_hist";
const string SMIT_BTN_BACK    = "smit_btn_back";
const string SMIT_BTN_ROW     = "smit_btn_row";
const string SMIT_BTN_FORGE   = "smit_btn_forge";
const string SMIT_BTN_F_ALL   = "smit_f_all";
const string SMIT_BTN_F_WPN   = "smit_f_wpn";
const string SMIT_BTN_F_ARM   = "smit_f_arm";
const string SMIT_BTN_F_SHL   = "smit_f_shl";

// ---- PC local variables ----
const string SMIT_LVAR_SEL      = "SMIT_SEL_REC";
const string SMIT_LVAR_FILTER   = "SMIT_FILTER";
const string SMIT_LVAR_RECIPES  = "SMIT_RECIPES";

// ---- Layout constants ----
const float SMIT_W = 740.0;
const float SMIT_H = 530.0;
