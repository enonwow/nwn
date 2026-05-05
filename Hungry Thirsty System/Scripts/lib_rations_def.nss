// =============================================================================
// lib_rations_def.nss
// =============================================================================
// Constants and core helpers for the Rations system. Exposes:
//   - All tunable constants (decay rates, thresholds, dimensions, IDs, binds)
//   - Pure helpers (RationsCalcCurrent, RationsGetThresholdLevel, color/name)
//   - Stat helpers (RationsGetCurrentHunger / Thirst, RationsAddHunger / Thirst)
//   - Effect helpers (apply / remove tagged debuffs at threshold edges)
//   - Item helpers (read LocalInt restore amounts)
// =============================================================================

#include "sql_rations"

// -----------------------------------------------------------------------------
// Tunables (production: lower decay rates, e.g. 0.014 hunger / 0.021 thirst)
// -----------------------------------------------------------------------------
// TEST MODE: 1 point per second -> full bar drains in 100 seconds.
const float  RAT_DECAY_HUNGER_PER_SEC = 1.0;
const float  RAT_DECAY_THIRST_PER_SEC = 1.0;

// Bar maximum and threshold breakpoints (>= for upper bound).
const int    RAT_MAX               = 100;
const int    RAT_TH_VAL_WELLFED    = 80;
const int    RAT_TH_VAL_NORMAL     = 30;
const int    RAT_TH_VAL_HUNGRY     = 10;

// Threshold IDs (0 = worst, 3 = best). Must match table column defaults.
const int    RAT_TH_STARVING = 0;
const int    RAT_TH_HUNGRY   = 1;
const int    RAT_TH_NORMAL   = 2;
const int    RAT_TH_WELLFED  = 3;

// Death reset value (both bars set to this on respawn).
const int    RAT_DEATH_RESET = 50;

// Effect tags
const string RAT_TAG_DBF_H = "RAT_DEBUFF_H";
const string RAT_TAG_DBF_T = "RAT_DEBUFF_T";

// Item LocalInts that drive consumption (set on item blueprints).
const string RAT_LVAR_IT_HUNGER = "HUNGER_RESTORE";
const string RAT_LVAR_IT_THIRST = "THIRST_RESTORE";

// HUD geometry. -1/-1 default position lets NUI auto-place the window;
// the player drags it once and the new position is persisted.
const float  RAT_HUD_W      = 230.0;
const float  RAT_HUD_H      = 135.0;
const float  RAT_HUD_ICON   = 36.0;
const float  RAT_HUD_BAR_H  = 32.0;

// HUD window / bind / element IDs
const string RAT_HUD_WIN       = "rat_hud";
const string RAT_HUD_ROW_H     = "rat_row_h";
const string RAT_HUD_ROW_T     = "rat_row_t";
const string RAT_BIND_GEOM     = "rat_geom";
const string RAT_BIND_BAR_H    = "rat_p_h";
const string RAT_BIND_BAR_T    = "rat_p_t";
const string RAT_BIND_LBL_H    = "rat_l_h";
const string RAT_BIND_LBL_T    = "rat_l_t";
const string RAT_BIND_COLOR_H  = "rat_c_h";
const string RAT_BIND_COLOR_T  = "rat_c_t";
const string RAT_BIND_TIP_H    = "rat_t_h";
const string RAT_BIND_TIP_T    = "rat_t_t";
const string RAT_BIND_ICON_H   = "rat_i_h";
const string RAT_BIND_ICON_T   = "rat_i_t";

// LVARs cached on the PC
const string RAT_LVAR_HUD_TOKEN  = "RAT_HUD_TOKEN";
const string RAT_LVAR_GEOM_DELAY = "RAT_GEOM_DELAY";
const string RAT_LVAR_TICK_GUARD = "RAT_TICK_GUARD";

// -----------------------------------------------------------------------------
// Pure calculation helpers
// -----------------------------------------------------------------------------
int RationsCalcCurrent(int nLastAt, float fDecayPerSec)
{
    int nNow     = RationsNowUnix();
    int nElapsed = nNow - nLastAt;
    if(nElapsed < 0) nElapsed = 0;

    float fLost = IntToFloat(nElapsed) * fDecayPerSec;
    int   nVal  = RAT_MAX - FloatToInt(fLost);
    if(nVal < 0)        nVal = 0;
    if(nVal > RAT_MAX)  nVal = RAT_MAX;
    return nVal;
}

