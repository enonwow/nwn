#include "lib_dlg"

void main()
{
    object oPC = GetEnteringObject();
    if(!GetIsPC(oPC)) return;

    DlgEnsureRow(oPC);

    int nDebt = DlgGetDebt(oPC);
    if(nDebt <= 0) return;

    // Reapply debt effects lost across server restarts
    DlgApplyDebtEffects(oPC);

    string sMsg = "[Dług Śmierci] Nosisz dług wobec Śmierci — poziom " + IntToString(nDebt)
        + ". Odwiedź Ołtarz Śmierci, by go zmniejszyć.";
    SendMessageToPC(oPC, sMsg);

    if(nDebt >= 3)
        SendMessageToPC(oPC, "[Dług Śmierci] Posłaniec śledzi twoje kroki. Zachowaj ostrożność.");
}
