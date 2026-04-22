#include "lib_st"

void main()
{
    object oPC = GetLastUsedBy();
    if(!GetIsPC(oPC)) return;
    CreateSpellTrackerIconWindow(oPC);
}
