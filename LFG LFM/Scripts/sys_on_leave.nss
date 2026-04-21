// sys_on_leave.nss
// OnClientLeave event script

#include "lib_lfg_def"

void main()
{
    object oPC = GetExitingObject();
    if(!GetIsPC(oPC)) return;
    LfgPlayerLeave(oPC);
}
