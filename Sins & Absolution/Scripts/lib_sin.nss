#include "lib_sin_def"

// ================================================================
// String / color helpers
// ================================================================

string SinTypeName(int nType)
{
    switch (nType)
    {
        case SIN_TYPE_MURDER:      return "Morderstwo";
        case SIN_TYPE_THEFT:       return "Kradzież";
        case SIN_TYPE_BLASPHEMY:   return "Bluźnierstwo";
        case SIN_TYPE_DARK_RITUAL: return "Mroczny Rytuał";
        case SIN_TYPE_BETRAYAL:    return "Zdrada";
        case SIN_TYPE_UNDEAD:      return "Nekromancja";
        case SIN_TYPE_DEMON_PACT:  return "Pakt z Demonem";
        case SIN_TYPE_CORRUPTION:  return "Korupcja";
        case SIN_TYPE_DESECRATION: return "Profanacja";
    }
    return "Grzech";
}

json SinTypeColor(int nType)
{
    switch (nType)
    {
        case SIN_TYPE_MURDER:      return NuiColor(220,  40,  40);
        case SIN_TYPE_THEFT:       return NuiColor(190, 140,  50);
        case SIN_TYPE_BLASPHEMY:   return NuiColor(140,  60, 200);
        case SIN_TYPE_DARK_RITUAL: return NuiColor(110,  40, 180);
        case SIN_TYPE_BETRAYAL:    return NuiColor(210, 180,  30);
        case SIN_TYPE_UNDEAD:      return NuiColor(170, 200, 170);
        case SIN_TYPE_DEMON_PACT:  return NuiColor(230,  20,  70);
        case SIN_TYPE_CORRUPTION:  return NuiColor( 60, 170,  70);
        case SIN_TYPE_DESECRATION: return NuiColor(160, 150, 140);
    }
    return NuiColor(200, 200, 200);
}

string SinLevelName(int nScore)
{
    if (nScore >= SIN_LEVEL_DAMNED)  return "POTĘPIONY";
    if (nScore >= SIN_LEVEL_CORRUPT) return "Przeklęty";
    if (nScore >= SIN_LEVEL_WICKED)  return "Niegodziwiec";
    if (nScore >= SIN_LEVEL_IMPURE)  return "Nieczysty";
    if (nScore >= SIN_LEVEL_TAINTED) return "Skażony";
    return "Czysty";
}

json SinLevelColor(int nScore)
{
    if (nScore >= SIN_LEVEL_DAMNED)  return NuiColor(255,  20,  20);
    if (nScore >= SIN_LEVEL_CORRUPT) return NuiColor(230,  70,  50);
    if (nScore >= SIN_LEVEL_WICKED)  return NuiColor(210, 120,  50);
    if (nScore >= SIN_LEVEL_IMPURE)  return NuiColor(190, 170,  60);
    if (nScore >= SIN_LEVEL_TAINTED) return NuiColor(160, 190, 100);
    return NuiColor(130, 200, 130);
}

string SinGetPenaltyDesc(int nScore)
{
    if (nScore >= SIN_LEVEL_DAMNED)
        return "−4 Cha, −3 Mąd, −3 Int, −3 Wola";
    if (nScore >= SIN_LEVEL_CORRUPT)
        return "−3 Cha, −2 Mąd, −2 Int, −2 Wola";
    if (nScore >= SIN_LEVEL_WICKED)
        return "−3 Cha, −2 Mąd, −1 Int";
    if (nScore >= SIN_LEVEL_IMPURE)
        return "−2 Cha, −1 Mąd";
    if (nScore >= SIN_LEVEL_TAINTED)
        return "−1 Cha";
    return "Brak";
}

int SinCalcAbsolveCost(int nScore)
{
    return nScore * SIN_ABS_GOLD_PER_PT;
}

// ================================================================
// Effect management
// ================================================================

void SinRemoveTaggedEffects(object oPC, string sTag)
{
    effect e = GetFirstEffect(oPC);
    while (GetIsEffectValid(e))
    {
        if (GetEffectTag(e) == sTag)
            RemoveEffect(oPC, e);
        e = GetNextEffect(oPC);
    }
}

