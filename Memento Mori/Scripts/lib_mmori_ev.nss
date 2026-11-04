#include "lib_mmori"

void main()
{
    object oPC    = NuiGetEventPlayer();
    int    nToken = NuiGetEventWindow();
    string sEvent = NuiGetEventType();
    string sElem  = NuiGetEventElement();

    // ---- Last Words window ----
    if(nToken == NuiFindWindow(oPC, MMORI_WIN_LASTWORDS))
    {
        if(sEvent == EVENT_TYPE_CLOSE)
        {
            // Closed without confirming — treat as "Zapomnij"
            DeleteLocalString(oPC, MMORI_LVAR_DEATH_AREA);
            DeleteLocalString(oPC, MMORI_LVAR_DEATH_ANAME);
            DeleteLocalFloat (oPC, MMORI_LVAR_DEATH_X);
            DeleteLocalFloat (oPC, MMORI_LVAR_DEATH_Y);
            DeleteLocalFloat (oPC, MMORI_LVAR_DEATH_Z);
            return;
        }

        if(sEvent == EVENT_TYPE_CLICK)
        {
            if(sElem == MMORI_BTN_LW_CONFIRM)
            {
                MmoriConfirmMark(oPC);
                return;
            }
            if(sElem == MMORI_BTN_LW_SKIP)
            {
                NuiDestroy(oPC, nToken);
                DeleteLocalString(oPC, MMORI_LVAR_DEATH_AREA);
                DeleteLocalString(oPC, MMORI_LVAR_DEATH_ANAME);
                DeleteLocalFloat (oPC, MMORI_LVAR_DEATH_X);
                DeleteLocalFloat (oPC, MMORI_LVAR_DEATH_Y);
                DeleteLocalFloat (oPC, MMORI_LVAR_DEATH_Z);
                return;
            }
        }
        return;
    }

    // ---- Cairn window (view/mourn/reclaim) ----
    if(nToken == NuiFindWindow(oPC, MMORI_WIN_CAIRN))
    {
        if(sEvent == EVENT_TYPE_CLOSE)
        {
            DeleteLocalInt(oPC, MMORI_LVAR_MARK_ID);
            return;
        }

        if(sEvent == EVENT_TYPE_CLICK)
        {
            if(sElem == MMORI_BTN_CA_MOURN)
            {
                MmoriHandleMourn(oPC);
                return;
            }
            if(sElem == MMORI_BTN_CA_RECLAIM)
            {
                MmoriHandleReclaim(oPC);
                return;
            }
            if(sElem == MMORI_BTN_CA_CLOSE)
            {
                NuiDestroy(oPC, nToken);
                DeleteLocalInt(oPC, MMORI_LVAR_MARK_ID);
                return;
            }
        }
        return;
    }
}
