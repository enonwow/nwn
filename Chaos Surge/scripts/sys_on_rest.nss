// sys_on_rest.nss — module OnPlayerRest (Finished): reduce chaos on rest.
// Hook: Module → Events → OnPlayerRest
// Note: standard NWN fires this on STARTED; for FINISHED phase use NWNX or
// check GetLastPCRested() inside a DelayCommand if needed by the server config.

#include "lib_chaos"

void main()
{
    object oPC = GetLastPCRested();
    if(!GetIsObjectValid(oPC) || !GetIsPC(oPC)) return;

    int nOld = ChaosGetCP(oPC);
    if(nOld <= 0) return;

    int nNew = nOld - CHAOS_REST_REDUCE;
    if(nNew < 0) nNew = 0;
    ChaosSetCP(oPC, nNew);

    SendMessageToPC(oPC,
        "[Chaos] Odpoczynek łagodzi pulsację. Chaos: "
        + IntToString(nNew) + "/" + IntToString(CHAOS_MAX) + ".");

    int nToken = NuiFindWindow(oPC, CHAOS_WINDOW);
    if(nToken != 0)
        FeedChaosWindow(oPC, nToken);

    ChaosSaveState(oPC);
}
