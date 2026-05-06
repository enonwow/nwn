// lib_plg.nss - Plague v2 core logic
//
// Faza A scope:
//   - Effect management (apply/remove per disease)
//   - Icon effect (visible aura przy mild, hidden w incubation)
//   - Contract/cure z hidden identity (incubation = NIC, mild = "feel sick")
//   - Basic phase progression (BEZ saves jeszcze - faza B)
//   - Per-tick DoT dla critical phase
//   - OnClientEnter restore (BEZ offline progression jeszcze - faza B)
//
// NIE w fazie A:
//   - Saving throws (PlgRollProgressionSave) -> faza B
//   - Offline progression -> faza B
//   - Safe areas check -> faza B
//   - Diagnostic item -> faza C
//   - Apteczka logic -> faza D
//   - DM panel -> faza E
//   - Contagion -> faza F
//   - UI window -> faza C/D
//   - Telemetry -> faza G

#include "lib_plg_def"
#include "sql_plg_events"

// Forward declarations
void PlgRemoveEffectsForDisease(object oPC, int nDiseaseId);
void PlgApplyEffectsForDisease(object oPC, int nDiseaseId, int nPhase);
void PlgContractAndNotify(object oPC, int nDiseaseId);
void PlgCureAndNotify(object oPC, int nDiseaseId);
int  PlgRollProgressionSave(object oPC, int nDC);
void PlgCheckProgression(object oPC, int nDiseaseId);
void PlgProcessOfflineProgression(object oPC, int nDiseaseId);
void PlgApplyPerTick(object oPC, int nDiseaseId);
void PlgApplyContagion(object oPC, int nDiseaseId);
void PlgOnClientEnter(object oPC);
void PlgOnClientLeave(object oPC);
// Diagnostic & item handling (faza C/D)
int  PlgIsDiagnosed(object oPC, int nDiseaseId);
int  PlgUseDiagnosticLens(object oPC, object oItem);
int  PlgUseRemedy(object oPC, object oItem);
int  PlgUseFirstAid(object oPC, object oItem);
int  PlgHandleItemActivation(object oPC, object oItem);

// ============================================================
// Effect management
// ============================================================

// Usuwa wszystkie effects oznaczone PLG_ICON_<diseaseId>.
// Tag jest na linked effect ze stat decrease (jeden effect, jeden tag).
void PlgRemoveEffectsForDisease(object oPC, int nDiseaseId)
{
    string sIconTag = PLG_ICON_TAG + IntToString(nDiseaseId);

    effect e = GetFirstEffect(oPC);
    effect eNext;
    while(GetIsEffectValid(e))
    {
        eNext = GetNextEffect(oPC);
        if(GetEffectTag(e) == sIconTag)
            RemoveEffect(oPC, e);
        e = eNext;
    }
}

// Aplikuje effects per disease per phase.
// - Incubation: tylko EffectIcon(DISEASE) - brown HP bar + icon w top right (player wie ze chory)
// - Mild/Severe/Critical: stat decrease + (HideEffectIcon + EffectIcon DISEASE) zeby zachowac ten sam visual
// Tag PLG_ICON_<diseaseId> na linked effect zeby diagnostic lens mogla odczytac.
void PlgApplyEffectsForDisease(object oPC, int nDiseaseId, int nPhase)
{
    PlgRemoveEffectsForDisease(oPC, nDiseaseId);
    if(nPhase == PLG_PHASE_NONE) return;

    string sIconTag = PLG_ICON_TAG + IntToString(nDiseaseId);
    effect eLink;

    if(nPhase == PLG_PHASE_INCUBATION)
    {
        // Incubation: tylko icon - bez stat penalties (gracz wie ze chory, nie wie jaka choroba)
        eLink = EffectIcon(EFFECT_ICON_DISEASE);
    }
    else
    {
        // Mild/Severe/Critical: stat decrease per disease
        if(nDiseaseId == PLG_DIS_BLACK_PLAGUE)
        {
            int nCon = (nPhase == PLG_PHASE_MILD) ? 2 : (nPhase == PLG_PHASE_SEVERE) ? 4 : 6;
            int nStr = (nPhase == PLG_PHASE_MILD) ? 0 : (nPhase == PLG_PHASE_SEVERE) ? 2 : 4;
            eLink = EffectAbilityDecrease(ABILITY_CONSTITUTION, nCon);
            if(nStr > 0)
                eLink = EffectLinkEffects(eLink, EffectAbilityDecrease(ABILITY_STRENGTH, nStr));
        }
        else if(nDiseaseId == PLG_DIS_BLOOD_ROT)
        {
            int nPen = (nPhase == PLG_PHASE_MILD) ? 1 : (nPhase == PLG_PHASE_SEVERE) ? 2 : 3;
            eLink = EffectACDecrease(nPen, AC_DODGE_BONUS);
            eLink = EffectLinkEffects(eLink, EffectSavingThrowDecrease(SAVING_THROW_FORT, nPen));
        }
        else if(nDiseaseId == PLG_DIS_SWAMP_FEVER)
        {
            int nDex = (nPhase == PLG_PHASE_MILD) ? 2 : (nPhase == PLG_PHASE_SEVERE) ? 4 : 6;
            int nWis = (nPhase == PLG_PHASE_MILD) ? 0 : (nPhase == PLG_PHASE_SEVERE) ? 2 : 4;
            eLink = EffectAbilityDecrease(ABILITY_DEXTERITY, nDex);
            if(nWis > 0)
                eLink = EffectLinkEffects(eLink, EffectAbilityDecrease(ABILITY_WISDOM, nWis));
        }
        else if(nDiseaseId == PLG_DIS_NECROTIC)
        {
            int nStr = (nPhase == PLG_PHASE_MILD) ? 1 : (nPhase == PLG_PHASE_SEVERE) ? 3 : 5;
            int nCon = (nPhase == PLG_PHASE_MILD) ? 0 : (nPhase == PLG_PHASE_SEVERE) ? 2 : 4;
            eLink = EffectAbilityDecrease(ABILITY_STRENGTH, nStr);
            if(nCon > 0)
                eLink = EffectLinkEffects(eLink, EffectAbilityDecrease(ABILITY_CONSTITUTION, nCon));
        }
        else return;

        // Hide stat-decrease default icons, replace with disease icon (brown HP bar)
        eLink = HideEffectIcon(eLink);
        eLink = EffectLinkEffects(eLink, EffectIcon(EFFECT_ICON_DISEASE));
    }

    eLink = TagEffect(eLink, sIconTag);
    ApplyEffectToObject(DURATION_TYPE_PERMANENT, eLink, oPC);
}

