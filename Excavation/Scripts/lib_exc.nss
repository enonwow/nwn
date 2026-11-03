#include "lib_exc_def"

// ----------------------------------------------------------------
// Relic effect management
// ----------------------------------------------------------------

void ExcApplyRelicEffects(object oPC)
{
    // Strip all existing relic bonuses before re-applying
    effect eEff = GetFirstEffect(oPC);
    while(GetIsEffectValid(eEff))
    {
        if(GetEffectTag(eEff) == EXC_EFFECT_TAG)
            RemoveEffect(oPC, eEff);
        eEff = GetNextEffect(oPC);
    }

    int nEra;
    for(nEra = 0; nEra < EXC_ERA_COUNT; nEra++)
    {
        int nRelics = ExcGetRelics(oPC, nEra);
        if(nRelics <= 0) continue;
        int nAbility = ExcEraAbility(nEra);
        if(nAbility < 0) continue;

        effect eBonus = EffectAbilityIncrease(nAbility, nRelics);
        eBonus = TagEffect(eBonus, EXC_EFFECT_TAG);
        ApplyEffectToObject(DURATION_TYPE_PERMANENT, eBonus, oPC);
    }
}

// ----------------------------------------------------------------
// NUI — Dig View layout
// ----------------------------------------------------------------

json BuildExcDigView(object oPC)
{
    float fBtnH  = GetNuiScaleDimension(oPC, 30.0);
    float fBarH  = GetNuiScaleDimension(oPC, 22.0);
    float fLblH  = GetNuiScaleDimension(oPC, 22.0);
    float fBigBH = GetNuiScaleDimension(oPC, 42.0);
    float fBigBW = GetNuiScaleDimension(oPC, 170.0);
    float fEraW  = GetNuiScaleDimension(oPC, 160.0);

    // Header: site name (left) + era (right)
    json jSiteName = NuiLabel(NuiBind(EXC_BIND_SITE_NAME), JsonInt(NUI_HALIGN_LEFT), JsonInt(NUI_VALIGN_MIDDLE));
    jSiteName = NuiHeight(jSiteName, fLblH);

    json jSiteEra = NuiLabel(NuiBind(EXC_BIND_SITE_ERA_LBL), JsonInt(NUI_HALIGN_RIGHT), JsonInt(NUI_VALIGN_MIDDLE));
    jSiteEra = NuiWidth(jSiteEra, fEraW);
    jSiteEra = NuiHeight(jSiteEra, fLblH);

    json jHeaderRow = JsonArray();
    jHeaderRow = JsonArrayInsert(jHeaderRow, jSiteName);
    jHeaderRow = JsonArrayInsert(jHeaderRow, jSiteEra);

    // Progress bar
    json jBar = NuiProgress(NuiBind(EXC_BIND_PROGRESS));
    jBar = NuiHeight(jBar, fBarH);

    // Progress percentage label
    json jProgLbl = NuiLabel(NuiBind(EXC_BIND_PROGRESS_LBL), JsonInt(NUI_HALIGN_CENTER), JsonInt(NUI_VALIGN_MIDDLE));
    jProgLbl = NuiHeight(jProgLbl, fLblH);

    // Tries remaining
    json jTriesLbl = NuiLabel(NuiBind(EXC_BIND_TRIES_LBL), JsonInt(NUI_HALIGN_LEFT), JsonInt(NUI_VALIGN_MIDDLE));
    jTriesLbl = NuiHeight(jTriesLbl, fLblH);

    // Result / event message (taller so text doesn't get clipped)
    json jResultLbl = NuiLabel(NuiBind(EXC_BIND_RESULT_LBL), JsonInt(NUI_HALIGN_CENTER), JsonInt(NUI_VALIGN_MIDDLE));
    jResultLbl = NuiHeight(jResultLbl, GetNuiScaleDimension(oPC, 48.0));

    // Dig button (centred)
    json jDigBtn = NuiButton(JsonString("Kopać"));
    jDigBtn = NuiId(jDigBtn, EXC_BTN_DIG);
    jDigBtn = NuiEnabled(jDigBtn, NuiBind(EXC_BIND_DIG_ENA));
    jDigBtn = NuiWidth(jDigBtn, fBigBW);
    jDigBtn = NuiHeight(jDigBtn, fBigBH);

    json jDigRow = JsonArray();
    jDigRow = JsonArrayInsert(jDigRow, NuiSpacer());
    jDigRow = JsonArrayInsert(jDigRow, jDigBtn);
    jDigRow = JsonArrayInsert(jDigRow, NuiSpacer());

    // HP cost note
    json jHpLbl = NuiLabel(NuiBind(EXC_BIND_HP_COST_LBL), JsonInt(NUI_HALIGN_CENTER), JsonInt(NUI_VALIGN_MIDDLE));
    jHpLbl = NuiHeight(jHpLbl, fLblH);

    json jCol = JsonArray();
    jCol = JsonArrayInsert(jCol, CreateEmptyRow(oPC, 10.0));
    jCol = JsonArrayInsert(jCol, NuiRow(jHeaderRow));
    jCol = JsonArrayInsert(jCol, CreateEmptyRow(oPC, 20.0));
    jCol = JsonArrayInsert(jCol, jBar);
    jCol = JsonArrayInsert(jCol, jProgLbl);
    jCol = JsonArrayInsert(jCol, CreateEmptyRow(oPC, 12.0));
    jCol = JsonArrayInsert(jCol, jTriesLbl);
    jCol = JsonArrayInsert(jCol, CreateEmptyRow(oPC, 6.0));
    jCol = JsonArrayInsert(jCol, jResultLbl);
    jCol = JsonArrayInsert(jCol, NuiSpacer());
    jCol = JsonArrayInsert(jCol, NuiRow(jDigRow));
    jCol = JsonArrayInsert(jCol, CreateEmptyRow(oPC, 8.0));
    jCol = JsonArrayInsert(jCol, jHpLbl);
    jCol = JsonArrayInsert(jCol, CreateEmptyRow(oPC, 6.0));

    json jSide = NuiCol(JsonArrayInsert(JsonArray(), NuiSpacer()));
    float fContentW = GetNuiScaleDimension(oPC, 480.0);
    json jMainRow = JsonArray();
    jMainRow = JsonArrayInsert(jMainRow, jSide);
    jMainRow = JsonArrayInsert(jMainRow, NuiWidth(NuiCol(jCol), fContentW));
    jMainRow = JsonArrayInsert(jMainRow, jSide);
    return NuiRow(jMainRow);
}