int RationsGetThresholdLevel(int nValue)
{
    if(nValue >= RAT_TH_VAL_WELLFED) return RAT_TH_WELLFED;
    if(nValue >= RAT_TH_VAL_NORMAL)  return RAT_TH_NORMAL;
    if(nValue >= RAT_TH_VAL_HUNGRY)  return RAT_TH_HUNGRY;
    return RAT_TH_STARVING;
}

string RationsGetThresholdNameH(int nLvl)
{
    switch(nLvl)
    {
        case 3: return "Well-fed";
        case 2: return "Sated";
        case 1: return "Hungry";
        case 0: return "Starving";
    }
    return "";
}

string RationsGetThresholdNameT(int nLvl)
{
    switch(nLvl)
    {
        case 3: return "Quenched";
        case 2: return "Hydrated";
        case 1: return "Thirsty";
        case 0: return "Parched";
    }
    return "";
}

// Icon resref to display next to the bar, based on the current threshold.
// 3 images per category (full / mid / empty) cover all 4 thresholds:
//   Well-fed / Sated  -> image 1 (full)
//   Hungry / Thirsty  -> image 2 (mid)
//   Starving / Parched -> image 3 (empty)
string RationsGetIconResrefH(int nLvl)
{
    if(nLvl >= 2) return "rat_hunger_1";
    if(nLvl == 1) return "rat_hunger_2";
    return "rat_hunger_3";
}

string RationsGetIconResrefT(int nLvl)
{
    if(nLvl >= 2) return "rat_thirst_1";
    if(nLvl == 1) return "rat_thirst_2";
    return "rat_thirst_3";
}

// Returns packed RGB (r << 16 | g << 8 | b). Caller wraps in NuiColor().
int RationsGetThresholdColorRGB(int nLvl)
{
    if(nLvl == 3) return (120 << 16) | (220 << 8) | 120;
    if(nLvl == 2) return ( 90 << 16) | (170 << 8) |  90;
    if(nLvl == 1) return (220 << 16) | (200 << 8) |  60;
    if(nLvl == 0) return (220 << 16) | ( 80 << 8) |  60;
    return (200 << 16) | (200 << 8) | 200;
}

// -----------------------------------------------------------------------------
// PC value getters / setters
// -----------------------------------------------------------------------------
int RationsGetCurrentHunger(object oPC)
{
    int nLast = RationsGetLastMealAt(GetObjectUUID(oPC));
    return RationsCalcCurrent(nLast, RAT_DECAY_HUNGER_PER_SEC);
}

int RationsGetCurrentThirst(object oPC)
{
    int nLast = RationsGetLastDrinkAt(GetObjectUUID(oPC));
    return RationsCalcCurrent(nLast, RAT_DECAY_THIRST_PER_SEC);
}

// Set hunger to nNew by adjusting last_meal_at backward in time.
//   current = MAX - (now - last) * decay
//   => last = now - (MAX - new) / decay
void RationsSetHungerValue(object oPC, int nNew)
{
    if(nNew > RAT_MAX) nNew = RAT_MAX;
    if(nNew < 0)       nNew = 0;
    int nNow  = RationsNowUnix();
    int nLast = nNow - FloatToInt(IntToFloat(RAT_MAX - nNew) / RAT_DECAY_HUNGER_PER_SEC);
    RationsSetLastMealAt(GetObjectUUID(oPC), nLast);
}

void RationsSetThirstValue(object oPC, int nNew)
{
    if(nNew > RAT_MAX) nNew = RAT_MAX;
    if(nNew < 0)       nNew = 0;
    int nNow  = RationsNowUnix();
    int nLast = nNow - FloatToInt(IntToFloat(RAT_MAX - nNew) / RAT_DECAY_THIRST_PER_SEC);
    RationsSetLastDrinkAt(GetObjectUUID(oPC), nLast);
}

void RationsAddHunger(object oPC, int nAmt)
{
    RationsSetHungerValue(oPC, RationsGetCurrentHunger(oPC) + nAmt);
}

void RationsAddThirst(object oPC, int nAmt)
{
    RationsSetThirstValue(oPC, RationsGetCurrentThirst(oPC) + nAmt);
}

