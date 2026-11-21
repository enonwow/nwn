// lib_fac.nss - Faction Reputation: core logic, NUI window, effect management
//
// Public API (call from other scripts):
//   FacAdjust(oPC, nFactionId, nDelta, sReason) - change reputation, apply effects, refresh UI
//   FacGetPoints(oPC, nFactionId)               - read current points
//   FacOpenWindow(oPC)                          - open/refresh the reputation panel
//   FacApplyAllEffects(oPC)                     - reapply effects on login
//   FacInit()                                   - called from sys_on_load

#include "lib_fac_def"

// ================================================================
// Forward declarations
// ================================================================

void FacRemoveEffects(object oPC, int nFactionId);
void FacApplyEffectsForStanding(object oPC, int nFactionId, int nStanding);
void FacApplyAllEffects(object oPC);
void FacAdjust(object oPC, int nFactionId, int nDelta, string sReason);
int  FacGetPoints(object oPC, int nFactionId);
void FacOpenWindow(object oPC);
void FacFeedList(object oPC, int nToken);
void FacFeedDetail(object oPC, int nToken, int nFactionId);
json FacBuildWindow(object oPC);

// ================================================================
// Effect management
// ================================================================

void FacRemoveEffects(object oPC, int nFactionId)
{
    string sTag = FAC_EFFECT_TAG + IntToString(nFactionId);
    effect e = GetFirstEffect(oPC);
    effect eNext;
    while(GetIsEffectValid(e))
    {
        eNext = GetNextEffect(oPC);
        if(GetEffectTag(e) == sTag)
            RemoveEffect(oPC, e);
        e = eNext;
    }
}

