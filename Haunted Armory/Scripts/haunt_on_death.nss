#include "lib_haunt"
#include "nwnx_events"
#include "nwnx_creature"

// NWNX_ON_CREATURE_DEATH_BEFORE event handler.
// OBJECT_SELF is the dying creature; GetLastKiller() returns the killer.
void main()
{
    object oVictim = OBJECT_SELF;
    object oKiller = GetLastKiller();

    // Skip player deaths — this tracks kills made BY players, not deaths of players.
    if(GetIsPC(oVictim)) return;

    HauntRecordKill(oKiller, oVictim);
}
