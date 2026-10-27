// sys_on_pdeath.nss — Wyrd System: handle Cheat Death boon on player death.
// Hook as OnPlayerDeath, or call WyrdOnPlayerDeath() from an existing handler.
// The boon resurrects the PC at 1 HP and consumes itself.
#include "lib_wyrd"

void WyrdOnPlayerDeath()
{
    object oPC = GetLastPlayerDied();
    if(!GetIsObjectValid(oPC) || !GetIsPC(oPC)) return;

    WyrdCheckCheatDeath(oPC);
}

void main()
{
    WyrdOnPlayerDeath();
}