// Builds and applies a permanent linked effect for the given faction+standing.
// Each faction has one active effect stack (tagged FAC_EFF_<id>).
// HOSTILE grants a curse penalty; NEUTRAL has no mechanical effect.
void FacApplyEffectsForStanding(object oPC, int nFactionId, int nStanding)
{
    FacRemoveEffects(oPC, nFactionId);

    string sTag = FAC_EFFECT_TAG + IntToString(nFactionId);
    effect eChain;
    int    bHasEffect = FALSE;

    // Iron Guard
    if(nFactionId == FAC_ID_IRON_GUARD)
    {
        switch(nStanding)
        {
            case FAC_STANDING_HOSTILE:
                eChain = EffectAbilityDecrease(ABILITY_CHARISMA, 2);
                bHasEffect = TRUE;
                break;
            case FAC_STANDING_FRIENDLY:
                eChain = EffectAbilityIncrease(ABILITY_CHARISMA, 1);
                eChain = EffectLinkEffects(eChain, EffectSkillIncrease(SKILL_PERSUADE, 2));
                bHasEffect = TRUE;
                break;
            case FAC_STANDING_HONORED:
                eChain = EffectAbilityIncrease(ABILITY_CHARISMA, 2);
                eChain = EffectLinkEffects(eChain, EffectSkillIncrease(SKILL_PERSUADE, 4));
                eChain = EffectLinkEffects(eChain, EffectACIncrease(1, AC_DODGE_BONUS));
                bHasEffect = TRUE;
                break;
            case FAC_STANDING_EXALTED:
                eChain = EffectAbilityIncrease(ABILITY_CHARISMA, 3);
                eChain = EffectLinkEffects(eChain, EffectSkillIncrease(SKILL_PERSUADE, 6));
                eChain = EffectLinkEffects(eChain, EffectACIncrease(2, AC_DODGE_BONUS));
                eChain = EffectLinkEffects(eChain, EffectAttackIncrease(1, ATTACK_BONUS_MISC));
                bHasEffect = TRUE;
                break;
            default:
                break;
        }
    }
    // Brotherhood of Shadow
    else if(nFactionId == FAC_ID_SHADOW)
    {
        switch(nStanding)
        {
            case FAC_STANDING_HOSTILE:
                // No passive stat effect — NPC hostility handled by server event
                break;
            case FAC_STANDING_FRIENDLY:
                eChain = EffectSkillIncrease(SKILL_HIDE, 3);
                eChain = EffectLinkEffects(eChain, EffectSkillIncrease(SKILL_MOVE_SILENTLY, 3));
                bHasEffect = TRUE;
                break;
            case FAC_STANDING_HONORED:
                eChain = EffectSkillIncrease(SKILL_HIDE, 6);
                eChain = EffectLinkEffects(eChain, EffectSkillIncrease(SKILL_MOVE_SILENTLY, 6));
                eChain = EffectLinkEffects(eChain, EffectSkillIncrease(SKILL_PICK_POCKET, 3));
                bHasEffect = TRUE;
                break;
            case FAC_STANDING_EXALTED:
                eChain = EffectSkillIncrease(SKILL_HIDE, 9);
                eChain = EffectLinkEffects(eChain, EffectSkillIncrease(SKILL_MOVE_SILENTLY, 9));
                eChain = EffectLinkEffects(eChain, EffectSkillIncrease(SKILL_PICK_POCKET, 6));
                eChain = EffectLinkEffects(eChain, EffectConcealment(10, MISS_CHANCE_TYPE_NORMAL));
                bHasEffect = TRUE;
                break;
            default:
                break;
        }
    }
    // Cult of the Eternal Night
    else if(nFactionId == FAC_ID_NIGHT_CULT)
    {
        switch(nStanding)
        {
            case FAC_STANDING_HOSTILE:
                // Necromantic curse: will save penalty
                eChain = EffectSavingThrowDecrease(SAVING_THROW_WILL, 2,
                    SAVING_THROW_TYPE_ALL);
                bHasEffect = TRUE;
                break;
            case FAC_STANDING_FRIENDLY:
                eChain = EffectSkillIncrease(SKILL_SPELLCRAFT, 3);
                eChain = EffectLinkEffects(eChain, EffectSkillIncrease(SKILL_LORE, 2));
                bHasEffect = TRUE;
                break;
            case FAC_STANDING_HONORED:
                eChain = EffectSkillIncrease(SKILL_SPELLCRAFT, 6);
                eChain = EffectLinkEffects(eChain, EffectSkillIncrease(SKILL_LORE, 4));
                eChain = EffectLinkEffects(eChain, EffectAbilityIncrease(ABILITY_CONSTITUTION, 1));
                bHasEffect = TRUE;
                break;
            case FAC_STANDING_EXALTED:
                eChain = EffectSkillIncrease(SKILL_SPELLCRAFT, 9);
                eChain = EffectLinkEffects(eChain, EffectSkillIncrease(SKILL_LORE, 6));
                eChain = EffectLinkEffects(eChain, EffectAbilityIncrease(ABILITY_STRENGTH, 2));
                eChain = EffectLinkEffects(eChain, EffectAbilityIncrease(ABILITY_CONSTITUTION, 1));
                bHasEffect = TRUE;
                break;
            default:
                break;
        }
    }
    // Order of the Flame
    else if(nFactionId == FAC_ID_ORDER_FLAME)
    {
        switch(nStanding)
        {
            case FAC_STANDING_HOSTILE:
                // Pariah curse: wisdom drain
                eChain = EffectAbilityDecrease(ABILITY_WISDOM, 2);
                bHasEffect = TRUE;
                break;
            case FAC_STANDING_FRIENDLY:
                eChain = EffectAbilityIncrease(ABILITY_WISDOM, 1);
                eChain = EffectLinkEffects(eChain, EffectSkillIncrease(SKILL_HEAL, 2));
                bHasEffect = TRUE;
                break;
            case FAC_STANDING_HONORED:
                eChain = EffectAbilityIncrease(ABILITY_WISDOM, 2);
                eChain = EffectLinkEffects(eChain, EffectSkillIncrease(SKILL_HEAL, 4));
                eChain = EffectLinkEffects(eChain, EffectSavingThrowIncrease(SAVING_THROW_ALL, 1,
                    SAVING_THROW_TYPE_ALL));
                bHasEffect = TRUE;
                break;
            case FAC_STANDING_EXALTED:
                eChain = EffectAbilityIncrease(ABILITY_WISDOM, 3);
                eChain = EffectLinkEffects(eChain, EffectSkillIncrease(SKILL_HEAL, 6));
                eChain = EffectLinkEffects(eChain, EffectSavingThrowIncrease(SAVING_THROW_ALL, 2,
                    SAVING_THROW_TYPE_ALL));
                eChain = EffectLinkEffects(eChain, EffectACIncrease(1, AC_DODGE_BONUS));
                bHasEffect = TRUE;
                break;
            default:
                break;
        }
    }

    if(!bHasEffect) return;

    eChain = TagEffect(eChain, sTag);
    eChain = ExtraordinaryEffect(eChain);
    ApplyEffectToObject(DURATION_TYPE_PERMANENT, eChain, oPC);
}

