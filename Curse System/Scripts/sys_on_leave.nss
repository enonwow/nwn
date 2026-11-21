#include "lib_crs_def"

void main()
{
    object oPC = GetExitingObject();
    if(!GetIsPC(oPC)) return;

    // Clear ticking flag so CrsStartTicking works correctly on next login
    DeleteLocalInt(oPC, CRS_LVAR_TICKING);
}
