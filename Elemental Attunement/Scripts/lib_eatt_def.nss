// lib_eatt_def.nss — constants, bind names, forward declarations for Elemental Attunement
#include "lib_nui"
#include "sql_eatt"

void EattOpenWindow(object oPC);
void EattFeedWindow(object oPC, int nToken);
void EattApplyEffects(object oPC);
void EattRestoreEffects(object oPC);
void EattAddPoints(object oPC, int nElem, int nPoints);

// ----------------------------------------------------------------
// Element indices
// ----------------------------------------------------------------

const int EATT_ELEM_FIRE       = 0;
const int EATT_ELEM_COLD       = 1;
const int EATT_ELEM_ACID       = 2;
const int EATT_ELEM_LIGHTNING  = 3;
const int EATT_ELEM_SHADOW     = 4;
const int EATT_ELEM_COUNT      = 5;

// ----------------------------------------------------------------
// Tier thresholds (attunement points)
// ----------------------------------------------------------------

const int EATT_TIER1_PTS = 100;
const int EATT_TIER2_PTS = 300;
const int EATT_TIER3_PTS = 600;
const int EATT_MAX_PTS   = 700;

// ----------------------------------------------------------------
// Economy
// ----------------------------------------------------------------

const int EATT_PURGE_COST = 500;    // gold to reset one element

// ----------------------------------------------------------------
// Window / event-script identifiers
// ----------------------------------------------------------------

const string EATT_WINDOW      = "EATT_WINDOW";
const string EATT_EV_SCRIPT   = "lib_eatt_ev";
const string EATT_WIN_GEOM    = "eatt_win_geom";

// ----------------------------------------------------------------
// NUI bind names
// ----------------------------------------------------------------

const string EATT_BIND_ELEM_NAME = "eatt_elem_name";   // string array[5]
const string EATT_BIND_ELEM_PROG = "eatt_elem_prog";   // float  array[5], 0.0–1.0
const string EATT_BIND_ELEM_TIER = "eatt_elem_tier";   // string array[5]
const string EATT_BIND_ELEM_ENC  = "eatt_elem_enc";    // bool   array[5]
const string EATT_BIND_DESC      = "eatt_desc";        // string — selected element info
const string EATT_BIND_PURGE_ENA = "eatt_purge_ena";   // bool
const string EATT_BIND_PURGE_LBL = "eatt_purge_lbl";   // string
const string EATT_BIND_ROWCOUNT  = "eatt_rowcount";    // int = 5

// ----------------------------------------------------------------
// Button IDs
// ----------------------------------------------------------------

const string EATT_BTN_ROW    = "eatt_btn_row";
const string EATT_BTN_CLOSE  = "eatt_btn_close";
const string EATT_BTN_PURGE  = "eatt_btn_purge";

// ----------------------------------------------------------------
// Local variables on PC
// ----------------------------------------------------------------

const string EATT_LVAR_SEL    = "EATT_SEL_ELEM";      // int — currently selected element
const string EATT_PREV_SCRIPT = "EATT_PREV_DAMAGED";  // string — chained OnDamaged script

// ----------------------------------------------------------------
// Effect tag prefix (all our tagged effects start with this)
// ----------------------------------------------------------------

const string EATT_EFF_TAG = "EATT_";

// ----------------------------------------------------------------
// Layout
// ----------------------------------------------------------------

const float EATT_W = 500.0;
const float EATT_H = 500.0;
