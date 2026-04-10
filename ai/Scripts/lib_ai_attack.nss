#include "lib_nui"

const string AI_ATTACK_WINDOW = "AI_ATTACK_WINDOW";
const string AI_ATTACK_EVENT_SCRIPT = "lib_ai_attack_ev";

const string AI_BIND_HAND_MODE = "AI_BIND_HAND_MODE";
const string AI_BIND_HAND_LABEL = "AI_BIND_HAND_LABEL";
const string AI_BIND_MAIN_NAME = "AI_BIND_MAIN_NAME";
const string AI_BIND_MAIN_INFO = "AI_BIND_MAIN_INFO";
const string AI_BIND_EXTRA_INFO = "AI_BIND_EXTRA_INFO";
const string AI_BIND_EXTRA_LIST = "AI_BIND_EXTRA_LIST";
const string AI_BIND_OFF_NAME = "AI_BIND_OFF_NAME";
const string AI_BIND_OFF_INFO = "AI_BIND_OFF_INFO";
const string AI_BIND_OFF_DISABLED = "AI_BIND_OFF_DISABLED";
const string AI_BIND_DMG_SUMMARY = "AI_BIND_DMG_SUMMARY";
const string AI_BIND_ATTACK_BONUS_LIST = "AI_BIND_ATTACK_BONUS_LIST";
const string AI_BIND_DAMAGE_BONUS_LIST = "AI_BIND_DAMAGE_BONUS_LIST";

const string AI_BTN_MAIN = "AI_BTN_MAIN";
const string AI_BTN_OFF = "AI_BTN_OFF";

const int AI_HAND_MAIN = 0;
const int AI_HAND_OFF = 1;

int AIAttackIsShield(int nBaseItem)
{
    if(nBaseItem == BASE_ITEM_SMALLSHIELD)
    {
        return TRUE;
    }

    if(nBaseItem == BASE_ITEM_LARGESHIELD)
    {
        return TRUE;
    }

    if(nBaseItem == BASE_ITEM_TOWERSHIELD)
    {
        return TRUE;
    }

    return FALSE;
}

int AIAttackIsOffhandWeapon(object oOffhand)
{
    if(!GetIsObjectValid(oOffhand))
    {
        return FALSE;
    }

    int nBaseItem = GetBaseItemType(oOffhand);
    return !AIAttackIsShield(nBaseItem);
}

int AIAttackGetTwoWeaponPenaltyMain(object oPC)
{
    object oOffhand = GetItemInSlot(INVENTORY_SLOT_LEFTHAND, oPC);
    if(!AIAttackIsOffhandWeapon(oOffhand))
    {
        return 0;
    }

    int nPenalty = -6;

    if(GetHasFeat(FEAT_AMBIDEXTERITY, oPC))
    {
        nPenalty += 2;
    }

    if(GetHasFeat(FEAT_TWO_WEAPON_FIGHTING, oPC))
    {
        nPenalty += 2;
    }

    return nPenalty;
}

int AIAttackGetTwoWeaponPenaltyOff(object oPC)
{
    object oOffhand = GetItemInSlot(INVENTORY_SLOT_LEFTHAND, oPC);
    if(!AIAttackIsOffhandWeapon(oOffhand))
    {
        return 0;
    }

    int nPenalty = -10;

    if(GetHasFeat(FEAT_AMBIDEXTERITY, oPC))
    {
        nPenalty += 4;
    }

    if(GetHasFeat(FEAT_TWO_WEAPON_FIGHTING, oPC))
    {
        nPenalty += 2;
    }

    return nPenalty;
}

int AIAttackGetStrengthMod(object oPC)
{
    return GetAbilityModifier(ABILITY_STRENGTH, oPC);
}

string AIAttackGetWeaponName(object oWeapon, string sDefaultLabel)
{
    if(!GetIsObjectValid(oWeapon))
    {
        return sDefaultLabel;
    }

    return GetName(oWeapon);
}

string AIAttackGetMainInfo(object oPC)
{
    int nBAB = GetBaseAttackBonus(oPC);
    int nStr = AIAttackGetStrengthMod(oPC);
    int nPenalty = AIAttackGetTwoWeaponPenaltyMain(oPC);

    return "BAB " + IntToString(nBAB)
        + " | STR mod " + IntToString(nStr)
        + " | Kara TWF " + IntToString(nPenalty);
}

string AIAttackGetOffInfo(object oPC)
{
    int nBAB = GetBaseAttackBonus(oPC);
    int nStr = AIAttackGetStrengthMod(oPC);
    int nPenalty = AIAttackGetTwoWeaponPenaltyOff(oPC);

    return "BAB " + IntToString(nBAB)
        + " | STR mod " + IntToString(nStr)
        + " | Kara offhand " + IntToString(nPenalty);
}

