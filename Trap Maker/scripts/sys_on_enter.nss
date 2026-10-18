#include "lib_trap_def"

void main()
{
    object oPC = GetEnteringObject();
    if(!GetIsPC(oPC)) return;

    TrapInitPCStats(oPC);

    int nPlaced = TrapCountActivePlaced(oPC);
    if(nPlaced > 0)
    {
        string sMsg = "[Pułapki] Masz " + IntToString(nPlaced) + " aktywn"
                    + (nPlaced == 1 ? "ą" : (nPlaced < 5 ? "e" : "ych"))
                    + " pułapk" + (nPlaced == 1 ? "ę" : "i")
                    + " gdzieś w świecie.";
        SendMessageToPC(oPC, sMsg);
    }
}
