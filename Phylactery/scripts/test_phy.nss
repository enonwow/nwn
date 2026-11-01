#include "lib_phy"

// Attach to OnUsed of a placeable to open the Phylactery UI.
// The placeable can have the description:
//   "Naczynie Dusz — przybliż się i skupiaj, by obudzić uwięzioną esencję."

void main()
{
    object oPC = GetLastUsedBy();
    if(!GetIsPC(oPC)) return;
    CreatePhyWindow(oPC);
}
