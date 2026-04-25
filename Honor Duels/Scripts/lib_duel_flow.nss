#include "lib_duel_def"

// ----------------------------------------------------------------
// Honor Duels — flow + state machine
// Triggered from event handlers and timers; no UI building here.
// ----------------------------------------------------------------

void DuelTick(int nDuelId);
void DuelBegin(int nDuelId);
void DuelEnd(int nDuelId, string sWinnerUuid, string sLoserUuid, string sNote, int bKill);
void CreateDuelHud(object oPC, int nDuelId);
void DestroyDuelHud(object oPC);
void FeedDuelMain(object oPC, int nToken);
void DuelShowIncomingPopup(object oPC, int nDuelId);

// ----------------------------------------------------------------
// Notifications
// ----------------------------------------------------------------

void DuelBroadcast(string sMsg, object oA, object oB)
{
    if(GetIsObjectValid(oA))
    {
        FloatingTextStringOnCreature(sMsg, oA, FALSE);
        SendMessageToPC(oA, "[Pojedynek] " + sMsg);
    }
    if(GetIsObjectValid(oB))
    {
        FloatingTextStringOnCreature(sMsg, oB, FALSE);
        SendMessageToPC(oB, "[Pojedynek] " + sMsg);
    }
}

void DuelNotifyChallenged(string sChallengedUuid, int nDuelId, string sChallengerName)
{
    object oPC = DuelGetPCByUUID(sChallengedUuid);
    if(!GetIsObjectValid(oPC)) return;

    string sMsg = sChallengerName + " rzuca ci wyzwanie. Honor czeka.";
    FloatingTextStringOnCreature(sMsg, oPC, FALSE);
    SendMessageToPC(oPC, "[Pojedynek] " + sMsg);

    DelayCommand(0.5, DuelShowIncomingPopup(oPC, nDuelId));
}

// ----------------------------------------------------------------
// Challenge submission
// ----------------------------------------------------------------

int DuelSubmitChallenge(object oPC, string sTargetUuid, string sTargetName,
                        int nRules, int nWinCond, int nStake)
{
    if(sTargetUuid == "" || sTargetUuid == GetObjectUUID(oPC))
    {
        SendMessageToPC(oPC, "[Pojedynek] Nieprawidlowy cel.");
        return 0;
    }

    if(DuelHasActiveBetween(GetObjectUUID(oPC), sTargetUuid))
    {
        SendMessageToPC(oPC, "[Pojedynek] Macie juz aktywny pojedynek lub wyzwanie.");
        return 0;
    }

    if(nStake < 0) nStake = 0;
    if(nStake > 0 && GetGold(oPC) < nStake)
    {
        SendMessageToPC(oPC, "[Pojedynek] Nie masz tyle zlota na stawke.");
        return 0;
    }

    object oTarget = DuelGetPCByUUID(sTargetUuid);
    if(!GetIsObjectValid(oTarget))
    {
        SendMessageToPC(oPC, "[Pojedynek] Przeciwnik musi byc obecny.");
        return 0;
    }

    int nId = DuelCreate(oPC, oTarget, nRules, nWinCond, nStake);
    if(nId <= 0)
    {
        SendMessageToPC(oPC, "[Pojedynek] Nie udalo sie utworzyc wyzwania.");
        return 0;
    }

    if(nStake > 0)
        AssignCommand(oPC, TakeGoldFromCreature(nStake, oPC, TRUE));

    SendMessageToPC(oPC, "[Pojedynek] Wyzwanie wyslane do " + sTargetName + ".");
    DuelNotifyChallenged(sTargetUuid, nId, GetName(oPC));
    return nId;
}

// ----------------------------------------------------------------
// Decline / cancel / expire helpers
// ----------------------------------------------------------------

void DuelRefundStake(string sUuid, int nGold)
{
    if(nGold <= 0) return;
    object oPC = DuelGetPCByUUID(sUuid);
    if(GetIsObjectValid(oPC))
    {
        GiveGoldToCreature(oPC, nGold);
        SendMessageToPC(oPC, "[Pojedynek] Stawka " + IntToString(nGold) + " zlota zwrocona.");
    }
    // Offline: gold is forfeit. A real server would queue a refund into Mailbox.
}

