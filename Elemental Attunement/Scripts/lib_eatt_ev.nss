// lib_eatt_ev.nss — NUI event handler for Elemental Attunement
#include "lib_eatt"

void main()
{
    object oPC    = NuiGetEventPlayer();
    int    nToken = NuiGetEventWindow();
    string sEvent = NuiGetEventType();
    string sElem  = NuiGetEventElement();
    int    nIdx   = NuiGetEventArrayIndex();

    if (nToken != NuiFindWindow(oPC, EATT_WINDOW)) return;

    if (sEvent == EVENT_TYPE_CLOSE)
    {
        DeleteLocalInt(oPC, EATT_LVAR_SEL);
        return;
    }

    if (sEvent == EVENT_TYPE_MOUSEDOWN && sElem == EATT_BTN_ROW)
    {
        if (nIdx < 0 || nIdx >= EATT_ELEM_COUNT) return;

        // Toggle selection
        int nPrevSel = GetLocalInt(oPC, EATT_LVAR_SEL);
        int nNewSel  = (nPrevSel == nIdx) ? -1 : nIdx;
        SetLocalInt(oPC, EATT_LVAR_SEL, nNewSel);
        EattFeedWindow(oPC, nToken);
        return;
    }

    if (sEvent == EVENT_TYPE_CLICK)
    {
        if (sElem == EATT_BTN_CLOSE)
        {
            NuiDestroy(oPC, nToken);
            return;
        }

        if (sElem == EATT_BTN_PURGE)
        {
            int nSel = GetLocalInt(oPC, EATT_LVAR_SEL);
            if (nSel < 0 || nSel >= EATT_ELEM_COUNT) return;

            string sUUID = GetObjectUUID(oPC);
            int nPts     = EattGetPoints(sUUID, nSel);
            int nTier    = EattGetTier(nPts);

            if (nTier <= 0)
            {
                SendMessageToPC(oPC, "[Nastrojenie] Ten żywioł nie jest aktywny.");
                return;
            }

            if (GetGold(oPC) < EATT_PURGE_COST)
            {
                SendMessageToPC(oPC, "[Nastrojenie] Potrzebujesz "
                    + IntToString(EATT_PURGE_COST)
                    + " sztuk złota, aby oczyścić nastrojenie.");
                return;
            }

            AssignCommand(oPC, TakeGoldFromCreature(EATT_PURGE_COST, oPC, TRUE));
            EattResetPoints(sUUID, nSel);

            SendMessageToPC(oPC,
                "[Nastrojenie] Nastrojenie żywiołu "
                + EattGetElemName(nSel)
                + " zostało oczyszczone za "
                + IntToString(EATT_PURGE_COST) + " sz.");

            FloatingTextStringOnCreature(
                "Nastrojenie " + EattGetElemName(nSel) + " wygasło.", oPC, FALSE);

            EattApplyEffects(oPC);
            SetLocalInt(oPC, EATT_LVAR_SEL, -1);
            EattFeedWindow(oPC, nToken);
            return;
        }
    }
}
