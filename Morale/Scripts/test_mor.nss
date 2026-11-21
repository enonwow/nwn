#include "lib_mor"

// Place on a Placeable (OnUsed). Using it opens the Morale panel,
// or, when the PC holds Shift, simulates a terror event for testing.
void main()
{
    object oPC = GetLastUsedBy();
    if(!GetIsPC(oPC)) return;

    // Init if somehow not done (e.g. testing without OnClientEnter wired)
    if(!GetLocalInt(oPC, MOR_LVAR_HB_RUNNING))
        MorInitPC(oPC);

    // Always open the window as the primary action
    MorOpenWindow(oPC);

    SendMessageToPC(oPC, "[Morale] Aktualne morale: " + IntToString(MorGet(oPC)) + " / " + IntToString(MOR_MAX)
        + " — Stan: " + MorTierName(MorGetTier(MorGet(oPC))));
}