void SinApplyPenalties(object oPC)
{
    SinRemoveTaggedEffects(oPC, SIN_EFFECT_TAG);

    int nScore = SinGetScore(oPC);
    if (nScore < SIN_LEVEL_TAINTED) return;

    // Cumulative stat decreases per threshold
    int nCha = 0;
    int nWis = 0;
    int nInt = 0;
    int nWil = 0;

    if (nScore >= SIN_LEVEL_TAINTED) { nCha += 1; }
    if (nScore >= SIN_LEVEL_IMPURE)  { nCha += 1; nWis += 1; }
    if (nScore >= SIN_LEVEL_WICKED)  { nCha += 1; nWis += 1; nInt += 1; }
    if (nScore >= SIN_LEVEL_CORRUPT) { nInt += 1; nWil += 2; }
    if (nScore >= SIN_LEVEL_DAMNED)  { nCha += 1; nWis += 1; nInt += 1; nWil += 1; }

    // Build single linked effect so removal by tag is O(1) in the effects list
    effect ePen = EffectAbilityDecrease(ABILITY_CHARISMA, nCha);
    if (nWis > 0)
        ePen = EffectLinkEffects(ePen, EffectAbilityDecrease(ABILITY_WISDOM, nWis));
    if (nInt > 0)
        ePen = EffectLinkEffects(ePen, EffectAbilityDecrease(ABILITY_INTELLIGENCE, nInt));
    if (nWil > 0)
        ePen = EffectLinkEffects(ePen, EffectSavingThrowDecrease(SAVING_THROW_WILL, nWil));
    if (nScore >= SIN_LEVEL_DAMNED)
        ePen = EffectLinkEffects(ePen, EffectIcon(EFFECT_ICON_DISEASE));

    ePen = SupernaturalEffect(ePen);
    ePen = TagEffect(ePen, SIN_EFFECT_TAG);
    ApplyEffectToObject(DURATION_TYPE_PERMANENT, ePen, oPC);
}

void SinApplyEmbraceEffects(object oPC)
{
    SinRemoveTaggedEffects(oPC, SIN_EMBRACE_TAG);

    effect eEmb = EffectAbilityIncrease(ABILITY_STRENGTH, 2);
    eEmb = EffectLinkEffects(eEmb, EffectAbilityIncrease(ABILITY_CONSTITUTION, 2));
    eEmb = EffectLinkEffects(eEmb, EffectDamageBonus(DAMAGE_BONUS_1, DAMAGE_TYPE_NEGATIVE));
    eEmb = EffectLinkEffects(eEmb, EffectImmunity(IMMUNITY_TYPE_FEAR));
    eEmb = SupernaturalEffect(eEmb);
    eEmb = TagEffect(eEmb, SIN_EMBRACE_TAG);
    ApplyEffectToObject(DURATION_TYPE_PERMANENT, eEmb, oPC);
}

// ================================================================
// Public API — call from other modules to record sin
// ================================================================

void SinAddSin(object oPC, int nSinType, int nAmount, string sDesc)
{
    if (!GetIsPC(oPC) || nAmount <= 0) return;

    SinRegisterChar(oPC);

    int nCurrent = SinGetScore(oPC);
    int nNew     = nCurrent + nAmount;
    if (nNew > SIN_MAX) nNew = SIN_MAX;

    SinSetScore(oPC, nNew);
    SinLogEntry(oPC, nSinType, nAmount, sDesc);
    SinApplyPenalties(oPC);

    SendMessageToPC(oPC,
        "[Piętno] " + SinTypeName(nSinType) + ": +" + IntToString(nAmount) +
        " pkt. (" + IntToString(nNew) + "/" + IntToString(SIN_MAX) + ")");

    if (nNew >= SIN_LEVEL_DAMNED && nCurrent < SIN_LEVEL_DAMNED)
        FloatingTextStringOnCreature(
            "Piętno pożera twoją duszę bez reszty. Jesteś POTĘPIONY.", oPC, FALSE);
    else if (nNew >= SIN_LEVEL_CORRUPT && nCurrent < SIN_LEVEL_CORRUPT)
        FloatingTextStringOnCreature(
            "Ciemność znaczy cię na zawsze. Jesteś przeklęty.", oPC, FALSE);
    else if (nNew >= SIN_LEVEL_WICKED && nCurrent < SIN_LEVEL_WICKED)
        FloatingTextStringOnCreature(
            "Grzech wyżera ci twarz. Ludzie odwracają wzrok.", oPC, FALSE);

    int nToken = NuiFindWindow(oPC, SIN_WINDOW);
    if (nToken != 0) SinFeedWindow(oPC, nToken);
}

