#include "lib_nui"
#include "sql_obs"

void ObsOpenUI(object oPC);
void ObsFeedUI(object oPC, int nToken);
void ObsFeedDetails(object oPC, int nToken, int nIdx);
void ObsApplyBonuses(object oPC);
void ObsCheckCompulsions(object oPC);

// --- Window / event ---
const string OBS_WINDOW         = "OBS_WINDOW";
const string OBS_EV_SCRIPT      = "lib_obs_ev";

// --- NUI binds: list panel ---
const string OBS_BIND_LIST_COUNT = "obs_list_count";
const string OBS_BIND_ROW_NAME   = "obs_row_name";
const string OBS_BIND_ROW_TIER   = "obs_row_tier";
const string OBS_BIND_ROW_COLOR  = "obs_row_color";
const string OBS_BIND_ROW_ENC    = "obs_row_enc";

// --- NUI binds: detail panel ---
const string OBS_BIND_DET_HEADER     = "obs_det_header";
const string OBS_BIND_DET_TIER       = "obs_det_tier";
const string OBS_BIND_DET_PROGRESS   = "obs_det_progress";
const string OBS_BIND_DET_PTS_LBL    = "obs_det_pts_lbl";
const string OBS_BIND_DET_BONUS      = "obs_det_bonus";
const string OBS_BIND_DET_COMPULSION = "obs_det_compulsion";
const string OBS_BIND_DET_TIER_COLOR = "obs_det_tier_color";
const string OBS_BIND_DET_SUPP_LBL  = "obs_det_supp_lbl";
const string OBS_BIND_DET_SUPP_ENA  = "obs_det_supp_ena";

// --- NUI button IDs ---
const string OBS_BTN_ROW        = "obs_btn_row";
const string OBS_BTN_SUPPRESS   = "obs_btn_suppress";
const string OBS_BTN_CLOSE      = "obs_btn_close";

// --- Category constants (index 0–9) ---
const string OBS_CAT_UNDEAD     = "UNDEAD";
const string OBS_CAT_BLOOD      = "BLOOD";
const string OBS_CAT_THEFT      = "THEFT";
const string OBS_CAT_DRINK      = "DRINK";
const string OBS_CAT_ARCANE     = "ARCANE";
const string OBS_CAT_PAIN       = "PAIN";
const string OBS_CAT_SHADOW     = "SHADOW";
const string OBS_CAT_GOLD       = "GOLD";
const string OBS_CAT_BATTLE     = "BATTLE";
const string OBS_CAT_DARKNESS   = "DARKNESS";

// --- Tier thresholds ---
const int OBS_TIER_LATENT       = 0;    // 0–24
const int OBS_TIER_FIXATION     = 1;    // 25–49
const int OBS_TIER_COMPULSION   = 2;    // 50–74
const int OBS_TIER_OBSESSION    = 3;    // 75–99
const int OBS_TIER_MADNESS      = 4;    // 100+

// --- Limits & config ---
const int OBS_MAX_POINTS        = 125;
const int OBS_SUPPRESS_COST     = 500;
const int OBS_SUPPRESS_DURATION = 3600; // 1 real hour
const int OBS_HB_TICKS          = 10;   // 10 × 6s heartbeats ≈ 60s check interval
const int OBS_NUM_CATEGORIES    = 10;

// --- Window geometry ---
const float OBS_WIN_W           = 620.0;
const float OBS_WIN_H           = 480.0;
const float OBS_LIST_W          = 190.0;

// --- Local vars ---
const string OBS_LVAR_SEL_IDX   = "OBS_SEL_IDX";
const string OBS_LVAR_HB_TICK   = "OBS_HB_TICK";

// -----------------------------------------------------------------
// Inline helpers (called from multiple files)
// -----------------------------------------------------------------

string ObsGetCategoryAtIndex(int nIdx)
{
    switch(nIdx)
    {
        case 0: return OBS_CAT_UNDEAD;
        case 1: return OBS_CAT_BLOOD;
        case 2: return OBS_CAT_THEFT;
        case 3: return OBS_CAT_DRINK;
        case 4: return OBS_CAT_ARCANE;
        case 5: return OBS_CAT_PAIN;
        case 6: return OBS_CAT_SHADOW;
        case 7: return OBS_CAT_GOLD;
        case 8: return OBS_CAT_BATTLE;
        case 9: return OBS_CAT_DARKNESS;
    }
    return "";
}

int ObsGetTier(int nPoints)
{
    if(nPoints >= 100) return OBS_TIER_MADNESS;
    if(nPoints >= 75)  return OBS_TIER_OBSESSION;
    if(nPoints >= 50)  return OBS_TIER_COMPULSION;
    if(nPoints >= 25)  return OBS_TIER_FIXATION;
    return OBS_TIER_LATENT;
}

string ObsTierLabel(int nTier)
{
    switch(nTier)
    {
        case OBS_TIER_LATENT:     return "Nieuśpiona";
        case OBS_TIER_FIXATION:   return "Skłonność";
        case OBS_TIER_COMPULSION: return "Przymus";
        case OBS_TIER_OBSESSION:  return "Obsesja";
        case OBS_TIER_MADNESS:    return "Obłęd";
    }
    return "";
}

