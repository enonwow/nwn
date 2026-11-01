#include "lib_phy"

// ----------------------------------------------------------------
// Action handlers
// ----------------------------------------------------------------

void PhyHandleCreate(object oPC, int nToken)
{
    int nCost = PHY_CREATE_GOLD_COST;
    if(GetGold(oPC) < nCost)
    {
        SendMessageToPC(oPC,
            "[Filakteria] Potrzebujesz " + IntToString(nCost) + " sztuk złota.");
        return;
    }

    AssignCommand(oPC, TakeGoldFromCreature(nCost, oPC, TRUE));
    PhyCreateRecord(oPC);

    FloatingTextStringOnCreature(
        "Filakteria zostaje skuta w ciemności...", oPC, FALSE);
    SendMessageToPC(oPC,
        "[Filakteria] Naczynie duszy zostało stworzone. "
        + "Zakotwicz je w wybranej lokacji.");

    PhyFeedStatus(oPC, nToken);
}

void PhyHandleAnchor(object oPC, int nToken)
{
    json jRec = PhyGetRecord(oPC);
    if(JsonGetType(jRec) == JSON_TYPE_NULL || !JsonGetInt(JsonObjectGet(jRec, "is_active")))
    {
        SendMessageToPC(oPC, "[Filakteria] Brak aktywnej filakterii.");
        return;
    }

    object oArea    = GetArea(oPC);
    vector vPos     = GetPosition(oPC);
    float  fFacing  = GetFacing(oPC);

    PhyAnchorLocation(oPC, oArea, vPos.x, vPos.y, vPos.z, fFacing);

    FloatingTextStringOnCreature(
        "Dusza wgryza się w tę ziemię...", oPC, FALSE);
    SendMessageToPC(oPC,
        "[Filakteria] Zakotwiczono w: " + GetName(oArea)
        + ". Tu zmartwychwstaniesz.");

    PhyFeedStatus(oPC, nToken);
}

void PhyHandleEmpower(object oPC, int nToken)
{
    json jRec = PhyGetRecord(oPC);
    if(JsonGetType(jRec) == JSON_TYPE_NULL || !JsonGetInt(JsonObjectGet(jRec, "is_active")))
    {
        SendMessageToPC(oPC, "[Filakteria] Brak aktywnej filakterii.");
        return;
    }

    int nCharges = JsonGetInt(JsonObjectGet(jRec, "charges"));
    int nMax     = JsonGetInt(JsonObjectGet(jRec, "max_charges"));
    if(nCharges >= nMax)
    {
        SendMessageToPC(oPC, "[Filakteria] Filakteria jest już w pełni naładowana.");
        return;
    }

    int nCost = PHY_EMPOWER_GOLD_COST;
    if(GetGold(oPC) < nCost)
    {
        SendMessageToPC(oPC,
            "[Filakteria] Potrzebujesz " + IntToString(nCost) + " sztuk złota.");
        return;
    }

    AssignCommand(oPC, TakeGoldFromCreature(nCost, oPC, TRUE));
    PhyAddCharge(oPC, 1);

    SendMessageToPC(oPC,
        "[Filakteria] Ładunek dodany. Złoto spływa po kamieniu...");

    PhyFeedStatus(oPC, nToken);
}

void PhyHandleShatterConfirm(object oPC)
{
    json jRec = PhyGetRecord(oPC);
    if(JsonGetType(jRec) == JSON_TYPE_NULL)
    {
        SendMessageToPC(oPC, "[Filakteria] Brak filakterii do rozbicia.");
        return;
    }

    PhyDestroyRecord(oPC);
    PhyApplyShatterBuff(oPC);

    SendMessageToPC(oPC,
        "[Filakteria] Naczynie duszy zostało rozbite. "
        + "Uwolniona energia wzmacnia cię na godzinę.");

    int nMainToken = NuiFindWindow(oPC, PHY_WINDOW);
    if(nMainToken != 0)
        PhyFeedStatus(oPC, nMainToken);
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

    // ---- Shatter confirmation popup ----
    if(nToken == NuiFindWindow(oPC, PHY_WIN_CONFIRM))
    {
        if(sEvent == EVENT_TYPE_CLICK)
        {
            if(sElem == PHY_BTN_CONF_YES)
            {
                NuiDestroy(oPC, nToken);
                PhyHandleShatterConfirm(oPC);
            }
            else if(sElem == PHY_BTN_CONF_NO)
            {
                NuiDestroy(oPC, nToken);
            }
        }
        return;
    }

    if(nToken != NuiFindWindow(oPC, PHY_WINDOW)) return;

    if(sEvent == EVENT_TYPE_CLOSE)
    {
        DeleteLocalString(oPC, PHY_LVAR_VIEW);
        return;
    }

    if(sEvent != EVENT_TYPE_CLICK) return;

    if(sElem == PHY_BTN_CLOSE)
    {
        NuiDestroy(oPC, nToken);
        return;
    }

    if(sElem == PHY_BTN_TAB_STATUS)
    {
        PhySwapToStatus(oPC, nToken);
        return;
    }

    if(sElem == PHY_BTN_TAB_HISTORY)
    {
        PhySwapToHistory(oPC, nToken);
        return;
    }

    if(sElem == PHY_BTN_CREATE)
    {
        PhyHandleCreate(oPC, nToken);
        return;
    }

    if(sElem == PHY_BTN_ANCHOR)
    {
        PhyHandleAnchor(oPC, nToken);
        return;
    }

    if(sElem == PHY_BTN_EMPOWER)
    {
        PhyHandleEmpower(oPC, nToken);
        return;
    }

    if(sElem == PHY_BTN_SHATTER)
    {
        CreatePhyShatterConfirm(oPC);
        return;
    }
}
