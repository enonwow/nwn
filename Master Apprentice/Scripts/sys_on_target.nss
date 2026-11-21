#include "lib_ma"

void main()
{
    object oPC = GetLastPlayerToSelectTarget();
    if(!GetIsPC(oPC)) return;
    if(NuiFindWindow(oPC, MA_WINDOW) != 0)
        MaOnPlayerTarget(oPC);
}
