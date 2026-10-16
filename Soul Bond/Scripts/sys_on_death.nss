#include "lib_sb"

void main()
{
    object oDead   = OBJECT_SELF;
    object oKiller = GetLastKiller();

    if(GetIsPC(oDead)) return;
    if(!GetIsObjectValid(oKiller)) return;

    // If killed by an associate (henchman/familiar/summoned), credit the master
    object oMaster = GetMaster(oKiller);
    if(GetIsObjectValid(oMaster) && GetIsPC(oMaster))
        oKiller = oMaster;

    SbCreditKill(oKiller);
}
