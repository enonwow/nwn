#include "lib_lycan"

// Module OnClientLeave — revert wolf form cleanly on disconnect.

void main()
{
    object oPC = GetExitingObject();
    if(!GetIsPC(oPC)) return;

    // Restore human appearance so the stored appearance type stays consistent.
    if(GetLocalInt(oPC, LYCAN_LVAR_TRANSFORMED))
        LycanRevert(oPC);
}
