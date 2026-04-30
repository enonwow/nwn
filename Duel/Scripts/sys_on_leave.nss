// sys_on_leave.nss
// OnClientLeave - if the leaving PC was in an active duel (PENDING /
// ACCEPTED / IN_PROGRESS), end it as a forfeit on their side. Logging out
// counts as fleeing the arena. Hook as the module's OnClientLeave event.
#include "lib_duel"

void main()
{
    object oPC = GetExitingObject();
    if(!GetIsPC(oPC)) return;

    int nDuelId = GetLocalInt(oPC, DUEL_LVAR_ACTIVE_DUEL);
    if(nDuelId <= 0) return;

    json jD = DuelGetById(nDuelId);
    if(JsonGetType(jD) == JSON_TYPE_NULL) return;

    int nStatus = JsonGetInt(JsonObjectGet(jD, "status"));
    if(!DuelIsActiveStatus(nStatus)) return;

    string sUuidA = JsonGetString(JsonObjectGet(jD, "challenger_uuid"));
    string sUuidB = JsonGetString(JsonObjectGet(jD, "challenged_uuid"));
    string sSelf  = GetObjectUUID(oPC);
    string sWin   = (sSelf == sUuidA) ? sUuidB : sUuidA;

    DuelEnd(nDuelId, sWin, sSelf, DUEL_OUTCOME_FLEE, "Logged out during duel.");
}
