#include "lib_smit"

// OnUsed script for a test placeable (anvil / forge).
// Also seeds the PC with a small batch of crafting materials so the
// forge UI can be exercised without manual item setup.
void main()
{
    object oPC = GetLastUsedBy();
    if(!GetIsPC(oPC)) return;

    // Give the PC a handful of each material (using scroll resref as stand-in).
    // In a real module these would be dedicated HAK items with the correct resrefs,
    // appearances, and descriptions.
    CreateItemOnObject("nw_it_mscroll001", oPC, 6, SMIT_TAG_IRON);
    CreateItemOnObject("nw_it_mscroll001", oPC, 4, SMIT_TAG_LEATHER);
    CreateItemOnObject("nw_it_mscroll001", oPC, 3, SMIT_TAG_BONE);
    CreateItemOnObject("nw_it_mscroll001", oPC, 2, SMIT_TAG_WOOD);
    CreateItemOnObject("nw_it_mscroll001", oPC, 1, SMIT_TAG_GEM);

    SendMessageToPC(oPC,
        "[Kuznia TEST] Dodano materialy testowe do ekwipunku. Otwieranie interfejsu...");

    SmithOpenWindow(oPC);
}
