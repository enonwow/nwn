//::///////////////////////////////////////////////////////////////
//:: test_fshop — Feat Shop, dzwignia testowa
//::///////////////////////////////////////////////////////////////
//:: Bez harness'a, bez NWNX. Lista-renderer powinien zmiescic
//:: sie pod default 524k. Jak nie — to jest cos powaznego do
//:: zdiagnozowania osobno.
//::///////////////////////////////////////////////////////////////

#include "lib_fshop"

void main()
{
    object oPC = GetLastUsedBy();
    if(!GetIsPC(oPC)) return;

    CreateFShopWindow(oPC);
}
