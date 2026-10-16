#include "lib_bs_def"

// Place this script as the OnDeath script for enemy creatures
// whose kills should count toward spirit progression.
// GetLastKiller() returns OBJECT_SELF's killer at time of death.

void main()
{
    object oKiller = GetLastKiller();
    if(!GetIsPC(oKiller) || GetIsDMPossessed(oKiller)) return;

    BsHandleKill(oKiller);
}
