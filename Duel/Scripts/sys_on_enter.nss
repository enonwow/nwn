// sys_on_enter.nss
// OnClientEnter - register the PC in the honor table (so they appear in the
// ranking even with zero duels), expire any stale pending challenges, and
// notify the player if someone challenged them while they were offline.
// Hook as the module's OnClientEnter event.
#include "lib_duel"

void main()
{
    object oPC = GetEnteringObject();
    if(!GetIsPC(oPC)) return;

    DuelRegisterHonor(oPC);
    DuelExpireOld(DUEL_PENDING_TTL);

    if(DuelGetIncomingPendingId(GetObjectUUID(oPC)) > 0)
    {
        SendMessageToPC(oPC,
            "[Duel] You have a pending challenge. Visit the honor board.");
    }
}