// -----------------------------------------------------------------------------
// Effect helpers
// -----------------------------------------------------------------------------
void RationsRemoveTaggedEffects(object oPC, string sTag)
{
    effect e = GetFirstEffect(oPC);
    while(GetIsEffectValid(e))
    {
        if(GetEffectTag(e) == sTag) RemoveEffect(oPC, e);
        e = GetNextEffect(oPC);
    }
}

void RationsApplyDebuffH(object oPC, int nLvl)
{
    RationsRemoveTaggedEffects(oPC, RAT_TAG_DBF_H);
    if(nLvl >= RAT_TH_NORMAL) return; // no debuff at Normal/Well-fed

    effect eDbf;
    if(nLvl == RAT_TH_HUNGRY)
    {
        eDbf = EffectAbilityDecrease(ABILITY_STRENGTH, 1);
        eDbf = EffectLinkEffects(eDbf, EffectAbilityDecrease(ABILITY_CONSTITUTION, 1));
    }
    else // STARVING -> -2 to all stats
    {
        eDbf = EffectAbilityDecrease(ABILITY_STRENGTH, 2);
        eDbf = EffectLinkEffects(eDbf, EffectAbilityDecrease(ABILITY_DEXTERITY,    2));
        eDbf = EffectLinkEffects(eDbf, EffectAbilityDecrease(ABILITY_CONSTITUTION, 2));
        eDbf = EffectLinkEffects(eDbf, EffectAbilityDecrease(ABILITY_INTELLIGENCE, 2));
        eDbf = EffectLinkEffects(eDbf, EffectAbilityDecrease(ABILITY_WISDOM,       2));
        eDbf = EffectLinkEffects(eDbf, EffectAbilityDecrease(ABILITY_CHARISMA,     2));
    }
    eDbf = SupernaturalEffect(eDbf);
    eDbf = TagEffect(eDbf, RAT_TAG_DBF_H);
    ApplyEffectToObject(DURATION_TYPE_PERMANENT, eDbf, oPC);
}

void RationsApplyDebuffT(object oPC, int nLvl)
{
    RationsRemoveTaggedEffects(oPC, RAT_TAG_DBF_T);
    if(nLvl >= RAT_TH_NORMAL) return;

    effect eDbf;
    if(nLvl == RAT_TH_HUNGRY)
    {
        eDbf = EffectAbilityDecrease(ABILITY_DEXTERITY,    1);
        eDbf = EffectLinkEffects(eDbf, EffectAbilityDecrease(ABILITY_CONSTITUTION, 1));
    }
    else // PARCHED -> -2 to all stats
    {
        eDbf = EffectAbilityDecrease(ABILITY_STRENGTH, 2);
        eDbf = EffectLinkEffects(eDbf, EffectAbilityDecrease(ABILITY_DEXTERITY,    2));
        eDbf = EffectLinkEffects(eDbf, EffectAbilityDecrease(ABILITY_CONSTITUTION, 2));
        eDbf = EffectLinkEffects(eDbf, EffectAbilityDecrease(ABILITY_INTELLIGENCE, 2));
        eDbf = EffectLinkEffects(eDbf, EffectAbilityDecrease(ABILITY_WISDOM,       2));
        eDbf = EffectLinkEffects(eDbf, EffectAbilityDecrease(ABILITY_CHARISMA,     2));
    }
    eDbf = SupernaturalEffect(eDbf);
    eDbf = TagEffect(eDbf, RAT_TAG_DBF_T);
    ApplyEffectToObject(DURATION_TYPE_PERMANENT, eDbf, oPC);
}

// -----------------------------------------------------------------------------
// Item helpers
// -----------------------------------------------------------------------------
int RationsGetItemRestoreH(object oItem)
{
    return GetLocalInt(oItem, RAT_LVAR_IT_HUNGER);
}

int RationsGetItemRestoreT(object oItem)
{
    return GetLocalInt(oItem, RAT_LVAR_IT_THIRST);
}

void RationsRemoveOneFromStack(object oItem)
{
    int n = GetItemStackSize(oItem);
    if(n <= 1) DestroyObject(oItem);
    else       SetItemStackSize(oItem, n - 1);
}
