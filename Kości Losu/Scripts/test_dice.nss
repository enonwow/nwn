// test_dice.nss — OnUsed placeable script; place on a dice table prop in the module

#include "lib_dice"

void main()
{
    object oPC = GetLastUsedBy();
    if(!GetIsPC(oPC)) return;
    DiceOpenWindow(oPC);
}
