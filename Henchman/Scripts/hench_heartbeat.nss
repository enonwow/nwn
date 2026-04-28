// hench_heartbeat.nss
// OnHeartbeat for henchman - HP save every ~60s (crash backup) + AI passthrough.
#include "lib_hench_def"

void main()
{
    int n = GetLocalInt(OBJECT_SELF, HENCH_LVAR_HB_TIMER) + 1;
    SetLocalInt(OBJECT_SELF, HENCH_LVAR_HB_TIMER, n);
    if(n >= 10)
    {
        SetLocalInt(OBJECT_SELF, HENCH_LVAR_HB_TIMER, 0);
        object oPC = GetMaster(OBJECT_SELF);
        if(GetIsObjectValid(oPC))
            HenchSave(oPC);
    }

    // SoU/HotU AI heartbeat (follow master, idle behaviors) - from set_xp2_henchmen.ini
    ExecuteScript("x0_ch_hen_heart", OBJECT_SELF);
}
