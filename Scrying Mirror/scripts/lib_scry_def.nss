#include "lib_nui"
#include "sql_scry"

void ScryCreateWindow(object oPC);
void ScryFeedMirrorList(object oPC, int nToken);
void ScryFeedDetail(object oPC, int nToken, int nMirrorId);
void ScryFeedAttunePopup(object oPC);
void ScryCreateAttunePopup(object oPC);
void ScryHandleSaveAttunement(object oPC);
json ScryGetPCsInArea(string sAreaTag);
void ScryPerformGaze(object oPC, int nToken, int nMirrorId);
int  ScryCanAttune(object oPC);
int  ScryCanDeactivate(object oPC, json jMirror);

// Window IDs
const string SCRY_WINDOW         = "SCRY_WINDOW";
const string SCRY_EV_SCRIPT      = "lib_scry_ev";
const string SCRY_WIN_ATTUNE     = "SCRY_WIN_ATTUNE";
const string SCRY_WIN_GEOM       = "scry_win_geom";

// Mirror list binds (array binds, one value per row)
const string SCRY_BIND_ROW_NAME  = "scry_row_name";
const string SCRY_BIND_ROW_AREA  = "scry_row_area";
const string SCRY_BIND_ROW_ENC   = "scry_row_enc";
const string SCRY_BIND_ROW_COUNT = "scry_rowcount";

// Detail panel binds
const string SCRY_BIND_DET_NAME  = "scry_det_name";
const string SCRY_BIND_DET_AREA  = "scry_det_area";
const string SCRY_BIND_DET_NOTE  = "scry_det_note";
const string SCRY_BIND_DET_PRES  = "scry_det_pres";
const string SCRY_BIND_DET_GAZE  = "scry_det_gaze_ena";
const string SCRY_BIND_DET_DEACT = "scry_det_deact_ena";
const string SCRY_BIND_DET_ATT   = "scry_det_att_ena";

// Attune popup binds
const string SCRY_BIND_ATT_NAME  = "scry_att_name";
const string SCRY_BIND_ATT_NOTE  = "scry_att_note";
const string SCRY_BIND_ATT_AREA  = "scry_att_area";
const string SCRY_BIND_ATT_SAVE  = "scry_att_save_ena";

// Button IDs
const string SCRY_BTN_CLOSE      = "scry_btn_close";
const string SCRY_BTN_ROW        = "scry_btn_row";
const string SCRY_BTN_GAZE       = "scry_btn_gaze";
const string SCRY_BTN_ATTUNE     = "scry_btn_attune";
const string SCRY_BTN_DEACT      = "scry_btn_deact";
const string SCRY_BTN_REFRESH    = "scry_btn_refresh";
const string SCRY_BTN_ATT_SAVE   = "scry_btn_att_save";
const string SCRY_BTN_ATT_CANCEL = "scry_btn_att_cancel";

// LVARs stored on the PC object during session
const string SCRY_LVAR_SEL_ID    = "SCRY_SEL_ID";
const string SCRY_LVAR_MIRRORS   = "SCRY_MIRRORS_CACHE";

// Item tags — create these blueprints in the HAK/toolset
const string SCRY_ITEM_TEAR      = "scry_tear";      // Lza Jasnowidza — consumed per gaze
const string SCRY_ITEM_CRYSTAL   = "scry_crystal";   // Kamien Krysztalowy — consumed per attunement (non-DMs)

// Text limits
const int    SCRY_NAME_MAX       = 60;
const int    SCRY_NOTE_MAX       = 200;
const int    SCRY_MAX_MIRRORS    = 20;

// Window base dimensions (scaled per player GUI setting)
const float  SCRY_W              = 720.0;
const float  SCRY_H              = 480.0;
const float  SCRY_LIST_W         = 245.0;