// ============================================================
// Disease contraction and cure
// ============================================================

void PlgContractAndNotify(object oPC, int nDiseaseId)
{
    if(!GetIsPC(oPC) || GetIsDM(oPC)) return;
    if(PlgIsImmune(oPC, nDiseaseId)) return;
    if(PlgHasDisease(oPC, nDiseaseId)) return; // already has this disease

    int nInterval = PlgPhaseInterval(nDiseaseId, PLG_PHASE_INCUBATION);
    string sEpisodeId = PlgGenerateEpisodeId();

    PlgInsertDisease(oPC, nDiseaseId, sEpisodeId, nInterval);
    SetLocalInt(oPC, PLG_LVAR_HAS + IntToString(nDiseaseId), TRUE);

    PlgLogContract(oPC, nDiseaseId, sEpisodeId);

    // Aplikuj icon od razu w incubation (brown HP bar + disease icon).
    // Player widzi ze chory ale nie wie ktora choroba (hidden identity przez
    // generic DISEASE icon - diagnostic lens czyta tag PLG_ICON_<id>).
    PlgApplyEffectsForDisease(oPC, nDiseaseId, PLG_PHASE_INCUBATION);

    // Generic notification - gracz widzi ze cos sie dzieje, ale bez nazwy
    string sMsg = "[Plague] You feel unwell - something is sapping your strength.";
    SendMessageToPC(oPC, sMsg);
    FloatingTextStringOnCreature(sMsg, oPC, FALSE, FALSE);
}

void PlgCureAndNotify(object oPC, int nDiseaseId)
{
    // Log przed usunieciem stanu (zeby episode_id byl dostepny)
    json jStatePre = PlgGetState(oPC, nDiseaseId);
    string sEpisodeId = "";
    if(JsonGetType(jStatePre) != JSON_TYPE_NULL)
        sEpisodeId = JsonGetString(JsonObjectGet(jStatePre, "episode_id"));

    PlgRemoveEffectsForDisease(oPC, nDiseaseId);
    PlgDeleteDisease(oPC, nDiseaseId);
    DeleteLocalInt(oPC, PLG_LVAR_HAS + IntToString(nDiseaseId));
    DeleteLocalInt(oPC, PLG_LVAR_TICK + IntToString(nDiseaseId));
    DeleteLocalInt(oPC, PLG_LVAR_DIAGNOSED + IntToString(nDiseaseId));

    PlgLogCureSuccess(oPC, nDiseaseId, sEpisodeId, "generic");

    string sName = PlgDiseaseName(nDiseaseId);
    string sMsg = "[Plague] " + sName + " leaves your body. You are free of this disease.";
    SendMessageToPC(oPC, sMsg);
    FloatingTextStringOnCreature(sMsg, oPC, FALSE, FALSE);

    ApplyEffectToObject(DURATION_TYPE_INSTANT,
        EffectVisualEffect(VFX_IMP_HEALING_M, FALSE), oPC);
}

// ============================================================
// Save throw mechanic
// ============================================================

// Module-level cache ostatniego rzutu (dla telemetrii).
const string PLG_LVAR_LAST_ROLL = "PLG_LAST_ROLL";

