#include "lib_obs"

void main()
{
    object oPC = GetFirstPC();
    while(GetIsObjectValid(oPC))
    {
        int nTick = GetLocalInt(oPC, OBS_LVAR_HB_TICK) + 1;
        if(nTick >= OBS_HB_TICKS)
        {
            SetLocalInt(oPC, OBS_LVAR_HB_TICK, 0);
            // Refresh rolling temporary bonuses and check for compulsion triggers
            ObsApplyBonuses(oPC);
            ObsCheckCompulsions(oPC);

            // Refresh UI if open
            int nToken = NuiFindWindow(oPC, OBS_WINDOW);
            if(nToken != 0)
                ObsFeedUI(oPC, nToken);
        }
        else
        {
            SetLocalInt(oPC, OBS_LVAR_HB_TICK, nTick);
        }
        oPC = GetNextPC();
    }
}
