// lib_wf_ev.nss — Watchfire: NUI event handler

#include "lib_wf"

void main()
{
    object oPC     = NuiGetEventPlayer();
    int    nToken  = NuiGetEventWindow();
    string sEvent  = NuiGetEventType();
    string sElem   = NuiGetEventElement();
    int    nIdx    = NuiGetEventArrayIndex();

    if(nToken != NuiFindWindow(oPC, WF_WINDOW)) return;

    if(sEvent == EVENT_TYPE_CLOSE)
    {
        DeleteLocalObject(oPC, WF_LVAR_CAMPFIRE);
        DeleteLocalInt(oPC, WF_LVAR_TAB);
        return;
    }

    if(sEvent == EVENT_TYPE_CLICK)
    {
        // --- Tab navigation ---
        if(sElem == WF_BTN_CLOSE)
        {
            NuiDestroy(oPC, nToken);
            return;
        }

        if(sElem == WF_BTN_TAB_CAMP)
        {
            SetLocalInt(oPC, WF_LVAR_TAB, WF_TAB_CAMP);
            NuiSetGroupLayout(oPC, nToken, WF_GRP_TABS, BuildWfCampTab(oPC));
            WfFeedCampTab(oPC, nToken);
            return;
        }

        if(sElem == WF_BTN_TAB_COOK)
        {
            SetLocalInt(oPC, WF_LVAR_TAB, WF_TAB_COOK);
            NuiSetGroupLayout(oPC, nToken, WF_GRP_TABS, BuildWfCookTab(oPC));
            WfFeedCookTab(oPC, nToken);
            return;
        }

        if(sElem == WF_BTN_TAB_LOG)
        {
            SetLocalInt(oPC, WF_LVAR_TAB, WF_TAB_LOG);
            NuiSetGroupLayout(oPC, nToken, WF_GRP_TABS, BuildWfJournalTab(oPC));
            WfFeedJournalTab(oPC, nToken);
            return;
        }

        // --- Camp tab actions ---
        if(sElem == WF_BTN_WATCH)
        {
            int nCurrent = GetLocalInt(oPC, WF_LVAR_WATCH_ON);
            SetLocalInt(oPC, WF_LVAR_WATCH_ON, nCurrent ? 0 : 1);
            WfFeedCampTab(oPC, nToken);
            return;
        }

        if(sElem == WF_BTN_REST_SHORT)
        {
            WfDoRest(oPC, nToken, 0);
            return;
        }

        if(sElem == WF_BTN_REST_LONG)
        {
            WfDoRest(oPC, nToken, 1);
            return;
        }

        if(sElem == WF_BTN_WAKE)
        {
            WfDoWake(oPC, nToken);
            return;
        }

        // --- Cook tab ---
        if(sElem == WF_BTN_COOK)
        {
            WfDoCook(oPC, nToken);
            return;
        }
    }

    // Recipe row mousedown (list click)
    if(sEvent == EVENT_TYPE_MOUSEDOWN && sElem == WF_BTN_REC_ROW)
    {
        if(nIdx >= 0 && nIdx < WF_RECIPE_COUNT)
        {
            SetLocalInt(oPC, WF_LVAR_SEL_REC, nIdx);
            WfFeedCookTab(oPC, nToken);
        }
        return;
    }
}