// Roll d20 + Fort vs DC. Returns one of PLG_SAVE_* constants.
// Side effect: zapisuje raw d20 do GetModule() LVAR PLG_LAST_ROLL (dla loga).
int PlgRollProgressionSave(object oPC, int nDC)
{
    int nRoll = Random(20) + 1;
    SetLocalInt(GetModule(), PLG_LVAR_LAST_ROLL, nRoll);

    int nFort = GetFortitudeSavingThrow(oPC);
    int nTotal = nRoll + nFort;

    if(nRoll == 20) return PLG_SAVE_CRIT_SUCCESS;
    if(nRoll == 1)  return PLG_SAVE_CRIT_FAIL;
    if(nTotal >= nDC) return PLG_SAVE_SUCCESS;
    return PLG_SAVE_FAIL;
}

// ============================================================
// Phase progression (heartbeat-driven)
// FAZA B: full saving throws.
//   Nat 20 (incubation/mild): CURE TOTAL (choroba znika)
//   Nat 20 (severe/critical): standard success (phase stays)
//   Standard success: phase stays, reset clock
//   Standard fail / Nat 1: phase advance
// ============================================================

void PlgCheckProgression(object oPC, int nDiseaseId)
{
    if(!PlgHasDisease(oPC, nDiseaseId)) return;

    json jState = PlgGetState(oPC, nDiseaseId);
    if(JsonGetType(jState) == JSON_TYPE_NULL) return;

    int nPhase = JsonGetInt(JsonObjectGet(jState, "phase"));
    if(nPhase >= PLG_PHASE_CRITICAL) return; // terminal

    int nPhaseEnd = JsonGetInt(JsonObjectGet(jState, "phase_end"));
    int nNow = PlgUnixNow();

    // Safe area - freeze the disease clock by shifting phase_start/end
    // forward by one heartbeat tick (~6s). This pauses progression while
    // keeping time-to-boundary stable for the UI countdown.
    object oArea = GetArea(oPC);
    if(GetLocalInt(oArea, PLG_LVAR_AREA_FREEZE))
    {
        int nPhaseStart = JsonGetInt(JsonObjectGet(jState, "phase_start"));
        PlgSetPhase(oPC, nDiseaseId, nPhase, nPhaseStart + 6, nPhaseEnd + 6);
        return;
    }

    if(nNow < nPhaseEnd) return; // not time yet

    // Roll save
    int nDC = PlgGetProgressionDC(nDiseaseId, nPhase);
    int nResult = PlgRollProgressionSave(oPC, nDC);
    int nRollVal = GetLocalInt(GetModule(), PLG_LVAR_LAST_ROLL);
    int nFort = GetFortitudeSavingThrow(oPC);
    int nTotal = nRollVal + nFort;
    string sEpisodeId = JsonGetString(JsonObjectGet(jState, "episode_id"));
    string sResultStr = PlgSaveResultToString(nResult);

    PlgLogBodyFight(oPC, nDiseaseId, sEpisodeId, nPhase, nRollVal, nDC, sResultStr);

    // Disease label for messages (hidden identity unless diagnosed)
    int bDiagnosed = JsonGetInt(JsonObjectGet(jState, "diagnosed"));
    string sName = bDiagnosed ? PlgDiseaseName(nDiseaseId) : "Disease";

    // Roll info string - always shown (player gets explicit feedback)
    string sRollInfo = "(d20: " + IntToString(nRollVal)
        + " + Fort " + IntToString(nFort)
        + " = " + IntToString(nTotal)
        + " vs DC " + IntToString(nDC) + ")";

    // Krytyczny sukces na incubation/mild = CURE TOTAL
    if(nResult == PLG_SAVE_CRIT_SUCCESS && nPhase <= PLG_PHASE_MILD)
    {
        PlgCureAndNotify(oPC, nDiseaseId);
        SendMessageToPC(oPC, "[Plague] NATURAL 20! Your body overcomes the disease "
            + sRollInfo);
        FloatingTextStringOnCreature("Body fight: NATURAL 20 - cured!",
            oPC, FALSE, FALSE);
        return;
    }

    // Success (standard lub crit przy severe+) - phase stays, reset clock
    if(nResult == PLG_SAVE_SUCCESS || nResult == PLG_SAVE_CRIT_SUCCESS)
    {
        int nInterval = PlgPhaseInterval(nDiseaseId, nPhase);
        PlgSetPhase(oPC, nDiseaseId, nPhase, nNow, nNow + nInterval);

        SendMessageToPC(oPC, "[Plague] " + sName + " - body resists "
            + sRollInfo + " - holding at " + PlgPhaseName(nPhase) + ".");
        FloatingTextStringOnCreature("Body fight: success",
            oPC, FALSE, FALSE);
        return;
    }

    // Fail (standard lub crit) - phase advance
    int nNewPhase = nPhase + 1;
    int nNextInterval = (nNewPhase < PLG_PHASE_CRITICAL)
        ? PlgPhaseInterval(nDiseaseId, nNewPhase) : 0;
    int nNewEnd = (nNextInterval > 0) ? nPhaseEnd + nNextInterval : 0;

    PlgSetPhase(oPC, nDiseaseId, nNewPhase, nPhaseEnd, nNewEnd);
    PlgApplyEffectsForDisease(oPC, nDiseaseId, nNewPhase);

    PlgLogPhaseChange(oPC, PLG_EVT_PHASE_ADVANCE, nDiseaseId, sEpisodeId,
        nPhase, nNewPhase, nRollVal, nDC, sResultStr);

    // Notify - z hidden identity + roll info
    string sFailPrefix = (nResult == PLG_SAVE_CRIT_FAIL) ? "NATURAL 1! " : "";
    string sMsg;
    if(nNewPhase == PLG_PHASE_MILD)
    {
        sMsg = "[Plague] " + sFailPrefix
            + "You feel weak. Something is wrong... " + sRollInfo;
    }
    else
    {
        sMsg = "[Plague] " + sFailPrefix + sName + " advances to "
            + PlgPhaseName(nNewPhase) + " " + sRollInfo;
    }
    SendMessageToPC(oPC, sMsg);
    FloatingTextStringOnCreature("Body fight: " + sFailPrefix + "advances",
        oPC, FALSE, FALSE);
}

