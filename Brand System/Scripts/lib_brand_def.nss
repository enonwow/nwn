// lib_brand_def.nss -- Constants, type helpers, forward declarations for Brand System
#include "lib_nui"
#include "sql_brand"

// Forward declarations
void CreateBrandWindow(object oPC);
void FeedBrandLocations(object oPC, int nToken);
void FeedBrandDetail(object oPC, int nToken, int nLoc);
void BrandApplyEffects(object oPC);
void BrandRemoveAllEffects(object oPC);
void BrandApply(object oBrander, object oBranded, int nLoc, int nType, string sName, string sOrigin);
void BrandRemoveAtLocation(object oPC, int nLoc);

// ----------------------------------------------------------------
// Window / group identifiers
// ----------------------------------------------------------------

const string BRAND_WINDOW      = "BRAND_WINDOW";
const string BRAND_EV_SCRIPT   = "lib_brand_ev";
const string BRAND_GRP_DETAIL  = "BRAND_GRP_DETAIL";
const string BRAND_WIN_CONFIRM = "BRAND_WIN_CONFIRM";
const string BRAND_WIN_GEOM    = "brand_win_geom";

// ----------------------------------------------------------------
// Brand types
// ----------------------------------------------------------------

const int BRAND_TYPE_SLAVE    = 1;
const int BRAND_TYPE_CRIMINAL = 2;
const int BRAND_TYPE_HERETIC  = 3;
const int BRAND_TYPE_HUNTER   = 4;
const int BRAND_TYPE_INFERNAL = 5;
const int BRAND_TYPE_BLOOD    = 6;
const int BRAND_TYPE_EXILE    = 7;

// ----------------------------------------------------------------
// Body locations
// ----------------------------------------------------------------

const int BRAND_LOC_FOREHEAD    = 0;
const int BRAND_LOC_NECK        = 1;
const int BRAND_LOC_CHEST       = 2;
const int BRAND_LOC_LEFT_ARM    = 3;
const int BRAND_LOC_RIGHT_ARM   = 4;
const int BRAND_LOC_LEFT_HAND   = 5;
const int BRAND_LOC_RIGHT_HAND  = 6;
const int BRAND_LOC_COUNT       = 7;

// ----------------------------------------------------------------
// NUI bind names
// ----------------------------------------------------------------

const string BRAND_BIND_ROW_LOC_NAME  = "brand_row_locname";   // array [7]
const string BRAND_BIND_ROW_NAME      = "brand_row_name";       // array [7]
const string BRAND_BIND_ROW_COLOR     = "brand_row_color";      // array [7]
const string BRAND_BIND_ROW_ENC       = "brand_row_enc";        // array [7]
const string BRAND_BIND_ROW_STATUS    = "brand_row_status";     // array [7] "Ukryta"/"Aktywna"/""

const string BRAND_BIND_DET_NAME      = "brand_det_name";
const string BRAND_BIND_DET_TYPE      = "brand_det_type";
const string BRAND_BIND_DET_ORIGIN    = "brand_det_origin";
const string BRAND_BIND_DET_FX        = "brand_det_fx";
const string BRAND_BIND_DET_CSTATE    = "brand_det_cstate";
const string BRAND_BIND_DET_BRANDER   = "brand_det_brander";
const string BRAND_BIND_BTN_CONCEAL_L = "brand_btn_conceallbl";
const string BRAND_BIND_BTN_REM_ENA   = "brand_btn_remena";
const string BRAND_BIND_STATUS        = "brand_status";
const string BRAND_BIND_ROW_COUNT     = "brand_rowcount";

// ----------------------------------------------------------------
// Button identifiers
// ----------------------------------------------------------------

const string BRAND_BTN_CLOSE          = "brand_btn_close";
const string BRAND_BTN_ROW            = "brand_btn_row";
const string BRAND_BTN_CONCEAL        = "brand_btn_conceal";
const string BRAND_BTN_REMOVE         = "brand_btn_remove";
const string BRAND_BTN_CONFIRM_YES    = "brand_btn_confyes";
const string BRAND_BTN_CONFIRM_NO     = "brand_btn_confno";

// ----------------------------------------------------------------
// Local vars on PC
// ----------------------------------------------------------------

