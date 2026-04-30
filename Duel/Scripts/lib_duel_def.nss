// lib_duel_def.nss
// Honor Duels - constants + core flow logic. Owns:
//  - all status / outcome / honor / mechanics / LVAR / bind / button constants
//  - flow functions: SubmitChallenge, Decline, Accept, Begin, Tick, End,
//    HandlePlayerDeath
//  - arena visual marker spawn / despawn
//  - PC-by-UUID lookup, broadcast, faction restore, OOB tick helper
// HUD-only constants (DUEL_WIN_HUD, DUEL_EV_SCRIPT, DUEL_HUD_*, DUEL_BIND_HUD_*)
// and CreateDuelHud / DestroyDuelHud live in lib_duel_hud (one-way include).
// NUI builders for the main window / popups live in lib_duel.
// Info / rules window is its own subsystem (lib_duel_inf).
#include "lib_duel_hud"

// ============================================================
// Window IDs (HUD lives in lib_duel_hud)
// ============================================================
const string DUEL_WINDOW         = "DUEL_WINDOW";
const string DUEL_WIN_CHALLENGE  = "DUEL_WIN_CHALLENGE";
const string DUEL_WIN_INCOMING   = "DUEL_WIN_INCOMING";

// ============================================================
// View tabs (main window swap)
// ============================================================
const int DUEL_VIEW_HISTORY  = 0;
const int DUEL_VIEW_RANKING  = 1;

// ============================================================
// Status (matches SQL status column)
// ============================================================
const int DUEL_STATUS_PENDING     = 0;
const int DUEL_STATUS_ACCEPTED    = 1;
const int DUEL_STATUS_IN_PROGRESS = 2;
const int DUEL_STATUS_COMPLETED   = 3;
const int DUEL_STATUS_DECLINED    = 4;
const int DUEL_STATUS_EXPIRED     = 5;
const int DUEL_STATUS_CANCELED    = 6;

// ============================================================
// Outcome type (matches SQL outcome_type column)
// ============================================================
const int DUEL_OUTCOME_NONE    = -1;
const int DUEL_OUTCOME_KILL    = 0;  // win/loss by killing blow (rescued)
const int DUEL_OUTCOME_FLEE    = 1;  // win/loss by leaving the arena
const int DUEL_OUTCOME_DECLINE = 2;  // loss by refusing the challenge
const int DUEL_OUTCOME_CANCEL  = 3;  // no winner - challenger withdrew
const int DUEL_OUTCOME_EXPIRE  = 4;  // no winner - TTL passed
const int DUEL_OUTCOME_BOTH    = 5;  // no winner - both fell

// ============================================================
// Honor scoring
// ============================================================
const int DUEL_HONOR_WIN     =  10;
const int DUEL_HONOR_LOSE    =  -3;
const int DUEL_HONOR_DECLINE =   0;  // declining is a player's right - no penalty (declines still tracked)
const int DUEL_HONOR_FORFEIT = -25;  // losses_by_flee

// ============================================================
// Mechanics
// ============================================================
const float DUEL_ARENA_RADIUS        = 10.0;  // meters from marker; aura VFX is scaled to match (see DuelSpawnArenaMarker)
const float DUEL_OUT_OF_BOUNDS_TIME  = 6.0;   // seconds outside arena before forfeit
const int   DUEL_COUNTDOWN_SECONDS   = 5;     // delay between accept and FIGHT
const int   DUEL_PENDING_TTL         = 300;   // 5 min for the challenged to respond
const int   DUEL_HISTORY_LIMIT       = 20;    // rows shown in History tab
const int   DUEL_RANKING_LIMIT       = 10;    // rows shown in Ranking tab
const int   DUEL_ARENA_VFX           = 273;   // VFX_IMP_AURA_HOLY (yellow); base ~5m, scaled 2x = 10m
const string DUEL_ARENA_TAG_PREFIX   = "DUEL_ARENA_";  // marker placeable tag prefix + duel id
const int   DUEL_TICK_PERIOD         = 1;     // seconds between bounds/death checks
const int   DUEL_CHALLENGE_COOLDOWN  = 30;    // seconds between sent challenges (anti-spam)

