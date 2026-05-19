// sys_on_enter.nss — module OnClientEnter: register PC and restore permanent effects

#include "lib_bur"

void main()
{
    object oPC = GetEnteringObject();
    if(!GetIsPC(oPC)) return;

    BurEnsureRecord(oPC);

    // Re-apply permanent milestone effects lost on relog.
    BurRestorePermanentEffects(oPC);

    json jRecord = BurGetRecord(oPC);
    if(JsonGetType(jRecord) == JSON_TYPE_NULL) return;

    int nTotal = JsonGetInt(JsonObjectGet(jRecord, "total_pauper"))
               + JsonGetInt(JsonObjectGet(jRecord, "total_proper"))
               + JsonGetInt(JsonObjectGet(jRecord, "total_sacred"));

    if(nTotal > 0)
    {
        SendMessageToPC(oPC,
            "[Pogrzebnik] Masz na koncie " + IntToString(nTotal)
            + " rytua\305\202(\303\263w) pogrzebowych. Podejd\305\272 do kamiennego sto\305\202u grabarza.");
    }
}
