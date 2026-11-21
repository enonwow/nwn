#include "lib_ma"

void main()
{
    object oPC    = NuiGetEventPlayer();
    int    nToken = NuiGetEventWindow();
    string sEvent = NuiGetEventType();
    string sElem  = NuiGetEventElement();
    int    nIdx   = NuiGetEventArrayIndex();

    int nMain     = NuiFindWindow(oPC, MA_WINDOW);
    int nProposal = NuiFindWindow(oPC, MA_WIN_PROPOSAL);

    // ---- Proposal popup ----
    if(nToken == nProposal && nProposal != 0)
    {
        if(sEvent == EVENT_TYPE_CLICK)
        {
            if(sElem == MA_BTN_PROP_ACCEPT)
            {
                NuiDestroy(oPC, nToken);
                MaAcceptProposal(oPC);
                return;
            }
            if(sElem == MA_BTN_PROP_DECLINE)
            {
                NuiDestroy(oPC, nToken);
                MaDeclineProposal(oPC);
                return;
            }
        }
        if(sEvent == EVENT_TYPE_CLOSE)
        {
            // Closing without choosing = decline.
            if(GetLocalString(oPC, MA_LVAR_PROPOSAL_FROM) != "")
                MaDeclineProposal(oPC);
        }
        return;
    }

    // ---- Main window ----
    if(nToken != nMain || nMain == 0) return;

    if(sEvent == EVENT_TYPE_CLICK)
    {
        if(sElem == MA_BTN_CLOSE)
        {
            NuiDestroy(oPC, nToken);
            return;
        }
        if(sElem == MA_BTN_TAKE_APPRENTICE)
        {
            MaStartTakeApprentice(oPC);
            return;
        }
        if(sElem == MA_BTN_LEAVE)
        {
            MaLeaveMaster(oPC);
            return;
        }
    }

    if(sEvent == EVENT_TYPE_MOUSEDOWN && sElem == MA_BTN_ROW)
    {
        // Row click in apprentice list => dismiss that apprentice.
        json jApps = MaGetApprentices(GetObjectUUID(oPC));
        if(nIdx < 0 || nIdx >= JsonGetLength(jApps)) return;
        json jR = JsonArrayGet(jApps, nIdx);
        int nBondId = JsonGetInt(JsonObjectGet(jR, "id"));
        MaDismissApprentice(oPC, nBondId, "Master dismissed apprentice.");
    }
}
