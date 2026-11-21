#include "lib_fcraft"

void main()
{
    object oPC = GetEnteringObject();
    if(!GetIsPC(oPC)) return;

    // Clear active-ability cooldowns on module entry (rest-equivalent reset)
    DeleteLocalInt(oPC, FCRAFT_COOL_WEB);
    DeleteLocalInt(oPC, FCRAFT_COOL_POISON);
    DeleteLocalInt(oPC, FCRAFT_COOL_BLINK);

    // Reapply all persistent modification effects
    FcraftReapplyAll(oPC);
}
