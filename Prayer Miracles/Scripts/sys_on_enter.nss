#include "lib_pr"

void main()
{
    object oPC = GetEnteringObject();
    if(!GetIsPC(oPC)) return;
    PrEnsureRow(oPC);
}