// ----------------------------------------------------------------
// NUI — Codex View layout
// ----------------------------------------------------------------

json BuildExcCodexView(object oPC)
{
    float fRowH   = GetNuiScaleDimension(oPC, 34.0);
    float fListH  = GetNuiScaleDimension(oPC, 145.0);
    float fBtnH   = GetNuiScaleDimension(oPC, 28.0);
    float fBtnW   = GetNuiScaleDimension(oPC, 72.0);
    float fEraW   = GetNuiScaleDimension(oPC, 145.0);
    float fCntW   = GetNuiScaleDimension(oPC, 65.0);
    float fRelW   = GetNuiScaleDimension(oPC, 65.0);
    float fBonusW = GetNuiScaleDimension(oPC, 60.0);

    json jEraNameLbl = NuiLabel(NuiBind(EXC_BIND_ERA_NAMES),  JsonInt(NUI_HALIGN_LEFT),   JsonInt(NUI_VALIGN_MIDDLE));
    jEraNameLbl = NuiWidth(jEraNameLbl, fEraW);

    json jShardsLbl  = NuiLabel(NuiBind(EXC_BIND_ERA_SHARDS), JsonInt(NUI_HALIGN_CENTER), JsonInt(NUI_VALIGN_MIDDLE));
    jShardsLbl = NuiWidth(jShardsLbl, fCntW);

    json jRelicsLbl  = NuiLabel(NuiBind(EXC_BIND_ERA_RELICS), JsonInt(NUI_HALIGN_CENTER), JsonInt(NUI_VALIGN_MIDDLE));
    jRelicsLbl = NuiWidth(jRelicsLbl, fRelW);

    json jBonusLbl   = NuiLabel(NuiBind(EXC_BIND_ERA_BONUS),  JsonInt(NUI_HALIGN_CENTER), JsonInt(NUI_VALIGN_MIDDLE));
    jBonusLbl = NuiWidth(jBonusLbl, fBonusW);

    json jAssBtn     = NuiButton(JsonString("Złóż"));
    jAssBtn = NuiId(jAssBtn, EXC_BTN_ASSEMBLE);
    jAssBtn = NuiEnabled(jAssBtn, NuiBind(EXC_BIND_ASSEMBLE_ENA));
    jAssBtn = NuiWidth(jAssBtn, fBtnW);
    jAssBtn = NuiHeight(jAssBtn, fBtnH);

    json jCellRow = JsonArray();
    jCellRow = JsonArrayInsert(jCellRow, jEraNameLbl);
    jCellRow = JsonArrayInsert(jCellRow, jShardsLbl);
    jCellRow = JsonArrayInsert(jCellRow, jRelicsLbl);
    jCellRow = JsonArrayInsert(jCellRow, jBonusLbl);
    jCellRow = JsonArrayInsert(jCellRow, jAssBtn);

    json jCell = NuiGroup(NuiRow(jCellRow), TRUE, NUI_SCROLLBARS_NONE);
    jCell = NuiId(jCell, EXC_BTN_ERA_ROW);
    jCell = NuiEncouraged(jCell, NuiBind(EXC_BIND_ERA_ENC));

    json jTmpl = JsonArrayInsert(JsonArray(), NuiListTemplateCell(jCell, 0.0, TRUE));
    json jList = NuiList(jTmpl, JsonInt(EXC_ERA_COUNT), fRowH);
    jList = NuiHeight(jList, fListH);

    // Column header row
    json jHdrEra   = NuiLabel(JsonString("Era"),       JsonInt(NUI_HALIGN_LEFT),   JsonInt(NUI_VALIGN_MIDDLE));
    jHdrEra = NuiWidth(jHdrEra, fEraW);
    json jHdrSh    = NuiLabel(JsonString("Odłamki"),   JsonInt(NUI_HALIGN_CENTER), JsonInt(NUI_VALIGN_MIDDLE));
    jHdrSh = NuiWidth(jHdrSh, fCntW);
    json jHdrRel   = NuiLabel(JsonString("Relikwie"),  JsonInt(NUI_HALIGN_CENTER), JsonInt(NUI_VALIGN_MIDDLE));
    jHdrRel = NuiWidth(jHdrRel, fRelW);
    json jHdrBonus = NuiLabel(JsonString("Bonus"),     JsonInt(NUI_HALIGN_CENTER), JsonInt(NUI_VALIGN_MIDDLE));
    jHdrBonus = NuiWidth(jHdrBonus, fBonusW);
    json jHdrAct   = NuiLabel(JsonString(""),          JsonInt(NUI_HALIGN_CENTER), JsonInt(NUI_VALIGN_MIDDLE));
    jHdrAct = NuiWidth(jHdrAct, fBtnW);

    json jHdrRow = JsonArray();
    jHdrRow = JsonArrayInsert(jHdrRow, jHdrEra);
    jHdrRow = JsonArrayInsert(jHdrRow, jHdrSh);
    jHdrRow = JsonArrayInsert(jHdrRow, jHdrRel);
    jHdrRow = JsonArrayInsert(jHdrRow, jHdrBonus);
    jHdrRow = JsonArrayInsert(jHdrRow, jHdrAct);

    // Status
    json jStatusLbl = NuiLabel(NuiBind(EXC_BIND_CODEX_STATUS), JsonInt(NUI_HALIGN_CENTER), JsonInt(NUI_VALIGN_MIDDLE));
    jStatusLbl = NuiHeight(jStatusLbl, GetNuiScaleDimension(oPC, 42.0));

    json jLegend = NuiLabel(
        JsonString("Złóż 3 odłamki jednej ery, by stworzyć Relikwię (max 3 na erę)."),
        JsonInt(NUI_HALIGN_CENTER), JsonInt(NUI_VALIGN_MIDDLE));
    jLegend = NuiHeight(jLegend, GetNuiScaleDimension(oPC, 22.0));

    json jCol = JsonArray();
    jCol = JsonArrayInsert(jCol, CreateEmptyRow(oPC, 8.0));
    jCol = JsonArrayInsert(jCol, NuiRow(jHdrRow));
    jCol = JsonArrayInsert(jCol, jList);
    jCol = JsonArrayInsert(jCol, jStatusLbl);
    jCol = JsonArrayInsert(jCol, NuiSpacer());
    jCol = JsonArrayInsert(jCol, jLegend);
    jCol = JsonArrayInsert(jCol, CreateEmptyRow(oPC, 6.0));

    json jSide = NuiCol(JsonArrayInsert(JsonArray(), NuiSpacer()));
    float fContentW = GetNuiScaleDimension(oPC, 480.0);
    json jMainRow = JsonArray();
    jMainRow = JsonArrayInsert(jMainRow, jSide);
    jMainRow = JsonArrayInsert(jMainRow, NuiWidth(NuiCol(jCol), fContentW));
    jMainRow = JsonArrayInsert(jMainRow, jSide);
    return NuiRow(jMainRow);
}

