#include "lib_nui"
#include "sql_prison"

// Forward declarations
void PrisonArrestPlayer(object oPC, int nCrimeLevel, string sCrimeDesc);
void PrisonReleasePlayer(object oPC, string sOutcome);
void PrisonShowWindow(object oPC);
void PrisonRefreshStatus(object oPC, int nToken);
void PrisonHeartbeat(object oPC);

// ----------------------------------------------------------------
// Window / group IDs
// ----------------------------------------------------------------

const string PRISON_WINDOW       = "PRISON_WINDOW";
const string PRISON_EV_SCRIPT    = "lib_prison_ev";
const string PRISON_GRP_SWAP     = "PRISON_GRP_SWAP";
const string PRISON_WIN_GEOM     = "prison_win_geom";

// ----------------------------------------------------------------
// Binds — status panel
// ----------------------------------------------------------------

const string PRISON_BIND_HEADER_LBL  = "prison_header";
const string PRISON_BIND_CRIME_LBL   = "prison_crime_lbl";
const string PRISON_BIND_LEVEL_LBL   = "prison_level_lbl";
const string PRISON_BIND_SENT_LBL    = "prison_sent_lbl";
const string PRISON_BIND_TIME_LBL    = "prison_time_lbl";
const string PRISON_BIND_ATT_LBL     = "prison_att_lbl";
const string PRISON_BIND_BRIBE_TIP   = "prison_bribe_tip";
const string PRISON_BIND_PICK_TIP    = "prison_pick_tip";
const string PRISON_BIND_OVER_TIP    = "prison_over_tip";

// Escape button enabled binds
const string PRISON_BIND_SERVE_ENA   = "prison_serve_ena";
const string PRISON_BIND_BRIBE_ENA   = "prison_bribe_ena";
const string PRISON_BIND_PICK_ENA    = "prison_pick_ena";
const string PRISON_BIND_OVER_ENA    = "prison_over_ena";

// ----------------------------------------------------------------
// Binds — history panel
// ----------------------------------------------------------------

const string PRISON_BIND_HIST_CRIME  = "prison_hist_crime";
const string PRISON_BIND_HIST_DATE   = "prison_hist_date";
const string PRISON_BIND_HIST_OUT    = "prison_hist_out";
const string PRISON_BIND_HIST_COLOR  = "prison_hist_color";
const string PRISON_BIND_HIST_CNT    = "prison_hist_cnt";

// ----------------------------------------------------------------
// Button IDs
// ----------------------------------------------------------------

const string PRISON_BTN_CLOSE        = "prison_btn_close";
const string PRISON_BTN_TAB_STATUS   = "prison_tab_status";
const string PRISON_BTN_TAB_HISTORY  = "prison_tab_hist";
const string PRISON_BTN_SERVE        = "prison_btn_serve";
const string PRISON_BTN_BRIBE        = "prison_btn_bribe";
const string PRISON_BTN_PICK         = "prison_btn_pick";
const string PRISON_BTN_OVERPOWER    = "prison_btn_over";

// ----------------------------------------------------------------
// LVARs on PC object
// ----------------------------------------------------------------

const string PRISON_LVAR_HB          = "PRISON_HB";        // 1 = heartbeat running

// ----------------------------------------------------------------
// Game constants
// ----------------------------------------------------------------

const int PRISON_SENTENCE_BASE       = 120;   // seconds per crime level
const int PRISON_BRIBE_COST_BASE     = 50;    // gold per crime level
const int PRISON_BRIBE_CHANCE        = 80;    // percent chance of success
const int PRISON_BRIBE_FAIL_EXTRA    = 90;    // extra seconds per level on failed bribe
const int PRISON_PICK_DC_BASE        = 10;    // Open Lock DC = base + crime_level * 2
const int PRISON_OVER_DC_BASE        = 12;    // STR check DC = base + crime_level * 2
const int PRISON_OVER_FAIL_EXTRA     = 120;   // extra seconds on failed overpower
const int PRISON_MAX_ESC_ATTEMPTS    = 3;     // failed attempts before lockdown

// ----------------------------------------------------------------
// Layout
// ----------------------------------------------------------------

const float PRISON_W                 = 500.0;
const float PRISON_H                 = 400.0;
