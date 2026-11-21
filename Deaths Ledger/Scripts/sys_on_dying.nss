#include "lib_dlg"

// Assign to the module OnPlayerDying event.
// NWN calls this when a PC reaches -1 to -9 HP. We block the default
// death and show the bargain NUI; the player chooses accept or refuse.

void main()
{
    object oPC = GetLastPlayerDied();
    if(!GetIsObjectValid(oPC) || !GetIsPC(oPC)) return;

    // Only intervene once per dying instance; DLG_LVAR_DYING prevents
    // re-entry if the engine calls this multiple times.
    if(GetLocalInt(oPC, DLG_LVAR_DYING)) return;
    SetLocalInt(oPC, DLG_LVAR_DYING, 1);

    // Freeze the dying PC so the engine doesn't finish the death sequence
    // while the popup is open. We use SetImmortal so HP can't drop further.
    SetImmortal(oPC, TRUE);

    // Show bargain popup
    DlgEnsureRow(oPC);
    DlgCreateBargainWindow(oPC);

    // Safety timeout: if the player closes without choosing, unfreeze them after 60s.
    // Re-entry is blocked by DLG_LVAR_DYING == 1 being already set.
    DelayCommand(60.0, AssignCommand(oPC, SetImmortal(oPC, FALSE)));
}
