#include "lib_pan"

void main()
{
    object oPC = GetLastPlayerToSelectTarget();
    if(!GetIsPC(oPC)) return;
    if(GetLocalInt(oPC, PAN_LVAR_PENDING_TARGET) > 0)
    {
        PanOnPlayerTarget(oPC);
    }
}
