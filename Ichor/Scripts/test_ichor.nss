#include "lib_ichor"

// OnUsed script for a demo placeable.
// Sets up test essences and opens the Ichor window.

void main()
{
    object oPC = GetLastUsedBy();
    if(!GetIsPC(oPC)) return;

    string sPcUuid = GetObjectUUID(oPC);

    // Seed one essence of each type for testing
    IchorAddEssence(sPcUuid, ICHOR_TYPE_UNDEAD,      "Szkielet Strażnik");
    IchorAddEssence(sPcUuid, ICHOR_TYPE_DEMON,       "Pomniejszy Diabeł");
    IchorAddEssence(sPcUuid, ICHOR_TYPE_DRAGON,      "Czerwony Smok");
    IchorAddEssence(sPcUuid, ICHOR_TYPE_LYCANTHROPE, "Wilkołak Leśny");
    IchorAddEssence(sPcUuid, ICHOR_TYPE_CONSTRUCT,   "Golem Żelazny");
    IchorAddEssence(sPcUuid, ICHOR_TYPE_FEY,         "Nimfa Wieczoru");
    IchorAddEssence(sPcUuid, ICHOR_TYPE_ABERRATION,  "Aboleth");
    IchorAddEssence(sPcUuid, ICHOR_TYPE_BEAST,       "Niedźwiedź Jaskiniowy");

    SendMessageToPC(oPC, "[Ichor] Zestaw demonstracyjny esencji dodany do kolekcji.");
    IchorOpen(oPC);
}
