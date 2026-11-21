// OnUsed script for a test placeable.
// Demonstrates the Obsessions system: seeds points, opens the journal UI.
#include "lib_obs"

void main()
{
    object oPC = GetLastUsedBy();
    if(!GetIsPC(oPC)) return;

    // Seed sample obsession data so the UI shows meaningful content
    ObsAddPoints(oPC, OBS_CAT_UNDEAD,   80);  // tier OBSESSION
    ObsAddPoints(oPC, OBS_CAT_BLOOD,    55);  // tier COMPULSION
    ObsAddPoints(oPC, OBS_CAT_THEFT,    30);  // tier FIXATION
    ObsAddPoints(oPC, OBS_CAT_DRINK,    10);  // tier LATENT
    ObsAddPoints(oPC, OBS_CAT_ARCANE,   100); // tier MADNESS
    ObsAddPoints(oPC, OBS_CAT_PAIN,     0);
    ObsAddPoints(oPC, OBS_CAT_SHADOW,   48);  // tier FIXATION (near COMPULSION)
    ObsAddPoints(oPC, OBS_CAT_GOLD,     25);  // tier FIXATION (exactly)
    ObsAddPoints(oPC, OBS_CAT_BATTLE,   75);  // tier OBSESSION (exactly)
    ObsAddPoints(oPC, OBS_CAT_DARKNESS, 15);  // tier LATENT

    SendMessageToPC(oPC,
        "[Test — Obsesje] Dodano przykładowe punkty. "
        "Otwieranie Kroniki Obsesji...");

    // Apply bonuses immediately so the player sees effects on their sheet
    ObsApplyBonuses(oPC);

    // Open the journal UI
    ObsOpenUI(oPC);
}