// ============================================================
// Offline progression - iteracyjna symulacja
// Algorytm: konsumujemy time offline po phase boundaries,
// kazdy boundary = 1 save attempt z full mechanika.
// Critical = terminal (break).
// ============================================================

void PlgProcessOfflineProgression(object oPC, int nDiseaseId)
{
    json jState = PlgGetState(oPC, nDiseaseId);
    if(JsonGetType(jState) == JSON_TYPE_NULL) return;

    int nLastLogin = JsonGetInt(JsonObjectGet(jState, "last_login"));
    int nPhase     = JsonGetInt(JsonObjectGet(jState, "phase"));
    int nPhaseEnd  = JsonGetInt(JsonObjectGet(jState, "phase_end"));
    int nNow       = PlgUnixNow();

    int nTimeOffline = nNow - nLastLogin;
    if(nTimeOffline <= 0) return;

    // Czas pozostaly do boundary AT logout
    int nTimeToBoundary = nPhaseEnd - nLastLogin;
    if(nTimeToBoundary < 0) nTimeToBoundary = 0;

    int nPhasesAdvanced = 0;
    int nPhaseStart = nPhase; // do offline_progression event log
    int bCured = FALSE;
    string sEpisodeId = JsonGetString(JsonObjectGet(jState, "episode_id"));

    while(nTimeOffline >= nTimeToBoundary && nPhase < PLG_PHASE_CRITICAL)
    {
        nTimeOffline -= nTimeToBoundary;

        int nDC = PlgGetProgressionDC(nDiseaseId, nPhase);
        int nResult = PlgRollProgressionSave(oPC, nDC);
        int nRollVal = GetLocalInt(GetModule(), PLG_LVAR_LAST_ROLL);
        string sResultStr = PlgSaveResultToString(nResult);

        PlgLogBodyFight(oPC, nDiseaseId, sEpisodeId, nPhase, nRollVal, nDC, sResultStr);

        // Krytyczny sukces na incubation/mild = CURE
        if(nResult == PLG_SAVE_CRIT_SUCCESS && nPhase <= PLG_PHASE_MILD)
        {
            PlgCureAndNotify(oPC, nDiseaseId);
            SendMessageToPC(oPC,
                "[Plague] During your rest your body defeated the disease...");
            bCured = TRUE;
            break;
        }

        // Fail (standard or crit) = advance
        if(nResult == PLG_SAVE_FAIL || nResult == PLG_SAVE_CRIT_FAIL)
        {
            nPhase++;
            nPhasesAdvanced++;
        }
        // Success / crit_success at severe+ = phase stays, time keeps consuming

        nTimeToBoundary = PlgPhaseInterval(nDiseaseId, nPhase);
    }

    if(bCured) return;

    // If no phase boundary was crossed, the original phase_start/phase_end
    // remain valid - do NOT recompute them (would shift phase_end forward
    // by the time the player was already in the phase before logout).
    if(nPhasesAdvanced == 0)
    {
        // Even though phase didn't change, re-apply effects in case server
        // restart cleared them.
        PlgApplyEffectsForDisease(oPC, nDiseaseId, nPhase);
        return;
    }

    // Po petli - ustal nowe phase_start/end na podstawie pozostalego czasu.
    // nTimeOffline = remaining time after last consumed boundary;
    // sets new phase_start to (now - remainder) so the new phase clock
    // continues correctly.
    int nNewPhaseStart = nNow - nTimeOffline;
    int nNewPhaseEnd;
    if(nPhase >= PLG_PHASE_CRITICAL)
        nNewPhaseEnd = 0;
    else
        nNewPhaseEnd = nNewPhaseStart + PlgPhaseInterval(nDiseaseId, nPhase);

    PlgSetPhase(oPC, nDiseaseId, nPhase, nNewPhaseStart, nNewPhaseEnd);
    PlgApplyEffectsForDisease(oPC, nDiseaseId, nPhase);

    // Log offline_progression summary
    int nTimeOfflineTotal = nNow - nLastLogin;
    PlgLogOfflineProg(oPC, nDiseaseId, sEpisodeId, nPhaseStart, nPhase,
        nPhasesAdvanced, nTimeOfflineTotal);

    // Notify gracza co sie stalo offline
    if(nPhasesAdvanced > 0)
    {
        string sMsg;
        if(nPhase == PLG_PHASE_CRITICAL)
            sMsg = "[Plague] Your condition worsened during your rest - you are critical!";
        else
            sMsg = "[Plague] The disease progressed during your rest...";
        SendMessageToPC(oPC, sMsg);
        FloatingTextStringOnCreature(sMsg, oPC, FALSE, FALSE);
    }
}

