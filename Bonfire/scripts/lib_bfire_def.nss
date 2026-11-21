#include "lib_nui"
#include "sql_bfire"

// Forward declarations
void BfireOpenWindow(object oPC, object oBonfire);
void BfireSwapToMain(object oPC, int nToken);
void BfireSwapToTravel(object oPC, int nToken);
void BfireSwapToMessages(object oPC, int nToken);
void BfireFeedMain(object oPC, int nToken);
void BfireFeedTravel(object oPC, int nToken);
void BfireFeedMessages(object oPC, int nToken);
void BfireDoRest(object oPC, int nToken);
void BfireDoKindle(object oPC, int nToken);
void BfireDoUseFlask(object oPC, int nToken);

// ----------------------------------------------------------------
// Window / view identifiers
// ----------------------------------------------------------------

const string BFIRE_WINDOW     = "BFIRE_WINDOW";
const string BFIRE_EV_SCRIPT  = "lib_bfire_ev";
const string BFIRE_GRP_SWAP   = "BFIRE_GRP_SWAP";
const string BFIRE_WIN_GEOM   = "bfire_win_geom";

// ----------------------------------------------------------------
// Binds — main view
// ----------------------------------------------------------------

const string BFIRE_BIND_NAME        = "bfire_name";
const string BFIRE_BIND_STATUS      = "bfire_status";
const string BFIRE_BIND_STATUS_CLR  = "bfire_status_clr";
const string BFIRE_BIND_REST_ENA    = "bfire_rest_ena";
const string BFIRE_BIND_REST_LBL    = "bfire_rest_lbl";
const string BFIRE_BIND_KINDLE_ENA  = "bfire_kindle_ena";
const string BFIRE_BIND_FLASK_LBL   = "bfire_flask_lbl";
const string BFIRE_BIND_FLASK_ENA   = "bfire_flask_ena";

// ----------------------------------------------------------------
// Binds — travel view
// ----------------------------------------------------------------

const string BFIRE_BIND_TRAV_NAME   = "bfire_trav_name";
const string BFIRE_BIND_TRAV_AREA   = "bfire_trav_area";
const string BFIRE_BIND_TRAV_ENC    = "bfire_trav_enc";
const string BFIRE_BIND_TRAV_CNT    = "bfire_trav_cnt";

// ----------------------------------------------------------------
// Binds — messages view
// ----------------------------------------------------------------

const string BFIRE_BIND_MSG_AUTHOR  = "bfire_msg_author";
const string BFIRE_BIND_MSG_TEXT    = "bfire_msg_text";
const string BFIRE_BIND_MSG_DATE    = "bfire_msg_date";
const string BFIRE_BIND_MSG_CNT     = "bfire_msg_cnt";
const string BFIRE_BIND_NEW_MSG     = "bfire_new_msg";
const string BFIRE_BIND_POST_ENA    = "bfire_post_ena";

// ----------------------------------------------------------------
// Button IDs
// ----------------------------------------------------------------

const string BFIRE_BTN_CLOSE        = "bfire_btn_close";
const string BFIRE_BTN_REST         = "bfire_btn_rest";
const string BFIRE_BTN_TRAVEL       = "bfire_btn_travel";
const string BFIRE_BTN_MESSAGES     = "bfire_btn_msgs";
const string BFIRE_BTN_KINDLE       = "bfire_btn_kindle";
const string BFIRE_BTN_FLASK        = "bfire_btn_flask";
const string BFIRE_BTN_BACK         = "bfire_btn_back";
const string BFIRE_BTN_TRAV_ROW     = "bfire_btn_trav_row";
const string BFIRE_BTN_POST         = "bfire_btn_post";

// ----------------------------------------------------------------
// Local vars on PC
// ----------------------------------------------------------------

const string BFIRE_LVAR_TAG         = "BFIRE_CUR_TAG";   // tag of bonfire PC is standing at
const string BFIRE_LVAR_TRAV_LIST   = "BFIRE_TRAV_LIST"; // cached JsonArray of lit bonfires

// Local var on bonfire placeable (set in toolset)
const string BFIRE_OVAR_START_LIT   = "BFIRE_START_LIT";   // int 1 = starts lit
const string BFIRE_OVAR_DISPLAY     = "BFIRE_DISPLAY_NAME"; // string display name override

// ----------------------------------------------------------------
// Tuning constants
// ----------------------------------------------------------------

const int    BFIRE_MAX_FLASKS       = 5;
const int    BFIRE_REST_COOLDOWN    = 600;  // 10 min between rests
const int    BFIRE_MAX_MSGS_SHOWN   = 10;
const int    BFIRE_MSG_MAX_LEN      = 120;
const string BFIRE_TINDER_TAG       = "bfire_tinder";

// ----------------------------------------------------------------
// Layout
// ----------------------------------------------------------------

const float  BFIRE_W                = 500.0;
const float  BFIRE_H                = 400.0;

// ----------------------------------------------------------------
// Helpers
// ----------------------------------------------------------------

// Extracts a readable name from a bonfire object.
// Prefers BFIRE_OVAR_DISPLAY local var, then the object's Name property.
string BfireGetDisplayName(object oBonfire)
{
    string sOverride = GetLocalString(oBonfire, BFIRE_OVAR_DISPLAY);
    if(sOverride != "") return sOverride;
    string sName = GetName(oBonfire);
    if(sName != "") return sName;
    return GetTag(oBonfire);
}

// Returns the tag stored on the PC for the currently open bonfire.
string BfireGetTag(object oPC)
{
    return GetLocalString(oPC, BFIRE_LVAR_TAG);
}
