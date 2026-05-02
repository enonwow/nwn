// sys_on_pdeath.nss — Bounty Contracts: OnPlayerDeath hook.
// Auto-pays the reward when a hunter kills a PC target they have an active contract on.
#include "lib_bnt"

void main()
{
    object oDeadPC = GetLastPlayerDied();
    if(!GetIsObjectValid(oDeadPC)) return;

    // Identify the killer: try hostile actor first, then last damager
    object oKiller = GetLastHostileActor(oDeadPC);
    if(!GetIsObjectValid(oKiller) || !GetIsPC(oKiller))
        oKiller = GetLastDamager(oDeadPC);

    int nReward = BntCheckDeathPayout(oDeadPC, oKiller);
    if(nReward <= 0) return;

    GiveGoldToCreature(oKiller, nReward);

    string sMsg = "[Kontrakty] Kontrakt na " + GetName(oDeadPC)
        + " ukończony. Nagroda: " + IntToString(nReward) + " zlota.";
    SendMessageToPC(oKiller, sMsg);
    FloatingTextStringOnCreature(
        "Kontrakt ukończony. +" + IntToString(nReward) + " zl", oKiller, FALSE);

    // Refresh the killer's window if open
    int nTk = NuiFindWindow(oKiller, BNT_WINDOW);
    if(nTk != 0) BntSwapToBoard(oKiller, nTk);
}
