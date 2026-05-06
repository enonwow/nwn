// sys_on_enter.nss - module OnClientEnter event
// Hook: Module Properties -> Events -> OnClientEnter

#include "lib_plg"

void main()
{
    object oPC = GetEnteringObject();
    if(!GetIsPC(oPC) || GetIsDM(oPC)) return;

    PlgOnClientEnter(oPC);
}
