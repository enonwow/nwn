#include "lib_exrc"

// OnUsed script for a test placeable.
// Behavior depends on whether the user is already possessed:
//   - Clean PC: inflicts level 1 possession (test the effects)
//   - Possessed PC: opens the detect window on self (exorcist mode)
//   - DM pressing the object: opens detect window targeting nearest PC

void main()
{
    object oUser = GetLastUsedBy();
    if(!GetIsObjectValid(oUser)) return;

    if(GetIsDM(oUser))
    {
        // DM: pick nearest PC to inspect/exorcise
        object oTarget = GetNearestCreature(CREATURE_TYPE_PLAYER_CHAR,
            PLAYER_CHAR_IS_PC, OBJECT_SELF, 1);
        if(GetIsObjectValid(oTarget))
            ExrcOpenDetectWindow(oUser, oTarget);
        else
            SendMessageToPC(oUser, "[Egzorcyzm] Brak graczy w zasięgu.");
        return;
    }

    if(!GetIsPC(oUser)) return;

    int nLevel = ExrcGetLevel(oUser);

    if(nLevel == EXRC_LEVEL_CLEAN)
    {
        // Inflict level 1 possession for testing
        ExrcInflictPossession(oUser, EXRC_LEVEL_WHISPERS, "Cień Bez Imienia");
        SendMessageToPC(oUser,
            "[Test] Ołtarz pulsuje złowrogą energią... coś wślizgnęło się do twojej duszy.");
    }
    else
    {
        // Open detect window on self so the PC can trigger exorcism
        ExrcOpenDetectWindow(oUser, oUser);
    }
}
