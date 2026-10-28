#include "lib_cvoid"

void main()
{
    object oPC    = NuiGetEventPlayer();
    int    nToken = NuiGetEventWindow();
    string sEvent = NuiGetEventType();
    string sElem  = NuiGetEventElement();
    int    nIdx   = NuiGetEventArrayIndex();

    if(nToken != NuiFindWindow(oPC, CVOID_WINDOW)) return;

    if(sEvent == EVENT_TYPE_CLOSE)
    {
        DeleteLocalInt(oPC, CVOID_LVAR_SEL);
        return;
    }

    if(sEvent == EVENT_TYPE_MOUSEDOWN && sElem == CVOID_BTN_ROW)
    {
        if(nIdx < 0 || nIdx >= CVOID_COUNT) return;

        SetLocalInt(oPC, CVOID_LVAR_SEL, nIdx);
        CvoidFeedList(oPC, nToken);
        CvoidFeedDetail(oPC, nToken, nIdx);
        return;
    }

    if(sEvent == EVENT_TYPE_CLICK)
    {
        if(sElem == CVOID_BTN_PERFORM)
        {
            int nSel = GetLocalInt(oPC, CVOID_LVAR_SEL);
            CvoidPerform(oPC, nToken, nSel);
            return;
        }
        if(sElem == CVOID_BTN_PURIFY)
        {
            CvoidPurify(oPC, nToken);
            return;
        }
    }
}
