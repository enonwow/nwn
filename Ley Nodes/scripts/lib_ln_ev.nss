#include "lib_ln"

// Main NUI event handler — set as the event script on NuiCreate.
void main()
{
    object oPC    = NuiGetEventPlayer();
    int    nToken = NuiGetEventWindow();
    string sEvent = NuiGetEventType();
    string sElem  = NuiGetEventElement();
    int    nIdx   = NuiGetEventArrayIndex();

    if(nToken != NuiFindWindow(oPC, LN_WINDOW)) return;

    if(sEvent == EVENT_TYPE_CLOSE)
        return; // local vars persist for next open

    // Row click — select a node from the attunements list
    if(sEvent == EVENT_TYPE_MOUSEDOWN && sElem == LN_BTN_ROW)
    {
        json jRows = LnGetAttunements(oPC);
        if(nIdx < 0 || nIdx >= JsonGetLength(jRows)) return;

        json   jRow  = JsonArrayGet(jRows, nIdx);
        string sTag  = JsonGetString(JsonObjectGet(jRow, "tag"));
        SetLocalString(oPC, LN_LVAR_SEL_TAG, sTag);

        // Update highlights
        int    nCount = JsonGetLength(jRows);
        json   jEncs  = JsonArray();
        int    i;
        for(i = 0; i < nCount; i++)
            jEncs = JsonArrayInsert(jEncs, JsonBool(i == nIdx));
        NuiSetBind(oPC, nToken, LN_BIND_ROW_ENC, jEncs);

        LnFeedDetail(oPC, nToken, sTag);
        return;
    }

    if(sEvent == EVENT_TYPE_CLICK)
    {
        if(sElem == LN_BTN_CLOSE)
        {
            NuiDestroy(oPC, nToken);
            return;
        }
        if(sElem == LN_BTN_SIPHON)
        {
            LnSiphonPower(oPC, nToken);
            return;
        }
        if(sElem == LN_BTN_ATTUNE)
        {
            LnAttuneSelected(oPC, nToken);
            return;
        }
        if(sElem == LN_BTN_RELEASE)
        {
            LnReleaseAttunement(oPC, nToken);
            return;
        }
    }
}
