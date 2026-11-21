// sys_on_enter.nss — module OnClientEnter: restore chaos state from DB.
// Hook: Module → Events → OnClientEnter

#include "lib_chaos"

void main()
{
    object oPC = GetEnteringObject();
    if(!GetIsPC(oPC) || GetIsDM(oPC)) return;

    ChaosLoadState(oPC);

    int nCP = ChaosGetCP(oPC);
    if(nCP >= CHAOS_THRESHOLD)
        SendMessageToPC(oPC,
            "[Chaos] Pulsacja Nicości: " + IntToString(nCP) + "/" + IntToString(CHAOS_MAX) +
            " — jesteś w strefie kryzysu. Uważaj na zaklęcia!");
}
