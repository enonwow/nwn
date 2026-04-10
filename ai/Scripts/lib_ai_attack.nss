#include "lib_nui"
#include "x2_inc_itemprop"

const string AI_ATTACK_WINDOW = "AI_ATTACK_WINDOW";
const string AI_ATTACK_EVENT_SCRIPT = "lib_ai_attack_ev";

const string AI_BTN_MAIN = "AI_BTN_MAIN";
const string AI_BTN_OFF = "AI_BTN_OFF";

const int AI_HAND_MAIN = 0;
const int AI_HAND_OFF = 1;

const string AI_BIND_MAIN_NAME = "AI_BIND_MAIN_NAME";
const string AI_BIND_MAIN_INFO = "AI_BIND_MAIN_INFO";
const string AI_BIND_EXTRA_INFO = "AI_BIND_EXTRA_INFO";
const string AI_BIND_EXTRA_LIST = "AI_BIND_EXTRA_LIST";
const string AI_BIND_OFF_NAME = "AI_BIND_OFF_NAME";
const string AI_BIND_OFF_INFO = "AI_BIND_OFF_INFO";
const string AI_BIND_OFF_ENABLED = "AI_BIND_OFF_ENABLED";
const string AI_BIND_DMG_SUMMARY = "AI_BIND_DMG_SUMMARY";
const string AI_BIND_ATTACK_BONUS_LIST = "AI_BIND_ATTACK_BONUS_LIST";
const string AI_BIND_DAMAGE_BONUS_LIST = "AI_BIND_DAMAGE_BONUS_LIST";

int AIGetBaseItemColumnInt(object oItem, string sColumn)
{
    if(!GetIsObjectValid(oItem))
    {
        return -1;
    }

    string sValue = Get2DAString("baseitems", sColumn, GetBaseItemType(oItem));
    if(sValue == "****")
    {
        return -1;
    }

    return StringToInt(sValue);
}

int AIIsShield(object oItem)
{
    return AIGetBaseItemColumnInt(oItem, "WeaponWield") == 7;
}

int AIIsMonkWeapon(object oItem)
{
    if(!GetIsObjectValid(oItem))
    {
        return FALSE;
    }

    return AIGetBaseItemColumnInt(oItem, "IsMonkWeapon") == 1;
}

int AIIsCrossbow(object oItem)
{
    return AIGetBaseItemColumnInt(oItem, "WeaponWield") == 6;
}

int AIGetCreatureSize(object oPC)
{
    int nAppearance = GetAppearanceType(oPC);
    string sSize = Get2DAString("appearance", "SIZECATEGORY", nAppearance);

    if(sSize == "****")
    {
        return 3;
    }

    return StringToInt(sSize);
}

int AIIsLightWeaponForCreature(object oPC, object oWeapon)
{
    if(!GetIsObjectValid(oWeapon))
    {
        return FALSE;
    }

    int nCreatureSize = AIGetCreatureSize(oPC);
    int nWeaponSize = AIGetBaseItemColumnInt(oWeapon, "WeaponSize");

    if(nWeaponSize < 0)
    {
        return FALSE;
    }

    return (nCreatureSize - nWeaponSize) >= 1;
}

int AIIsRangedWeapon(object oItem)
{
    if(!GetIsObjectValid(oItem))
    {
        return FALSE;
    }

    return GetWeaponRanged(oItem);
}

int AIIsOffhandWeapon(object oOffhand)
{
    if(!GetIsObjectValid(oOffhand))
    {
        return FALSE;
    }

    if(AIIsShield(oOffhand))
    {
        return FALSE;
    }

    if(!GetIsWeaponEffective(oOffhand))
    {
        return FALSE;
    }

    return TRUE;
}

int AIHasHaste(object oPC)
{
    effect eEffect = GetFirstEffect(oPC);
    while(GetIsEffectValid(eEffect))
    {
        if(GetEffectType(eEffect) == EFFECT_TYPE_HASTE)
        {
            return TRUE;
        }
        eEffect = GetNextEffect(oPC);
    }

    return FALSE;
}