void SinAbsolve(object oPC)
{
    if (SinIsEmbraced(oPC))
    {
        SendMessageToPC(oPC,
            "[Piętno] Mroczne Objęcie zamknęło twą duszę na łaskę. Absolucja jest niedostępna.");
        return;
    }

    int nScore = SinGetScore(oPC);
    if (nScore <= 0)
    {
        SendMessageToPC(oPC, "[Piętno] Twoja dusza jest czysta — nie ma czego przebaczać.");
        return;
    }

    int nCost = SinCalcAbsolveCost(nScore);
    if (GetGold(oPC) < nCost)
    {
        SendMessageToPC(oPC,
            "[Piętno] Absolucja kosztuje " + IntToString(nCost) +
            " sz. Brakuje ci złota na oczyszczenie duszy.");
        return;
    }

    AssignCommand(oPC, TakeGoldFromCreature(nCost, oPC, TRUE));
    SinSetScore(oPC, 0);
    SinClearLog(oPC);
    SinApplyPenalties(oPC);

    ApplyEffectToObject(DURATION_TYPE_INSTANT, EffectVisualEffect(VFX_IMP_HOLY_AID), oPC);
    FloatingTextStringOnCreature(
        "Absolucja udzielona. Dusza oczyszczona jak nowo wykuta stal.", oPC, FALSE);
    SendMessageToPC(oPC,
        "[Piętno] Absolucja przyjęta. −" + IntToString(nCost) + " sz. Grzechy wymazane z rejestru.");

    int nToken = NuiFindWindow(oPC, SIN_WINDOW);
    if (nToken != 0) SinFeedWindow(oPC, nToken);
}

void SinEmbrace(object oPC)
{
    if (SinIsEmbraced(oPC))
    {
        SendMessageToPC(oPC, "[Piętno] Już przyjąłeś Mroczne Objęcie. Droga wstecz jest zamknięta.");
        return;
    }

    int nScore = SinGetScore(oPC);
    if (nScore < SIN_EMBRACE_MIN)
    {
        SendMessageToPC(oPC,
            "[Piętno] Piętno jest zbyt słabe. Potrzebujesz " +
            IntToString(SIN_EMBRACE_MIN) + " pkt grzechu by Objęcie cię przyjęło.");
        return;
    }

    SinSetEmbraced(oPC, 1);

    int nNew = nScore + SIN_EMBRACE_COST;
    if (nNew > SIN_MAX) nNew = SIN_MAX;
    SinSetScore(oPC, nNew);
    SinLogEntry(oPC, SIN_TYPE_DARK_RITUAL, SIN_EMBRACE_COST, "Przyjęcie Mrocznego Objęcia");

    SinApplyPenalties(oPC);
    SinApplyEmbraceEffects(oPC);

    ApplyEffectToObject(DURATION_TYPE_INSTANT, EffectVisualEffect(VFX_IMP_EVIL_HELP), oPC);
    FloatingTextStringOnCreature(
        "Mroczne Objęcie wypala znamię na duszy. Moc bez granic — odkupienie niemożliwe.", oPC, FALSE);
    SendMessageToPC(oPC,
        "[Piętno] Mroczne Objęcie przyjęte: +2 Siły, +2 Budowy, odporność na Strach, +1 obrażenia nekrotyczne. "
        "Absolucja zamknięta na zawsze.");

    int nToken = NuiFindWindow(oPC, SIN_WINDOW);
    if (nToken != 0) SinFeedWindow(oPC, nToken);
}

// ================================================================
// NUI — list row template cell
// ================================================================

