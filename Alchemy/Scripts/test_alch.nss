// test_alch.nss
// OnUsed script for a demo placeable (tag: alch_bench).
// Opens the Alchemy Workshop window for the activating PC.
// Also hands out one set of starter ingredients and one recipe scroll
// on the first interaction so the demo can be run immediately.
#include "lib_alch"

const string ALCH_TEST_GIVEN = "ALCH_TEST_GIVEN";

void GiveTestIngredients(object oPC)
{
    // One of each ingredient for the two starter recipes:
    // Starter 0 (Nalewka Gojąca):        PIOLUN + KOSCIOL + KREW_N
    // Starter 1 (Odwar Mrocznego Wzroku): GRZYB  + OKO    + RTEC
    int i;
    for(i = 0; i < 6; i++)
    {
        string sRef;
        switch(i)
        {
            case 0: sRef = ALCH_ING_PIOLUN;  break;
            case 1: sRef = ALCH_ING_KOSCIOL; break;
            case 2: sRef = ALCH_ING_KREW_N;  break;
            case 3: sRef = ALCH_ING_GRZYB;   break;
            case 4: sRef = ALCH_ING_OKO;     break;
            case 5: sRef = ALCH_ING_RTEC;    break;
            default: sRef = ""; break;
        }
        if(sRef != "")
            CreateItemOnObject(sRef, oPC);
    }

    // One recipe scroll for recipe 2 (Wywar Pancerza Krwi) — demonstrates discovery
    // Tag must match ALCH_REC_2 so sys_on_acquire.nss picks it up
    CreateItemOnObject("alch_rec_2", oPC);

    SendMessageToPC(oPC,
        "[Alchemia — Demo] Otrzymałeś składniki testowe i zwój receptury 'Wywar Pancerza Krwi'.");
    SendMessageToPC(oPC,
        "[Alchemia — Demo] Podnieś zwój, by odblokować przepis, a potem otwórz stół alchemiczny.");
}

void main()
{
    object oPC = GetLastUsedBy();
    if(!GetIsPC(oPC)) return;

    if(!GetLocalInt(oPC, ALCH_TEST_GIVEN))
    {
        SetLocalInt(oPC, ALCH_TEST_GIVEN, 1);
        GiveTestIngredients(oPC);
    }

    AlchOpenWindow(oPC);
}
