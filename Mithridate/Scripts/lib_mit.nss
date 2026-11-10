#include "lib_mit_def"

// ----------------------------------------------------------------
// Poison list panel (left side)
// ----------------------------------------------------------------

json MitBuildPoisonList(object oPC)
{
    float fRowH = GetNuiScaleDimension(oPC, 36.0);

    json jNameLbl = NuiLabel(NuiBind(MIT_BIND_ROW_NAME), JsonInt(NUI_HALIGN_LEFT), JsonInt(NUI_VALIGN_MIDDLE));
    jNameLbl = NuiStyleForegroundColor(jNameLbl, NuiBind(MIT_BIND_ROW_COLOR));

    json jLvlLbl = NuiLabel(NuiBind(MIT_BIND_ROW_LEVEL), JsonInt(NUI_HALIGN_RIGHT), JsonInt(NUI_VALIGN_MIDDLE));
    jLvlLbl = NuiWidth(jLvlLbl, GetNuiScaleDimension(oPC, 110.0));
    jLvlLbl = NuiStyleForegroundColor(jLvlLbl, NuiBind(MIT_BIND_ROW_COLOR));

    json jRowInner = JsonArray();
    jRowInner = JsonArrayInsert(jRowInner, jNameLbl);
    jRowInner = JsonArrayInsert(jRowInner, jLvlLbl);

    json jCell = NuiGroup(NuiRow(jRowInner), TRUE, NUI_SCROLLBARS_NONE);
    jCell = NuiId(jCell, MIT_BTN_ROW);
    jCell = NuiEncouraged(jCell, NuiBind(MIT_BIND_ROW_ENC));

    json jTmpl = JsonArrayInsert(JsonArray(), NuiListTemplateCell(jCell, 0.0, TRUE));

    float fListH = GetNuiScaleDimension(oPC, 410.0);
    json jList = NuiList(jTmpl, JsonInt(MIT_POISON_COUNT), fRowH);
    jList = NuiHeight(jList, fListH);

    return NuiCol(JsonArrayInsert(JsonArray(), jList));
}

// ----------------------------------------------------------------
// Detail panel (right side)
// ----------------------------------------------------------------

