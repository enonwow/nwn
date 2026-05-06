#include "lib_plg"

void main()
{
    object oPC = GetFirstPC();
    while(GetIsObjectValid(oPC))
    {
        PlgCheckProgression(oPC);
        PlgApplyPerTick(oPC);
        oPC = GetNextPC();
    }
}
