#include "lib_mmori"

void main()
{
    object oPC = GetLastRespawnButtonPressed();
    MmoriExpireOld(MMORI_EXPIRY_DAYS);
    MmoriOnPlayerRespawn(oPC);
}
