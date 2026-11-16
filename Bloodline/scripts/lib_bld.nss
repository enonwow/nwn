#include "lib_bld_def"

// ----------------------------------------------------------------
// Effect management
// ----------------------------------------------------------------

void BldRemoveEffects(object oPC)
{
    RemoveEffectByTag(oPC, "BLD_EFFECT");
}

void BldApplyEffects(object oPC)
{
    int nType   = BldGetBloodlineType(oPC);
    int nPurity = BldGetPurity(oPC);
    int nTier   = BldGetCurrentTier(nPurity);

    BldRemoveEffects(oPC);

    if(nType < 0 || nTier == BLD_TIER_DORMANT) return;

    int nSTR     = 0;
    int nCON     = 0;
    int nDEX     = 0;
    int nINT     = 0;
    int nWIS     = 0;
    int nCHA     = 0;
    int nAC      = 0;
    int nAB      = 0;
    int nSave    = 0;
    int nFireRes = 0;
    int nAcidRes = 0;
    int nRegen   = 0;
    int bFearImm = FALSE;

    if(nTier >= BLD_TIER_STIRRING)
    {
        switch(nType)
        {
            case 0: nSTR += 2; nCON += 1; break;
            case 1: nDEX += 2; nINT += 1; break;
            case 2: nCON += 2; nSTR += 1; break;
            case 3: nCHA += 2; nFireRes += 5; break;
            case 4: nWIS += 2; nCHA += 1; break;
            case 5: nSTR += 2; nAcidRes += 5; break;
        }
    }

    if(nTier >= BLD_TIER_AWAKENED)
    {
        switch(nType)
        {
            case 0: bFearImm = TRUE; break;
            case 1: nSave += 2; break;
            case 2: nAC   += 2; break;
            case 3: nFireRes += 5; nRegen += 1; break;
            case 4: nSave += 2; break;
            case 5: nAcidRes += 5; nAC += 2; break;
        }
    }

    if(nTier >= BLD_TIER_ASCENDANT)
    {
        switch(nType)
        {
            case 0: nSTR += 2; nCON += 1; nAB += 2; break;
            case 1: nDEX += 2; nINT += 1; nSave += 1; nAC += 2; break;
            case 2: nCON += 2; nSTR += 1; nAC   += 2; break;
            case 3: nCHA += 2; nFireRes += 15; nRegen += 1; nSTR += 2; break;
            case 4: nWIS += 2; nCHA += 1; nSave += 2; nRegen += 1; break;
            case 5: nSTR += 2; nAcidRes += 15; nAC += 2; bFearImm = TRUE; break;
        }
    }

    if(nSTR > 0)
    {
        effect e = SupernaturalEffect(TagEffect(EffectAbilityIncrease(ABILITY_STRENGTH, nSTR), "BLD_EFFECT"));
        ApplyEffectToObject(DURATION_TYPE_PERMANENT, e, oPC);
    }
    if(nCON > 0)
    {
        effect e = SupernaturalEffect(TagEffect(EffectAbilityIncrease(ABILITY_CONSTITUTION, nCON), "BLD_EFFECT"));
        ApplyEffectToObject(DURATION_TYPE_PERMANENT, e, oPC);
    }
    if(nDEX > 0)
    {
        effect e = SupernaturalEffect(TagEffect(EffectAbilityIncrease(ABILITY_DEXTERITY, nDEX), "BLD_EFFECT"));
        ApplyEffectToObject(DURATION_TYPE_PERMANENT, e, oPC);
    }
    if(nINT > 0)
    {
        effect e = SupernaturalEffect(TagEffect(EffectAbilityIncrease(ABILITY_INTELLIGENCE, nINT), "BLD_EFFECT"));
        ApplyEffectToObject(DURATION_TYPE_PERMANENT, e, oPC);
    }
    if(nWIS > 0)
    {
        effect e = SupernaturalEffect(TagEffect(EffectAbilityIncrease(ABILITY_WISDOM, nWIS), "BLD_EFFECT"));
        ApplyEffectToObject(DURATION_TYPE_PERMANENT, e, oPC);
    }
    if(nCHA > 0)
    {
        effect e = SupernaturalEffect(TagEffect(EffectAbilityIncrease(ABILITY_CHARISMA, nCHA), "BLD_EFFECT"));
        ApplyEffectToObject(DURATION_TYPE_PERMANENT, e, oPC);
    }
    if(nAC > 0)
    {
        effect e = SupernaturalEffect(TagEffect(EffectACIncrease(nAC, AC_NATURAL_BONUS, AC_VS_DAMAGE_TYPE_ALL), "BLD_EFFECT"));
        ApplyEffectToObject(DURATION_TYPE_PERMANENT, e, oPC);
    }
    if(nAB > 0)
    {
        effect e = SupernaturalEffect(TagEffect(EffectAttackIncrease(nAB, ATTACK_BONUS_MISC), "BLD_EFFECT"));
        ApplyEffectToObject(DURATION_TYPE_PERMANENT, e, oPC);
    }
    if(nSave > 0)
    {
        effect e = SupernaturalEffect(TagEffect(EffectSavingThrowIncrease(SAVING_THROW_ALL, nSave, SAVING_THROW_TYPE_ALL), "BLD_EFFECT"));
        ApplyEffectToObject(DURATION_TYPE_PERMANENT, e, oPC);
    }
    if(nFireRes > 0)
    {
        effect e = SupernaturalEffect(TagEffect(EffectDamageImmunityIncrease(DAMAGE_TYPE_FIRE, nFireRes), "BLD_EFFECT"));
        ApplyEffectToObject(DURATION_TYPE_PERMANENT, e, oPC);
    }
    if(nAcidRes > 0)
    {
        effect e = SupernaturalEffect(TagEffect(EffectDamageImmunityIncrease(DAMAGE_TYPE_ACID, nAcidRes), "BLD_EFFECT"));
        ApplyEffectToObject(DURATION_TYPE_PERMANENT, e, oPC);
    }
    if(nRegen > 0)
    {
        effect e = SupernaturalEffect(TagEffect(EffectRegenerate(nRegen, 6.0), "BLD_EFFECT"));
        ApplyEffectToObject(DURATION_TYPE_PERMANENT, e, oPC);
    }
    if(bFearImm)
    {
        effect e = SupernaturalEffect(TagEffect(EffectImmunity(IMMUNITY_TYPE_FEAR), "BLD_EFFECT"));
        ApplyEffectToObject(DURATION_TYPE_PERMANENT, e, oPC);
    }
}

