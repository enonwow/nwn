// sys_on_load.nss
// OnModuleLoad - initialize DB schema and clean up stale state from previous
// runs (a duel left as IN_PROGRESS or ACCEPTED after a server crash/restart
// is force-expired so players are not locked out of new duels). Hook as the
// module's OnModuleLoad event.
#include "lib_duel"

void main()
{
    DuelCreateTables();
    DuelClearStaleActive();
    DuelExpireOld(DUEL_PENDING_TTL);
}
