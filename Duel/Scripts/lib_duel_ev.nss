// lib_duel_ev.nss
// Honor Duels - NUI event router for all 4 windows owned by this subsystem:
// HUD, incoming popup, challenge confirm popup, main window. Dispatches by
// matching the event token against NuiFindWindow for each window.
// (The info / rules window has its own router: lib_duel_inf_ev.)
// Include chain: lib_duel -> lib_duel_def -> lib_duel_hud -> sql_duel + lib_nui.
#include "lib_duel"

void main()
{
    object oPC    = NuiGetEventPlayer();
    int    nToken = NuiGetEventWindow();
    string sEvent = NuiGetEventType();
    string sElem  = NuiGetEventElement();

    int nMain      = NuiFindWindow(oPC, DUEL_WINDOW);
    int nChallenge = NuiFindWindow(oPC, DUEL_WIN_CHALLENGE);
    int nIncoming  = NuiFindWindow(oPC, DUEL_WIN_INCOMING);
    int nHud       = NuiFindWindow(oPC, DUEL_WIN_HUD);

    // ------------------------------------------------------------
    // HUD: only watch event for geometry save (no buttons)
    // ------------------------------------------------------------
    if(nToken == nHud && nHud != 0)
    {
        if(sEvent == EVENT_TYPE_WATCH && sElem == DUEL_BIND_HUD_GEOM)
        {
            DelayCommand(0.5, DuelHudSavePosition(oPC, nToken));
        }
        return;
    }

    // ------------------------------------------------------------
    // Incoming challenge popup
    // ------------------------------------------------------------
    if(nToken == nIncoming && nIncoming != 0)
    {
        if(sEvent == EVENT_TYPE_CLICK)
        {
            int nDuelId = GetLocalInt(oPC, DUEL_LVAR_INCOMING_ID);
            if(nDuelId > 0)
            {
                if(sElem == DUEL_BTN_INC_ACCEPT)
                {
                    NuiDestroy(oPC, nToken);
                    DeleteLocalInt(oPC, DUEL_LVAR_INCOMING_ID);
                    DuelAccept(oPC, nDuelId);
                    return;
                }
                if(sElem == DUEL_BTN_INC_DECLINE)
                {
                    NuiDestroy(oPC, nToken);
                    DeleteLocalInt(oPC, DUEL_LVAR_INCOMING_ID);
                    DuelDecline(oPC, nDuelId);
                    return;
                }
            }
        }
        if(sEvent == EVENT_TYPE_CLOSE)
            DeleteLocalInt(oPC, DUEL_LVAR_INCOMING_ID);
        return;
    }

    // ------------------------------------------------------------
    // Challenge confirm popup
    // ------------------------------------------------------------
    if(nToken == nChallenge && nChallenge != 0)
    {
        if(sEvent == EVENT_TYPE_CLICK)
        {
            if(sElem == DUEL_BTN_CH_SEND)
            {
                string sTargetUuid = GetLocalString(oPC, DUEL_LVAR_DRAFT_TARGET);
                string sTargetName = GetLocalString(oPC, DUEL_LVAR_DRAFT_NAME);
                if(sTargetUuid == "")
                {
                    SendMessageToPC(oPC, "[Duel] No target selected.");
                    return;
                }

                int nId = DuelSubmitChallenge(oPC, sTargetUuid, sTargetName);
                if(nId > 0)
                {
                    NuiDestroy(oPC, nToken);
                    DeleteLocalString(oPC, DUEL_LVAR_DRAFT_TARGET);
                    DeleteLocalString(oPC, DUEL_LVAR_DRAFT_NAME);

                    int nMainTk = NuiFindWindow(oPC, DUEL_WINDOW);
                    if(nMainTk != 0) FeedDuelMain(oPC, nMainTk);
                }
                return;
            }
            if(sElem == DUEL_BTN_CH_CANCEL)
            {
                NuiDestroy(oPC, nToken);
                DeleteLocalString(oPC, DUEL_LVAR_DRAFT_TARGET);
                DeleteLocalString(oPC, DUEL_LVAR_DRAFT_NAME);
                return;
            }
        }
        if(sEvent == EVENT_TYPE_CLOSE)
        {
            DeleteLocalString(oPC, DUEL_LVAR_DRAFT_TARGET);
            DeleteLocalString(oPC, DUEL_LVAR_DRAFT_NAME);
        }
        return;
    }

    // ------------------------------------------------------------
    // Main window
    // ------------------------------------------------------------
    if(nToken != nMain || nMain == 0) return;

    if(sEvent == EVENT_TYPE_CLOSE)
    {
        DeleteLocalInt(oPC, DUEL_LVAR_VIEW);
        return;
    }

    if(sEvent == EVENT_TYPE_CLICK)
    {
        if(sElem == DUEL_BTN_CLOSE)
        {
            NuiDestroy(oPC, nToken);
            return;
        }
        if(sElem == DUEL_BTN_CHALLENGE)
        {
            NuiDestroy(oPC, nToken);
            DuelStartChallengeTargeting(oPC);
            return;
        }
        if(sElem == DUEL_BTN_TAB_HISTORY)
        {
            SetLocalInt(oPC, DUEL_LVAR_VIEW, DUEL_VIEW_HISTORY);
            FeedDuelMain(oPC, nToken);
            return;
        }
        if(sElem == DUEL_BTN_TAB_RANKING)
        {
            SetLocalInt(oPC, DUEL_LVAR_VIEW, DUEL_VIEW_RANKING);
            FeedDuelMain(oPC, nToken);
            return;
        }
    }
}
