#include "lib_nui"
#include "sql_cvoid"

void CvoidOpenWindow(object oPC);
void CvoidFeedList(object oPC, int nToken);
void CvoidFeedDetail(object oPC, int nToken, int nSel);
void CvoidFeedTaint(object oPC, int nToken);
void CvoidApplyTaintEffects(object oPC, int nTaint);
void CvoidPerform(object oPC, int nToken, int nSel);

// ----------------------------------------------------------------
// Window / UI IDs
// ----------------------------------------------------------------

const string CVOID_WINDOW           = "CVOID_WINDOW";
const string CVOID_EV_SCRIPT        = "lib_cvoid_ev";

// Buttons
const string CVOID_BTN_ROW          = "cvoid_btn_row";
const string CVOID_BTN_PERFORM      = "cvoid_btn_perform";
const string CVOID_BTN_PURIFY       = "cvoid_btn_purify";

// Taint header binds
const string CVOID_BIND_TAINT_PROG  = "cvoid_taint_prog";
const string CVOID_BIND_TAINT_LBL   = "cvoid_taint_lbl";
const string CVOID_BIND_CORR_LBL    = "cvoid_corr_lbl";
const string CVOID_BIND_CORR_COLOR  = "cvoid_corr_color";

// List binds (all arrays of CVOID_COUNT elements)
const string CVOID_BIND_ROW_NAME    = "cvoid_row_name";
const string CVOID_BIND_ROW_COST    = "cvoid_row_cost";
const string CVOID_BIND_ROW_CD      = "cvoid_row_cd";
const string CVOID_BIND_ROW_TAINT   = "cvoid_row_taint";
const string CVOID_BIND_ROW_ENC     = "cvoid_row_enc";
const string CVOID_BIND_ROW_COLOR   = "cvoid_row_color";
const string CVOID_BIND_ROW_COUNT   = "cvoid_row_count";

// Detail panel binds
const string CVOID_BIND_DESC_LBL    = "cvoid_desc";
const string CVOID_BIND_DETAIL_COST = "cvoid_dcost";
const string CVOID_BIND_DETAIL_CD   = "cvoid_dcd";
const string CVOID_BIND_PERFORM_ENA = "cvoid_perf_ena";
const string CVOID_BIND_PERFORM_LBL = "cvoid_perf_lbl";
const string CVOID_BIND_PURIFY_LBL  = "cvoid_pur_lbl";
const string CVOID_BIND_PURIFY_ENA  = "cvoid_pur_ena";

// LVARs on PC
const string CVOID_LVAR_SEL         = "CVOID_SEL";

// Counts / limits
const int    CVOID_COUNT            = 8;
const int    CVOID_TAINT_MAX        = 100;
const int    CVOID_TAINT_MINOR      = 25;
const int    CVOID_TAINT_MODERATE   = 50;
const int    CVOID_TAINT_SEVERE     = 75;
const int    CVOID_TAINT_CONSUMED   = 100;

// Purification
const int    CVOID_PURIFY_COST      = 500;
const int    CVOID_PURIFY_REDUCE    = 25;
const int    CVOID_PURIFY_CD_SECS   = 86400;

// All permanent taint effects are tagged so they can be stripped cleanly
const string CVOID_EFFECT_TAG       = "CVOID_TAINT";

// Layout
const float  CVOID_WIN_W            = 530.0;
const float  CVOID_WIN_H            = 590.0;

// ----------------------------------------------------------------
// Canticle data accessors (switch-based; easier to extend)
// ----------------------------------------------------------------

string CvoidGetName(int nId)
{
    switch(nId)
    {
        case 0: return "Litania Krwi";
        case 1: return "Psalm Nocy";
        case 2: return "Wezwanie Cienia";
        case 3: return "Hymn Zatracenia";
        case 4: return "Modlitwa Głodu";
        case 5: return "Śpiew Grozy";
        case 6: return "Inwokacja Pustki";
        case 7: return "Ostatnia Litania";
    }
    return "";
}

