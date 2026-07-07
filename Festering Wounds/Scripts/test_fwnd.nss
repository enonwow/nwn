#include "lib_fwnd"

// OnUsed demo: each use inflicts the next wound type in sequence (1–5),
// then opens the Festering Wounds journal for the activating PC.
void main()
{
    object oPC = GetLastUsedBy();
    if(!GetIsPC(oPC)) return;

    int nNext = GetLocalInt(OBJECT_SELF, "FWND_TEST_NEXT") + 1;
    if(nNext > 5) nNext = 1;
    SetLocalInt(OBJECT_SELF, "FWND_TEST_NEXT", nNext);

    FwndInflictWound(oPC, nNext, "Kamienny Posąg [Test]");
    FwndApplyWoundEffects(oPC);

    SendMessageToPC(oPC,
        "[Test Ran] Zadano: " + FwndTypeName(nNext)
        + "  |  Uzyj ponownie, by dodac kolejny typ rany (1-5 cykl).");

    FwndOpen(oPC);
}