// ----------------------------------------------------------------
// Window creation / swap
// ----------------------------------------------------------------

void ExcOpen(object oPC, object oSite)
{
    string sSiteTag = GetTag(oSite);
    int    nEra     = GetLocalInt(oSite, "EXC_ERA");

    ExcInitSite(oPC, sSiteTag, nEra);
    SetLocalString(oPC, EXC_LVAR_SITE_TAG, sSiteTag);
    SetLocalInt   (oPC, EXC_LVAR_VIEW,     EXC_VIEW_DIG);

    int nToken = NuiFindWindow(oPC, EXC_WINDOW);
    if(nToken != 0)
    {
        NuiSetGroupLayout(oPC, nToken, EXC_GRP_SWAP, BuildExcDigView(oPC));
        ExcFeedDigView(oPC, nToken);
        return;
    }

    float fCX = (IntToFloat(GetPlayerDeviceProperty(oPC, PLAYER_DEVICE_PROPERTY_GUI_WIDTH))  - GetNuiScaleDimension(oPC, EXC_W)) / 2.0;
    float fCY = (IntToFloat(GetPlayerDeviceProperty(oPC, PLAYER_DEVICE_PROPERTY_GUI_HEIGHT)) - GetNuiScaleDimension(oPC, EXC_H)) / 2.0;
    json jGeom = NuiRect(fCX, fCY, GetNuiScaleDimension(oPC, EXC_W), GetNuiScaleDimension(oPC, EXC_H));

    float fBtnH = GetNuiScaleDimension(oPC, 28.0);

    json jTitle = NuiLabel(JsonString("Wykopaliska"), JsonInt(NUI_HALIGN_LEFT), JsonInt(NUI_VALIGN_MIDDLE));

    json jTabDig = NuiButton(JsonString("Wykopalisko"));
    jTabDig = NuiId(jTabDig, EXC_BTN_TAB_DIG);
    jTabDig = NuiWidth(jTabDig, GetNuiScaleDimension(oPC, 105.0));
    jTabDig = NuiHeight(jTabDig, fBtnH);

    json jTabCod = NuiButton(JsonString("Kodeks"));
    jTabCod = NuiId(jTabCod, EXC_BTN_TAB_COD);
    jTabCod = NuiWidth(jTabCod, GetNuiScaleDimension(oPC, 80.0));
    jTabCod = NuiHeight(jTabCod, fBtnH);

    json jCloseBtn = NuiButton(JsonString("X"));
    jCloseBtn = NuiId(jCloseBtn, EXC_BTN_CLOSE);
    jCloseBtn = NuiWidth(jCloseBtn, GetNuiScaleDimension(oPC, 30.0));
    jCloseBtn = NuiHeight(jCloseBtn, fBtnH);

    json jTopBar = JsonArray();
    jTopBar = JsonArrayInsert(jTopBar, jTitle);
    jTopBar = JsonArrayInsert(jTopBar, NuiSpacer());
    jTopBar = JsonArrayInsert(jTopBar, jTabDig);
    jTopBar = JsonArrayInsert(jTopBar, jTabCod);
    jTopBar = JsonArrayInsert(jTopBar, jCloseBtn);

    json jSwapGrp = NuiGroup(BuildExcDigView(oPC), FALSE, NUI_SCROLLBARS_NONE);
    jSwapGrp = NuiId(jSwapGrp, EXC_GRP_SWAP);

    json jRootChildren = JsonArray();
    jRootChildren = JsonArrayInsert(jRootChildren, NuiRow(jTopBar));
    jRootChildren = JsonArrayInsert(jRootChildren, jSwapGrp);

    json jRoot = NuiCol(jRootChildren);
    json jWin  = NuiWindow(jRoot,
        JsonBool(FALSE),
        NuiBind(EXC_BIND_WIN_GEOM),
        JsonBool(FALSE),
        JsonBool(FALSE),
        JsonBool(FALSE),
        JsonBool(TRUE),
        JsonBool(FALSE));

    nToken = NuiCreate(oPC, jWin, EXC_WINDOW, EXC_EV_SCRIPT);
    NuiSetBind(oPC, nToken, EXC_BIND_WIN_GEOM, jGeom);
    ExcFeedDigView(oPC, nToken);
}

