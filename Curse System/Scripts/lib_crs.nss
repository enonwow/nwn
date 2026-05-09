#include "lib_crs_def"

// ----------------------------------------------------------------
// Effect helpers
// ----------------------------------------------------------------

// Removes all effects with the curse-specific tag from oPC.
void CrsRemoveEffects(object oPC, int nCurseId)
{
    string sTag = CRS_EFF_TAG_PREFIX + IntToString(nCurseId);
    effect e = GetFirstEffect(oPC);
    while(GetIsEffectValid(e))
    {
        effect eNext = GetNextEffect(oPC);
        if(GetEffectTag(e) == sTag)
            RemoveEffect(oPC, e);
        e = eNext;
    }
}

// Removes all curse effects (all IDs) from oPC.
void CrsRemoveAllEffects(object oPC)
{
    CrsRemoveEffects(oPC, CRS_CURSE_ROTTING_HAND);
    CrsRemoveEffects(oPC, CRS_CURSE_PLAGUE_BRAND);
    CrsRemoveEffects(oPC, CRS_CURSE_SHADOW_DESPAIR);
    CrsRemoveEffects(oPC, CRS_CURSE_TREMBLING);
    CrsRemoveEffects(oPC, CRS_CURSE_SOUL_FROST);
    CrsRemoveEffects(oPC, CRS_CURSE_BLOOD_SEAL);
}

// Helper: tag an effect and apply it permanently to oPC.
void CrsApplyEffect(object oPC, effect e, int nCurseId)
{
    e = TagEffect(e, CRS_EFF_TAG_PREFIX + IntToString(nCurseId));
    e = SupernaturalEffect(e);
    ApplyEffectToObject(DURATION_TYPE_PERMANENT, e, oPC);
}

