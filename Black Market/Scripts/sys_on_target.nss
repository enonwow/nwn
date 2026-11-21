#include "lib_bmt"

void main()
{
    object oPC = GetLastPlayerToSelectTarget();
    if(!GetIsPC(oPC)) return;
    if(NuiFindWindow(oPC, BMT_WINDOW) == 0) return;

    BmtHandleTarget(oPC);
}
