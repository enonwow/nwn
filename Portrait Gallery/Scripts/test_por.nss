// OnUsed script for a "Galeria Portretów" placeable.
// Assign this script to any placeable in the test module to open the gallery.
// The placeable should have a tag such as "por_gallery_placeable".

#include "lib_por"

void main()
{
    object oPC = GetLastUsedBy();
    if(!GetIsPC(oPC)) return;
    CreatePortraitWindow(oPC);
}