json SinBuildRowCell(object oPC)
{
    float fTypeW = GetNuiScaleDimension(oPC, 140.0);
    float fAmtW  = GetNuiScaleDimension(oPC, 44.0);
    float fH     = GetNuiScaleDimension(oPC, 24.0);

    json jType = NuiLabel(
        NuiBind(SIN_BIND_ROW_TYPE),
        JsonInt(NUI_HALIGN_LEFT),
        JsonInt(NUI_VALIGN_MIDDLE));
    jType = NuiWidth(jType, fTypeW);
    jType = NuiStyleForegroundColor(jType, NuiBind(SIN_BIND_ROW_COLOR));

    json jDesc = NuiLabel(
        NuiBind(SIN_BIND_ROW_DESC),
        JsonInt(NUI_HALIGN_LEFT),
        JsonInt(NUI_VALIGN_MIDDLE));
    jDesc = NuiStyleForegroundColor(jDesc, NuiBind(SIN_BIND_ROW_COLOR));

    // Amount column always in blood red — color is not row-specific
    json jAmt = NuiLabel(
        NuiBind(SIN_BIND_ROW_AMT),
        JsonInt(NUI_HALIGN_RIGHT),
        JsonInt(NUI_VALIGN_MIDDLE));
    jAmt = NuiWidth(jAmt, fAmtW);
    jAmt = NuiStyleForegroundColor(jAmt, NuiColor(220, 50, 50));

    json jCols = JsonArray();
    jCols = JsonArrayInsert(jCols, jType);
    jCols = JsonArrayInsert(jCols, jDesc);
    jCols = JsonArrayInsert(jCols, jAmt);

    json jCell = NuiGroup(NuiRow(jCols), FALSE, NUI_SCROLLBARS_NONE);
    jCell = NuiHeight(jCell, fH);
    return jCell;
}

// ================================================================
// NUI — window builder
// ================================================================

