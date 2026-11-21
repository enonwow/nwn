// test_bnt.nss — Bounty Contracts: OnUsed script for demo placeable.
// Place a placeable in the module and set this script as its OnUsed event.
// Using it opens the Bounty Board window for the activating PC.
#include "lib_bnt"

void main()
{
    object oPC = GetLastUsedBy();
    if(!GetIsPC(oPC)) return;
    BntOpenWindow(oPC);
}
