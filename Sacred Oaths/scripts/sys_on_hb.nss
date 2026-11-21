// sys_on_hb.nss — module OnHeartbeat: check oath violations every ~60 s
// Hook this script to the module OnHeartbeat event (alongside any existing HB script).

#include "lib_oath"

void main()
{
    object oPC = GetFirstPC();
    while(GetIsObjectValid(oPC))
    {
        if(GetIsPC(oPC) && !GetIsDMPossessed(oPC))
        {
            int nCnt = GetLocalInt(oPC, OATH_LVAR_HB_CNT) + 1;
            SetLocalInt(oPC, OATH_LVAR_HB_CNT, nCnt);

            if(nCnt >= OATH_HB_TICKS)
            {
                DeleteLocalInt(oPC, OATH_LVAR_HB_CNT);
                OathCheckViolations(oPC);
            }
        }
        oPC = GetNextPC();
    }
}
