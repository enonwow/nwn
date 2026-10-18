#include "lib_sth"

void StrongholdHandleUpgrade(object oPC, int nToken, int nBldId)
{
    string sUuid = GetObjectUUID(oPC);

    StrongholdCheckUpgrades(oPC);

    int nLevel  = StrongholdGetLevel(sUuid, nBldId);
    int nFinish = StrongholdGetUpgradeFinish(sUuid, nBldId);
    int nNow    = StrongholdNow();

    if(nFinish > 0 && nNow < nFinish)
    {
        SendMessageToPC(oPC, "[Twierdza] Ten budynek jest już w trakcie rozbudowy.");
        return;
    }

    if(nLevel >= STH_MAX_LEVEL)
    {
        SendMessageToPC(oPC, "[Twierdza] Ten budynek jest na maksymalnym poziomie.");
        return;
    }

    int nTargetLvl = nLevel + 1;
    int nCost      = StrongholdUpgradeCost(nTargetLvl);
    if(GetGold(oPC) < nCost)
    {
        SendMessageToPC(oPC, "[Twierdza] Za mało złota. Potrzebujesz " + IntToString(nCost) + " szt.");
        return;
    }

    float fDelay = StrongholdUpgradeDelay(nTargetLvl);
    int nFinishTs = nNow + FloatToInt(fDelay);

    AssignCommand(oPC, TakeGoldFromCreature(nCost, oPC, TRUE));
    StrongholdStartUpgrade(sUuid, nBldId, nFinishTs);

    string sMsg = "[Twierdza] Rozbudowa " + StrongholdBuildingName(nBldId)
        + " do poziomu " + IntToString(nTargetLvl) + " rozpoczęta. Koszt: "
        + IntToString(nCost) + " szt. złota.";
    SendMessageToPC(oPC, sMsg);

    // Schedule server-side check for when the upgrade finishes
    DelayCommand(fDelay, StrongholdCheckUpgrades(oPC));

    StrongholdFeedGrid(oPC, nToken);
    StrongholdFeedDetail(oPC, nToken, nBldId);
}

void StrongholdHandleCancel(object oPC, int nToken, int nBldId)
{
    string sUuid = GetObjectUUID(oPC);

    int nLevel  = StrongholdGetLevel(sUuid, nBldId);
    int nFinish = StrongholdGetUpgradeFinish(sUuid, nBldId);
    int nNow    = StrongholdNow();

    if(nFinish == 0 || nNow >= nFinish)
    {
        SendMessageToPC(oPC, "[Twierdza] Brak aktywnej rozbudowy do anulowania.");
        StrongholdCheckUpgrades(oPC);
        StrongholdFeedGrid(oPC, nToken);
        StrongholdFeedDetail(oPC, nToken, nBldId);
        return;
    }

    int nTargetLvl = nLevel + 1;
    int nRefund    = StrongholdUpgradeCost(nTargetLvl) / 2;

    StrongholdCancelUpgrade(sUuid, nBldId);
    GiveGoldToCreature(oPC, nRefund);

    string sMsg = "[Twierdza] Rozbudowa " + StrongholdBuildingName(nBldId)
        + " anulowana. Zwrot: " + IntToString(nRefund) + " szt. złota.";
    SendMessageToPC(oPC, sMsg);

    StrongholdFeedGrid(oPC, nToken);
    StrongholdFeedDetail(oPC, nToken, nBldId);
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

    if(nToken != NuiFindWindow(oPC, STH_WINDOW)) return;

    if(sEvent == EVENT_TYPE_CLOSE)
    {
        DeleteLocalInt(oPC, STH_LVAR_SEL);
        DeleteLocalInt(oPC, "STH_HAS_SEL");
        return;
    }

    if(sEvent == EVENT_TYPE_CLICK || sEvent == EVENT_TYPE_MOUSEDOWN)
    {
        if(sElem == STH_BTN_CLOSE)
        {
            NuiDestroy(oPC, nToken);
            return;
        }

        if(sElem == STH_BTN_UPGRADE)
        {
            int nSel = GetLocalInt(oPC, STH_LVAR_SEL);
            if(nSel >= 0)
                StrongholdHandleUpgrade(oPC, nToken, nSel);
            return;
        }

        if(sElem == STH_BTN_CANCEL)
        {
            int nSel = GetLocalInt(oPC, STH_LVAR_SEL);
            if(nSel >= 0)
                StrongholdHandleCancel(oPC, nToken, nSel);
            return;
        }

        // Building cell clicks
        int i;
        for(i = 0; i < STH_BLD_COUNT; i++)
        {
            if(sElem == STH_BTN_BLD + IntToString(i))
            {
                int nPrev = GetLocalInt(oPC, STH_LVAR_SEL);
                int bHad  = GetLocalInt(oPC, "STH_HAS_SEL");
                if(bHad && nPrev == i)
                {
                    // Deselect on second click
                    SetLocalInt(oPC, STH_LVAR_SEL, -1);
                    DeleteLocalInt(oPC, "STH_HAS_SEL");
                    StrongholdFeedGrid(oPC, nToken);
                    StrongholdFeedDetail(oPC, nToken, -1);
                }
                else
                {
                    SetLocalInt(oPC, STH_LVAR_SEL, i);
                    SetLocalInt(oPC, "STH_HAS_SEL", 1);
                    StrongholdCheckUpgrades(oPC);
                    StrongholdFeedGrid(oPC, nToken);
                    StrongholdFeedDetail(oPC, nToken, i);
                }
                return;
            }
        }
    }
}
