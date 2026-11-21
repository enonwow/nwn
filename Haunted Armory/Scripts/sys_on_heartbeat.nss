#include "lib_haunt"

// Module OnHeartbeat fires every 6 seconds.
// Curse save checks are throttled:
//   Level 4 (DC 18 → confused)   every  5 ticks ≈ 30 s
//   Level 3 (DC 15 → -2 Wis)    every 10 ticks ≈ 60 s
//   Level 2 (DC 12 → -1 Wis)    every 20 ticks ≈ 120 s
// A module-level integer counter drives all three intervals.
void main()
{
    object oMod = GetModule();

    int nTick = GetLocalInt(oMod, "HAUNT_TICK") + 1;
    if(nTick > 20) nTick = 1;        // wrap to prevent overflow over long sessions
    SetLocalInt(oMod, "HAUNT_TICK", nTick);

    // Only iterate PCs on ticks that are multiples of 5 (≥ every level needs).
    if(nTick % 5 != 0) return;

    object oPC = GetFirstPC();
    while(GetIsObjectValid(oPC))
    {
        if(GetIsPC(oPC) && !GetIsDM(oPC))
        {
            object oWeap = GetItemInSlot(INVENTORY_SLOT_RIGHTHAND, oPC);
            if(!GetIsObjectValid(oWeap))
                oWeap = GetItemInSlot(INVENTORY_SLOT_LEFTHAND, oPC);

            if(GetIsObjectValid(oWeap))
            {
                json jData = HauntGetWeaponData(GetObjectUUID(oWeap));
                if(JsonGetType(jData) != JSON_TYPE_NULL)
                {
                    int nLevel = JsonGetInt(JsonObjectGet(jData, "haunt_level"));

                    // Apply curse saves at the appropriate cadence.
                    int bRun = FALSE;
                    if(nLevel == 4 && nTick % 5 == 0)  bRun = TRUE;
                    if(nLevel == 3 && nTick % 10 == 0) bRun = TRUE;
                    if(nLevel == 2 && nTick % 20 == 0) bRun = TRUE;
                    // Level 5 has no save; its permanent Wis drain is handled by HauntApplyEffects.
                    if(nLevel >= 5)
                    {
                        // Refresh permanent effects once per 30s cycle in case
                        // they were stripped by a dispel.
                        if(nTick % 5 == 0) HauntApplyEffects(oPC, oWeap);
                    }

                    if(bRun) HauntProcessCurse(oPC);
                }
            }
            else
            {
                // No weapon in hand — strip lingering haunt bonuses.
                HauntStripAllEffects(oPC);
            }
        }
        oPC = GetNextPC();
    }
}