// ----------------------------------------------------------------
// Choose view
// ----------------------------------------------------------------

json BldBuildChooseView(object oPC)
{
    float fBtnH  = GetNuiScaleDimension(oPC, 30.0);
    float fRowH  = GetNuiScaleDimension(oPC, 32.0);
    float fHdrH  = GetNuiScaleDimension(oPC, 42.0);
    float fListH = GetNuiScaleDimension(oPC, 210.0);

    json jHdr = NuiLabel(
        JsonString("Krew przemawia... Wybierz swoje Dziedzictwo."),
        JsonInt(NUI_HALIGN_CENTER), JsonInt(NUI_VALIGN_MIDDLE));
    jHdr = NuiHeight(jHdr, fHdrH);
    jHdr = NuiStyleForegroundColor(jHdr, NuiColor(200, 160, 100));

    json jSubHdr = NuiLabel(
        JsonString("Przebudzenie jest nieodwracalne. Wybierz madrzej."),
        JsonInt(NUI_HALIGN_CENTER), JsonInt(NUI_VALIGN_MIDDLE));
    jSubHdr = NuiHeight(jSubHdr, GetNuiScaleDimension(oPC, 22.0));
    jSubHdr = NuiStyleForegroundColor(jSubHdr, NuiColor(140, 100, 80));

    json jNameLbl = NuiLabel(NuiBind(BLD_BIND_CHOICE_ROW_NAME), JsonInt(NUI_HALIGN_LEFT), JsonInt(NUI_VALIGN_MIDDLE));
    jNameLbl = NuiStyleForegroundColor(jNameLbl, NuiColor(220, 190, 130));

    json jCell = NuiGroup(NuiRow(JsonArrayInsert(JsonArray(), jNameLbl)), TRUE, NUI_SCROLLBARS_NONE);
    jCell = NuiId(jCell, BLD_BTN_CHOICE_ROW);
    jCell = NuiEncouraged(jCell, NuiBind(BLD_BIND_CHOICE_ROW_ENC));

    json jTmpl = JsonArrayInsert(JsonArray(), NuiListTemplateCell(jCell, 0.0, TRUE));
    json jList = NuiList(jTmpl, NuiBind(BLD_BIND_CHOICE_CNT), fRowH);
    jList = NuiHeight(jList, fListH);

    json jConfirmBtn = NuiButton(JsonString("Przebudzic Krew"));
    jConfirmBtn = NuiId(jConfirmBtn, BLD_BTN_CHOOSE_CONFIRM);
    jConfirmBtn = NuiWidth(jConfirmBtn, GetNuiScaleDimension(oPC, 160.0));
    jConfirmBtn = NuiHeight(jConfirmBtn, fBtnH);

    json jCancelBtn = NuiButton(JsonString("Jeszcze nie teraz"));
    jCancelBtn = NuiId(jCancelBtn, BLD_BTN_CHOOSE_CANCEL);
    jCancelBtn = NuiWidth(jCancelBtn, GetNuiScaleDimension(oPC, 160.0));
    jCancelBtn = NuiHeight(jCancelBtn, fBtnH);

    json jBotRow = JsonArray();
    jBotRow = JsonArrayInsert(jBotRow, jCancelBtn);
    jBotRow = JsonArrayInsert(jBotRow, NuiSpacer());
    jBotRow = JsonArrayInsert(jBotRow, jConfirmBtn);

    json jCol = JsonArray();
    jCol = JsonArrayInsert(jCol, jHdr);
    jCol = JsonArrayInsert(jCol, jSubHdr);
    jCol = JsonArrayInsert(jCol, jList);
    jCol = JsonArrayInsert(jCol, NuiRow(jBotRow));

    json jSide = NuiCol(JsonArrayInsert(JsonArray(), NuiSpacer()));
    float fContentW = GetNuiScaleDimension(oPC, 440.0);
    json jMainRow = JsonArray();
    jMainRow = JsonArrayInsert(jMainRow, jSide);
    jMainRow = JsonArrayInsert(jMainRow, NuiWidth(NuiCol(jCol), fContentW));
    jMainRow = JsonArrayInsert(jMainRow, jSide);
    return NuiRow(jMainRow);
}

