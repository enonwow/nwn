#include "lib_sleg"

// OnUsed script for a "Kamień Pamięci" placeable.
// Place a placeable in the toolset with this script to test the module.
void main()
{
    object oPC = GetLastUsedBy();
    if(!GetIsPC(oPC)) return;

    // In a real module, seed a test record so new characters can claim it.
    // Remove this seeding block after testing.
    string sCDKey = GetPCPublicCDKey(oPC, FALSE);
    if(SlegUnclaimedCount(sCDKey) == 0 && !SlegHasActiveLegacy(GetObjectUUID(oPC)))
    {
        // Plant a demo warrior legacy attributed to a fictional predecessor
        SlegRecordLegacy(sCDKey, "demo_uuid_warrior", "Aldric Żelazna Pięść", SLEG_TYPE_WARRIOR);
        SlegRecordLegacy(sCDKey, "demo_uuid_mage",    "Mirela z Popiołu",     SLEG_TYPE_MAGE);
        SlegRecordLegacy(sCDKey, "demo_uuid_cursed",  "Tomas Przeklęty",      SLEG_TYPE_CURSED);
        SendMessageToPC(oPC, "[Demo] Zasiano testowe dziedzictwa dla twojego CD-key.");
    }

    SlegOpenWindow(oPC);
}
