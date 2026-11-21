// lib_oath_ev.nss — NUI event handler for Sacred Oaths

#include "lib_oath"

void main()
{
    object oPC    = NuiGetEventPlayer();
    int    nToken = NuiGetEventWindow();
    string sEvent = NuiGetEventType();
    string sElem  = NuiGetEventElement();

    // ----------------------------------------------------------------
    // Confirm popup
    // ----------------------------------------------------------------
    if(nToken == NuiFindWindow(oPC, OATH_WIN_CONFIRM))
    {
        if(sEvent == EVENT_TYPE_CLICK)
        {
            if(sElem == OATH_BTN_YES)
            {
                string sType   = GetLocalString(oPC, OATH_LVAR_CONFIRM);
                int    nOathId = GetLocalInt(oPC, OATH_LVAR_SEL);

                NuiDestroy(oPC, nToken);

                if(sType == "swear")
                    OathDoSwear(oPC, nOathId);
                else if(sType == "renounce")
                    OathDoRenounce(oPC);
                else if(sType == "atone")
                    OathDoAtone(oPC);
            }
            else if(sElem == OATH_BTN_NO)
            {
                NuiDestroy(oPC, nToken);
            }
        }
        return;
    }

    // ----------------------------------------------------------------
    // Main window
    // ----------------------------------------------------------------
    if(nToken != NuiFindWindow(oPC, OATH_WINDOW)) return;

    if(sEvent == EVENT_TYPE_CLOSE)
    {
        DeleteLocalInt(oPC, OATH_LVAR_SEL);
        DeleteLocalString(oPC, OATH_LVAR_CONFIRM);
        return;
    }

    if(sEvent == EVENT_TYPE_CLICK)
    {
        if(sElem == OATH_BTN_CLOSE)
        {
            NuiDestroy(oPC, nToken);
            return;
        }

        if(sElem == OATH_BTN_SWEAR)
        {
            int nSel = GetLocalInt(oPC, OATH_LVAR_SEL);
            if(nSel <= 0)
            {
                SendMessageToPC(oPC, "[Przysięgi] Wybierz przysięgę z listy.");
                return;
            }
            OathCreateConfirmPopup(oPC, nSel, "swear");
            return;
        }

        if(sElem == OATH_BTN_RENOUNCE)
        {
            int nActive = OathGetActive(oPC);
            if(nActive <= 0) return;
            OathCreateConfirmPopup(oPC, nActive, "renounce");
            return;
        }

        if(sElem == OATH_BTN_ATONE)
        {
            if(!OathIsBroken(oPC))
            {
                SendMessageToPC(oPC, "[Przysięgi] Nie nosisz piętna — odkupienie nie jest potrzebne.");
                return;
            }
            OathCreateConfirmPopup(oPC, 0, "atone");
            return;
        }

        // Oath row clicks (oath_btn_row1 .. oath_btn_row5)
        int i;
        for(i = 1; i <= OATH_COUNT; i++)
        {
            if(sElem == OATH_BTN_ROW + IntToString(i))
            {
                SetLocalInt(oPC, OATH_LVAR_SEL, i);
                FeedOathRows(oPC, nToken, i);
                FeedOathDetail(oPC, nToken, i);
                return;
            }
        }
    }

    if(sEvent == EVENT_TYPE_MOUSEDOWN)
    {
        // Row clicks also fire mousedown — handle same as click for groups
        int i;
        for(i = 1; i <= OATH_COUNT; i++)
        {
            if(sElem == OATH_BTN_ROW + IntToString(i))
            {
                SetLocalInt(oPC, OATH_LVAR_SEL, i);
                FeedOathRows(oPC, nToken, i);
                FeedOathDetail(oPC, nToken, i);
                return;
            }
        }
    }
}