json MitBuildDetailPanel(object oPC)
{
    float fBtnH  = GetNuiScaleDimension(oPC, 32.0);
    float fLblW  = GetNuiScaleDimension(oPC, 130.0);
    float fDescH = GetNuiScaleDimension(oPC, 80.0);

    json jName = NuiLabel(NuiBind(MIT_BIND_DET_NAME), JsonInt(NUI_HALIGN_CENTER), JsonInt(NUI_VALIGN_MIDDLE));
    jName = NuiStyleForegroundColor(jName, NuiColor(220, 190, 130));
    jName = NuiHeight(jName, GetNuiScaleDimension(oPC, 30.0));

    json jDesc = NuiGroup(NuiText(NuiBind(MIT_BIND_DET_DESC), FALSE), TRUE, NUI_SCROLLBARS_NONE);
    jDesc = NuiHeight(jDesc, fDescH);

    // Helper: label+value row
    // DC
    json jDcL = NuiWidth(NuiLabel(JsonString("Trudność (DC):"), JsonInt(NUI_HALIGN_LEFT), JsonInt(NUI_VALIGN_MIDDLE)), fLblW);
    json jDcV = NuiLabel(NuiBind(MIT_BIND_DET_DC), JsonInt(NUI_HALIGN_LEFT), JsonInt(NUI_VALIGN_MIDDLE));
    json jDcRow = NuiRow(JsonArrayInsert(JsonArrayInsert(JsonArray(), jDcL), jDcV));

    // Success doses
    json jDsL = NuiWidth(NuiLabel(JsonString("Dawki (sukces/ogółem):"), JsonInt(NUI_HALIGN_LEFT), JsonInt(NUI_VALIGN_MIDDLE)), fLblW);
    json jDsV = NuiLabel(NuiBind(MIT_BIND_DET_DOSES), JsonInt(NUI_HALIGN_LEFT), JsonInt(NUI_VALIGN_MIDDLE));
    json jDsRow = NuiRow(JsonArrayInsert(JsonArrayInsert(JsonArray(), jDsL), jDsV));

    // Overdoses
    json jOdL = NuiWidth(NuiLabel(JsonString("Przedawkowania:"), JsonInt(NUI_HALIGN_LEFT), JsonInt(NUI_VALIGN_MIDDLE)), fLblW);
    json jOdV = NuiLabel(NuiBind(MIT_BIND_DET_OD), JsonInt(NUI_HALIGN_LEFT), JsonInt(NUI_VALIGN_MIDDLE));
    jOdV = NuiStyleForegroundColor(jOdV, NuiColor(200, 100, 100));
    json jOdRow = NuiRow(JsonArrayInsert(JsonArrayInsert(JsonArray(), jOdL), jOdV));

    // Current buff
    json jBfL = NuiWidth(NuiLabel(JsonString("Efekt odporności:"), JsonInt(NUI_HALIGN_LEFT), JsonInt(NUI_VALIGN_MIDDLE)), fLblW);
    json jBfV = NuiLabel(NuiBind(MIT_BIND_DET_LVLBUF), JsonInt(NUI_HALIGN_LEFT), JsonInt(NUI_VALIGN_MIDDLE));
    jBfV = NuiStyleForegroundColor(jBfV, NuiColor(100, 200, 100));
    json jBfRow = NuiRow(JsonArrayInsert(JsonArrayInsert(JsonArray(), jBfL), jBfV));

    // Next level requirement
    json jNxL = NuiWidth(NuiLabel(JsonString("Do następnego poziomu:"), JsonInt(NUI_HALIGN_LEFT), JsonInt(NUI_VALIGN_MIDDLE)), fLblW);
    json jNxV = NuiLabel(NuiBind(MIT_BIND_DET_NEXT), JsonInt(NUI_HALIGN_LEFT), JsonInt(NUI_VALIGN_MIDDLE));
    json jNxRow = NuiRow(JsonArrayInsert(JsonArrayInsert(JsonArray(), jNxL), jNxV));

    // Cooldown
    json jCdL = NuiWidth(NuiLabel(JsonString("Następna dawka za:"), JsonInt(NUI_HALIGN_LEFT), JsonInt(NUI_VALIGN_MIDDLE)), fLblW);
    json jCdV = NuiLabel(NuiBind(MIT_BIND_DET_CD), JsonInt(NUI_HALIGN_LEFT), JsonInt(NUI_VALIGN_MIDDLE));
    jCdV = NuiStyleForegroundColor(jCdV, NuiColor(200, 160, 80));
    json jCdRow = NuiRow(JsonArrayInsert(JsonArrayInsert(JsonArray(), jCdL), jCdV));

    // Buttons
    json jDoseBtn = NuiButton(NuiBind(MIT_BIND_DOSE_LBL));
    jDoseBtn = NuiId(jDoseBtn, MIT_BTN_DOSE);
    jDoseBtn = NuiEnabled(jDoseBtn, NuiBind(MIT_BIND_DOSE_ENA));
    jDoseBtn = NuiHeight(jDoseBtn, fBtnH);

    json jAntiBtn = NuiButton(JsonString("Sporządź antidotum (" + IntToString(MIT_ANTIDOTE_COST) + " sz)"));
    jAntiBtn = NuiId(jAntiBtn, MIT_BTN_ANTIDOTE);
    jAntiBtn = NuiEnabled(jAntiBtn, NuiBind(MIT_BIND_ANTI_ENA));
    jAntiBtn = NuiHeight(jAntiBtn, fBtnH);

    json jBtnRow = JsonArray();
    jBtnRow = JsonArrayInsert(jBtnRow, jDoseBtn);
    jBtnRow = JsonArrayInsert(jBtnRow, NuiSpacer());
    jBtnRow = JsonArrayInsert(jBtnRow, jAntiBtn);

    json jCol = JsonArray();
    jCol = JsonArrayInsert(jCol, jName);
    jCol = JsonArrayInsert(jCol, jDesc);
    jCol = JsonArrayInsert(jCol, jDcRow);
    jCol = JsonArrayInsert(jCol, jDsRow);
    jCol = JsonArrayInsert(jCol, jOdRow);
    jCol = JsonArrayInsert(jCol, jBfRow);
    jCol = JsonArrayInsert(jCol, jNxRow);
    jCol = JsonArrayInsert(jCol, jCdRow);
    jCol = JsonArrayInsert(jCol, NuiSpacer());
    jCol = JsonArrayInsert(jCol, NuiRow(jBtnRow));

    return NuiCol(jCol);
}

