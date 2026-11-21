#include "lib_sb"

// OnUsed script for a placeable. Drag-and-drop onto any container or statue
// in the toolset to let players open the Soul Bond inspector.
void main()
{
    object oPC = GetLastUsedBy();
    if(!GetIsPC(oPC)) return;

    SbOpenWindow(oPC);
}