void DuelDecline(object oPC, int nDuelId)
{
    json jD = DuelGetById(nDuelId);
    if(JsonGetType(jD) == JSON_TYPE_NULL) return;

    int nStatus = JsonGetInt(JsonObjectGet(jD, "status"));
    if(nStatus != DUEL_STATUS_PENDING) return;

    string sChallengedUuid = JsonGetString(JsonObjectGet(jD, "challenged_uuid"));
    if(GetObjectUUID(oPC) != sChallengedUuid) return;

    string sChallengerUuid = JsonGetString(JsonObjectGet(jD, "challenger_uuid"));
    string sChallengerName = JsonGetString(JsonObjectGet(jD, "challenger_name"));
    int nStake = JsonGetInt(JsonObjectGet(jD, "stake_gold"));

    DuelSetOutcome(nDuelId, DUEL_STATUS_DECLINED, "", GetObjectUUID(oPC),
                   "Odrzucone bez walki.");

    DuelRefundStake(sChallengerUuid, nStake);

    DuelAdjustHonor(GetObjectUUID(oPC), GetName(oPC),
                    DUEL_HONOR_DECLINE, 0, 0, 1, 0, 0);

    object oCh = DuelGetPCByUUID(sChallengerUuid);
    DuelBroadcast("Wyzwanie odrzucone. Honor pochylony nizej niz miecz.",
                  oCh, oPC);

    object oRefresh = GetFirstPC();
    while(GetIsObjectValid(oRefresh))
    {
        int nTk = NuiFindWindow(oRefresh, DUEL_WINDOW);
        if(nTk != 0) FeedDuelMain(oRefresh, nTk);
        oRefresh = GetNextPC();
    }
}

void DuelCancelOutgoing(object oPC, int nDuelId)
{
    json jD = DuelGetById(nDuelId);
    if(JsonGetType(jD) == JSON_TYPE_NULL) return;
    if(JsonGetInt(JsonObjectGet(jD, "status")) != DUEL_STATUS_PENDING) return;
    if(JsonGetString(JsonObjectGet(jD, "challenger_uuid")) != GetObjectUUID(oPC)) return;

    int nStake = JsonGetInt(JsonObjectGet(jD, "stake_gold"));
    DuelSetOutcome(nDuelId, DUEL_STATUS_CANCELED,
                   "", "", "Anulowane przez wyzywajacego.");
    if(nStake > 0) GiveGoldToCreature(oPC, nStake);

    SendMessageToPC(oPC, "[Pojedynek] Wyzwanie wycofane.");

    int nTk = NuiFindWindow(oPC, DUEL_WINDOW);
    if(nTk != 0) FeedDuelMain(oPC, nTk);
}

// ----------------------------------------------------------------
// Accept → countdown → begin
// ----------------------------------------------------------------

