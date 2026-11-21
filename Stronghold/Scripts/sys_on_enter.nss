#include "lib_sth"

void main()
{
    object oPC = GetEnteringObject();
    if(!GetIsPC(oPC)) return;

    StrongholdCheckUpgrades(oPC);
    StrongholdApplyBonuses(oPC);

    // Notify if any building is under construction
    string sUuid = GetObjectUUID(oPC);
    int    nNow  = StrongholdNow();
    int i;
    for(i = 0; i < STH_BLD_COUNT; i++)
    {
        int nFinish = StrongholdGetUpgradeFinish(sUuid, i);
        if(nFinish > 0 && nNow < nFinish)
        {
            int nSec = nFinish - nNow;
            string sMsg = "[Twierdza] " + StrongholdBuildingName(i)
                + " — rozbudowa w toku, ukończona za ~"
                + IntToString(nSec / 60) + "m " + IntToString(nSec % 60) + "s.";
            DelayCommand(2.0, SendMessageToPC(oPC, sMsg));
        }
    }
}
