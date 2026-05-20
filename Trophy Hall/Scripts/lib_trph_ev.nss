// lib_trph_ev.nss — Trophy Hall: NUI event handler
// Assigned as NuiCreate's event script for TRPH_WINDOW.

#include "lib_trph"

void main()
{
    object oPC    = NuiGetEventPlayer();
    int    nToken = NuiGetEventWindow();
    string sEvent = NuiGetEventType();
    string sElem  = NuiGetEventElement();
    int    nIdx   = NuiGetEventArrayIndex();

    if(nToken != NuiFindWindow(oPC, TRPH_WINDOW)) return;

    if(sEvent == EVENT_TYPE_CLOSE)
    {
        DeleteLocalInt(oPC, TRPH_LVAR_SEL_CAT);
        return;
    }

    if(sEvent == EVENT_TYPE_CLICK)
    {
        if(sElem == TRPH_BTN_CLOSE)
        {
            NuiDestroy(oPC, nToken);
            return;
        }

        if(sElem == TRPH_BTN_DEPOSIT)
        {
            int nCat   = GetLocalInt(oPC, TRPH_LVAR_SEL_CAT);
            int nCount = TrphDepositTrophies(oPC, nCat);
            if(nCount > 0)
                SendMessageToPC(oPC,
                    "[Trofea] Złożono " + IntToString(nCount) + " trofe"
                    + (nCount == 1 ? "um" : "a")
                    + " — " + TrphCatName(nCat) + ". "
                    + "Sala przyjmuje je z mrocznym szacunkiem.");
            else
                SendMessageToPC(oPC, "[Trofea] Nie masz trofeów tej kategorii w ekwipunku.");
            TrphFeedCategories(oPC, nToken);
            TrphFeedDetail(oPC, nToken, nCat);
            return;
        }

        if(sElem == TRPH_BTN_FORGE_MINOR)
        {
            int nCat = GetLocalInt(oPC, TRPH_LVAR_SEL_CAT);
            TrphForgeTalisman(oPC, nToken, nCat, FALSE);
            return;
        }

        if(sElem == TRPH_BTN_FORGE_MAJOR)
        {
            int nCat = GetLocalInt(oPC, TRPH_LVAR_SEL_CAT);
            TrphForgeTalisman(oPC, nToken, nCat, TRUE);
            return;
        }
    }

    // Category row click (left column list)
    if(sEvent == EVENT_TYPE_MOUSEDOWN && sElem == TRPH_BTN_CAT_ROW)
    {
        if(nIdx < 0 || nIdx >= TRPH_CAT_COUNT) return;
        SetLocalInt(oPC, TRPH_LVAR_SEL_CAT, nIdx);
        TrphFeedCategories(oPC, nToken);
        TrphFeedDetail(oPC, nToken, nIdx);
    }
}