void DuelAccept(object oPC, int nDuelId)
{
    json jD = DuelGetById(nDuelId);
    if(JsonGetType(jD) == JSON_TYPE_NULL) return;

    int nStatus = JsonGetInt(JsonObjectGet(jD, "status"));
    if(nStatus != DUEL_STATUS_PENDING) return;

    string sChallengedUuid = JsonGetString(JsonObjectGet(jD, "challenged_uuid"));
    if(GetObjectUUID(oPC) != sChallengedUuid) return;

    string sChallengerUuid = JsonGetString(JsonObjectGet(jD, "challenger_uuid"));
    object oChallenger = DuelGetPCByUUID(sChallengerUuid);
    if(!GetIsObjectValid(oChallenger))
    {
        SendMessageToPC(oPC, "[Pojedynek] Wyzywajacego juz nie ma w grze.");
        DuelSetOutcome(nDuelId, DUEL_STATUS_EXPIRED, "", "", "Brak wyzywajacego.");
        return;
    }

    int nStake = JsonGetInt(JsonObjectGet(jD, "stake_gold"));
    if(nStake > 0 && GetGold(oPC) < nStake)
    {
        SendMessageToPC(oPC, "[Pojedynek] Nie masz zlota by sprostac stawce.");
        return;
    }
    if(nStake > 0)
        AssignCommand(oPC, TakeGoldFromCreature(nStake, oPC, TRUE));

    // Distance check — must be near the challenger (arena point).
    float fX = JsonGetFloat(JsonObjectGet(jD, "arena_x"));
    float fY = JsonGetFloat(JsonObjectGet(jD, "arena_y"));
    vector vArena = Vector(fX, fY, JsonGetFloat(JsonObjectGet(jD, "arena_z")));
    float fDist = GetDistanceBetweenLocations(GetLocation(oPC),
        Location(GetArea(oChallenger), vArena, 0.0));
    if(fDist > DUEL_ARENA_RADIUS * 1.5)
    {
        SendMessageToPC(oPC, "[Pojedynek] Musisz stawic sie w poblizu wyzywajacego.");
        if(nStake > 0) GiveGoldToCreature(oPC, nStake);
        return;
    }

    DuelSetStatus(nDuelId, DUEL_STATUS_ACCEPTED);

    SetLocalInt(oPC,         DUEL_LVAR_ACTIVE_DUEL, nDuelId);
    SetLocalInt(oChallenger, DUEL_LVAR_ACTIVE_DUEL, nDuelId);

    DuelBroadcast("Wyzwanie przyjete. Krew rozstrzygnie spor.",
                  oChallenger, oPC);

    // Countdown floating text on both
    int i;
    for(i = DUEL_COUNTDOWN_SECONDS; i > 0; i--)
    {
        float fT = IntToFloat(DUEL_COUNTDOWN_SECONDS - i);
        string sCd = IntToString(i) + "...";
        DelayCommand(fT, FloatingTextStringOnCreature(sCd, oChallenger, FALSE));
        DelayCommand(fT, FloatingTextStringOnCreature(sCd, oPC, FALSE));
    }
    DelayCommand(IntToFloat(DUEL_COUNTDOWN_SECONDS), DuelBegin(nDuelId));
}

// ----------------------------------------------------------------
// Begin
// ----------------------------------------------------------------

void DuelMakeHostile(object oA, object oB)
{
    SetIsTemporaryEnemy(oB, oA, FALSE, 0.0);
    SetIsTemporaryEnemy(oA, oB, FALSE, 0.0);
    AdjustReputation(oB, oA, -100);
    AdjustReputation(oA, oB, -100);
}

void DuelRestoreNeutral(object oA, object oB)
{
    if(GetIsObjectValid(oA) && GetIsObjectValid(oB))
    {
        SetIsTemporaryNeutral(oB, oA, FALSE, 0.0);
        SetIsTemporaryNeutral(oA, oB, FALSE, 0.0);
        AdjustReputation(oB, oA, 100);
        AdjustReputation(oA, oB, 100);
    }
}

void DuelBegin(int nDuelId)
{
    json jD = DuelGetById(nDuelId);
    if(JsonGetType(jD) == JSON_TYPE_NULL) return;
    if(JsonGetInt(JsonObjectGet(jD, "status")) != DUEL_STATUS_ACCEPTED) return;

    object oA = DuelGetPCByUUID(JsonGetString(JsonObjectGet(jD, "challenger_uuid")));
    object oB = DuelGetPCByUUID(JsonGetString(JsonObjectGet(jD, "challenged_uuid")));
    if(!GetIsObjectValid(oA) || !GetIsObjectValid(oB))
    {
        DuelSetOutcome(nDuelId, DUEL_STATUS_EXPIRED, "", "", "Strona opuscila gre.");
        return;
    }

    DuelSetStatus(nDuelId, DUEL_STATUS_IN_PROGRESS);

    DuelMakeHostile(oA, oB);

    DuelBroadcast("WALKA!", oA, oB);

    CreateDuelHud(oA, nDuelId);
    CreateDuelHud(oB, nDuelId);

    DelayCommand(IntToFloat(DUEL_TICK_PERIOD), DuelTick(nDuelId));
}

// ----------------------------------------------------------------
// Tick: HP / bounds / win condition checks
// ----------------------------------------------------------------

