// sys_on_target.nss — Necromancy: module OnPlayerTarget hook
// Handles the creature-targeting mode entered when "Przywołaj Umarłych" is clicked.

#include "lib_nec"

void main()
{
    object oPC = GetLastPlayerToSelectTarget();
    if (!GetIsPC(oPC)) return;

    // Only process if we are waiting for a necromancy bind target.
    if (!GetLocalInt(oPC, NEC_LVAR_TARGETING)) return;
    DeleteLocalInt(oPC, NEC_LVAR_TARGETING);

    object oTarget = GetTargetingModeSelectedObject();

    int nToken = NuiFindWindow(oPC, NEC_WINDOW);

    if (!GetIsObjectValid(oTarget))
    {
        // Player cancelled targeting.
        SendMessageToPC(oPC, "[Nekromancja] Anulowano przywoływanie.");
        if (nToken != 0) NecUpdateBindState(oPC, nToken);
        return;
    }

    NecBindCorpse(oPC, oTarget);
}