// Applies the mechanical effects for nCurseId at nStage.
// Call CrsRemoveEffects first to avoid stacking.
void CrsApplyEffects(object oPC, int nCurseId, int nStage)
{
    if(nStage < 1) return;

    switch(nCurseId)
    {
        // --- Gnijąca Dłoń: STR/DEX loss + attack penalty ---
        case CRS_CURSE_ROTTING_HAND:
        {
            int nStr = (nStage == 1) ? 2 : (nStage == 2) ? 4 : 6;
            int nDex = (nStage >= 2) ? (nStage == 2 ? 2 : 4) : 0;
            int nAtk = (nStage == 1) ? 1 : (nStage == 2) ? 2 : 4;
            CrsApplyEffect(oPC, EffectAbilityDecrease(ABILITY_STRENGTH,  nStr),   nCurseId);
            CrsApplyEffect(oPC, EffectAttackDecrease(nAtk, ATTACK_BONUS_MISC),    nCurseId);
            if(nDex > 0)
                CrsApplyEffect(oPC, EffectAbilityDecrease(ABILITY_DEXTERITY, nDex), nCurseId);
            if(nStage == 3)
                CrsApplyEffect(oPC, EffectSpellFailure(20, SPELL_SCHOOL_GENERAL),  nCurseId);
            break;
        }
        // --- Piętno Zarazy: CON + DEX loss (HP drain is handled in CrsTick) ---
        case CRS_CURSE_PLAGUE_BRAND:
        {
            int nCon = (nStage == 1) ? 2 : (nStage == 2) ? 4 : 6;
            int nDex = (nStage >= 2) ? (nStage == 2 ? 2 : 4) : 0;
            int nStr = (nStage == 3) ? 2 : 0;
            CrsApplyEffect(oPC, EffectAbilityDecrease(ABILITY_CONSTITUTION, nCon), nCurseId);
            if(nDex > 0)
                CrsApplyEffect(oPC, EffectAbilityDecrease(ABILITY_DEXTERITY, nDex), nCurseId);
            if(nStr > 0)
                CrsApplyEffect(oPC, EffectAbilityDecrease(ABILITY_STRENGTH, nStr),  nCurseId);
            break;
        }
        // --- Cień Rozpaczy: CHA/WIS loss + spell failure ---
        case CRS_CURSE_SHADOW_DESPAIR:
        {
            int nCha = (nStage == 1) ? 3 : (nStage == 2) ? 6 : 9;
            int nWis = (nStage >= 2) ? (nStage == 2 ? 2 : 4) : 0;
            int nSkl = (nStage == 1) ? 5 : (nStage == 2) ? 10 : 0;
            CrsApplyEffect(oPC, EffectAbilityDecrease(ABILITY_CHARISMA, nCha),    nCurseId);
            if(nWis > 0)
                CrsApplyEffect(oPC, EffectAbilityDecrease(ABILITY_WISDOM, nWis),  nCurseId);
            if(nSkl > 0)
                CrsApplyEffect(oPC, EffectSkillDecrease(SKILL_PERSUADE, nSkl),    nCurseId);
            if(nStage == 3)
                CrsApplyEffect(oPC, EffectSpellFailure(25, SPELL_SCHOOL_GENERAL), nCurseId);
            break;
        }
        // --- Klątwa Drżenia: DEX + attack + movement ---
        case CRS_CURSE_TREMBLING:
        {
            int nDex = (nStage == 1) ? 3 : (nStage == 2) ? 6 : 9;
            int nAtk = (nStage == 1) ? 2 : (nStage == 2) ? 4 : 6;
            int nMov = (nStage == 1) ? 0 : (nStage == 2) ? 20 : 40;
            CrsApplyEffect(oPC, EffectAbilityDecrease(ABILITY_DEXTERITY,  nDex), nCurseId);
            CrsApplyEffect(oPC, EffectAttackDecrease(nAtk, ATTACK_BONUS_MISC),   nCurseId);
            if(nMov > 0)
                CrsApplyEffect(oPC, EffectMovementSpeedDecrease(nMov),           nCurseId);
            break;
        }
        // --- Mróz Duszy: WIS/INT loss + movement + spell failure ---
        case CRS_CURSE_SOUL_FROST:
        {
            int nWis = (nStage == 1) ? 2 : (nStage == 2) ? 4 : 6;
            int nInt = (nStage >= 2) ? (nStage == 2 ? 2 : 4) : 0;
            int nMov = (nStage == 1) ? 10 : (nStage == 2) ? 20 : 30;
            CrsApplyEffect(oPC, EffectAbilityDecrease(ABILITY_WISDOM, nWis),      nCurseId);
            if(nInt > 0)
                CrsApplyEffect(oPC, EffectAbilityDecrease(ABILITY_INTELLIGENCE, nInt), nCurseId);
            CrsApplyEffect(oPC, EffectMovementSpeedDecrease(nMov),                nCurseId);
            if(nStage == 3)
                CrsApplyEffect(oPC, EffectSpellFailure(15, SPELL_SCHOOL_GENERAL), nCurseId);
            break;
        }
        // --- Pieczęć Krwi: CON + STR loss + attack (HP drain in CrsTick) ---
        case CRS_CURSE_BLOOD_SEAL:
        {
            int nCon = (nStage == 1) ? 2 : (nStage == 2) ? 4 : 6;
            int nStr = (nStage >= 2) ? (nStage == 2 ? 2 : 4) : 0;
            int nAtk = (nStage == 3) ? 2 : 0;
            CrsApplyEffect(oPC, EffectAbilityDecrease(ABILITY_CONSTITUTION, nCon), nCurseId);
            if(nStr > 0)
                CrsApplyEffect(oPC, EffectAbilityDecrease(ABILITY_STRENGTH, nStr),  nCurseId);
            if(nAtk > 0)
                CrsApplyEffect(oPC, EffectAttackDecrease(nAtk, ATTACK_BONUS_MISC),  nCurseId);
            break;
        }
    }
}

// Re-applies all effects for oPC from DB state.
// Removes existing ones first to prevent stacking on login.
void CrsApplyAllEffects(object oPC)
{
    json jAll  = CrsGetAllCurses(oPC);
    int  nCount = JsonGetLength(jAll);
    int i;
    for(i = 0; i < nCount; i++)
    {
        json jRow    = JsonArrayGet(jAll, i);
        int nCurseId = JsonGetInt(JsonObjectGet(jRow, "curse_id"));
        int nStage   = JsonGetInt(JsonObjectGet(jRow, "stage"));

        CrsRemoveEffects(oPC, nCurseId);
        CrsApplyEffects(oPC, nCurseId, nStage);
    }
}

// ----------------------------------------------------------------
// Inflict / cleanse
// ----------------------------------------------------------------