// Reads all faction reps from DB and applies/reapplies effects.
// Called on login and after any reputation change.
void FacApplyAllEffects(object oPC)
{
    if(!GetIsPC(oPC) || GetIsDM(oPC)) return;

    int i;
    for(i = 0; i < FAC_COUNT; i++)
    {
        int nPoints  = FacSqlGetPoints(oPC, i);
        int nStanding = FacGetStanding(nPoints);
        FacApplyEffectsForStanding(oPC, i, nStanding);
    }
}

// ================================================================
// Reputation adjustment (main public API)
// ================================================================

int FacGetPoints(object oPC, int nFactionId)
{
    return FacSqlGetPoints(oPC, nFactionId);
}

// Adjusts faction reputation by nDelta, clamped to [FAC_POINTS_MIN, FAC_POINTS_MAX].
// Applies rival penalty automatically.
// Reapplies passive effects and refreshes open NUI window.
void FacAdjust(object oPC, int nFactionId, int nDelta, string sReason)
{
    if(!GetIsPC(oPC) || GetIsDM(oPC))    return;
    if(nFactionId < 0 || nFactionId >= FAC_COUNT) return;
    if(nDelta == 0) return;

    int nOldPoints   = FacSqlGetPoints(oPC, nFactionId);
    int nNewPoints   = nOldPoints + nDelta;
    if(nNewPoints < FAC_POINTS_MIN) nNewPoints = FAC_POINTS_MIN;
    if(nNewPoints > FAC_POINTS_MAX) nNewPoints = FAC_POINTS_MAX;

    int nActualDelta = nNewPoints - nOldPoints;
    if(nActualDelta == 0) return;

    FacSqlSetPoints(oPC, nFactionId, nNewPoints);
    FacSqlLogHistory(oPC, nFactionId, nActualDelta, sReason);

    int nOldStanding = FacGetStanding(nOldPoints);
    int nNewStanding = FacGetStanding(nNewPoints);
    FacApplyEffectsForStanding(oPC, nFactionId, nNewStanding);

    // Notify player when standing tier changes
    if(nNewStanding != nOldStanding)
    {
        string sDir = (nNewStanding > nOldStanding) ? "poprawilo" : "pogorszylo";
        string sMsg = "[Frakcje] Twoje nastawienie wobec " + FacName(nFactionId)
                    + " " + sDir + " sie: " + FacStandingName(nNewStanding)
                    + " (" + IntToString(nNewPoints) + ")";
        SendMessageToPC(oPC, sMsg);
        FloatingTextStringOnCreature(sMsg, oPC, FALSE, FALSE);
    }

    // Apply rival penalty
    int nRivalId = FacGetRival(nFactionId);
    if(nRivalId >= 0 && nActualDelta != 0)
    {
        int nPenalty = -(nActualDelta * FAC_RIVAL_PENALTY_PCT / 100);
        if(nPenalty != 0)
        {
            int nRivalOld = FacSqlGetPoints(oPC, nRivalId);
            int nRivalNew = nRivalOld + nPenalty;
            if(nRivalNew < FAC_POINTS_MIN) nRivalNew = FAC_POINTS_MIN;
            if(nRivalNew > FAC_POINTS_MAX) nRivalNew = FAC_POINTS_MAX;

            int nRivalActual = nRivalNew - nRivalOld;
            if(nRivalActual != 0)
            {
                FacSqlSetPoints(oPC, nRivalId, nRivalNew);
                FacSqlLogHistory(oPC, nRivalId, nRivalActual, "rivalry:" + sReason);

                int nRivalOldStanding = FacGetStanding(nRivalOld);
                int nRivalNewStanding = FacGetStanding(nRivalNew);
                FacApplyEffectsForStanding(oPC, nRivalId, nRivalNewStanding);

                if(nRivalNewStanding != nRivalOldStanding)
                {
                    string sDir2 = (nRivalNewStanding > nRivalOldStanding) ? "poprawilo" : "pogorszylo";
                    string sRMsg = "[Frakcje] Rywalizacja: nastawienie " + FacName(nRivalId)
                                 + " " + sDir2 + " sie: " + FacStandingName(nRivalNewStanding);
                    SendMessageToPC(oPC, sRMsg);
                }
            }
        }
    }

    // Refresh open NUI window
    int nToken = NuiFindWindow(oPC, FAC_WINDOW);
    if(nToken != 0)
    {
        FacFeedList(oPC, nToken);
        // Refresh detail for currently selected faction if it changed
        int nSel = GetLocalInt(oPC, FAC_LVAR_SEL_FACTION);
        if(nSel == nFactionId || nSel == nRivalId)
            FacFeedDetail(oPC, nToken, nSel);
    }
}

