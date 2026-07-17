#include "lib_nit"

// OnUsed on a placeable — applies a test drain then opens the window.
// Place in the module for demonstration / QA purposes.
// Remove or disable this placeable in production.
void main()
{
    object oPC = GetLastUsedBy();
    if(!GetIsPC(oPC)) return;

    int nVal = NitGetValue(oPC);

    // Cycle through states for testing: drain 20 each use, reset at 0
    if(nVal <= 0)
    {
        SendMessageToPC(oPC, "[Nić TEST] Resetowanie do 100...");
        NitSetValue(oPC, NIT_MAX, TRUE);
        NitApplyTierEffects(oPC, NitGetTier(NIT_MAX));
    }
    else
    {
        int nDrain = 20;
        SendMessageToPC(oPC, "[Nić TEST] Stosowanie drenażu " + IntToString(nDrain) + " punktów (było: " + IntToString(nVal) + ")...");
        NitDrainThread(oPC, nDrain, "Test");
    }

    DelayCommand(0.3, NitOpenWindow(oPC));
}
