// OnUsed script for a "Pracownia Tatuaży" placeable.
// Place on any NWN placeable to open the tattoo studio UI.
#include "lib_tatu"

void main()
{
    object oPC = GetLastUsedBy();
    if(!GetIsPC(oPC)) return;

    TatuOpenWindow(oPC);
}