int AIGetModifyAttacksEffectTotal(object oPC)
{
    int nTotal = 0;

    effect eEffect = GetFirstEffect(oPC);
    while(GetIsEffectValid(eEffect))
    {
        if(GetEffectType(eEffect) == EFFECT_TYPE_MODIFY_ATTACKS)
        {
            nTotal += GetEffectInteger(eEffect, 0);
        }
        eEffect = GetNextEffect(oPC);
    }

    return nTotal;
}

int AIGetDivinePowerExtraAttacks(object oPC)
{
    effect eEffect = GetFirstEffect(oPC);
    while(GetIsEffectValid(eEffect))
    {
        if(GetEffectSpellId(eEffect) == SPELL_DIVINE_POWER)
        {
            int nLevel = GetHitDice(oPC);
            int nFighterBAB = nLevel;
            if(nFighterBAB > 20)
            {
                nFighterBAB = 20;
            }

            int nCurrentBAB = GetBaseAttackBonus(oPC);
            if(nCurrentBAB > 20)
            {
                nCurrentBAB = 20;
            }

            int nFighterMainCount = 1 + (nFighterBAB >= 6) + (nFighterBAB >= 11) + (nFighterBAB >= 16);
            int nCurrentMainCount = 1 + (nCurrentBAB >= 6) + (nCurrentBAB >= 11) + (nCurrentBAB >= 16);
            int nExtra = nFighterMainCount - nCurrentMainCount;

            if(nExtra > 0)
            {
                return nExtra;
            }
            return 0;
        }
        eEffect = GetNextEffect(oPC);
    }

    return 0;
}

int AIGetMainBABCap20(object oPC)
{
    int nBAB = GetBaseAttackBonus(oPC);
    if(nBAB > 20)
    {
        nBAB = 20;
    }

    return nBAB;
}

int AIUseMonkUBAB(object oPC)
{
    if(GetLevelByClass(CLASS_TYPE_MONK, oPC) <= 0)
    {
        return FALSE;
    }

    object oMain = GetItemInSlot(INVENTORY_SLOT_RIGHTHAND, oPC);
    object oOff = GetItemInSlot(INVENTORY_SLOT_LEFTHAND, oPC);
    object oArmor = GetItemInSlot(INVENTORY_SLOT_CHEST, oPC);

    int bUnarmedOrKama = !GetIsObjectValid(oMain) || AIIsMonkWeapon(oMain) || GetBaseItemType(oMain) == BASE_ITEM_KAMA;
    int bNoShield = !AIIsShield(oOff);
    int bNoArmor = !GetIsObjectValid(oArmor);

    return bUnarmedOrKama && bNoShield && bNoArmor;
}

int AIGetMainAttackCount(object oPC)
{
    int nBAB = AIGetMainBABCap20(oPC);

    if(AIUseMonkUBAB(oPC))
    {
        if(nBAB < 4)
        {
            return 1;
        }

        int nCount = 2 + ((nBAB - 4) / 3);
        if(nCount > 6)
        {
            nCount = 6;
        }
        return nCount;
    }

    return 1 + (nBAB >= 6) + (nBAB >= 11) + (nBAB >= 16);
}

int AIGetMainPenalty(object oPC)
{
    object oOff = GetItemInSlot(INVENTORY_SLOT_LEFTHAND, oPC);
    if(!AIIsOffhandWeapon(oOff))
    {
        return 0;
    }

    int nPenaltyMain = -6;

    int bAmbi = GetHasFeat(FEAT_AMBIDEXTERITY, oPC);
    int bTWF = GetHasFeat(FEAT_TWO_WEAPON_FIGHTING, oPC);
    int bLight = AIIsLightWeaponForCreature(oPC, oOff);

    if(bAmbi)
    {
        // Ambidexterity alone reduces only off-hand penalty.
    }

    if(bTWF)
    {
        nPenaltyMain += 2;
    }

    if(bLight)
    {
        nPenaltyMain += 2;
    }

    return nPenaltyMain;
}

int AIGetOffPenalty(object oPC)
{
    object oOff = GetItemInSlot(INVENTORY_SLOT_LEFTHAND, oPC);
    if(!AIIsOffhandWeapon(oOff))
    {
        return 0;
    }

    int nPenaltyOff = -10;

    if(GetHasFeat(FEAT_AMBIDEXTERITY, oPC))
    {
        nPenaltyOff += 4;
    }

    if(GetHasFeat(FEAT_TWO_WEAPON_FIGHTING, oPC))
    {
        nPenaltyOff += 2;
    }

    if(AIIsLightWeaponForCreature(oPC, oOff))
    {
        nPenaltyOff += 2;
    }

    return nPenaltyOff;
}

