// sys_module_hb.nss — Necromancy: module OnHeartbeat hook
// Fires every ~6 seconds. Ticks essence decay and syncs servant HP for all online PCs.
// If your module already has an OnHeartbeat script, call NecHeartbeat() from there
// instead of replacing the script entirely.

#include "lib_nec"

// Essence decay runs every tick; HP sync runs every 5 ticks (~30 s) to reduce DB writes.
const string NEC_LVAR_HB_TICK = "NEC_HB_TICK";

void NecHeartbeat()
{
    object oPC = GetFirstPC();
    while (GetIsObjectValid(oPC))
    {
        if (!GetIsDMPossessed(oPC))
        {
            NecProcessDecay(oPC);

            int nTick = GetLocalInt(GetModule(), NEC_LVAR_HB_TICK + GetObjectUUID(oPC));
            nTick++;
            SetLocalInt(GetModule(), NEC_LVAR_HB_TICK + GetObjectUUID(oPC), nTick);

            if (nTick >= 5)
            {
                SetLocalInt(GetModule(), NEC_LVAR_HB_TICK + GetObjectUUID(oPC), 0);
                NecSyncServantHP(oPC);

                // Also keep servants following their master (re-issue command if idle).
                json jServants = NecGetServants(oPC);
                int  nCount    = JsonGetLength(jServants);
                int  i;
                for (i = 0; i < nCount; i++)
                {
                    json   jRow     = JsonArrayGet(jServants, i);
                    string sTag     = JsonGetString(JsonObjectGet(jRow, "servant_tag"));
                    object oServant = GetObjectByTag(sTag);

                    if (GetIsObjectValid(oServant) && !GetIsInCombat(oServant))
                        AssignCommand(oServant, ActionFollow(oPC, 2.0));
                }
            }
        }
        oPC = GetNextPC();
    }
}

void main()
{
    NecHeartbeat();
}