int DuelHpFraction(object oPC)
{
    int nMax = GetMaxHitPoints(oPC);
    if(nMax <= 0) return 100;
    int nCur = GetCurrentHitPoints(oPC);
    if(nCur < 0) nCur = 0;
    return (nCur * 100) / nMax;
}

void DuelUpdateHud(object oPC, object oOpp, int nFracSelf, int nFracOpp)
{
    int nTk = NuiFindWindow(oPC, DUEL_WIN_HUD);
    if(nTk == 0) return;
    NuiSetBind(oPC, nTk, DUEL_BIND_HUD_SELF_HP, JsonFloat(IntToFloat(nFracSelf) / 100.0));
    NuiSetBind(oPC, nTk, DUEL_BIND_HUD_OPP_HP,  JsonFloat(IntToFloat(nFracOpp) / 100.0));
    NuiSetBind(oPC, nTk, DUEL_BIND_HUD_SELF_HP_TIP, JsonString(IntToString(nFracSelf) + "%"));
    NuiSetBind(oPC, nTk, DUEL_BIND_HUD_OPP_HP_TIP,  JsonString(IntToString(nFracOpp) + "%"));
    NuiSetBind(oPC, nTk, DUEL_BIND_HUD_TITLE,
        JsonString("Pojedynek: " + GetName(oOpp)));
}

