// sys_on_leave.nss — Necromancy: module OnClientLeave hook
// Saves current servant HP to DB and destroys their in-world objects.

#include "lib_nec"

void main()
{
    object oPC = GetExitingObject();
    if (!GetIsPC(oPC) || GetIsDMPossessed(oPC)) return;

    NecDespawnServants(oPC);
}
