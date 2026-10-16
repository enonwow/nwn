// test_tomb.nss — OnUsed demo script for a test placeable.
//
// Place a placeable in the test area (e.g. a lever or barrel),
// set its OnUsed script to "test_tomb", then use it in-game.
//
// First use:  simulates a player death at the placeable's location
//             and opens the write-epitaph window.
// Second use: opens a read window for memorial id 1 (if it exists).
//
// This lets you test both NUI panels without actually dying.

#include "lib_tomb"

void main()
{
    object oPC = GetLastUsedBy();
    if(!GetIsObjectValid(oPC) || !GetIsPC(oPC)) return;

    int nMode = GetLocalInt(OBJECT_SELF, "TEST_TOMB_MODE");

    if(nMode == 0)
    {
        // Simulate death at this placeable's location
        object oArea  = GetArea(OBJECT_SELF);
        vector vPos   = GetPosition(OBJECT_SELF);

        SetLocalString(oPC, TOMB_LVAR_AREA,  GetTag(oArea));
        SetLocalFloat (oPC, TOMB_LVAR_POS_X, vPos.x);
        SetLocalFloat (oPC, TOMB_LVAR_POS_Y, vPos.y);
        SetLocalFloat (oPC, TOMB_LVAR_POS_Z, vPos.z);
        SetLocalString(oPC, TOMB_LVAR_CAUSE, "zabity/a przez testowego trolla");

        SendMessageToPC(oPC, "[Test Epitafium] Otwieranie okna zapisu epitafium...");
        TombCreateWriteWindow(oPC);

        SetLocalInt(OBJECT_SELF, "TEST_TOMB_MODE", 1);
    }
    else
    {
        // Show the first memorial in the DB
        json jAll = TombGetAllActive();
        if(JsonGetLength(jAll) == 0)
        {
            SendMessageToPC(oPC, "[Test Epitafium] Brak nagrobków w bazie — najpierw zapisz epitafium.");
            return;
        }
        int nId = JsonGetInt(JsonObjectGet(JsonArrayGet(jAll, 0), "id"));
        SendMessageToPC(oPC, "[Test Epitafium] Otwieranie nagrobka id=" + IntToString(nId) + "...");
        TombCreateReadWindow(oPC, nId);

        SetLocalInt(OBJECT_SELF, "TEST_TOMB_MODE", 0);
    }
}
