// Attach to the OnUsed event of an "Arena Board" placeable in the module.
// The placeable acts as the entry point: clicking it opens the arena NUI.
#include "lib_gla"

void main()
{
    object oPC = GetLastUsedBy();
    if(!GetIsPC(oPC)) return;

    ArenaRegisterFighter(oPC);
    ArenaOpenWindow(oPC);
}
