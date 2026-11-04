#include "lib_nui"
#include "sql_mmori"

void CreateMmoriMarkWindow(object oPC);
void CreateMmoriCairnWindow(object oPC, int nMarkId);
void CreateMmoriOwnCairnWindow(object oPC, int nMarkId, object oCairn);
void FeedMmoriCairnView(object oPC, int nToken, int nMarkId);

// ----------------------------------------------------------------
// Window / event-script IDs
// ----------------------------------------------------------------

const string MMORI_WIN_LASTWORDS  = "MMORI_WIN_LASTWORDS";
const string MMORI_WIN_CAIRN      = "MMORI_WIN_CAIRN";
const string MMORI_EV_SCRIPT      = "lib_mmori_ev";

// ----------------------------------------------------------------
// Bind IDs — Last Words window
// ----------------------------------------------------------------

const string MMORI_BIND_LW_AREA   = "mmori_lw_area";
const string MMORI_BIND_LW_TXT    = "mmori_lw_txt";
const string MMORI_BIND_LW_GEOM   = "mmori_lw_geom";

// ----------------------------------------------------------------
// Bind IDs — Cairn window
// ----------------------------------------------------------------

const string MMORI_BIND_CA_HEADER = "mmori_ca_header";
const string MMORI_BIND_CA_WORDS  = "mmori_ca_words";
const string MMORI_BIND_CA_FOOTER = "mmori_ca_footer";
const string MMORI_BIND_CA_GEOM   = "mmori_ca_geom";
const string MMORI_BIND_CA_MOURN  = "mmori_ca_mourn_lbl";
const string MMORI_BIND_CA_MOURNA = "mmori_ca_mourn_ena";
const string MMORI_BIND_CA_RECLAIM= "mmori_ca_reclaim_vis";
const string MMORI_BIND_CA_LEGEND = "mmori_ca_legend_vis";

// ----------------------------------------------------------------
// Button IDs
// ----------------------------------------------------------------

const string MMORI_BTN_LW_CONFIRM = "mmori_btn_lwconfirm";
const string MMORI_BTN_LW_SKIP    = "mmori_btn_lwskip";
const string MMORI_BTN_CA_MOURN   = "mmori_btn_mourn";
const string MMORI_BTN_CA_RECLAIM = "mmori_btn_reclaim";
const string MMORI_BTN_CA_CLOSE   = "mmori_btn_caclose";

// ----------------------------------------------------------------
// Local vars on PC / cairn placeable
// ----------------------------------------------------------------

const string MMORI_LVAR_DEATH_AREA  = "MMORI_DEATH_AREA";
const string MMORI_LVAR_DEATH_X     = "MMORI_DEATH_X";
const string MMORI_LVAR_DEATH_Y     = "MMORI_DEATH_Y";
const string MMORI_LVAR_DEATH_Z     = "MMORI_DEATH_Z";
const string MMORI_LVAR_DEATH_ANAME = "MMORI_DEATH_ANAME";
const string MMORI_LVAR_PENDING     = "MMORI_PENDING";     // 1 = death loc stored, waiting for respawn
const string MMORI_LVAR_MARK_ID     = "MMORI_MARK_ID";     // on cairn placeable

// ----------------------------------------------------------------
// Gameplay tuning
// ----------------------------------------------------------------

const int    MMORI_EXPIRY_DAYS        = 14;    // non-legendary marks expire after 14 days
const int    MMORI_LEGENDARY_THRESH   = 7;     // mourners needed for legendary status
const int    MMORI_BUFF_DURATION      = 300;   // seconds for mourning buff
const int    MMORI_RECLAIM_HP_BONUS   = 10;    // HP restored when owner reclaims their stone
const string MMORI_CAIRN_RESREF       = "plc_brlstn1";   // base NWN burial stone placeable
const string MMORI_CAIRN_TAG_PREFIX   = "mmori_cairn_";

// ----------------------------------------------------------------
// Layout
// ----------------------------------------------------------------

const float  MMORI_LW_W   = 480.0;
const float  MMORI_LW_H   = 280.0;
const float  MMORI_CA_W   = 500.0;
const float  MMORI_CA_H   = 340.0;
