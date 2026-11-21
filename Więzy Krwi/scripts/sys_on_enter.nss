#include "lib_wkr"

void main()
{
    object oPC = GetEnteringObject();
    if(!GetIsPC(oPC) || GetIsDMPossessed(oPC)) return;

    WkrRestoreOnEnter(oPC);
}
