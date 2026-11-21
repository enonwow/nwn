#include "lib_nui"
#include "sql_stn"

void CreateStanceWindow(object oPC);
void CreateStanceWidget(object oPC);
void FeedStanceWindow(object oPC, int nToken);
void FeedStanceWidget(object oPC, int nToken);
void StnAdoptStance(object oPC, int nId);
void StnUnlockAtTrainer(object oPC, int nId);

// ----------------------------------------------------------------
// Stance IDs
// ----------------------------------------------------------------

const int STN_STANCE_READY  = 0; // Oczekiwanie
const int STN_STANCE_FURY   = 1; // Uderzenie Gwaltowne
const int STN_STANCE_IRON   = 2; // Zelazna Obrona
const int STN_STANCE_BLOOD  = 3; // Szal Krwi        (unlock)
const int STN_STANCE_SHADOW = 4; // Mrok w Oczach    (unlock)
const int STN_STANCE_DEATH  = 5; // Pieczen Smierci  (unlock)
const int STN_COUNT         = 6;

const int STN_FREE_COUNT    = 3; // stances 0-2 always unlocked

// ----------------------------------------------------------------
// Unlock costs (GP)
// ----------------------------------------------------------------

const int STN_COST_BLOOD  = 500;
const int STN_COST_SHADOW = 400;
const int STN_COST_DEATH  = 600;

// ----------------------------------------------------------------
// Effect identification
// ----------------------------------------------------------------

const string STN_EFFECT_TAG = "STN_STANCE_FX";

// ----------------------------------------------------------------
// Window IDs
// ----------------------------------------------------------------

const string STN_WIN_BOOK   = "STN_WIN_BOOK";
const string STN_WIN_WIDGET = "STN_WIN_WIDGET";
const string STN_EV_SCRIPT  = "lib_stn_ev";

// ----------------------------------------------------------------
// Book window binds
// ----------------------------------------------------------------

const string STN_BIND_WIN_GEOM      = "stn_geom";
const string STN_BIND_ROW_NAME      = "stn_row_name";
const string STN_BIND_ROW_STATUS    = "stn_row_status";
const string STN_BIND_ROW_ENC       = "stn_row_enc";
const string STN_BIND_ROW_COLOR     = "stn_row_color";
const string STN_BIND_ROW_COUNT     = "stn_rowcount";
const string STN_BIND_DESC          = "stn_desc";
const string STN_BIND_COST_LBL      = "stn_cost_lbl";
const string STN_BIND_ADOPT_ENA     = "stn_adopt_ena";
const string STN_BIND_ADOPT_LBL     = "stn_adopt_lbl";
const string STN_BIND_UNLOCK_VIS    = "stn_unlock_vis";
const string STN_BIND_UNLOCK_ENA    = "stn_unlock_ena";
const string STN_BIND_UNLOCK_LBL    = "stn_unlock_lbl";
const string STN_BIND_HEADER        = "stn_header";

// ----------------------------------------------------------------
// Widget binds
// ----------------------------------------------------------------

const string STN_BIND_WGT_GEOM      = "stn_wgt_geom";
const string STN_BIND_WGT_NAME      = "stn_wgt_name";
const string STN_BIND_WGT_COLOR     = "stn_wgt_color";

// ----------------------------------------------------------------
// Buttons
// ----------------------------------------------------------------

const string STN_BTN_CLOSE          = "stn_btn_close";
const string STN_BTN_ADOPT          = "stn_btn_adopt";
const string STN_BTN_UNLOCK         = "stn_btn_unlock";
const string STN_BTN_ROW            = "stn_btn_row";
const string STN_BTN_WGT_OPEN       = "stn_btn_wgt_open";
const string STN_BTN_WGT_CLOSE      = "stn_btn_wgt_close";

// ----------------------------------------------------------------
// LVARs
// ----------------------------------------------------------------

const string STN_LVAR_SEL           = "STN_SEL_STANCE";

// ----------------------------------------------------------------
// Layout
// ----------------------------------------------------------------

const float STN_W   = 640.0;
const float STN_H   = 480.0;
const float STN_WGT_W = 210.0;
const float STN_WGT_H = 60.0;
