// NUI event handler for the Forge Trial module.
// Registered as the group script on the FRG_WINDOW.

#include "lib_frg"

void main()
{
    object oPC    = NuiGetEventPlayer();
    int    nToken = NuiGetEventWindow();
    string sEvent = NuiGetEventType();
    string sElem  = NuiGetEventElement();

    if(NuiFindWindow(oPC, FRG_WINDOW) != nToken) return;

    if(sEvent == EVENT_TYPE_CLOSE)
    {
        FrgCleanup(oPC);
        return;
    }

    if(sEvent == EVENT_TYPE_CLICK)
    {
        if(sElem == FRG_BTN_CLOSE)
        {
            FrgCleanup(oPC);
            NuiDestroy(oPC, nToken);
            return;
        }

        if(sElem == FRG_BTN_STRIKE)
        {
            FrgExecuteStrike(oPC, nToken);
            return;
        }
    }

    // Slot group uses mousedown events
    if(sEvent == EVENT_TYPE_MOUSEDOWN)
    {
        int i;
        for(i = 0; i < FRG_SLOT_COUNT; i++)
        {
            if(sElem == FRG_BTN_SLOT + IntToString(i))
            {
                object oItem = FrgGetSlotItem(oPC, i);
                if(!GetIsObjectValid(oItem)) return;

                int nPrevSel = GetLocalInt(oPC, FRG_LVAR_SEL_SLOT);
                SetLocalInt(oPC, FRG_LVAR_SEL_SLOT, i);
                SetLocalInt(oPC, FRG_LVAR_STRIKES, FRG_STRIKES_MAX);

                FrgFeedSlots(oPC, nToken);
                FrgFeedSelectedItem(oPC, nToken);

                NuiSetBind(oPC, nToken, FRG_BIND_RESULT_TXT, JsonString("Wybierz chwilę ataku."));
                NuiSetBind(oPC, nToken, FRG_BIND_RESULT_COL, NuiColor(200, 200, 200));

                // Restart meter for the newly selected slot
                FrgStartMeter(oPC, nToken);
                return;
            }
        }
    }
}
