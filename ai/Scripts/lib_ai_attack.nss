#include "lib_nui"
#include "x2_inc_itemprop"
#include "nwnx_creature"

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
const string AI_BIND_FREE_ICONS = "AI_BIND_FREE_ICONS";
const string AI_BIND_FREE_NAMES = "AI_BIND_FREE_NAMES";
const string AI_BIND_FREE_COUNTS = "AI_BIND_FREE_COUNTS";
const string AI_BIND_FREE_LENGTH = "AI_BIND_FREE_LENGTH";

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

int AIItemHasHaste(object oItem)
{
    if(!GetIsObjectValid(oItem))
    {
        return FALSE;
    }

    itemproperty ip = GetFirstItemProperty(oItem);
    while(GetIsItemPropertyValid(ip))
    {
        if(GetItemPropertyType(ip) == ITEM_PROPERTY_HASTE)
        {
            return TRUE;
        }

        ip = GetNextItemProperty(oItem);
    }

    return FALSE;
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

    int nSlot;
    for(nSlot = 0; nSlot < NUM_INVENTORY_SLOTS; nSlot++)
    {
        if(AIItemHasHaste(GetItemInSlot(nSlot, oPC)))
        {
            return TRUE;
        }
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

    int bUnarmedOrKama = !GetIsObjectValid(oMain) || AIIsMonkWeapon(oMain);
    int bNoShield = !AIIsShield(oOff);
    int bNoArmor = !GetIsObjectValid(oArmor);

    return bUnarmedOrKama && bNoShield && bNoArmor;
}

int AIGetMainAttackCount(object oPC)
{
    int nCount = GetAttacksPerRound(oPC, FALSE);
    if(nCount < 1)
    {
        nCount = 1;
    }
    return nCount;
}

int AIGetMainPenalty(object oPC)
{
    object oOff = GetItemInSlot(INVENTORY_SLOT_LEFTHAND, oPC);
    if(!AIIsOffhandWeapon(oOff))
    {
        return 0;
    }

    int nPenaltyMain = -6;

    int bTWF = GetHasFeat(FEAT_TWO_WEAPON_FIGHTING, oPC);
    int bLight = AIIsLightWeaponForCreature(oPC, oOff);

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
    int nCount = GetAttacksPerRound(oPC, TRUE);
    if(nCount < 0)
    {
        nCount = 0;
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

int AIGetCurrentHighestAB(object oPC, int bOffhand)
{
    object oMain = GetItemInSlot(INVENTORY_SLOT_RIGHTHAND, oPC);
    int bMelee = !AIIsRangedWeapon(oMain);

    return NWNX_Creature_GetAttackBonus(
        oPC,
        bMelee,
        FALSE,
        bOffhand,
        TRUE);
}

string AIBuildMainProgression(object oPC)
{
    object oMain = GetItemInSlot(INVENTORY_SLOT_RIGHTHAND, oPC);

    int nCount = AIGetMainAttackCount(oPC);

    int nAB = AIGetCurrentHighestAB(oPC, FALSE);

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

    int nAB = AIGetCurrentHighestAB(oPC, TRUE);

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

    int nModifyAttacks = AIGetModifyAttacksEffectTotal(oPC);
    int i;
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

int AIAttackGetEffectIconRow(effect e)
{
    int nType = GetEffectType(e);
    if(nType == EFFECT_TYPE_HASTE) return 25;
    if(nType == EFFECT_TYPE_MODIFY_ATTACKS) return 29;
    if(nType == EFFECT_TYPE_ATTACK_INCREASE) return 29;
    if(nType == EFFECT_TYPE_ATTACK_DECREASE) return 30;
    if(nType == EFFECT_TYPE_DAMAGE_INCREASE) return 31;
    if(nType == EFFECT_TYPE_DAMAGE_DECREASE) return 32;
    return -1;
}

void AIBuildFreeAttacksFeed(
    object oPC,
    int nToken)
{
    json jIcons = JsonArray();
    json jNames = JsonArray();
    json jCounts = JsonArray();

    int bHasteAdded = FALSE;

    if(AIHasHaste(oPC))
    {
        jIcons = JsonArrayInsert(jIcons, JsonString("ir_fx_haste"));
        jNames = JsonArrayInsert(jNames, JsonString("Haste"));
        jCounts = JsonArrayInsert(jCounts, JsonString("+1"));
        bHasteAdded = TRUE;
    }

    effect e = GetFirstEffect(oPC);
    while(GetIsEffectValid(e))
    {
        int nType = GetEffectType(e);
        if(nType == EFFECT_TYPE_HASTE && bHasteAdded)
        {
            e = GetNextEffect(oPC);
            continue;
        }

        if(nType == EFFECT_TYPE_MODIFY_ATTACKS || nType == EFFECT_TYPE_ATTACK_INCREASE || nType == EFFECT_TYPE_ATTACK_DECREASE)
        {
            int nIconRow = AIAttackGetEffectIconRow(e);
            string sIcon = nIconRow >= 0 ? Get2DAString("effecticon", "IconResRef", nIconRow) : "";
            if(sIcon == "****")
            {
                sIcon = "";
            }

            string sName = nIconRow >= 0 ? Get2DAString("effecticon", "Label", nIconRow) : "Effect";
            if(sName == "****")
            {
                sName = "Effect";
            }

            int nValue = 1;
            if(nType == EFFECT_TYPE_MODIFY_ATTACKS)
            {
                nValue = GetEffectInteger(e, 0);
            }

            jIcons = JsonArrayInsert(jIcons, JsonString(sIcon));
            jNames = JsonArrayInsert(jNames, JsonString(sName));
            jCounts = JsonArrayInsert(jCounts, JsonString(IntToString(nValue)));
        }

        e = GetNextEffect(oPC);
    }
    NuiSetBind(oPC, nToken, AI_BIND_FREE_ICONS, jIcons);
    NuiSetBind(oPC, nToken, AI_BIND_FREE_NAMES, jNames);
    NuiSetBind(oPC, nToken, AI_BIND_FREE_COUNTS, jCounts);
    NuiSetBind(oPC, nToken, AI_BIND_FREE_LENGTH, JsonInt(JsonGetLength(jNames)));
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
    int bUBAB = AIUseMonkUBAB(oPC);

    return "AB: " + AIBuildMainProgression(oPC)
        + " | UBAB: " + (bUBAB ? "TAK" : "NIE")
        + " | Kara dual(main): " + IntToString(AIGetMainPenalty(oPC));
}

string AIBuildOffInfo(object oPC)
{
    object oOff = GetItemInSlot(INVENTORY_SLOT_LEFTHAND, oPC);

    string sLight = AIIsLightWeaponForCreature(oPC, oOff) ? "TAK" : "NIE";

    return "AB: " + AIBuildOffProgression(oPC)
        + " | Kara dual(off): " + IntToString(AIGetOffPenalty(oPC))
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
        JsonString("Free attacks: haste/modify(fl divine)/flurry/rapid/cleave"));
    NuiSetBind(oPC, nToken, AI_BIND_EXTRA_LIST,
        JsonString(AIBuildFreeAttackList(oPC)));

    AIBuildFreeAttacksFeed(oPC, nToken);

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
    json jRowB = JsonArray();
    json jRowC = JsonArray();
    json jRowD = JsonArray();
    json jRowE = JsonArray();
    json jRowF = JsonArray();
    json jRowG = JsonArray();
    json jRowH = JsonArray();
    json jCellRow = JsonArray();
    json jTemplate = JsonArray();
    json jSwitch = JsonArray();

    json jLblMainName = NuiLabel(NuiBind(AI_BIND_MAIN_NAME), JsonInt(NUI_HALIGN_LEFT), JsonInt(NUI_VALIGN_MIDDLE));
    json jLblMainInfo = NuiLabel(NuiBind(AI_BIND_MAIN_INFO), JsonInt(NUI_HALIGN_LEFT), JsonInt(NUI_VALIGN_MIDDLE));
    json jLblExtraTitle = NuiLabel(JsonString("Wyliczenie extra ataków"), JsonInt(NUI_HALIGN_LEFT), JsonInt(NUI_VALIGN_MIDDLE));
    json jLblExtraInfo = NuiLabel(NuiBind(AI_BIND_EXTRA_INFO), JsonInt(NUI_HALIGN_LEFT), JsonInt(NUI_VALIGN_MIDDLE));
    json jLblOffName = NuiLabel(NuiBind(AI_BIND_OFF_NAME), JsonInt(NUI_HALIGN_LEFT), JsonInt(NUI_VALIGN_MIDDLE));
    json jLblOffInfo = NuiLabel(NuiBind(AI_BIND_OFF_INFO), JsonInt(NUI_HALIGN_LEFT), JsonInt(NUI_VALIGN_MIDDLE));
    json jLblOffDisabled = NuiLabel(JsonString("offhand disabled gdy brak broni"), JsonInt(NUI_HALIGN_LEFT), JsonInt(NUI_VALIGN_MIDDLE));
    json jLblDmgTitle = NuiLabel(JsonString("Obrażenia:"), JsonInt(NUI_HALIGN_LEFT), JsonInt(NUI_VALIGN_MIDDLE));
    json jLblDmgSummary = NuiLabel(NuiBind(AI_BIND_DMG_SUMMARY), JsonInt(NUI_HALIGN_LEFT), JsonInt(NUI_VALIGN_MIDDLE));
    json jLblAtkTitle = NuiLabel(JsonString("Lista bonusów ataku"), JsonInt(NUI_HALIGN_LEFT), JsonInt(NUI_VALIGN_TOP));
    json jLblAtkList = NuiLabel(NuiBind(AI_BIND_ATTACK_BONUS_LIST), JsonInt(NUI_HALIGN_LEFT), JsonInt(NUI_VALIGN_TOP));
    json jLblDmgBonusTitle = NuiLabel(JsonString("Lista bonusów obrażeń"), JsonInt(NUI_HALIGN_LEFT), JsonInt(NUI_VALIGN_TOP));
    json jLblDmgBonusList = NuiLabel(NuiBind(AI_BIND_DAMAGE_BONUS_LIST), JsonInt(NUI_HALIGN_LEFT), JsonInt(NUI_VALIGN_TOP));

    json jBtnMain = NuiButton(JsonString("mainhand"));
    json jBtnOff = NuiButton(JsonString("offhand"));

    json jIcon = NuiButtonImage(NuiBind(AI_BIND_FREE_ICONS));
    json jName = NuiLabel(NuiBind(AI_BIND_FREE_NAMES), JsonInt(NUI_HALIGN_LEFT), JsonInt(NUI_VALIGN_MIDDLE));
    json jCount = NuiLabel(NuiBind(AI_BIND_FREE_COUNTS), JsonInt(NUI_HALIGN_RIGHT), JsonInt(NUI_VALIGN_MIDDLE));
    json jCell = JsonNull();
    json jList = JsonNull();

    jRowA = JsonArrayInsert(jRowA, jLblMainName);
    jRowA = JsonArrayInsert(jRowA, jLblMainInfo);
    jCol = JsonArrayInsert(jCol, NuiRow(jRowA));

    jCol = JsonArrayInsert(jCol, NuiSpacer());

    jRowB = JsonArrayInsert(jRowB, NuiLabel(JsonString("Informacja BAB/UBAB"), JsonInt(NUI_HALIGN_LEFT), JsonInt(NUI_VALIGN_MIDDLE)));
    jRowB = JsonArrayInsert(jRowB, jLblMainInfo);
    jCol = JsonArrayInsert(jCol, NuiRow(jRowB));

    jCol = JsonArrayInsert(jCol, NuiSpacer());

    jRowC = JsonArrayInsert(jRowC, jLblExtraTitle);
    jRowC = JsonArrayInsert(jRowC, jLblExtraInfo);
    jCol = JsonArrayInsert(jCol, NuiRow(jRowC));

    jIcon = NuiWidth(jIcon, 24.0);
    jCount = NuiWidth(jCount, 60.0);
    jCellRow = JsonArrayInsert(jCellRow, jIcon);
    jCellRow = JsonArrayInsert(jCellRow, jName);
    jCellRow = JsonArrayInsert(jCellRow, jCount);
    jCell = NuiListTemplateCell(NuiRow(jCellRow), 0.0, TRUE);
    jTemplate = JsonArrayInsert(jTemplate, jCell);
    jList = NuiList(jTemplate, NuiBind(AI_BIND_FREE_LENGTH), 34.0, FALSE, NUI_SCROLLBARS_Y);

    jRowD = JsonArrayInsert(jRowD, NuiLabel(JsonString("Lista extra ataków"), JsonInt(NUI_HALIGN_LEFT), JsonInt(NUI_VALIGN_TOP)));
    jRowD = JsonArrayInsert(jRowD, jList);
    jCol = JsonArrayInsert(jCol, NuiRow(jRowD));

    jCol = JsonArrayInsert(jCol, NuiSpacer());

    jRowE = JsonArrayInsert(jRowE, jLblOffName);
    jRowE = JsonArrayInsert(jRowE, jLblOffInfo);
    jCol = JsonArrayInsert(jCol, NuiRow(jRowE));

    jCol = JsonArrayInsert(jCol, NuiSpacer());

    jBtnMain = NuiId(jBtnMain, AI_BTN_MAIN);
    jBtnOff = NuiId(jBtnOff, AI_BTN_OFF);
    jBtnOff = NuiEnabled(jBtnOff, NuiBind(AI_BIND_OFF_ENABLED));

    jSwitch = JsonArrayInsert(jSwitch, jBtnMain);
    jSwitch = JsonArrayInsert(jSwitch, jBtnOff);
    jSwitch = JsonArrayInsert(jSwitch, jLblOffDisabled);
    jCol = JsonArrayInsert(jCol, NuiRow(jSwitch));

    jCol = JsonArrayInsert(jCol, NuiSpacer());

    jRowF = JsonArrayInsert(jRowF, jLblDmgTitle);
    jRowF = JsonArrayInsert(jRowF, jLblDmgSummary);
    jCol = JsonArrayInsert(jCol, NuiRow(jRowF));

    jRowG = JsonArrayInsert(jRowG, jLblAtkTitle);
    jRowG = JsonArrayInsert(jRowG, jLblAtkList);
    jCol = JsonArrayInsert(jCol, NuiRow(jRowG));

    jRowH = JsonArrayInsert(jRowH, jLblDmgBonusTitle);
    jRowH = JsonArrayInsert(jRowH, jLblDmgBonusList);
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
