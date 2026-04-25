#include "lib_duel"

void main()
{
    DuelCreateTables();
    DuelExpireOld(DUEL_PENDING_TTL);
}
