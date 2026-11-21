#include "lib_poi"

void main()
{
    object oPC = GetLastPlayerToSelectTarget();
    if(!GetIsPC(oPC)) return;

    if(GetLocalInt(oPC, POI_LVAR_PENDING) > 0)
        PoiOnWeaponTarget(oPC);
}
