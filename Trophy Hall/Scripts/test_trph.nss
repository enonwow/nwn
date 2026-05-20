// test_trph.nss — Trophy Hall: demo script
//
// Assign as OnUsed on a Trophy Hall placeable (e.g., a trophy case or bookshelf).
// When a PC activates the placeable, the Trophy Hall NUI opens.
//
// For testing without a placeable: execute from DM's toolbox or
// call via ExecuteScript("test_trph", oPC).

#include "lib_trph"

void main()
{
    object oUser = GetLastUsedBy();
    if(!GetIsPC(oUser) || GetIsDMPossessed(oUser)) return;

    // Ensure player is registered (idempotent)
    TrphRegisterPlayer(oUser);

    TrphCreateWindow(oUser);
}
