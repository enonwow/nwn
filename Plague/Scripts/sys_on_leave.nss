// sys_on_leave.nss - module OnClientExit event
// Hook: Module Properties -> Events -> OnClientLeave

#include "lib_plg"

void main()
{
    object oPC = GetExitingObject();
    if(!GetIsPC(oPC) || GetIsDM(oPC)) return;

    PlgOnClientLeave(oPC);
}
