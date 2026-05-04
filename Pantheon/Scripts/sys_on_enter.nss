#include "lib_pan"

void main()
{
    object oPC = GetEnteringObject();
    if(!GetIsPC(oPC)) return;
    PanEnsureRow(oPC);
}
