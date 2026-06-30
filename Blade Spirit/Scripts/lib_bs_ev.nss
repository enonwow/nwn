#include "lib_bs"

// ----------------------------------------------------------------
// Create window: handle class toggle buttons
// ----------------------------------------------------------------

void BsHandleClassToggle(object oPC, int nToken, int nClass)
{
    SetLocalInt(oPC, BS_LVAR_CREATE_CLASS, nClass);
    BsFeedCreateWindow(oPC, nToken);
}

// ----------------------------------------------------------------
// Create window: execute bind
// ----------------------------------------------------------------

void BsHandleBind(object oPC, int nToken)
{
    string sItemUUID = GetLocalString(oPC, BS_LVAR_CREATE_UUID);
    int    nClass    = GetLocalInt   (oPC, BS_LVAR_CREATE_CLASS);
    string sName     = JsonGetString (NuiGetBind(oPC, nToken, BS_BIND_C_SNAME));

    if(sName == "")
    {
        SendMessageToPC(oPC, "[Duch Ostrza] Podaj imię ducha.");
        return;
    }
    if(GetGold(oPC) < BS_BIND_COST)
    {
        SendMessageToPC(oPC, "[Duch Ostrza] Brakuje " + IntToString(BS_BIND_COST) + " sztuk złota.");
        return;
    }

    json jExisting = BsGetSpirit(sItemUUID);
    if(JsonGetType(jExisting) != JSON_TYPE_NULL)
    {
        SendMessageToPC(oPC, "[Duch Ostrza] To ostrze jest już nawiedzone.");
        NuiDestroy(oPC, nToken);
        return;
    }

    AssignCommand(oPC, TakeGoldFromCreature(BS_BIND_COST, oPC, TRUE));
    BsBindSpirit(sItemUUID, sName, nClass);

    // Immediately apply tier-0 bonuses
    BsApplyBonuses(oPC, sItemUUID, nClass, BS_TIER_DORMANT, FALSE);

    string sMsg = "[Duch Ostrza] Duch \"" + sName + "\" (" + BsSpiritClassName(nClass) +
                  ") związany z ostrzem. Pierwsze premie aktywne.";
    SendMessageToPC(oPC, sMsg);
    FloatingTextStringOnCreature(
        "Ostrze pulsuje zimnym blaskiem...\n\"" + BsGetWhisper(nClass, 0, 0) + "\"",
        oPC, FALSE);

    NuiDestroy(oPC, nToken);
    DeleteLocalString(oPC, BS_LVAR_CREATE_UUID);
    DeleteLocalInt   (oPC, BS_LVAR_CREATE_CLASS);
}

// ----------------------------------------------------------------
// Main window: commune
// ----------------------------------------------------------------

void BsHandleCommune(object oPC, int nToken, string sUUID)
{
    json jSpirit = BsGetSpirit(sUUID);
    if(JsonGetType(jSpirit) == JSON_TYPE_NULL) return;

    int    nClass  = JsonGetInt   (JsonObjectGet(jSpirit, "spirit_class"));
    int    nKills  = JsonGetInt   (JsonObjectGet(jSpirit, "kill_count"));
    int    nTier   = BsGetTier(nKills);
    string sName   = JsonGetString(JsonObjectGet(jSpirit, "spirit_name"));
    string sWisper = BsGetWhisper(nClass, nTier, nKills + d4(1));

    FloatingTextStringOnCreature("\"" + sWisper + "\" — " + sName, oPC, FALSE);
    SendMessageToPC(oPC, "[Duch Ostrza] " + sName + " szepcze: \"" + sWisper + "\"");

    BsFeedMainWindow(oPC, nToken);
}

// ----------------------------------------------------------------
// Main window: appease (pay gold to calm spirit)
// ----------------------------------------------------------------

void BsHandleAppease(object oPC, int nToken, string sUUID)
{
    if(GetGold(oPC) < BS_APPEASE_COST)
    {
        SendMessageToPC(oPC, "[Duch Ostrza] Potrzebujesz " +
            IntToString(BS_APPEASE_COST) + " sztuk złota, by ubłagać ducha.");
        return;
    }

    json jSpirit = BsGetSpirit(sUUID);
    if(BsIsAppeased(jSpirit))
    {
        SendMessageToPC(oPC, "[Duch Ostrza] Duch jest już uspokojony.");
        return;
    }

    AssignCommand(oPC, TakeGoldFromCreature(BS_APPEASE_COST, oPC, TRUE));

    // Re-apply bonuses with appease bonus
    int nClass = JsonGetInt(JsonObjectGet(jSpirit, "spirit_class"));
    int nKills = JsonGetInt(JsonObjectGet(jSpirit, "kill_count"));
    int nTier  = BsGetTier(nKills);

    BsRemoveBonuses(oPC, sUUID);
    BsSetAppeased(sUUID);
    BsApplyBonuses(oPC, sUUID, nClass, nTier, TRUE);

    FloatingTextStringOnCreature("Duch uspokaja się... premie wzrastają.", oPC, FALSE);
    SendMessageToPC(oPC, "[Duch Ostrza] Duch ubłagany. Wzmocnione premie aktywne przez 6 godzin.");

    BsFeedMainWindow(oPC, nToken);
}

// ----------------------------------------------------------------
// Main window: exorcise (remove spirit, requires cleric level)
// ----------------------------------------------------------------