// ----------------------------------------------------------------
// Window create
// ----------------------------------------------------------------

void MitShowWindow(object oPC)
{
    if(NuiFindWindow(oPC, MIT_WINDOW) != 0)
    {
        int nToken = NuiFindWindow(oPC, MIT_WINDOW);
        int nSel   = GetLocalInt(oPC, MIT_LVAR_SEL);
        MitFeedPoisons(oPC, nToken);
        MitFeedDetail(oPC, nToken, nSel);
        return;
    }

    float fCX = (IntToFloat(GetPlayerDeviceProperty(oPC, PLAYER_DEVICE_PROPERTY_GUI_WIDTH))
                 - GetNuiScaleDimension(oPC, MIT_W)) / 2.0;
    float fCY = (IntToFloat(GetPlayerDeviceProperty(oPC, PLAYER_DEVICE_PROPERTY_GUI_HEIGHT))
                 - GetNuiScaleDimension(oPC, MIT_H)) / 2.0;
    json jGeom = NuiRect(fCX, fCY, GetNuiScaleDimension(oPC, MIT_W), GetNuiScaleDimension(oPC, MIT_H));

    // Top bar
    float fBtnH = GetNuiScaleDimension(oPC, 30.0);
    json jClose  = NuiButton(JsonString("X"));
    jClose = NuiId(jClose, MIT_BTN_CLOSE);
    jClose = NuiWidth(jClose, GetNuiScaleDimension(oPC, 30.0));
    jClose = NuiHeight(jClose, fBtnH);
    json jTopBar = JsonArray();
    jTopBar = JsonArrayInsert(jTopBar, NuiSpacer());
    jTopBar = JsonArrayInsert(jTopBar, jClose);

    // Left column: poison list
    float fListW = GetNuiScaleDimension(oPC, 240.0);
    json jLeft = NuiWidth(MitBuildPoisonList(oPC), fListW);

    // Divider spacer
    json jDiv = NuiWidth(NuiCol(JsonArrayInsert(JsonArray(), NuiSpacer())), GetNuiScaleDimension(oPC, 10.0));

    // Right column: detail panel
    json jRight = MitBuildDetailPanel(oPC);

    json jBodyRow = JsonArray();
    jBodyRow = JsonArrayInsert(jBodyRow, jLeft);
    jBodyRow = JsonArrayInsert(jBodyRow, jDiv);
    jBodyRow = JsonArrayInsert(jBodyRow, jRight);

    json jRoot = JsonArray();
    jRoot = JsonArrayInsert(jRoot, NuiRow(jTopBar));
    jRoot = JsonArrayInsert(jRoot, NuiRow(jBodyRow));

    json jWin = NuiWindow(NuiCol(jRoot),
        JsonString("Mithridatyzacja — Stół Aptekarza"),
        NuiBind(MIT_WIN_GEOM),
        JsonBool(FALSE),
        JsonBool(FALSE),
        JsonBool(TRUE),
        JsonBool(TRUE),
        JsonBool(FALSE));

    int nToken = NuiCreate(oPC, jWin, MIT_WINDOW, MIT_EV_SCRIPT);
    NuiSetBind(oPC, nToken, MIT_WIN_GEOM, jGeom);

    SetLocalInt(oPC, MIT_LVAR_SEL, 0);
    MitFeedPoisons(oPC, nToken);
    MitFeedDetail(oPC, nToken, 0);
}

// ----------------------------------------------------------------
// Feed: list of all poisons
// ----------------------------------------------------------------

