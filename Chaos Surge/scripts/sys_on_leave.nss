// sys_on_leave.nss — module OnClientLeave: persist chaos state to DB.
// Hook: Module → Events → OnClientLeave

#include "lib_chaos"

void main()
{
    object oPC = GetExitingObject();
    if(!GetIsPC(oPC) || GetIsDM(oPC)) return;

    ChaosSaveState(oPC);
}
