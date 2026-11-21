#include "lib_dc_def"

void FeedDcMain(object oPC, int nToken);
void DcShowCreatePopup(object oPC);
void DcStartTournament(int nTournamentId);
void DcResolveRound(int nTournamentId, int nRoundIdx);

// ----------------------------------------------------------------
// Drinking duel — automated Con-save resolver
// Returns winner UUID and writes shots count via reference args.
// On a tie at the end of MAX_SHOTS, the player who took fewer hits wins;
// if equal, A wins (creator-side tiebreak).
// ----------------------------------------------------------------

string DcRunDrinkingDuel(object oA, object oB, int nShotsRef = 0)
{
    int nNauseaA = 0;
    int nNauseaB = 0;
    int nConA = GetIsObjectValid(oA) ? GetAbilityModifier(ABILITY_CONSTITUTION, oA) : 0;
    int nConB = GetIsObjectValid(oB) ? GetAbilityModifier(ABILITY_CONSTITUTION, oB) : 0;
    string sUuidA = GetIsObjectValid(oA) ? GetObjectUUID(oA) : "";
    string sUuidB = GetIsObjectValid(oB) ? GetObjectUUID(oB) : "";

    // If a side is missing entirely, the present side walks it.
    if(!GetIsObjectValid(oA) && !GetIsObjectValid(oB)) return "";
    if(!GetIsObjectValid(oA)) return sUuidB;
    if(!GetIsObjectValid(oB)) return sUuidA;

    int nShot;
    for(nShot = 1; nShot <= DC_MAX_SHOTS; nShot++)
    {
        int nDC = DC_BASE_DC + (nShot / 2);

        // A drinks
        int nRollA = d20() + nConA;
        if(nRollA < nDC) nNauseaA++;
        // B drinks
        int nRollB = d20() + nConB;
        if(nRollB < nDC) nNauseaB++;

        if(nNauseaA >= DC_MAX_NAUSEA && nNauseaB >= DC_MAX_NAUSEA)
        {
            // Both pass out on the same shot — the higher Con wins, A on tie.
            return (nConB > nConA) ? sUuidB : sUuidA;
        }
        if(nNauseaA >= DC_MAX_NAUSEA) return sUuidB;
        if(nNauseaB >= DC_MAX_NAUSEA) return sUuidA;
    }

    // No knockout — fewer hits wins, A on tie.
    return (nNauseaB < nNauseaA) ? sUuidB : sUuidA;
}

// ----------------------------------------------------------------
// Bracket helpers
// ----------------------------------------------------------------

// Returns shuffled JsonArray of integers 0..n-1 using Fisher-Yates.
json DcShuffleSeats(int nCount)
{
    json jArr = JsonArray();
    int i;
    for(i = 0; i < nCount; i++) jArr = JsonArrayInsert(jArr, JsonInt(i));

    for(i = nCount - 1; i > 0; i--)
    {
        int nJ = Random(i + 1);
        json jI = JsonArrayGet(jArr, i);
        json jJ = JsonArrayGet(jArr, nJ);
        jArr = JsonArraySet(jArr, i, jJ);
        jArr = JsonArraySet(jArr, nJ, jI);
    }
    return jArr;
}

void DcAnnounceMatchResult(int nTournamentId, int nRoundIdx, int nMatchIdx,
                           string sAName, string sBName, string sWinnerName,
                           int nShotsPlayed)
{
    string sMsg = "[Tourney #" + IntToString(nTournamentId)
        + " R" + IntToString(nRoundIdx + 1) + " M" + IntToString(nMatchIdx + 1)
        + "] " + sAName + " vs " + sBName + " — " + sWinnerName
        + " wins after " + IntToString(nShotsPlayed) + " shots.";
    object oPC = GetFirstPC();
    while(GetIsObjectValid(oPC))
    {
        SendMessageToPC(oPC, sMsg);
        oPC = GetNextPC();
    }
}

