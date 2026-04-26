#include "lib_duel"

void main()
{
    object oPC = GetEnteringObject();
    if(!GetIsPC(oPC)) return;

    DuelRegisterHonor(oPC);
    DuelExpireOld(DUEL_PENDING_TTL);

    json jIn = DuelGetIncoming(GetObjectUUID(oPC));
    int nCnt = JsonGetLength(jIn);
    if(nCnt > 0)
    {
        SendMessageToPC(oPC, "[Duel] You have "
            + IntToString(nCnt) + " pending challenge(s). Visit the honor board.");
    }
}
