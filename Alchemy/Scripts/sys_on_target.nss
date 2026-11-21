#include "lib_alch"

void main()
{
    object oPC = GetLastPlayerToSelectTarget();
    if(!GetIsPC(oPC)) return;

    if(NuiFindWindow(oPC, ALCH_WINDOW) != 0
    && GetLocalInt(oPC, ALCH_LVAR_TARGETING) > 0)
        AlchHandleTargeting(oPC);
}
