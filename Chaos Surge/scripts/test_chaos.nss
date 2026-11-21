// test_chaos.nss — OnUsed script for a Chaos Surge demonstration placeable.
// Place a placeable in the test area, set its OnUsed to this script.
//
// Each use simulates casting a spell of a random circle (3–8), adds appropriate
// CP, opens the Chaos Surge window, and reports current state to the player.

#include "lib_chaos"

void main()
{
    object oPC = GetLastUsedBy();
    if(!GetIsPC(oPC) || GetIsDM(oPC)) return;

    // Simulate a spell of circle 3–8 adding 5–20 CP
    int nCircle = Random(6) + 3;
    int nCPGain = nCircle * 2 + Random(5);

    int nOldCP = ChaosGetCP(oPC);

    SendMessageToPC(oPC,
        "[Chaos] Symulacja rzucenia zaklęcia " + IntToString(nCircle) +
        ". kręgu — +" + IntToString(nCPGain) + " punktów chaosu.");

    int bSurged = ChaosAddCP(oPC, nCPGain);

    int nNewCP = ChaosGetCP(oPC);
    if(!bSurged)
        SendMessageToPC(oPC,
            "[Chaos] Pulsacja: " + IntToString(nNewCP) + "/" + IntToString(CHAOS_MAX) +
            "  [" + ChaosGetStatusLabel(nNewCP) + "]");

    // Open or refresh the Chaos window
    ChaosOpenWindow(oPC);

    // Refresh if already open (ChaosOpenWindow handles both cases,
    // but explicit feed ensures the meter updates immediately after AddCP)
    int nToken = NuiFindWindow(oPC, CHAOS_WINDOW);
    if(nToken != 0)
        FeedChaosWindow(oPC, nToken);
}