// ============================================================
// LVARs (on PC)
// ============================================================
const string DUEL_LVAR_DRAFT_TARGET     = "DUEL_DRAFT_TARGET_UUID";
const string DUEL_LVAR_DRAFT_NAME       = "DUEL_DRAFT_TARGET_NAME";
const string DUEL_LVAR_ACTIVE_DUEL      = "DUEL_ACTIVE_ID";
const string DUEL_LVAR_OUT_OF_BOUNDS    = "DUEL_OOB_TICKS";
const string DUEL_LVAR_VIEW             = "DUEL_VIEW";
const string DUEL_LVAR_INCOMING_ID      = "DUEL_INCOMING_ID";
const string DUEL_LVAR_LAST_CHALLENGE   = "DUEL_LAST_CHALLENGE_AT";
const string DUEL_LVAR_TARGETING_ACTIVE = "DUEL_TARGETING_ACTIVE";

// ============================================================
// Bind names - main window
// ============================================================
const string DUEL_BIND_HONOR_LBL        = "duel_honor_lbl";
const string DUEL_BIND_RECORD_LBL       = "duel_record_lbl";
const string DUEL_BIND_TAB_HIS_ENC      = "duel_tab_his_enc";
const string DUEL_BIND_TAB_RNK_ENC      = "duel_tab_rnk_enc";
const string DUEL_BIND_ROW_PRIMARY      = "duel_row_primary";
const string DUEL_BIND_ROW_SECONDARY    = "duel_row_secondary";
const string DUEL_BIND_ROW_RIGHT        = "duel_row_right";
const string DUEL_BIND_ROW_COLOR        = "duel_row_color";
const string DUEL_BIND_ROW_COUNT        = "duel_row_count";

// Bind names - challenge confirm popup
const string DUEL_BIND_CH_TARGET_LBL    = "duel_ch_target_lbl";

// Bind names - incoming popup
const string DUEL_BIND_INC_TITLE        = "duel_inc_title";

// Bind names - HUD live in lib_duel_hud

// ============================================================
// Button IDs
// ============================================================
const string DUEL_BTN_CHALLENGE       = "duel_btn_challenge";
const string DUEL_BTN_CLOSE           = "duel_btn_close";
const string DUEL_BTN_TAB_HISTORY     = "duel_btn_tab_his";
const string DUEL_BTN_TAB_RANKING     = "duel_btn_tab_rnk";
const string DUEL_BTN_ROW             = "duel_btn_row";
const string DUEL_BTN_INC_ACCEPT      = "duel_btn_inc_accept";
const string DUEL_BTN_INC_DECLINE     = "duel_btn_inc_decline";
const string DUEL_BTN_CH_SEND         = "duel_btn_ch_send";
const string DUEL_BTN_CH_CANCEL       = "duel_btn_ch_cancel";

// ============================================================
// Layout
// ============================================================
const float DUEL_W              = 900.0;
const float DUEL_H              = 800.0;
const float DUEL_POPUP_W        = 330.0;  // shared by challenge confirm + incoming popup
const float DUEL_POPUP_H        = 110.0;
// DUEL_HUD_W / DUEL_HUD_H live in lib_duel_hud

// Info / rules text moved to lib_duel_inf (separate subsystem).

// ============================================================
// Forward declarations (defined in lib_duel - resolved when this
// chain is included via lib_duel.nss).
// CreateDuelHud / DestroyDuelHud come from lib_duel_hud (included above).
// ============================================================
void FeedDuelMain(object oPC, int nToken);
void DuelShowIncomingPopup(object oPC, int nDuelId);
void DuelShowChallengeConfig(object oPC, string sTargetUuid, string sTargetName);

