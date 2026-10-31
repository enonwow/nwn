#include "lib_nui"
#include "sql_sleg"

void SlegOpenWindow(object oPC);
void SlegFeedList(object oPC, int nToken);
void SlegFeedDetail(object oPC, int nToken, int nId);
void SlegApplyEffects(object oPC);
void SlegRemoveEffects(object oPC);
void SlegCheckOnEnter(object oPC);
void SlegRecordDeath(object oPC);

// ---------------------------------------------------------------
// Window IDs
// ---------------------------------------------------------------

const string SLEG_WINDOW          = "SLEG_WIN";
const string SLEG_EV_SCRIPT       = "lib_sleg_ev";
const string SLEG_WIN_GEOM        = "sleg_win_geom";

// ---------------------------------------------------------------
// Bind IDs — list column arrays
// ---------------------------------------------------------------

const string SLEG_BIND_ROW_TYPE   = "sleg_row_type";
const string SLEG_BIND_ROW_CHAR   = "sleg_row_char";
const string SLEG_BIND_ROW_STATUS = "sleg_row_status";
const string SLEG_BIND_ROW_ENC    = "sleg_row_enc";
const string SLEG_BIND_ROW_COLOR  = "sleg_row_color";

// ---------------------------------------------------------------
// Bind IDs — detail panel
// ---------------------------------------------------------------

const string SLEG_BIND_DET_NAME    = "sleg_det_name";
const string SLEG_BIND_DET_CHAR    = "sleg_det_char";
const string SLEG_BIND_DET_BLESS   = "sleg_det_bless";
const string SLEG_BIND_DET_BURDEN  = "sleg_det_burden";
const string SLEG_BIND_DET_FLAVOR  = "sleg_det_flavor";
const string SLEG_BIND_CLAIM_ENA   = "sleg_claim_ena";
const string SLEG_BIND_CLAIM_LBL   = "sleg_claim_lbl";
const string SLEG_BIND_ACTIVE_VIS  = "sleg_active_vis";
const string SLEG_BIND_ACTIVE_LBL  = "sleg_active_lbl";

// ---------------------------------------------------------------
// Buttons
// ---------------------------------------------------------------

const string SLEG_BTN_ROW          = "sleg_btn_row";
const string SLEG_BTN_CLAIM        = "sleg_btn_claim";

// ---------------------------------------------------------------
// LVARs stored on PC object
// ---------------------------------------------------------------

const string SLEG_LVAR_SEL_ID      = "SLEG_SEL_ID";
const string SLEG_LVAR_KILLS       = "SLEG_KILLS";
const string SLEG_LVAR_AREAS       = "SLEG_AREAS";
const string SLEG_LVAR_DEATHS      = "SLEG_DEATHS";
const string SLEG_LVAR_CURSED      = "SLEG_CURSED";     // 1 if PC died under a curse

// ---------------------------------------------------------------
// Legacy type constants
// ---------------------------------------------------------------

const int SLEG_TYPE_NONE           = -1;
const int SLEG_TYPE_WARRIOR        =  0;   // many kills, melee
const int SLEG_TYPE_MAGE           =  1;   // spellcaster levels
const int SLEG_TYPE_ROGUE          =  2;   // rogue class
const int SLEG_TYPE_MARTYR         =  3;   // died multiple times
const int SLEG_TYPE_WANDERER       =  4;   // visited many areas
const int SLEG_TYPE_DEVOUT         =  5;   // divine class levels
const int SLEG_TYPE_CURSED         =  6;   // died while cursed

// ---------------------------------------------------------------
// Effect tag — used to remove and reapply legacy effects
// ---------------------------------------------------------------

const string SLEG_EFFECT_TAG       = "SLEG_EFFECT";

// ---------------------------------------------------------------
// Window geometry
// ---------------------------------------------------------------

const float SLEG_W                 = 680.0;
const float SLEG_H                 = 480.0;
const float SLEG_LIST_W            = 220.0;
