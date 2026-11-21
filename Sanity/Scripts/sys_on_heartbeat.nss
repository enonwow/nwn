// sys_on_heartbeat.nss — module OnHeartbeat hook.
//   Runs every 6 seconds; dispatches sanity checks at configured cadences.

#include "lib_san"

void main()
{
    SanHeartbeatTick();
}
