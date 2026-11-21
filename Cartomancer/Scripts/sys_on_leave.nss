#include "lib_carto"

void main()
{
    object oPC = GetExitingObject();
    if(!GetIsPC(oPC) || GetIsDMPossessed(oPC)) return;

    CartoRemoveAreaBonus(oPC);
}
