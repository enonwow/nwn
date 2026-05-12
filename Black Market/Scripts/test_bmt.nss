#include "lib_bmt"

// Attach to OnUsed of a placeable named "Czarne Targowisko" in the toolset.
// Simulates knocking on the fence's door.
void main()
{
    object oPC = GetLastUsedBy();
    if(!GetIsPC(oPC)) return;

    string sUuid = GetObjectUUID(oPC);
    BmtRegisterPlayer(sUuid);
    BmtDecayHeat(sUuid);

    int nHeat = BmtGetHeat(sUuid);
    string sIntro;

    if(nHeat < BMT_HEAT_WARN)
        sIntro = "Drzwi uchylają się. Wnętrze pachnie pleśnią i starymi tajemnicami.";
    else
        sIntro =
            "Passur mierzy cię długim spojrzeniem. "
            "„Gorące paluchy, co? Wejdź. Szybko."";

    FloatingTextStringOnCreature(sIntro, oPC, FALSE);
    BmtShowWindow(oPC);
}