// ============================================================
// Helpers
// ============================================================

object DuelGetPCByUUID(string sUuid)
{
    if(sUuid == "") return OBJECT_INVALID;
    object oPC = GetFirstPC();
    while(GetIsObjectValid(oPC))
    {
        if(GetObjectUUID(oPC) == sUuid) return oPC;
        oPC = GetNextPC();
    }
    return OBJECT_INVALID;
}

int DuelIsActiveStatus(int nStatus)
{
    return (nStatus == DUEL_STATUS_PENDING
         || nStatus == DUEL_STATUS_ACCEPTED
         || nStatus == DUEL_STATUS_IN_PROGRESS);
}

string DuelOutcomeToString(int nOutcome)
{
    switch(nOutcome)
    {
        case DUEL_OUTCOME_KILL:    return "killing blow";
        case DUEL_OUTCOME_FLEE:    return "fleeing";
        case DUEL_OUTCOME_DECLINE: return "decline";
        case DUEL_OUTCOME_CANCEL:  return "canceled";
        case DUEL_OUTCOME_EXPIRE:  return "expired";
        case DUEL_OUTCOME_BOTH:    return "both fell";
    }
    return "";
}

void DuelBroadcast(string sMsg, object oA, object oB)
{
    // bBroadcastToFaction=FALSE, bChatWindow=FALSE - float only, no chat duplicate.
    if(GetIsObjectValid(oA))
    {
        FloatingTextStringOnCreature(sMsg, oA, FALSE, FALSE);
        SendMessageToPC(oA, "[Duel] " + sMsg);
    }
    if(GetIsObjectValid(oB))
    {
        FloatingTextStringOnCreature(sMsg, oB, FALSE, FALSE);
        SendMessageToPC(oB, "[Duel] " + sMsg);
    }
}

void RefreshAllDuelMainWindows()
{
    object oPC = GetFirstPC();
    while(GetIsObjectValid(oPC))
    {
        int nTk = NuiFindWindow(oPC, DUEL_WINDOW);
        if(nTk != 0) FeedDuelMain(oPC, nTk);
        oPC = GetNextPC();
    }
}

void DuelNotifyChallenged(string sChallengedUuid, int nDuelId, string sChallengerName)
{
    object oPC = DuelGetPCByUUID(sChallengedUuid);
    if(!GetIsObjectValid(oPC)) return;

    string sMsg = sChallengerName + " challenges you. Honor awaits.";
    FloatingTextStringOnCreature(sMsg, oPC, FALSE);
    SendMessageToPC(oPC, "[Duel] " + sMsg);

    DelayCommand(0.5, DuelShowIncomingPopup(oPC, nDuelId));
}

// ============================================================
// Targeting entry points
// ============================================================

void DuelStartChallengeTargeting(object oPC)
{
    if(DuelHasAnyActive(GetObjectUUID(oPC)))
    {
        SendMessageToPC(oPC, "[Duel] You already have an active duel or pending challenge.");
        return;
    }

    int nNow  = GetTimeSecond() + GetTimeMinute() * 60 + GetTimeHour() * 3600;
    int nLast = GetLocalInt(oPC, DUEL_LVAR_LAST_CHALLENGE);
    if(nLast > 0 && nNow - nLast < DUEL_CHALLENGE_COOLDOWN)
    {
        SendMessageToPC(oPC, "[Duel] Cooldown active. Wait a moment before another challenge.");
        return;
    }

    SetLocalInt(oPC, DUEL_LVAR_TARGETING_ACTIVE, 1);
    SendMessageToPC(oPC, "[Duel] Choose your foe within sight. Liars spit on the code.");
    EnterTargetingMode(oPC, OBJECT_TYPE_CREATURE);
}

