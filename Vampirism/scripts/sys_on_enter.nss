#include "lib_vamp"

// OnClientEnter: restore vampire effects and open status window for returning vampires.

void main()
{
    object oPC = GetEnteringObject();
    if(!GetIsPC(oPC)) return;
    if(!VampIsVampire(oPC)) return;

    int nBlood = VampGetBlood(oPC);

    // Session restart wiped in-memory effects — reapply from stored blood level
    VampApplyEffects(oPC, nBlood);

    SendMessageToPC(oPC,
        "[Wampiryzm] Klątwa krwi wciąż ciąży na tobie."
        " Poziom krwi: " + IntToString(nBlood) + "/100.");

    // Small delay lets the client finish loading the GUI before we create the window
    DelayCommand(3.0, CreateVampWindow(oPC));
}
