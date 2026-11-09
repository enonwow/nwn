#include "lib_mrel"

void main()
{
    object oPC = GetEnteringObject();
    if(!GetIsPC(oPC)) return;

    MrelSyncItems(oPC);

    string sUuid = GetObjectUUID(oPC);
    int i;
    for(i = 1; i <= MREL_SLOT_COUNT; i++)
    {
        json jRelic = MrelDbGetRelic(sUuid, i);
        if(JsonGetType(jRelic) == JSON_TYPE_NULL) continue;

        int nHunger = JsonGetInt(JsonObjectGet(jRelic, "hunger"));
        int nMem    = JsonGetInt(JsonObjectGet(jRelic, "memory"));

        if(nMem >= MrelMemMax(nHunger))
            DelayCommand(5.0, SendMessageToPC(oPC,
                "[Relikwia — slot " + IntToString(i) + "] Pieczęć krwi pulsuje silnie... "
                "Otwórz okno Żywych Relikwii, by wyzwolić wspomnienie."));
    }
}
