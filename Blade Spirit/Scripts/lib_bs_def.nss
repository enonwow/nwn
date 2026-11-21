#include "lib_nui"
#include "sql_bs"

// Forward declarations for functions defined in lib_bs.nss
void BsOpenWindow(object oPC, string sItemUUID);
void BsOpenCreateWindow(object oPC, string sItemUUID, string sWeaponName, string sWeaponIcon);
void BsFeedMainWindow(object oPC, int nToken);
void BsFeedCreateWindow(object oPC, int nToken);

// ----------------------------------------------------------------
// Window IDs
// ----------------------------------------------------------------

const string BS_WIN             = "BS_WIN";
const string BS_WIN_EV          = "lib_bs_ev";
const string BS_WIN_GEOM        = "bs_win_geom";

const string BS_WIN_CREATE      = "BS_WIN_CREATE";
const string BS_WIN_CREATE_GEOM = "bs_create_geom";

// ----------------------------------------------------------------
// Main window binds
// ----------------------------------------------------------------

const string BS_BIND_WPN_ICON     = "bs_wpn_icon";
const string BS_BIND_SPIRIT_NAME  = "bs_spirit_name";
const string BS_BIND_TIER_LBL     = "bs_tier_lbl";
const string BS_BIND_TIER_COLOR   = "bs_tier_color";
const string BS_BIND_CLASS_LBL    = "bs_class_lbl";
const string BS_BIND_KILLS_LBL    = "bs_kills_lbl";
const string BS_BIND_KILLS_NEXT   = "bs_kills_next";
const string BS_BIND_BONUS_LBL    = "bs_bonus_lbl";
const string BS_BIND_WHISPER_0    = "bs_whisper_0";
const string BS_BIND_WHISPER_1    = "bs_whisper_1";
const string BS_BIND_WHISPER_2    = "bs_whisper_2";
const string BS_BIND_MANIFEST_ENA = "bs_manifest_ena";
const string BS_BIND_MANIFEST_LBL = "bs_manifest_lbl";
const string BS_BIND_APPEASE_ENA  = "bs_appease_ena";
const string BS_BIND_APPEASE_LBL  = "bs_appease_lbl";
const string BS_BIND_EXORCISE_ENA = "bs_exorcise_ena";
const string BS_BIND_APPEASED_LBL = "bs_appeased_lbl";
const string BS_BIND_WPNNAME_LBL  = "bs_wpnname_lbl";

// ----------------------------------------------------------------
// Create window binds
// ----------------------------------------------------------------

const string BS_BIND_C_WPN_ICON  = "bs_c_icon";
const string BS_BIND_C_WPN_NAME  = "bs_c_wpnname";
const string BS_BIND_C_SNAME     = "bs_c_sname";
const string BS_BIND_C_CLASS_W   = "bs_c_cl_w";
const string BS_BIND_C_CLASS_M   = "bs_c_cl_m";
const string BS_BIND_C_CLASS_R   = "bs_c_cl_r";
const string BS_BIND_C_CLASS_C   = "bs_c_cl_c";
const string BS_BIND_C_BIND_ENA  = "bs_c_bind_ena";
const string BS_BIND_C_STATUS    = "bs_c_status";

// ----------------------------------------------------------------
// Buttons
// ----------------------------------------------------------------

const string BS_BTN_CLOSE        = "bs_btn_close";
const string BS_BTN_COMMUNE      = "bs_btn_commune";
const string BS_BTN_APPEASE      = "bs_btn_appease";
const string BS_BTN_EXORCISE     = "bs_btn_exorcise";
const string BS_BTN_MANIFEST     = "bs_btn_manifest";
const string BS_BTN_C_W          = "bs_btn_cl_w";
const string BS_BTN_C_M          = "bs_btn_cl_m";
const string BS_BTN_C_R          = "bs_btn_cl_r";
const string BS_BTN_C_C          = "bs_btn_cl_c";
const string BS_BTN_C_BIND       = "bs_btn_bind";
const string BS_BTN_C_CANCEL     = "bs_btn_cancel";

// ----------------------------------------------------------------
// LVARs on PC
// ----------------------------------------------------------------

const string BS_LVAR_ACTIVE_UUID  = "BS_ACTIVE_UUID";
const string BS_LVAR_CREATE_UUID  = "BS_CREATE_UUID";
const string BS_LVAR_CREATE_CLASS = "BS_CREATE_CLASS";
const string BS_LVAR_TARGETING    = "BS_TARGETING";

