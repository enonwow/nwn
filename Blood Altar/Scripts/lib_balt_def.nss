// lib_balt_def.nss — Blood Altar: stale, ID bindow, ID przyciskow
#include "lib_nui"
#include "sql_balt"

// Forward declarations (implementacja w lib_balt.nss)
void BaltOpenWindow(object oPC, string sAltarTag);
void BaltFeedWindow(object oPC, int nToken, string sAltarTag);
void BaltShowBloodConfirm(object oPC, int nHPCost, string sAltarName);

// ---------------------------------------------------------------
// Identyfikatory okien NUI
// ---------------------------------------------------------------
const string BALT_WINDOW      = "BALT_WINDOW";
const string BALT_WIN_CONFIRM = "BALT_WIN_CONFIRM";
const string BALT_EV_SCRIPT   = "lib_balt_ev";

// ---------------------------------------------------------------
// Nazwy bindow (BALT_BIND_*)
// ---------------------------------------------------------------
const string BALT_BIND_TITLE      = "balt_title";
const string BALT_BIND_LORE       = "balt_lore";
const string BALT_BIND_CORRUPTION = "balt_corruption";  // float 0..1 dla NuiProgress
const string BALT_BIND_CORR_LBL   = "balt_corr_lbl";
const string BALT_BIND_CORR_COLOR  = "balt_corr_color";
const string BALT_BIND_SAC_NAME   = "balt_sac_name";
const string BALT_BIND_SAC_COST   = "balt_sac_cost";
const string BALT_BIND_SAC_EFF    = "balt_sac_eff";
const string BALT_BIND_SAC_ENA    = "balt_sac_ena";
const string BALT_BIND_SAC_COLOR  = "balt_sac_color";
const string BALT_BIND_ROWCOUNT   = "balt_rowcount";
const string BALT_BIND_WIN_GEOM   = "balt_win_geom";

// ---------------------------------------------------------------
// Identyfikatory przyciskow (BALT_BTN_*)
// ---------------------------------------------------------------
const string BALT_BTN_CLOSE     = "balt_btn_close";
const string BALT_BTN_SACRIFICE = "balt_btn_sac";   // w szablonie listy
const string BALT_BTN_CONFIRM   = "balt_btn_confirm";
const string BALT_BTN_CANCEL    = "balt_btn_cancel";

// ---------------------------------------------------------------
// Zmienne lokalne na PC (BALT_LVAR_*)
// ---------------------------------------------------------------
const string BALT_LVAR_ALTAR_TAG   = "BALT_ALTAR_TAG";
const string BALT_LVAR_PENDING_IDX = "BALT_PENDING_IDX";  // indeks ofiary czekajacy na potwierdzenie
const string BALT_LVAR_PENDING_HP  = "BALT_PENDING_HP";   // koszt HP czekajacy na potwierdzenie
const string BALT_LVAR_ITEM_IDX    = "BALT_ITEM_IDX";     // indeks ofiary przy celowaniu w przedmiot

// ---------------------------------------------------------------
// Tagi placeable'i oltarzy (ustawiane w toolsecie jako Tag)
// ---------------------------------------------------------------
const string BALT_TAG_BLOOD  = "ALTAR_BLOOD";
const string BALT_TAG_BONE   = "ALTAR_BONE";
const string BALT_TAG_EARTH  = "ALTAR_EARTH";
const string BALT_TAG_SHADOW = "ALTAR_SHADOW";

// ---------------------------------------------------------------
// Typy efektow boonow (uzywane w tablicy "eff" JSON ofiary)
// ---------------------------------------------------------------
const int BALT_EFF_ABILITY   = 0; // sub = ABILITY_*, val = ilosc
const int BALT_EFF_TEMP_HP   = 1; // val = ilosc PW tymczasowych
const int BALT_EFF_INVIS     = 2; // Ulepszona Niewidzialnosc (bez sub/val)
const int BALT_EFF_HASTE     = 3; // Przyspieszenie (bez sub/val)
const int BALT_EFF_REGEN     = 4; // val = HP/tick (co 6s)
const int BALT_EFF_SPELL_RES = 5; // val = wzrost Odpornosci na Czary
const int BALT_EFF_SAVES     = 6; // val = wzrost rzutow obronnych (wszystkie)

// ---------------------------------------------------------------
// Tagi efektow korupcji (TagEffect, pozwalaja na usuwanie)
// ---------------------------------------------------------------
const string BALT_VFX_TAG_LOW   = "BALT_VFX_LOW";
const string BALT_VFX_TAG_HIGH  = "BALT_VFX_HIGH";
const string BALT_VFX_TAG_RIVEN = "BALT_VFX_RIVEN";

// ---------------------------------------------------------------
// Progi korupcji
// ---------------------------------------------------------------
const int BALT_CORRUPT_LOW  = 33;
const int BALT_CORRUPT_HIGH = 66;
// BALT_CORRUPT_MAX = 100 zdefiniowany w sql_balt.nss

// ---------------------------------------------------------------
// Wymiary okna
// ---------------------------------------------------------------
const float BALT_W = 620.0;
const float BALT_H = 460.0;
