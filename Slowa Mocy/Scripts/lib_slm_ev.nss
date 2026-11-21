#include "lib_slm"

// ----------------------------------------------------------------
// Helpers
// ----------------------------------------------------------------

void SlmHandleForge(object oPC, int nToken)
{
    int nElem   = JsonGetInt(NuiGetBind(oPC, nToken, SLM_BIND_ELEM_SEL));
    int nTarget = JsonGetInt(NuiGetBind(oPC, nToken, SLM_BIND_TGT_SEL));
    int nPower  = JsonGetInt(NuiGetBind(oPC, nToken, SLM_BIND_POW_SEL));

    if(nElem == 0 || nTarget == 0 || nPower == 0)
    {
        SendMessageToPC(oPC, "[Słowa Mocy] Wybierz Żywioł, Cel i Moc przed wykuciem inkantacji.");
        return;
    }

    if(!SlmKnowsWord(oPC, nElem) || !SlmKnowsWord(oPC, nTarget) || !SlmKnowsWord(oPC, nPower))
    {
        SendMessageToPC(oPC, "[Słowa Mocy] Nie znasz jednego lub więcej użytych słów.");
        return;
    }

    int nSlot = GetLocalInt(oPC, SLM_LVAR_SEL_SLOT);
    SlmSaveIncantation(oPC, nSlot, nElem, nTarget, nPower);

    SendMessageToPC(oPC, "[Słowa Mocy] Inkantacja '" + SlmGetIncantationName(nElem, nTarget, nPower) +
        "' zapisana w slocie " + IntToString(nSlot + 1) + ".");
    FeedSlmForge(oPC, nToken);
}

void SlmHandleInvoke(object oPC, int nToken)
{
    json jList   = SlmGetIncantations(oPC);
    int nSelIdx  = GetLocalInt(oPC, SLM_LVAR_SEL_INCAN);
    int nCount   = JsonGetLength(jList);

    if(nSelIdx < 0 || nSelIdx >= nCount) return;

    json jEntry  = JsonArrayGet(jList, nSelIdx);
    int nElem    = JsonGetInt(JsonObjectGet(jEntry, "elem"));
    int nTarget  = JsonGetInt(JsonObjectGet(jEntry, "target"));
    int nPower   = JsonGetInt(JsonObjectGet(jEntry, "power"));

    // Self and area: no target needed, cast immediately
    if(nTarget == SLM_TARGET_SELF || nTarget == SLM_TARGET_AREA)
    {
        NuiDestroy(oPC, nToken);
        SlmApplyEffect(oPC, nElem, nTarget, nPower, OBJECT_INVALID);
        return;
    }

    // Enemy or ally: enter targeting mode
    SetLocalInt(oPC, SLM_LVAR_TARGETING,    1);
    SetLocalInt(oPC, SLM_LVAR_INVOKE_ELEM,  nElem);
    SetLocalInt(oPC, SLM_LVAR_INVOKE_TGT,   nTarget);
    SetLocalInt(oPC, SLM_LVAR_INVOKE_POW,   nPower);

    NuiDestroy(oPC, nToken);

    if(nTarget == SLM_TARGET_ENEMY)
        SendMessageToPC(oPC, "[Słowa Mocy] Wskaż wroga inkantacją...");
    else
        SendMessageToPC(oPC, "[Słowa Mocy] Wskaż sojusznika inkantacją...");

    EnterTargetingMode(oPC, OBJECT_TYPE_CREATURE);
}

