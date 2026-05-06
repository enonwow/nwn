#include "lib_plg"

void main()
{
    object oPC    = NuiGetEventPlayer();
    int    nToken = NuiGetEventWindow();
    string sEvent = NuiGetEventType();
    string sElem  = NuiGetEventElement();
    int    nIdx   = NuiGetEventArrayIndex();

    // ---- Test / debug window ----
    if(nToken == NuiFindWindow(oPC, PLG_WIN_TEST))
    {
        if(sEvent == EVENT_TYPE_MOUSEDOWN && sElem == PLG_BTN_TEST_ROW)
        {
            if(nIdx < 0 || nIdx >= PLG_DIS_COUNT) return;
            NuiDestroy(oPC, nToken);
            PlgContractAndNotify(oPC, nIdx);
            CreatePlgWindow(oPC);
        }
        else if(sEvent == EVENT_TYPE_CLICK && sElem == PLG_BTN_TEST_CURE)
        {
            PlgCureAndNotify(oPC);
            NuiDestroy(oPC, nToken);
            int nMain = NuiFindWindow(oPC, PLG_WINDOW);
            if(nMain != 0) FeedPlgWindow(oPC, nMain);
        }
        else if(sEvent == EVENT_TYPE_CLICK && sElem == PLG_BTN_TEST_OPEN)
        {
            NuiDestroy(oPC, nToken);
            CreatePlgWindow(oPC);
        }
        return;
    }

    // ---- Main status window ----
    if(nToken != NuiFindWindow(oPC, PLG_WINDOW)) return;

    if(sEvent == EVENT_TYPE_CLOSE)
        return; // nothing to clean up

    if(sEvent == EVENT_TYPE_OPEN)
    {
        FeedPlgWindow(oPC, nToken);
        return;
    }

    if(sEvent != EVENT_TYPE_CLICK) return;

    if(sElem == PLG_BTN_CLOSE)
    {
        NuiDestroy(oPC, nToken);
        return;
    }

    if(sElem == PLG_BTN_CURE)
    {
        int nDiseaseId = GetLocalInt(oPC, PLG_LVAR_DISEASE);
        if(nDiseaseId == PLG_DIS_NONE) return;

        string sRemedyTag = PlgDiseaseRemedyTag(nDiseaseId);
        object oRemedy    = GetItemPossessedBy(oPC, sRemedyTag);
        if(!GetIsObjectValid(oRemedy))
        {
            SendMessageToPC(oPC, "[Zaraza] Nie masz przy sobie odpowiedniego lekarstwa.");
            NuiSetBind(oPC, nToken, PLG_BIND_CURE_ENA, JsonBool(FALSE));
            return;
        }

        DestroyObject(oRemedy);
        PlgCureAndNotify(oPC);
        FeedPlgWindow(oPC, nToken);
        return;
    }
}
