#include "lib_scar"

void main()
{
    object oPC = GetLastRespawnButtonPresser();
    if(!GetIsPC(oPC)) return;

    // 75% chance per respawn; only one wound per death to avoid instant cap
    if(Random(4) < 3)
        ScarGainWound(oPC);
}
