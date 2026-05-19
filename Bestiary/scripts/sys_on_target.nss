// sys_on_target.nss — OnPlayerTarget: dispatch study targeting for Codex Bestiarum
// Hook: Module Properties -> Events -> OnPlayerTarget
//
// If another module also uses OnPlayerTarget (e.g. Mailbox), do NOT set this
// script directly. Instead call BstHandleTarget(GetLastPlayerToDoTarget())
// from your combined dispatcher. See INTEGRATION.md.
#include "lib_bst"

void main()
{
    object oPC = GetLastPlayerToDoTarget();
    BstHandleTarget(oPC);
}
