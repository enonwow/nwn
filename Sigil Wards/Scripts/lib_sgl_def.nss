#include "lib_nui"
#include "sql_sgl"

// ----------------------------------------------------------------
// Sigil type IDs
// ----------------------------------------------------------------

const int SGL_TYPE_ALARM = 0;  // powiadamia właściciela, brak obrażeń
const int SGL_TYPE_SHOCK = 1;  // błyskawica, 1k8 obrażeń od elektryczności
const int SGL_TYPE_HOLD  = 2;  // paraliż na 6 sekund
const int SGL_TYPE_FEAR  = 3;  // przerażenie na 8 sekund

const int SGL_TYPE_COUNT = 4;

// ----------------------------------------------------------------
// Limits and tuning
// ----------------------------------------------------------------

const int   SGL_MAX_SIGILS        = 5;     // max active sigils per player
const float SGL_TRIGGER_RADIUS    = 4.5;   // metres — trigger if closer than this
const int   SGL_HB_MODULO         = 3;     // check proximity every N heartbeats (~18 s)
const int   SGL_COOLDOWN_SECONDS  = 30;    // seconds before same creature can retrigger same sigil
const int   SGL_MAX_ATTUNED       = 10;    // max attuned players per sigil

// ----------------------------------------------------------------
// Window / group IDs
// ----------------------------------------------------------------

const string SGL_WINDOW     = "SGL_WINDOW";
const string SGL_EV_SCRIPT  = "lib_sgl_ev";
const string SGL_WIN_GEOM   = "sgl_win_geom";
const string SGL_GRP_SWAP   = "SGL_GRP_SWAP";

// ----------------------------------------------------------------
// Bind names — list view
// ----------------------------------------------------------------

const string SGL_BIND_ROW_TYPE    = "sgl_row_type";
const string SGL_BIND_ROW_AREA    = "sgl_row_area";
const string SGL_BIND_ROW_CHARGES = "sgl_row_charges";
const string SGL_BIND_ROW_ENC     = "sgl_row_enc";
const string SGL_BIND_ROW_COLOR   = "sgl_row_color";
const string SGL_BIND_LIST_COUNT  = "sgl_list_count";
const string SGL_BIND_HEADER      = "sgl_header";
const string SGL_BIND_DISARM_ENA  = "sgl_disarm_ena";
const string SGL_BIND_ATT_ENA     = "sgl_att_ena";

// ----------------------------------------------------------------
// Bind names — place view
// ----------------------------------------------------------------

const string SGL_BIND_PLACE_TYPE_LBL  = "sgl_place_type";
const string SGL_BIND_PLACE_TYPE_DESC = "sgl_place_desc";
const string SGL_BIND_PLACE_CHARGES   = "sgl_place_chg";

// ----------------------------------------------------------------
// Bind names — attune view
// ----------------------------------------------------------------

const string SGL_BIND_ATT_HEADER  = "sgl_att_header";
const string SGL_BIND_ATT_NAME    = "sgl_att_name";
const string SGL_BIND_ATT_ENC     = "sgl_att_enc";
const string SGL_BIND_ATT_COUNT   = "sgl_att_count";
const string SGL_BIND_REVOKE_ENA  = "sgl_revoke_ena";
const string SGL_BIND_SEARCH_TXT  = "sgl_search_txt";
const string SGL_BIND_ONLINE_NAME = "sgl_online_name";
const string SGL_BIND_ONLINE_ENC  = "sgl_online_enc";
const string SGL_BIND_ONLINE_CNT  = "sgl_online_count";

// ----------------------------------------------------------------
// Button IDs
// ----------------------------------------------------------------

const string SGL_BTN_CLOSE       = "sgl_btn_close";
const string SGL_BTN_PLACE_OPEN  = "sgl_btn_place_open";
const string SGL_BTN_DISARM      = "sgl_btn_disarm";
const string SGL_BTN_ATT_OPEN    = "sgl_btn_att_open";
const string SGL_BTN_ROW         = "sgl_btn_row";
const string SGL_BTN_TYPE_PREV   = "sgl_btn_type_prev";
const string SGL_BTN_TYPE_NEXT   = "sgl_btn_type_next";
const string SGL_BTN_PLACE_CONF  = "sgl_btn_place_conf";
const string SGL_BTN_BACK        = "sgl_btn_back";
const string SGL_BTN_ATT_ROW     = "sgl_btn_att_row";
const string SGL_BTN_ONLINE_ROW  = "sgl_btn_online_row";
const string SGL_BTN_REVOKE      = "sgl_btn_revoke";
const string SGL_BTN_SEARCH      = "sgl_btn_search";

// ----------------------------------------------------------------
// LVARs on PC
// ----------------------------------------------------------------

const string SGL_LVAR_SEL_ID     = "SGL_SEL_ID";       // selected sigil id in list view
const string SGL_LVAR_TYPE_IDX   = "SGL_TYPE_IDX";     // current type in place view
const string SGL_LVAR_SEL_ATT    = "SGL_SEL_ATT";      // selected attuned uuid in attune view
const string SGL_LVAR_SEARCH_RES = "SGL_SEARCH_RES";   // json array of search results

// ----------------------------------------------------------------
// Layout dimensions (pre-scale)
// ----------------------------------------------------------------

const float SGL_W = 660.0;
const float SGL_H = 460.0;

// ----------------------------------------------------------------
// Forward declarations for cross-referencing
// ----------------------------------------------------------------

void FeedSglList(object oPC, int nToken);
void FeedSglPlace(object oPC, int nToken);
void FeedSglAttune(object oPC, int nToken);
string SglGetTypeName(int nType);
