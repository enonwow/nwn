#include "lib_app_misc"

void main()
{
    object oPC = GetLastPlayerToSelectTarget();
    object oTarget = GetTargetingModeSelectedObject();

    if(GetIsObjectValid(oTarget))
    {
        AppMiscOnItemTarget(oPC, oTarget);
    }
}
