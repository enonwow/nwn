#include "lib_pact"

void main()
{
    object oPC = GetEnteringObject();
    if(!GetIsPC(oPC)) return;

    // Delay to let the client finish loading before applying effects/messages.
    DelayCommand(3.0, PactCheckAndApply(oPC));
}
