// sys_module_hb.nss - module OnHeartbeat event (default 6s tick)
// Hook: Module Properties -> Events -> OnHeartbeat

#include "lib_plg"

void main()
{
    object oPC = GetFirstPC();
    while(GetIsObjectValid(oPC))
    {
        if(!GetIsDM(oPC))
        {
            // LVAR check (cheap) - SQL query tylko jezeli gracz ma te chorobe
            int nDiseaseId;
            for(nDiseaseId = 0; nDiseaseId < PLG_DIS_COUNT; nDiseaseId++)
            {
                if(GetLocalInt(oPC, PLG_LVAR_HAS + IntToString(nDiseaseId)))
                {
                    PlgCheckProgression(oPC, nDiseaseId);
                    PlgApplyPerTick(oPC, nDiseaseId);
                    PlgApplyContagion(oPC, nDiseaseId);
                }
            }
        }
        oPC = GetNextPC();
    }
}
