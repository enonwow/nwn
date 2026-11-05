#include "lib_mia"

// Module OnClientEnter. If you already have a sys_on_enter, merge main() body.
// DMs are excluded from miasma exposure but can open the management panel.
void main()
{
    object oPC = GetEnteringObject();
    if(!GetIsPC(oPC)) return;

    if(GetIsDM(oPC))
    {
        // Let DM know the tool exists; they open it via the designated item or test script.
        SendMessageToPC(oPC, "[Opar] Panel zarządzania dostępny przez przedmiot MG: "
            + MIA_ITEM_HERB + " (lub test_mia jako DM).");
        return;
    }

    // Start the tick loop after engine settles the player's area
    DelayCommand(2.0, MiaStartTick(oPC));
}
