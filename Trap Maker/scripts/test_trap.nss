#include "lib_trap"

// ================================================================
// test_trap.nss  —  OnUsed for the "Warsztat Pułapek" placeable
//
// Place a placeable in the toolset, set tag TRAP_WORKSHOP and
// set its OnUsed script to "test_trap".
//
// For testing without components, the script also gives the PC
// a sample component kit when they use the placeable for the first
// time (indicated by local var TRAP_GOT_KIT on the PC).
// ================================================================

void GiveTestKit(object oPC)
{
    if(GetLocalInt(oPC, "TRAP_GOT_KIT")) return;
    SetLocalInt(oPC, "TRAP_GOT_KIT", 1);

    // Standard misc item used as placeholder for components.
    // Tags match TRAP_COMP_* constants — assign these tags to items in toolset.
    CreateItemOnObject("nw_it_msmlmisc01", oPC, 3, TRAP_COMP_BLADE);
    CreateItemOnObject("nw_it_msmlmisc01", oPC, 3, TRAP_COMP_SPRING);
    CreateItemOnObject("nw_it_msmlmisc01", oPC, 5, TRAP_COMP_DART);
    CreateItemOnObject("nw_it_msmlmisc01", oPC, 2, TRAP_COMP_POISON);
    CreateItemOnObject("nw_it_msmlmisc01", oPC, 2, TRAP_COMP_OIL);
    CreateItemOnObject("nw_it_msmlmisc01", oPC, 2, TRAP_COMP_FLINT);
    CreateItemOnObject("nw_it_msmlmisc01", oPC, 3, TRAP_COMP_POWDER);
    CreateItemOnObject("nw_it_msmlmisc01", oPC, 2, TRAP_COMP_GLASS);
    CreateItemOnObject("nw_it_msmlmisc01", oPC, 2, TRAP_COMP_BELL);
    CreateItemOnObject("nw_it_msmlmisc01", oPC, 4, TRAP_COMP_WIRE);
    CreateItemOnObject("nw_it_msmlmisc01", oPC, 4, TRAP_COMP_ROPE);
    CreateItemOnObject("nw_it_msmlmisc01", oPC, 3, TRAP_COMP_HOOK);

    SendMessageToPC(oPC, "[Pułapki] Otrzymałeś zespół testowych składników.");
}

void main()
{
    object oPC = GetLastUsedBy();
    if(!GetIsPC(oPC)) return;

    // First-time use: give sample components so the tester can try crafting
    GiveTestKit(oPC);

    TrapOpenCraftWindow(oPC);
}
