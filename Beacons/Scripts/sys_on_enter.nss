#include "lib_bcn_def"

void main()
{
    object oPC = GetEnteringObject();
    if(!GetIsPC(oPC) || GetIsDMPossessed(oPC)) return;

    // Close any stale beacon window from a previous session/area transition
    int nToken = NuiFindWindow(oPC, BCN_WINDOW);
    if(nToken != 0)
        NuiDestroy(oPC, nToken);
}