// ----------------------------------------------------------------
// Feed — Dig View
// ----------------------------------------------------------------

void ExcFeedDigView(object oPC, int nToken)
{
    string sSiteTag = GetLocalString(oPC, EXC_LVAR_SITE_TAG);
    int nEra, nRemaining, nProgress;
    ExcGetSiteData(oPC, sSiteTag, nEra, nRemaining, nProgress);

    object oSite = GetObjectByTag(sSiteTag);
    string sSiteName = GetIsObjectValid(oSite) ? GetName(oSite) : sSiteTag;

    int nMaxHP  = GetMaxHitPoints(oPC);
    int nHPCost = nMaxHP * EXC_DIG_HP_COST_PCT / 100;
    if(nHPCost < 1) nHPCost = 1;

    int bExhausted = (nRemaining <= 0);
    int bEnoughHP  = (GetCurrentHitPoints(oPC) > nHPCost);

    string sTriesLbl;
    string sResultLbl;

    if(bExhausted)
    {
        sTriesLbl  = "Stanowisko wyczerpane — ziemia nie kryje już tajemnic.";
        sResultLbl = "";
    }
    else
    {
        sTriesLbl  = "Pozostałe próby: " + IntToString(nRemaining) + " / " + IntToString(EXC_SITE_MAX_TRIES);
        sResultLbl = !bEnoughHP ? "Za mało punktów życia, by kopać." : "";
    }

    float fProgress = IntToFloat(nProgress) / 100.0;

    NuiSetBind(oPC, nToken, EXC_BIND_SITE_NAME,    JsonString(sSiteName));
    NuiSetBind(oPC, nToken, EXC_BIND_SITE_ERA_LBL, JsonString(ExcEraName(nEra)));
    NuiSetBind(oPC, nToken, EXC_BIND_PROGRESS,     JsonFloat(fProgress));
    NuiSetBind(oPC, nToken, EXC_BIND_PROGRESS_LBL, JsonString(IntToString(nProgress) + "%"));
    NuiSetBind(oPC, nToken, EXC_BIND_TRIES_LBL,    JsonString(sTriesLbl));
    NuiSetBind(oPC, nToken, EXC_BIND_RESULT_LBL,   JsonString(sResultLbl));
    NuiSetBind(oPC, nToken, EXC_BIND_DIG_ENA,      JsonBool(!bExhausted && bEnoughHP));
    NuiSetBind(oPC, nToken, EXC_BIND_HP_COST_LBL,  JsonString("Koszt: " + IntToString(nHPCost) + " PŻ za próbę"));
}

