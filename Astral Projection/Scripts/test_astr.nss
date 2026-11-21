#include "lib_astr"

// OnUsed on a placeable named "Astralny Ołtarz" (or any test placeable).
// Activating it while already in projection cancels it; otherwise enters projection.
void main()
{
    object oPC = GetLastUsedBy();
    if(!GetIsPC(oPC)) return;

    if(GetLocalInt(oPC, ASTR_LVAR_ACTIVE))
        AstrExitProjection(oPC, FALSE);
    else
        AstrEnterProjection(oPC);
}