string AIAttackBuildAttackBonusList(object oPC, int nMode)
{
    int nBAB = GetBaseAttackBonus(oPC);
    int nStr = AIAttackGetStrengthMod(oPC);

    int nPenalty = AIAttackGetTwoWeaponPenaltyMain(oPC);
    if(nMode == AI_HAND_OFF)
    {
        nPenalty = AIAttackGetTwoWeaponPenaltyOff(oPC);
    }

    int nAttacks = (nBAB + 4) / 5;
    if(nAttacks < 1)
    {
        nAttacks = 1;
    }

    string sList = "";
    int i;
    for(i = 0; i < nAttacks; i++)
    {
        int nBonus = nBAB - (i * 5) + nStr + nPenalty;

        if(i > 0)
        {
            sList += "\n";
        }

        sList += "Atak " + IntToString(i + 1) + ": " + IntToString(nBonus);
    }

    return sList;
}

string AIAttackBuildExtraAttackList(object oPC)
{
    int nBAB = GetBaseAttackBonus(oPC);
    int nAttacks = (nBAB + 4) / 5;

    if(nAttacks <= 1)
    {
        return "Brak dodatkowych ataków z BAB.";
    }

    string sList = "";
    int i;
    for(i = 1; i < nAttacks; i++)
    {
        if(i > 1)
        {
            sList += "\n";
        }

        sList += "Extra atak " + IntToString(i) + ": -" + IntToString(i * 5) + " do trafienia";
    }

    return sList;
}

string AIAttackBuildDamageBonusList(object oPC, int nMode)
{
    int nStr = AIAttackGetStrengthMod(oPC);

    int nDmgFromStr = nStr;
    if(nMode == AI_HAND_OFF)
    {
        nDmgFromStr = nStr / 2;
    }

    string sList = "Modyfikator siły: " + IntToString(nDmgFromStr);

    if(GetHasFeat(FEAT_WEAPON_SPECIALIZATION, oPC))
    {
        sList += "\nSpecjalizacja broni: +2";
    }

    if(GetHasFeat(FEAT_EPIC_WEAPON_SPECIALIZATION, oPC))
    {
        sList += "\nEpicka specjalizacja: +4";
    }

    return sList;
}

void AIAttackApplyBinds(object oPC, int nToken, int nMode)
{
    object oMain = GetItemInSlot(INVENTORY_SLOT_RIGHTHAND, oPC);
    object oOff = GetItemInSlot(INVENTORY_SLOT_LEFTHAND, oPC);

    int bOffhandWeapon = AIAttackIsOffhandWeapon(oOff);

    NuiSetBind(oPC, nToken, AI_BIND_HAND_MODE, JsonInt(nMode));
    NuiSetBind(oPC, nToken, AI_BIND_MAIN_NAME,
        JsonString(AIAttackGetWeaponName(oMain, "Main hand / unarmed")));
    NuiSetBind(oPC, nToken, AI_BIND_OFF_NAME,
        JsonString(AIAttackGetWeaponName(oOff, "Offhand")));

    NuiSetBind(oPC, nToken, AI_BIND_MAIN_INFO, JsonString(AIAttackGetMainInfo(oPC)));
    NuiSetBind(oPC, nToken, AI_BIND_OFF_INFO, JsonString(AIAttackGetOffInfo(oPC)));

    NuiSetBind(oPC, nToken, AI_BIND_OFF_DISABLED, JsonBool(bOffhandWeapon));

    string sLabel = "Main hand";
    if(nMode == AI_HAND_OFF)
    {
        sLabel = "Offhand";
    }
    NuiSetBind(oPC, nToken, AI_BIND_HAND_LABEL, JsonString(sLabel));

    NuiSetBind(oPC, nToken, AI_BIND_EXTRA_INFO,
        JsonString("Wyliczenie extra ataków (na bazie BAB)"));
    NuiSetBind(oPC, nToken, AI_BIND_EXTRA_LIST,
        JsonString(AIAttackBuildExtraAttackList(oPC)));

    NuiSetBind(oPC, nToken, AI_BIND_ATTACK_BONUS_LIST,
        JsonString(AIAttackBuildAttackBonusList(oPC, nMode)));

    NuiSetBind(oPC, nToken, AI_BIND_DAMAGE_BONUS_LIST,
        JsonString(AIAttackBuildDamageBonusList(oPC, nMode)));

    NuiSetBind(oPC, nToken, AI_BIND_DMG_SUMMARY,
        JsonString("Obrażenia dla: " + sLabel));
}