void DuelOnPlayerTarget(object oPC)
{
    if(GetLocalInt(oPC, DUEL_LVAR_TARGETING_ACTIVE) != 1) return;
    DeleteLocalInt(oPC, DUEL_LVAR_TARGETING_ACTIVE);

    object oTarget = GetTargetingModeSelectedObject();
    if(!GetIsObjectValid(oTarget))
    {
        SendMessageToPC(oPC, "[Duel] Selection canceled.");
        return;
    }
    if(!GetIsPC(oTarget))
    {
        SendMessageToPC(oPC, "[Duel] Only living players may answer the code of honor.");
        return;
    }
    if(oTarget == oPC)
    {
        SendMessageToPC(oPC, "[Duel] You cannot challenge yourself.");
        return;
    }
    DuelShowChallengeConfig(oPC, GetObjectUUID(oTarget), GetName(oTarget));
}

// ============================================================
// Challenge submission
// ============================================================

int DuelSubmitChallenge(object oPC, string sTargetUuid, string sTargetName)
{
    if(sTargetUuid == "" || sTargetUuid == GetObjectUUID(oPC))
    {
        SendMessageToPC(oPC, "[Duel] Invalid target.");
        return 0;
    }

    // Single-duel rule: a player may only be involved in one duel at a time
    // (as challenger OR challenged). Re-check at submit in case state
    // changed during targeting.
    if(DuelHasAnyActive(GetObjectUUID(oPC)))
    {
        SendMessageToPC(oPC, "[Duel] You already have an active duel or pending challenge.");
        return 0;
    }

    if(DuelHasAnyActive(sTargetUuid))
    {
        SendMessageToPC(oPC, "[Duel] " + sTargetName + " is busy with another duel or pending challenge.");
        return 0;
    }

    object oTarget = DuelGetPCByUUID(sTargetUuid);
    if(!GetIsObjectValid(oTarget))
    {
        SendMessageToPC(oPC, "[Duel] Opponent must be online.");
        return 0;
    }

    // Same-party split - friendly fire is off in a party so a duel between
    // members would never resolve. Eject the challenger so the duel works,
    // notify both. They can re-form the party after the duel.
    if(GetFactionLeader(oPC) == GetFactionLeader(oTarget))
    {
        RemoveFromParty(oPC);
        SendMessageToPC(oPC,
            "[Duel] You left the party to challenge " + sTargetName + ".");
        SendMessageToPC(oTarget,
            "[Duel] " + GetName(oPC) + " left the party to challenge you.");
    }

    int nId = DuelCreate(oPC, oTarget);
    if(nId <= 0)
    {
        SendMessageToPC(oPC, "[Duel] Could not create challenge.");
        return 0;
    }

    int nNow = GetTimeSecond() + GetTimeMinute() * 60 + GetTimeHour() * 3600;
    SetLocalInt(oPC, DUEL_LVAR_LAST_CHALLENGE, nNow);

    SendMessageToPC(oPC, "[Duel] Challenge sent to " + sTargetName + ".");
    DuelNotifyChallenged(sTargetUuid, nId, GetName(oPC));
    return nId;
}

// ============================================================
// Decline (challenged player refuses the challenge)
// ============================================================

void DuelDecline(object oPC, int nDuelId)
{
    json jD = DuelGetById(nDuelId);
    if(JsonGetType(jD) == JSON_TYPE_NULL) return;
    if(JsonGetInt(JsonObjectGet(jD, "status")) != DUEL_STATUS_PENDING) return;

    string sChallengedUuid = JsonGetString(JsonObjectGet(jD, "challenged_uuid"));
    if(GetObjectUUID(oPC) != sChallengedUuid) return;

    string sChallengerUuid = JsonGetString(JsonObjectGet(jD, "challenger_uuid"));

    DuelSetOutcome(nDuelId, DUEL_STATUS_DECLINED, "", GetObjectUUID(oPC),
                   DUEL_OUTCOME_DECLINE, "Refused without a fight.");

    DuelAdjustHonor(GetObjectUUID(oPC), GetName(oPC),
                    DUEL_HONOR_DECLINE, 0, 0, 0, 0, 1);

    object oCh = DuelGetPCByUUID(sChallengerUuid);
    DuelBroadcast("Challenge declined. Honor stooped lower than the blade.", oCh, oPC);

    RefreshAllDuelMainWindows();
}

