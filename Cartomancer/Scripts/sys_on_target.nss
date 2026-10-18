#include "lib_carto"

void main()
{
    object oPC = GetLastPlayerToSelectTarget();
    if(!GetIsPC(oPC)) return;

    if(GetLocalInt(oPC, CARTO_LVAR_TARGETING))
        CartoOnPlayerTarget(oPC);
}