// ----------------------------------------------------------------
// Feed — Codex View
// ----------------------------------------------------------------

void ExcFeedCodexView(object oPC, int nToken)
{
    json jNames    = JsonArray();
    json jShards   = JsonArray();
    json jRelics   = JsonArray();
    json jBonuses  = JsonArray();
    json jAssemble = JsonArray();
    json jEncs     = JsonArray();

    int nEra;
    for(nEra = 0; nEra < EXC_ERA_COUNT; nEra++)
    {
        int nShards = ExcGetShards(oPC, nEra);
        int nRels   = ExcGetRelics(oPC, nEra);
        int bCanAss = (nShards >= EXC_SHARDS_PER_RELIC) && (nRels < EXC_MAX_RELICS_PER_ERA);

        jNames    = JsonArrayInsert(jNames,    JsonString(ExcEraName(nEra)));
        jShards   = JsonArrayInsert(jShards,   JsonString(IntToString(nShards) + "/" + IntToString(EXC_SHARDS_PER_RELIC)));
        jRelics   = JsonArrayInsert(jRelics,   JsonString(IntToString(nRels) + "/" + IntToString(EXC_MAX_RELICS_PER_ERA)));
        jBonuses  = JsonArrayInsert(jBonuses,  JsonString(ExcEraBonus(nEra, nRels)));
        jAssemble = JsonArrayInsert(jAssemble, JsonBool(bCanAss));
        jEncs     = JsonArrayInsert(jEncs,     JsonBool(FALSE));
    }

    NuiSetBind(oPC, nToken, EXC_BIND_ERA_NAMES,    jNames);
    NuiSetBind(oPC, nToken, EXC_BIND_ERA_SHARDS,   jShards);
    NuiSetBind(oPC, nToken, EXC_BIND_ERA_RELICS,   jRelics);
    NuiSetBind(oPC, nToken, EXC_BIND_ERA_BONUS,    jBonuses);
    NuiSetBind(oPC, nToken, EXC_BIND_ASSEMBLE_ENA, jAssemble);
    NuiSetBind(oPC, nToken, EXC_BIND_ERA_ENC,      jEncs);
    NuiSetBind(oPC, nToken, EXC_BIND_CODEX_STATUS, JsonString(""));
}

