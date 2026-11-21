#include "lib_pact"

// Runs every 6 seconds (module OnHeartbeat). PactCollectToll is a no-op
// until PACT_TOLL_INTERVAL seconds have elapsed since the last toll,
// so the per-PC SQL cost here is one lightweight SELECT by primary key.
void main()
{
    object oPC = GetFirstPC();
    while(GetIsObjectValid(oPC))
    {
        PactCollectToll(oPC);
        oPC = GetNextPC();
    }
}
