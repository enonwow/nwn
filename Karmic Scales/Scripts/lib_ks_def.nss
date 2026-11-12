#include "lib_nui"
#include "sql_ks"

// ----------------------------------------------------------------
// Window / event identifiers
// ----------------------------------------------------------------

const string KS_WINDOW         = "KS_WINDOW";
const string KS_EV_SCRIPT      = "lib_ks_ev";
const string KS_WIN_GEOM       = "ks_win_geom";

// Binds
const string KS_BIND_TIER_LBL      = "ks_tier_lbl";
const string KS_BIND_TIER_COL      = "ks_tier_col";
const string KS_BIND_KARMA_LBL     = "ks_karma_lbl";
const string KS_BIND_KARMA_COL     = "ks_karma_col";
const string KS_BIND_EFFECT_LBL    = "ks_effect_lbl";
const string KS_BIND_LOG_TXT       = "ks_log_txt";
const string KS_BIND_LOG_COL       = "ks_log_col";
const string KS_BIND_LOG_CNT       = "ks_log_cnt";
const string KS_BIND_BTN_RIT_ENA   = "ks_btn_rit_ena";
const string KS_BIND_BTN_RIT_TIP   = "ks_btn_rit_tip";
const string KS_BIND_BTN_SHAD_ENA  = "ks_btn_shad_ena";
const string KS_BIND_BTN_LIGHT_ENA = "ks_btn_light_ena";

// Buttons
const string KS_BTN_CLOSE        = "ks_btn_close";
const string KS_BTN_RITUAL       = "ks_btn_ritual";
const string KS_BTN_SHADOW_SURGE = "ks_btn_shadow";
const string KS_BTN_LIGHT_GRACE  = "ks_btn_light";

// Local vars on PC
const string KS_LVAR_DRAWN_KARMA = "KS_DRAWN_KARMA";

// Effect tags
const string KS_EFFECT_TAG = "KS_PASSIVE";
const string KS_SURGE_TAG  = "KS_SURGE";
const string KS_GRACE_TAG  = "KS_GRACE";

// Karma tiers
const int KS_TIER_DAMNATION = 0;   // karma <= -75
const int KS_TIER_SHADOW    = 1;   // karma -74 to -25
const int KS_TIER_BALANCE   = 2;   // karma -24 to 24
const int KS_TIER_BLESSED   = 3;   // karma 25 to 74
const int KS_TIER_TRIAL     = 4;   // karma >= 75

// Costs & cooldowns
const int KS_RITUAL_GOLD_COST = 50;
const int KS_RITUAL_SHIFT     = 10;   // karma points shifted toward 0 by ritual
const int KS_SURGE_COST       = 25;   // dark karma spent for Shadow Surge
const int KS_GRACE_COST       = 25;   // light karma spent for Light's Grace
const int KS_RITUAL_COOLDOWN  = 3600; // seconds between rituals

// Layout
const float KS_W   = 600.0;
const float KS_H   = 450.0;
const float KS_ROW = 30.0;

// ----------------------------------------------------------------
// Tier helpers
// ----------------------------------------------------------------

int KsGetTier(int nKarma)
{
    if(nKarma <= -75) return KS_TIER_DAMNATION;
    if(nKarma <= -25) return KS_TIER_SHADOW;
    if(nKarma <   25) return KS_TIER_BALANCE;
    if(nKarma <   75) return KS_TIER_BLESSED;
    return KS_TIER_TRIAL;
}

string KsGetTierLabel(int nKarma)
{
    switch(KsGetTier(nKarma))
    {
        case KS_TIER_DAMNATION: return "POTEPIENIE";
        case KS_TIER_SHADOW:    return "DOTKNIETY CIENIEM";
        case KS_TIER_BALANCE:   return "ROWNOWAGA";
        case KS_TIER_BLESSED:   return "LASKA SWIATLA";
        case KS_TIER_TRIAL:     return "PROBA WIARY";
    }
    return "ROWNOWAGA";
}

json KsGetTierColor(int nKarma)
{
    switch(KsGetTier(nKarma))
    {
        case KS_TIER_DAMNATION: return NuiColor(220,  40,  40);
        case KS_TIER_SHADOW:    return NuiColor(170,  80, 130);
        case KS_TIER_BALANCE:   return NuiColor(190, 190, 190);
        case KS_TIER_BLESSED:   return NuiColor(170, 210,  90);
        case KS_TIER_TRIAL:     return NuiColor(220, 190,  50);
    }
    return NuiColor(190, 190, 190);
}

json KsGetKarmaColor(int nKarma)
{
    if(nKarma < 0) return NuiColor(220,  60,  60);
    if(nKarma > 0) return NuiColor(200, 180,  50);
    return NuiColor(185, 185, 185);
}

string KsGetTierEffectDescription(int nKarma)
{
    switch(KsGetTier(nKarma))
    {
        case KS_TIER_DAMNATION:
            return "Duchy potępionych szepczą w twoich uszach. Efekt: -3 Perswazja, -3 Leczenie.";
        case KS_TIER_SHADOW:
            return "Mrok spowija twoje serce niczym całun. Efekt: -1 Charyzma.";
        case KS_TIER_BALANCE:
            return "Szale drżą w niepewnej równowadze. Brak efektów pasywnych.";
        case KS_TIER_BLESSED:
            return "Blask wiary wzmacnia twoją wolę. Efekt: +1 do rzutów Woli.";
        case KS_TIER_TRIAL:
            return "Oczy bogów obserwują każdy twój krok. Efekt: +2 do wszystkich rzutów obronnych.";
    }
    return "";
}

string KsGetTierChangeMessage(int nTier)
{
    switch(nTier)
    {
        case KS_TIER_DAMNATION: return "[Szale] Poczułeś jak ciemność pożera twoją duszę...";
        case KS_TIER_SHADOW:    return "[Szale] Cień zacisnął się wokół twojego serca.";
        case KS_TIER_BALANCE:   return "[Szale] Szale powróciły do chwiejnej równowagi.";
        case KS_TIER_BLESSED:   return "[Szale] Blask wiary rozgrzewa twe serce.";
        case KS_TIER_TRIAL:     return "[Szale] Czujesz ciężar boskiej uwagi...";
    }
    return "";
}

// ----------------------------------------------------------------
// Forward declarations
// ----------------------------------------------------------------

void KsAwardKarma(object oPC, int nDelta, string sReason);
void CreateKsWindow(object oPC);
void FeedKsWindow(object oPC, int nToken);
int  KsGetRitualCooldownRemaining(object oPC);