void CrsInflict(object oPC, int nCurseId)
{
    if(CrsHasCurse(oPC, nCurseId))
    {
        SendMessageToPC(oPC, "[Klątwa] Jesteś już dotknięty: " + CrsGetName(nCurseId) + ".");
        return;
    }

    CrsAddCurse(oPC, nCurseId);
    CrsRemoveEffects(oPC, nCurseId);
    CrsApplyEffects(oPC, nCurseId, 1);

    FloatingTextStringOnCreature("Klątwa: " + CrsGetName(nCurseId), oPC, FALSE);
    SendMessageToPC(oPC, "[Klątwa] Dosięgła cię: " + CrsGetName(nCurseId) + ". Szukaj świętego oleju, by ją zdjąć.");

    int nToken = NuiFindWindow(oPC, CRS_WINDOW);
    if(nToken != 0)
        CrsFeedList(oPC, nToken);
}

void CrsCleanse(object oPC, int nCurseId)
{
    json jCurse = CrsGetCurse(oPC, nCurseId);
    if(JsonGetType(jCurse) == JSON_TYPE_NULL)
    {
        SendMessageToPC(oPC, "[Klątwa] Nie masz tej klątwy.");
        return;
    }

    int nStage = JsonGetInt(JsonObjectGet(jCurse, "stage"));
    int nCost  = CrsGetCleanseCost(nCurseId, nStage);

    if(GetItemPossessedBy(oPC, CRS_ITEM_HOLY_OIL) == OBJECT_INVALID)
    {
        SendMessageToPC(oPC, "[Klątwa] Brakuje świętego oleju (crs_hol_oil).");
        return;
    }
    if(GetGold(oPC) < nCost)
    {
        SendMessageToPC(oPC, "[Klątwa] Brakuje złota. Potrzebujesz: " + IntToString(nCost) + " sztuk złota.");
        return;
    }

    // Consume one holy oil
    DestroyObject(GetItemPossessedBy(oPC, CRS_ITEM_HOLY_OIL));
    AssignCommand(oPC, TakeGoldFromCreature(nCost, oPC, TRUE));

    CrsRemoveEffects(oPC, nCurseId);
    CrsDeleteCurse(oPC, nCurseId);

    FloatingTextStringOnCreature("Klątwa zdjęta: " + CrsGetName(nCurseId), oPC, FALSE);
    SendMessageToPC(oPC, "[Klątwa] Klątwa " + CrsGetName(nCurseId) + " została zdjęta. Zapłacono " + IntToString(nCost) + " złota.");

    int nToken = NuiFindWindow(oPC, CRS_WINDOW);
    if(nToken != 0)
        CrsFeedList(oPC, nToken);
}

// ----------------------------------------------------------------
// Tick (called via DelayCommand chain started in sys_on_enter)
// ----------------------------------------------------------------

void CrsTick(object oPC)
{
    if(!GetIsObjectValid(oPC)) return;
    if(!GetIsPC(oPC))          return;

    json jAll   = CrsGetAllCurses(oPC);
    int  nCount = JsonGetLength(jAll);
    if(nCount == 0)
    {
        // No curses: reschedule anyway so we catch new inflictions
        DelayCommand(CRS_TICK_INTERVAL, CrsTick(oPC));
        return;
    }

    // HP drain for each curse that has it
    int i;
    for(i = 0; i < nCount; i++)
    {
        json jRow    = JsonArrayGet(jAll, i);
        int nCurseId = JsonGetInt(JsonObjectGet(jRow, "curse_id"));
        int nStage   = JsonGetInt(JsonObjectGet(jRow, "stage"));

        int nDrain = CrsGetDrainPerTick(nCurseId, nStage);
        if(nDrain > 0)
        {
            int nHP = GetCurrentHitPoints(oPC);
            if(nHP > 1)
            {
                int nActual = (nDrain >= nHP) ? (nHP - 1) : nDrain;
                ApplyEffectToObject(DURATION_TYPE_INSTANT,
                    EffectDamage(nActual, DAMAGE_TYPE_MAGICAL), oPC);
            }
        }
    }

    // Advance tick counters; get list of curses that progressed a stage
    json jProgressed = CrsTickAllCurses(oPC, CRS_TICKS_PER_STAGE);
    int nProgCount   = JsonGetLength(jProgressed);
    for(i = 0; i < nProgCount; i++)
    {
        json jP      = JsonArrayGet(jProgressed, i);
        int nCurseId = JsonGetInt(JsonObjectGet(jP, "curse_id"));
        int nNew     = JsonGetInt(JsonObjectGet(jP, "new_stage"));

        CrsRemoveEffects(oPC, nCurseId);
        CrsApplyEffects(oPC, nCurseId, nNew);

        string sMsg = "[Klątwa] " + CrsGetName(nCurseId)
                      + " wzmocniła się do stadium " + IntToString(nNew) + "!";
        FloatingTextStringOnCreature(sMsg, oPC, FALSE);
        SendMessageToPC(oPC, sMsg + " " + CrsGetDesc(nCurseId, nNew));
    }

    // Refresh window if open
    int nToken = NuiFindWindow(oPC, CRS_WINDOW);
    if(nToken != 0)
        CrsFeedList(oPC, nToken);

    DelayCommand(CRS_TICK_INTERVAL, CrsTick(oPC));
}

