// sys_on_enter.nss -- Module OnClientEnter hook for Brand System
// Hooks into: Module OnClientEnter event
// Re-applies brand effects to the PC after login (permanent effects reset on login).
#include "lib_brand_def"

void main()
{
    object oPC = GetEnteringObject();
    if(!GetIsPC(oPC) || GetIsDMPossessed(oPC)) return;

    int nCount = BrandGetCount(GetObjectUUID(oPC));
    if(nCount <= 0) return;

    // Delay to ensure PC is fully initialized before applying effects
    DelayCommand(3.0, BrandApplyEffects(oPC));

    if(nCount == 1)
        SendMessageToPC(oPC, "[Pietna] Masz aktywne pietno. Uzywaj placeabla 'Lustro Duszy', aby je przeglonac.");
    else
        SendMessageToPC(oPC, "[Pietna] Masz " + IntToString(nCount) + " aktywnych piet. Uzywaj placeabla 'Lustro Duszy', aby je przejrzec.");
}
