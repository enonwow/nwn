#include "lib_carto"

// Hook this script to each area's OnEnter event (or a central area-enter dispatcher).
void main()
{
    object oPC = GetEnteringObject();
    if(!GetIsPC(oPC) || GetIsDMPossessed(oPC)) return;

    CartoRemoveAreaBonus(oPC);
    CartoApplyAreaBonus(oPC);
}