void BsHandleExorcise(object oPC, int nToken, string sUUID)
{
    int nClericLevel = GetLevelByClass(CLASS_TYPE_CLERIC, oPC)
                     + GetLevelByClass(CLASS_TYPE_PALADIN, oPC);
    if(nClericLevel < BS_EXORCISE_MIN_CLERIC)
    {
        SendMessageToPC(oPC, "[Duch Ostrza] Wygnanie wymaga co najmniej " +
            IntToString(BS_EXORCISE_MIN_CLERIC) + " poziomów Kapłana lub Paladyna.");
        return;
    }

    json jSpirit = BsGetSpirit(sUUID);
    if(JsonGetType(jSpirit) == JSON_TYPE_NULL) return;

    string sName = JsonGetString(JsonObjectGet(jSpirit, "spirit_name"));

    BsRemoveBonuses(oPC, sUUID);
    BsDeleteSpirit(sUUID);

    FloatingTextStringOnCreature(
        "Duch \"" + sName + "\" zostaje wygnany. Ostrze milknie.", oPC, FALSE);
    SendMessageToPC(oPC, "[Duch Ostrza] Duch \"" + sName + "\" wygnany. Wszystkie premie usunięte.");

    NuiDestroy(oPC, nToken);
    DeleteLocalString(oPC, BS_LVAR_ACTIVE_UUID);
}

// ----------------------------------------------------------------
// Main window: manifest ability
// ----------------------------------------------------------------

void BsHandleManifest(object oPC, int nToken, string sUUID)
{
    json jSpirit = BsGetSpirit(sUUID);
    if(JsonGetType(jSpirit) == JSON_TYPE_NULL) return;

    int nKills = JsonGetInt(JsonObjectGet(jSpirit, "kill_count"));
    int nTier  = BsGetTier(nKills);

    if(nTier < BS_TIER_MANIFESTED)
    {
        SendMessageToPC(oPC, "[Duch Ostrza] Duch nie osiągnął jeszcze poziomu Zmaterializowany.");
        return;
    }
    if(BsManifestOnCooldown(jSpirit))
    {
        SendMessageToPC(oPC, "[Duch Ostrza] Manifestacja jest jeszcze na odnowieniu.");
        return;
    }

    int nClass = JsonGetInt(JsonObjectGet(jSpirit, "spirit_class"));
    NuiDestroy(oPC, nToken);

    BsDoManifest(oPC, sUUID, nClass);
}

// ----------------------------------------------------------------
// Main event handler
// ----------------------------------------------------------------

void main()
{
    object oPC    = NuiGetEventPlayer();
    int    nToken = NuiGetEventWindow();
    string sEvent = NuiGetEventType();
    string sElem  = NuiGetEventElement();

    // ---- Create window ----
    if(nToken == NuiFindWindow(oPC, BS_WIN_CREATE))
    {
        if(sEvent == EVENT_TYPE_CLOSE)
        {
            DeleteLocalString(oPC, BS_LVAR_CREATE_UUID);
            DeleteLocalInt   (oPC, BS_LVAR_CREATE_CLASS);
            return;
        }

        if(sEvent == EVENT_TYPE_WATCH && sElem == BS_BIND_C_SNAME)
        {
            BsFeedCreateWindow(oPC, nToken);
            return;
        }

        if(sEvent == EVENT_TYPE_CLICK)
        {
            if(sElem == BS_BTN_C_W) { BsHandleClassToggle(oPC, nToken, BS_CLASS_WARRIOR); return; }
            if(sElem == BS_BTN_C_M) { BsHandleClassToggle(oPC, nToken, BS_CLASS_MAGE);    return; }
            if(sElem == BS_BTN_C_R) { BsHandleClassToggle(oPC, nToken, BS_CLASS_ROGUE);   return; }
            if(sElem == BS_BTN_C_C) { BsHandleClassToggle(oPC, nToken, BS_CLASS_CLERIC);  return; }
            if(sElem == BS_BTN_C_BIND)   { BsHandleBind   (oPC, nToken); return; }
            if(sElem == BS_BTN_C_CANCEL) { NuiDestroy(oPC, nToken);       return; }
        }
        return;
    }

    // ---- Main spirit window ----
    if(nToken != NuiFindWindow(oPC, BS_WIN)) return;

    if(sEvent == EVENT_TYPE_CLOSE)
    {
        DeleteLocalString(oPC, BS_LVAR_ACTIVE_UUID);
        return;
    }

    if(sEvent == EVENT_TYPE_CLICK)
    {
        string sUUID = GetLocalString(oPC, BS_LVAR_ACTIVE_UUID);

        if(sElem == BS_BTN_CLOSE)
        {
            NuiDestroy(oPC, nToken);
            return;
        }
        if(sElem == BS_BTN_COMMUNE)
        {
            BsHandleCommune(oPC, nToken, sUUID);
            return;
        }
        if(sElem == BS_BTN_APPEASE)
        {
            BsHandleAppease(oPC, nToken, sUUID);
            return;
        }
        if(sElem == BS_BTN_EXORCISE)
        {
            BsHandleExorcise(oPC, nToken, sUUID);
            return;
        }
        if(sElem == BS_BTN_MANIFEST)
        {
            BsHandleManifest(oPC, nToken, sUUID);
            return;
        }
    }
}
