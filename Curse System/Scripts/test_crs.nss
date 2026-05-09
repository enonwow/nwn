// OnUsed on a placeable.
// First click:  inflicts all 6 curses on the using PC (for demo).
// Second click: opens the Curse Panel so the player can cleanse.
// Spawn the placeable, give yourself a crs_hol_oil item + gold to test cleansing.

#include "lib_crs"

void main()
{
    object oPC = GetLastUsedBy();
    if(!GetIsPC(oPC)) return;

    // If any curse already active, just open the panel
    if(JsonGetLength(CrsGetAllCurses(oPC)) > 0)
    {
        CrsOpenWindow(oPC);
        return;
    }

    // Give the PC one of each curse for demonstration
    CrsInflict(oPC, CRS_CURSE_ROTTING_HAND);
    CrsInflict(oPC, CRS_CURSE_PLAGUE_BRAND);
    CrsInflict(oPC, CRS_CURSE_SHADOW_DESPAIR);
    CrsInflict(oPC, CRS_CURSE_TREMBLING);
    CrsInflict(oPC, CRS_CURSE_SOUL_FROST);
    CrsInflict(oPC, CRS_CURSE_BLOOD_SEAL);

    // Give a holy oil for test cleansing
    CreateItemOnObject(CRS_ITEM_HOLY_OIL, oPC, 3);

    SendMessageToPC(oPC, "[Test] Nałożono wszystkie klątwy. Kliknij ponownie, by otworzyć panel klątw.");

    CrsStartTicking(oPC);
}
