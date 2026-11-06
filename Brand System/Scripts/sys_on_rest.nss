// sys_on_rest.nss -- Module OnPlayerRest (after rest) hook for Brand System
// Hooks into: Module OnPlayerRestFinished event
// Permanent effects reset after rest; this restores brand effects.
#include "lib_brand_def"

void main()
{
    object oPC = GetLastPCRested();
    if(!GetIsObjectValid(oPC) || GetIsDMPossessed(oPC)) return;
    if(BrandGetCount(GetObjectUUID(oPC)) > 0)
        DelayCommand(1.0, BrandApplyEffects(oPC));
}
