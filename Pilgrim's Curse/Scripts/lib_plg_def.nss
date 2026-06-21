#include "lib_nui"
#include "sql_plg"

// Forward declarations — defined in lib_plg.nss
void PlgOpenWindow(object oPC);
void PlgApplyBurdenEffects(object oPC);
void PlgRemoveBurdenEffects(object oPC);
void PlgHandleShrine(object oPC, object oShrine);
void PlgFeedStatus(object oPC, int nToken);
void PlgFeedShrines(object oPC, int nToken);
void PlgFeedLeaderboard(object oPC, int nToken);
void PlgSwapTab(object oPC, int nToken, int nTab);
void PlgShowShrinePopup(object oPC, int nShrineId, int bAlreadyVisited);
json PlgBuildStatusTab(object oPC);
json PlgBuildShrinesTab(object oPC);
json PlgBuildLeaderboardTab(object oPC);

// ----------------------------------------------------------------
// Window identifiers
// ----------------------------------------------------------------

const string PLG_WINDOW           = "PLG_WINDOW";
const string PLG_EV_SCRIPT        = "lib_plg_ev";
const string PLG_GRP_SWAP         = "PLG_GRP_SWAP";
const string PLG_WIN_GEOM         = "plg_win_geom";
const string PLG_WIN_SHRINE_INFO  = "PLG_WIN_SINFO";

// ----------------------------------------------------------------
// Button IDs
// ----------------------------------------------------------------

const string PLG_BTN_CLOSE        = "plg_btn_close";
const string PLG_BTN_TAB_STATUS   = "plg_btn_tab0";
const string PLG_BTN_TAB_SHRINES  = "plg_btn_tab1";
const string PLG_BTN_TAB_BOARD    = "plg_btn_tab2";
const string PLG_BTN_CATHARSIS    = "plg_btn_kath";
const string PLG_BTN_SHRINE_ROW   = "plg_btn_srow";
const string PLG_BTN_SINFO_CLOSE  = "plg_btn_sinfc";

// ----------------------------------------------------------------
// Status tab bind keys
// ----------------------------------------------------------------

const string PLG_BIND_SHADOW_VAL  = "plg_sv";
const string PLG_BIND_BLOOD_VAL   = "plg_bv";
const string PLG_BIND_DEATH_VAL   = "plg_dv";
const string PLG_BIND_CHAOS_VAL   = "plg_cv";
const string PLG_BIND_SHADOW_PRG  = "plg_sp";
const string PLG_BIND_BLOOD_PRG   = "plg_bp";
const string PLG_BIND_DEATH_PRG   = "plg_dp";
const string PLG_BIND_CHAOS_PRG   = "plg_cp";
const string PLG_BIND_TOTAL_LBL   = "plg_total";
const string PLG_BIND_TIER_LBL    = "plg_tier";
const string PLG_BIND_FX_LBL      = "plg_fxlbl";
const string PLG_BIND_VISITS_LBL  = "plg_visits";
const string PLG_BIND_CIRCUITS_LBL = "plg_circuits";
const string PLG_BIND_KATH_ENA    = "plg_kath_ena";
const string PLG_BIND_KATH_LBL    = "plg_kath_lbl";
const string PLG_BIND_KATH_TIP    = "plg_kath_tip";

// ----------------------------------------------------------------
// Shrines tab bind keys
// ----------------------------------------------------------------

const string PLG_BIND_SHRINE_NAME = "plg_sname";
const string PLG_BIND_SHRINE_TYPE = "plg_stype";
const string PLG_BIND_SHRINE_VIS  = "plg_svis";
const string PLG_BIND_SHRINE_ENC  = "plg_senc";
const string PLG_BIND_SHRINE_CNT  = "plg_scnt";

// ----------------------------------------------------------------
// Shrine info popup bind keys
// ----------------------------------------------------------------

const string PLG_BIND_SINFO_NAME  = "plg_si_name";
const string PLG_BIND_SINFO_TYPE  = "plg_si_type";
const string PLG_BIND_SINFO_LORE  = "plg_si_lore";
const string PLG_BIND_SINFO_STAT  = "plg_si_stat";
const string PLG_BIND_SINFO_GEOM  = "plg_si_geom";

// ----------------------------------------------------------------
// Leaderboard bind keys
// ----------------------------------------------------------------

const string PLG_BIND_BOARD_NAME     = "plg_bname";
const string PLG_BIND_BOARD_TOTAL    = "plg_btotal";
const string PLG_BIND_BOARD_CIRCUITS = "plg_bcirc";
const string PLG_BIND_BOARD_CNT      = "plg_bcnt";

// ----------------------------------------------------------------
// Local variables stored on the PC object
// ----------------------------------------------------------------

const string PLG_LVAR_TAB         = "PLG_TAB";       // 0=status 1=shrines 2=leaderboard
const string PLG_LVAR_SEL_SHRINE  = "PLG_SEL_SH";    // shrine id last selected in list

// ----------------------------------------------------------------
// Game design constants
// ----------------------------------------------------------------

// TagEffect tag — lets us find and remove burden effects later.
const string PLG_FX_TAG           = "PLG_BURDEN";

// Placeable tag for the catharsis altar.
const string PLG_CATHARSIS_TAG    = "plg_catharsis";

// Window dimensions
const float PLG_W                 = 640.0;
const float PLG_H                 = 530.0;

// Burden thresholds that unlock tier effects.
const int PLG_TIER_1              = 3;   // Minor blessing begins
const int PLG_TIER_2              = 6;   // Fear immunity, ultravision
const int PLG_TIER_3              = 10;  // Constitution buff, disease immunity
const int PLG_TIER_4              = 15;  // Poison+paralysis immunity, CHA penalty

// Upper bound for the progress-bar display (clamped to 1.0 above this).
const int PLG_BAR_MAX             = 20;
