#include "lib_crs"

void main()
{
    object oPC    = NuiGetEventPlayer();
    int    nToken = NuiGetEventWindow();
    string sEvent = NuiGetEventType();
    string sElem  = NuiGetEventElement();
    int    nIdx   = NuiGetEventArrayIndex();

    if(nToken != NuiFindWindow(oPC, CRS_WINDOW)) return;

    if(sEvent == EVENT_TYPE_CLOSE)
    {
        DeleteLocalJson(oPC, CRS_LVAR_CURSE_ROW);
        return;
    }

    if(sEvent == EVENT_TYPE_CLICK)
    {
        if(sElem == CRS_BTN_CLOSE)
        {
            NuiDestroy(oPC, nToken);
            return;
        }

        if(sElem == CRS_BTN_CLEANSE)
        {
            json jMap = GetLocalJson(oPC, CRS_LVAR_CURSE_ROW);
            if(JsonGetType(jMap) != JSON_TYPE_ARRAY) return;
            if(nIdx < 0 || nIdx >= JsonGetLength(jMap)) return;

            int nCurseId = JsonGetInt(JsonArrayGet(jMap, nIdx));
            CrsCleanse(oPC, nCurseId);
            return;
        }
    }
}
