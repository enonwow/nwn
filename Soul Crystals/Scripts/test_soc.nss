// test_soc.nss — Soul Crystals: demo OnUsed script for the Soul Forge placeable.
// Attach this script to any placeable's OnUsed event to open the Soul Crystals UI.
// The placeable acts as the Soul Forge — the access point for managing crystals.

#include "lib_soc"

void main()
{
    object oPC = GetLastUsedBy();
    if (!GetIsPC(oPC)) return;

    // Ensure the player has a row in soc_players before opening the window
    SocRegisterPlayer(oPC);
    SocOpenWindow(oPC);
}
