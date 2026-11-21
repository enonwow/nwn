#include "lib_wkr"

// OnPlayerDeath (or OnCreatureDeath if a PC dies):
// Hook into OnPlayerDeath in the module. The killer is GetLastKiller().
void main()
{
    object oVictim = GetLastPlayerDied();
    if(!GetIsObjectValid(oVictim)) return;

    object oKiller = GetLastKiller();
    WkrCheckBetrayal(oKiller, oVictim);
}