// ----------------------------------------------------------------
// Gameplay — dig attempt
// ----------------------------------------------------------------

void ExcDoDigAttempt(object oPC, int nToken)
{
    string sSiteTag = GetLocalString(oPC, EXC_LVAR_SITE_TAG);
    int nEra, nRemaining, nProgress;
    if(!ExcGetSiteData(oPC, sSiteTag, nEra, nRemaining, nProgress)) return;

    if(nRemaining <= 0)
    {
        SendMessageToPC(oPC, "[Wykopaliska] To stanowisko jest całkowicie wyczerpane.");
        NuiSetBind(oPC, nToken, EXC_BIND_DIG_ENA, JsonBool(FALSE));
        return;
    }

    int nMaxHP  = GetMaxHitPoints(oPC);
    int nHPCost = nMaxHP * EXC_DIG_HP_COST_PCT / 100;
    if(nHPCost < 1) nHPCost = 1;

    if(GetCurrentHitPoints(oPC) <= nHPCost)
    {
        SendMessageToPC(oPC, "[Wykopaliska] Za mało punktów życia — ziemia pochłania cię, nie odwrotnie.");
        NuiSetBind(oPC, nToken, EXC_BIND_DIG_ENA, JsonBool(FALSE));
        NuiSetBind(oPC, nToken, EXC_BIND_RESULT_LBL, JsonString("Za mało punktów życia, by kopać."));
        return;
    }

    // Pay HP
    ApplyEffectToObject(DURATION_TYPE_INSTANT, EffectDamage(nHPCost, DAMAGE_TYPE_PHYSICAL), oPC);

    // Advance progress
    int nRoll   = Random(EXC_PROGRESS_MAX - EXC_PROGRESS_MIN + 1) + EXC_PROGRESS_MIN;
    nProgress  += nRoll;

    string sResult;
    int bFoundShard = (nProgress >= 100);

    if(bFoundShard)
    {
        nProgress  = 0;
        nRemaining = nRemaining - 1;

        int nNewShards = ExcGetShards(oPC, nEra) + 1;
        ExcSetShards(oPC, nEra, nNewShards);

        sResult = "Odłamek z epoki " + ExcEraName(nEra) + " wyłania się z ziemi... (łącznie: " + IntToString(nNewShards) + ")";
        FloatingTextStringOnCreature("Znaleziono odłamek!", oPC, FALSE);
        PlaySound("gui_picklocked");
    }
    else
    {
        sResult = "Ziemia opiera się twoim wysiłkom. (" + IntToString(nProgress) + "% odkopane)";
    }

    ExcUpdateSite(oPC, sSiteTag, nRemaining, nProgress);

    int bExhausted = (nRemaining <= 0);
    int bEnoughHP  = (GetCurrentHitPoints(oPC) > nHPCost);
    int bCanDig    = !bExhausted && bEnoughHP;

    float fProg = IntToFloat(nProgress) / 100.0;
    NuiSetBind(oPC, nToken, EXC_BIND_PROGRESS,     JsonFloat(fProg));
    NuiSetBind(oPC, nToken, EXC_BIND_PROGRESS_LBL, JsonString(IntToString(nProgress) + "%"));
    NuiSetBind(oPC, nToken, EXC_BIND_RESULT_LBL,   JsonString(sResult));
    NuiSetBind(oPC, nToken, EXC_BIND_DIG_ENA,      JsonBool(bCanDig));

    if(bExhausted)
        NuiSetBind(oPC, nToken, EXC_BIND_TRIES_LBL, JsonString("Stanowisko wyczerpane — ziemia nie kryje już tajemnic."));
    else
        NuiSetBind(oPC, nToken, EXC_BIND_TRIES_LBL, JsonString("Pozostałe próby: " + IntToString(nRemaining) + " / " + IntToString(EXC_SITE_MAX_TRIES)));
}

