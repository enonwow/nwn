// test_wyrd.nss — Wyrd System test/demo placeable.
// Assign as the OnUsed script of any placeable in your module.
// Using the placeable opens the Krosno Przeznaczenia UI and optionally
// grants a small amount of wyrd to demonstrate the system.
//
// Flavor: "Kamienny postument z wyzetym okiem w trikolwanie — Oko Opatrznosci.
//          Dotkniecie go budzi przeczucie, ze przeznaczenie zauwazyo twoja obecnosc."
#include "lib_wyrd"

// Amount of wyrd granted per use (0 = UI only, set higher to test boons quickly)
const int WYRD_TEST_GRANT = 15;

// Cooldown between grants from this placeable (game-seconds)
const int WYRD_TEST_COOLDOWN = 120;

void main()
{
    object oPC = GetLastUsedBy();
    if(!GetIsPC(oPC)) return;

    // Per-placeable cooldown tracked on the PC with the placeable's object ID
    object oSelf = OBJECT_SELF;
    string sCdVar = "WYRD_TEST_CD_" + ObjectToString(oSelf);
    int nNow  = WyrdGameSec();
    int nLast = GetLocalInt(oPC, sCdVar);

    if(WYRD_TEST_GRANT > 0)
    {
        if(nNow - nLast >= WYRD_TEST_COOLDOWN)
        {
            SetLocalInt(oPC, sCdVar, nNow);
            WyrdGrant(oPC, WYRD_TEST_GRANT,
                      "Oko Opatrznosci dostrzeglo twoja obecnosc.");
        }
        else
        {
            int nLeft = WYRD_TEST_COOLDOWN - (nNow - nLast);
            SendMessageToPC(oPC,
                "[Wyrd] Postument nie reaguje. Poczekaj jeszcze "
                + IntToString(nLeft / 60 + 1) + " min.");
        }
    }

    // Always open the Wyrd panel so the player can spend
    WyrdOpenWindow(oPC);
}