// ============================================================
// Per-tick DoT dla critical phase (heartbeat = 6s, tick co 5 = 30s)
// ============================================================

void PlgApplyPerTick(object oPC, int nDiseaseId)
{
    if(!PlgHasDisease(oPC, nDiseaseId)) return;

    // Safe area - pause DoT
    if(GetLocalInt(GetArea(oPC), PLG_LVAR_AREA_FREEZE)) return;

    json jState = PlgGetState(oPC, nDiseaseId);
    if(JsonGetType(jState) == JSON_TYPE_NULL) return;

    int nPhase = JsonGetInt(JsonObjectGet(jState, "phase"));
    if(nPhase < PLG_PHASE_CRITICAL) return;

    string sLvar = PLG_LVAR_TICK + IntToString(nDiseaseId);
    int nTick = GetLocalInt(oPC, sLvar) + 1;
    if(nTick < 5) // 5 heartbeats = 30s
    {
        SetLocalInt(oPC, sLvar, nTick);
        return;
    }
    SetLocalInt(oPC, sLvar, 0);

    if(nDiseaseId == PLG_DIS_BLOOD_ROT)
    {
        ApplyEffectToObject(DURATION_TYPE_INSTANT,
            EffectDamage(4, DAMAGE_TYPE_MAGICAL), oPC);
        SendMessageToPC(oPC, "[Plague] Blood Rot drains your life force...");
    }
    else if(nDiseaseId == PLG_DIS_NECROTIC)
    {
        int nDmg = Random(4) + 1;
        ApplyEffectToObject(DURATION_TYPE_INSTANT,
            EffectDamage(nDmg, DAMAGE_TYPE_NEGATIVE), oPC);
        SendMessageToPC(oPC, "[Plague] The necrotic wound saps your vitality...");
    }
    // Czarna Dzuma i Bagienna Goraczka w critical: tylko stat penalties (juz mocne)
}

// ============================================================
// Contagion mechanic (faza F)
// Tylko critical phase, online-only, heartbeat-driven.
// Carrier emituje probe zarazenia co X sekund, target robi Fort save.
// ============================================================

void PlgApplyContagion(object oCarrier, int nDiseaseId)
{
    if(!PlgIsContagious(nDiseaseId)) return;

    // Safe area - pause contagion (carrier doesn't infect inside safe zones)
    if(GetLocalInt(GetArea(oCarrier), PLG_LVAR_AREA_FREEZE)) return;

    json jState = PlgGetState(oCarrier, nDiseaseId);
    if(JsonGetType(jState) == JSON_TYPE_NULL) return;

    int nPhase = JsonGetInt(JsonObjectGet(jState, "phase"));
    if(nPhase != PLG_PHASE_CRITICAL) return; // tylko critical zaraza

    // Tick counter - co X heartbeats (X = ContagionTick / 6s)
    string sTickLvar = PLG_LVAR_CONTAG_TICK + IntToString(nDiseaseId);
    int nTick = GetLocalInt(oCarrier, sTickLvar) + 1;
    int nThreshold = PlgGetContagionTick(nDiseaseId) / 6;
    if(nThreshold < 1) nThreshold = 1;

    if(nTick < nThreshold)
    {
        SetLocalInt(oCarrier, sTickLvar, nTick);
        return;
    }
    SetLocalInt(oCarrier, sTickLvar, 0);

    // Iteruj po pobliskich PC
    float fRange = PlgGetContagionRange(nDiseaseId);
    int nDC      = PlgGetContagionDC(nDiseaseId);
    location lCarrier = GetLocation(oCarrier);

    object oNearby = GetFirstObjectInShape(SHAPE_SPHERE, fRange, lCarrier,
        FALSE, OBJECT_TYPE_CREATURE);

    json jCarrierState = PlgGetState(oCarrier, nDiseaseId);
    string sCarrierEpId = JsonGetString(JsonObjectGet(jCarrierState, "episode_id"));

    while(GetIsObjectValid(oNearby))
    {
        if(GetIsPC(oNearby) && !GetIsDM(oNearby) && oNearby != oCarrier)
        {
            if(!PlgIsImmune(oNearby, nDiseaseId) && !PlgHasDisease(oNearby, nDiseaseId))
            {
                int nRoll = Random(20) + 1;
                int nFort = GetFortitudeSavingThrow(oNearby);
                int nTotal = nRoll + nFort;
                int bInfected = (nTotal < nDC);

                PlgLogContagion(oCarrier, oNearby, nDiseaseId, sCarrierEpId,
                    nTotal, nDC, bInfected);

                if(bInfected)
                {
                    PlgContractAndNotify(oNearby, nDiseaseId);
                    // Ofiara nie wie ze zostala zarazona (incubation = hidden)
                    // Carrier tez nie dostaje jawnego potwierdzenia (immersion)
                }
            }
        }
        oNearby = GetNextObjectInShape(SHAPE_SPHERE, fRange, lCarrier,
            FALSE, OBJECT_TYPE_CREATURE);
    }
}

