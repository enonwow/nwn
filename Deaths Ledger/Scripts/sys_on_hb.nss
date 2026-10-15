#include "lib_dlg"

// Assign to OnModuleHeartbeat (fires every 6 seconds).
// For each PC with debt >= 3, check if an emissary should spawn.

void main()
{
    object oPC = GetFirstPC();
    while(GetIsObjectValid(oPC))
    {
        if(GetIsPC(oPC) && !GetIsDead(oPC))
        {
            int nDebt = DlgGetDebt(oPC);
            if(nDebt >= 3)
                DlgSpawnEmissary(oPC);
        }
        oPC = GetNextPC();
    }
}
