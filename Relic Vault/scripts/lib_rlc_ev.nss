#include "lib_rlc"

// ----------------------------------------------------------------
// Attune handler
// ----------------------------------------------------------------

void RlcHandleAttune(object oPC, int nToken)
{
    int nSel = GetLocalInt(oPC, RLC_LVAR_SEL);
    if(nSel < 1 || nSel > RLC_RELIC_COUNT) return;

    if(RlcGetAttuned(oPC) != 0)
    {
        SendMessageToPC(oPC, "[Relikwia] Już dzierżysz relikwię. Najpierw ją uwolnij.");
        return;
    }

    if(RlcGetHolder(nSel) != "")
    {
        SendMessageToPC(oPC, "[Relikwia] Ta relikwia jest już w czyjejś mocy.");
        RlcFeedList(oPC, nToken);
        RlcFeedDetail(oPC, nToken);
        return;
    }

    if(GetGold(oPC) < RLC_GOLD_ATTUNE)
    {
        SendMessageToPC(oPC, "[Relikwia] Potrzebujesz " + IntToString(RLC_GOLD_ATTUNE) + " sztuk złota na rytuał atunowania.");
        return;
    }

    AssignCommand(oPC, TakeGoldFromCreature(RLC_GOLD_ATTUNE, oPC, TRUE));
    RlcAttuneRelic(oPC, nSel);
    RlcApplyEffects(oPC);

    SendMessageToPC(oPC, "[Relikwia] Związałeś się z " + RlcRelicName(nSel) + ". Moc płynie — i klątwa razem z nią.");
    RlcFeedList(oPC, nToken);
    RlcFeedDetail(oPC, nToken);
}

// ----------------------------------------------------------------
// Release handler
// ----------------------------------------------------------------

void RlcHandleRelease(object oPC, int nToken)
{
    int nMyRelic = RlcGetAttuned(oPC);
    if(nMyRelic == 0) return;

    if(GetGold(oPC) < RLC_GOLD_RELEASE)
    {
        SendMessageToPC(oPC, "[Relikwia] Potrzebujesz " + IntToString(RLC_GOLD_RELEASE) + " sztuk złota na rytuał uwolnienia.");
        return;
    }

    string sName = RlcRelicName(nMyRelic);
    AssignCommand(oPC, TakeGoldFromCreature(RLC_GOLD_RELEASE, oPC, TRUE));
    RlcRemoveEffects(oPC);
    RlcReleaseRelic(oPC);

    SendMessageToPC(oPC, "[Relikwia] Uwolniłeś się od " + sName + ". Pustka, którą po sobie zostawiła, jest głośna.");
    RlcFeedList(oPC, nToken);
    RlcFeedDetail(oPC, nToken);
}

// ----------------------------------------------------------------
// Purify handler
// ----------------------------------------------------------------

void RlcHandlePurify(object oPC, int nToken)
{
    int nMyRelic = RlcGetAttuned(oPC);
    if(nMyRelic == 0) return;

    int nCurse = RlcGetCurseLevel(oPC);
    if(nCurse <= 0)
    {
        SendMessageToPC(oPC, "[Relikwia] Nie ma czego oczyszczać — klątwa nie zdążyła się jeszcze zakorzenić.");
        return;
    }

    if(GetGold(oPC) < RLC_GOLD_PURIFY)
    {
        SendMessageToPC(oPC, "[Relikwia] Potrzebujesz " + IntToString(RLC_GOLD_PURIFY) + " sztuk złota na rytuał oczyszczenia.");
        return;
    }

    AssignCommand(oPC, TakeGoldFromCreature(RLC_GOLD_PURIFY, oPC, TRUE));

    int nRoll = Random(100) + 1;
    if(nRoll <= RLC_PURIFY_CHANCE)
    {
        int nNew = RlcPurifyDB(oPC);
        RlcApplyEffects(oPC);
        SendMessageToPC(oPC, "[Relikwia] Rytuał powiódł się. Klątwa zredukowana do poziomu " + IntToString(nNew) + ".");
    }
    else
    {
        SendMessageToPC(oPC, "[Relikwia] Rytuał się nie powiódł. Klątwa jest głębiej zakorzeniona niż sądziłeś.");
    }

    RlcFeedList(oPC, nToken);
    RlcFeedDetail(oPC, nToken);
}

// ----------------------------------------------------------------
// Main event handler
// ----------------------------------------------------------------

void main()
{
    object oPC    = NuiGetEventPlayer();
    int    nToken = NuiGetEventWindow();
    string sEvent = NuiGetEventType();
    string sElem  = NuiGetEventElement();
    int    nIdx   = NuiGetEventArrayIndex();

    if(nToken != NuiFindWindow(oPC, RLC_WINDOW)) return;

    if(sEvent == EVENT_TYPE_CLOSE)
    {
        DeleteLocalInt(oPC, RLC_LVAR_SEL);
        return;
    }

    if(sEvent == EVENT_TYPE_MOUSEDOWN && sElem == RLC_BTN_ROW)
    {
        // nIdx is 0-based; relic IDs are 1-based
        int nRelicId = nIdx + 1;
        if(nRelicId < 1 || nRelicId > RLC_RELIC_COUNT) return;

        SetLocalInt(oPC, RLC_LVAR_SEL, nRelicId);
        RlcFeedList(oPC, nToken);
        RlcFeedDetail(oPC, nToken);
        return;
    }

    if(sEvent == EVENT_TYPE_CLICK)
    {
        if(sElem == RLC_BTN_CLOSE)
        {
            NuiDestroy(oPC, nToken);
            return;
        }
        if(sElem == RLC_BTN_ATTUNE)
        {
            RlcHandleAttune(oPC, nToken);
            return;
        }
        if(sElem == RLC_BTN_RELEASE)
        {
            RlcHandleRelease(oPC, nToken);
            return;
        }
        if(sElem == RLC_BTN_PURIFY)
        {
            RlcHandlePurify(oPC, nToken);
            return;
        }
    }
}
