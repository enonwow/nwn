#include "lib_dur"

void main()
{
    object oPC    = NuiGetEventPlayer();
    int    nToken = NuiGetEventWindow();
    string sEvent = NuiGetEventType();
    string sElem  = NuiGetEventElement();
    int    nIdx   = NuiGetEventArrayIndex();

    if(nToken != NuiFindWindow(oPC, DUR_WINDOW)) return;

    if(sEvent == EVENT_TYPE_CLOSE)
    {
        DeleteLocalInt(oPC, DUR_LVAR_SEL);
        DeleteLocalInt(oPC, DUR_LVAR_FORGE);
        return;
    }

    if(sEvent == EVENT_TYPE_CLICK)
    {
        if(sElem == DUR_BTN_CLOSE)
        {
            NuiDestroy(oPC, nToken);
            return;
        }

        if(sElem == DUR_BTN_REPAIR)
        {
            int nSel = GetLocalInt(oPC, DUR_LVAR_SEL);
            DurDoRepair(oPC, nToken, nSel, FALSE);
            return;
        }

        if(sElem == DUR_BTN_FIELD)
        {
            int nSel = GetLocalInt(oPC, DUR_LVAR_SEL);
            DurDoRepair(oPC, nToken, nSel, TRUE);
            return;
        }

        if(sElem == DUR_BTN_REPALL)
        {
            DurDoRepairAll(oPC, nToken);
            return;
        }
    }

    if(sEvent == EVENT_TYPE_MOUSEDOWN && sElem == DUR_BTN_ROW)
    {
        if(nIdx < 0 || nIdx >= DUR_SLOT_COUNT) return;

        SetLocalInt(oPC, DUR_LVAR_SEL, nIdx);

        // Update row highlight array
        json jEncs = JsonArray();
        int i;
        for(i = 0; i < DUR_SLOT_COUNT; i++)
            jEncs = JsonArrayInsert(jEncs, JsonBool(i == nIdx));
        NuiSetBind(oPC, nToken, DUR_BIND_ROW_ENC, jEncs);

        DurFeedDetail(oPC, nToken, nIdx);
        return;
    }
}