void MitFeedPoisons(object oPC, int nToken)
{
    json jAll    = MitGetAllTolerances(oPC);
    int  nSel    = GetLocalInt(oPC, MIT_LVAR_SEL);

    json jNames  = JsonArray();
    json jLevels = JsonArray();
    json jEncs   = JsonArray();
    json jColors = JsonArray();

    int i;
    for(i = 0; i < MIT_POISON_COUNT; i++)
    {
        json jRow = JsonArrayGet(jAll, i);
        int nTol  = JsonGetInt(JsonObjectGet(jRow, "tolerance"));

        jNames  = JsonArrayInsert(jNames,  JsonString(MitGetPoisonName(i)));
        jLevels = JsonArrayInsert(jLevels, JsonString(MitGetLevelName(nTol)));
        jEncs   = JsonArrayInsert(jEncs,   JsonBool(i == nSel));

        json jColor;
        if(nTol == 0) jColor = NuiColor(170, 170, 170);
        else if(nTol == 1) jColor = NuiColor(200, 220, 150);
        else if(nTol == 2) jColor = NuiColor(150, 220, 150);
        else if(nTol == 3) jColor = NuiColor(100, 210, 100);
        else               jColor = NuiColor(80,  255, 80);

        jColors = JsonArrayInsert(jColors, jColor);
    }

    NuiSetBind(oPC, nToken, MIT_BIND_ROW_NAME,  jNames);
    NuiSetBind(oPC, nToken, MIT_BIND_ROW_LEVEL, jLevels);
    NuiSetBind(oPC, nToken, MIT_BIND_ROW_ENC,   jEncs);
    NuiSetBind(oPC, nToken, MIT_BIND_ROW_COLOR, jColors);
}

// ----------------------------------------------------------------
// Feed: detail panel for one poison
// ----------------------------------------------------------------

void MitFeedDetail(object oPC, int nToken, int nPoisonId)
{
    json jRow     = MitGetTolerance(oPC, nPoisonId);
    int nTol      = JsonGetInt(JsonObjectGet(jRow, "tolerance"));
    int nSucDoses = JsonGetInt(JsonObjectGet(jRow, "success_doses"));
    int nTotDoses = JsonGetInt(JsonObjectGet(jRow, "total_doses"));
    int nOd       = JsonGetInt(JsonObjectGet(jRow, "overdoses"));
    int nDC       = MitGetPoisonDC(nPoisonId);
    int nCd       = MitGetCooldownRemaining(oPC, nPoisonId);

    string sNext;
    if(nTol >= MIT_MAX_LEVEL)
        sNext = "— maksimum osiągnięte —";
    else
    {
        int nNeeded = MitDosesForLevel(nTol + 1) - nSucDoses;
        if(nNeeded < 0) nNeeded = 0;
        sNext = IntToString(nNeeded) + " udanych dawek";
    }

    string sCd;
    if(nCd <= 0)
        sCd = "Gotowy";
    else
    {
        int nMin = nCd / 60;
        int nSec = nCd % 60;
        sCd = IntToString(nMin) + " min " + IntToString(nSec) + " sek";
    }

    int bDoseEna = (nCd <= 0 && nTol < MIT_MAX_LEVEL);
    string sDoseLbl = "Zażyj dawkę (" + IntToString(MIT_DOSE_COST) + " sz)";

    NuiSetBind(oPC, nToken, MIT_BIND_DET_NAME,   JsonString(MitGetPoisonName(nPoisonId)));
    NuiSetBind(oPC, nToken, MIT_BIND_DET_DESC,   JsonString(MitGetPoisonDesc(nPoisonId)));
    NuiSetBind(oPC, nToken, MIT_BIND_DET_DC,     JsonString(IntToString(nDC)));
    NuiSetBind(oPC, nToken, MIT_BIND_DET_DOSES,  JsonString(IntToString(nSucDoses) + " / " + IntToString(nTotDoses)));
    NuiSetBind(oPC, nToken, MIT_BIND_DET_OD,     JsonString(IntToString(nOd)));
    NuiSetBind(oPC, nToken, MIT_BIND_DET_LVLBUF, JsonString(MitGetLevelBuffDesc(nTol)));
    NuiSetBind(oPC, nToken, MIT_BIND_DET_NEXT,   JsonString(sNext));
    NuiSetBind(oPC, nToken, MIT_BIND_DET_CD,     JsonString(sCd));
    NuiSetBind(oPC, nToken, MIT_BIND_DOSE_ENA,   JsonBool(bDoseEna));
    NuiSetBind(oPC, nToken, MIT_BIND_DOSE_LBL,   JsonString(sDoseLbl));
    NuiSetBind(oPC, nToken, MIT_BIND_ANTI_ENA,   JsonBool(nTol >= 3));
}

