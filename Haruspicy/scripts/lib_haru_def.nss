#include "lib_nui"
#include "sql_haru"

void HaruFeedSigns(object oPC, int nToken, json jSigns);
void HaruFeedProphecy(object oPC, int nToken, int nScore, string sProphecy);
void HaruFeedHistory(object oPC, int nToken);
void HaruOpenReading(object oPC, object oSource);
void HaruOpenHistory(object oPC);

// ----------------------------------------------------------------
// Window / event IDs
// ----------------------------------------------------------------

const string HARU_WIN_MAIN   = "HARU_WIN_MAIN";
const string HARU_WIN_HIST   = "HARU_WIN_HIST";
const string HARU_EV_SCRIPT  = "lib_haru_ev";
const string HARU_WIN_GEOM   = "haru_win_geom";
const string HARU_HIST_GEOM  = "haru_hist_geom";

// ----------------------------------------------------------------
// Bind names — main window
// ----------------------------------------------------------------

const string HARU_BIND_TITLE      = "haru_title";       // string
const string HARU_BIND_ORG_NAMES  = "haru_org_names";   // string[]
const string HARU_BIND_ORG_SIGNS  = "haru_org_signs";   // string[]
const string HARU_BIND_ORG_COLS   = "haru_org_cols";    // NuiColor[]
const string HARU_BIND_ORG_COUNT  = "haru_org_count";   // int
const string HARU_BIND_PROPHECY   = "haru_prophecy";    // string
const string HARU_BIND_SCORE_LBL  = "haru_score_lbl";   // string
const string HARU_BIND_SCORE_COL  = "haru_score_col";   // NuiColor
const string HARU_BIND_EFFECT_LBL = "haru_effect_lbl";  // string
const string HARU_BIND_APPLY_ENA  = "haru_apply_ena";   // bool
const string HARU_BIND_READINGS   = "haru_readings";    // string (e.g. "Odczytów: 7")

// Bind names — history window
const string HARU_BIND_HIST_DATE  = "haru_hist_date";   // string[]
const string HARU_BIND_HIST_CNAME = "haru_hist_cname";  // string[]
const string HARU_BIND_HIST_SCORE = "haru_hist_score";  // string[]
const string HARU_BIND_HIST_SCOL  = "haru_hist_scol";   // NuiColor[]
const string HARU_BIND_HIST_TEXT  = "haru_hist_text";   // string[]
const string HARU_BIND_HIST_COUNT = "haru_hist_count";  // int
const string HARU_BIND_HIST_TOTAL = "haru_hist_total";  // string

// ----------------------------------------------------------------
// Buttons
// ----------------------------------------------------------------

const string HARU_BTN_CLOSE     = "haru_btn_close";
const string HARU_BTN_APPLY     = "haru_btn_apply";
const string HARU_BTN_HISTORY   = "haru_btn_history";
const string HARU_BTN_HISTCLOSE = "haru_btn_histclose";

// ----------------------------------------------------------------
// Local variables on PC
// ----------------------------------------------------------------

const string HARU_LVAR_SIGNS    = "HARU_SIGNS";      // json array of 6 ints
const string HARU_LVAR_SCORE    = "HARU_SCORE";
const string HARU_LVAR_CNAME    = "HARU_CNAME";
const string HARU_LVAR_CTYPE    = "HARU_CTYPE";
const string HARU_LVAR_CR       = "HARU_CR";
const string HARU_LVAR_APPLIED  = "HARU_APPLIED";    // 1 once effect is applied
const string HARU_LVAR_TARGETING= "HARU_TARGETING";  // 1 when in targeting mode

// Local variables on the corpse / source object
const string HARU_SRC_READABLE  = "HARU_READABLE";
const string HARU_SRC_CNAME     = "HARU_ITEM_CNAME";
const string HARU_SRC_CTYPE     = "HARU_ITEM_CTYPE";
const string HARU_SRC_CR        = "HARU_ITEM_CR";

// ----------------------------------------------------------------
// Sign constants
// ----------------------------------------------------------------

const int HARU_SIGN_INAUSPICIOUS = -1;
const int HARU_SIGN_NEUTRAL      =  0;
const int HARU_SIGN_AUSPICIOUS   =  1;

// ----------------------------------------------------------------
// Creature type categories (internal)
// ----------------------------------------------------------------

const int HARU_CTYPE_HUMANOID = 1;
const int HARU_CTYPE_BEAST    = 2;
const int HARU_CTYPE_UNDEAD   = 3;
const int HARU_CTYPE_DRAGON   = 4;
const int HARU_CTYPE_DEMON    = 5;
const int HARU_CTYPE_OTHER    = 6;

// ----------------------------------------------------------------
// Effect IDs (what was applied)
// ----------------------------------------------------------------

const int HARU_EFF_NONE      = 0;
const int HARU_EFF_HASTE     = 1;
const int HARU_EFF_SAVES     = 2;
const int HARU_EFF_AC        = 3;
const int HARU_EFF_LORE      = 4;
const int HARU_EFF_ATK_DEBUF = 5;
const int HARU_EFF_DAM_DEBUF = 6;
const int HARU_EFF_CURSE     = 7;

// ----------------------------------------------------------------
// Layout dimensions
// ----------------------------------------------------------------

const float HARU_WIN_W   = 660.0;
const float HARU_WIN_H   = 460.0;
const float HARU_HIST_W  = 540.0;
const float HARU_HIST_H  = 400.0;
const int   HARU_HIST_LIMIT = 30;
