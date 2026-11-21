#include "lib_chim"

// OnUsed script for the "Warsztat Chimerysty" demo placeable.
// In a real module, place this on an alchemist's workbench or NPC dialog node.
void main()
{
    object oPC = GetLastUsedBy();
    if(!GetIsPC(oPC)) return;

    // Spawn one of each trophy item so a developer can test all grafts immediately.
    // Remove this block in production; trophies should come from monster loot.
    CreateItemOnObject("ds_basilisk_eye",      oPC);
    CreateItemOnObject("ds_mind_flayer_brain", oPC);
    CreateItemOnObject("ds_troll_heart",       oPC);
    CreateItemOnObject("ds_dragon_scale",      oPC);
    CreateItemOnObject("ds_ghoul_claw",        oPC);
    CreateItemOnObject("ds_wyvern_spine",      oPC);
    CreateItemOnObject("ds_ogre_tendon",       oPC);
    CreateItemOnObject("ds_phase_spider_gland",oPC);
    CreateItemOnObject("ds_frost_giant_bone",  oPC);
    CreateItemOnObject("ds_shadow_essence",    oPC);

    GiveGoldToCreature(oPC, 10000);

    SendMessageToPC(oPC,
        "[Test] Dodano trofea (tagi: ds_*) i 10000 zp. Otwieranie warsztatu...");

    ChimOpenWindow(oPC);
}
