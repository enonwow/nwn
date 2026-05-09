#include "lib_crs"

void main()
{
    object oPC = GetEnteringObject();
    if(!GetIsPC(oPC) || GetIsDMPossessed(oPC)) return;

    // Re-apply curse effects lost on logout
    CrsApplyAllEffects(oPC);

    // Start the per-PC tick chain (idempotent guard inside)
    CrsStartTicking(oPC);

    // Notify if any curses are active
    json jAll = CrsGetAllCurses(oPC);
    if(JsonGetLength(jAll) > 0)
        SendMessageToPC(oPC, "[Klątwy] Masz aktywne klątwy. Wpisz !klątwy lub użyj placeable by otworzyć panel.");
}
