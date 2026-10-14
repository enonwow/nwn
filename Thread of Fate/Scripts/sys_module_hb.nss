#include "lib_nit"

void main()
{
    object oPC = GetFirstPC();
    while(GetIsObjectValid(oPC))
    {
        NitHeartbeatTick(oPC);
        oPC = GetNextPC();
    }
}
