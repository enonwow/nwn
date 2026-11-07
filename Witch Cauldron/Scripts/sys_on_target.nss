// sys_on_target.nss — Witch Cauldron: module OnPlayerTarget hook
// Routes targeting events to the appropriate subsystem.
#include "lib_wca"

void main()
{
    object oPC = GetLastPlayerToSelectTarget();
    if(!GetIsPC(oPC)) return;

    // Dispatch to Witch Cauldron if that window is open and awaiting a target
    if(NuiFindWindow(oPC, WCA_WINDOW) != 0)
    {
        WcaOnPlayerTarget(oPC);
        return;
    }
}