// ============================================================
// Accept -> countdown -> begin
// ============================================================

void DuelMakeHostile(object oA, object oB)
{
    SetPCDislike(oA, oB);
    SetPCDislike(oB, oA);
}

void DuelRestoreNeutral(object oA, object oB)
{
    if(GetIsObjectValid(oA) && GetIsObjectValid(oB))
    {
        SetPCLike(oA, oB);
        SetPCLike(oB, oA);
    }
}

// ============================================================
// Arena visual marker (invisible placeable + aura VFX)
// ============================================================

void DuelSpawnArenaMarker(int nDuelId, location lArena)
{
    string sTag = DUEL_ARENA_TAG_PREFIX + IntToString(nDuelId);
    object oMarker = CreateObject(OBJECT_TYPE_PLACEABLE,
        "plc_invisobj", lArena, FALSE, sTag);
    if(!GetIsObjectValid(oMarker)) return;

    // EffectVisualEffect(id, bMiss, fScale) - scale 2.6x so the aura covers
    // the full 10m radius (default VFX_IMP_AURA_* visual is ~5m).
    ApplyEffectToObject(DURATION_TYPE_PERMANENT,
        EffectVisualEffect(DUEL_ARENA_VFX, FALSE, 2.6), oMarker);
    SetLocalObject(GetModule(), sTag, oMarker);
}

void DuelDespawnArenaMarker(int nDuelId)
{
    string sTag = DUEL_ARENA_TAG_PREFIX + IntToString(nDuelId);
    object oMarker = GetLocalObject(GetModule(), sTag);
    if(GetIsObjectValid(oMarker)) DestroyObject(oMarker);
    DeleteLocalObject(GetModule(), sTag);
}

// Forward decls for funcs defined below
void DuelTick(int nDuelId);
void DuelEnd(int nDuelId, string sWinnerUuid, string sLoserUuid,
             int nOutcomeType, string sNote);

void DuelBegin(int nDuelId)
{
    json jD = DuelGetById(nDuelId);
    if(JsonGetType(jD) == JSON_TYPE_NULL) return;
    if(JsonGetInt(JsonObjectGet(jD, "status")) != DUEL_STATUS_ACCEPTED) return;

    object oA = DuelGetPCByUUID(JsonGetString(JsonObjectGet(jD, "challenger_uuid")));
    object oB = DuelGetPCByUUID(JsonGetString(JsonObjectGet(jD, "challenged_uuid")));
    if(!GetIsObjectValid(oA) || !GetIsObjectValid(oB))
    {
        DuelSetOutcome(nDuelId, DUEL_STATUS_EXPIRED, "", "",
                       DUEL_OUTCOME_EXPIRE, "A duelist left the game.");
        return;
    }

    DuelSetStatus(nDuelId, DUEL_STATUS_IN_PROGRESS);
    DuelMakeHostile(oA, oB);
    DuelBroadcast("FIGHT!", oA, oB);

    DelayCommand(IntToFloat(DUEL_TICK_PERIOD), DuelTick(nDuelId));
}