// ============================================================
// OnClientEnter / OnClientLeave
// FAZA A: simple restore bez offline progression. Offline -> faza B.
// ============================================================

void PlgOnClientEnter(object oPC)
{
    if(!GetIsPC(oPC) || GetIsDM(oPC)) return;

    // Inicjalizuj first_login dla cohort tracking (raz per UUID)
    PlgInitFirstLogin(oPC);

    json jStates = PlgGetStates(oPC);
    int nLen = JsonGetLength(jStates);
    if(nLen == 0) return;

    int nNow = PlgUnixNow();
    int bAnyFrozen = FALSE; // for the comfort message

    int i;
    for(i = 0; i < nLen; i++)
    {
        json jState = JsonArrayGet(jStates, i);
        int nDiseaseId       = JsonGetInt(JsonObjectGet(jState, "disease_id"));
        int nPhase           = JsonGetInt(JsonObjectGet(jState, "phase"));
        int nLastLogin       = JsonGetInt(JsonObjectGet(jState, "last_login"));
        int nPhaseStart      = JsonGetInt(JsonObjectGet(jState, "phase_start"));
        int nPhaseEnd        = JsonGetInt(JsonObjectGet(jState, "phase_end"));
        int bFrozenAtLogout  = JsonGetInt(JsonObjectGet(jState, "frozen_at_logout"));
        string sEpisodeId    = JsonGetString(JsonObjectGet(jState, "episode_id"));

        SetLocalInt(oPC, PLG_LVAR_HAS + IntToString(nDiseaseId), TRUE);
        SetLocalInt(oPC, PLG_LVAR_TICK + IntToString(nDiseaseId), 0);

        PlgLogLogin(oPC, nDiseaseId, sEpisodeId, nPhase);

        if(bFrozenAtLogout)
        {
            // Player was in a safe area at logout - freeze the disease clock
            // by shifting phase_start/end forward by the offline duration.
            // Clock pauses: time-to-boundary stays the same.
            bAnyFrozen = TRUE;
            int nDelta = nNow - nLastLogin;
            if(nDelta > 0 && nPhase < PLG_PHASE_CRITICAL)
            {
                PlgSetPhase(oPC, nDiseaseId, nPhase,
                    nPhaseStart + nDelta, nPhaseEnd + nDelta);
            }
        }
        else
        {
            // Standard offline progression
            PlgProcessOfflineProgression(oPC, nDiseaseId);
        }

        // Re-apply effects (po offline progression jezeli sie zmienila faza)
        if(PlgHasDisease(oPC, nDiseaseId))
        {
            json jStateNow = PlgGetState(oPC, nDiseaseId);
            int nPhaseNow = JsonGetInt(JsonObjectGet(jStateNow, "phase"));
            PlgApplyEffectsForDisease(oPC, nDiseaseId, nPhaseNow);
        }
    }

    // Aktualizuj last_login dla wszystkich (po offline simulation)
    PlgUpdateLastLogin(oPC);

    if(bAnyFrozen)
    {
        SendMessageToPC(oPC,
            "[Plague] Peaceful rest allowed your body to pause the disease.");
    }
}

void PlgOnClientLeave(object oPC)
{
    if(!GetIsPC(oPC) || GetIsDM(oPC)) return;

    // Capture safe area state at logout (GetArea is reliable here - player is
    // still in the world). Stored in SQL so OnClientEnter can read it without
    // depending on GetArea timing (which can return INVALID just after login).
    object oArea = GetArea(oPC);
    int bInSafeArea = GetLocalInt(oArea, PLG_LVAR_AREA_FREEZE);

    // Log logout per kazda chorobe
    json jStates = PlgGetStates(oPC);
    int nLen = JsonGetLength(jStates);
    int i;
    for(i = 0; i < nLen; i++)
    {
        json jState = JsonArrayGet(jStates, i);
        int nDiseaseId = JsonGetInt(JsonObjectGet(jState, "disease_id"));
        int nPhase     = JsonGetInt(JsonObjectGet(jState, "phase"));
        string sEpisodeId = JsonGetString(JsonObjectGet(jState, "episode_id"));
        PlgLogLogout(oPC, nDiseaseId, sEpisodeId, nPhase, bInSafeArea);
    }

    PlgUpdateLastLogin(oPC);
    PlgUpdateFrozenAtLogout(oPC, bInSafeArea);
}

