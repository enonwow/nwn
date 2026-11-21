#include "lib_drm"

// OnUsed script for the "Kamień Wizji" (Vision Stone) placeable.
// Place in a dark corner of the world — a cracked stone altar, a circle of bones,
// or a runed monolith. PC clicks the placeable and the trance begins.

void main()
{
    object oPC = GetLastUsedBy();
    if(!GetIsPC(oPC)) return;

    // Atmosphere message before the window opens.
    AssignCommand(oPC, ActionSpeakString("*przymknął oczy, czując jak rzeczywistość kruszy się wokół niego...*",
        TALKVOLUME_TALK));

    DelayCommand(1.5, DrmOpenWindow(oPC));
}