const string BRAND_LVAR_SEL_LOC   = "BRAND_SEL_LOC";     // -1 = none selected
const string BRAND_LVAR_PENDING   = "BRAND_PENDING_LOC";  // loc pending remove confirm
const string BRAND_LVAR_FX_SLAVE  = "BRAND_FX_SLAVE";
const string BRAND_LVAR_FX_CRIM   = "BRAND_FX_CRIMINAL";
const string BRAND_LVAR_FX_HERET  = "BRAND_FX_HERETIC";
const string BRAND_LVAR_FX_HUNT   = "BRAND_FX_HUNTED";
const string BRAND_LVAR_FX_INF    = "BRAND_FX_INFERNAL";
const string BRAND_LVAR_FX_BLOOD  = "BRAND_FX_BLOOD";
const string BRAND_LVAR_FX_EXILE  = "BRAND_FX_EXILE";

const string BRAND_EFFECT_TAG     = "BRAND_FX";

// ----------------------------------------------------------------
// Layout constants
// ----------------------------------------------------------------

const float BRAND_W        = 600.0;
const float BRAND_H        = 540.0;
const int   BRAND_REMOVE_DC       = 20;
const int   BRAND_REMOVE_GOLD     = 1000;
const int   BRAND_REMOVE_FAIL_DMG = 15;

// ----------------------------------------------------------------
// Type / location name helpers
// ----------------------------------------------------------------

string BrandTypeName(int nType)
{
    switch(nType)
    {
        case BRAND_TYPE_SLAVE:    return "Znamie Panszczyzny";
        case BRAND_TYPE_CRIMINAL: return "Pietno Wyrzutka";
        case BRAND_TYPE_HERETIC:  return "Pietno Heretyka";
        case BRAND_TYPE_HUNTER:   return "Znacznik Lowcy";
        case BRAND_TYPE_INFERNAL: return "Pieczen Infernalna";
        case BRAND_TYPE_BLOOD:    return "Pieczen Krwi";
        case BRAND_TYPE_EXILE:    return "Stygmat Wygnanca";
    }
    return "Nieznane Pietno";
}

string BrandLocationName(int nLoc)
{
    switch(nLoc)
    {
        case BRAND_LOC_FOREHEAD:   return "Czolo";
        case BRAND_LOC_NECK:       return "Szyja";
        case BRAND_LOC_CHEST:      return "Piers";
        case BRAND_LOC_LEFT_ARM:   return "Lewe ramie";
        case BRAND_LOC_RIGHT_ARM:  return "Prawe ramie";
        case BRAND_LOC_LEFT_HAND:  return "Lewa dlon";
        case BRAND_LOC_RIGHT_HAND: return "Prawa dlon";
    }
    return "Nieznane";
}

string BrandEffectDesc(int nType)
{
    switch(nType)
    {
        case BRAND_TYPE_SLAVE:
            return "Karze blizna dumy. Sila -2, Charyzma -4.\nInni wiedza, czym jestes.";
        case BRAND_TYPE_CRIMINAL:
            return "Strazni reaguja wrogoscia. Perswazja -4, Blef -2.\nKupcy podniesli ceny o 20%.";
        case BRAND_TYPE_HERETIC:
            return "Bogowie odwrocili sie od ciebie. Madrosc -2.\nKaplani nie udzielaja poslugi.";
        case BRAND_TYPE_HUNTER:
            return "Jestes znaczony jako cel. Strzezenie +2, Sluch +2.\nOdczuwasz bliskosc zagrozenia.";
        case BRAND_TYPE_INFERNAL:
            return "Pakt jest zawarty. Odpornosc na ogien 5.\nMadrosc -2. Pieczen plonie w miejscach swietych.";
        case BRAND_TYPE_BLOOD:
            return "Krew paktuje z krwia. Kondycja +2.\nOkres kryzysu budzi w tobie sile pradawna.";
        case BRAND_TYPE_EXILE:
            return "Wygnany przez prawa i bogow. Skradanie +2, Ukrywanie +2.\nCharyzma -2. Zaden dom nie jest bezpieczny.";
    }
    return "Efekty nieznane.";
}

string BrandOriginDefault(int nType)
{
    switch(nType)
    {
        case BRAND_TYPE_SLAVE:    return "Wypalono rozarzonym zelazem przez handlarza.";
        case BRAND_TYPE_CRIMINAL: return "Napietnowany przez wyrok sadowy.";
        case BRAND_TYPE_HERETIC:  return "Kapitulek inkwizycji wydal wyrok.";
        case BRAND_TYPE_HUNTER:   return "Najemnik wystawil kontrakt. Jestes celem.";
        case BRAND_TYPE_INFERNAL: return "Pakt podpisany krwia w obecnosci demonow.";
        case BRAND_TYPE_BLOOD:    return "Ceremonia przymierza krwi z braterstwem.";
        case BRAND_TYPE_EXILE:    return "Wygnany przez rade starszych z ziem ojczystych.";
    }
    return "Pochodzenie nieznane.";
}
