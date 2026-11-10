#include "lib_mit"

void main()
{
    object oPC = GetEnteringObject();
    if(!GetIsPC(oPC) || GetIsDMPossessed(oPC)) return;

    // Slight delay to avoid login congestion
    DelayCommand(2.0, MitApplyTolerance(oPC));
}