int AIGetOffAttackCount(object oPC)
{
    object oOff = GetItemInSlot(INVENTORY_SLOT_LEFTHAND, oPC);
    if(!AIIsOffhandWeapon(oOff))
    {
        return 0;
    }

    int nCount = 1;

    if(GetHasFeat(FEAT_IMPROVED_TWO_WEAPON_FIGHTING, oPC))
    {
        nCount += 1;
    }

    return nCount;
}

int AIGetStrengthDamageModForHand(object oPC, int nMode)
{
    int nStr = GetAbilityModifier(ABILITY_STRENGTH, oPC);

    if(nMode == AI_HAND_MAIN)
    {
        return nStr;
    }

    if(nStr < 0)
    {
        return nStr;
    }

    return nStr / 2;
}

int AIGetPowerAttackDamageBonus(object oPC)
{
    if(GetActionMode(oPC, ACTION_MODE_IMPROVED_POWER_ATTACK))
    {
        return 10;
    }

    if(GetActionMode(oPC, ACTION_MODE_POWER_ATTACK))
    {
        return 5;
    }

    return 0;
}

int AIGetPowerAttackABPenalty(object oPC)
{
    if(GetActionMode(oPC, ACTION_MODE_IMPROVED_POWER_ATTACK))
    {
        return -10;
    }

    if(GetActionMode(oPC, ACTION_MODE_POWER_ATTACK))
    {
        return -5;
    }

    return 0;
}

string AIAttackGetWeaponLabel(object oItem, string sFallback)
{
    if(!GetIsObjectValid(oItem))
    {
        return sFallback;
    }

    return GetName(oItem);
}

string AIJoinAttackLine(string sCurrent, int nBonus)
{
    if(GetStringLength(sCurrent) > 0)
    {
        sCurrent += "\n";
    }

    return sCurrent + IntToString(nBonus);
}

string AIBuildMainProgression(object oPC)
{
    object oMain = GetItemInSlot(INVENTORY_SLOT_RIGHTHAND, oPC);

    int nBAB = AIGetMainBABCap20(oPC);
    int nStrAB = GetAbilityModifier(ABILITY_STRENGTH, oPC);
    int nCount = AIGetMainAttackCount(oPC);

    if(AIIsRangedWeapon(oMain))
    {
        nStrAB = 0;
    }

    int nAB = nBAB + nStrAB + AIGetMainPenalty(oPC) + AIGetPowerAttackABPenalty(oPC);

    string sList = "";
    int i;
    for(i = 0; i < nCount; i++)
    {
        int nStep = AIUseMonkUBAB(oPC) ? 3 : 5;

        if(AIIsCrossbow(oMain) && !GetHasFeat(FEAT_RAPID_RELOAD, oPC))
        {
            if(i == 0)
            {
                sList = AIJoinAttackLine(sList, nAB);
            }
            break;
        }

        sList = AIJoinAttackLine(sList, nAB - (i * nStep));
    }

    return sList;
}

string AIBuildOffProgression(object oPC)
{
    int nCount = AIGetOffAttackCount(oPC);
    if(nCount <= 0)
    {
        return "Brak ataków offhand.";
    }

    int nBAB = AIGetMainBABCap20(oPC);
    int nStrAB = GetAbilityModifier(ABILITY_STRENGTH, oPC);
    int nAB = nBAB + nStrAB + AIGetOffPenalty(oPC) + AIGetPowerAttackABPenalty(oPC);

    string sList = "";
    int i;
    for(i = 0; i < nCount; i++)
    {
        sList = AIJoinAttackLine(sList, nAB - (i * 5));
    }

    return sList;
}

