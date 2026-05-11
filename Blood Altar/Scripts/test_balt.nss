// test_balt.nss — Blood Altar: skrypt testowy (OnUsed na placeable demonstracyjnym)
// Klika kolejno cykluje przez wszystkie 4 typy oltarzy.
// Dodaj ten skrypt jako OnUsed na dowolnym placeablu w DEMO module.
#include "lib_balt"

void main()
{
    object oPC   = GetLastUsedBy();
    object oSelf = OBJECT_SELF;

    if(!GetIsPC(oPC)) return;

    int nType = GetLocalInt(oSelf, "BALT_TEST_CYCLE");
    string sTag;
    switch(nType % 4)
    {
        case 0: sTag = BALT_TAG_BLOOD;  break;
        case 1: sTag = BALT_TAG_BONE;   break;
        case 2: sTag = BALT_TAG_EARTH;  break;
        default: sTag = BALT_TAG_SHADOW; break;
    }
    SetLocalInt(oSelf, "BALT_TEST_CYCLE", nType + 1);

    SendMessageToPC(oPC, "[Test-Oltarz] Otwieranie: " + BaltGetAltarName(sTag)
                  + "  |  Skalanie: " + IntToString(BaltGetCorruption(oPC)) + "%");
    BaltOpenWindow(oPC, sTag);
}
