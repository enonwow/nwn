#include "lib_btrk"

void main()
{
    object oPC    = NuiGetEventPlayer();
    int    nToken = NuiGetEventWindow();
    string sEvent = NuiGetEventType();
    string sElem  = NuiGetEventElement();

    if(nToken != NuiFindWindow(oPC, BTRK_WINDOW)) return;

    if(sEvent == EVENT_TYPE_CLOSE)
    {
        // Tracking mode persists across window closes — intentional.
        // The PC must explicitly press Dezaktywuj to stop leaving trails.
        return;
    }

    if(sEvent != EVENT_TYPE_CLICK) return;

    if(sElem == BTRK_BTN_CLOSE)
    {
        NuiDestroy(oPC, nToken);
        return;
    }

    if(sElem == BTRK_BTN_ACTIVATE)
    {
        int bActive = GetLocalInt(oPC, BTRK_LVAR_ACTIVE);
        if(bActive)
        {
            DeleteLocalInt(oPC, BTRK_LVAR_ACTIVE);
            DeleteLocalInt(oPC, BTRK_LVAR_TRACKED_ID);
            SendMessageToPC(oPC, "[Tropiciel] Tryb tropienia dezaktywowany.");
            BtrkAddLog(oPC, "--- Tropienie wyłączone ---");
        }
        else
        {
            SetLocalInt(oPC, BTRK_LVAR_ACTIVE, 1);
            SendMessageToPC(oPC, "[Tropiciel] Tryb tropienia aktywowany. Pieczęć krwi pulsuje słabo...");
            BtrkAddLog(oPC, "--- Tropienie włączone ---");
        }
        BtrkFeedDisplay(oPC, nToken);
        return;
    }

    if(sElem == BTRK_BTN_SEARCH)
    {
        if(!GetLocalInt(oPC, BTRK_LVAR_ACTIVE))
        {
            SendMessageToPC(oPC, "[Tropiciel] Najpierw aktywuj tryb tropienia.");
            return;
        }
        BtrkSearchTrails(oPC, nToken);
        return;
    }

    if(sElem == BTRK_BTN_CLEAR_LOG)
    {
        DeleteLocalJson(oPC, BTRK_LVAR_LOG);
        BtrkFeedDisplay(oPC, nToken);
        return;
    }
}
