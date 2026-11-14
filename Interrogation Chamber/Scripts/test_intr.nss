#include "lib_intr"

// Place this script as OnUsed on a "Krzeslo przesluchan" placeable.
// The placeable must be near a creature that has INTR_IS_PRISONER = 1 set on it.
// The creature's ResRef can optionally have matching rows in intr_confessions
// for custom secrets (see sys_on_load.nss for examples).
//
// Quick test setup in the toolset:
//   1. Create any creature, set Local Int INTR_IS_PRISONER = 1.
//   2. Create a Chair placeable, set OnUsed = "test_intr".
//   3. Enter the module, use the chair.

void main()
{
    object oPC = GetLastUsedBy();
    if(!GetIsPC(oPC)) return;

    // Find the nearest prisoner within 15 metres
    object oPrisoner = OBJECT_INVALID;
    float  fBest     = 15.0;
    object oArea     = GetArea(oPC);
    object oObj      = GetFirstObjectInArea(oArea);

    while(GetIsObjectValid(oObj))
    {
        if(   GetObjectType(oObj) == OBJECT_TYPE_CREATURE
           && GetLocalInt(oObj, "INTR_IS_PRISONER")
           && !GetIsDead(oObj))
        {
            float fDist = GetDistanceBetween(oPC, oObj);
            if(fDist < fBest)
            {
                fBest     = fDist;
                oPrisoner = oObj;
            }
        }
        oObj = GetNextObjectInArea(oArea);
    }

    if(!GetIsObjectValid(oPrisoner))
    {
        SendMessageToPC(oPC,
            "[Przesluchanie] Brak wieznia w poblizu. "
            "Ustaw INTR_IS_PRISONER = 1 na stworzeniu w odleglosci do 15 m.");
        return;
    }

    // Show statistics banner if the PC has prior interrogation history
    int nTotal  = IntrGetTotalSessions(GetObjectUUID(oPC));
    int nBroken = IntrGetTotalBroken(GetObjectUUID(oPC));
    if(nTotal > 0)
        SendMessageToPC(oPC,
            "[Przesluchanie] Sesje lacznie: " + IntToString(nTotal)
            + ", zlaman: " + IntToString(nBroken) + ".");

    IntrOpenWindow(oPC, oPrisoner);
}
