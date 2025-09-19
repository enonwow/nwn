#include "lib_g_lockpick"

void main()
{
    object oPC = GetLastUsedBy();
    object oChest = OBJECT_SELF;

    if(GetLocked(oChest))
    {
        int nDifficulty = Random(5) + 1;
        GothicLockpickWindowCreate(oPC, nDifficulty, oChest);
    }
}
