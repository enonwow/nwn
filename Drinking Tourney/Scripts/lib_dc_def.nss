#include "lib_nui"
#include "sql_dc"

// ----------------------------------------------------------------
// Drinking Tournament
// ----------------------------------------------------------------
// Tavern drinking-contest tournament with single-elimination brackets
// of 4, 8 or 16 contestants. Anyone may create a tournament; players
// join until full, then matches resolve automatically through
// Constitution saves with rising DC. Prize pool = sum of entry fees,
// taken to the champion.
//
// Hooks:
//   OnModuleLoad  -> sys_on_load   (init schema)
//   OnClientEnter -> sys_on_enter  (notify if pending tournament)
//
// Open the panel from a placeable's OnUsed:
//   #include "lib_dc"
//   void main() { CreateDcWindow(GetLastUsedBy()); }
// ----------------------------------------------------------------

const string DC_WINDOW         = "DC_WINDOW";
const string DC_WIN_CREATE     = "DC_WIN_CREATE";
const string DC_EV_SCRIPT      = "lib_dc_ev";

// View tabs
const int DC_VIEW_ACTIVE       = 0;
const int DC_VIEW_OPEN         = 1;
const int DC_VIEW_HISTORY      = 2;

// Tournament status
const int DC_STATUS_OPEN       = 0;   // accepting entries
const int DC_STATUS_RUNNING    = 1;   // matches in progress
const int DC_STATUS_FINISHED   = 2;
const int DC_STATUS_CANCELED   = 3;

// Match status
const int DC_MATCH_PENDING     = 0;   // both sides not ready
const int DC_MATCH_DONE        = 1;   // resolved

// Tunables
const int DC_MAX_NAUSEA        = 3;       // pass out at this many failed saves
const int DC_MAX_SHOTS         = 12;      // safety cap per match
const int DC_BASE_DC           = 10;      // shot 1 DC
const int DC_HISTORY_LIMIT     = 10;
const int DC_MIN_FEE           = 0;
const int DC_MAX_FEE           = 5000;

// LVARs on PC
const string DC_LVAR_VIEW           = "DC_VIEW";
const string DC_LVAR_CREATE_SIZE    = "DC_CREATE_SIZE";
const string DC_LVAR_CREATE_FEE     = "DC_CREATE_FEE";

// Bind names
const string DC_BIND_TITLE          = "dc_title";
const string DC_BIND_HEADER         = "dc_header";
const string DC_BIND_TAB_ACTIVE_ENC  = "dc_tab_act_enc";
const string DC_BIND_TAB_OPEN_ENC    = "dc_tab_opn_enc";
const string DC_BIND_TAB_HISTORY_ENC = "dc_tab_his_enc";
const string DC_BIND_ROW_PRIM       = "dc_row_prim";
const string DC_BIND_ROW_SEC        = "dc_row_sec";
const string DC_BIND_ROW_RIGHT      = "dc_row_right";
const string DC_BIND_ROW_COLOR      = "dc_row_color";
const string DC_BIND_EMPTY_VIS      = "dc_empty_vis";
const string DC_BIND_EMPTY_TXT      = "dc_empty_txt";
const string DC_BIND_BTN_LBL        = "dc_btn_lbl";   // primary action label
const string DC_BIND_BTN_ENA        = "dc_btn_ena";

// Create-tournament popup
const string DC_BIND_CREATE_SIZE_LBL = "dc_cr_size_lbl";
const string DC_BIND_CREATE_FEE_TXT  = "dc_cr_fee_txt";
const string DC_BIND_CREATE_SIZE_4   = "dc_cr_size_4";
const string DC_BIND_CREATE_SIZE_8   = "dc_cr_size_8";
const string DC_BIND_CREATE_SIZE_16  = "dc_cr_size_16";

// Button IDs
const string DC_BTN_CLOSE          = "dc_btn_close";
const string DC_BTN_TAB_ACTIVE     = "dc_btn_tab_act";
const string DC_BTN_TAB_OPEN       = "dc_btn_tab_opn";
const string DC_BTN_TAB_HISTORY    = "dc_btn_tab_his";
const string DC_BTN_PRIMARY        = "dc_btn_primary";
const string DC_BTN_ROW            = "dc_btn_row";
const string DC_BTN_CREATE_SIZE_4  = "dc_btn_cr_4";
const string DC_BTN_CREATE_SIZE_8  = "dc_btn_cr_8";
const string DC_BTN_CREATE_SIZE_16 = "dc_btn_cr_16";
const string DC_BTN_CREATE_OK      = "dc_btn_cr_ok";
const string DC_BTN_CREATE_CANCEL  = "dc_btn_cr_cancel";

// Layout
const float DC_W = 640.0;
const float DC_H = 540.0;
const float DC_CR_W = 400.0;
const float DC_CR_H = 280.0;

object DcGetPCByUUID(string sUuid)
{
    if(sUuid == "") return OBJECT_INVALID;
    object oPC = GetFirstPC();
    while(GetIsObjectValid(oPC))
    {
        if(GetObjectUUID(oPC) == sUuid) return oPC;
        oPC = GetNextPC();
    }
    return OBJECT_INVALID;
}

string DcStatusToString(int n)
{
    switch(n)
    {
        case DC_STATUS_OPEN:     return "Open";
        case DC_STATUS_RUNNING:  return "Running";
        case DC_STATUS_FINISHED: return "Finished";
        case DC_STATUS_CANCELED: return "Canceled";
    }
    return "?";
}

int DcRoundsForSize(int nSize)
{
    // 4 -> 2 rounds, 8 -> 3 rounds, 16 -> 4 rounds
    if(nSize == 4)  return 2;
    if(nSize == 8)  return 3;
    if(nSize == 16) return 4;
    return 0;
}
