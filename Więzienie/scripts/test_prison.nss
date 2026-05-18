#include "lib_prison"

// Place this script on the OnUsed event of a placeable (e.g., a guard post or jail door).
// Using the placeable arrests the activating PC with a demo crime.
// The crime level cycles 1-5 based on how many times the PC has been arrested before.

void main()
{
    object oPC = GetLastUsedBy();
    if(!GetIsPC(oPC)) return;

    if(PrisonIsActive(oPC))
    {
        SendMessageToPC(oPC, "[Więzienie] Już jesteś za kratami.");
        PrisonShowWindow(oPC);
        return;
    }

    // Pick a rotating demo crime so each test looks different.
    int nPrevRecords = JsonGetLength(PrisonGetHistory(oPC));
    int nLevel = (nPrevRecords % 5) + 1;

    string sCrime;
    switch(nLevel)
    {
        case 1: sCrime = "Zakłócenie porządku publicznego";        break;
        case 2: sCrime = "Kradzież kieszeniowa na targu";          break;
        case 3: sCrime = "Napad z bronią na mieszczanina";         break;
        case 4: sCrime = "Przemyt zakazanych artefaktów";          break;
        case 5: sCrime = "Zamach na życie przedstawiciela Korony"; break;
        default: sCrime = "Podejrzane zachowanie";
    }

    PrisonArrestPlayer(oPC, nLevel, sCrime);
}