void SlmHandleErase(object oPC, int nToken)
{
    json jList   = SlmGetIncantations(oPC);
    int nSelIdx  = GetLocalInt(oPC, SLM_LVAR_SEL_INCAN);
    int nCount   = JsonGetLength(jList);

    if(nSelIdx < 0 || nSelIdx >= nCount) return;

    json jEntry = JsonArrayGet(jList, nSelIdx);
    int nSlot   = JsonGetInt(JsonObjectGet(jEntry, "slot"));
    int nElem   = JsonGetInt(JsonObjectGet(jEntry, "elem"));
    int nTarget = JsonGetInt(JsonObjectGet(jEntry, "target"));
    int nPower  = JsonGetInt(JsonObjectGet(jEntry, "power"));

    SlmDeleteIncantation(oPC, nSlot);
    SetLocalInt(oPC, SLM_LVAR_SEL_INCAN, -1);
    SendMessageToPC(oPC, "[Słowa Mocy] Inkantacja '" + SlmGetIncantationName(nElem, nTarget, nPower) +
        "' wymazana ze słów pamięci.");
    FeedSlmIncan(oPC, nToken);
}

void SlmCleanupLocals(object oPC)
{
    DeleteLocalInt(oPC, SLM_LVAR_VIEW);
    DeleteLocalInt(oPC, SLM_LVAR_SEL_SLOT);
    DeleteLocalInt(oPC, SLM_LVAR_SEL_INCAN);
    DeleteLocalInt(oPC, SLM_LVAR_TARGETING);
    DeleteLocalInt(oPC, SLM_LVAR_INVOKE_ELEM);
    DeleteLocalInt(oPC, SLM_LVAR_INVOKE_TGT);
    DeleteLocalInt(oPC, SLM_LVAR_INVOKE_POW);
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

    if(nToken != NuiFindWindow(oPC, SLM_WINDOW)) return;

    // -- Window closed --
    if(sEvent == EVENT_TYPE_CLOSE)
    {
        SlmCleanupLocals(oPC);
        return;
    }

    // -- Combo watch: any word selection changed → refresh preview --
    if(sEvent == EVENT_TYPE_WATCH &&
        (sElem == SLM_BIND_ELEM_SEL || sElem == SLM_BIND_TGT_SEL || sElem == SLM_BIND_POW_SEL))
    {
        FeedSlmForge(oPC, nToken);
        return;
    }

    // -- Clicks --
    if(sEvent == EVENT_TYPE_CLICK)
    {
        // Close button
        if(sElem == SLM_BTN_CLOSE)
        {
            NuiDestroy(oPC, nToken);
            return;
        }

        // Tab: switch to incantations list
        if(sElem == SLM_BTN_TAB_INCAN)
        {
            SwapToIncanView(oPC, nToken);
            return;
        }

        // Back to forge
        if(sElem == SLM_BTN_BACK_FORGE)
        {
            SwapToForgeView(oPC, nToken);
            return;
        }

        // Forge (save) button
        if(sElem == SLM_BTN_FORGE)
        {
            SlmHandleForge(oPC, nToken);
            return;
        }

        // Save-slot selection buttons
        if(GetStringLeft(sElem, GetStringLength(SLM_BTN_SLOT)) == SLM_BTN_SLOT)
        {
            string sSuffix = GetStringRight(sElem, GetStringLength(sElem) - GetStringLength(SLM_BTN_SLOT));
            int nSlotIdx   = StringToInt(sSuffix);
            if(nSlotIdx >= 0 && nSlotIdx < SLM_MAX_SLOTS)
            {
                SetLocalInt(oPC, SLM_LVAR_SEL_SLOT, nSlotIdx);
                FeedSlmForge(oPC, nToken);
            }
            return;
        }

        // Invoke incantation
        if(sElem == SLM_BTN_INVOKE)
        {
            SlmHandleInvoke(oPC, nToken);
            return;
        }

        // Erase incantation
        if(sElem == SLM_BTN_ERASE)
        {
            SlmHandleErase(oPC, nToken);
            return;
        }
    }

    // -- List row click: select incantation --
    if(sEvent == EVENT_TYPE_MOUSEDOWN && sElem == SLM_BTN_INCAN_ROW)
    {
        int nCount = JsonGetInt(NuiGetBind(oPC, nToken, SLM_BIND_INCAN_CNT));
        if(nIdx < 0 || nIdx >= nCount) return;

        SetLocalInt(oPC, SLM_LVAR_SEL_INCAN, nIdx);
        FeedSlmIncan(oPC, nToken);
        return;
    }
}
