#include "lib_dur"

// OnUsed script for a "Forge" / "Kowalskie Zaplecze" placeable.
// Place this on any workbench, forge, or blacksmith placeable to
// give players access to the durability repair panel.

void main()
{
    object oPC = GetLastUsedBy();
    if(!GetIsPC(oPC)) return;

    SetLocalInt(oPC, DUR_LVAR_FORGE, 1);
    DurCreateWindow(oPC);
}
