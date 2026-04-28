// lib_hench_cmd_ev.nss
// Event handler for henchman AI control window (lib_hench_cmd).
#include "lib_hench_cmd"

void main()
{
    object oPC    = NuiGetEventPlayer();
    int    nToken = NuiGetEventWindow();
    string sEvent = NuiGetEventType();
    string sElem  = NuiGetEventElement();

    if(sEvent != "click") return;

    object oHench = GetHenchman(oPC);
    if(!GetIsObjectValid(oHench) && sElem != HCMD_BTN_SAVE) return;

    if(sElem == HCMD_BTN_FOLLOW)
    {
        HenchCmdFollow(oPC, oHench);
        return;
    }

    if(sElem == HCMD_BTN_STAND)
    {
        HenchCmdStand(oHench);
        return;
    }

    if(sElem == HCMD_BTN_GUARD)
    {
        HenchCmdGuard(oPC, oHench);
        return;
    }

    if(sElem == HCMD_BTN_ATTACK)
    {
        HenchCmdAttackNearest(oPC, oHench);
        return;
    }

    if(sElem == HCMD_BTN_SUMMON)
    {
        HenchCmdSummon(oPC, oHench);
        return;
    }

    if(sElem == HCMD_BTN_SAVE)
    {
        // Delay - without it, NuiGetBind returns position from a few seconds
        // earlier because the engine hasn't committed the bind after window drag.
        DelayCommand(HCMD_SAVE_DELAY, HenchCmdDoSavePosition(oPC, nToken));
        return;
    }
}
