#include "lib_haru"

// OnUsed script for a test placeable.
// Simulates a recently-slain wolf (beast, CR 2) for demonstration.
// In production: use Zestaw Haruspika (haru_kit) item on an actual corpse.

void main()
{
    object oPC = GetLastUsedBy();
    if(!GetIsPC(oPC)) return;

    // Use the placeable itself as the simulated corpse source
    object oSelf = OBJECT_SELF;
    SetLocalInt   (oSelf, HARU_SRC_READABLE, 1);
    SetLocalString(oSelf, HARU_SRC_CNAME,    "Wilk Cienisty (TEST)");
    SetLocalInt   (oSelf, HARU_SRC_CTYPE,    HARU_CTYPE_BEAST);
    SetLocalInt   (oSelf, HARU_SRC_CR,       2);

    HaruOpenReading(oPC, oSelf);
}