// ================================================================
// NUI window construction
// ================================================================

json FacBuildWindow(object oPC)
{
    float fW     = GetNuiScaleDimension(oPC, FAC_WIN_W);
    float fBtnH  = GetNuiScaleDimension(oPC, 28.0);
    float fRowH  = GetNuiScaleDimension(oPC, 38.0);
    float fListH = GetNuiScaleDimension(oPC, 164.0); // 4 rows * ~41px
    float fDetH  = GetNuiScaleDimension(oPC, 268.0);

    // ---- Header row: title label + close button ----
    json jTitle = NuiLabel(JsonString("Reputacja Frakcji"),
                           JsonInt(NUI_HALIGN_LEFT),
                           JsonInt(NUI_VALIGN_MIDDLE));
    jTitle = NuiHeight(jTitle, fBtnH);

    json jClose = NuiButton(JsonString("Zamknij"));
    jClose = NuiId(jClose, FAC_BTN_CLOSE);
    jClose = NuiWidth(jClose, GetNuiScaleDimension(oPC, 80.0));
    jClose = NuiHeight(jClose, fBtnH);

    json jHeader = JsonArray();
    jHeader = JsonArrayInsert(jHeader, jTitle);
    jHeader = JsonArrayInsert(jHeader, jClose);

    // ---- List section: one row per faction ----
    // Columns: Name | Standing | Points | [Szczegoly]
    float fNameW    = GetNuiScaleDimension(oPC, 180.0);
    float fStandW   = GetNuiScaleDimension(oPC, 125.0);
    float fPtsW     = GetNuiScaleDimension(oPC, 75.0);
    float fDetailW  = GetNuiScaleDimension(oPC, 90.0);

    json jLstName = NuiLabel(NuiBind(FAC_BIND_LST_NAME),
                             JsonInt(NUI_HALIGN_LEFT),
                             JsonInt(NUI_VALIGN_MIDDLE));
    jLstName = NuiWidth(jLstName, fNameW);

    json jLstStanding = NuiLabel(NuiBind(FAC_BIND_LST_STANDING),
                                 JsonInt(NUI_HALIGN_LEFT),
                                 JsonInt(NUI_VALIGN_MIDDLE));
    jLstStanding = NuiWidth(jLstStanding, fStandW);
    jLstStanding = NuiStyleForegroundColor(jLstStanding, NuiBind(FAC_BIND_LST_COLOR));

    json jLstPts = NuiLabel(NuiBind(FAC_BIND_LST_POINTS),
                            JsonInt(NUI_HALIGN_RIGHT),
                            JsonInt(NUI_VALIGN_MIDDLE));
    jLstPts = NuiWidth(jLstPts, fPtsW);

    json jLstBtn = NuiId(NuiButton(JsonString("Szczegoly")), FAC_BTN_ROW);
    jLstBtn = NuiWidth(jLstBtn, fDetailW);
    jLstBtn = NuiHeight(jLstBtn, GetNuiScaleDimension(oPC, 28.0));

    json jCellRow = JsonArray();
    jCellRow = JsonArrayInsert(jCellRow, jLstName);
    jCellRow = JsonArrayInsert(jCellRow, jLstStanding);
    jCellRow = JsonArrayInsert(jCellRow, jLstPts);
    jCellRow = JsonArrayInsert(jCellRow, jLstBtn);

    json jCell = NuiGroup(NuiRow(jCellRow), FALSE, NUI_SCROLLBARS_NONE);
    jCell = NuiEncouraged(jCell, NuiBind(FAC_BIND_LST_ROW_ENC));

    json jTmpl = JsonArrayInsert(JsonArray(), NuiListTemplateCell(jCell, 0.0, TRUE));
    json jList = NuiList(jTmpl, NuiBind(FAC_BIND_LST_COUNT), fRowH);
    jList = NuiHeight(jList, fListH);

    // ---- Detail section ----
    float fDetNameW    = GetNuiScaleDimension(oPC, 280.0);
    float fDetStandW   = GetNuiScaleDimension(oPC, 150.0);
    float fProgH       = GetNuiScaleDimension(oPC, 16.0);
    float fFlavorH     = GetNuiScaleDimension(oPC, 70.0);
    float fConsH       = GetNuiScaleDimension(oPC, 130.0);

    // Faction name + standing (same row)
    json jDetName = NuiLabel(NuiBind(FAC_BIND_DET_NAME),
                             JsonInt(NUI_HALIGN_LEFT),
                             JsonInt(NUI_VALIGN_MIDDLE));
    jDetName = NuiWidth(jDetName, fDetNameW);

    json jDetStanding = NuiLabel(NuiBind(FAC_BIND_DET_STANDING),
                                 JsonInt(NUI_HALIGN_RIGHT),
                                 JsonInt(NUI_VALIGN_MIDDLE));
    jDetStanding = NuiWidth(jDetStanding, fDetStandW);
    jDetStanding = NuiStyleForegroundColor(jDetStanding, NuiBind(FAC_BIND_DET_COLOR));

    json jDetNameRow = JsonArray();
    jDetNameRow = JsonArrayInsert(jDetNameRow, jDetName);
    jDetNameRow = JsonArrayInsert(jDetNameRow, jDetStanding);

    // Points label
    json jDetPts = NuiLabel(NuiBind(FAC_BIND_DET_POINTS),
                            JsonInt(NUI_HALIGN_LEFT),
                            JsonInt(NUI_VALIGN_MIDDLE));
    jDetPts = NuiHeight(jDetPts, GetNuiScaleDimension(oPC, 22.0));

    // Progress bar (value bound via JsonObjectSet below)
    json jDetBar = NuiProgressBar();
    jDetBar = JsonObjectSet(jDetBar, "value", NuiBind(FAC_BIND_DET_PROGRESS));
    jDetBar = NuiHeight(jDetBar, fProgH);

    // Flavor description
    json jFlavorLbl = NuiLabel(JsonString("Opis:"),
                               JsonInt(NUI_HALIGN_LEFT),
                               JsonInt(NUI_VALIGN_MIDDLE));
    jFlavorLbl = NuiHeight(jFlavorLbl, GetNuiScaleDimension(oPC, 20.0));

    json jFlavorBox = NuiGroup(
        NuiText(NuiBind(FAC_BIND_DET_FLAVOR), FALSE),
        FALSE, NUI_SCROLLBARS_NONE);
    jFlavorBox = NuiHeight(jFlavorBox, fFlavorH);
    jFlavorBox = NuiEnabled(jFlavorBox, JsonBool(FALSE));

    // Consequences
    json jConsLbl = NuiLabel(JsonString("Konsekwencje:"),
                             JsonInt(NUI_HALIGN_LEFT),
                             JsonInt(NUI_VALIGN_MIDDLE));
    jConsLbl = NuiHeight(jConsLbl, GetNuiScaleDimension(oPC, 20.0));

    json jConsBox = NuiGroup(
        NuiText(NuiBind(FAC_BIND_DET_CONS), FALSE),
        TRUE, NUI_SCROLLBARS_AUTO);
    jConsBox = NuiHeight(jConsBox, fConsH);
    jConsBox = NuiEnabled(jConsBox, JsonBool(FALSE));

    // Detail column
    json jDetCol = JsonArray();
    jDetCol = JsonArrayInsert(jDetCol, NuiRow(jDetNameRow));
    jDetCol = JsonArrayInsert(jDetCol, jDetPts);
    jDetCol = JsonArrayInsert(jDetCol, jDetBar);
    jDetCol = JsonArrayInsert(jDetCol, CreateEmptyRow(oPC, 4.0));
    jDetCol = JsonArrayInsert(jDetCol, jFlavorLbl);
    jDetCol = JsonArrayInsert(jDetCol, jFlavorBox);
    jDetCol = JsonArrayInsert(jDetCol, CreateEmptyRow(oPC, 4.0));
    jDetCol = JsonArrayInsert(jDetCol, jConsLbl);
    jDetCol = JsonArrayInsert(jDetCol, jConsBox);

    json jDetGroup = NuiGroup(NuiCol(jDetCol), FALSE, NUI_SCROLLBARS_NONE);
    jDetGroup = NuiHeight(jDetGroup, fDetH);

    // ---- Root column ----
    json jRoot = JsonArray();
    jRoot = JsonArrayInsert(jRoot, NuiRow(jHeader));
    jRoot = JsonArrayInsert(jRoot, CreateEmptyRow(oPC, 4.0));
    jRoot = JsonArrayInsert(jRoot, jList);
    jRoot = JsonArrayInsert(jRoot, CreateEmptyRow(oPC, 6.0));
    jRoot = JsonArrayInsert(jRoot, jDetGroup);

    return NuiCol(jRoot);
}

