#include "lib_astr"

// OnClientEnter — seeds the SQL row so GetStats works before the first session.
// Also aborts any dangling projection state from a previous disconnect.
void main()
{
    object oPC = GetEnteringObject();
    if(!GetIsPC(oPC)) return;

    AstrEnsureRow(oPC);

    // A player who disconnected mid-projection has stale LVAR state;
    // clean it up so they don't wake up unable to project again.
    if(GetLocalInt(oPC, ASTR_LVAR_ACTIVE))
    {
        DeleteLocalInt(oPC, ASTR_LVAR_ACTIVE);
        DeleteLocalInt(oPC, ASTR_LVAR_TIMER_SECS);
        DeleteLocalInt(oPC, ASTR_LVAR_PERCEIVE_CD);
        AstrRemoveGhostEffects(oPC);
        SendMessageToPC(oPC, "[Projekcja] Połączenie zostało zerwane — projekcja anulowana.");
    }
}
