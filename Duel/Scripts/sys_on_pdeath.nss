// sys_on_pdeath.nss
// OnPlayerDeath - if the dying PC is in an active duel, end the duel as a
// kill and (if the killer was the duel opponent) resurrect the dying player
// on the spot at 1 HP. Hook this script as the module's OnPlayerDeath event.
// Filename is short (max 16 chars) - toolset truncates longer names.
#include "lib_duel"

void main()
{
    object oPC = GetLastPlayerDied();
    if(!GetIsObjectValid(oPC) || !GetIsPC(oPC)) return;

    DuelHandlePlayerDeath(oPC);
}
