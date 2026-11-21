#include "lib_btrk"

// Module OnHeartbeat fires every ~6 seconds.
// Every tick: drop PC trails if they took damage since last tick.
// Every BTRK_REFRESH_TICKS ticks: decay expired trails + refresh active tracker UIs.

void main()
{
    object oMod = GetModule();
    int nTick   = GetLocalInt(oMod, BTRK_LVAR_HB_TICK) + 1;
    SetLocalInt(oMod, BTRK_LVAR_HB_TICK, nTick);

    // ---- PC damage trail check (every tick) ----
    object oPC = GetFirstPC();
    while(GetIsObjectValid(oPC))
    {
        int nCurHP  = GetCurrentHitPoints(oPC);
        int nLastHP = GetLocalInt(oPC, "BTRK_LAST_HP");

        if(nLastHP > 0)
        {
            int nDmg = nLastHP - nCurHP;
            if(nDmg >= BTRK_MIN_BLEED_DMG)
                BtrkDropTrail(oPC, nDmg);
        }
        SetLocalInt(oPC, "BTRK_LAST_HP", nCurHP);

        oPC = GetNextPC();
    }

    if(nTick % BTRK_REFRESH_TICKS != 0) return;

    // ---- Decay expired trails ----
    BtrkDecayExpired();

    // ---- Refresh UI for active trackers ----
    oPC = GetFirstPC();
    while(GetIsObjectValid(oPC))
    {
        if(GetLocalInt(oPC, BTRK_LVAR_ACTIVE))
            BtrkRefreshTrackerUI(oPC);
        oPC = GetNextPC();
    }
}
