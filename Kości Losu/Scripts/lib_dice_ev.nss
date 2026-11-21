// lib_dice_ev.nss — NUI event handler for Kości Losu

#include "lib_dice"

void main()
{
    object oPC    = NuiGetEventPlayer();
    int    nToken = NuiGetEventWindow();
    string sEvent = NuiGetEventType();
    string sElem  = NuiGetEventElement();

    // ---- Leaderboard popup ----
    if(nToken == NuiFindWindow(oPC, DICE_WIN_LB))
    {
        if(sEvent == EVENT_TYPE_CLICK && sElem == DICE_BTN_LB_CLOSE)
            NuiDestroy(oPC, nToken);
        return;
    }

    if(nToken != NuiFindWindow(oPC, DICE_WINDOW)) return;

    if(sEvent == EVENT_TYPE_CLOSE)
    {
        DeleteLocalInt(oPC, DICE_LVAR_BUSY);
        return;
    }

    if(sEvent == EVENT_TYPE_WATCH && sElem == DICE_BIND_BET_TXT)
    {
        string sVal = JsonGetString(NuiGetBind(oPC, nToken, DICE_BIND_BET_TXT));
        int nVal    = StringToInt(sVal);
        int bBusy   = GetLocalInt(oPC, DICE_LVAR_BUSY);
        int bValid  = (!bBusy && nVal >= DICE_MIN_BET && nVal <= DICE_MAX_BET && GetGold(oPC) >= nVal);
        NuiSetBind(oPC, nToken, DICE_BIND_ROLL_ENA, JsonBool(bValid));
        return;
    }

    if(sEvent == EVENT_TYPE_CLICK)
    {
        if(sElem == DICE_BTN_CLOSE)
        {
            NuiDestroy(oPC, nToken);
            return;
        }

        if(sElem == DICE_BTN_ROLL)
        {
            DiceRollStart(oPC, nToken);
            return;
        }

        if(sElem == DICE_BTN_LB)
        {
            DiceOpenLeaderboard(oPC);
            return;
        }
    }
}