string CvoidGetCostShort(int nId)
{
    switch(nId)
    {
        case 0: return "20% PZ";
        case 1: return "150 sz.";
        case 2: return "250 sz.";
        case 3: return "35% PZ";
        case 4: return "300 sz.";
        case 5: return "15% PZ + 200 sz.";
        case 6: return "500 sz.";
        case 7: return "50% PZ + 1000 sz.";
    }
    return "";
}

string CvoidGetDesc(int nId)
{
    switch(nId)
    {
        case 0: return "Oddajesz krew Pustce. Twoje ciosy stają się niemal nieodparte.\n+2 do trafienia, +3 do obrażeń przez 5 minut.";
        case 1: return "Mrok otula twoje ruchy niczym całun.\n+4 do Ukrywania i Cichego poruszania się przez 5 minut.";
        case 2: return "Zasłona nicości skrywa twoją postać.\nEfekt Sanktuarium przez 2 minuty (ST 14).";
        case 3: return "Pustka wypełnia twoje żyły czystym złem.\nEfekt PoŚpieszenia przez 3 minuty.";
        case 4: return "Chłoniesz esencję Pustki jako tarczę z nicestwem.\nPrzejściowe PZ (50% maks.) przez 10 minut.";
        case 5: return "Twój głos rozbrzmiewa grozą z zaświatu.\n+4 do trafienia, +2 do obrażeń, +2 do rzutów obronnych przez 5 minut.\n(Wymaga Zmazy >= 20)";
        case 6: return "Pustka tworzy powłokę odpierającą czary.\nOdporność na zaklecia 20 przez 5 minut.";
        case 7: return "Ostateczna Litania — wszystkie moce Pustki naraz.\nPołączone efekty kantylen 0–6 przez 3 minuty.\n(Wymaga Zmazy >= 60, koszt: 50% PZ + 1000 sz.)";
    }
    return "";
}

int CvoidGetCostHpPct(int nId)
{
    switch(nId) { case 0: return 20; case 3: return 35; case 5: return 15; case 7: return 50; }
    return 0;
}

int CvoidGetCostGold(int nId)
{
    switch(nId) { case 1: return 150; case 2: return 250; case 4: return 300; case 5: return 200; case 6: return 500; case 7: return 1000; }
    return 0;
}

int CvoidGetTaintGain(int nId)
{
    switch(nId) { case 0: return 5; case 1: return 4; case 2: return 6; case 3: return 8; case 4: return 6; case 5: return 10; case 6: return 10; case 7: return 20; }
    return 0;
}

int CvoidGetCooldownSecs(int nId)
{
    if(nId == 7) return 7200;
    if(nId == 5 || nId == 6) return 2700;
    if(nId == 3) return 2100;
    return 1800;
}

int CvoidGetMinTaint(int nId)
{
    if(nId == 7) return 60;
    if(nId == 5) return 20;
    return 0;
}

int CvoidGetDurationSecs(int nId)
{
    switch(nId) { case 2: return 120; case 3: return 180; case 4: return 600; case 7: return 180; }
    return 300;
}

// ----------------------------------------------------------------
// Taint display helpers
// ----------------------------------------------------------------

string CvoidGetCorruptionLabel(int nTaint)
{
    if(nTaint >= 100) return "POCHŁONIĘTY PRZEZ PUSTKĘ — Opętanie";
    if(nTaint >= 75)  return "Zmaza Ciężka — Mrok spowija twoją duszę";
    if(nTaint >= 50)  return "Zmaza Znaczna — Pustka się budzi";
    if(nTaint >= 25)  return "Zmaza Widoma — Pustka już cię widzi";
    return "Bez Zmazy — Czyste sumienie";
}

json CvoidGetCorruptionColor(int nTaint)
{
    if(nTaint >= 100) return NuiColor(220, 50,  50);
    if(nTaint >= 75)  return NuiColor(200, 80,  20);
    if(nTaint >= 50)  return NuiColor(180, 140, 30);
    if(nTaint >= 25)  return NuiColor(150, 150, 80);
    return NuiColor(100, 180, 100);
}
