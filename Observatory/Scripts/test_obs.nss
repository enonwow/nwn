// OnUsed script for the Observatory placeable.
// Place this placeable in the module (tag: OBS_TELESCOPE or any tag).
// Set OnUsed → test_obs

#include "lib_obs"

void main()
{
    object oPC = GetLastUsedBy();
    if(!GetIsPC(oPC)) return;

    ObsRegisterPC(oPC);
    ObsOpen(oPC);
}
