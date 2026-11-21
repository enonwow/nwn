#include "lib_nui"
#include "sql_msk"

void MskOpenPanel(object oPC);
void MskFeedPanel(object oPC, int nToken);
void MskFeedMaskList(object oPC, int nToken);
void MskActivate(object oPC, int nToken, int nMaskId);
void MskDeactivate(object oPC, int nToken);
void MskBlowCover(object oPC);
void MskScheduleHeartbeat(object oPC);
void MskTickSuspicion(object oPC);
void MskAddSpellSuspicion(object oPC);

// ----------------------------------------------------------------
// Window / group IDs
// ----------------------------------------------------------------

const string MSK_WINDOW         = "MSK_WINDOW";
const string MSK_EV_SCRIPT      = "lib_msk_ev";
const string MSK_WIN_GEOM       = "msk_win_geom";
const string MSK_GRP_STATUS     = "MSK_GRP_STATUS";
const string MSK_GRP_LIST       = "MSK_GRP_LIST";

// ----------------------------------------------------------------
// Binds — status panel
// ----------------------------------------------------------------

const string MSK_BIND_IDENTITY_LBL   = "msk_identity_lbl";
const string MSK_BIND_FLAVOR_TXT     = "msk_flavor_txt";
const string MSK_BIND_SUSP_BAR       = "msk_susp_bar";
const string MSK_BIND_SUSP_LBL       = "msk_susp_lbl";
const string MSK_BIND_SUSP_COLOR     = "msk_susp_color";
const string MSK_BIND_BTN_REMOVE_ENA = "msk_btn_rem_ena";
const string MSK_BIND_BTN_REMOVE_LBL = "msk_btn_rem_lbl";

// Binds — mask list (NuiList)
const string MSK_BIND_ROW_NAME       = "msk_row_name";
const string MSK_BIND_ROW_FLAVOR     = "msk_row_flavor";
const string MSK_BIND_ROW_ENC        = "msk_row_enc";
const string MSK_BIND_ROW_BTN_ENA    = "msk_row_btn_ena";

// ----------------------------------------------------------------
// Buttons
// ----------------------------------------------------------------

const string MSK_BTN_CLOSE       = "msk_btn_close";
const string MSK_BTN_WEAR        = "msk_btn_wear";       // per-row "Załóż"
const string MSK_BTN_REMOVE      = "msk_btn_remove";     // global "Zdejmij"

// ----------------------------------------------------------------
// Local vars on PC
// ----------------------------------------------------------------

const string MSK_LVAR_ACTIVE_ID      = "MSK_ACTIVE_ID";
const string MSK_LVAR_ACTIVE_NAME    = "MSK_ACTIVE_NAME";
const string MSK_LVAR_SUSPICION      = "MSK_SUSPICION";
const string MSK_LVAR_HB_DELAY      = "MSK_HB_DELAY";

// ----------------------------------------------------------------
// Layout
// ----------------------------------------------------------------

const float  MSK_W               = 560.0;
const float  MSK_H               = 500.0;
const int    MSK_SUSP_MAX        = 100;

// ----------------------------------------------------------------
// Suspicion thresholds
// ----------------------------------------------------------------

const int    MSK_SUSP_WARN       = 60;   // żółty
const int    MSK_SUSP_DANGER     = 80;   // czerwony

// ----------------------------------------------------------------
// Heartbeat tick interval (seconds)
// ----------------------------------------------------------------

const float  MSK_HB_INTERVAL    = 6.0;

// ----------------------------------------------------------------
// Suspicion increments per tick
// ----------------------------------------------------------------

const int    MSK_SUSP_COMBAT     = 4;   // każdy tick w walce
const int    MSK_SUSP_SPELL      = 2;   // każdy rzucony czar (patrz sys_on_spell)
const int    MSK_SUSP_PASSIVE    = 1;   // pasywnie, zawsze
