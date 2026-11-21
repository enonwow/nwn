#include "lib_vamp"

// NUI event handler assigned to VAMP_WINDOW.
// All vampire UI interactions are routed here.

void main()
{
    object oPC    = NuiGetEventPlayer();
    int    nToken = NuiGetEventWindow();
    string sEvent = NuiGetEventType();
    string sElem  = NuiGetEventElement();

    if(nToken != NuiFindWindow(oPC, VAMP_WINDOW)) return;

    // ---- Window closed (e.g. escape key) ----
    if(sEvent == EVENT_TYPE_CLOSE)
    {
        // Clear targeting flag so Feed button is not stuck
        SetLocalInt(oPC, VAMP_LVAR_IS_FEEDING, 0);
        return;
    }

    if(sEvent != EVENT_TYPE_CLICK) return;

    // ---- [X] close button ----
    if(sElem == VAMP_BTN_CLOSE)
    {
        SetLocalInt(oPC, VAMP_LVAR_IS_FEEDING, 0);
        NuiDestroy(oPC, nToken);
        return;
    }

    // ---- Feed button ----
    if(sElem == VAMP_BTN_FEED)
    {
        int nBlood = VampGetBlood(oPC);
        if(nBlood >= 100)
        {
            SendMessageToPC(oPC, "[Wampiryzm] Jesteś już nasycony — krew kapie z ust.");
            return;
        }
        if(VampGetTier(nBlood) == 0)
        {
            SendMessageToPC(oPC, "[Wampiryzm] Jesteś zbyt osłabiony, by samemu polować.");
            return;
        }

        SetLocalInt(oPC, VAMP_LVAR_IS_FEEDING, 1);
        // Disable button while targeting mode is active
        NuiSetBind(oPC, nToken, VAMP_BIND_FEED_ENA, JsonBool(FALSE));
        EnterTargetingMode(oPC, OBJECT_TYPE_CREATURE);
        SendMessageToPC(oPC, "[Wampiryzm] Wybierz ofiarę, z której wysysasz krew...");
        return;
    }

    // ---- Cure button ----
    if(sElem == VAMP_BTN_CURE)
    {
        object oItem = GetItemPossessedBy(oPC, VAMP_CURE_ITEM_TAG);
        if(!GetIsObjectValid(oItem))
        {
            SendMessageToPC(oPC, "[Wampiryzm] Nie posiadasz Krwi Świętej.");
            VampUpdateUI(oPC, nToken);
            return;
        }
        VampIncrementCureAttempts(oPC);
        DestroyObject(oItem);
        VampCurePC(oPC);
        return;
    }
}
