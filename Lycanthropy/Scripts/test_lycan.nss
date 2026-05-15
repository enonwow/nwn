#include "lib_lycan"

// test_lycan.nss — OnUsed script for a test placeable.
//
// Left-click → shows the Lycanthropy Status window.
// Shift-click (modifier via local int "LYCAN_TEST_MODE" on the placeable):
//   MODE 1 — infect the user at LATENT stage (for testing).
//   MODE 2 — fast-forward to FULL stage.
//   MODE 3 — cure the user.

void main()
{
    object oPC       = GetLastUsedBy();
    object oPlaceable = OBJECT_SELF;

    if(!GetIsPC(oPC)) return;

    int nMode = GetLocalInt(oPlaceable, "LYCAN_TEST_MODE");

    switch(nMode)
    {
        case 1:
        {
            if(LycanGetInfectionStage(oPC) == LYCAN_STAGE_NONE)
            {
                LycanSetInfection(oPC, LYCAN_STAGE_LATENT);
                SendMessageToPC(oPC,
                    "[Test] Zarażono klątwą wilkołaka — etap utajony.");
            }
            else
            {
                SendMessageToPC(oPC,
                    "[Test] Już jesteś zarażony. Zmień LYCAN_TEST_MODE na 3, by się uleczyć.");
            }
            break;
        }
        case 2:
        {
            LycanSetInfection(oPC, LYCAN_STAGE_FULL);
            LycanApplyStageEffects(oPC, LYCAN_STAGE_FULL);
            SendMessageToPC(oPC,
                "[Test] Klątwa zaawansowana do etapu PELNEGO.");
            break;
        }
        case 3:
        {
            LycanCure(oPC);
            SendMessageToPC(oPC,
                "[Test] Klątwa usunięta (tryb testowy, bez zuzycia kitu).");
            break;
        }
        default:
        {
            // Standard use: open status window.
            LycanOpenWindow(oPC);
            break;
        }
    }

    // Always (re-)open the window so the player can see current state.
    LycanOpenWindow(oPC);
}
