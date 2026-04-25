#include "lib_duel"

void main()
{
    object oPC = GetLastUsedBy();
    if(!GetIsPC(oPC)) return;
    CreateDuelMainWindow(oPC);
}
