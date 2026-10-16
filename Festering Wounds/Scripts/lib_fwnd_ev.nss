#include "lib_fwnd"

void main()
{
    object oPC    = NuiGetEventPlayer();
    int    nToken = NuiGetEventWindow();
    string sEvent = NuiGetEventType();
    string sElem  = NuiGetEventElement();
    int    nIdx   = NuiGetEventArrayIndex();

    if(nToken != NuiFindWindow(oPC, FWND_WINDOW)) return;

    if(sEvent == EVENT_TYPE_CLOSE)
    {
        DeleteLocalInt(oPC, FWND_LVAR_SEL_ID);
        return;
    }

    if(sEvent == EVENT_TYPE_CLICK)
    {
        if(sElem == FWND_BTN_CLOSE)
        {
            NuiDestroy(oPC, nToken);
            return;
        }

        if(sElem == FWND_BTN_BACK)
        {
            FwndSwapToList(oPC, nToken);
            return;
        }

        if(sElem == FWND_BTN_TREAT)
        {
            int nSelId = GetLocalInt(oPC, FWND_LVAR_SEL_ID);
            if(nSelId <= 0) return;

            FwndApplyTreatment(oPC, nSelId);

            // If the wound was fully healed, go back to list; otherwise refresh detail.
            json jW = FwndGetWound(nSelId);
            if(JsonGetType(jW) == JSON_TYPE_NULL)
                FwndSwapToList(oPC, nToken);
            else
                FwndFeedDetail(oPC, nToken, nSelId);

            return;
        }
    }

    if(sEvent == EVENT_TYPE_MOUSEDOWN)
    {
        if(sElem == FWND_BTN_ROW)
        {
            json jWounds = FwndGetWounds(oPC);
            if(nIdx < 0 || nIdx >= JsonGetLength(jWounds)) return;

            json jW  = JsonArrayGet(jWounds, nIdx);
            int  nId = JsonGetInt(JsonObjectGet(jW, "id"));

            // Highlight selected row before switching view
            int nCount = JsonGetLength(jWounds);
            json jEncs = JsonArray();
            int i;
            for(i = 0; i < nCount; i++)
                jEncs = JsonArrayInsert(jEncs, JsonBool(i == nIdx));
            NuiSetBind(oPC, nToken, FWND_BIND_LIST_ENC, jEncs);

            FwndSwapToDetail(oPC, nToken, nId);
            return;
        }
    }
}