// ----------------------------------------------------------------
// Dose mechanic
// ----------------------------------------------------------------

void MitTakeDose(object oPC, int nToken, int nPoisonId)
{
    if(GetGold(oPC) < MIT_DOSE_COST)
    {
        SendMessageToPC(oPC, "[Mithridatyzacja] Brakuje złota. Potrzebujesz " + IntToString(MIT_DOSE_COST) + " sz za kontrolowaną dawkę.");
        return;
    }

    int nCd = MitGetCooldownRemaining(oPC, nPoisonId);
    if(nCd > 0)
    {
        int nMin = nCd / 60;
        SendMessageToPC(oPC, "[Mithridatyzacja] Organizm potrzebuje więcej czasu. Poczekaj jeszcze około " + IntToString(nMin + 1) + " minut.");
        return;
    }

    json jRow = MitGetTolerance(oPC, nPoisonId);
    int nTol  = JsonGetInt(JsonObjectGet(jRow, "tolerance"));

    if(nTol >= MIT_MAX_LEVEL)
    {
        SendMessageToPC(oPC, "[Mithridatyzacja] Osiągnąłeś pełną odporność. Dalsze dawki są zbędne.");
        return;
    }

    AssignCommand(oPC, TakeGoldFromCreature(MIT_DOSE_COST, oPC, TRUE));

    int nDC        = MitGetPoisonDC(nPoisonId);
    int nFortMod   = GetFortitudeSavingThrow(oPC);
    int nRoll      = d20();
    int nTotal     = nRoll + nFortMod;
    int bNatOne    = (nRoll == 1);
    int bOverdose  = bNatOne || (nTotal <= nDC - 8);
    int bSuccess   = (!bNatOne) && (nTotal >= nDC);

    int nSucDoses  = JsonGetInt(JsonObjectGet(jRow, "success_doses"));

    if(bOverdose)
    {
        int nDmg = d8() + d8();
        ApplyEffectToObject(DURATION_TYPE_INSTANT, EffectDamage(nDmg, DAMAGE_TYPE_POISON), oPC);
        MitUpsertDoseResult(oPC, nPoisonId, FALSE, TRUE);

        if(nTol > 0)
        {
            int nNewTol = nTol - 1;
            MitSetTolerance(oPC, nPoisonId, nNewTol);
            // Reset success doses to the floor of the new level so the PC must rebuild
            MitSetSuccessDoses(oPC, nPoisonId, MitDosesForLevel(nNewTol));
            MitApplyTolerance(oPC);
            SendMessageToPC(oPC, "[Mithridatyzacja] Przedawkowanie! Tracisz " + IntToString(nDmg) + " KP. Ciało odrzuca truciznę — odporność spada do poziomu: " + MitGetLevelName(nNewTol) + ".");
        }
        else
        {
            SendMessageToPC(oPC, "[Mithridatyzacja] Przedawkowanie! Tracisz " + IntToString(nDmg) + " KP. Trucizna rozlewa się boleśnie po żyłach.");
        }
        FloatingTextStringOnCreature("Przedawkowanie!", oPC, FALSE);
    }
    else if(bSuccess)
    {
        int nDmg   = d4();
        ApplyEffectToObject(DURATION_TYPE_INSTANT, EffectDamage(nDmg, DAMAGE_TYPE_POISON), oPC);
        MitUpsertDoseResult(oPC, nPoisonId, TRUE, FALSE);

        int nNewSuc   = nSucDoses + 1;
        int nNextLvl  = nTol + 1;
        if(nNewSuc >= MitDosesForLevel(nNextLvl))
        {
            MitSetTolerance(oPC, nPoisonId, nNextLvl);
            MitApplyTolerance(oPC);
            SendMessageToPC(oPC, "[Mithridatyzacja] Organizm przystosowuje się. Odporność na " + MitGetPoisonName(nPoisonId) + " wzrasta: " + MitGetLevelName(nNextLvl) + ".");
            FloatingTextStringOnCreature("Odporność wzrasta!", oPC, FALSE);
        }
        else
        {
            int nLeft = MitDosesForLevel(nNextLvl) - nNewSuc;
            SendMessageToPC(oPC, "[Mithridatyzacja] Dawka wchłonięta. Tracisz " + IntToString(nDmg) + " KP. Jeszcze " + IntToString(nLeft) + " skutecznych dawek do następnego poziomu.");
        }
    }
    else
    {
        // Failed save but not severe enough for overdose
        int nDmg = d6();
        ApplyEffectToObject(DURATION_TYPE_INSTANT, EffectDamage(nDmg, DAMAGE_TYPE_POISON), oPC);
        MitUpsertDoseResult(oPC, nPoisonId, FALSE, FALSE);
        SendMessageToPC(oPC, "[Mithridatyzacja] Organizm walczy z trucizną. Tracisz " + IntToString(nDmg) + " KP. Bez postępu tym razem.");
    }

    MitFeedPoisons(oPC, nToken);
    MitFeedDetail(oPC, nToken, nPoisonId);
}

