// lib_bnt_ev.nss — Bounty Contracts: NUI event handler (OnNUIEvent).
#include "lib_bnt"

void main()
{
    object oPC    = NuiGetEventPlayer();
    int    nToken = NuiGetEventWindow();
    string sEvent = NuiGetEventType();
    string sElem  = NuiGetEventElement();
    int    nIdx   = NuiGetEventArrayIndex();

    if(nToken != NuiFindWindow(oPC, BNT_WINDOW)) return;

    // ---- Window close ----
    if(sEvent == EVENT_TYPE_CLOSE)
    {
        DeleteLocalInt(oPC, BNT_LVAR_SEL_ID);
        DeleteLocalInt(oPC, BNT_LVAR_MINE_SEL);
        return;
    }

    // ---- Tab navigation ----
    if(sEvent == EVENT_TYPE_CLICK)
    {
        if(sElem == BNT_BTN_CLOSE)
        {
            NuiDestroy(oPC, nToken);
            return;
        }

        if(sElem == BNT_BTN_TAB_BOARD)
        {
            BntSwapToBoard(oPC, nToken);
            return;
        }
        if(sElem == BNT_BTN_TAB_ACTIVE)
        {
            BntSwapToActive(oPC, nToken);
            return;
        }
        if(sElem == BNT_BTN_TAB_MINE)
        {
            BntSwapToMine(oPC, nToken);
            return;
        }
        if(sElem == BNT_BTN_TAB_POST)
        {
            BntSwapToPost(oPC, nToken);
            return;
        }

        // ---- Board actions ----
        if(sElem == BNT_BTN_ACCEPT)
        {
            BntHandleAccept(oPC, nToken);
            return;
        }

        // ---- Active contract actions ----
        if(sElem == BNT_BTN_CLAIM)
        {
            BntHandleClaim(oPC, nToken);
            return;
        }
        if(sElem == BNT_BTN_ABANDON)
        {
            BntHandleAbandon(oPC, nToken);
            return;
        }

        // ---- Mine actions ----
        if(sElem == BNT_BTN_CANCEL_OWN)
        {
            BntHandleCancelOwn(oPC, nToken);
            return;
        }

        // ---- Post actions ----
        if(sElem == BNT_BTN_SUBMIT)
        {
            BntHandlePost(oPC, nToken);
            return;
        }
    }

    // ---- List row selection (mousedown gives index before click fires) ----
    if(sEvent == EVENT_TYPE_MOUSEDOWN)
    {
        if(sElem == BNT_BTN_BD_ROW)
        {
            json jContracts = BntGetOpenContracts();
            if(nIdx < 0 || nIdx >= JsonGetLength(jContracts)) return;

            json jRow = JsonArrayGet(jContracts, nIdx);
            int  nId  = JsonGetInt(JsonObjectGet(jRow, "id"));

            // Toggle: clicking already-selected row deselects
            int nPrev = GetLocalInt(oPC, BNT_LVAR_SEL_ID);
            SetLocalInt(oPC, BNT_LVAR_SEL_ID, (nPrev == nId) ? 0 : nId);
            BntFeedBoard(oPC, nToken);
            return;
        }

        if(sElem == BNT_BTN_MINE_ROW)
        {
            json jMine = BntGetMyPostedContracts(oPC);
            if(nIdx < 0 || nIdx >= JsonGetLength(jMine)) return;

            json jRow = JsonArrayGet(jMine, nIdx);
            int  nId  = JsonGetInt(JsonObjectGet(jRow, "id"));

            int nPrev = GetLocalInt(oPC, BNT_LVAR_MINE_SEL);
            SetLocalInt(oPC, BNT_LVAR_MINE_SEL, (nPrev == nId) ? 0 : nId);
            BntFeedMine(oPC, nToken);
            return;
        }
    }

    // ---- Watch: real-time form validation on post view ----
    if(sEvent == EVENT_TYPE_WATCH)
    {
        if(sElem == BNT_BIND_POST_TARGET || sElem == BNT_BIND_POST_REWARD)
        {
            NuiSetBind(oPC, nToken, BNT_BIND_POST_STATUS, JsonString(""));
            BntValidatePostForm(oPC, nToken);
            return;
        }
    }
}
