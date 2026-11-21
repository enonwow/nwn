#include "lib_dlg"

// Assign to a placeable's OnUsed event.
// Two modes depending on the placeable tag:
//   DLG_ALTAR  — open the Ledger window (debt reduction)
//   DLG_TEST   — simulate dying (shows bargain popup, adds 1 debt for testing)

void main()
{
    object oUser = GetLastUsedBy();
    if(!GetIsPC(oUser)) return;

    string sTag = GetTag(OBJECT_SELF);

    if(sTag == "DLG_ALTAR")
    {
        DlgOpenLedger(oUser);
        return;
    }

    // DLG_TEST: quick debug — directly open bargain popup as if dying
    if(sTag == "DLG_TEST")
    {
        DlgEnsureRow(oUser);
        SetLocalInt(oUser, DLG_LVAR_DYING, 1);
        SetImmortal(oUser, TRUE);
        DlgCreateBargainWindow(oUser);
        SendMessageToPC(oUser, "[Dług Śmierci] TEST: Okno paktu otwarte. Dług obecny: "
            + IntToString(DlgGetDebt(oUser)));
        return;
    }

    // DLG_INFO: print current debt and effects to chat
    int nDebt = DlgGetDebt(oUser);
    SendMessageToPC(oUser, "=== Dług Śmierci — Status ===");
    SendMessageToPC(oUser, DlgDebtLabel(nDebt));
    SendMessageToPC(oUser, DlgEffectDesc(nDebt));
    SendMessageToPC(oUser, "Ostatnia wizyta Posłańca: "
        + IntToString(DlgGetLastEmissary(oUser)) + " (unix)");
    SendMessageToPC(oUser, "Kara HP (permanentna): "
        + IntToString(DlgGetHpPenalty(oUser)));
}