// ----------------------------------------------------------------
// Main view
// ----------------------------------------------------------------

json BldBuildMainView(object oPC)
{
    float fBtnH  = GetNuiScaleDimension(oPC, 30.0);
    float fLoreH = GetNuiScaleDimension(oPC, 100.0);
    float fEffH  = GetNuiScaleDimension(oPC, 20.0);
    float fHdrH  = GetNuiScaleDimension(oPC, 36.0);

    // Bloodline name + tier row
    json jNameLbl = NuiLabel(NuiBind(BLD_BIND_LINEAGE_NAME), JsonInt(NUI_HALIGN_LEFT), JsonInt(NUI_VALIGN_MIDDLE));
    jNameLbl = NuiStyleForegroundColor(jNameLbl, NuiBind(BLD_BIND_TIER_COLOR));
    jNameLbl = NuiHeight(jNameLbl, fHdrH);

    json jTierLbl = NuiLabel(NuiBind(BLD_BIND_TIER_NAME), JsonInt(NUI_HALIGN_RIGHT), JsonInt(NUI_VALIGN_MIDDLE));
    jTierLbl = NuiStyleForegroundColor(jTierLbl, NuiBind(BLD_BIND_TIER_COLOR));
    jTierLbl = NuiWidth(jTierLbl, GetNuiScaleDimension(oPC, 130.0));
    jTierLbl = NuiHeight(jTierLbl, fHdrH);

    json jHeaderRow = JsonArray();
    jHeaderRow = JsonArrayInsert(jHeaderRow, jNameLbl);
    jHeaderRow = JsonArrayInsert(jHeaderRow, NuiSpacer());
    jHeaderRow = JsonArrayInsert(jHeaderRow, jTierLbl);

    // Purity display
    json jPurityLbl = NuiLabel(NuiBind(BLD_BIND_PURITY_VAL), JsonInt(NUI_HALIGN_CENTER), JsonInt(NUI_VALIGN_MIDDLE));
    jPurityLbl = NuiHeight(jPurityLbl, GetNuiScaleDimension(oPC, 22.0));
    jPurityLbl = NuiStyleForegroundColor(jPurityLbl, NuiColor(170, 170, 200));

    // Lore text
    json jLoreTxt = NuiGroup(NuiText(NuiBind(BLD_BIND_LINEAGE_LORE), FALSE), TRUE, NUI_SCROLLBARS_NONE);
    jLoreTxt = NuiHeight(jLoreTxt, fLoreH);

    // Effects header
    json jEffHdr = NuiLabel(JsonString("Efekty dziedzictwa"), JsonInt(NUI_HALIGN_LEFT), JsonInt(NUI_VALIGN_MIDDLE));
    jEffHdr = NuiHeight(jEffHdr, fEffH);
    jEffHdr = NuiStyleForegroundColor(jEffHdr, NuiColor(200, 200, 200));

    // Three tier effect rows
    json jEff1 = NuiLabel(NuiBind(BLD_BIND_EFFECTS_T1), JsonInt(NUI_HALIGN_LEFT), JsonInt(NUI_VALIGN_MIDDLE));
    jEff1 = NuiStyleForegroundColor(jEff1, NuiBind(BLD_BIND_TIER1_COLOR));
    jEff1 = NuiHeight(jEff1, fEffH);

    json jEff2 = NuiLabel(NuiBind(BLD_BIND_EFFECTS_T2), JsonInt(NUI_HALIGN_LEFT), JsonInt(NUI_VALIGN_MIDDLE));
    jEff2 = NuiStyleForegroundColor(jEff2, NuiBind(BLD_BIND_TIER2_COLOR));
    jEff2 = NuiHeight(jEff2, fEffH);

    json jEff3 = NuiLabel(NuiBind(BLD_BIND_EFFECTS_T3), JsonInt(NUI_HALIGN_LEFT), JsonInt(NUI_VALIGN_MIDDLE));
    jEff3 = NuiStyleForegroundColor(jEff3, NuiBind(BLD_BIND_TIER3_COLOR));
    jEff3 = NuiHeight(jEff3, fEffH);

    // Cooldown line
    json jCooldown = NuiLabel(NuiBind(BLD_BIND_COOLDOWN_LBL), JsonInt(NUI_HALIGN_CENTER), JsonInt(NUI_VALIGN_MIDDLE));
    jCooldown = NuiHeight(jCooldown, fEffH);
    jCooldown = NuiStyleForegroundColor(jCooldown, NuiColor(180, 120, 60));

    // Ritual cost description
    json jRitualDesc = NuiLabel(NuiBind(BLD_BIND_RITUAL_DESC), JsonInt(NUI_HALIGN_CENTER), JsonInt(NUI_VALIGN_MIDDLE));
    jRitualDesc = NuiHeight(jRitualDesc, fEffH);
    jRitualDesc = NuiStyleForegroundColor(jRitualDesc, NuiColor(200, 160, 100));

    // Ritual button
    json jRitualBtn = NuiButton(NuiBind(BLD_BIND_RITUAL_LBL));
    jRitualBtn = NuiId(jRitualBtn, BLD_BTN_RITUAL);
    jRitualBtn = NuiEnabled(jRitualBtn, NuiBind(BLD_BIND_RITUAL_ENA));
    jRitualBtn = NuiHeight(jRitualBtn, fBtnH);

    // Assemble column
    json jCol = JsonArray();
    jCol = JsonArrayInsert(jCol, NuiRow(jHeaderRow));
    jCol = JsonArrayInsert(jCol, jPurityLbl);
    jCol = JsonArrayInsert(jCol, jLoreTxt);
    jCol = JsonArrayInsert(jCol, CreateEmptyRow(oPC, 6.0));
    jCol = JsonArrayInsert(jCol, jEffHdr);
    jCol = JsonArrayInsert(jCol, jEff1);
    jCol = JsonArrayInsert(jCol, jEff2);
    jCol = JsonArrayInsert(jCol, jEff3);
    jCol = JsonArrayInsert(jCol, CreateEmptyRow(oPC, 8.0));
    jCol = JsonArrayInsert(jCol, jRitualDesc);
    jCol = JsonArrayInsert(jCol, jCooldown);
    jCol = JsonArrayInsert(jCol, jRitualBtn);

    json jSide = NuiCol(JsonArrayInsert(JsonArray(), NuiSpacer()));
    float fContentW = GetNuiScaleDimension(oPC, 440.0);
    json jMainRow = JsonArray();
    jMainRow = JsonArrayInsert(jMainRow, jSide);
    jMainRow = JsonArrayInsert(jMainRow, NuiWidth(NuiCol(jCol), fContentW));
    jMainRow = JsonArrayInsert(jMainRow, jSide);
    return NuiRow(jMainRow);
}