void DuelAccept(object oPC, int nDuelId)
{
    json jD = DuelGetById(nDuelId);
    if(JsonGetType(jD) == JSON_TYPE_NULL) return;
    if(JsonGetInt(JsonObjectGet(jD, "status")) != DUEL_STATUS_PENDING) return;

    string sChallengedUuid = JsonGetString(JsonObjectGet(jD, "challenged_uuid"));
    if(GetObjectUUID(oPC) != sChallengedUuid) return;

    string sChallengerUuid = JsonGetString(JsonObjectGet(jD, "challenger_uuid"));
    object oChallenger = DuelGetPCByUUID(sChallengerUuid);
    if(!GetIsObjectValid(oChallenger))
    {
        SendMessageToPC(oPC, "[Duel] The challenger is no longer in game.");
        DuelSetOutcome(nDuelId, DUEL_STATUS_EXPIRED, "", "",
                       DUEL_OUTCOME_EXPIRE, "Challenger absent.");
        return;
    }

    // Distance check: must be reasonably close to the arena point.
    float fX = JsonGetFloat(JsonObjectGet(jD, "arena_x"));
    float fY = JsonGetFloat(JsonObjectGet(jD, "arena_y"));
    float fZ = JsonGetFloat(JsonObjectGet(jD, "arena_z"));
    vector vArena = Vector(fX, fY, fZ);
    location lArena = Location(GetArea(oChallenger), vArena, 0.0);
    float fDist = GetDistanceBetweenLocations(GetLocation(oPC), lArena);
    if(fDist > DUEL_ARENA_RADIUS * 1.5)
    {
        SendMessageToPC(oPC, "[Duel] You must stand near the challenger.");
        return;
    }

    DuelSetStatus(nDuelId, DUEL_STATUS_ACCEPTED);

    SetLocalInt(oPC,         DUEL_LVAR_ACTIVE_DUEL, nDuelId);
    SetLocalInt(oChallenger, DUEL_LVAR_ACTIVE_DUEL, nDuelId);

    // Visual arena marker (10m aura) - spawned during countdown so players
    // see the boundary before the fight starts.
    DuelSpawnArenaMarker(nDuelId, lArena);

    // HUD windows up immediately so both players see HP bars during countdown.
    CreateDuelHud(oChallenger, nDuelId);
    CreateDuelHud(oPC,         nDuelId);

    DuelBroadcast("Challenge accepted. Blood shall settle the dispute.",
                  oChallenger, oPC);

    int i;
    for(i = DUEL_COUNTDOWN_SECONDS; i > 0; i--)
    {
        float fT = IntToFloat(DUEL_COUNTDOWN_SECONDS - i);
        string sCd = IntToString(i) + "...";
        DelayCommand(fT, FloatingTextStringOnCreature(sCd, oChallenger, FALSE));
        DelayCommand(fT, FloatingTextStringOnCreature(sCd, oPC,         FALSE));
    }
    DelayCommand(IntToFloat(DUEL_COUNTDOWN_SECONDS), DuelBegin(nDuelId));
}

// ============================================================
// HUD helpers + Tick
// ============================================================

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
    NuiSetBind(oPC, nTk, DUEL_BIND_HUD_SELF_HP,     JsonFloat(IntToFloat(nFracSelf) / 100.0));
    NuiSetBind(oPC, nTk, DUEL_BIND_HUD_OPP_HP,      JsonFloat(IntToFloat(nFracOpp) / 100.0));
    NuiSetBind(oPC, nTk, DUEL_BIND_HUD_SELF_HP_TIP, JsonString(IntToString(nFracSelf) + "%"));
    NuiSetBind(oPC, nTk, DUEL_BIND_HUD_OPP_HP_TIP,  JsonString(IntToString(nFracOpp) + "%"));
    NuiSetBind(oPC, nTk, DUEL_BIND_HUD_TITLE,       JsonString("Duel: " + GetName(oOpp)));
}

