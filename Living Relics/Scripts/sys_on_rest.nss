#include "lib_mrel"

// Called from module OnPlayerRest (rest completed).
// Gives a small memory tick to all attuned relics (the relic absorbs dream-whispers during sleep)
// and auto-wakes any relic that has reached its memory threshold.
void main()
{
    object oPC = GetLastPCRested();
    if(!GetIsObjectValid(oPC) || !GetIsPC(oPC)) return;

    string sUuid = GetObjectUUID(oPC);
    int i;
    for(i = 1; i <= MREL_SLOT_COUNT; i++)
    {
        json jRelic = MrelDbGetRelic(sUuid, i);
        if(JsonGetType(jRelic) == JSON_TYPE_NULL) continue;

        int nHunger = JsonGetInt(JsonObjectGet(jRelic, "hunger"));
        int nMem    = JsonGetInt(JsonObjectGet(jRelic, "memory"));
        int nMemMax = MrelMemMax(nHunger);

        // Rest gives +1 memory tick (the relic feeds on the edge of dreams)
        if(nMem < nMemMax)
        {
            int nNewMem  = nMem + 1;
            string sVis  = JsonGetString(JsonObjectGet(jRelic, "visions_json"));
            MrelDbUpdateState(sUuid, i, nHunger, nNewMem, sVis);
            if(nNewMem >= nMemMax)
                SendMessageToPC(oPC, "[Relikwia — slot " + IntToString(i)
                    + "] Pieczęć krwi pulsuje słabo… Relikwia jest gotowa na przebudzenie.");
        }
        else
        {
            // Auto-wake relics that are ready on rest
            SetLocalInt(oPC, "MREL_LAST_TRIG_" + IntToString(i), MREL_TRIG_REST);
            AssignCommand(oPC, DelayCommand(2.0, MrelWakeRelic(oPC, i)));
        }
    }

    int nToken = NuiFindWindow(oPC, MREL_WINDOW);
    if(nToken != 0) DelayCommand(2.5, MrelFeedRelicList(oPC, nToken));
}
