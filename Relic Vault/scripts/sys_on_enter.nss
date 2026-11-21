#include "lib_rlc"

void main()
{
    object oPC = GetEnteringObject();
    if(!GetIsPC(oPC)) return;

    // Permanent effects don't persist through server restarts — reapply on login.
    RlcApplyEffects(oPC);

    // If the player was offline long enough for curse escalation, catch up one tick.
    RlcCheckCurseTick(oPC);
}
