#include "lib_ma"

void main()
{
    object oPC = GetEnteringObject();
    if(!GetIsPC(oPC)) return;

    // Reapply skill bonuses if the apprentice still has an active master.
    if(MaHasMaster(GetObjectUUID(oPC)))
        MaApplyApprenticeBonuses(oPC);
    else
        MaRemoveApprenticeBonuses(oPC);
}
