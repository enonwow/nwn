#include "lib_nui"
#include "sql_por"

void CreatePortraitWindow(object oPC);
void SwapToGalleryView(object oPC, int nToken);
void SwapToCommissionView(object oPC, int nToken);
void FeedGalleryList(object oPC, int nToken);
void FeedPortraitDetail(object oPC, int nToken, int nId);
void FeedDetailEmpty(object oPC, int nToken);
void FeedCommissionView(object oPC, int nToken);

// ----------------------------------------------------------------
// Window / group identifiers
// ----------------------------------------------------------------

const string POR_WINDOW            = "POR_WINDOW";
const string POR_EV_SCRIPT         = "lib_por_ev";
const string POR_GRP_SWAP          = "POR_GRP_SWAP";
const string POR_WIN_GEOM          = "por_win_geom";

// ----------------------------------------------------------------
// Gallery list (NuiList) binds — each is a JSON array, one value per row
// ----------------------------------------------------------------

const string POR_BIND_ROW_NAME     = "por_row_name";
const string POR_BIND_ROW_CLASS    = "por_row_class";
const string POR_BIND_ROW_LVL      = "por_row_lvl";
const string POR_BIND_ROW_SHADOW   = "por_row_shadow";
const string POR_BIND_ROW_COLOR    = "por_row_color";
const string POR_BIND_ROW_SHDCOL   = "por_row_shdcol";
const string POR_BIND_ROW_ENC      = "por_row_enc";
const string POR_BIND_ROWCOUNT     = "por_rowcount";

// ----------------------------------------------------------------
// Detail panel binds — scalar values for the selected portrait
// ----------------------------------------------------------------

const string POR_BIND_DET_TITLE    = "por_det_title";
const string POR_BIND_DET_SUB      = "por_det_sub";
const string POR_BIND_DET_ALIGN    = "por_det_align";
const string POR_BIND_DET_STATE    = "por_det_state";
const string POR_BIND_DET_SHADOW   = "por_det_shadow";
const string POR_BIND_DET_DATE     = "por_det_date";
const string POR_BIND_DET_MOTTO    = "por_det_motto";
const string POR_BIND_DET_TITLECOL = "por_det_titlecol";
const string POR_BIND_DET_SHDCOL   = "por_det_shdcol";

// ----------------------------------------------------------------
// Action button enable/disable binds
// ----------------------------------------------------------------

const string POR_BIND_VIEW_ENA     = "por_view_ena";
const string POR_BIND_REPAIR_ENA   = "por_repair_ena";
const string POR_BIND_COMM_ENA     = "por_comm_ena";
const string POR_BIND_MEM_ENA      = "por_mem_ena";     // DM only
const string POR_BIND_SHADOW_ENA   = "por_shadow_ena";  // DM only

// ----------------------------------------------------------------
// Commission view binds
// ----------------------------------------------------------------

const string POR_BIND_COM_MOTTO    = "por_com_motto";
const string POR_BIND_COM_COSTLBL  = "por_com_costlbl";

// ----------------------------------------------------------------
// Button IDs
// ----------------------------------------------------------------

const string POR_BTN_CLOSE         = "por_btn_close";
const string POR_BTN_ROW           = "por_btn_row";
const string POR_BTN_VIEW          = "por_btn_view";
const string POR_BTN_REPAIR        = "por_btn_repair";
const string POR_BTN_COMMISSION    = "por_btn_commission";
const string POR_BTN_MEMORIAL      = "por_btn_memorial";
const string POR_BTN_ADD_SHADOW    = "por_btn_addshadow";
const string POR_BTN_COM_CONFIRM   = "por_btn_comconf";
const string POR_BTN_COM_CANCEL    = "por_btn_comcanc";

// ----------------------------------------------------------------
// Local variables stored on the PC object
// ----------------------------------------------------------------

const string POR_LVAR_SEL_ID       = "POR_SEL_ID";
const string POR_LVAR_CURSE        = "POR_CURSE_ACTIVE";

// ----------------------------------------------------------------
// Effect tags for identifying and removing buffs / curses
// ----------------------------------------------------------------

const string POR_TAG_BUFF          = "POR_PORTRAIT_BUFF";
const string POR_TAG_CURSE         = "POR_PORTRAIT_CURSE";

// ----------------------------------------------------------------
// Gameplay constants
// ----------------------------------------------------------------

const int    POR_COMMISSION_COST   = 500;   // gold pieces to commission a portrait
const int    POR_REPAIR_COST       = 200;   // gold pieces to restore a damaged portrait
const int    POR_SHADOW_PER_VIEW   = 1;     // shadow gain when DM uses "Add Shadow" button

// Shadow-score thresholds that change portrait description and color.
const int    POR_SHADOW_TAINTED    = 21;
const int    POR_SHADOW_CORRUPTED  = 51;
const int    POR_SHADOW_DAMNED     = 81;

// Portrait state constants stored in the DB.
const int    POR_STATE_NORMAL      = 0;
const int    POR_STATE_DAMAGED     = 1;
const int    POR_STATE_MEMORIAL    = 2;

// Buff duration in seconds (real-time).
const float  POR_BUFF_DURATION     = 3600.0;

// ----------------------------------------------------------------
// Window geometry
// ----------------------------------------------------------------

const float  POR_W                 = 700.0;
const float  POR_H                 = 510.0;
