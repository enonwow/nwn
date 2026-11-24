#include "lib_ichor"

void main()
{
    object oPC = GetEnteringObject();
    if(!GetIsPC(oPC)) return;

    IchorReapplyOnLogin(oPC);
}
