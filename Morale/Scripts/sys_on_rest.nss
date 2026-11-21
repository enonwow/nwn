#include "lib_mor"

// Wire this to OnPCRested (module event).
void main()
{
    object oPC = GetLastPCRested();
    if(!GetIsObjectValid(oPC) || !GetIsPC(oPC)) return;

    MorRestoreOnRest(oPC);
}
