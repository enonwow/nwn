// sys_on_enter.nss — Bounty Contracts: OnClientEnter hook.
// Registers the entering PC in the players table so they can be searched
// as bounty targets, and notifies them if a contract exists on their head.
#include "lib_bnt_def"

void main()
{
    object oPC = GetEnteringObject();
    if(!GetIsPC(oPC) || GetIsDMPossessed(oPC)) return;

    BntRegisterPlayer(oPC);

    // Check if anyone has posted a bounty on this PC
    sqlquery q = SqlPrepareQueryCampaign("bounty",
        "SELECT COUNT(*) FROM bnt_contracts "
        "WHERE target_uuid = @uuid AND state IN (@open, @acc)");
    SqlBindString(q, "@uuid", GetObjectUUID(oPC));
    SqlBindInt   (q, "@open", BNT_STATE_OPEN);
    SqlBindInt   (q, "@acc",  BNT_STATE_ACCEPTED);
    if(SqlStep(q) && SqlGetInt(q, 0) > 0)
    {
        DelayCommand(3.0, SendMessageToPC(oPC,
            "[Kontrakty] Na twoja glowe wystawiono nagrode. Oczy w slepy zaul."));
        DelayCommand(3.0, FloatingTextStringOnCreature(
            "Kontrakt na twoja glowe!", oPC, FALSE));
    }
}
