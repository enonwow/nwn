#include "lib_echo_def"
#include "sql_echo"

// Module OnClientEnter — optionally notify PC if their detector crystal
// is in inventory and there are traces in the area they entered.

void main()
{
    object oPC = GetEnteringObject();
    if(!GetIsPC(oPC)) return;

    object oCrystal = GetItemPossessedBy(oPC, ECHO_CRYSTAL_TAG);
    if(!GetIsObjectValid(oCrystal)) return;

    object oArea    = GetArea(oPC);
    string sAreaTag = GetTag(oArea);

    EchoDecayArea(sAreaTag, ECHO_DECAY_HOURS);

    json jTraces = EchoGetAreaTraces(sAreaTag, ECHO_MAX_LIST);
    int nCount   = JsonGetLength(jTraces);
    if(nCount > 0)
    {
        SendMessageToPC(oPC, "[Echo Arkanów] Kryształ rezonansu drga — " + IntToString(nCount)
            + " echo(a) magiczne wykryte w tej lokacji.");
    }
}