json ObsTierColor(int nTier)
{
    switch(nTier)
    {
        case OBS_TIER_LATENT:     return NuiColor(140, 140, 140);
        case OBS_TIER_FIXATION:   return NuiColor(220, 200, 100);
        case OBS_TIER_COMPULSION: return NuiColor(220, 150, 60);
        case OBS_TIER_OBSESSION:  return NuiColor(200, 70, 40);
        case OBS_TIER_MADNESS:    return NuiColor(160, 30, 180);
    }
    return NuiColor(255, 255, 255);
}

string ObsCategoryLabel(string sCategory)
{
    if(sCategory == OBS_CAT_UNDEAD)   return "Nieumarli";
    if(sCategory == OBS_CAT_BLOOD)    return "Krew";
    if(sCategory == OBS_CAT_THEFT)    return "Złodziejstwo";
    if(sCategory == OBS_CAT_DRINK)    return "Pijaństwo";
    if(sCategory == OBS_CAT_ARCANE)   return "Magia Arcana";
    if(sCategory == OBS_CAT_PAIN)     return "Ból";
    if(sCategory == OBS_CAT_SHADOW)   return "Cień";
    if(sCategory == OBS_CAT_GOLD)     return "Złoto";
    if(sCategory == OBS_CAT_BATTLE)   return "Bitwa";
    if(sCategory == OBS_CAT_DARKNESS) return "Mrok";
    return sCategory;
}

string ObsCategoryBonusDesc(string sCategory, int nTier)
{
    if(nTier <= 0) return "Brak efektu.";
    string s = IntToString(nTier);
    if(sCategory == OBS_CAT_UNDEAD)
        return "+" + s + " do ataków wręcz. Krew pamięta wrogie oblicze nieumarłych.";
    if(sCategory == OBS_CAT_BLOOD)
        return "+" + s + " do ataków gdy poniżej połowy PŻ. Rana jest paliwem.";
    if(sCategory == OBS_CAT_THEFT)
        return "+" + s + " do Otwierania Zamków i Kradzieży Kieszonkowej.";
    if(sCategory == OBS_CAT_DRINK)
        return "+" + s + " do rzutów na Strach, +" + IntToString(nTier*5) + " tymcz. PŻ.";
    if(sCategory == OBS_CAT_ARCANE)
        return "+" + s + " do Koncentracji. Zaklęcia płyną jak krew przez ranę.";
    if(sCategory == OBS_CAT_PAIN)
        return "+" + IntToString(nTier*2) + " odporności na każdy typ fizycznych obrażeń.";
    if(sCategory == OBS_CAT_SHADOW)
        return "+" + s + " do Ukrywania się i Cichego Poruszania. Cień zna twoją sylwetkę.";
    if(sCategory == OBS_CAT_GOLD)
        return "+" + IntToString(nTier*2) + " do Wyceny. Złoto śpiewa tylko dla wtajemniczonych.";
    if(sCategory == OBS_CAT_BATTLE)
        return "+" + s + " do Ataku. Wieczna gotowość bojowa nie zna odpoczynku.";
    if(sCategory == OBS_CAT_DARKNESS)
        return "Wzmocnione widzenie w nocy, +" + s + " do Woli vs oślepienie.";
    return "";
}

string ObsCategoryCompulsionDesc(string sCategory, int nTier)
{
    if(nTier <= 0) return "—";
    string sDC = IntToString(8 + nTier * 4);
    if(sCategory == OBS_CAT_UNDEAD)
        return "Na widok nieumarłego musisz rzucić Wolę DC " + sDC + " lub natychmiast zaatakować.";
    if(sCategory == OBS_CAT_BLOOD)
        return "Musisz rzucić Wolę DC " + sDC + " lub zadać sobie 1k4 obrażeń (głęboka rana).";
    if(sCategory == OBS_CAT_THEFT)
        return "Palce drżą — Wola DC " + sDC + " lub chwilowy szał kleptomański (+2 DEX, efekt RP).";
    if(sCategory == OBS_CAT_DRINK)
        return "Bez trunku: Wola DC " + sDC + " lub -1 do ataków przez 60 sekund.";
    if(sCategory == OBS_CAT_ARCANE)
        return "Wola DC " + sDC + " lub niekontrolowane wyładowanie magii (1k4 obrażeń od błyskawicy).";
    if(sCategory == OBS_CAT_PAIN)
        return "Wola DC " + sDC + " lub autoflagellacja (1k4 obrażeń, krzyk pokuty).";
    if(sCategory == OBS_CAT_SHADOW)
        return "Wola DC " + sDC + " lub natychmiastowe wejście w cień (20% ukrycia przez chwilę).";
    if(sCategory == OBS_CAT_GOLD)
        return "Wola DC " + sDC + " lub rozproszenie (liczysz monety, -2 Koncentracji przez 15 s).";
    if(sCategory == OBS_CAT_BATTLE)
        return "Wola DC " + sDC + " lub szał bojowy (+2 do ataków, musisz zaatakować coś w pobliżu).";
    if(sCategory == OBS_CAT_DARKNESS)
        return "Wola DC " + sDC + " lub musisz zgasić pobliskie źródło światła (ruch RP).";
    return "—";
}
