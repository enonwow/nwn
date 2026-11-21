#include "lib_echo"

// OnUsed placeable — "Kryształ Rezonansu" or any detector placeable.
// Alternatively wire to an item's OnActivated if using an inventory item.

void main()
{
    object oPC = GetLastUsedBy();
    if(!GetIsPC(oPC)) return;

    // Seed a few test traces so there's something to see in an empty module.
    // Remove this block before shipping to a live server.
    object oArea    = GetArea(oPC);
    string sAreaTag = GetTag(oArea);

    EchoInsertTrace(sAreaTag, GetObjectUUID(oPC),
        EchoBuildCasterMask(oPC),
        SPELL_FIREBALL,
        SPELL_SCHOOL_EVOCATION,
        "Kula Ognia",
        GetTotalLevels(oPC, FALSE));

    EchoInsertTrace(sAreaTag, "",
        "Nieumarły / Nekromanta",
        SPELL_ANIMATE_DEAD,
        SPELL_SCHOOL_NECROMANCY,
        "Animuj Truchło",
        12);

    EchoInsertTrace(sAreaTag, "",
        "Elf / Mag",
        SPELL_INVISIBILITY,
        SPELL_SCHOOL_ILLUSION,
        "Niewidzialność",
        7);

    SendMessageToPC(oPC, "[Echo Arkanów] Kryształ rezonansu aktywowany — odczyt śladów magicznych.");
    EchoOpenDetector(oPC);
}
