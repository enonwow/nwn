#include "lib_scar"

// OnUsed handler for a placeable named "Stół Medyczny" (Medical Table).
// Simulates a near-death wound if none exist, then opens the wound UI.
void main()
{
    object oPC = GetLastUsedBy();
    if(!GetIsPC(oPC)) return;

    if(ScarDbCountAll(oPC) == 0)
    {
        ScarGainWound(oPC);
        SendMessageToPC(oPC, "[Test] Przyznano testową ranę. Otwieranie dziennika...");
    }

    ScarOpenWindow(oPC);
}