// ----------------------------------------------------------------
// Antidote crafting (requires tolerance level 3+)
// ----------------------------------------------------------------

void MitCraftAntidote(object oPC, int nToken, int nPoisonId)
{
    json jRow = MitGetTolerance(oPC, nPoisonId);
    int nTol  = JsonGetInt(JsonObjectGet(jRow, "tolerance"));

    if(nTol < 3)
    {
        SendMessageToPC(oPC, "[Mithridatyzacja] Potrzebujesz silnej odporności, by sporządzić antidotum. Osiągnij najpierw poziom trzeci.");
        return;
    }

    if(GetGold(oPC) < MIT_ANTIDOTE_COST)
    {
        SendMessageToPC(oPC, "[Mithridatyzacja] Za mało złota na składniki. Potrzebujesz " + IntToString(MIT_ANTIDOTE_COST) + " sz.");
        return;
    }

    AssignCommand(oPC, TakeGoldFromCreature(MIT_ANTIDOTE_COST, oPC, TRUE));

    // nw_it_mpotion015 is a standard "Neutralize Poison" potion placeholder.
    // Replace with a module-specific resref if added to the hak.
    object oAntidote = CreateItemOnObject("nw_it_mpotion015", oPC, 1);
    if(GetIsObjectValid(oAntidote))
    {
        SetName(oAntidote, "Antidotum: " + MitGetPoisonName(nPoisonId));
        SetDescription(oAntidote, "Sporządzone przez " + GetName(oPC) +
            " na podstawie nabytej odporności na " + MitGetPoisonName(nPoisonId) +
            ". Biegłość aptekarza przebija każdy inny specyfik.");
        SetLocalInt(oAntidote, "MIT_ANTIDOTE_POISON_ID", nPoisonId);
    }

    SendMessageToPC(oPC, "[Mithridatyzacja] Antidotum sporządzone. Sprawdź ekwipunek.");
    MitFeedDetail(oPC, nToken, nPoisonId);
}

// ----------------------------------------------------------------
// Apply tolerance effects to PC
// Applies the highest earned save bonus as a permanent Fort/Poison buff.
// Called on enter and after every tolerance change.
// ----------------------------------------------------------------

void MitApplyTolerance(object oPC)
{
    // Safe removal: restart iterator after each RemoveEffect
    effect eEff = GetFirstEffect(oPC);
    while(GetIsEffectValid(eEff))
    {
        if(GetEffectTag(eEff) == "MIT_TOL")
        {
            RemoveEffect(oPC, eEff);
            eEff = GetFirstEffect(oPC);
        }
        else
            eEff = GetNextEffect(oPC);
    }

    json jAll     = MitGetAllTolerances(oPC);
    int nMaxBonus = 0;
    int i;
    for(i = 0; i < MIT_POISON_COUNT; i++)
    {
        int nTol   = JsonGetInt(JsonObjectGet(JsonArrayGet(jAll, i), "tolerance"));
        int nBonus = MitGetSaveBonus(nTol);
        if(nBonus > nMaxBonus) nMaxBonus = nBonus;
    }

    if(nMaxBonus > 0)
    {
        effect eBuff = EffectSavingThrowIncrease(SAVING_THROW_FORT, nMaxBonus, SAVING_THROW_TYPE_POISON);
        eBuff = TagEffect(eBuff, "MIT_TOL");
        eBuff = SupernaturalEffect(eBuff);
        ApplyEffectToObject(DURATION_TYPE_PERMANENT, eBuff, oPC);
    }
}