json AIAttackHeaderRows()
{
    json jCol = JsonArray();

    json jTop = JsonArray();
    jTop = JsonArrayInsert(jTop, NuiLabel(NuiBind(AI_BIND_MAIN_NAME), NUI_HALIGN_LEFT, NUI_VALIGN_MIDDLE));
    jTop = JsonArrayInsert(jTop, NuiLabel(JsonString("label"), NUI_HALIGN_CENTER, NUI_VALIGN_MIDDLE));
    jCol = JsonArrayInsert(jCol, NuiRow(jTop));

    json jSecond = JsonArray();
    jSecond = JsonArrayInsert(jSecond, NuiLabel(JsonString("Informacja BAB"), NUI_HALIGN_LEFT, NUI_VALIGN_MIDDLE));
    jSecond = JsonArrayInsert(jSecond, NuiLabel(NuiBind(AI_BIND_MAIN_INFO), NUI_HALIGN_LEFT, NUI_VALIGN_MIDDLE));
    jSecond = JsonArrayInsert(jSecond, NuiLabel(JsonString("label"), NUI_HALIGN_RIGHT, NUI_VALIGN_MIDDLE));
    jCol = JsonArrayInsert(jCol, NuiRow(jSecond));

    return NuiCol(jCol);
}

json AIAttackExtraRows()
{
    json jCol = JsonArray();

    json jA = JsonArray();
    jA = JsonArrayInsert(jA, NuiLabel(NuiBind(AI_BIND_EXTRA_INFO), NUI_HALIGN_LEFT, NUI_VALIGN_MIDDLE));
    jA = JsonArrayInsert(jA, NuiLabel(JsonString("label"), NUI_HALIGN_RIGHT, NUI_VALIGN_MIDDLE));
    jCol = JsonArrayInsert(jCol, NuiRow(jA));

    json jB = JsonArray();
    jB = JsonArrayInsert(jB, NuiLabel(JsonString("Lista dodatkowych ataków:"), NUI_HALIGN_LEFT, NUI_VALIGN_TOP));
    jCol = JsonArrayInsert(jCol, NuiRow(jB));

    json jC = JsonArray();
    jC = JsonArrayInsert(jC, NuiLabel(JsonString("ikona"), NUI_HALIGN_LEFT, NUI_VALIGN_TOP));
    jC = JsonArrayInsert(jC, NuiLabel(NuiBind(AI_BIND_EXTRA_LIST), NUI_HALIGN_LEFT, NUI_VALIGN_TOP));
    jCol = JsonArrayInsert(jCol, NuiRow(jC));

    return NuiCol(jCol);
}

json AIAttackOffhandRows()
{
    json jCol = JsonArray();

    json jTop = JsonArray();
    jTop = JsonArrayInsert(jTop, NuiLabel(NuiBind(AI_BIND_OFF_NAME), NUI_HALIGN_LEFT, NUI_VALIGN_MIDDLE));
    jTop = JsonArrayInsert(jTop, NuiLabel(JsonString("label"), NUI_HALIGN_RIGHT, NUI_VALIGN_MIDDLE));
    jCol = JsonArrayInsert(jCol, NuiRow(jTop));

    json jSecond = JsonArray();
    jSecond = JsonArrayInsert(jSecond, NuiLabel(JsonString("Wyliczenie offhandu jeżeli jest broń"), NUI_HALIGN_LEFT, NUI_VALIGN_MIDDLE));
    jSecond = JsonArrayInsert(jSecond, NuiLabel(NuiBind(AI_BIND_OFF_INFO), NUI_HALIGN_LEFT, NUI_VALIGN_MIDDLE));
    jCol = JsonArrayInsert(jCol, NuiRow(jSecond));

    return NuiCol(jCol);
}

json AIAttackSwitchRow()
{
    json jRow = JsonArray();

    json jMain = NuiButton(JsonString("mainhand"));
    jMain = NuiId(jMain, AI_BTN_MAIN);
    jMain = NuiWidth(jMain, 180.0);
    jMain = NuiHeight(jMain, 45.0);

    json jOff = NuiButton(JsonString("offhand"));
    jOff = NuiId(jOff, AI_BTN_OFF);
    jOff = NuiWidth(jOff, 180.0);
    jOff = NuiHeight(jOff, 45.0);
    jOff = NuiEnabled(jOff, NuiBind(AI_BIND_OFF_DISABLED));

    jRow = JsonArrayInsert(jRow, jMain);
    jRow = JsonArrayInsert(jRow, jOff);
    jRow = JsonArrayInsert(jRow, NuiLabel(JsonString("disabled jeżeli nie jest broń"), NUI_HALIGN_LEFT, NUI_VALIGN_MIDDLE));

    return NuiRow(jRow);
}

