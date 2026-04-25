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
        SendMessageToPC(oPC, "[Pojedynek] Czeka na ciebie "
            + IntToString(nCnt) + " wyzwan(ie). Sprawdz tablice honoru.");
    }
}