// ============================================================
// Diagnostic & item handling (faza C/D)
// ============================================================

// Czy gracz wie jaka chorobe ma (uzyl soczewki lub byl u medyka).
int PlgIsDiagnosed(object oPC, int nDiseaseId)
{
    return GetLocalInt(oPC, PLG_LVAR_DIAGNOSED + IntToString(nDiseaseId));
}

// Soczewka diagnostyczna (tag: plg_lens). Czyta tagged effect icon, ujawnia chorobe.
// Zwraca TRUE jezeli zdiagnozowano cos.
int PlgUseDiagnosticLens(object oPC, object oItem)
{
    int nFound = 0;
    string sFoundDiseases = "";

    int nDiseaseId;
    for(nDiseaseId = 0; nDiseaseId < PLG_DIS_COUNT; nDiseaseId++)
    {
        if(!PlgHasDisease(oPC, nDiseaseId)) continue;

        // Always diagnose if not already (sets diagnosed=1 for telemetry).
        if(!PlgIsDiagnosed(oPC, nDiseaseId))
        {
            SetLocalInt(oPC, PLG_LVAR_DIAGNOSED + IntToString(nDiseaseId), TRUE);
            PlgSetDiagnosed(oPC, nDiseaseId, TRUE);

            json jState = PlgGetState(oPC, nDiseaseId);
            string sEpisodeId = JsonGetString(JsonObjectGet(jState, "episode_id"));
            PlgLogLensUsed(oPC, nDiseaseId, sEpisodeId);
        }

        // List all active diseases (player might want to re-check current state).
        if(nFound > 0) sFoundDiseases += ", ";
        sFoundDiseases += PlgDiseaseName(nDiseaseId);
        nFound++;
    }

    if(nFound == 0)
    {
        SendMessageToPC(oPC, "[Lens] You are healthy. No diseases detected.");
        return FALSE; // do not consume lens if player has nothing
    }

    string sMsg = "[Lens] Active diseases: " + sFoundDiseases;
    SendMessageToPC(oPC, sMsg);
    FloatingTextStringOnCreature(sMsg, oPC, FALSE, FALSE);

    // Consume 1 lens (stackable)
    int nStack = GetItemStackSize(oItem);
    if(nStack <= 1) DestroyObject(oItem);
    else            SetItemStackSize(oItem, nStack - 1);

    return TRUE;
}

// Lekarstwo z systemem rang. Sprawdza tag, parsuje, weryfikuje rank vs phase.
// Zwraca TRUE jezeli wyleczono.
int PlgUseRemedy(object oPC, object oItem)
{
    string sTag = GetTag(oItem);
    json jParsed = PlgParseRemedyTag(sTag);
    if(JsonGetType(jParsed) == JSON_TYPE_NULL)
    {
        return FALSE; // nie remedy
    }

    int nDiseaseId = JsonGetInt(JsonObjectGet(jParsed, "disease_id"));
    int nRemedyRank = JsonGetInt(JsonObjectGet(jParsed, "rank"));

    if(!PlgHasDisease(oPC, nDiseaseId))
    {
        SendMessageToPC(oPC, "[Remedy] Does not match your disease (or you are not sick).");
        return FALSE;
    }

    json jState = PlgGetState(oPC, nDiseaseId);
    int nPhase = JsonGetInt(JsonObjectGet(jState, "phase"));
    string sEpisodeId = JsonGetString(JsonObjectGet(jState, "episode_id"));

    if(!PlgCanRemedyHeal(nRemedyRank, nPhase))
    {
        PlgLogCureAttempt(oPC, nDiseaseId, sEpisodeId, sTag, nRemedyRank, "rank_mismatch");
        SendMessageToPC(oPC,
            "[Remedy] Too weak for the current condition. You need a stronger one.");
        return FALSE;
    }

    PlgLogCureAttempt(oPC, nDiseaseId, sEpisodeId, sTag, nRemedyRank, "success");

    // Cure!
    PlgCureAndNotify(oPC, nDiseaseId);

    // Zniszcz 1 lekarstwo (stackowalne)
    int nStack = GetItemStackSize(oItem);
    if(nStack <= 1) DestroyObject(oItem);
    else            SetItemStackSize(oItem, nStack - 1);

    return TRUE;
}

