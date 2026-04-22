#include "nw_inc_nui"

// ============================================================
//  Spell Tracker ? constants, helpers, data layer
//  Include chain:  lib_st_ev -> lib_st -> lib_st_def -> nw_inc_nui
// ============================================================

// --- Window IDs --------------------------------------------------
const string ST_LIST_WINDOW_ID  = "st_list";
const string ST_ICON_WINDOW_ID  = "st_icon";

// --- List window ? per-row array binds --------------------------
const string ST_BIND_L_ICONS  = "st_l_ic";  // JsonArray<string>  icon resref
const string ST_BIND_L_NAMES  = "st_l_nm";  // JsonArray<string>  spell name
const string ST_BIND_L_TIMERS = "st_l_tm";  // JsonArray<string>  "1:05" / "45s"
const string ST_BIND_L_BTNVIS    = "st_l_bv";  // JsonArray<bool>    Remove button visible
const string ST_BIND_L_PROGRESS  = "st_l_pr";  // JsonArray<float>   0.0-1.0 remaining ratio
const string ST_BIND_L_COUNT     = "st_l_cnt"; // JsonInt            row count for NuiList

// --- List window ? element IDs ----------------------------------
const string ST_BTN_L_REMOVE  = "st_l_rm";

// --- Icon window ? group + button prefix -----------------------
const string ST_GROUP_IC_ROW  = "st_ic_row";
const string ST_BTN_IC_PREFIX = "st_ic_";

// --- LVARs on the player object ---------------------------------
const string ST_LVAR_L_TOKEN    = "ST_L_TOK";
const string ST_LVAR_IC_TOKEN   = "ST_IC_TOK";
const string ST_LVAR_L_RUNNING  = "ST_L_RUN";
const string ST_LVAR_IC_RUNNING = "ST_IC_RUN";
const string ST_LVAR_IC_SPDATA  = "ST_IC_SPD"; // cached JsonArray for icon click handler

// --- Spell JsonObject field keys --------------------------------
const string ST_F_ID        = "id";  // int    SpellId
const string ST_F_ICON      = "ic";  // string icon resref
const string ST_F_NAME      = "nm";  // string spell name
const string ST_F_TIMER     = "tm";  // int    seconds remaining
const string ST_F_DURATION  = "du";  // int    total duration (for progress ratio)
const string ST_F_CANREMOVE = "cr";  // int    bool ? effect is positive (player can dispel)

// --- List window ? progress bar color bind ----------------------
const string ST_BIND_L_PROGCOL = "st_l_pc";  // JsonArray<NuiColor>

// --- Event type strings (no dependency on module's lib_nui) -----
const string ST_EV_CLICK     = "click";
const string ST_EV_MOUSEDOWN = "mousedown";
const string ST_EV_CLOSE     = "close";

// --- Tick & layout constants ------------------------------------
const float ST_TICK_INTERVAL = 1.0;
const float ST_LIST_W        = 500.0;
const float ST_LIST_H        = 600.0;
const float ST_ICON_W        = 720.0;
const float ST_ICON_H        = 126.0;
const float ST_ICON_SIZE     = 48.0;
const float ST_ICON_CELL     = 56.0;  // icon + horizontal padding
const float ST_ROW_H         = 62.0;


// ----------------------------------------------------------------
//  StGetTimerColor
//  Returns NuiColor based on remaining/total ratio:
//  > 50% ? green, 25-50% ? yellow, <= 25% ? red.
// ----------------------------------------------------------------
json StGetTimerColor(int nRemaining, int nDuration)
{
    float fRatio = 1.0;
    if(nDuration > 0) fRatio = IntToFloat(nRemaining) / IntToFloat(nDuration);
    if(fRatio > 1.0) fRatio = 1.0;
    if(fRatio < 0.0) fRatio = 0.0;

    if(fRatio > 0.5)  return NuiColor(80,  200, 80);
    if(fRatio > 0.25) return NuiColor(210, 180, 50);
    return                   NuiColor(200, 60,  60);
}

// ----------------------------------------------------------------
//  StFormatTimer
//  Converts seconds to "1:05" (>= 60s) or "45s" (< 60s).
// ----------------------------------------------------------------
string StFormatTimer(int nSeconds)
{
    if(nSeconds <= 0) return "0s";
    if(nSeconds < 60) return IntToString(nSeconds) + "s";

    int nMin = nSeconds / 60;
    int nSec = nSeconds % 60;
    string sPad = "";
    if(nSec < 10) sPad = "0";
    return IntToString(nMin) + ":" + sPad + IntToString(nSec);
}

