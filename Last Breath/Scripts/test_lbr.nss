#include "lib_lbr"

// OnUsed script for a test placeable.
// Place this placeable in-world and use it to open the Last Breath collection window.
// To simulate harvesting: kill a CR 3+ NPC, equip a "lbr_vial" item, then use the
// "Pochłoń Tchnienie" button to target the corpse.

void main()
{
    object oPC = GetLastUsedBy();
    if(!GetIsPC(oPC)) return;
    LbrOpenWindow(oPC);
}
