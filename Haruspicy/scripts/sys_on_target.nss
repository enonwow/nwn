#include "lib_haru"

// Module OnPlayerTarget hook.
// Fires when a PC completes cursor-select. We handle only
// the haruspicy targeting mode here; other modules' targeting
// modes are unaffected because we exit early if the flag is absent.

void main()
{
    object oPC = GetLastPlayerToSelectTarget();
    if(!GetIsPC(oPC)) return;
    if(!GetLocalInt(oPC, HARU_LVAR_TARGETING)) return;

    DeleteLocalInt(oPC, HARU_LVAR_TARGETING);

    object oTarget = GetTargetingModeSelectedObject();
    if(!GetIsObjectValid(oTarget))
    {
        SendMessageToPC(oPC, "[Haruspika] Nie wskazano celu.");
        return;
    }

    HaruOpenReading(oPC, oTarget);
}
