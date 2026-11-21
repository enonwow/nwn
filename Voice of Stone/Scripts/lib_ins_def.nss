#include "lib_nui"
#include "sql_ins"

// Forward declarations
void FeedInsList(object oPC, int nToken);
void FeedInsDetail(object oPC, int nToken, int nId);
void InsOpenWindow(object oPC, object oTablet);
void SwapToReadView(object oPC, int nToken);
void SwapToWriteView(object oPC, int nToken);
void InsApplyBloodBonus(object oPC);

// ----------------------------------------------------------------
// Window / bind constants
// ----------------------------------------------------------------

const string INS_WINDOW        = "INS_WINDOW";
const string INS_EV_SCRIPT     = "lib_ins_ev";
const string INS_GRP_SWAP      = "INS_GRP_SWAP";
const string INS_WIN_GEOM      = "ins_win_geom";

// Top bar buttons
const string INS_BTN_TAB_READ  = "ins_tab_read";
const string INS_BTN_TAB_WRITE = "ins_tab_write";
const string INS_BTN_CLOSE     = "ins_btn_close";

// List array binds (one value per visible row)
const string INS_BIND_LST_TYPE = "ins_lst_type";   // type name string
const string INS_BIND_LST_TCOL = "ins_lst_tcol";   // NuiColor per type
const string INS_BIND_LST_AUTH = "ins_lst_auth";
const string INS_BIND_LST_PREV = "ins_lst_prev";   // truncated preview
const string INS_BIND_LST_AGE  = "ins_lst_age";
const string INS_BIND_LST_ENC  = "ins_lst_enc";    // encouraged = selected
const string INS_BIND_LST_CNT  = "ins_lst_cnt";    // row count integer bind
const string INS_BTN_ROW       = "ins_btn_row";

// Pagination
const string INS_BTN_PREV_PAGE = "ins_btn_prev";
const string INS_BTN_NEXT_PAGE = "ins_btn_next";
const string INS_BIND_PAGE_LBL = "ins_page_lbl";
const string INS_BIND_PREV_ENA = "ins_prev_ena";
const string INS_BIND_NEXT_ENA = "ins_next_ena";

// Detail panel
const string INS_BIND_DET_HDR  = "ins_det_hdr";    // "TYPE | Author [Krwawa]"
const string INS_BIND_DET_TEXT = "ins_det_text";
const string INS_BIND_DET_RATE = "ins_det_rate";   // formatted blessing count
const string INS_BIND_BLESS_ENA= "ins_bless_ena";
const string INS_BTN_BLESS     = "ins_btn_bless";
const string INS_BTN_BACK_LIST = "ins_btn_back";

// Write panel
const string INS_BTN_TYPE_PFX  = "ins_type_";      // + "0".."4"
const string INS_BIND_TYPE_ENC = "ins_type_enc";   // + "0".."4" (bool, radio emulation)
const string INS_BIND_WRITE_TXT= "ins_write_txt";
const string INS_BIND_BLOOD_CHK= "ins_blood_chk";
const string INS_BIND_CHARS_LBL= "ins_chars_lbl";
const string INS_BIND_WRITE_ENA= "ins_write_ena";
const string INS_BTN_INSCRIBE  = "ins_btn_inscribe";

// LVARs on PC
const string INS_LVAR_TABLET   = "INS_TABLET_TAG";
const string INS_LVAR_PAGE     = "INS_PAGE";
const string INS_LVAR_SEL_ID   = "INS_SEL_ID";
const string INS_LVAR_SEL_TYPE = "INS_SEL_TYPE";   // currently selected write type
const string INS_LVAR_LIST_JSON= "INS_LIST_JSON";  // cached page rows for row-click lookup

// Layout dimensions (pre-scale)
const float  INS_W             = 700.0;
const float  INS_H             = 540.0;
const int    INS_PAGE_SIZE     = 8;
const int    INS_TEXT_MAX      = 200;
const int    INS_BLOOD_HP_PCT  = 10;   // % of current HP consumed by blood inscription

// Inscription types
const int INS_TYPE_WARNING     = 0;
const int INS_TYPE_DISCOVERY   = 1;
const int INS_TYPE_GUIDANCE    = 2;
const int INS_TYPE_MOCKERY     = 3;
const int INS_TYPE_TRIBUTE     = 4;
const int INS_TYPE_COUNT       = 5;

// Blood bonus caps
const int   INS_BLOOD_BONUS_MAX= 3;      // max stacks of Lore bonus
const float INS_BLOOD_BONUS_DUR= 3600.0; // 1 hour per stack

// ----------------------------------------------------------------
// Type helpers
// ----------------------------------------------------------------

string InsTypeName(int nType)
{
    switch(nType)
    {
        case INS_TYPE_WARNING:   return "OSTRZEZENIE";
        case INS_TYPE_DISCOVERY: return "ODKRYCIE";
        case INS_TYPE_GUIDANCE:  return "PORADA";
        case INS_TYPE_MOCKERY:   return "SZPILA";
        case INS_TYPE_TRIBUTE:   return "HOLD";
    }
    return "?";
}

json InsTypeColor(int nType)
{
    switch(nType)
    {
        case INS_TYPE_WARNING:   return NuiColor(220, 60,  60);
        case INS_TYPE_DISCOVERY: return NuiColor(220, 180, 50);
        case INS_TYPE_GUIDANCE:  return NuiColor(80,  160, 220);
        case INS_TYPE_MOCKERY:   return NuiColor(100, 210, 100);
        case INS_TYPE_TRIBUTE:   return NuiColor(200, 130, 220);
    }
    return NuiColor(200, 200, 200);
}

// Returns at most nMax chars, appending ellipsis if truncated
string InsTruncate(string sText, int nMax)
{
    if(GetStringLength(sText) <= nMax) return sText;
    return GetStringLeft(sText, nMax - 1) + "~";
}

string InsFormatBlessings(int nCount)
{
    if(nCount == 0) return "Brak blogoslawien";
    if(nCount >= INS_BLESS_PERMANENT)
        return "Pieczen Wieczna (" + IntToString(nCount) + ")";
    string sStar = "";
    int i;
    for(i = 0; i < nCount && i < 5; i++) sStar = sStar + "*";
    return sStar + " (" + IntToString(nCount) + ")";
}