json AIAttackDamageSection()
{
    json jCol = JsonArray();

    json jHead = JsonArray();
    jHead = JsonArrayInsert(jHead, NuiLabel(JsonString("Obrażenia:"), NUI_HALIGN_LEFT, NUI_VALIGN_MIDDLE));
    jHead = JsonArrayInsert(jHead, NuiLabel(NuiBind(AI_BIND_DMG_SUMMARY), NUI_HALIGN_LEFT, NUI_VALIGN_MIDDLE));
    jHead = JsonArrayInsert(jHead, NuiLabel(JsonString("label"), NUI_HALIGN_RIGHT, NUI_VALIGN_MIDDLE));
    jCol = JsonArrayInsert(jCol, NuiRow(jHead));

    json jAtt = JsonArray();
    jAtt = JsonArrayInsert(jAtt, NuiLabel(JsonString("Lista bonusów ataku:"), NUI_HALIGN_LEFT, NUI_VALIGN_TOP));
    jAtt = JsonArrayInsert(jAtt, NuiLabel(NuiBind(AI_BIND_ATTACK_BONUS_LIST), NUI_HALIGN_LEFT, NUI_VALIGN_TOP));
    jCol = JsonArrayInsert(jCol, NuiRow(jAtt));

    json jDmg = JsonArray();
    jDmg = JsonArrayInsert(jDmg, NuiLabel(JsonString("Lista bonusów obrażeń:"), NUI_HALIGN_LEFT, NUI_VALIGN_TOP));
    jDmg = JsonArrayInsert(jDmg, NuiLabel(NuiBind(AI_BIND_DAMAGE_BONUS_LIST), NUI_HALIGN_LEFT, NUI_VALIGN_TOP));
    jCol = JsonArrayInsert(jCol, NuiRow(jDmg));

    return NuiCol(jCol);
}

void CreateAIAttackWindow(object oPC)
{
    int nToken = NuiFindWindow(oPC, AI_ATTACK_WINDOW);
    if(nToken > 0)
    {
        NuiDestroy(oPC, nToken);
    }

    json jCol = JsonArray();
    jCol = JsonArrayInsert(jCol, AIAttackHeaderRows());
    jCol = JsonArrayInsert(jCol, NuiSpacer());
    jCol = JsonArrayInsert(jCol, AIAttackExtraRows());
    jCol = JsonArrayInsert(jCol, NuiSpacer());
    jCol = JsonArrayInsert(jCol, AIAttackOffhandRows());
    jCol = JsonArrayInsert(jCol, NuiSpacer());
    jCol = JsonArrayInsert(jCol, AIAttackSwitchRow());
    jCol = JsonArrayInsert(jCol, NuiSpacer());
    jCol = JsonArrayInsert(jCol, AIAttackDamageSection());

    json jRoot = NuiCol(jCol);

    json jNui = NuiWindow(
        jRoot,
        NuiBind(WINDOW_TITLE),
        NuiBind(WINDOW_GEOMETRY),
        NuiBind(WINDOW_RESIZABLE),
        JsonBool(TRUE),
        NuiBind(WINDOW_CLOSABLE),
        NuiBind(WINDOW_TRANSPARENT),
        NuiBind(WINDOW_BORDER));

    nToken = NuiCreate(oPC, jNui, AI_ATTACK_WINDOW);

    NuiSetBind(oPC, nToken, WINDOW_TITLE, JsonString("Attack View"));
    NuiSetBind(oPC, nToken, WINDOW_GEOMETRY, NuiRect(80.0, 40.0, 1250.0, 900.0));
    NuiSetBind(oPC, nToken, WINDOW_RESIZABLE, JsonBool(FALSE));
    NuiSetBind(oPC, nToken, WINDOW_CLOSABLE, JsonBool(TRUE));
    NuiSetBind(oPC, nToken, WINDOW_TRANSPARENT, JsonBool(FALSE));
    NuiSetBind(oPC, nToken, WINDOW_BORDER, JsonBool(TRUE));

    NuiSetGroupLayout(oPC, nToken, AI_ATTACK_WINDOW, jRoot);

    NuiSetBind(oPC, nToken, AI_BIND_HAND_MODE, JsonInt(AI_HAND_MAIN));
    AIAttackApplyBinds(oPC, nToken, AI_HAND_MAIN);

    SetEventScript(oPC, EVENT_SCRIPT_NUI, AI_ATTACK_EVENT_SCRIPT);
}