void SinOpenWindow(object oPC)
{
    int nExisting = NuiFindWindow(oPC, SIN_WINDOW);
    if (nExisting != 0)
    {
        SinFeedWindow(oPC, nExisting);
        return;
    }

    float fW    = GetNuiScaleDimension(oPC, SIN_W);
    float fH    = GetNuiScaleDimension(oPC, SIN_H);
    float fBtnH = GetNuiScaleDimension(oPC, 30.0);
    float fBarH = GetNuiScaleDimension(oPC, 20.0);
    float fLblH = GetNuiScaleDimension(oPC, 22.0);

    // Title row: label left, X right
    json jTitleLbl = NuiLabel(
        JsonString("PIĘTNO GRZECHU"),
        JsonInt(NUI_HALIGN_LEFT),
        JsonInt(NUI_VALIGN_MIDDLE));
    jTitleLbl = NuiHeight(jTitleLbl, fBtnH);
    jTitleLbl = NuiStyleForegroundColor(jTitleLbl, NuiColor(220, 55, 55));

    json jClose = NuiButton(JsonString("X"));
    jClose = NuiId(jClose, SIN_BTN_CLOSE);
    jClose = NuiWidth(jClose, GetNuiScaleDimension(oPC, 30.0));
    jClose = NuiHeight(jClose, fBtnH);

    json jTitleRow = JsonArray();
    jTitleRow = JsonArrayInsert(jTitleRow, jTitleLbl);
    jTitleRow = JsonArrayInsert(jTitleRow, NuiSpacer());
    jTitleRow = JsonArrayInsert(jTitleRow, jClose);

    // Sin gauge (0.0 - 1.0)
    json jGauge = NuiProgress(NuiBind(SIN_BIND_GAUGE));
    jGauge = NuiHeight(jGauge, fBarH);
    jGauge = NuiTooltip(jGauge, JsonString("Poziom piętna grzechu"));

    json jGaugeRow = JsonArray();
    jGaugeRow = JsonArrayInsert(jGaugeRow, jGauge);

    // Status label: level name + score
    json jStatus = NuiLabel(
        NuiBind(SIN_BIND_STATUS_LBL),
        JsonInt(NUI_HALIGN_CENTER),
        JsonInt(NUI_VALIGN_MIDDLE));
    jStatus = NuiHeight(jStatus, fLblH);
    jStatus = NuiStyleForegroundColor(jStatus, NuiBind(SIN_BIND_STATUS_COL));

    json jStatusRow = JsonArray();
    jStatusRow = JsonArrayInsert(jStatusRow, jStatus);

    // Sin log list header label
    json jLogHdr = NuiLabel(
        JsonString("Rejestr grzechów:"),
        JsonInt(NUI_HALIGN_LEFT),
        JsonInt(NUI_VALIGN_MIDDLE));
    jLogHdr = NuiHeight(jLogHdr, fLblH);
    jLogHdr = NuiStyleForegroundColor(jLogHdr, NuiColor(180, 170, 140));

    json jLogHdrRow = JsonArray();
    jLogHdrRow = JsonArrayInsert(jLogHdrRow, jLogHdr);

    // Sin log list
    json jListCells = JsonArray();
    jListCells = JsonArrayInsert(jListCells,
        NuiListTemplateCell(SinBuildRowCell(oPC), 0.0, TRUE));

    float fListH = fH - GetNuiScaleDimension(oPC, 260.0);
    json jList = NuiList(jListCells, NuiBind(SIN_BIND_ROW_COUNT),
        GetNuiScaleDimension(oPC, 24.0));
    jList = NuiHeight(jList, fListH);

    json jListRow = JsonArray();
    jListRow = JsonArrayInsert(jListRow, jList);

    // Penalty description label
    json jPenLbl = NuiLabel(
        NuiBind(SIN_BIND_PENALTY_LBL),
        JsonInt(NUI_HALIGN_LEFT),
        JsonInt(NUI_VALIGN_MIDDLE));
    jPenLbl = NuiHeight(jPenLbl, fLblH);
    jPenLbl = NuiStyleForegroundColor(jPenLbl, NuiColor(200, 170, 70));

    json jPenRow = JsonArray();
    jPenRow = JsonArrayInsert(jPenRow, jPenLbl);

    // Action buttons: Absolucja | Mroczne Objęcie
    json jAbsBtn = NuiButton(NuiBind(SIN_BIND_ABS_LBL));
    jAbsBtn = NuiId(jAbsBtn, SIN_BTN_ABS);
    jAbsBtn = NuiEnabled(jAbsBtn, NuiBind(SIN_BIND_ABS_ENA));
    jAbsBtn = NuiHeight(jAbsBtn, fBtnH);
    jAbsBtn = NuiTooltip(jAbsBtn,
        JsonString("Oddaj złoto kapłanowi i usuń wszystkie grzechy z rejestru"));

    json jEmbBtn = NuiButton(NuiBind(SIN_BIND_EMB_LBL));
    jEmbBtn = NuiId(jEmbBtn, SIN_BTN_EMBRACE);
    jEmbBtn = NuiEnabled(jEmbBtn, NuiBind(SIN_BIND_EMB_ENA));
    jEmbBtn = NuiHeight(jEmbBtn, fBtnH);
    jEmbBtn = NuiTooltip(jEmbBtn,
        JsonString("Przyjmij mrok jako część siebie. Nieodwracalne. Blokuje absolucję."));

    json jActRow = JsonArray();
    jActRow = JsonArrayInsert(jActRow, jAbsBtn);
    jActRow = JsonArrayInsert(jActRow,
        NuiWidth(NuiSpacer(), GetNuiScaleDimension(oPC, 8.0)));
    jActRow = JsonArrayInsert(jActRow, jEmbBtn);

    // Assemble column layout
    json jCols = JsonArray();
    jCols = JsonArrayInsert(jCols, NuiRow(jTitleRow));
    jCols = JsonArrayInsert(jCols, CreateEmptyRow(oPC, 6.0));
    jCols = JsonArrayInsert(jCols, NuiRow(jGaugeRow));
    jCols = JsonArrayInsert(jCols, NuiRow(jStatusRow));
    jCols = JsonArrayInsert(jCols, CreateEmptyRow(oPC, 4.0));
    jCols = JsonArrayInsert(jCols, NuiRow(jLogHdrRow));
    jCols = JsonArrayInsert(jCols, NuiRow(jListRow));
    jCols = JsonArrayInsert(jCols, CreateEmptyRow(oPC, 4.0));
    jCols = JsonArrayInsert(jCols, NuiRow(jPenRow));
    jCols = JsonArrayInsert(jCols, CreateEmptyRow(oPC, 6.0));
    jCols = JsonArrayInsert(jCols, NuiRow(jActRow));

    json jRoot = NuiCol(jCols);

    json jNui = NuiWindow(jRoot,
        JsonString(""),            // no native title bar text (custom title in layout)
        NuiRect(-1.0, -1.0, fW, fH),
        JsonBool(FALSE),           // resizable
        JsonBool(FALSE),           // collapsed
        JsonBool(FALSE),           // closable (hide engine X button)
        JsonBool(FALSE),           // transparent
        JsonBool(TRUE));           // border (draggable title area)

    int nToken = NuiCreate(oPC, jNui, SIN_WINDOW, SIN_EV_SCRIPT);
    SinFeedWindow(oPC, nToken);
}

