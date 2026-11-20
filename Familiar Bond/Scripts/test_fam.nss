// OnUsed script for the "Kamień Więzi" (Bond Stone) placeable.
// Place a placeable (any resref) in the module with this as its OnUsed script.
// Tag suggestion: "bonding_stone"
#include "lib_fam"

void main()
{
    object oPC = GetLastUsedBy();
    if(!GetIsPC(oPC)) return;

    // Check if mourning record exists but bond is gone (rebond scenario)
    if(!FamExists(oPC))
    {
        // Check if there's an orphaned mourning record
        sqlquery q = SqlPrepareQueryCampaign("familiar",
            "SELECT mourning_until FROM fam_familiar WHERE uuid = @uuid");
        SqlBindString(q, "@uuid", GetObjectUUID(oPC));
        if(SqlStep(q))
        {
            int nMourn = SqlGetInt(q, 0);
            if(nMourn > 0 && FamNowUnix() < nMourn)
            {
                int nLeft = nMourn - FamNowUnix();
                SendMessageToPC(oPC,
                    "[Znamię] Kamień milczy. Twoja dusza nosi żałobę po utraconym towarzyszu. "
                    "Poczekaj jeszcze " + IntToString(nLeft / 3600) + " godzin.");
                return;
            }
            // Mourning expired — clean up stale record
            FamDeleteBond(oPC);
        }
    }

    FamOpenWindow(oPC);
}