string AIBuildFreeAttackList(object oPC)
{
    int nBaseAB = AIGetMainBABCap20(oPC) + GetAbilityModifier(ABILITY_STRENGTH, oPC);
    int nCurrent = nBaseAB;

    string sList = "";

    if(AIHasHaste(oPC))
    {
        sList = AIJoinAttackLine(sList, nCurrent);
        nCurrent -= 5;
    }

    if(GetActionMode(oPC, ACTION_MODE_FLURRY_OF_BLOWS))
    {
        sList = AIJoinAttackLine(sList, nCurrent - 2);
        nCurrent -= 5;
    }

    if(GetActionMode(oPC, ACTION_MODE_RAPID_SHOT))
    {
        object oMain = GetItemInSlot(INVENTORY_SLOT_RIGHTHAND, oPC);
        if(AIIsRangedWeapon(oMain) && !AIIsCrossbow(oMain))
        {
            sList = AIJoinAttackLine(sList, nCurrent - 2);
            nCurrent -= 5;
        }
    }

    int nDivinePowerExtra = AIGetDivinePowerExtraAttacks(oPC);
    int i;
    for(i = 0; i < nDivinePowerExtra; i++)
    {
        sList = AIJoinAttackLine(sList, nCurrent);
        nCurrent -= 5;
    }

    int nModifyAttacks = AIGetModifyAttacksEffectTotal(oPC);
    for(i = 0; i < nModifyAttacks; i++)
    {
        sList = AIJoinAttackLine(sList, nCurrent);
        nCurrent -= 5;
    }

    if(GetHasFeat(FEAT_CLEAVE, oPC))
    {
        sList += "\nCleave: zależne od zabicia celu (dynamiczne).";
    }

    if(GetHasFeat(FEAT_GREAT_CLEAVE, oPC))
    {
        sList += "\nGreat Cleave: dynamiczne, bez stałego limitu/round.";
    }

    if(GetStringLength(sList) == 0)
    {
        sList = "Brak stałych free attacks.";
    }

    return sList;
}

string AIBuildDamageBonusList(object oPC, int nMode)
{
    object oMain = GetItemInSlot(INVENTORY_SLOT_RIGHTHAND, oPC);

    int nStrDmg = AIGetStrengthDamageModForHand(oPC, nMode);
    if(AIIsRangedWeapon(oMain) && nMode == AI_HAND_MAIN)
    {
        nStrDmg = 0;
    }

    string sList = "STR do DMG: " + IntToString(nStrDmg);

    int nPowerAttack = AIGetPowerAttackDamageBonus(oPC);
    if(nPowerAttack > 0)
    {
        sList += "\nPower Attack DMG: +" + IntToString(nPowerAttack);
    }

    return sList;
}

string AIBuildMainInfo(object oPC)
{
    int nBAB = AIGetMainBABCap20(oPC);
    int bUBAB = AIUseMonkUBAB(oPC);

    return "BAB: " + IntToString(nBAB)
        + " | UBAB: " + (bUBAB ? "TAK" : "NIE")
        + " | Kara dual(main): " + IntToString(AIGetMainPenalty(oPC));
}

string AIBuildOffInfo(object oPC)
{
    object oOff = GetItemInSlot(INVENTORY_SLOT_LEFTHAND, oPC);

    string sLight = AIIsLightWeaponForCreature(oPC, oOff) ? "TAK" : "NIE";

    return "Kara dual(off): " + IntToString(AIGetOffPenalty(oPC))
        + " | Lekka: " + sLight
        + " | Ataki: " + IntToString(AIGetOffAttackCount(oPC));
}