void DuelTick(int nDuelId)
{
    json jD = DuelGetById(nDuelId);
    if(JsonGetType(jD) == JSON_TYPE_NULL) return;
    if(JsonGetInt(JsonObjectGet(jD, "status")) != DUEL_STATUS_IN_PROGRESS) return;

    string sUuidA = JsonGetString(JsonObjectGet(jD, "challenger_uuid"));
    string sUuidB = JsonGetString(JsonObjectGet(jD, "challenged_uuid"));
    object oA = DuelGetPCByUUID(sUuidA);
    object oB = DuelGetPCByUUID(sUuidB);

    int nWinCond = JsonGetInt(JsonObjectGet(jD, "win_cond"));

    // Disconnect / death-by-ragequit handling.
    if(!GetIsObjectValid(oA))
    {
        DuelEnd(nDuelId, sUuidB, sUuidA, "Wyzywajacy opuscil arene.", FALSE);
        return;
    }
    if(!GetIsObjectValid(oB))
    {
        DuelEnd(nDuelId, sUuidA, sUuidB, "Wyzwany opuscil arene.", FALSE);
        return;
    }

    int nDeadA = GetIsDead(oA);
    int nDeadB = GetIsDead(oB);
    if(nDeadA && !nDeadB)
    {
        DuelEnd(nDuelId, sUuidB, sUuidA, "Smiertelny cios.", TRUE);
        return;
    }
    if(nDeadB && !nDeadA)
    {
        DuelEnd(nDuelId, sUuidA, sUuidB, "Smiertelny cios.", TRUE);
        return;
    }
    if(nDeadA && nDeadB)
    {
        DuelEnd(nDuelId, "", "", "Obaj polegli.", FALSE);
        return;
    }

    int nFracA = DuelHpFraction(oA);
    int nFracB = DuelHpFraction(oB);
    DuelUpdateHud(oA, oB, nFracA, nFracB);
    DuelUpdateHud(oB, oA, nFracB, nFracA);

    if(nWinCond == DUEL_WIN_FIRST_BLOOD)
    {
        int nThr = FloatToInt(DUEL_FIRST_BLOOD_FRAC * 100.0);
        if(nFracA <= nThr && nFracB > nThr)
        {
            DuelEnd(nDuelId, sUuidB, sUuidA, "Pierwsza krew.", FALSE);
            return;
        }
        if(nFracB <= nThr && nFracA > nThr)
        {
            DuelEnd(nDuelId, sUuidA, sUuidB, "Pierwsza krew.", FALSE);
            return;
        }
        if(nFracA <= nThr && nFracB <= nThr)
        {
            string sWin = (nFracA >= nFracB) ? sUuidA : sUuidB;
            string sLos = (nFracA >= nFracB) ? sUuidB : sUuidA;
            DuelEnd(nDuelId, sWin, sLos, "Obaj zranieni — wygrywa silniejszy.", FALSE);
            return;
        }
    }

    // Bounds check
    float fX = JsonGetFloat(JsonObjectGet(jD, "arena_x"));
    float fY = JsonGetFloat(JsonObjectGet(jD, "arena_y"));
    float fZ = JsonGetFloat(JsonObjectGet(jD, "arena_z"));
    string sAreaTag = JsonGetString(JsonObjectGet(jD, "arena_area"));
    object oArea    = GetObjectByTag(sAreaTag);
    if(!GetIsObjectValid(oArea)) oArea = GetArea(oA);
    location lArena = Location(oArea, Vector(fX, fY, fZ), 0.0);

    float fDistA = GetDistanceBetweenLocations(GetLocation(oA), lArena);
    float fDistB = GetDistanceBetweenLocations(GetLocation(oB), lArena);

    int nOobA = GetLocalInt(oA, DUEL_LVAR_OUT_OF_BOUNDS);
    int nOobB = GetLocalInt(oB, DUEL_LVAR_OUT_OF_BOUNDS);

    int bAreaA = (GetArea(oA) == oArea);
    int bAreaB = (GetArea(oB) == oArea);

    if(!bAreaA || fDistA > DUEL_ARENA_RADIUS) nOobA++; else nOobA = 0;
    if(!bAreaB || fDistB > DUEL_ARENA_RADIUS) nOobB++; else nOobB = 0;

    SetLocalInt(oA, DUEL_LVAR_OUT_OF_BOUNDS, nOobA);
    SetLocalInt(oB, DUEL_LVAR_OUT_OF_BOUNDS, nOobB);

    int nTkA = NuiFindWindow(oA, DUEL_WIN_HUD);
    int nTkB = NuiFindWindow(oB, DUEL_WIN_HUD);
    if(nTkA != 0) NuiSetBind(oA, nTkA, DUEL_BIND_HUD_BOUNDS,
        JsonString(nOobA > 0 ? "Wracaj na arene! " + IntToString(nOobA) + "/"
            + IntToString(FloatToInt(DUEL_OUT_OF_BOUNDS_TIME)) : ""));
    if(nTkB != 0) NuiSetBind(oB, nTkB, DUEL_BIND_HUD_BOUNDS,
        JsonString(nOobB > 0 ? "Wracaj na arene! " + IntToString(nOobB) + "/"
            + IntToString(FloatToInt(DUEL_OUT_OF_BOUNDS_TIME)) : ""));

    if(IntToFloat(nOobA) >= DUEL_OUT_OF_BOUNDS_TIME)
    {
        DuelEnd(nDuelId, sUuidB, sUuidA, "Ucieczka z areny.", FALSE);
        return;
    }
    if(IntToFloat(nOobB) >= DUEL_OUT_OF_BOUNDS_TIME)
    {
        DuelEnd(nDuelId, sUuidA, sUuidB, "Ucieczka z areny.", FALSE);
        return;
    }

    DelayCommand(IntToFloat(DUEL_TICK_PERIOD), DuelTick(nDuelId));
}

// ----------------------------------------------------------------
// Yield
// ----------------------------------------------------------------

void DuelYield(object oPC)
{
    int nDuelId = GetLocalInt(oPC, DUEL_LVAR_ACTIVE_DUEL);
    if(nDuelId <= 0) return;

    json jD = DuelGetById(nDuelId);
    if(JsonGetType(jD) == JSON_TYPE_NULL) return;
    if(JsonGetInt(JsonObjectGet(jD, "status")) != DUEL_STATUS_IN_PROGRESS) return;

    string sUuidA = JsonGetString(JsonObjectGet(jD, "challenger_uuid"));
    string sUuidB = JsonGetString(JsonObjectGet(jD, "challenged_uuid"));
    string sSelf  = GetObjectUUID(oPC);
    if(sSelf != sUuidA && sSelf != sUuidB) return;

    string sWin = (sSelf == sUuidA) ? sUuidB : sUuidA;
    DuelEnd(nDuelId, sWin, sSelf, "Poddanie sie.", FALSE);
}

