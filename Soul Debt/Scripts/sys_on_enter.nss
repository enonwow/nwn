#include "lib_sdebt"

void main()
{
    object oPC = GetEnteringObject();
    if(!GetIsPC(oPC)) return;

    SDebtRegisterPlayer(oPC);
    SDebtCheckOnLogin(oPC);
}
