// lib_chaos_def.nss — constants, NUI IDs, bind names, and forward declarations
// for the Chaos Surge system.

#include "lib_nui"
#include "sql_chaos"

// ── Window identifiers ────────────────────────────────────────────────────────

const string CHAOS_WINDOW     = "CHAOS_WINDOW";
const string CHAOS_EV_SCRIPT  = "lib_chaos_ev";
const string CHAOS_WIN_GEOM   = "chaos_win_geom";

// ── Bind names — chaos meter ──────────────────────────────────────────────────

const string CHAOS_BIND_METER_VAL   = "chaos_mval";      // float 0.0–1.0 for NuiProgress
const string CHAOS_BIND_METER_COL   = "chaos_mcol";      // NuiColor for progress bar fill
const string CHAOS_BIND_CP_LBL      = "chaos_cplbl";     // "47 / 100"
const string CHAOS_BIND_STATUS_LBL  = "chaos_stlbl";     // "Spokój" / "Wzburzenie" etc.
const string CHAOS_BIND_STATUS_COL  = "chaos_stcol";     // NuiColor for status label

// ── Bind names — surge log list ───────────────────────────────────────────────

const string CHAOS_BIND_LOG_TEXT    = "chaos_logtxt";    // JsonArray of strings
const string CHAOS_BIND_LOG_COL     = "chaos_logcol";    // JsonArray of NuiColor
const string CHAOS_BIND_LOG_CNT     = "chaos_logcnt";    // int row count for NuiList

// ── Bind names — footer ───────────────────────────────────────────────────────

const string CHAOS_BIND_SURGE_ENA   = "chaos_surge_ena"; // bool — surge button enabled
const string CHAOS_BIND_SURGE_LBL   = "chaos_surge_lbl"; // button label with CP cost
const string CHAOS_BIND_TOTAL_LBL   = "chaos_total_lbl"; // "Łączne pulsacje: N"

// ── Button IDs ────────────────────────────────────────────────────────────────

const string CHAOS_BTN_CLOSE        = "chaos_btn_close";
const string CHAOS_BTN_SURGE        = "chaos_btn_surge";

// ── Local variables on PC ─────────────────────────────────────────────────────

const string CHAOS_LVAR_CP          = "CHAOS_CP";        // int 0–100
const string CHAOS_LVAR_TOTAL       = "CHAOS_TOTAL";     // int lifetime surge count
const string CHAOS_LVAR_LOG         = "CHAOS_LOG";       // JsonArray of log entries

// ── Tunable settings ──────────────────────────────────────────────────────────

const int   CHAOS_MAX               = 100;
const int   CHAOS_THRESHOLD         = 60;  // surge zone starts here
const int   CHAOS_SURGE_COST        = 40;  // CP consumed by manual surge trigger
const int   CHAOS_REST_REDUCE       = 35;  // CP lost per rest
const int   CHAOS_LOG_MAX           = 8;   // entries kept in history

// ── Effect tag ────────────────────────────────────────────────────────────────

const string CHAOS_TAG_SURGE_BUFF   = "CHAOS_SURGE";

// ── Window dimensions ─────────────────────────────────────────────────────────

const float CHAOS_W                 = 480.0;
const float CHAOS_H                 = 430.0;

// ── Forward declarations ──────────────────────────────────────────────────────

void  FeedChaosWindow (object oPC, int nToken);
void  ChaosOpenWindow (object oPC);
int   ChaosGetCP      (object oPC);
void  ChaosSetCP      (object oPC, int nNew);
int   ChaosAddCP      (object oPC, int nAmt);
void  ChaosRollSurge  (object oPC);
void  ChaosExecuteSurge (object oPC, int nRoll);
string ChaosGetSurgeName (int nRoll);
int   ChaosGetSurgeCategory (int nRoll);
void  ChaosAppendLog  (object oPC, int nRoll);
void  ChaosRemoveTaggedEffects (object oPC, string sTag);
void  ChaosSaveState  (object oPC);
void  ChaosLoadState  (object oPC);
