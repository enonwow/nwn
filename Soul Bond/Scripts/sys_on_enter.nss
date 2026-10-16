#include "lib_sb"

void main()
{
    object oPC = GetEnteringObject();
    if(!GetIsPC(oPC) || GetIsDMPossessed(oPC)) return;

    // Small delay so inventory is fully loaded before scanning
    DelayCommand(2.0, SbRestoreAllBonds(oPC));
}