void CrsStartTicking(object oPC)
{
    if(GetLocalInt(oPC, CRS_LVAR_TICKING)) return;
    SetLocalInt(oPC, CRS_LVAR_TICKING, 1);
    DelayCommand(CRS_TICK_INTERVAL, CrsTick(oPC));
}

// ----------------------------------------------------------------
// NUI — window layout
// ----------------------------------------------------------------

json CrsBuildWindow(object oPC)
{
    float fBtnH  = GetNuiScaleDimension(oPC, 28.0);
    float fRowH  = GetNuiScaleDimension(oPC, 66.0);
    float fNameW = GetNuiScaleDimension(oPC, 180.0);
    float fDotW  = GetNuiScaleDimension(oPC, 56.0);
    float fBtnW  = GetNuiScaleDimension(oPC, 110.0);
    float fListH = GetNuiScaleDimension(oPC, 360.0);
    float fInfoH = GetNuiScaleDimension(oPC, 24.0);

    // --- List row template ---
    // Col: name + stage dots
    json jNameLbl = NuiLabel(NuiBind(CRS_BIND_NAME), JsonInt(NUI_HALIGN_LEFT), JsonInt(NUI_VALIGN_TOP));
    jNameLbl = NuiStyleForegroundColor(jNameLbl, NuiBind(CRS_BIND_COLOR));
    jNameLbl = NuiHeight(jNameLbl, GetNuiScaleDimension(oPC, 22.0));

    json jDotLbl = NuiLabel(NuiBind(CRS_BIND_STAGE_DOT), JsonInt(NUI_HALIGN_LEFT), JsonInt(NUI_VALIGN_TOP));
    jDotLbl = NuiStyleForegroundColor(jDotLbl, NuiBind(CRS_BIND_COLOR));
    jDotLbl = NuiHeight(jDotLbl, GetNuiScaleDimension(oPC, 22.0));
    jDotLbl = NuiWidth(jDotLbl,  fDotW);

    json jDescLbl = NuiLabel(NuiBind(CRS_BIND_DESC), JsonInt(NUI_HALIGN_LEFT), JsonInt(NUI_VALIGN_TOP));
    jDescLbl = NuiStyleForegroundColor(jDescLbl, NuiColor(200, 180, 150));
    jDescLbl = NuiHeight(jDescLbl, GetNuiScaleDimension(oPC, 40.0));

    json jLeftCol = JsonArray();
    jLeftCol = JsonArrayInsert(jLeftCol, NuiRow(JsonArrayInsert(JsonArrayInsert(JsonArray(), jNameLbl), jDotLbl)));
    jLeftCol = JsonArrayInsert(jLeftCol, jDescLbl);
    json jLeft = NuiCol(jLeftCol);

    // Cleanse button
    json jBtn = NuiButton(NuiBind(CRS_BIND_BTN_LBL));
    jBtn = NuiId(jBtn,      CRS_BTN_CLEANSE);
    jBtn = NuiEnabled(jBtn, NuiBind(CRS_BIND_BTN_ENA));
    jBtn = NuiWidth(jBtn,   fBtnW);
    jBtn = NuiHeight(jBtn,  GetNuiScaleDimension(oPC, 44.0));
    jBtn = NuiTooltip(jBtn, JsonString("Wymaga: Święty Olej + złoto"));

    json jRowArr = JsonArray();
    jRowArr = JsonArrayInsert(jRowArr, jLeft);
    jRowArr = JsonArrayInsert(jRowArr, jBtn);
    json jRowWidget = NuiGroup(NuiRow(jRowArr), FALSE, NUI_SCROLLBARS_NONE);

    json jTmpl = JsonArray();
    jTmpl = JsonArrayInsert(jTmpl, NuiListTemplateCell(jRowWidget, 0.0, TRUE));

    json jList = NuiList(jTmpl, NuiBind(CRS_BIND_ROWCOUNT), fRowH);
    jList = NuiHeight(jList, fListH);

    // Empty-state label (shown when no curses active)
    json jEmptyLbl = NuiLabel(
        JsonString("Nie masz aktywnych klątw."),
        JsonInt(NUI_HALIGN_CENTER), JsonInt(NUI_VALIGN_MIDDLE));
    jEmptyLbl = NuiVisible(jEmptyLbl, NuiBind(CRS_BIND_EMPTY_VIS));
    jEmptyLbl = NuiHeight(jEmptyLbl, GetNuiScaleDimension(oPC, 40.0));

    // Info bar at bottom
    json jInfoLbl = NuiLabel(NuiBind(CRS_BIND_INFO), JsonInt(NUI_HALIGN_LEFT), JsonInt(NUI_VALIGN_MIDDLE));
    jInfoLbl = NuiStyleForegroundColor(jInfoLbl, NuiColor(220, 190, 100));
    jInfoLbl = NuiHeight(jInfoLbl, fInfoH);

    // Close button
    json jClose = NuiButton(JsonString("Zamknij"));
    jClose = NuiId(jClose,    CRS_BTN_CLOSE);
    jClose = NuiWidth(jClose, GetNuiScaleDimension(oPC, 80.0));
    jClose = NuiHeight(jClose, fBtnH);

    json jBotRow = JsonArray();
    jBotRow = JsonArrayInsert(jBotRow, jInfoLbl);
    jBotRow = JsonArrayInsert(jBotRow, NuiSpacer());
    jBotRow = JsonArrayInsert(jBotRow, jClose);

    json jCol = JsonArray();
    jCol = JsonArrayInsert(jCol, jEmptyLbl);
    jCol = JsonArrayInsert(jCol, jList);
    jCol = JsonArrayInsert(jCol, CreateEmptyRow(oPC, 4.0));
    jCol = JsonArrayInsert(jCol, NuiRow(jBotRow));

    json jSide    = NuiCol(JsonArrayInsert(JsonArray(), NuiSpacer()));
    float fContW  = GetNuiScaleDimension(oPC, 558.0);
    json jMainRow = JsonArray();
    jMainRow = JsonArrayInsert(jMainRow, jSide);
    jMainRow = JsonArrayInsert(jMainRow, NuiWidth(NuiCol(jCol), fContW));
    jMainRow = JsonArrayInsert(jMainRow, jSide);

    return NuiRow(jMainRow);
}

