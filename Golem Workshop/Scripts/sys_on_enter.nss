#include "lib_gwk"

void main()
{
    object oPC = GetEnteringObject();
    if(!GetIsPC(oPC)) return;

    // Delay to let the PC finish loading before spawning the golem companion
    DelayCommand(3.0, GwkAutoRecall(oPC));
}