void AIAttackApplyBinds(object oPC, int nToken, int nMode)
{
    object oMain = GetItemInSlot(INVENTORY_SLOT_RIGHTHAND, oPC);
    object oOff = GetItemInSlot(INVENTORY_SLOT_LEFTHAND, oPC);

    int bOffEnabled = AIIsOffhandWeapon(oOff);

    NuiSetBind(oPC, nToken, AI_BIND_MAIN_NAME,
        JsonString(AIAttackGetWeaponLabel(oMain, "Main hand / unarmed")));
    NuiSetBind(oPC, nToken, AI_BIND_OFF_NAME,
        JsonString(AIAttackGetWeaponLabel(oOff, "Offhand")));

    NuiSetBind(oPC, nToken, AI_BIND_MAIN_INFO, JsonString(AIBuildMainInfo(oPC)));
    NuiSetBind(oPC, nToken, AI_BIND_OFF_INFO, JsonString(AIBuildOffInfo(oPC)));
    NuiSetBind(oPC, nToken, AI_BIND_OFF_ENABLED, JsonBool(bOffEnabled));

    NuiSetBind(oPC, nToken, AI_BIND_EXTRA_INFO,
        JsonString("Free attacks: haste/divine/modify/flurry/rapid/cleave"));
    NuiSetBind(oPC, nToken, AI_BIND_EXTRA_LIST,
        JsonString(AIBuildFreeAttackList(oPC)));

    if(nMode == AI_HAND_OFF)
    {
        NuiSetBind(oPC, nToken, AI_BIND_DMG_SUMMARY, JsonString("Offhand"));
        NuiSetBind(oPC, nToken, AI_BIND_ATTACK_BONUS_LIST, JsonString(AIBuildOffProgression(oPC)));
    }
    else
    {
        NuiSetBind(oPC, nToken, AI_BIND_DMG_SUMMARY, JsonString("Main hand"));
        NuiSetBind(oPC, nToken, AI_BIND_ATTACK_BONUS_LIST, JsonString(AIBuildMainProgression(oPC)));
    }

    NuiSetBind(oPC, nToken, AI_BIND_DAMAGE_BONUS_LIST,
        JsonString(AIBuildDamageBonusList(oPC, nMode)));
}

json AIAttackRoot()
{
    json jCol = JsonArray();

    json jRowA = JsonArray();
    jRowA = JsonArrayInsert(jRowA, NuiLabel(NuiBind(AI_BIND_MAIN_NAME), NUI_HALIGN_LEFT, NUI_VALIGN_MIDDLE));
    jRowA = JsonArrayInsert(jRowA, NuiLabel(JsonString("label"), NUI_HALIGN_RIGHT, NUI_VALIGN_MIDDLE));
    jCol = JsonArrayInsert(jCol, NuiRow(jRowA));

    json jRowB = JsonArray();
    jRowB = JsonArrayInsert(jRowB, NuiLabel(JsonString("Informacja BAB/UBAB"), NUI_HALIGN_LEFT, NUI_VALIGN_MIDDLE));
    jRowB = JsonArrayInsert(jRowB, NuiLabel(NuiBind(AI_BIND_MAIN_INFO), NUI_HALIGN_LEFT, NUI_VALIGN_MIDDLE));
    jCol = JsonArrayInsert(jCol, NuiRow(jRowB));

    jCol = JsonArrayInsert(jCol, NuiSpacer());

    json jRowC = JsonArray();
    jRowC = JsonArrayInsert(jRowC, NuiLabel(JsonString("Wyliczenie extra ataków"), NUI_HALIGN_LEFT, NUI_VALIGN_MIDDLE));
    jRowC = JsonArrayInsert(jRowC, NuiLabel(NuiBind(AI_BIND_EXTRA_INFO), NUI_HALIGN_LEFT, NUI_VALIGN_MIDDLE));
    jCol = JsonArrayInsert(jCol, NuiRow(jRowC));

    json jRowD = JsonArray();
    jRowD = JsonArrayInsert(jRowD, NuiLabel(JsonString("Lista extra ataków"), NUI_HALIGN_LEFT, NUI_VALIGN_TOP));
    jRowD = JsonArrayInsert(jRowD, NuiLabel(NuiBind(AI_BIND_EXTRA_LIST), NUI_HALIGN_LEFT, NUI_VALIGN_TOP));
    jCol = JsonArrayInsert(jCol, NuiRow(jRowD));

    jCol = JsonArrayInsert(jCol, NuiSpacer());

    json jRowE = JsonArray();
    jRowE = JsonArrayInsert(jRowE, NuiLabel(NuiBind(AI_BIND_OFF_NAME), NUI_HALIGN_LEFT, NUI_VALIGN_MIDDLE));
    jRowE = JsonArrayInsert(jRowE, NuiLabel(NuiBind(AI_BIND_OFF_INFO), NUI_HALIGN_LEFT, NUI_VALIGN_MIDDLE));
    jCol = JsonArrayInsert(jCol, NuiRow(jRowE));

    jCol = JsonArrayInsert(jCol, NuiSpacer());

    json jBtnMain = NuiButton(JsonString("mainhand"));
    jBtnMain = NuiId(jBtnMain, AI_BTN_MAIN);

    json jBtnOff = NuiButton(JsonString("offhand"));
    jBtnOff = NuiId(jBtnOff, AI_BTN_OFF);
    jBtnOff = NuiEnabled(jBtnOff, NuiBind(AI_BIND_OFF_ENABLED));

    json jSwitch = JsonArray();
    jSwitch = JsonArrayInsert(jSwitch, jBtnMain);
    jSwitch = JsonArrayInsert(jSwitch, jBtnOff);
    jSwitch = JsonArrayInsert(jSwitch, NuiLabel(JsonString("offhand disabled gdy brak broni"), NUI_HALIGN_LEFT, NUI_VALIGN_MIDDLE));
    jCol = JsonArrayInsert(jCol, NuiRow(jSwitch));

    jCol = JsonArrayInsert(jCol, NuiSpacer());

    json jRowF = JsonArray();
    jRowF = JsonArrayInsert(jRowF, NuiLabel(JsonString("Obrażenia:"), NUI_HALIGN_LEFT, NUI_VALIGN_MIDDLE));
    jRowF = JsonArrayInsert(jRowF, NuiLabel(NuiBind(AI_BIND_DMG_SUMMARY), NUI_HALIGN_LEFT, NUI_VALIGN_MIDDLE));
    jCol = JsonArrayInsert(jCol, NuiRow(jRowF));

    json jRowG = JsonArray();
    jRowG = JsonArrayInsert(jRowG, NuiLabel(JsonString("Lista bonusów ataku"), NUI_HALIGN_LEFT, NUI_VALIGN_TOP));
    jRowG = JsonArrayInsert(jRowG, NuiLabel(NuiBind(AI_BIND_ATTACK_BONUS_LIST), NUI_HALIGN_LEFT, NUI_VALIGN_TOP));
    jCol = JsonArrayInsert(jCol, NuiRow(jRowG));

    json jRowH = JsonArray();
    jRowH = JsonArrayInsert(jRowH, NuiLabel(JsonString("Lista bonusów obrażeń"), NUI_HALIGN_LEFT, NUI_VALIGN_TOP));
    jRowH = JsonArrayInsert(jRowH, NuiLabel(NuiBind(AI_BIND_DAMAGE_BONUS_LIST), NUI_HALIGN_LEFT, NUI_VALIGN_TOP));
    jCol = JsonArrayInsert(jCol, NuiRow(jRowH));

    return NuiCol(jCol);
}