// ----------------------------------------------------------------
// NUI — feed data
// ----------------------------------------------------------------

void CrsFeedList(object oPC, int nToken)
{
    json jAll   = CrsGetAllCurses(oPC);
    int  nCount = JsonGetLength(jAll);

    // Store row->curse_id map on PC for event handler lookup
    json jRowMap = JsonArray();

    json jNames  = JsonArray();
    json jDots   = JsonArray();
    json jDescs  = JsonArray();
    json jColors = JsonArray();
    json jBtnEna = JsonArray();
    json jBtnLbl = JsonArray();

    int bHasOil = (GetItemPossessedBy(oPC, CRS_ITEM_HOLY_OIL) != OBJECT_INVALID);
    int nGold   = GetGold(oPC);

    json jRed    = NuiColor(220,  60,  60);
    json jOrange = NuiColor(230, 130,  40);
    json jCrimson= NuiColor(160,  20,  20);

    int i;
    for(i = 0; i < nCount; i++)
    {
        json jRow    = JsonArrayGet(jAll, i);
        int nCurseId = JsonGetInt(JsonObjectGet(jRow, "curse_id"));
        int nStage   = JsonGetInt(JsonObjectGet(jRow, "stage"));

        string sDots;
        switch(nStage)
        {
            case 1:  sDots = "\xe2\x97\x8f\xe2\x97\x8b\xe2\x97\x8b"; break; // ●○○
            case 2:  sDots = "\xe2\x97\x8f\xe2\x97\x8f\xe2\x97\x8b"; break; // ●●○
            default: sDots = "\xe2\x97\x8f\xe2\x97\x8f\xe2\x97\x8f"; break; // ●●●
        }

        int nCost    = CrsGetCleanseCost(nCurseId, nStage);
        int bCanClns = bHasOil && (nGold >= nCost);

        json jColor;
        switch(nStage)
        {
            case 1:  jColor = jOrange;  break;
            case 2:  jColor = jRed;     break;
            default: jColor = jCrimson; break;
        }

        jRowMap  = JsonArrayInsert(jRowMap,  JsonInt(nCurseId));
        jNames   = JsonArrayInsert(jNames,   JsonString(CrsGetName(nCurseId)));
        jDots    = JsonArrayInsert(jDots,    JsonString(sDots));
        jDescs   = JsonArrayInsert(jDescs,   JsonString(CrsGetDesc(nCurseId, nStage)));
        jColors  = JsonArrayInsert(jColors,  jColor);
        jBtnEna  = JsonArrayInsert(jBtnEna,  JsonBool(bCanClns));
        jBtnLbl  = JsonArrayInsert(jBtnLbl,  JsonString("Zdjąć (" + IntToString(nCost) + "z)"));
    }

    SetLocalJson(oPC, CRS_LVAR_CURSE_ROW, jRowMap);

    NuiSetBind(oPC, nToken, CRS_BIND_ROWCOUNT,  JsonInt(nCount));
    NuiSetBind(oPC, nToken, CRS_BIND_NAME,       jNames);
    NuiSetBind(oPC, nToken, CRS_BIND_STAGE_DOT,  jDots);
    NuiSetBind(oPC, nToken, CRS_BIND_DESC,        jDescs);
    NuiSetBind(oPC, nToken, CRS_BIND_COLOR,       jColors);
    NuiSetBind(oPC, nToken, CRS_BIND_BTN_ENA,     jBtnEna);
    NuiSetBind(oPC, nToken, CRS_BIND_BTN_LBL,     jBtnLbl);
    NuiSetBind(oPC, nToken, CRS_BIND_EMPTY_VIS,   JsonBool(nCount == 0));

    string sOilInfo = bHasOil ? "Masz Święty Olej." : "Brak Świętego Oleju — nie możesz zdjąć klątwy.";
    NuiSetBind(oPC, nToken, CRS_BIND_INFO, JsonString(sOilInfo));
}