// ----------------------------------------------------------------
// Gameplay — assemble relic
// ----------------------------------------------------------------

void ExcDoAssemble(object oPC, int nToken, int nEra)
{
    if(nEra < 0 || nEra >= EXC_ERA_COUNT) return;

    int nShards = ExcGetShards(oPC, nEra);
    int nRels   = ExcGetRelics(oPC, nEra);

    if(nShards < EXC_SHARDS_PER_RELIC)
    {
        NuiSetBind(oPC, nToken, EXC_BIND_CODEX_STATUS,
            JsonString("Za mało odłamków. Potrzebujesz " + IntToString(EXC_SHARDS_PER_RELIC) + " z epoki " + ExcEraName(nEra) + "."));
        return;
    }
    if(nRels >= EXC_MAX_RELICS_PER_ERA)
    {
        NuiSetBind(oPC, nToken, EXC_BIND_CODEX_STATUS,
            JsonString("Osiągnięto maksymalną moc tej relikwii. Dalsze złożenie nic nie da."));
        return;
    }

    int nNewRels = nRels + 1;
    ExcSetShards(oPC, nEra, nShards - EXC_SHARDS_PER_RELIC);
    ExcSetRelics(oPC, nEra, nNewRels);
    ExcApplyRelicEffects(oPC);

    string sMsg = ExcRelicName(nEra) + " skompletowana. Bonus: " + ExcEraBonus(nEra, nNewRels) + " — aktywne.";
    NuiSetBind(oPC, nToken, EXC_BIND_CODEX_STATUS, JsonString(sMsg));
    FloatingTextStringOnCreature("Relikwia skompletowana!", oPC, FALSE);
    PlaySound("gui_levelup");

    ExcFeedCodexView(oPC, nToken);
}