void CreateAIAttackWindow(object oPC)
{
    int nToken = NuiFindWindow(oPC, AI_ATTACK_WINDOW);
    if(nToken > 0)
    {
        NuiDestroy(oPC, nToken);
    }

    json jRoot = AIAttackRoot();

    json jNui = NuiWindow(
        jRoot,
        NuiBind(WINDOW_TITLE),
        NuiBind(WINDOW_GEOMETRY),
        NuiBind(WINDOW_RESIZABLE),
        JsonBool(TRUE),
        NuiBind(WINDOW_CLOSABLE),
        NuiBind(WINDOW_TRANSPARENT),
        NuiBind(WINDOW_BORDER));

    nToken = NuiCreate(oPC, jNui, AI_ATTACK_WINDOW, AI_ATTACK_EVENT_SCRIPT);

    NuiSetBind(oPC, nToken, WINDOW_TITLE, JsonString("Attack View"));
    NuiSetBind(oPC, nToken, WINDOW_GEOMETRY, NuiRect(80.0, 40.0, 1250.0, 900.0));
    NuiSetBind(oPC, nToken, WINDOW_RESIZABLE, JsonBool(FALSE));
    NuiSetBind(oPC, nToken, WINDOW_CLOSABLE, JsonBool(TRUE));
    NuiSetBind(oPC, nToken, WINDOW_TRANSPARENT, JsonBool(FALSE));
    NuiSetBind(oPC, nToken, WINDOW_BORDER, JsonBool(TRUE));

    AIAttackApplyBinds(oPC, nToken, AI_HAND_MAIN);
}