// ----------------------------------------------------------------
// NUI — open window
// ----------------------------------------------------------------

void CrsOpenWindow(object oPC)
{
    int nToken = NuiFindWindow(oPC, CRS_WINDOW);
    if(nToken != 0)
    {
        CrsFeedList(oPC, nToken);
        return;
    }

    float fCX = (IntToFloat(GetPlayerDeviceProperty(oPC, PLAYER_DEVICE_PROPERTY_GUI_WIDTH))
                 - GetNuiScaleDimension(oPC, CRS_W)) / 2.0;
    float fCY = (IntToFloat(GetPlayerDeviceProperty(oPC, PLAYER_DEVICE_PROPERTY_GUI_HEIGHT))
                 - GetNuiScaleDimension(oPC, CRS_H)) / 2.0;
    json jGeom = NuiRect(fCX, fCY,
                         GetNuiScaleDimension(oPC, CRS_W),
                         GetNuiScaleDimension(oPC, CRS_H));

    json jWin = NuiWindow(
        CrsBuildWindow(oPC),
        JsonString("Klątwy"),
        NuiBind(CRS_WIN_GEOM),
        JsonBool(FALSE),
        JsonBool(FALSE),
        JsonBool(FALSE),
        JsonBool(TRUE),
        JsonBool(FALSE));

    nToken = NuiCreate(oPC, jWin, CRS_WINDOW, CRS_EV_SCRIPT);
    NuiSetBind(oPC, nToken, CRS_WIN_GEOM, jGeom);
    CrsFeedList(oPC, nToken);
}