// ----------------------------------------------------------------
// Effect tag prefix (+ item UUID = unique per-spirit tag)
// ----------------------------------------------------------------

const string BS_FX_TAG = "BS_SPIRIT_";

// ----------------------------------------------------------------
// Costs and limits
// ----------------------------------------------------------------

const int BS_BIND_COST           = 500;
const int BS_APPEASE_COST        = 100;
const int BS_EXORCISE_MIN_CLERIC = 5;

// ----------------------------------------------------------------
// Layout dimensions
// ----------------------------------------------------------------

const float BS_WIN_W    = 680.0;
const float BS_WIN_H    = 460.0;
const float BS_CREATE_W = 460.0;
const float BS_CREATE_H = 340.0;

// ----------------------------------------------------------------
// Bonus application / removal
// ----------------------------------------------------------------

void BsApplyBonuses(object oPC, string sUUID, int nClass, int nTier, int bAppeased)
{
    string sTag  = BS_FX_TAG + sUUID;
    int    nApp  = bAppeased ? 1 : 0;

    if(nClass == BS_CLASS_WARRIOR)
    {
        int nAB = nTier + 1 + nApp;
        ApplyEffectToObject(DURATION_TYPE_PERMANENT,
            TagEffect(EffectAttackIncrease(nAB), sTag), oPC);
        if(nTier >= BS_TIER_ACTIVE)
            ApplyEffectToObject(DURATION_TYPE_PERMANENT,
                TagEffect(EffectAbilityIncrease(ABILITY_STRENGTH,
                    nTier == BS_TIER_MANIFESTED ? 3 : 2), sTag), oPC);
    }
    else if(nClass == BS_CLASS_MAGE)
    {
        int nConc   = (nTier + 1) * 2 + nApp;
        ApplyEffectToObject(DURATION_TYPE_PERMANENT,
            TagEffect(EffectSkillIncrease(SKILL_CONCENTRATION, nConc), sTag), oPC);
        if(nTier >= BS_TIER_RESTLESS)
        {
            int nScraft = nTier == BS_TIER_RESTLESS ? 2 :
                          nTier == BS_TIER_ACTIVE   ? 3 : 4 + nApp;
            ApplyEffectToObject(DURATION_TYPE_PERMANENT,
                TagEffect(EffectSkillIncrease(SKILL_SPELLCRAFT, nScraft), sTag), oPC);
        }
        if(nTier == BS_TIER_MANIFESTED)
            ApplyEffectToObject(DURATION_TYPE_PERMANENT,
                TagEffect(EffectAbilityIncrease(ABILITY_INTELLIGENCE, 2), sTag), oPC);
    }
    else if(nClass == BS_CLASS_ROGUE)
    {
        int nHide = (nTier == BS_TIER_DORMANT  ? 2 :
                     nTier == BS_TIER_RESTLESS  ? 3 :
                     nTier == BS_TIER_ACTIVE    ? 5 : 6) + nApp;
        ApplyEffectToObject(DURATION_TYPE_PERMANENT,
            TagEffect(EffectSkillIncrease(SKILL_HIDE, nHide), sTag), oPC);
        if(nTier >= BS_TIER_RESTLESS)
        {
            int nMS = nTier == BS_TIER_RESTLESS ? 3 :
                      nTier == BS_TIER_ACTIVE   ? 4 : 6;
            ApplyEffectToObject(DURATION_TYPE_PERMANENT,
                TagEffect(EffectSkillIncrease(SKILL_MOVE_SILENTLY, nMS), sTag), oPC);
        }
        if(nTier == BS_TIER_MANIFESTED)
            ApplyEffectToObject(DURATION_TYPE_PERMANENT,
                TagEffect(EffectAttackIncrease(1), sTag), oPC);
    }
    else if(nClass == BS_CLASS_CLERIC)
    {
        int nHeal = (nTier == BS_TIER_DORMANT  ? 2 :
                     nTier == BS_TIER_RESTLESS  ? 3 :
                     nTier == BS_TIER_ACTIVE    ? 4 : 5) + nApp;
        ApplyEffectToObject(DURATION_TYPE_PERMANENT,
            TagEffect(EffectSkillIncrease(SKILL_HEAL, nHeal), sTag), oPC);
        if(nTier >= BS_TIER_RESTLESS)
        {
            int nConc = nTier == BS_TIER_RESTLESS ? 2 :
                        nTier == BS_TIER_ACTIVE   ? 3 : 4;
            ApplyEffectToObject(DURATION_TYPE_PERMANENT,
                TagEffect(EffectSkillIncrease(SKILL_CONCENTRATION, nConc), sTag), oPC);
        }
        if(nTier == BS_TIER_MANIFESTED)
            ApplyEffectToObject(DURATION_TYPE_PERMANENT,
                TagEffect(EffectAbilityIncrease(ABILITY_WISDOM, 2), sTag), oPC);
    }
}

