#include "lib_nui"
#include "sql_sin"

// ----------------------------------------------------------------
// Forward declarations
// ----------------------------------------------------------------

void SinRemoveTaggedEffects(object oPC, string sTag);
void SinApplyPenalties(object oPC);
void SinApplyEmbraceEffects(object oPC);
void SinAddSin(object oPC, int nSinType, int nAmount, string sDesc);
void SinAbsolve(object oPC);
void SinEmbrace(object oPC);
void SinOpenWindow(object oPC);
void SinFeedWindow(object oPC, int nToken);

// ----------------------------------------------------------------
// Window identifiers
// ----------------------------------------------------------------

const string SIN_WINDOW    = "SIN_WINDOW";
const string SIN_EV_SCRIPT = "lib_sin_ev";

// ----------------------------------------------------------------
// Bind names — prefix "sin_"
// ----------------------------------------------------------------

const string SIN_BIND_GAUGE       = "sin_gauge";
const string SIN_BIND_STATUS_LBL  = "sin_status_lbl";
const string SIN_BIND_STATUS_COL  = "sin_status_col";
const string SIN_BIND_PENALTY_LBL = "sin_penalty_lbl";
const string SIN_BIND_ABS_LBL     = "sin_abs_lbl";
const string SIN_BIND_ABS_ENA     = "sin_abs_ena";
const string SIN_BIND_EMB_LBL     = "sin_emb_lbl";
const string SIN_BIND_EMB_ENA     = "sin_emb_ena";
const string SIN_BIND_ROW_TYPE    = "sin_row_type";
const string SIN_BIND_ROW_DESC    = "sin_row_desc";
const string SIN_BIND_ROW_AMT     = "sin_row_amt";
const string SIN_BIND_ROW_COLOR   = "sin_row_col";
const string SIN_BIND_ROW_COUNT   = "sin_row_cnt";

// ----------------------------------------------------------------
// Button identifiers
// ----------------------------------------------------------------

const string SIN_BTN_CLOSE   = "sin_btn_close";
const string SIN_BTN_ABS     = "sin_btn_abs";
const string SIN_BTN_EMBRACE = "sin_btn_emb";

// ----------------------------------------------------------------
// Sin type constants
// ----------------------------------------------------------------

const int SIN_TYPE_MURDER      = 1;
const int SIN_TYPE_THEFT       = 2;
const int SIN_TYPE_BLASPHEMY   = 3;
const int SIN_TYPE_DARK_RITUAL = 4;
const int SIN_TYPE_BETRAYAL    = 5;
const int SIN_TYPE_UNDEAD      = 6;
const int SIN_TYPE_DEMON_PACT  = 7;
const int SIN_TYPE_CORRUPTION  = 8;
const int SIN_TYPE_DESECRATION = 9;

// ----------------------------------------------------------------
// Score thresholds (inclusive lower bound)
// ----------------------------------------------------------------

const int SIN_LEVEL_TAINTED = 10;
const int SIN_LEVEL_IMPURE  = 25;
const int SIN_LEVEL_WICKED  = 50;
const int SIN_LEVEL_CORRUPT = 75;
const int SIN_LEVEL_DAMNED  = 100;

// ----------------------------------------------------------------
// Limits and costs
// ----------------------------------------------------------------

const int SIN_MAX             = 150;
const int SIN_LOG_LIMIT       = 15;
const int SIN_ABS_GOLD_PER_PT = 80;
const int SIN_EMBRACE_MIN     = 75;
const int SIN_EMBRACE_COST    = 15;

// ----------------------------------------------------------------
// Tagged effect identifiers
// ----------------------------------------------------------------

const string SIN_EFFECT_TAG  = "SIN_PENALTY";
const string SIN_EMBRACE_TAG = "SIN_EMBRACE";

// ----------------------------------------------------------------
// Window geometry
// ----------------------------------------------------------------

const float SIN_W = 480.0;
const float SIN_H = 530.0;
