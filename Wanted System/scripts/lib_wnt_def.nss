// =============================================================================
// lib_wnt_def.nss
// =============================================================================
// Constants, pure helpers, and effect helpers for the Wanted system.
// Exposes the full public API used by lib_wnt.nss and by external callers
// (e.g., guard OnPerception scripts, crime-detection hooks).
// =============================================================================

#include "nw_inc_nui"
#include "sql_wnt"

// ---------------------------------------------------------------------------
// Thresholds — heat >= value means you are AT LEAST that level
// ---------------------------------------------------------------------------
const int WNT_MAX_HEAT    = 100;
const int WNT_TH_SUSPECT  =  20;   // >= 20  → Podejrzany
const int WNT_TH_WANTED   =  40;   // >= 40  → Poszukiwany
const int WNT_TH_OUTLAW   =  60;   // >= 60  → Wyjęty spod prawa
const int WNT_TH_DEAD     =  80;   // >= 80  → Martwy lub żywy

// ---------------------------------------------------------------------------
// Level IDs
// ---------------------------------------------------------------------------
const int WNT_LVL_CLEAN   = 0;
const int WNT_LVL_SUSPECT = 1;
const int WNT_LVL_WANTED  = 2;
const int WNT_LVL_OUTLAW  = 3;
const int WNT_LVL_DEAD    = 4;

// ---------------------------------------------------------------------------
// Decay rate
// TEST: 0.1 heat/s → full stack clears in ~17 minutes.
// Production: try 0.010–0.016 (1 heat per ~1 min).
// ---------------------------------------------------------------------------
const float WNT_DECAY_PER_SEC = 0.1;

// ---------------------------------------------------------------------------
// Economy
// ---------------------------------------------------------------------------
const int WNT_BRIBE_COST_PER_HEAT  = 15;  // gold per current heat point
const int WNT_BRIBE_REDUCTION      = 30;  // heat removed per successful bribe
const int WNT_SURRENDER_PER_CRIME  = 50;  // gold per crime when surrendering
const int WNT_SURRENDER_MIN_COST   = 100; // minimum gold for surrender

// ---------------------------------------------------------------------------
// HUD — small always-on bar (draggable, no close button)
// ---------------------------------------------------------------------------
const float  WNT_HUD_W = 220.0;
const float  WNT_HUD_H =  44.0;
const float  WNT_HUD_ICON = 36.0;

const string WNT_HUD_WIN      = "wnt_hud";
const string WNT_BIND_GEOM    = "wnt_geom";
const string WNT_BIND_ICON    = "wnt_icon";
const string WNT_BIND_LVL_LBL = "wnt_lvl";
const string WNT_BIND_BAR     = "wnt_bar";
const string WNT_BIND_COLOR   = "wnt_col";
const string WNT_BIND_TIP     = "wnt_tip";
const string WNT_BTN_OPEN     = "wnt_btn_open"; // click skull to open panel

// ---------------------------------------------------------------------------
// Records Panel — full window with buttons
// ---------------------------------------------------------------------------
const float  WNT_PANEL_W = 300.0;
const float  WNT_PANEL_H = 282.0;

const string WNT_PANEL_WIN          = "wnt_panel";
const string WNT_PANEL_BIND_GEOM    = "wnt_p_geom";
const string WNT_PANEL_BIND_HDR     = "wnt_p_hdr";
const string WNT_PANEL_BIND_BODY    = "wnt_p_body";
const string WNT_PANEL_BIND_HEAT    = "wnt_p_heat";
const string WNT_PANEL_BIND_CRIMES  = "wnt_p_crimes";
const string WNT_PANEL_BIND_BRIBE   = "wnt_p_bribe";  // button label (dynamic cost)
const string WNT_PANEL_BIND_BRIBE_EN    = "wnt_p_bribe_en";
const string WNT_PANEL_BIND_SURR_EN     = "wnt_p_surr_en";
const string WNT_BTN_BRIBE     = "wnt_btn_bribe";
const string WNT_BTN_SURRENDER = "wnt_btn_surr";
const string WNT_BTN_CLOSE     = "wnt_btn_close";

