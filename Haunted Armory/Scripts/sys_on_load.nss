#include "sql_haunt"
#include "nwnx_events"

void main()
{
    HauntCreateTables();

    // Subscribe to OnCreatureDeath via NWNX_Events so every creature kill
    // is routed through haunt_on_death.nss regardless of the creature's
    // own death script.
    NWNX_Events_SubscribeEvent("NWNX_ON_CREATURE_DEATH_BEFORE", "haunt_on_death");
}