// ----------------------------------------------------------------
// Window lifecycle
// ----------------------------------------------------------------

void BldOpenWindow(object oPC)
{
    int nToken = NuiFindWindow(oPC, BLD_WINDOW);
    if(nToken != 0)
    {
        BldFeedWindow(oPC, nToken);
        return;
    }

    BldEnsureRecord(oPC);

    float fW = GetNuiScaleDimension(oPC, 500.0);
    float fH = GetNuiScaleDimension(oPC, 490.0);
    float fX = (IntToFloat(GetPlayerDeviceProperty(oPC, PLAYER_DEVICE_PROPERTY_GUI_WIDTH))  - fW) / 2.0;
    float fY = (IntToFloat(GetPlayerDeviceProperty(oPC, PLAYER_DEVICE_PROPERTY_GUI_HEIGHT)) - fH) / 2.0;

    float fBtnH = GetNuiScaleDimension(oPC, 28.0);
    json jCloseBtn = NuiButton(JsonString("X"));
    jCloseBtn = NuiId(jCloseBtn, BLD_BTN_CLOSE);
    jCloseBtn = NuiWidth(jCloseBtn, GetNuiScaleDimension(oPC, 28.0));
    jCloseBtn = NuiHeight(jCloseBtn, fBtnH);

    json jTitleLbl = NuiLabel(JsonString("Dziedzictwo Krwi"), JsonInt(NUI_HALIGN_LEFT), JsonInt(NUI_VALIGN_MIDDLE));
    jTitleLbl = NuiHeight(jTitleLbl, fBtnH);
    jTitleLbl = NuiStyleForegroundColor(jTitleLbl, NuiColor(200, 50, 50));

    json jTopRow = JsonArray();
    jTopRow = JsonArrayInsert(jTopRow, jTitleLbl);
    jTopRow = JsonArrayInsert(jTopRow, NuiSpacer());
    jTopRow = JsonArrayInsert(jTopRow, jCloseBtn);

    int nType = BldGetBloodlineType(oPC);
    json jContent = (nType < 0) ? BldBuildChooseView(oPC) : BldBuildMainView(oPC);

    json jSwapGrp = NuiGroup(jContent, FALSE, NUI_SCROLLBARS_NONE);
    jSwapGrp = NuiId(jSwapGrp, BLD_GRP_CONTENT);

    json jRootChildren = JsonArray();
    jRootChildren = JsonArrayInsert(jRootChildren, NuiRow(jTopRow));
    jRootChildren = JsonArrayInsert(jRootChildren, jSwapGrp);
    json jRoot = NuiCol(jRootChildren);

    json jWin = NuiWindow(jRoot,
        JsonBool(FALSE),
        NuiBind(BLD_WIN_GEOM),
        JsonBool(FALSE),
        JsonBool(FALSE),
        JsonBool(FALSE),
        JsonBool(TRUE),
        JsonBool(FALSE));

    nToken = NuiCreate(oPC, jWin, BLD_WINDOW, BLD_EV_SCRIPT);
    NuiSetBind(oPC, nToken, BLD_WIN_GEOM, NuiRect(fX, fY, fW, fH));

    BldFeedWindow(oPC, nToken);
}