// ---------------------------------------------------------------------------
// Local variables stored on the PC object
// ---------------------------------------------------------------------------
const string WNT_LVAR_HUD_TOKEN   = "WNT_HUD_TK";
const string WNT_LVAR_PANEL_TOKEN = "WNT_PANEL_TK";
const string WNT_LVAR_GEOM_DELAY  = "WNT_GEOM_DL";
const string WNT_LVAR_TICK_GUARD  = "WNT_TICK_GD";

// ---------------------------------------------------------------------------
// Effect tag (all wanted debuffs share this tag for clean removal)
// ---------------------------------------------------------------------------
const string WNT_TAG_DBF = "WNT_DEBUFF";

// ===========================================================================
// Pure helpers
// ===========================================================================

// Compute effective heat from the stored snapshot + elapsed decay.
int WantedCalcHeat(struct WantedState s)
{
    int nNow     = WantedNowUnix();
    int nElapsed = nNow - s.last_decay_at;
    if(nElapsed < 0) nElapsed = 0;

    float fLost = IntToFloat(nElapsed) * WNT_DECAY_PER_SEC;
    int   nHeat = s.stored_heat - FloatToInt(fLost);
    if(nHeat < 0)            nHeat = 0;
    if(nHeat > WNT_MAX_HEAT) nHeat = WNT_MAX_HEAT;
    return nHeat;
}

int WantedGetLevel(int nHeat)
{
    if(nHeat >= WNT_TH_DEAD)   return WNT_LVL_DEAD;
    if(nHeat >= WNT_TH_OUTLAW) return WNT_LVL_OUTLAW;
    if(nHeat >= WNT_TH_WANTED) return WNT_LVL_WANTED;
    if(nHeat >= WNT_TH_SUSPECT)return WNT_LVL_SUSPECT;
    return WNT_LVL_CLEAN;
}

string WantedGetLevelName(int nLvl)
{
    switch(nLvl)
    {
        case WNT_LVL_CLEAN:   return "Czysto";
        case WNT_LVL_SUSPECT: return "Podejrzany";
        case WNT_LVL_WANTED:  return "Poszukiwany";
        case WNT_LVL_OUTLAW:  return "Wyjety spod prawa";
        case WNT_LVL_DEAD:    return "Martwy lub zywy";
    }
    return "";
}

string WantedGetFlavorText(int nLvl)
{
    switch(nLvl)
    {
        case WNT_LVL_CLEAN:
            return "Nie ciazy na tobie zadna wina w oczach prawa.\nNa razie.";
        case WNT_LVL_SUSPECT:
            return "Straz zerka w twoja strone z podejrzliwoscia.\nJeszcze nic pewnego — lecz wiesci sie rozchodza.";
        case WNT_LVL_WANTED:
            return "Twoj wizerunek widnieje na bramach i drzwiach karczmy.\nPytania padaja, pieniadze zmieniaja wlascicieli.";
        case WNT_LVL_OUTLAW:
            return "Prawa cie nie chronia. Kazdy miecz zbrojnych mierzy\nw twoja strone. Szukaj schronienia wsrod kanalii.";
        case WNT_LVL_DEAD:
            return "Wyznaczono nagrode za twoja glowe — i to wysoka.\nLowcy nagrod, kaci i zdrajcy sa w drodze. Uciekaj.";
    }
    return "";
}

string WantedGetIconResref(int nLvl)
{
    switch(nLvl)
    {
        case WNT_LVL_CLEAN:   return "wnt_icon_0";
        case WNT_LVL_SUSPECT: return "wnt_icon_1";
        case WNT_LVL_WANTED:  return "wnt_icon_2";
        case WNT_LVL_OUTLAW:  return "wnt_icon_3";
        case WNT_LVL_DEAD:    return "wnt_icon_4";
    }
    return "wnt_icon_0";
}

