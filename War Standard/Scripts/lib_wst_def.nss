// =============================================================================
// lib_wst_def.nss
// =============================================================================
// Constants and core helpers for the War Standard system. Exposes:
//   - Standard types and gameplay tunables
//   - NUI window / bind / button ID constants
//   - PC LVAR keys
//   - Type name / description helpers
//   - Effect helpers (apply / remove tagged buffs)
// =============================================================================

#include "sql_wst"

// --- Standard types ----------------------------------------------------------
const int WST_TYPE_LEGION  = 0;  // Gonfalon Legionu  (STR+2, CON+1)
const int WST_TYPE_SACRED  = 1;  // Chorągiew Pokuty  (Will+2, Fort+2, Regen 1)
const int WST_TYPE_TERROR  = 2;  // Sztandar Grozy    (AB+2, Dmg+2)

// --- Gameplay tunables -------------------------------------------------------
const float WST_RANGE_M         = 10.0;  // buff radius in meters
const int   WST_MAX_HP          = 20;    // standard placeable HP
const int   WST_DURATION_MIN    = 30;    // minutes before it expires
const int   WST_MAX_ACTIVE      = 5;     // max standards per area at once
const int   WST_MAX_INSCRIPTION = 25;    // inscription char limit

// Resref of the banner placeable; DM must place a matching blueprint in the hak.
// Fallback "plc_boulderlrg" is visible and attackable out of the box.
const string WST_PLACEABLE_RESREF = "nwn_war_standard";
const string WST_PLACEABLE_FALLBACK = "plc_boulderlrg";

// --- Object tags & item tags -------------------------------------------------
const string WST_TAG_PREFIX = "WST_STD_";   // + IntToString(id)
const string WST_TAG_KIT    = "WST_KIT";    // usable item that opens plant UI

// --- Effect tags -------------------------------------------------------------
const string WST_TAG_BUFF   = "WST_BUFF";   // ally buff from any standard
const string WST_TAG_FEAR   = "WST_FEAR";   // debuff on enemies (Terror type)

// --- Local vars on placeable -------------------------------------------------
const string WST_LVAR_ID         = "WST_ID";
const string WST_LVAR_TYPE       = "WST_TYPE";
const string WST_LVAR_OWNER_UUID = "WST_OWN_UUID";

// --- Local vars on PC --------------------------------------------------------
const string WST_LVAR_OVR_TOKEN  = "WST_OVR_TOK";   // NUI token for overview panel
const string WST_LVAR_PLT_TOKEN  = "WST_PLT_TOK";   // NUI token for plant dialog
const string WST_LVAR_GEOM_DELAY = "WST_GM_DLY";    // debounce flag for drag-save
const string WST_LVAR_BUFF_ID    = "WST_BUFF_ID";   // ID of standard currently buffing PC (0 = none)

// --- NUI window IDs ----------------------------------------------------------
const string WST_WIN_OVR   = "WST_OVR";   // overview / command panel
const string WST_WIN_PLT   = "WST_PLT";   // plant dialog

// --- NUI bind names (overview) -----------------------------------------------
const string WST_BIND_OVR_GEOM    = "WST_O_GM";    // window geometry (drag persist)
const string WST_BIND_OVR_NAMES   = "WST_O_NM";    // JsonArray of display strings per row
const string WST_BIND_OVR_HP_VAL  = "WST_O_HP";    // JsonArray of float (0..1) for HP bar
const string WST_BIND_OVR_HP_COL  = "WST_O_HC";    // JsonArray of NuiColor for HP bar
const string WST_BIND_OVR_COUNT   = "WST_O_CNT";   // JsonInt row count

// --- NUI bind names (plant dialog) -------------------------------------------
const string WST_BIND_PLT_GEOM   = "WST_P_GM";
const string WST_BIND_PLT_TYPE   = "WST_P_TY";    // JsonInt selected type (combo)
const string WST_BIND_PLT_INSCR  = "WST_P_IN";    // JsonString inscription text
const string WST_BIND_PLT_DESC   = "WST_P_DS";    // JsonString effect description label

// --- NUI button IDs ----------------------------------------------------------
const string WST_BTN_OVR_ROW     = "WST_OBR";   // NuiList row button (+ array index)
const string WST_BTN_OVR_PLANT   = "WST_OBP";   // "Wznieś Sztandar"
const string WST_BTN_OVR_CLOSE   = "WST_OBC";   // close overview
const string WST_BTN_PLT_CONFIRM = "WST_PBC";   // confirm plant
const string WST_BTN_PLT_CANCEL  = "WST_PBX";   // cancel plant

// =============================================================================
// Type name helpers
// =============================================================================
string WstGetTypeName(int nType)
{
    switch(nType)
    {
        case WST_TYPE_LEGION: return "Gonfalon Legionu";
        case WST_TYPE_SACRED: return "Chorągiew Pokuty";
        case WST_TYPE_TERROR: return "Sztandar Grozy";
    }
    return "Nieznany";
}

string WstGetTypeDesc(int nType)
{
    switch(nType)
    {
        case WST_TYPE_LEGION:
            return "Ryczący lew na czarnym tle. Siła +2, Kondycja +1 dla pobliskich sojuszników (zasięg "
                 + FloatToString(WST_RANGE_M, 0, 0) + " m).";
        case WST_TYPE_SACRED:
            return "Płótno zabarwione krwią ofiar. Wola +2, Odporność +2, Regeneracja 1 HP/6s.";
        case WST_TYPE_TERROR:
            return "Zdobiony czaszkami poległych. Premia do ataku +2, obrażenia +2 dla wojowników w pobliżu.";
    }
    return "";
}

// =============================================================================
// Effect helpers
// =============================================================================
void WstRemoveBuff(object oPC)
{
    effect e = GetFirstEffect(oPC);
    while(GetIsEffectValid(e))
    {
        string sTag = GetEffectTag(e);
        if(sTag == WST_TAG_BUFF || sTag == WST_TAG_FEAR)
            RemoveEffect(oPC, e);
        e = GetNextEffect(oPC);
    }
}

void WstApplyBuff(object oPC, int nType)
{
    WstRemoveBuff(oPC);

    effect eFx;
    switch(nType)
    {
        case WST_TYPE_LEGION:
        {
            effect eStr = EffectAbilityIncrease(ABILITY_STRENGTH, 2);
            effect eCon = EffectAbilityIncrease(ABILITY_CONSTITUTION, 1);
            eFx = EffectLinkEffects(eStr, eCon);
            break;
        }
        case WST_TYPE_SACRED:
        {
            effect eWill = EffectSavingThrowIncrease(SAVING_THROW_WILL, 2);
            effect eFort = EffectSavingThrowIncrease(SAVING_THROW_FORT, 2);
            effect eReg  = EffectRegenerate(1, 6.0);
            eFx = EffectLinkEffects(eWill, EffectLinkEffects(eFort, eReg));
            break;
        }
        case WST_TYPE_TERROR:
        {
            effect eAtk = EffectAttackIncrease(2, ATTACK_BONUS_ONHAND);
            effect eDmg = EffectDamageIncrease(2, DAMAGE_TYPE_BLUDGEONING);
            eFx = EffectLinkEffects(eAtk, eDmg);
            break;
        }
        default:
            return;
    }
    eFx = SupernaturalEffect(TagEffect(eFx, WST_TAG_BUFF));
    ApplyEffectToObject(DURATION_TYPE_PERMANENT, eFx, oPC);
}
