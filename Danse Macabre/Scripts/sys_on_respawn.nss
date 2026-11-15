#include "lib_mac"

void main()
{
    object oPC = GetLastRespawnButtonPresser();
    if(!GetIsPC(oPC)) return;

    int nOld = MacGetProximity(oPC);
    // Death is a major event: +25 proximity
    MacAddProximity(oPC, 25);
    int nNew = MacGetProximity(oPC);

    MacApplyProximityEffects(oPC, nOld, nNew);
    MacSendOmen(oPC, nNew);

    SendMessageToPC(oPC,
        "[Danse Macabre] Smierc dotkniela cie palcem. Bliskosc: "
        + IntToString(nNew) + "/100.");
}
