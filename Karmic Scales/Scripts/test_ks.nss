// OnUsed script for a test placeable.
// Place a placeable tagged "test_ks_shrine" in the module,
// set this script as its OnUsed handler.
// Using it opens the Karmic Scales window for the PC.
// Using it while holding Shift awards +10 light karma (for quick testing).

#include "lib_ks"

void main()
{
    object oPC = GetLastUsedBy();
    if(!GetIsPC(oPC)) return;

    // Shift+Use = award karma for demonstration
    // (in production, karma comes from module events, not from here)
    if(GetLocalInt(OBJECT_SELF, "KS_TEST_CYCLE") == 0)
    {
        KsAwardKarma(oPC, 10, "Ofiarowanie modlitwy przy kapliczce");
        SetLocalInt(OBJECT_SELF, "KS_TEST_CYCLE", 1);
    }
    else if(GetLocalInt(OBJECT_SELF, "KS_TEST_CYCLE") == 1)
    {
        KsAwardKarma(oPC, -15, "Profanacja świętego miejsca");
        SetLocalInt(OBJECT_SELF, "KS_TEST_CYCLE", 2);
    }
    else
    {
        SetLocalInt(OBJECT_SELF, "KS_TEST_CYCLE", 0);
    }

    CreateKsWindow(oPC);
}