// Per-player bounds tick. Returns 1 if duel ended (caller should return), 0 otherwise.
int DuelTickPlayerBounds(int nDuelId, object oPC, object oMarker, int nMax,
                         string sSelfUuid, string sOppUuid)
{
    int bArea = GetIsObjectValid(oMarker) && (GetArea(oPC) == GetArea(oMarker));
    float fDist = bArea ? GetDistanceBetween(oMarker, oPC) : 999.0;

    int nOob = GetLocalInt(oPC, DUEL_LVAR_OUT_OF_BOUNDS);
    if(!bArea || fDist >= DUEL_ARENA_RADIUS) nOob++; else nOob = 0;
    SetLocalInt(oPC, DUEL_LVAR_OUT_OF_BOUNDS, nOob);

    int nTk = NuiFindWindow(oPC, DUEL_WIN_HUD);
    if(nTk != 0)
        NuiSetBind(oPC, nTk, DUEL_BIND_HUD_BOUNDS,
            JsonString(nOob > 0 ? "Return to the arena! "
                + IntToString(nOob) + "/" + IntToString(nMax) : ""));

    if(IntToFloat(nOob) >= DUEL_OUT_OF_BOUNDS_TIME)
    {
        DuelEnd(nDuelId, sOppUuid, sSelfUuid, DUEL_OUTCOME_FLEE, "Fled the arena.");
        return 1;
    }
    return 0;
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

    // Disconnect handling - logout while in duel = forfeit (also handled by sys_on_leave).
    if(!GetIsObjectValid(oA))
    {
        DuelEnd(nDuelId, sUuidB, sUuidA, DUEL_OUTCOME_FLEE, "Challenger left the arena.");
        return;
    }
    if(!GetIsObjectValid(oB))
    {
        DuelEnd(nDuelId, sUuidA, sUuidB, DUEL_OUTCOME_FLEE, "Challenged left the arena.");
        return;
    }

    // Death handling fallback (OnPlayerDeath should catch first; this is belt-and-suspenders).
    int nDeadA = GetIsDead(oA);
    int nDeadB = GetIsDead(oB);
    if(nDeadA && nDeadB)
    {
        DuelEnd(nDuelId, "", "", DUEL_OUTCOME_BOTH, "Both fell.");
        return;
    }
    if(nDeadA)
    {
        DuelEnd(nDuelId, sUuidB, sUuidA, DUEL_OUTCOME_KILL, "Killing blow.");
        return;
    }
    if(nDeadB)
    {
        DuelEnd(nDuelId, sUuidA, sUuidB, DUEL_OUTCOME_KILL, "Killing blow.");
        return;
    }

    DuelUpdateHud(oA, oB, DuelHpFraction(oA), DuelHpFraction(oB));
    DuelUpdateHud(oB, oA, DuelHpFraction(oB), DuelHpFraction(oA));

    // Bounds check - distance from arena marker placeable matches visible aura.
    object oMarker = GetLocalObject(GetModule(),
        DUEL_ARENA_TAG_PREFIX + IntToString(nDuelId));
    int nMax = FloatToInt(DUEL_OUT_OF_BOUNDS_TIME);

    if(DuelTickPlayerBounds(nDuelId, oA, oMarker, nMax, sUuidA, sUuidB)) return;
    if(DuelTickPlayerBounds(nDuelId, oB, oMarker, nMax, sUuidB, sUuidA)) return;

    DelayCommand(IntToFloat(DUEL_TICK_PERIOD), DuelTick(nDuelId));
}

// ============================================================
// End - outcome resolution + honor
// ============================================================

void DuelHealAndCleanup(object oPC)
{
    if(!GetIsObjectValid(oPC)) return;
    DeleteLocalInt(oPC, DUEL_LVAR_ACTIVE_DUEL);
    DeleteLocalInt(oPC, DUEL_LVAR_OUT_OF_BOUNDS);
    DestroyDuelHud(oPC);
}

