// test_rit.nss - OnUsed script for a Ritual Circle placeable
//
// Attach to a placeable's OnUsed event in the toolset.
// The placeable's Tag identifies the circle in the DB, so each
// circle in the world needs a unique tag (e.g. "rit_circle_01").
//
// Demo:
//   1. Place a placeable (e.g. Brazier) in the toolset.
//   2. Set its Tag to "rit_circle_01".
//   3. Assign this script to its OnUsed event.
//   4. Two or more players use the object to open the panel.
//   5. First player clicks a ritual type row to become leader.
//   6. Others click "Dołącz".
//   7. Leader clicks "Zainicjuj Rytuał" (with the required item in inventory).
//   8. After 60 seconds the ritual completes and effects are applied.

#include "lib_rit"

void main()
{
    object oPC = GetLastUsedBy();
    if(!GetIsPC(oPC) || GetIsDM(oPC)) return;

    RitOpenWindow(oPC, OBJECT_SELF);
}
