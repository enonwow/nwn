// sys_on_enter.nss - module OnClientEnter
// Hook: Module Properties -> Events -> OnClientEnter
//
// If the player was listed as a participant in an active ritual circle
// (e.g., they crashed mid-channeling), notify them so they know to rejoin.

#include "lib_rit"

void main()
{
    object oPC = GetEnteringObject();
    if(!GetIsPC(oPC) || GetIsDM(oPC)) return;

    string sUUID = GetObjectUUID(oPC);

    // Scan active (GATHERING or CASTING) circles for this player's UUID.
    // LIKE match is approximate; RitIsParticipant confirms the exact match.
    sqlquery q = SqlPrepareQueryCampaign(RIT_DB,
        "SELECT tag FROM rit_circles WHERE participants_json LIKE @pat AND state IN (1, 2)");
    SqlBindString(q, "@pat", "%" + sUUID + "%");
    while(SqlStep(q))
    {
        string sTag = SqlGetString(q, 0);
        if(RitIsParticipant(oPC, sTag))
        {
            SetLocalString(oPC, RIT_LVAR_CIRCLE, sTag);
            SendMessageToPC(oPC,
                "[Rytuał] Uczestniczyłeś w rytuale, który trwa lub zbiera uczestników. "
                "Wróć do kręgu, by otworzyć panel.");
            break;
        }
    }
}