void BsRemoveBonuses(object oPC, string sUUID)
{
    string sTag = BS_FX_TAG + sUUID;
    effect e    = GetFirstEffect(oPC);
    while(GetIsEffectValid(e))
    {
        effect eNext = GetNextEffect(oPC);
        if(GetEffectTag(e) == sTag)
            RemoveEffect(oPC, e);
        e = eNext;
    }
}

// ----------------------------------------------------------------
// Bonus description for display in UI
// ----------------------------------------------------------------

string BsGetBonusDescription(int nClass, int nTier, int bAppeased)
{
    int nApp = bAppeased ? 1 : 0;
    string s = "";

    if(nClass == BS_CLASS_WARRIOR)
    {
        s += "+" + IntToString(nTier + 1 + nApp) + " do trafień";
        if(nTier >= BS_TIER_ACTIVE)
            s += "\n+" + IntToString(nTier == BS_TIER_MANIFESTED ? 3 : 2) + " do SIŁY";
    }
    else if(nClass == BS_CLASS_MAGE)
    {
        s += "+" + IntToString((nTier + 1) * 2 + nApp) + " Koncentracja";
        if(nTier >= BS_TIER_RESTLESS)
            s += "\n+" + IntToString(nTier == BS_TIER_RESTLESS ? 2 :
                                     nTier == BS_TIER_ACTIVE   ? 3 : 4 + nApp) + " Czaroznawstwo";
        if(nTier == BS_TIER_MANIFESTED)
            s += "\n+2 do INTELIGENCJI";
    }
    else if(nClass == BS_CLASS_ROGUE)
    {
        int nHide = (nTier == BS_TIER_DORMANT  ? 2 :
                     nTier == BS_TIER_RESTLESS  ? 3 :
                     nTier == BS_TIER_ACTIVE    ? 5 : 6) + nApp;
        s += "+" + IntToString(nHide) + " Ukrywanie";
        if(nTier >= BS_TIER_RESTLESS)
            s += "\n+" + IntToString(nTier == BS_TIER_RESTLESS ? 3 :
                                     nTier == BS_TIER_ACTIVE   ? 4 : 6) + " Cichy chód";
        if(nTier == BS_TIER_MANIFESTED)
            s += "\n+1 do trafień";
    }
    else if(nClass == BS_CLASS_CLERIC)
    {
        int nHeal = (nTier == BS_TIER_DORMANT  ? 2 :
                     nTier == BS_TIER_RESTLESS  ? 3 :
                     nTier == BS_TIER_ACTIVE    ? 4 : 5) + nApp;
        s += "+" + IntToString(nHeal) + " Leczenie";
        if(nTier >= BS_TIER_RESTLESS)
            s += "\n+" + IntToString(nTier == BS_TIER_RESTLESS ? 2 :
                                     nTier == BS_TIER_ACTIVE   ? 3 : 4) + " Koncentracja";
        if(nTier == BS_TIER_MANIFESTED)
            s += "\n+2 do MĄDROŚCI";
    }
    return s;
}

// ----------------------------------------------------------------
// Whispers: dark flavor text, cycling by (kill_count % 4) + tier
// ----------------------------------------------------------------

