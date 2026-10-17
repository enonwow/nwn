#include "lib_msk"

// ----------------------------------------------------------------
// Main NUI event handler
// ----------------------------------------------------------------

void main()
{
    object oPC    = NuiGetEventPlayer();
    int    nToken = NuiGetEventWindow();
    string sEvent = NuiGetEventType();
    string sElem  = NuiGetEventElement();
    int    nIdx   = NuiGetEventArrayIndex();

    if(nToken != NuiFindWindow(oPC, MSK_WINDOW)) return;

    if(sEvent == EVENT_TYPE_CLOSE)
        return;

    if(sEvent != EVENT_TYPE_CLICK && sEvent != EVENT_TYPE_MOUSEDOWN)
        return;

    // ---- Close ----
    if(sElem == MSK_BTN_CLOSE)
    {
        NuiDestroy(oPC, nToken);
        return;
    }

    // ---- Voluntary removal ----
    if(sElem == MSK_BTN_REMOVE)
    {
        MskDeactivate(oPC, nToken);
        return;
    }

    // ---- Wear mask (row button) ----
    if(sElem == MSK_BTN_WEAR)
    {
        json jOwned = MskGetOwnedMasks(oPC);
        if(nIdx < 0 || nIdx >= JsonGetLength(jOwned)) return;

        json jRow   = JsonArrayGet(jOwned, nIdx);
        int nBurned = JsonGetInt(JsonObjectGet(jRow, "burned"));
        if(nBurned)
        {
            SendMessageToPC(oPC, "[Masquerade] Ta maska jest zniszczona — nie możesz jej ponownie założyć.");
            return;
        }

        int nMaskId = JsonGetInt(JsonObjectGet(jRow, "mask_id"));
        MskActivate(oPC, nToken, nMaskId);
        return;
    }
}
