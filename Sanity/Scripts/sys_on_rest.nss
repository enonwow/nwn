// sys_on_rest.nss — module OnPlayerRest hook  (REST_EVENTTYPE_REST_FINISHED).
//   Restores a portion of sanity after a completed rest.

#include "lib_san"

void main()
{
    object oPC = GetLastPCRested();
    if(!GetIsPC(oPC)) return;
    if(GetLastRestEventType() != REST_EVENTTYPE_REST_FINISHED) return;

    SanOnPlayerRest(oPC);
}
