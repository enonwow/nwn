#include "lib_alch_def"
#include "sql_alch"

void main()
{
    object oPC = GetEnteringObject();
    if(!GetIsPC(oPC)) return;

    int nKnown = AlchGetKnownCount(oPC);
    if(nKnown > 0)
    {
        string sMsg = "[Alchemia] Znasz " + IntToString(nKnown) + " przepis"
                    + (nKnown == 1 ? "." : (nKnown < 5 ? "y." : "ów."));
        SendMessageToPC(oPC, sMsg);
    }
}