string BsGetWhisper(int nClass, int nTier, int nKills)
{
    int nIdx = (nKills + nTier) % 4;

    if(nClass == BS_CLASS_WARRIOR)
    {
        if(nIdx == 0) return "Ostrze pamięta każdą bitwę... każdą krew.";
        if(nIdx == 1) return "Walcz. Nie słabnij. Poległem — ale ty jeszcze nie.";
        if(nIdx == 2) return "Twoi wrogowie będą nosić twarze moich wrogów.";
        return "Gdy zginą setki, dam ci siłę tysiąca.";
    }
    if(nClass == BS_CLASS_MAGE)
    {
        if(nIdx == 0) return "Magia uwięziona w stali... szuka wyjścia.";
        if(nIdx == 1) return "Słyszę echa zaklęć, które rzucałem przed śmiercią.";
        if(nIdx == 2) return "Twój umysł jak pergamin — piszę na nim moją wolę.";
        return "Wkrótce będziesz gotowy. Wkrótce uwolnię moc.";
    }
    if(nClass == BS_CLASS_ROGUE)
    {
        if(nIdx == 0) return "Cicho. Nikt nie powinien wiedzieć, że tu jestem.";
        if(nIdx == 1) return "Każdy ma słabość. Ich — znajdziemy razem.";
        if(nIdx == 2) return "Zabójstwo to sztuka. Pozwól, że ci pokażę.";
        return "Cień to nasz sojusznik. Wejdź w ciemność.";
    }
    // Cleric
    if(nIdx == 0) return "Mój bóg milczy, lecz nie opuścił żadnego z nas.";
    if(nIdx == 1) return "Modlę się za ciebie w ciemnościach śmierci.";
    if(nIdx == 2) return "Każda leczona rana daje mi chwilę spokoju.";
    return "Gdy nadejdzie czas — przemówię przez ciebie.";
}

// ----------------------------------------------------------------
// Kill handling: called from sys_on_death.nss
// ----------------------------------------------------------------

void BsHandleKill(object oPC)
{
    object oRH = GetItemInSlot(INVENTORY_SLOT_RIGHTHAND, oPC);
    if(!GetIsObjectValid(oRH)) return;

    string sUUID  = GetObjectUUID(oRH);
    json   jSpirit = BsGetSpirit(sUUID);
    if(JsonGetType(jSpirit) == JSON_TYPE_NULL) return;

    int nOldKills = JsonGetInt(JsonObjectGet(jSpirit, "kill_count"));
    BsIncrementKills(sUUID);
    int nNewKills = nOldKills + 1;

    int nOldTier = BsGetTier(nOldKills);
    int nNewTier = BsGetTier(nNewKills);

    if(nNewTier > nOldTier)
    {
        int nClass = JsonGetInt(JsonObjectGet(jSpirit, "spirit_class"));
        BsRemoveBonuses(oPC, sUUID);

        json jFresh = BsGetSpirit(sUUID);
        BsApplyBonuses(oPC, sUUID, nClass, nNewTier, BsIsAppeased(jFresh));

        string sSpiritName = JsonGetString(JsonObjectGet(jFresh, "spirit_name"));
        FloatingTextStringOnCreature(
            "Duch \"" + sSpiritName + "\" wzmacnia się... poziom " +
            IntToString(nNewTier + 1) + ": " + BsTierName(nNewTier) + "!",
            oPC, FALSE);
        SendMessageToPC(oPC,
            "[Duch Ostrza] \"" + sSpiritName + "\" osiąga poziom " +
            BsTierName(nNewTier) + ". Nowe premie są aktywne.");
    }
}

// ----------------------------------------------------------------
// Apply bonuses for all equipped haunted weapons on login
// ----------------------------------------------------------------

void BsCheckAndApplyBonuses(object oPC)
{
    // Only check right hand; spirits only activate in primary hand
    object oRH = GetItemInSlot(INVENTORY_SLOT_RIGHTHAND, oPC);
    if(!GetIsObjectValid(oRH)) return;

    string sUUID   = GetObjectUUID(oRH);
    json   jSpirit = BsGetSpirit(sUUID);
    if(JsonGetType(jSpirit) == JSON_TYPE_NULL) return;

    int nKills = JsonGetInt(JsonObjectGet(jSpirit, "kill_count"));
    int nTier  = BsGetTier(nKills);
    int nClass = JsonGetInt(JsonObjectGet(jSpirit, "spirit_class"));

    BsApplyBonuses(oPC, sUUID, nClass, nTier, BsIsAppeased(jSpirit));

    string sSpiritName = JsonGetString(JsonObjectGet(jSpirit, "spirit_name"));
    string sWhisper    = BsGetWhisper(nClass, nTier, nKills);
    DelayCommand(5.0, FloatingTextStringOnCreature(
        "\"" + sWhisper + "\" — " + sSpiritName,
        oPC, FALSE));
}
