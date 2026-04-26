#include "lib_duel"

// ----------------------------------------------------------------
// Honor Duels — NUI event router
// Handles main window, challenge config, incoming popup, HUD.
// ----------------------------------------------------------------

void DuelHandleSubmitFromConfig(object oPC, int nToken)
{
    string sTargetUuid = GetLocalString(oPC, DUEL_LVAR_DRAFT_TARGET);
    string sTargetName = GetLocalString(oPC, DUEL_LVAR_DRAFT_NAME);
    if(sTargetUuid == "")
    {
        SendMessageToPC(oPC, "[Duel] No target selected.");
        return;
    }

    int nWin = GetLocalInt(oPC, DUEL_LVAR_DRAFT_WIN);
    int nRules = GetLocalInt(oPC, DUEL_LVAR_DRAFT_RULES);

    string sStakeStr = JsonGetString(NuiGetBind(oPC, nToken, DUEL_BIND_CH_STAKE_TXT));
    int nStake = StringToInt(sStakeStr);
    if(nStake < 0) nStake = 0;

    int nId = DuelSubmitChallenge(oPC, sTargetUuid, sTargetName, nRules, nWin, nStake);
    if(nId > 0)
    {
        NuiDestroy(oPC, nToken);
        DeleteLocalString(oPC, DUEL_LVAR_DRAFT_TARGET);
        DeleteLocalString(oPC, DUEL_LVAR_DRAFT_NAME);
        DeleteLocalInt   (oPC, DUEL_LVAR_DRAFT_RULES);
        DeleteLocalInt   (oPC, DUEL_LVAR_DRAFT_WIN);

        int nMain = NuiFindWindow(oPC, DUEL_WINDOW);
        if(nMain != 0) FeedDuelMain(oPC, nMain);
    }
}

void DuelToggleWinCondition(object oPC, int nToken, int nWin)
{
    SetLocalInt(oPC, DUEL_LVAR_DRAFT_WIN, nWin);
    NuiSetBind(oPC, nToken, DUEL_BIND_CH_WIN_FB,    JsonBool(nWin == DUEL_WIN_FIRST_BLOOD));
    NuiSetBind(oPC, nToken, DUEL_BIND_CH_WIN_DEATH, JsonBool(nWin == DUEL_WIN_TO_DEATH));
    NuiSetBind(oPC, nToken, DUEL_BIND_CH_WIN_YIELD, JsonBool(nWin == DUEL_WIN_TO_YIELD));
}

void DuelToggleRuleFlag(object oPC, int nToken, int nFlag,
                        string sBindName, string sButtonId)
{
    int nMask = GetLocalInt(oPC, DUEL_LVAR_DRAFT_RULES);
    int bOn   = JsonGetInt(NuiGetBind(oPC, nToken, sBindName));
    if(bOn) nMask = nMask | nFlag;
    else    nMask = nMask & ~nFlag;
    SetLocalInt(oPC, DUEL_LVAR_DRAFT_RULES, nMask);
}

// ----------------------------------------------------------------
// Main entry point
// ----------------------------------------------------------------