void DuelEnd(int nDuelId, string sWinnerUuid, string sLoserUuid,
             int nOutcomeType, string sNote)
{
    json jD = DuelGetById(nDuelId);
    if(JsonGetType(jD) == JSON_TYPE_NULL) return;
    int nStatusNow = JsonGetInt(JsonObjectGet(jD, "status"));
    if(nStatusNow == DUEL_STATUS_COMPLETED) return;

    string sUuidA = JsonGetString(JsonObjectGet(jD, "challenger_uuid"));
    string sUuidB = JsonGetString(JsonObjectGet(jD, "challenged_uuid"));
    string sNameA = JsonGetString(JsonObjectGet(jD, "challenger_name"));
    string sNameB = JsonGetString(JsonObjectGet(jD, "challenged_name"));

    object oA = DuelGetPCByUUID(sUuidA);
    object oB = DuelGetPCByUUID(sUuidB);

    DuelSetOutcome(nDuelId, DUEL_STATUS_COMPLETED, sWinnerUuid, sLoserUuid,
                   nOutcomeType, sNote);

    if(GetIsObjectValid(oA) && GetIsObjectValid(oB))
        DuelRestoreNeutral(oA, oB);

    DuelDespawnArenaMarker(nDuelId);

    DuelHealAndCleanup(oA);
    DuelHealAndCleanup(oB);

    if(sWinnerUuid != "" && sLoserUuid != "")
    {
        string sWinName = (sWinnerUuid == sUuidA) ? sNameA : sNameB;
        string sLosName = (sLoserUuid  == sUuidA) ? sNameA : sNameB;

        int bKill = (nOutcomeType == DUEL_OUTCOME_KILL) ? 1 : 0;
        int bFlee = (nOutcomeType == DUEL_OUTCOME_FLEE) ? 1 : 0;
        int nLossDelta = bFlee ? DUEL_HONOR_FORFEIT : DUEL_HONOR_LOSE;

        DuelAdjustHonor(sWinnerUuid, sWinName, DUEL_HONOR_WIN,
                        bKill, bFlee, 0,     0,     0);
        DuelAdjustHonor(sLoserUuid,  sLosName, nLossDelta,
                        0,     0,     bKill, bFlee, 0);

        DuelBroadcast(sNote + " Victor: " + sWinName + ".", oA, oB);
    }
    else
    {
        // Both fell or no resolution: no honor change.
        DuelBroadcast(sNote, oA, oB);
    }

    RefreshAllDuelMainWindows();
}

// ============================================================
// Player death hook (called from sys_on_pdeath - OnPlayerDeath).
// If the killer is the duel opponent, resurrect on the spot at 1 HP and
// end the duel as a kill. Otherwise just end as a kill (no rescue).
// ============================================================

void DuelHandlePlayerDeath(object oPC)
{
    int nDuelId = GetLocalInt(oPC, DUEL_LVAR_ACTIVE_DUEL);
    if(nDuelId <= 0) return;

    json jD = DuelGetById(nDuelId);
    if(JsonGetType(jD) == JSON_TYPE_NULL) return;

    string sUuidA = JsonGetString(JsonObjectGet(jD, "challenger_uuid"));
    string sUuidB = JsonGetString(JsonObjectGet(jD, "challenged_uuid"));
    string sSelfUuid = GetObjectUUID(oPC);
    string sOppUuid  = (sSelfUuid == sUuidA) ? sUuidB : sUuidA;

    object oKiller = GetLastHostileActor(oPC);
    if(!GetIsObjectValid(oKiller))
        oKiller = GetLastDamager(oPC);

    int bByOpponent = (GetIsObjectValid(oKiller) && GetIsPC(oKiller)
                       && GetObjectUUID(oKiller) == sOppUuid);

    if(bByOpponent)
    {
        // Rescue: resurrect at 1 HP only. No heal - otherwise duels would be
        // abused as a free heal mechanic.
        // Delay required - engine is mid-death-processing, instant
        // resurrection during OnPlayerDeath is sometimes dropped.
        // Plain DelayCommand (no AssignCommand) - dead PC can't execute.
        DelayCommand(1.0,
            ApplyEffectToObject(DURATION_TYPE_INSTANT, EffectResurrection(), oPC));
    }
    // If killed by something else, no rescue but still end duel as loss.

    DuelEnd(nDuelId, sOppUuid, sSelfUuid, DUEL_OUTCOME_KILL, "Killing blow.");
}