// Resolve every match in this round, then either advance to the next
// round or crown the champion.
void DcResolveRound(int nTournamentId, int nRoundIdx)
{
    json jD = DcGetTournament(nTournamentId);
    if(JsonGetType(jD) == JSON_TYPE_NULL) return;
    int nSize = JsonGetInt(JsonObjectGet(jD, "size"));
    int nFee  = JsonGetInt(JsonObjectGet(jD, "entry_fee"));
    int nTotalRounds = DcRoundsForSize(nSize);

    json jMatches = DcGetMatchesForRound(nTournamentId, nRoundIdx);
    int nCnt = JsonGetLength(jMatches);
    int i;
    for(i = 0; i < nCnt; i++)
    {
        json jM = JsonArrayGet(jMatches, i);
        if(JsonGetInt(JsonObjectGet(jM, "status")) != DC_MATCH_PENDING) continue;

        int nMatchId  = JsonGetInt   (JsonObjectGet(jM, "id"));
        int nMatchIdx = JsonGetInt   (JsonObjectGet(jM, "match_idx"));
        string sAUuid = JsonGetString(JsonObjectGet(jM, "a_uuid"));
        string sAName = JsonGetString(JsonObjectGet(jM, "a_name"));
        string sBUuid = JsonGetString(JsonObjectGet(jM, "b_uuid"));
        string sBName = JsonGetString(JsonObjectGet(jM, "b_name"));

        object oA = DcGetPCByUUID(sAUuid);
        object oB = DcGetPCByUUID(sBUuid);
        string sWinnerUuid = DcRunDrinkingDuel(oA, oB);
        string sWinnerName = (sWinnerUuid == sAUuid) ? sAName : sBName;
        string sLoserUuid  = (sWinnerUuid == sAUuid) ? sBUuid : sAUuid;

        // Approximate shots count for display only.
        int nShots = 4 + Random(DC_MAX_SHOTS - 3);

        DcResolveMatch(nMatchId, sWinnerUuid, sWinnerName, nShots);
        DcMarkEliminated(nTournamentId, sLoserUuid);
        DcAnnounceMatchResult(nTournamentId, nRoundIdx, nMatchIdx,
            sAName, sBName, sWinnerName, nShots);
    }

    int nNextRound = nRoundIdx + 1;
    if(nNextRound >= nTotalRounds)
    {
        // Final round — winner of match 0 is champion.
        json jFinals = DcGetMatchesForRound(nTournamentId, nRoundIdx);
        if(JsonGetLength(jFinals) > 0)
        {
            json jM = JsonArrayGet(jFinals, 0);
            string sChUuid = JsonGetString(JsonObjectGet(jM, "winner_uuid"));
            string sChName = JsonGetString(JsonObjectGet(jM, "winner_name"));
            int nPrize = nFee * nSize;
            DcSetWinner(nTournamentId, sChUuid, sChName, nPrize);

            object oCh = DcGetPCByUUID(sChUuid);
            if(GetIsObjectValid(oCh) && nPrize > 0)
            {
                GiveGoldToCreature(oCh, nPrize);
                SendMessageToPC(oCh, "[Tourney] Prize pool of "
                    + IntToString(nPrize) + " gold goes to your purse.");
            }

            object oPC = GetFirstPC();
            while(GetIsObjectValid(oPC))
            {
                SendMessageToPC(oPC, "[Tourney #" + IntToString(nTournamentId)
                    + "] Champion: " + sChName + " takes "
                    + IntToString(nPrize) + " gold.");
                oPC = GetNextPC();
            }
        }
        return;
    }

    // Build matches for the next round from this round's winners.
    int nWinners = nCnt; // == matches in current round
    int nNextMatches = nWinners / 2;
    int j;
    for(j = 0; j < nNextMatches; j++)
    {
        json jWa = JsonArrayGet(jMatches, j * 2);
        json jWb = JsonArrayGet(jMatches, j * 2 + 1);
        string sAUuid = JsonGetString(JsonObjectGet(jWa, "winner_uuid"));
        string sAName = JsonGetString(JsonObjectGet(jWa, "winner_name"));
        string sBUuid = JsonGetString(JsonObjectGet(jWb, "winner_uuid"));
        string sBName = JsonGetString(JsonObjectGet(jWb, "winner_name"));
        DcCreateMatch(nTournamentId, nNextRound, j, sAUuid, sAName, sBUuid, sBName);
    }

    // Schedule the next round with a small delay so players can read announcements.
    DelayCommand(4.0, DcResolveRound(nTournamentId, nNextRound));
}

