#include "lib_fcraft_def"

void main()
{
    object oPC = GetLastPCRested();
    if(!GetIsPC(oPC)) return;

    // Reset active-ability cooldowns after rest
    DeleteLocalInt(oPC, FCRAFT_COOL_WEB);
    DeleteLocalInt(oPC, FCRAFT_COOL_POISON);
    DeleteLocalInt(oPC, FCRAFT_COOL_BLINK);

    int nToken = NuiFindWindow(oPC, FCRAFT_WIN_MAIN);
    if(nToken != 0)
    {
        // Refresh active tab if open
        int nSel = GetLocalInt(oPC, FCRAFT_LVAR_SEL_ACT);
        // Minimal refresh: just inform player
    }

    SendMessageToPC(oPC, "[Kowalnia] Modyfikacje ciała zostały odnowione — zdolności gotowe do użycia.");
}