// ----------------------------------------------------------------
// End — outcome resolution + honor + stake transfer
// ----------------------------------------------------------------

void DuelHealAndCleanup(object oPC)
{
    if(!GetIsObjectValid(oPC)) return;
    DeleteLocalInt(oPC, DUEL_LVAR_ACTIVE_DUEL);
    DeleteLocalInt(oPC, DUEL_LVAR_OUT_OF_BOUNDS);
    DestroyDuelHud(oPC);
}

void DuelEnd(int nDuelId, string sWinnerUuid, string sLoserUuid, string sNote, int bKill)
{
    json jD = DuelGetById(nDuelId);
    if(JsonGetType(jD) == JSON_TYPE_NULL) return;
    int nStatusNow = JsonGetInt(JsonObjectGet(jD, "status"));
    if(nStatusNow == DUEL_STATUS_COMPLETED) return;

    string sUuidA = JsonGetString(JsonObjectGet(jD, "challenger_uuid"));
    string sUuidB = JsonGetString(JsonObjectGet(jD, "challenged_uuid"));
    string sNameA = JsonGetString(JsonObjectGet(jD, "challenger_name"));
    string sNameB = JsonGetString(JsonObjectGet(jD, "challenged_name"));
    int nStake    = JsonGetInt   (JsonObjectGet(jD, "stake_gold"));
    int nWinCond  = JsonGetInt   (JsonObjectGet(jD, "win_cond"));

    object oA = DuelGetPCByUUID(sUuidA);
    object oB = DuelGetPCByUUID(sUuidB);

    DuelSetOutcome(nDuelId, DUEL_STATUS_COMPLETED, sWinnerUuid, sLoserUuid, sNote);

    if(GetIsObjectValid(oA) && GetIsObjectValid(oB))
        DuelRestoreNeutral(oA, oB);

    DuelHealAndCleanup(oA);
    DuelHealAndCleanup(oB);

    int bForfeit = (sNote == "Poddanie sie." || sNote == "Ucieczka z areny.");

    string sWinName = (sWinnerUuid == sUuidA) ? sNameA : sNameB;
    string sLosName = (sLoserUuid  == sUuidA) ? sNameA : sNameB;

    // Honor distribution
    if(sWinnerUuid != "")
    {
        int nWinDelta = DUEL_HONOR_WIN;
        if(bKill && nWinCond == DUEL_WIN_TO_DEATH) nWinDelta += DUEL_HONOR_KILL_BONUS;
        DuelAdjustHonor(sWinnerUuid, sWinName, nWinDelta, 1, 0, 0, 0, bKill ? 1 : 0);

        int nLoseDelta = bForfeit ? DUEL_HONOR_FORFEIT : DUEL_HONOR_LOSE;
        DuelAdjustHonor(sLoserUuid, sLosName, nLoseDelta, 0, 1, 0, bForfeit ? 1 : 0, 0);

        // Stake: winner takes both halves.
        if(nStake > 0)
        {
            object oWin = DuelGetPCByUUID(sWinnerUuid);
            if(GetIsObjectValid(oWin))
            {
                GiveGoldToCreature(oWin, nStake * 2);
                SendMessageToPC(oWin, "[Pojedynek] Stawka " + IntToString(nStake * 2)
                    + " zlota do twojej sakiewki.");
            }
        }
    }
    else
    {
        // No winner (mutual death) — stakes refunded.
        DuelRefundStake(sUuidA, nStake);
        DuelRefundStake(sUuidB, nStake);
    }

    string sMsg = sNote;
    if(sWinnerUuid != "")
        sMsg += " Zwyciezca: " + sWinName + ".";
    DuelBroadcast(sMsg, oA, oB);

    object oRefresh = GetFirstPC();
    while(GetIsObjectValid(oRefresh))
    {
        int nTk = NuiFindWindow(oRefresh, DUEL_WINDOW);
        if(nTk != 0) FeedDuelMain(oRefresh, nTk);
        oRefresh = GetNextPC();
    }
}
