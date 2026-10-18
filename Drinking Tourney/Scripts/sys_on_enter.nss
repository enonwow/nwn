#include "lib_dc"

void main()
{
    object oPC = GetEnteringObject();
    if(!GetIsPC(oPC)) return;
    int nT = DcGetActiveTournamentForPC(GetObjectUUID(oPC));
    if(nT > 0)
        SendMessageToPC(oPC, "[Tourney] You are entered in tournament #"
            + IntToString(nT) + ". Visit the tavern board.");
}