void BldFeedWindow(object oPC, int nToken)
{
    BldEnsureRecord(oPC);
    int nType = BldGetBloodlineType(oPC);

    if(nType < 0)
    {
        NuiSetGroupLayout(oPC, nToken, BLD_GRP_CONTENT, BldBuildChooseView(oPC));

        int bHasPending = GetLocalInt(oPC, BLD_LVAR_HAS_PENDING);
        int nPendingIdx = GetLocalInt(oPC, BLD_LVAR_PENDING_TYPE);

        json jNames = JsonArray();
        json jEncs  = JsonArray();
        int i;
        for(i = 0; i < BLD_TYPE_COUNT; i++)
        {
            jNames = JsonArrayInsert(jNames, JsonString(BldGetName(i)));
            jEncs  = JsonArrayInsert(jEncs,  JsonBool(bHasPending && i == nPendingIdx));
        }
        NuiSetBind(oPC, nToken, BLD_BIND_CHOICE_ROW_NAME, jNames);
        NuiSetBind(oPC, nToken, BLD_BIND_CHOICE_ROW_ENC,  jEncs);
        NuiSetBind(oPC, nToken, BLD_BIND_CHOICE_CNT,      JsonInt(BLD_TYPE_COUNT));
        return;
    }

    NuiSetGroupLayout(oPC, nToken, BLD_GRP_CONTENT, BldBuildMainView(oPC));

    int nPurity  = BldGetPurity(oPC);
    int nTier    = BldGetCurrentTier(nPurity);
    int nLastRit = BldGetLastRitual(oPC);
    int nNow     = BldGetCurrentTimestamp();

    // Tier label color
    json jTierColor;
    switch(nTier)
    {
        case 0:  jTierColor = NuiColor(130, 130, 130); break;
        case 1:  jTierColor = NuiColor(160, 220, 160); break;
        case 2:  jTierColor = NuiColor(255, 200,  80); break;
        default: jTierColor = NuiColor(255,  80,  80); break;
    }

    json jColActive   = NuiColor(220, 200, 150);
    json jColInactive = NuiColor(80,  80,  80);

    NuiSetBind(oPC, nToken, BLD_BIND_LINEAGE_NAME, JsonString(BldGetName(nType)));
    NuiSetBind(oPC, nToken, BLD_BIND_LINEAGE_LORE, JsonString(BldGetLore(nType)));
    NuiSetBind(oPC, nToken, BLD_BIND_TIER_NAME,    JsonString(BldGetTierName(nTier)));
    NuiSetBind(oPC, nToken, BLD_BIND_TIER_COLOR,   jTierColor);
    NuiSetBind(oPC, nToken, BLD_BIND_PURITY_VAL,
        JsonString("Czystosc Krwi: " + IntToString(nPurity) + " / 100  |  Poziom: " + BldGetTierName(nTier)));

    NuiSetBind(oPC, nToken, BLD_BIND_EFFECTS_T1,
        JsonString("[Budzaca sie]  " + BldGetTierEffectDesc(nType, BLD_TIER_STIRRING)));
    NuiSetBind(oPC, nToken, BLD_BIND_EFFECTS_T2,
        JsonString("[Obudzona]     " + BldGetTierEffectDesc(nType, BLD_TIER_AWAKENED)));
    NuiSetBind(oPC, nToken, BLD_BIND_EFFECTS_T3,
        JsonString("[Wzniosla]     " + BldGetTierEffectDesc(nType, BLD_TIER_ASCENDANT)));

    NuiSetBind(oPC, nToken, BLD_BIND_TIER1_COLOR, nTier >= BLD_TIER_STIRRING  ? jColActive : jColInactive);
    NuiSetBind(oPC, nToken, BLD_BIND_TIER2_COLOR, nTier >= BLD_TIER_AWAKENED  ? jColActive : jColInactive);
    NuiSetBind(oPC, nToken, BLD_BIND_TIER3_COLOR, nTier >= BLD_TIER_ASCENDANT ? jColActive : jColInactive);

    if(nTier >= BLD_TIER_ASCENDANT)
    {
        NuiSetBind(oPC, nToken, BLD_BIND_RITUAL_DESC, JsonString("Pieczen krwi pulsuje juz pelna moca."));
        NuiSetBind(oPC, nToken, BLD_BIND_RITUAL_LBL,  JsonString("Krew calkowicie przebudzona"));
        NuiSetBind(oPC, nToken, BLD_BIND_RITUAL_ENA,  JsonBool(FALSE));
        NuiSetBind(oPC, nToken, BLD_BIND_COOLDOWN_LBL, JsonString(""));
        return;
    }

    int nHPPct    = BldGetRitualHPPct(nTier);
    int nGoldCost = BldGetRitualGoldCost(nTier);
    int nMaxHP    = GetMaxHitPoints(oPC);
    int nHPDmg    = (nMaxHP * nHPPct) / 100;
    if(nHPDmg < 1) nHPDmg = 1;
    int nNextTier = nTier + 1;

    int nCoolRemain = (nLastRit + BLD_RITUAL_COOLDOWN) - nNow;
    int bOnCooldown = (nCoolRemain > 0);

    string sCoolLbl = "";
    if(bOnCooldown)
    {
        int nHoursLeft = nCoolRemain / 3600;
        int nMinsLeft  = (nCoolRemain % 3600) / 60;
        sCoolLbl = "Nastepny rytual za: " + IntToString(nHoursLeft) + "h " + IntToString(nMinsLeft) + "m";
    }

    NuiSetBind(oPC, nToken, BLD_BIND_RITUAL_DESC,
        JsonString("Koszt: " + IntToString(nHPDmg) + " HP (" + IntToString(nHPPct)
            + "% maksimum) + " + IntToString(nGoldCost) + " sztuk zlota"));
    NuiSetBind(oPC, nToken, BLD_BIND_RITUAL_LBL,
        JsonString("Odpraw Rytual Krwi  =>  " + BldGetTierName(nNextTier)));
    NuiSetBind(oPC, nToken, BLD_BIND_RITUAL_ENA,   JsonBool(!bOnCooldown));
    NuiSetBind(oPC, nToken, BLD_BIND_COOLDOWN_LBL, JsonString(sCoolLbl));
}
