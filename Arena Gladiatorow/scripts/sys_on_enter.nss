#include "lib_gla"

void main()
{
    object oPC = GetEnteringObject();
    if(!GetIsPC(oPC)) return;

    ArenaRegisterFighter(oPC);

    json   jF     = ArenaGetFighter(GetObjectUUID(oPC));
    int    nWins  = JsonGetInt(JsonObjectGet(jF, "total_wins"));
    int    nRank  = ArenaGetRank(GetObjectUUID(oPC));
    string sTitle = ArenaTitleFromWins(nWins);

    if(nWins > 0)
    {
        string sMsg = "[Arena] Witaj, " + sTitle + " " + GetName(oPC) +
            ". Twoja pozycja w tabeli: #" + IntToString(nRank) + ".";
        DelayCommand(3.0, SendMessageToPC(oPC, sMsg));
    }
}
