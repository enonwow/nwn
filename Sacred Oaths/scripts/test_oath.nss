// test_oath.nss — OnUsed for the Oath Shrine placeable
// Place a shrine in-world, set its OnUsed script to "test_oath".

#include "lib_oath"

void main()
{
    object oPC = GetLastUsedBy();
    if(!GetIsPC(oPC)) return;

    OathOpenWindow(oPC);
}
