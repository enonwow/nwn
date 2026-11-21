#include "lib_prison"

void main()
{
    object oPC = GetEnteringObject();
    if(!GetIsPC(oPC) || GetIsDMPossessed(oPC)) return;

    // If player had an active sentence when they logged out, restore it.
    if(!PrisonIsActive(oPC)) return;

    int nRemaining = PrisonGetSecondsRemaining(oPC);
    if(nRemaining <= 0)
    {
        // Sentence expired while offline — release immediately.
        PrisonReleasePlayer(oPC, "served");
        return;
    }

    // Teleport back to cell
    object oCell = GetWaypointByTag("PRISON_CELL_WP");
    if(GetIsObjectValid(oCell))
        AssignCommand(oPC, JumpToObject(oCell));

    SendMessageToPC(oPC, "[Więzienie] Twoja kara trwa. Pozostało: " +
        PrisonFormatSeconds(nRemaining) + ".");

    // Restart heartbeat
    if(!GetLocalInt(oPC, PRISON_LVAR_HB))
    {
        SetLocalInt(oPC, PRISON_LVAR_HB, 1);
        DelayCommand(3.0, PrisonShowWindow(oPC));
        DelayCommand(60.0, PrisonHeartbeat(oPC));
    }
}