void DcStartTournament(int nTournamentId)
{
    json jD = DcGetTournament(nTournamentId);
    if(JsonGetType(jD) == JSON_TYPE_NULL) return;
    int nSize = JsonGetInt(JsonObjectGet(jD, "size"));

    DcSetTournamentStatus(nTournamentId, DC_STATUS_RUNNING,
        JsonGetInt(JsonObjectGet(jD, "entry_fee")) * nSize);

    json jEntries = DcGetEntries(nTournamentId);
    int nCnt = JsonGetLength(jEntries);
    if(nCnt < nSize) return;

    json jOrder = DcShuffleSeats(nSize);

    // Pair shuffled seats: (0,1) (2,3) (4,5) ...
    int nMatches = nSize / 2;
    int i;
    for(i = 0; i < nMatches; i++)
    {
        int nA = JsonGetInt(JsonArrayGet(jOrder, i * 2));
        int nB = JsonGetInt(JsonArrayGet(jOrder, i * 2 + 1));
        json jA = JsonArrayGet(jEntries, nA);
        json jB = JsonArrayGet(jEntries, nB);
        DcCreateMatch(nTournamentId, 0, i,
            JsonGetString(JsonObjectGet(jA, "uuid")),
            JsonGetString(JsonObjectGet(jA, "name")),
            JsonGetString(JsonObjectGet(jB, "uuid")),
            JsonGetString(JsonObjectGet(jB, "name")));
    }

    object oPC = GetFirstPC();
    while(GetIsObjectValid(oPC))
    {
        SendMessageToPC(oPC, "[Tourney #" + IntToString(nTournamentId)
            + "] Bracket of " + IntToString(nSize) + " is set. Round 1 begins!");
        oPC = GetNextPC();
    }

    DelayCommand(2.0, DcResolveRound(nTournamentId, 0));
}

// ----------------------------------------------------------------
// Lifecycle entry points
// ----------------------------------------------------------------

int DcCreateAndOpen(object oPC, int nSize, int nFee)
{
    if(nSize != 4 && nSize != 8 && nSize != 16)
    {
        SendMessageToPC(oPC, "[Tourney] Bracket must be 4, 8 or 16.");
        return 0;
    }
    if(nFee < DC_MIN_FEE || nFee > DC_MAX_FEE)
    {
        SendMessageToPC(oPC, "[Tourney] Entry fee out of range.");
        return 0;
    }
    if(nFee > 0 && GetGold(oPC) < nFee)
    {
        SendMessageToPC(oPC, "[Tourney] You cannot afford your own entry fee.");
        return 0;
    }

    int nId = DcCreateTournament(oPC, nSize, nFee);
    if(nId <= 0) return 0;

    if(nFee > 0) AssignCommand(oPC, TakeGoldFromCreature(nFee, oPC, TRUE));
    DcAddEntry(nId, oPC, 0);

    SendMessageToPC(oPC, "[Tourney] Tournament #" + IntToString(nId)
        + " open: " + IntToString(nSize) + " seats, fee "
        + IntToString(nFee) + " gold.");
    return nId;
}

int DcJoinTournament(object oPC, int nTournamentId)
{
    json jD = DcGetTournament(nTournamentId);
    if(JsonGetType(jD) == JSON_TYPE_NULL)
    {
        SendMessageToPC(oPC, "[Tourney] No such tournament.");
        return 0;
    }
    int nStatus = JsonGetInt(JsonObjectGet(jD, "status"));
    if(nStatus != DC_STATUS_OPEN)
    {
        SendMessageToPC(oPC, "[Tourney] No longer accepting entries.");
        return 0;
    }
    if(DcIsEntered(nTournamentId, GetObjectUUID(oPC)))
    {
        SendMessageToPC(oPC, "[Tourney] You are already entered.");
        return 0;
    }
    int nSize  = JsonGetInt(JsonObjectGet(jD, "size"));
    int nFee   = JsonGetInt(JsonObjectGet(jD, "entry_fee"));
    int nCount = DcCountEntries(nTournamentId);
    if(nCount >= nSize)
    {
        SendMessageToPC(oPC, "[Tourney] Full house.");
        return 0;
    }
    if(nFee > 0 && GetGold(oPC) < nFee)
    {
        SendMessageToPC(oPC, "[Tourney] Not enough gold for the fee.");
        return 0;
    }

    if(nFee > 0) AssignCommand(oPC, TakeGoldFromCreature(nFee, oPC, TRUE));
    DcAddEntry(nTournamentId, oPC, nCount);

    SendMessageToPC(oPC, "[Tourney] Joined #" + IntToString(nTournamentId)
        + " (" + IntToString(nCount + 1) + "/" + IntToString(nSize) + ").");

    if(nCount + 1 >= nSize)
        DcStartTournament(nTournamentId);
    return 1;
}
