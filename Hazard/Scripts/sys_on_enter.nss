// sys_on_enter.nss — module OnClientEnter hook for Hazard
#include "lib_haz_def"

void main()
{
    object oPC = GetEnteringObject();
    if(!GetIsPC(oPC) || GetIsDMPossessed(oPC)) return;
    HazRegisterPlayer(oPC);
}
