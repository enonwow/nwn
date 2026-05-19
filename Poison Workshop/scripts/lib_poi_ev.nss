#include "lib_poi"

void main()
{
    object oPC    = NuiGetEventPlayer();
    int    nToken = NuiGetEventWindow();
    string sEvent = NuiGetEventType();
    string sElem  = NuiGetEventElement();
    int    nIdx   = NuiGetEventArrayIndex();

    if(nToken != NuiFindWindow(oPC, POI_WINDOW)) return;

    if(sEvent == EVENT_TYPE_CLOSE)
    {
        // If player had pending targeting, cancel it cleanly
        DeleteLocalInt(oPC, POI_LVAR_PENDING);
        return;
    }

    if(sEvent == EVENT_TYPE_OPEN)
    {
        NuiSetBind(oPC, nToken, POI_BIND_TAB_WORK_ENC, JsonBool(TRUE));
        NuiSetBind(oPC, nToken, POI_BIND_TAB_ARS_ENC,  JsonBool(FALSE));
        FeedWorkshop(oPC, nToken);
        return;
    }

    if(sEvent != EVENT_TYPE_CLICK) return;

    if(sElem == POI_BTN_CLOSE)
    {
        NuiDestroy(oPC, nToken);
        return;
    }

    if(sElem == POI_BTN_TAB_WORKSHOP)
    {
        SwapToWorkshop(oPC, nToken);
        return;
    }

    if(sElem == POI_BTN_TAB_ARSENAL)
    {
        SwapToArsenal(oPC, nToken);
        return;
    }

    if(sElem == POI_BTN_CRAFT)
    {
        if(nIdx >= 0 && nIdx < POI_VIAL_COUNT)
            PoiCraft(oPC, nToken, nIdx);
        return;
    }

    if(sElem == POI_BTN_APPLY)
    {
        if(nIdx >= 0 && nIdx < POI_VIAL_COUNT)
            PoiApplyToWeapon(oPC, nIdx);
        return;
    }
}
