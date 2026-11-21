#include "lib_bmt"

void main()
{
    object oPC = GetEnteringObject();
    if(!GetIsPC(oPC)) return;

    string sUuid = GetObjectUUID(oPC);
    BmtRegisterPlayer(sUuid);
    BmtDecayHeat(sUuid);

    // Guard check fires after the PC finishes loading into the area
    int nHeat = BmtGetHeat(sUuid);
    if(nHeat >= BMT_HEAT_WARN)
        DelayCommand(5.0, BmtCheckGuards(oPC));
}