// ================================================================
// Window lifecycle
// ================================================================

void FacOpenWindow(object oPC)
{
    int nToken = NuiFindWindow(oPC, FAC_WINDOW);
    if(nToken != 0)
    {
        // Already open — just refresh
        FacFeedList(oPC, nToken);
        FacFeedDetail(oPC, nToken, GetLocalInt(oPC, FAC_LVAR_SEL_FACTION));
        return;
    }

    float fW = GetNuiScaleDimension(oPC, FAC_WIN_W);
    float fH = GetNuiScaleDimension(oPC, FAC_WIN_H);

    // Center on screen
    float fCX = (IntToFloat(GetPlayerDeviceProperty(oPC, PLAYER_DEVICE_PROPERTY_GUI_WIDTH))  - fW) / 2.0;
    float fCY = (IntToFloat(GetPlayerDeviceProperty(oPC, PLAYER_DEVICE_PROPERTY_GUI_HEIGHT)) - fH) / 2.0;
    json jGeom = NuiRect(fCX, fCY, fW, fH);

    json jLayout = FacBuildWindow(oPC);

    // Wrap content in NuiWindow frame (no native title bar — we have our own header row)
    json jWin = NuiWindow(jLayout,
        JsonBool(FALSE),               // no native title text
        NuiBind(FAC_BIND_WIN_GEOM),    // geometry via bind (allows persistence)
        JsonBool(FALSE),               // not resizable
        JsonBool(FALSE),               // not collapsed
        JsonBool(FALSE),               // no native close button (we have FAC_BTN_CLOSE)
        JsonBool(FALSE),               // not transparent
        JsonBool(TRUE));               // with border

    nToken = NuiCreate(oPC, jWin, FAC_WINDOW, FAC_EV_SCRIPT);
    NuiSetBind(oPC, nToken, FAC_BIND_WIN_GEOM, jGeom);

    SetLocalInt(oPC, FAC_LVAR_SEL_FACTION, FAC_ID_IRON_GUARD);

    FacFeedList(oPC, nToken);
    FacFeedDetail(oPC, nToken, FAC_ID_IRON_GUARD);
}

