// sys_on_enter.nss — Necromancy: module OnClientEnter hook
// Registers the PC in the essence table and restores live servant objects.

#include "lib_nec"

void main()
{
    object oPC = GetEnteringObject();
    if (!GetIsPC(oPC) || GetIsDMPossessed(oPC)) return;

    NecRegisterPC(oPC);

    // Delay spawn so the PC's location is fully initialised before we place creatures.
    DelayCommand(2.0, NecSpawnServants(oPC));
}