// ----------------------------------------------------------------
//  StGetSpellName
//  Reads localised spell name from spells.2da Name StrRef.
//  Falls back to "Spell#ID" when the entry is missing or custom TLK.
// ----------------------------------------------------------------
string StGetSpellName(int nSpellId)
{
    int nStrRef = StringToInt(Get2DAString("spells", "Name", nSpellId));
    if(nStrRef <= 0) return "Spell#" + IntToString(nSpellId);

    string s = GetStringByStrRef(nStrRef);
    if(s == "")                             return "Spell#" + IntToString(nSpellId);
    if(FindSubString(s, "Bad Strref") >= 0) return "Spell#" + IntToString(nSpellId);
    return s;
}

// ----------------------------------------------------------------
//  StGetSpellIcon
//  Reads icon resref from spells.2da IconResRef column.
// ----------------------------------------------------------------
string StGetSpellIcon(int nSpellId)
{
    string s = Get2DAString("spells", "IconResRef", nSpellId);
    if(s == "") return "ir_null";
    return s;
}

// ----------------------------------------------------------------
//  StSpellCanRemove
//  Always returns TRUE ? player can dispel any effect on themselves.
//  HostileSetting from spells.2da is not reliable: spells like
//  Battletide are "hostile" (debuff enemies) but also buff the caster.
// ----------------------------------------------------------------
int StSpellCanRemove(int nSpellId)
{
    return TRUE;
}

// ----------------------------------------------------------------
//  StCollectSpells
//  Iterates effects on oPC only (fast ? called every tick).
//  Keeps temporary effects with SpellId > 0, deduplicates by SpellId.
//  Returns JsonArray of spell objects [{id,ic,nm,tm,du,cr}, ...].
// ----------------------------------------------------------------
json StCollectSpells(object oPC)
{
    json jResult = JsonArray();
    json jSeen   = JsonObject(); // key = SpellId string, prevents duplicates

    effect e = GetFirstEffect(oPC);
    while(GetIsEffectValid(e))
    {
        if(GetEffectDurationType(e) == DURATION_TYPE_TEMPORARY)
        {
            int nSpellId = GetEffectSpellId(e);
            if(nSpellId > 0)
            {
                string sKey = IntToString(nSpellId);
                if(JsonGetType(JsonObjectGet(jSeen, sKey)) == JSON_TYPE_NULL)
                {
                    jSeen = JsonObjectSet(jSeen, sKey, JsonBool(TRUE));

                    int nRemaining  = GetEffectDurationRemaining(e);
                    int nDuration   = GetEffectDuration(e);
                    int bCanRemove  = StSpellCanRemove(nSpellId);

                    json jSpell = JsonObject();
                    jSpell = JsonObjectSet(jSpell, ST_F_ID,        JsonInt(nSpellId));
                    jSpell = JsonObjectSet(jSpell, ST_F_ICON,      JsonString(StGetSpellIcon(nSpellId)));
                    jSpell = JsonObjectSet(jSpell, ST_F_NAME,      JsonString(StGetSpellName(nSpellId)));
                    jSpell = JsonObjectSet(jSpell, ST_F_TIMER,     JsonInt(nRemaining));
                    jSpell = JsonObjectSet(jSpell, ST_F_DURATION,  JsonInt(nDuration));
                    jSpell = JsonObjectSet(jSpell, ST_F_CANREMOVE, JsonBool(bCanRemove));

                    jResult = JsonArrayInsert(jResult, jSpell);
                }
            }
        }
        e = GetNextEffect(oPC);
    }
    return jResult;
}

// ----------------------------------------------------------------
//  StRemoveEffectsFromObject
//  Removes all temporary effects with nSpellId from a single object.
// ----------------------------------------------------------------
void StRemoveEffectsFromObject(object oObj, int nSpellId)
{
    effect e = GetFirstEffect(oObj);
    while(GetIsEffectValid(e))
    {
        effect eNext = GetNextEffect(oObj);
        if(GetEffectSpellId(e) == nSpellId &&
           GetEffectDurationType(e) == DURATION_TYPE_TEMPORARY)
            RemoveEffect(oObj, e);
        e = eNext;
    }
}

// ----------------------------------------------------------------
//  StRemoveBySpellId
//  Removes the spell from PC and from all equipped items.
//  Slot scan runs only on click ? not every tick.
// ----------------------------------------------------------------
void StRemoveBySpellId(object oPC, int nSpellId)
{
    StRemoveEffectsFromObject(oPC, nSpellId);

    int nSlot;
    for(nSlot = 0; nSlot < NUM_INVENTORY_SLOTS; nSlot++)
    {
        object oItem = GetItemInSlot(nSlot, oPC);
        if(GetIsObjectValid(oItem))
            StRemoveEffectsFromObject(oItem, nSpellId);
    }
}