// ================================================================
// Data feed helpers
// ================================================================

void FacFeedList(object oPC, int nToken)
{
    json jNames     = JsonArray();
    json jStandings = JsonArray();
    json jColors    = JsonArray();
    json jPoints    = JsonArray();
    json jEncs      = JsonArray();
    int  nSel       = GetLocalInt(oPC, FAC_LVAR_SEL_FACTION);

    int i;
    for(i = 0; i < FAC_COUNT; i++)
    {
        int    nPts      = FacSqlGetPoints(oPC, i);
        int    nStanding = FacGetStanding(nPts);
        string sPts      = IntToString(nPts);
        if(nPts > 0) sPts = "+" + sPts;

        jNames     = JsonArrayInsert(jNames,     JsonString(FacName(i)));
        jStandings = JsonArrayInsert(jStandings, JsonString(FacStandingName(nStanding)));
        jColors    = JsonArrayInsert(jColors,    FacStandingColor(nStanding));
        jPoints    = JsonArrayInsert(jPoints,    JsonString(sPts));
        jEncs      = JsonArrayInsert(jEncs,      JsonBool(i == nSel));
    }

    NuiSetBind(oPC, nToken, FAC_BIND_LST_NAME,     jNames);
    NuiSetBind(oPC, nToken, FAC_BIND_LST_STANDING, jStandings);
    NuiSetBind(oPC, nToken, FAC_BIND_LST_COLOR,    jColors);
    NuiSetBind(oPC, nToken, FAC_BIND_LST_POINTS,   jPoints);
    NuiSetBind(oPC, nToken, FAC_BIND_LST_ROW_ENC,  jEncs);
    NuiSetBind(oPC, nToken, FAC_BIND_LST_COUNT,    JsonInt(FAC_COUNT));
}

