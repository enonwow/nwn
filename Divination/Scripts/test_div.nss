#include "lib_div"

// OnUsed on a placeable (e.g. "Stolik Wróżbitki") — opens the Divination window.
void main()
{
    object oPC = GetLastUsedBy();
    if(!GetIsPC(oPC)) return;

    DivEnsureRow(oPC);
    DivShowWindow(oPC);
}