// Apteczka (tag: plg_apteczka). Heal skill check vs DC per disease per phase.
// Zwraca TRUE jezeli sukces (cofa o 1 faze, lub cure jezeli mild->none).
int PlgUseFirstAid(object oPC, object oItem)
{
    // Znajdz pierwsza chorobe gracza ktora apteczka moze leczyc (mild/severe)
    // FAZA D: jezeli wiele chorob, gracz powinien wybrac (UI). Na razie - pierwsza.
    int nDiseaseId;
    int nFoundDisease = -1;
    int nFoundPhase = -1;
    for(nDiseaseId = 0; nDiseaseId < PLG_DIS_COUNT; nDiseaseId++)
    {
        if(!PlgHasDisease(oPC, nDiseaseId)) continue;
        json jState = PlgGetState(oPC, nDiseaseId);
        int nPhase = JsonGetInt(JsonObjectGet(jState, "phase"));

        // Apteczka dziala tylko w mild/severe (PlgGetFirstAidDC zwraca -1 dla critical/incubation)
        int nDC = PlgGetFirstAidDC(nDiseaseId, nPhase);
        if(nDC > 0)
        {
            nFoundDisease = nDiseaseId;
            nFoundPhase = nPhase;
            break;
        }
    }

    if(nFoundDisease < 0)
    {
        SendMessageToPC(oPC,
            "[First Aid] Nothing to treat (or condition too advanced - first aid won't help).");
        return FALSE;
    }

    int nDC = PlgGetFirstAidDC(nFoundDisease, nFoundPhase);
    int nRoll = Random(20) + 1;
    int nHealSkill = GetSkillRank(SKILL_HEAL, oPC);
    int nTotal = nRoll + nHealSkill;

    // Zniszcz apteczke ZAWSZE (sukces lub fail) - wzorzec 15
    int nStack = GetItemStackSize(oItem);
    if(nStack <= 1) DestroyObject(oItem);
    else            SetItemStackSize(oItem, nStack - 1);

    json jState = PlgGetState(oPC, nFoundDisease);
    string sEpisodeId = JsonGetString(JsonObjectGet(jState, "episode_id"));

    // Roll info string - explicit breakdown for player feedback
    string sRollInfo = "(d20: " + IntToString(nRoll)
        + " + Heal " + IntToString(nHealSkill)
        + " = " + IntToString(nTotal)
        + " vs DC " + IntToString(nDC) + ")";

    if(nTotal >= nDC)
    {
        PlgLogApteczka(oPC, nFoundDisease, sEpisodeId, nFoundPhase, nTotal, nDC, "success");

        // Phase retreat. Incubation/Mild -> cured. Severe -> Mild.
        if(nFoundPhase <= PLG_PHASE_MILD)
        {
            PlgCureAndNotify(oPC, nFoundDisease);
            SendMessageToPC(oPC,
                "[First Aid] Success " + sRollInfo
                + ". You feel better - the disease has retreated!");
        }
        else
        {
            // Cofa severe -> mild
            int nNewPhase = nFoundPhase - 1;
            int nInterval = PlgPhaseInterval(nFoundDisease, nNewPhase);
            int nNow = PlgUnixNow();
            PlgSetPhase(oPC, nFoundDisease, nNewPhase, nNow, nNow + nInterval);
            PlgApplyEffectsForDisease(oPC, nFoundDisease, nNewPhase);
            PlgLogPhaseChange(oPC, PLG_EVT_PHASE_RETREAT, nFoundDisease, sEpisodeId,
                nFoundPhase, nNewPhase, nTotal, nDC, "apteczka");
            SendMessageToPC(oPC,
                "[First Aid] Success " + sRollInfo
                + ". The disease retreated by one phase.");
        }
        return TRUE;
    }
    else
    {
        PlgLogApteczka(oPC, nFoundDisease, sEpisodeId, nFoundPhase, nTotal, nDC, "fail");
        SendMessageToPC(oPC,
            "[First Aid] Failed " + sRollInfo
            + ". Try again or see a healer.");
        return FALSE;
    }
}

// Centralny dispatcher dla item activation - rozpoznaje typ itemu po tagu.
// Hookuj z OnActivateItem dispatchera modulu.
// Zwraca TRUE jezeli przeprocesowano (item plague-related).
int PlgHandleItemActivation(object oPC, object oItem)
{
    if(!GetIsObjectValid(oPC) || !GetIsObjectValid(oItem)) return FALSE;
    if(!GetIsPC(oPC) || GetIsDM(oPC)) return FALSE;

    string sTag = GetTag(oItem);

    // Soczewka diagnostyczna
    if(sTag == "plg_lens")
    {
        PlgUseDiagnosticLens(oPC, oItem);
        return TRUE;
    }

    // Apteczka
    if(sTag == "plg_firstaid")
    {
        PlgUseFirstAid(oPC, oItem);
        return TRUE;
    }

    // Lekarstwo (sprawdz przez prefix)
    if(GetStringLeft(sTag, 8) == "plg_rem_")
    {
        PlgUseRemedy(oPC, oItem);
        return TRUE;
    }

    return FALSE; // nie nasz item
}
