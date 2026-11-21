// sys_on_enter.nss — Szynkarz: restore intox state on login
// Hook: Module Properties -> Events -> OnClientEnter

#include "lib_syn"

void main()
{
    object oPC = GetEnteringObject();
    if(!GetIsPC(oPC) || GetIsDM(oPC)) return;

    SynOnClientEnter(oPC);
}