void FacFeedDetail(object oPC, int nToken, int nFactionId)
{
    if(nFactionId < 0 || nFactionId >= FAC_COUNT) return;

    int    nPts      = FacSqlGetPoints(oPC, nFactionId);
    int    nStanding = FacGetStanding(nPts);
    string sPts      = IntToString(nPts);
    if(nPts > 0) sPts = "+" + sPts;

    NuiSetBind(oPC, nToken, FAC_BIND_DET_NAME,     JsonString(FacName(nFactionId)));
    NuiSetBind(oPC, nToken, FAC_BIND_DET_STANDING, JsonString(FacStandingName(nStanding)));
    NuiSetBind(oPC, nToken, FAC_BIND_DET_COLOR,    FacStandingColor(nStanding));
    NuiSetBind(oPC, nToken, FAC_BIND_DET_POINTS,   JsonString("Punkty: " + sPts + " / " + IntToString(FAC_POINTS_MAX)));
    NuiSetBind(oPC, nToken, FAC_BIND_DET_PROGRESS, JsonFloat(FacProgressNorm(nPts)));
    NuiSetBind(oPC, nToken, FAC_BIND_DET_FLAVOR,   JsonString(FacDesc(nFactionId)));
    NuiSetBind(oPC, nToken, FAC_BIND_DET_CONS,     JsonString(FacConsequences(nFactionId, nStanding)));
}

// ================================================================
// Module init
// ================================================================

void FacInit()
{
    FacCreateTables();
}
