#include "lib_mit"

void main()
{
    object oPC    = NuiGetEventPlayer();
    int    nToken = NuiGetEventWindow();
    string sEvent = NuiGetEventType();
    string sElem  = NuiGetEventElement();
    int    nIdx   = NuiGetEventArrayIndex();

    if(nToken != NuiFindWindow(oPC, MIT_WINDOW)) return;

    if(sEvent == EVENT_TYPE_CLOSE)
    {
        DeleteLocalInt(oPC, MIT_LVAR_SEL);
        return;
    }

    // Row click: select a poison and show its detail
    if(sEvent == EVENT_TYPE_MOUSEDOWN && sElem == MIT_BTN_ROW)
    {
        if(nIdx < 0 || nIdx >= MIT_POISON_COUNT) return;

        SetLocalInt(oPC, MIT_LVAR_SEL, nIdx);

        // Update encouraged (selected) state in list
        json jEncs = JsonArray();
        int i;
        for(i = 0; i < MIT_POISON_COUNT; i++)
            jEncs = JsonArrayInsert(jEncs, JsonBool(i == nIdx));
        NuiSetBind(oPC, nToken, MIT_BIND_ROW_ENC, jEncs);

        MitFeedDetail(oPC, nToken, nIdx);
        return;
    }

    if(sEvent == EVENT_TYPE_CLICK)
    {
        if(sElem == MIT_BTN_CLOSE)
        {
            NuiDestroy(oPC, nToken);
            return;
        }

        int nSel = GetLocalInt(oPC, MIT_LVAR_SEL);

        if(sElem == MIT_BTN_DOSE)
        {
            MitTakeDose(oPC, nToken, nSel);
            return;
        }

        if(sElem == MIT_BTN_ANTIDOTE)
        {
            MitCraftAntidote(oPC, nToken, nSel);
            return;
        }
    }
}