// ================================================================
// NUI — feed binds from current DB state
// ================================================================

void SinFeedWindow(object oPC, int nToken)
{
    int nScore    = SinGetScore(oPC);
    int bEmbraced = SinIsEmbraced(oPC);

    // Progress gauge (0.0 - 1.0)
    float fGauge = IntToFloat(nScore) / IntToFloat(SIN_MAX);
    if (fGauge > 1.0) fGauge = 1.0;
    NuiSetBind(oPC, nToken, SIN_BIND_GAUGE, JsonFloat(fGauge));

    // Status line
    string sLevel = SinLevelName(nScore);
    if (bEmbraced) sLevel = sLevel + "  [Mroczne Objęcie]";
    NuiSetBind(oPC, nToken, SIN_BIND_STATUS_LBL,
        JsonString(sLevel + "  —  " + IntToString(nScore) + " / " + IntToString(SIN_MAX)));
    NuiSetBind(oPC, nToken, SIN_BIND_STATUS_COL, SinLevelColor(nScore));

    // Penalty label
    NuiSetBind(oPC, nToken, SIN_BIND_PENALTY_LBL,
        JsonString("Kary: " + SinGetPenaltyDesc(nScore)));

    // Absolucja button
    int nCost = SinCalcAbsolveCost(nScore);
    NuiSetBind(oPC, nToken, SIN_BIND_ABS_LBL,
        JsonString("Absolucja (" + IntToString(nCost) + " sz)"));
    NuiSetBind(oPC, nToken, SIN_BIND_ABS_ENA,
        JsonBool(nScore > 0 && !bEmbraced));

    // Mroczne Objęcie button
    NuiSetBind(oPC, nToken, SIN_BIND_EMB_LBL,
        JsonString(bEmbraced ? "Mroczne Objęcie (aktywne)" : "Mroczne Objęcie"));
    NuiSetBind(oPC, nToken, SIN_BIND_EMB_ENA,
        JsonBool(!bEmbraced && nScore >= SIN_EMBRACE_MIN));

    // Sin log list data
    json jLog    = SinGetLog(oPC, SIN_LOG_LIMIT);
    int  nCount  = JsonGetLength(jLog);

    json jTypes  = JsonArray();
    json jDescs  = JsonArray();
    json jAmts   = JsonArray();
    json jColors = JsonArray();

    int i;
    for (i = 0; i < nCount; i++)
    {
        json   jRow  = JsonArrayGet(jLog, i);
        int    nType = JsonGetInt(JsonObjectGet(jRow, "sin_type"));
        int    nAmt  = JsonGetInt(JsonObjectGet(jRow, "amount"));
        string sDesc = JsonGetString(JsonObjectGet(jRow, "description"));

        jTypes  = JsonArrayInsert(jTypes,  JsonString(SinTypeName(nType)));
        jDescs  = JsonArrayInsert(jDescs,  JsonString(sDesc));
        jAmts   = JsonArrayInsert(jAmts,   JsonString("+" + IntToString(nAmt)));
        jColors = JsonArrayInsert(jColors, SinTypeColor(nType));
    }

    NuiSetBind(oPC, nToken, SIN_BIND_ROW_COUNT, JsonInt(nCount));
    NuiSetBind(oPC, nToken, SIN_BIND_ROW_TYPE,  jTypes);
    NuiSetBind(oPC, nToken, SIN_BIND_ROW_DESC,  jDescs);
    NuiSetBind(oPC, nToken, SIN_BIND_ROW_AMT,   jAmts);
    NuiSetBind(oPC, nToken, SIN_BIND_ROW_COLOR, jColors);
}
