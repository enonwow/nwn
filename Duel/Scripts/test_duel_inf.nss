// test_duel_inf.nss
// OnUsed (placeable) - opens the Honor Duels rules / info window. Wire this
// to a separate placeable next to the duel board (e.g. a town notice board)
// so players can read the rules without opening the main duel window.
#include "lib_duel_inf"

void main()
{
    object oPC = GetLastUsedBy();
    if(!GetIsPC(oPC)) return;
    CreateDuelInfoWindow(oPC);
}