void main()
{
    object oPC    = NuiGetEventPlayer();
    int    nToken = NuiGetEventWindow();
    string sEvent = NuiGetEventType();
    string sElem  = NuiGetEventElement();

    int nMain     = NuiFindWindow(oPC, DUEL_WINDOW);
    int nChallenge= NuiFindWindow(oPC, DUEL_WIN_CHALLENGE);
    int nIncoming = NuiFindWindow(oPC, DUEL_WIN_INCOMING);
    int nHud      = NuiFindWindow(oPC, DUEL_WIN_HUD);

    // ---- HUD: yield button ----
    if(nToken == nHud && nHud != 0)
    {
        if(sEvent == EVENT_TYPE_CLICK && sElem == DUEL_BTN_HUD_YIELD)
            DuelYield(oPC);
        return;
    }

    // ---- Incoming challenge popup ----
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

    // ---- Challenge config popup ----
    if(nToken == nChallenge && nChallenge != 0)
    {
        if(sEvent == EVENT_TYPE_CLICK)
        {
            if(sElem == DUEL_BTN_CH_SEND)
            {
                DuelHandleSubmitFromConfig(oPC, nToken);
                return;
            }
            if(sElem == DUEL_BTN_CH_CANCEL)
            {
                NuiDestroy(oPC, nToken);
                DeleteLocalString(oPC, DUEL_LVAR_DRAFT_TARGET);
                DeleteLocalString(oPC, DUEL_LVAR_DRAFT_NAME);
                return;
            }
            if(sElem == DUEL_BTN_CH_WIN_FB)
            { DuelToggleWinCondition(oPC, nToken, DUEL_WIN_FIRST_BLOOD); return; }
            if(sElem == DUEL_BTN_CH_WIN_DEATH)
            { DuelToggleWinCondition(oPC, nToken, DUEL_WIN_TO_DEATH);    return; }
            if(sElem == DUEL_BTN_CH_WIN_YIELD)
            { DuelToggleWinCondition(oPC, nToken, DUEL_WIN_TO_YIELD);    return; }

            if(sElem == DUEL_BTN_CH_RULE_NOMAGIC)
            { DuelToggleRuleFlag(oPC, nToken, DUEL_RULE_NO_MAGIC,
                DUEL_BIND_CH_RULE_NOMAGIC, DUEL_BTN_CH_RULE_NOMAGIC); return; }
            if(sElem == DUEL_BTN_CH_RULE_NOITEMS)
            { DuelToggleRuleFlag(oPC, nToken, DUEL_RULE_NO_ITEMS,
                DUEL_BIND_CH_RULE_NOITEMS, DUEL_BTN_CH_RULE_NOITEMS); return; }
            if(sElem == DUEL_BTN_CH_RULE_NOCRIT)
            { DuelToggleRuleFlag(oPC, nToken, DUEL_RULE_NO_CRIT,
                DUEL_BIND_CH_RULE_NOCRIT, DUEL_BTN_CH_RULE_NOCRIT); return; }
        }

        if(sEvent == EVENT_TYPE_WATCH)
        {
            // Sync rule mask with checkbox state.
            if(sElem == DUEL_BIND_CH_RULE_NOMAGIC
            || sElem == DUEL_BIND_CH_RULE_NOITEMS
            || sElem == DUEL_BIND_CH_RULE_NOCRIT)
            {
                int nMask = 0;
                if(JsonGetInt(NuiGetBind(oPC, nToken, DUEL_BIND_CH_RULE_NOMAGIC)))
                    nMask = nMask | DUEL_RULE_NO_MAGIC;
                if(JsonGetInt(NuiGetBind(oPC, nToken, DUEL_BIND_CH_RULE_NOITEMS)))
                    nMask = nMask | DUEL_RULE_NO_ITEMS;
                if(JsonGetInt(NuiGetBind(oPC, nToken, DUEL_BIND_CH_RULE_NOCRIT)))
                    nMask = nMask | DUEL_RULE_NO_CRIT;
                SetLocalInt(oPC, DUEL_LVAR_DRAFT_RULES, nMask);
                return;
            }

            // Win condition radio behavior — only one allowed.
            if(sElem == DUEL_BIND_CH_WIN_FB
            || sElem == DUEL_BIND_CH_WIN_DEATH
            || sElem == DUEL_BIND_CH_WIN_YIELD)
            {
                int bFb    = JsonGetInt(NuiGetBind(oPC, nToken, DUEL_BIND_CH_WIN_FB));
                int bDeath = JsonGetInt(NuiGetBind(oPC, nToken, DUEL_BIND_CH_WIN_DEATH));
                int bYield = JsonGetInt(NuiGetBind(oPC, nToken, DUEL_BIND_CH_WIN_YIELD));
                int nWin   = GetLocalInt(oPC, DUEL_LVAR_DRAFT_WIN);
                if(sElem == DUEL_BIND_CH_WIN_FB    && bFb)    nWin = DUEL_WIN_FIRST_BLOOD;
                if(sElem == DUEL_BIND_CH_WIN_DEATH && bDeath) nWin = DUEL_WIN_TO_DEATH;
                if(sElem == DUEL_BIND_CH_WIN_YIELD && bYield) nWin = DUEL_WIN_TO_YIELD;
                DuelToggleWinCondition(oPC, nToken, nWin);
                return;
            }

            if(sElem == DUEL_BIND_CH_STAKE_TXT)
            {
                string sVal = JsonGetString(NuiGetBind(oPC, nToken, DUEL_BIND_CH_STAKE_TXT));
                int nVal = StringToInt(sVal);
                if(sVal != "" && sVal != "0" && nVal <= 0)
                    SendMessageToPC(oPC, "[Duel] Stake must be a whole positive number.");
                return;
            }
        }

        if(sEvent == EVENT_TYPE_CLOSE)
        {
            DeleteLocalString(oPC, DUEL_LVAR_DRAFT_TARGET);
            DeleteLocalString(oPC, DUEL_LVAR_DRAFT_NAME);
            DeleteLocalInt   (oPC, DUEL_LVAR_DRAFT_RULES);
            DeleteLocalInt   (oPC, DUEL_LVAR_DRAFT_WIN);
        }
        return;
    }

    // ---- Main window ----
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
            DuelStartChallengeTargeting(oPC);
            return;
        }
        if(sElem == DUEL_BTN_TAB_INCOMING)
        {
            SetLocalInt(oPC, DUEL_LVAR_VIEW, DUEL_VIEW_INCOMING);
            FeedDuelMain(oPC, nToken);
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

    if(sEvent == EVENT_TYPE_MOUSEDOWN && sElem == DUEL_BTN_ROW)
    {
        int nIdx  = NuiGetEventArrayIndex();
        int nView = GetLocalInt(oPC, DUEL_LVAR_VIEW);
        if(nView != DUEL_VIEW_INCOMING) return;

        json jRows = DuelGetIncoming(GetObjectUUID(oPC));
        if(nIdx < 0 || nIdx >= JsonGetLength(jRows)) return;

        json jR = JsonArrayGet(jRows, nIdx);
        int nDuelId   = JsonGetInt   (JsonObjectGet(jR, "id"));
        string sDir   = JsonGetString(JsonObjectGet(jR, "direction"));
        if(sDir == "in")
        {
            DuelShowIncomingPopup(oPC, nDuelId);
        }
        else
        {
            DuelCancelOutgoing(oPC, nDuelId);
        }
    }
}
