#include "lib_dlg"

// ----------------------------------------------------------------
// Bargain accept: revive PC, increment debt, reapply effects
// ----------------------------------------------------------------

void DlgAcceptBargain(object oPC)
{
    SetLocalInt(oPC, DLG_LVAR_DYING, 0);

    DlgAddDebt(oPC, 1);
    DlgApplyDebtEffects(oPC);

    // Revive at 1 HP
    ApplyEffectToObject(DURATION_TYPE_INSTANT, EffectResurrection(), oPC);
    ApplyEffectToObject(DURATION_TYPE_INSTANT, EffectHeal(1), oPC);

    int nDebt = DlgGetDebt(oPC);
    SendMessageToPC(oPC, "[Dług Śmierci] Pakt zawarty. Dług wzrósł do poziomu " + IntToString(nDebt) + ".");
    FloatingTextStringOnCreature("Pakt ze Śmiercią zawarty.", oPC, FALSE);
    ApplyEffectToObject(DURATION_TYPE_INSTANT, EffectVisualEffect(VFX_IMP_DEATH), oPC);

    if(nDebt >= 3)
        SendMessageToPC(oPC, "[Dług Śmierci] Czujesz obecność Posłańca. Będzie tu wkrótce.");

    if(NuiFindWindow(oPC, DLG_WIN_BARGAIN) != 0)
        NuiDestroy(oPC, NuiFindWindow(oPC, DLG_WIN_BARGAIN));
}

void DlgRefuseBargain(object oPC)
{
    SetLocalInt(oPC, DLG_LVAR_DYING, 0);

    if(NuiFindWindow(oPC, DLG_WIN_BARGAIN) != 0)
        NuiDestroy(oPC, NuiFindWindow(oPC, DLG_WIN_BARGAIN));

    SendMessageToPC(oPC, "[Dług Śmierci] Odmówiłeś. Śmierć przyjmuje twoją duszę z obojętnością.");
    // Normal death proceeds — do nothing, engine handles it
}

// ----------------------------------------------------------------
// Main NUI event handler
// ----------------------------------------------------------------

void main()
{
    object oPC    = NuiGetEventPlayer();
    int    nToken = NuiGetEventWindow();
    string sEvent = NuiGetEventType();
    string sElem  = NuiGetEventElement();

    // ---- Bargain window ----
    if(nToken == NuiFindWindow(oPC, DLG_WIN_BARGAIN))
    {
        if(sEvent == EVENT_TYPE_CLOSE)
        {
            // Closing without choosing counts as refusal
            if(GetLocalInt(oPC, DLG_LVAR_DYING))
                DlgRefuseBargain(oPC);
            return;
        }

        if(sEvent == EVENT_TYPE_CLICK)
        {
            if(sElem == DLG_BTN_BARGAIN_ACCEPT)
            {
                DlgAcceptBargain(oPC);
                return;
            }
            if(sElem == DLG_BTN_BARGAIN_REFUSE)
            {
                DlgRefuseBargain(oPC);
                return;
            }
        }
        return;
    }

    // ---- Ledger window ----
    if(nToken == NuiFindWindow(oPC, DLG_WIN_LEDGER))
    {
        if(sEvent == EVENT_TYPE_CLOSE)
            return;

        if(sEvent == EVENT_TYPE_CLICK)
        {
            if(sElem == DLG_BTN_CLOSE)
            {
                NuiDestroy(oPC, nToken);
                return;
            }
            if(sElem == DLG_BTN_PAY_GOLD)
            {
                DlgPayWithGold(oPC);
                return;
            }
            if(sElem == DLG_BTN_PAY_HP)
            {
                DlgPayWithBlood(oPC);
                return;
            }
            if(sElem == DLG_BTN_PENANCE)
            {
                DlgHandlePenance(oPC);
                return;
            }
        }
    }
}
