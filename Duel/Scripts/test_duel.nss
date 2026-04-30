// test_duel.nss
// OnUsed (lever / honor board placeable) - opens the main Honor Duels window.
#include "lib_duel"

void main()
{
    object oPC = GetLastUsedBy();
    if(!GetIsPC(oPC)) return;
    CreateDuelMainWindow(oPC);
}
