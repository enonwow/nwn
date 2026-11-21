// lib_bur_def.nss — constants, IDs and forward declarations for Burial Rites

#include "lib_nui"
#include "sql_bur"

void BurShowWindow(object oPC);
void BurFeedWindow(object oPC, int nToken);
void BurApplyRite(object oPC, int nRiteType);
void BurRestorePermanentEffects(object oPC);

// ----------------------------------------------------------------
// Window / event
// ----------------------------------------------------------------

const string BUR_WINDOW     = "BUR_WINDOW";
const string BUR_EV_SCRIPT  = "lib_bur_ev";
const string BUR_WIN_GEOM   = "bur_win_geom";

// ----------------------------------------------------------------
// Rite type indices
// ----------------------------------------------------------------

const int BUR_RITE_PAUPER   = 0;
const int BUR_RITE_PROPER   = 1;
const int BUR_RITE_SACRED   = 2;

// ----------------------------------------------------------------
// Item tags (builders set these on the respective items)
// ----------------------------------------------------------------

const string BUR_TAG_CANDLE  = "bur_candle";   // Swica Pogrzebowa
const string BUR_TAG_OIL     = "bur_oil";      // Olejek Ostatni
const string BUR_TAG_SCROLL  = "bur_scroll";   // Pergamin Imion

// ----------------------------------------------------------------
// Resource costs
// ----------------------------------------------------------------

const int   BUR_COST_PROPER_GOLD  = 50;
const int   BUR_COST_SACRED_GOLD  = 200;

// ----------------------------------------------------------------
// Buff durations (seconds)
// ----------------------------------------------------------------

const float BUR_DUR_PAUPER   = 3600.0;    // 1h
const float BUR_DUR_PROPER   = 14400.0;   // 4h
const float BUR_DUR_SACRED   = 28800.0;   // 8h

// ----------------------------------------------------------------
// Effect tags — used to identify and remove burial buffs
// ----------------------------------------------------------------

const string BUR_BUFF_TAG_1  = "BUR_BUFF_PAUPER";
const string BUR_BUFF_TAG_2  = "BUR_BUFF_PROPER";
const string BUR_BUFF_TAG_3  = "BUR_BUFF_SACRED";

const string BUR_PERM_TAG_MARKED   = "BUR_PERM_MARKED";
const string BUR_PERM_TAG_BLESSED  = "BUR_PERM_BLESSED";

// ----------------------------------------------------------------
// Milestone thresholds
// ----------------------------------------------------------------

const int BUR_MILESTONE_MARKED   = 5;    // sacred rites -> Pietno Grabarza
const int BUR_MILESTONE_BLESSED  = 25;   // total burials -> Blogoslawienstwo Spokoju

// ----------------------------------------------------------------
// Local vars on PC
// ----------------------------------------------------------------

const string BUR_LVAR_MARKED   = "BUR_LVAR_MARKED";
const string BUR_LVAR_BLESSED  = "BUR_LVAR_BLESSED";

// ----------------------------------------------------------------
// NUI bind IDs
// ----------------------------------------------------------------

const string BUR_BIND_P0_ENA       = "bur_p0_ena";
const string BUR_BIND_P0_REQ_LBL   = "bur_p0_req";
const string BUR_BIND_P0_REQ_COL   = "bur_p0_req_col";

const string BUR_BIND_P1_ENA       = "bur_p1_ena";
const string BUR_BIND_P1_REQ_LBL   = "bur_p1_req";
const string BUR_BIND_P1_REQ_COL   = "bur_p1_req_col";

const string BUR_BIND_P2_ENA       = "bur_p2_ena";
const string BUR_BIND_P2_REQ_LBL   = "bur_p2_req";
const string BUR_BIND_P2_REQ_COL   = "bur_p2_req_col";

const string BUR_BIND_PROGRESS_LBL  = "bur_progress";
const string BUR_BIND_MILESTONE_LBL = "bur_milestone";
const string BUR_BIND_STATUS_LBL    = "bur_status";

// ----------------------------------------------------------------
// NUI button IDs
// ----------------------------------------------------------------

const string BUR_BTN_CLOSE   = "bur_btn_close";
const string BUR_BTN_PAUPER  = "bur_btn_p0";
const string BUR_BTN_PROPER  = "bur_btn_p1";
const string BUR_BTN_SACRED  = "bur_btn_p2";

// ----------------------------------------------------------------
// Layout dimensions (pre-scale)
// ----------------------------------------------------------------

const float BUR_W   = 500.0;
const float BUR_H   = 460.0;
