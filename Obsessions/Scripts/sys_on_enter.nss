#include "lib_obs"

void main()
{
    object oPC = GetEnteringObject();
    if(!GetIsPC(oPC)) return;

    // Apply saved bonuses immediately on login
    ObsApplyBonuses(oPC);

    // Notify player if they have any active obsessions
    int nActive = 0;
    int nMadness = 0;
    int nIdx;
    for(nIdx = 0; nIdx < OBS_NUM_CATEGORIES; nIdx++)
    {
        string sCat = ObsGetCategoryAtIndex(nIdx);
        int nTier   = ObsGetTier(ObsGetPoints(oPC, sCat));
        if(nTier >= OBS_TIER_FIXATION) nActive++;
        if(nTier >= OBS_TIER_MADNESS)  nMadness++;
    }

    if(nMadness > 0)
    {
        SendMessageToPC(oPC,
            "[Obsesje] Obłęd przemawia przez " + IntToString(nMadness) + " z twoich obsesji. "
            "Otwórz Kronikę Obsesji, by zobaczyć swój stan.");
        FloatingTextStringOnCreature("Obłęd pulsuje w głowie...", oPC, FALSE);
    }
    else if(nActive > 0)
    {
        SendMessageToPC(oPC,
            "[Obsesje] Masz " + IntToString(nActive) + " aktywn"
            + (nActive == 1 ? "ą obsesję." : "e obsesje."));
    }
}
