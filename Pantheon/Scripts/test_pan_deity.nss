#include "lib_pan"

void main()
{
    object oPC = GetLastUsedBy();
    if(!GetIsPC(oPC)) return;
    PanShowDeitySelector(oPC);
}
