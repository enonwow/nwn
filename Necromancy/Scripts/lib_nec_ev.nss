// lib_nec_ev.nss — Necromancy: NUI event handler
// Set as the event script in NecBuildWindow (NEC_EV_SCRIPT).

#include "lib_nec"

void main()
{
    object oPC    = NuiGetEventPlayer();
    int    nToken = NuiGetEventWindow();
    string sEvent = NuiGetEventType();
    string sElem  = NuiGetEventElement();
    int    nIdx   = NuiGetEventArrayIndex();

    if (nToken != NuiFindWindow(oPC, NEC_WINDOW)) return;

    // ----------------------------------------------------------------
    // Window lifecycle
    // ----------------------------------------------------------------

    if (sEvent == EVENT_TYPE_OPEN)
    {
        NecFeedRoster(oPC, nToken);
        NecClearDetail(oPC, nToken);
        NecFeedEssencePool(oPC, nToken);
        NecUpdateBindState(oPC, nToken);
        return;
    }

    if (sEvent == EVENT_TYPE_CLOSE)
    {
        DeleteLocalInt(oPC, NEC_LVAR_SEL_ID);
        DeleteLocalInt(oPC, NEC_LVAR_TARGETING);
        return;
    }

    // ----------------------------------------------------------------
    // Watch events
    // ----------------------------------------------------------------

    if (sEvent == EVENT_TYPE_WATCH)
    {
        // Re-validate feed button when the amount field changes.
        if (sElem == NEC_BIND_FEED_AMT)
        {
            string sVal = JsonGetString(NuiGetBind(oPC, nToken, NEC_BIND_FEED_AMT));
            int    nVal = StringToInt(sVal);
            int    nSel = GetLocalInt(oPC, NEC_LVAR_SEL_ID);
            int    bOk  = (nVal > 0) && (nSel > 0) && (NecGetEssencePool(oPC) >= nVal);
            NuiSetBind(oPC, nToken, NEC_BIND_FEED_ENA, JsonBool(bOk));
        }
        return;
    }

    // ----------------------------------------------------------------
    // Click events
    // ----------------------------------------------------------------

    if (sEvent == EVENT_TYPE_CLICK)
    {
        // ---- Close button ----
        if (sElem == NEC_BTN_CLOSE)
        {
            NuiDestroy(oPC, nToken);
            return;
        }

        // ---- Row selection ----
        if (sElem == NEC_BTN_ROW)
        {
            json jServants = NecGetServants(oPC);
            if (nIdx < 0 || nIdx >= JsonGetLength(jServants)) return;

            json jRow  = JsonArrayGet(jServants, nIdx);
            int  nId   = JsonGetInt(JsonObjectGet(jRow, "id"));

            SetLocalInt(oPC, NEC_LVAR_SEL_ID, nId);

            // Highlight selected row.
            int  nCount  = JsonGetLength(jServants);
            json jEncs   = JsonArray();
            int  i;
            for (i = 0; i < nCount; i++)
                jEncs = JsonArrayInsert(jEncs, JsonBool(i == nIdx));
            NuiSetBind(oPC, nToken, NEC_BIND_ROW_ENC, jEncs);

            NecFeedDetail(oPC, nToken, nId);
            return;
        }

        // ---- Feed button ----
        if (sElem == NEC_BTN_FEED)
        {
            int nSel = GetLocalInt(oPC, NEC_LVAR_SEL_ID);
            NecDoFeed(oPC, nToken, nSel);
            return;
        }

        // ---- Dismiss button ----
        if (sElem == NEC_BTN_DISMISS)
        {
            int nSel = GetLocalInt(oPC, NEC_LVAR_SEL_ID);
            NecDoDismiss(oPC, nToken, nSel);
            return;
        }

        // ---- Bind (raise undead) button ----
        if (sElem == NEC_BTN_BIND)
        {
            int nCount = NecGetServantCount(oPC);
            int nMax   = NecGetMaxServants(oPC);
            if (nCount >= nMax)
            {
                SendMessageToPC(oPC, "[Nekromancja] Osiągnąłeś limit sług (" +
                    IntToString(nMax) + "). Pożegnaj jednego, by móc przywołać nowego.");
                return;
            }
            int nPool = NecGetEssencePool(oPC);
            if (nPool < NEC_BIND_COST)
            {
                SendMessageToPC(oPC, "[Nekromancja] Za mało Esencji Dusz — potrzebujesz " +
                    IntToString(NEC_BIND_COST) + ", masz " + IntToString(nPool) + ".");
                return;
            }

            SetLocalInt(oPC, NEC_LVAR_TARGETING, 1);
            NuiSetBind(oPC, nToken, NEC_BIND_BIND_ENA, JsonBool(FALSE));
            EnterTargetingMode(oPC, OBJECT_TYPE_CREATURE);
            SendMessageToPC(oPC, "[Nekromancja] Wskaż zwłoki stwora, by nałożyć Pieczęć Krwi.");
            return;
        }
    }

    // ----------------------------------------------------------------
    // Mousedown events (e.g., row selection via direct click area)
    // ----------------------------------------------------------------

    if (sEvent == EVENT_TYPE_MOUSEDOWN && sElem == NEC_BTN_ROW)
    {
        json jServants = NecGetServants(oPC);
        if (nIdx < 0 || nIdx >= JsonGetLength(jServants)) return;

        json jRow = JsonArrayGet(jServants, nIdx);
        int  nId  = JsonGetInt(JsonObjectGet(jRow, "id"));

        SetLocalInt(oPC, NEC_LVAR_SEL_ID, nId);
        NecFeedDetail(oPC, nToken, nId);
    }
}
