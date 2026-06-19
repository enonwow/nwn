#include "lib_scar"

void main()
{
    object oPC    = NuiGetEventPlayer();
    int    nToken = NuiGetEventWindow();
    string sEvent = NuiGetEventType();
    string sElem  = NuiGetEventElement();
    int    nIdx   = NuiGetEventArrayIndex();

    if(nToken != NuiFindWindow(oPC, SCAR_WINDOW)) return;

    if(sEvent == EVENT_TYPE_CLOSE)
    {
        DeleteLocalInt(oPC, SCAR_LVAR_SEL_ID);
        return;
    }

    if(sEvent == EVENT_TYPE_CLICK)
    {
        if(sElem == SCAR_BTN_CLOSE)
        {
            NuiDestroy(oPC, nToken);
            return;
        }

        if(sElem == SCAR_BTN_TREAT)
        {
            int nId = GetLocalInt(oPC, SCAR_LVAR_SEL_ID);
            if(nId > 0)
                ScarTreatWound(oPC, nId, nToken);
            return;
        }
    }

    if(sEvent == EVENT_TYPE_MOUSEDOWN && sElem == SCAR_BTN_ROW)
    {
        json jWounds = ScarDbGetWounds(oPC);
        int  nCount  = JsonGetLength(jWounds);
        if(nIdx < 0 || nIdx >= nCount) return;

        json jRow = JsonArrayGet(jWounds, nIdx);
        int  nId  = JsonGetInt(JsonObjectGet(jRow, "id"));

        SetLocalInt(oPC, SCAR_LVAR_SEL_ID, nId);

        json jEncs = JsonArray();
        int i;
        for(i = 0; i < nCount; i++)
            jEncs = JsonArrayInsert(jEncs, JsonBool(i == nIdx));
        NuiSetBind(oPC, nToken, SCAR_BIND_ROW_ENC, jEncs);

        FeedScarDetail(oPC, nToken, nId);
        return;
    }
}