// Returns packed RGB for NuiColor unpacking.
int WantedGetColorRGB(int nLvl)
{
    switch(nLvl)
    {
        case WNT_LVL_CLEAN:   return (120 << 16) | (220 << 8) | 120; // zielony
        case WNT_LVL_SUSPECT: return (220 << 16) | (200 << 8) |  60; // zolty
        case WNT_LVL_WANTED:  return (230 << 16) | (130 << 8) |  40; // pomaranczowy
        case WNT_LVL_OUTLAW:  return (220 << 16) |  (60 << 8) |  40; // czerwony
        case WNT_LVL_DEAD:    return (160 << 16) |  (20 << 8) | 180; // purpurowy
    }
    return (200 << 16) | (200 << 8) | 200;
}

// ===========================================================================
// Effect helpers
// ===========================================================================

void WantedRemoveDebuffs(object oPC)
{
    effect e = GetFirstEffect(oPC);
    while(GetIsEffectValid(e))
    {
        if(GetEffectTag(e) == WNT_TAG_DBF) RemoveEffect(oPC, e);
        e = GetNextEffect(oPC);
    }
}

// Debuffs: Clean/Suspect → none.
// Wanted → -1 CHA (haggard, nervous).
// Outlaw → -2 CHA, -1 DEX (constantly looking over shoulder).
// Dead   → -3 CHA, -2 DEX, -1 CON (terror of being hunted).
void WantedApplyEffects(object oPC, int nLvl)
{
    WantedRemoveDebuffs(oPC);
    if(nLvl < WNT_LVL_WANTED) return;

    effect eDbf;
    if(nLvl == WNT_LVL_WANTED)
    {
        eDbf = EffectAbilityDecrease(ABILITY_CHARISMA, 1);
    }
    else if(nLvl == WNT_LVL_OUTLAW)
    {
        eDbf = EffectAbilityDecrease(ABILITY_CHARISMA, 2);
        eDbf = EffectLinkEffects(eDbf, EffectAbilityDecrease(ABILITY_DEXTERITY, 1));
    }
    else // WNT_LVL_DEAD
    {
        eDbf = EffectAbilityDecrease(ABILITY_CHARISMA, 3);
        eDbf = EffectLinkEffects(eDbf, EffectAbilityDecrease(ABILITY_DEXTERITY,    2));
        eDbf = EffectLinkEffects(eDbf, EffectAbilityDecrease(ABILITY_CONSTITUTION, 1));
    }
    eDbf = SupernaturalEffect(eDbf);
    eDbf = TagEffect(eDbf, WNT_TAG_DBF);
    ApplyEffectToObject(DURATION_TYPE_PERMANENT, eDbf, oPC);
}

// ===========================================================================
// Guard helper (can be called from guard OnPerception scripts)
// ===========================================================================

// Returns TRUE if oPC is wanted at level >= WNT_LVL_WANTED.
int WantedShouldGuardAttack(object oPC)
{
    if(!GetIsPC(oPC) || GetIsDM(oPC)) return FALSE;
    struct WantedState s = WantedGetState(GetObjectUUID(oPC));
    return WantedGetLevel(WantedCalcHeat(s)) >= WNT_LVL_WANTED;
}

// Call from a guard's OnPerception. If the PC is wanted, mark them as a
// temporary enemy for 2 minutes and shout a warning.
void WantedGuardReact(object oGuard, object oPC)
{
    if(!GetIsPC(oPC) || GetIsDM(oPC)) return;
    if(!WantedShouldGuardAttack(oPC)) return;

    SetIsTemporaryEnemy(oPC, oGuard, FALSE, 120.0);
    SpeakString("Zatrzymac! Jestes poszukiwany!", TALKVOLUME_TALK);
}
