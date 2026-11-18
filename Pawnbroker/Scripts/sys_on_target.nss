#include "lib_pawn"

// Called from the module OnPlayerTarget event.
// Routes to PawnOnPlayerTarget if the pawn window is open.
void main()
{
    object oPC = GetLastPlayerToSelectTarget();
    if(NuiFindWindow(oPC, PAWN_WINDOW) != 0)
        PawnOnPlayerTarget(oPC);
}
