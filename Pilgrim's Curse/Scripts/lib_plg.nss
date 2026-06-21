#include "lib_plg_def"

// ----------------------------------------------------------------
// Helpers
// ----------------------------------------------------------------

string PlgBurdenTypeLabel(string sType)
{
    if(sType == "shadow") return "Cień";
    if(sType == "blood")  return "Krew";
    if(sType == "death")  return "Śmierć";
    if(sType == "chaos")  return "Chaos";
    return sType;
}

string PlgGetTierName(int nTotal)
{
    if(nTotal >= PLG_TIER_4) return "Piętno Potępionego";
    if(nTotal >= PLG_TIER_3) return "Ciężkie Brzemię";
    if(nTotal >= PLG_TIER_2) return "Umiarkowane Brzemię";
    if(nTotal >= PLG_TIER_1) return "Lekkie Brzemię";
    return "Nieoznaczony";
}

string PlgGetEffectSummary(int nTotal)
{
    if(nTotal == 0)
        return "Brak efektów. Nieskażony jeszcze ciemnością.";

    string s = "";
    if(nTotal >= PLG_TIER_1)
        s = s + "+ Siła +1\n";
    if(nTotal >= PLG_TIER_2)
        s = s + "+ Siła +2, Odporność na Strach, Widzenie w Ciemności\n";
    if(nTotal >= PLG_TIER_3)
        s = s + "+ Budowa +2, Odporność na Chorobę\n";
    if(nTotal >= PLG_TIER_4)
        s = s + "+ Budowa +3, Odporność na Truciznę i Paraliż\n"
              + "— Charyzma -4 (oblicze wzbudza odrazę)\n";
    return s;
}

int PlgGetCatharsisCost(int nTotal)
{
    return nTotal * 500;
}

// ----------------------------------------------------------------
// Burden effect management
// ----------------------------------------------------------------

void PlgRemoveBurdenEffects(object oPC)
{
    effect eEff = GetFirstEffect(oPC);
    while(GetIsEffectValid(eEff))
    {
        if(GetEffectTag(eEff) == PLG_FX_TAG)
            RemoveEffect(oPC, eEff);
        eEff = GetNextEffect(oPC);
    }
}

void PlgApplyBurdenEffects(object oPC)
{
    PlgRemoveBurdenEffects(oPC);

    json jP = PlgGetPilgrim(oPC);
    if(JsonGetType(jP) == JSON_TYPE_NULL) return;

    int nTotal = JsonGetInt(JsonObjectGet(jP, "burden_shadow"))
               + JsonGetInt(JsonObjectGet(jP, "burden_blood"))
               + JsonGetInt(JsonObjectGet(jP, "burden_death"))
               + JsonGetInt(JsonObjectGet(jP, "burden_chaos"));

    if(nTotal < PLG_TIER_1) return;

    // Tier 1: STR +1
    effect eS1 = TagEffect(SupernaturalEffect(EffectAbilityIncrease(ABILITY_STRENGTH, 1)), PLG_FX_TAG);
    ApplyEffectToCreature(oPC, eS1, DURATION_TYPE_PERMANENT, 0.0);

    if(nTotal >= PLG_TIER_2)
    {
        // Extra STR +1 (cumulative → +2 total), fear immunity, ultravision
        effect eS2 = TagEffect(SupernaturalEffect(EffectAbilityIncrease(ABILITY_STRENGTH, 1)), PLG_FX_TAG);
        ApplyEffectToCreature(oPC, eS2, DURATION_TYPE_PERMANENT, 0.0);

        effect eFear = TagEffect(SupernaturalEffect(EffectImmunity(IMMUNITY_TYPE_FEAR)), PLG_FX_TAG);
        ApplyEffectToCreature(oPC, eFear, DURATION_TYPE_PERMANENT, 0.0);

        effect eUV = TagEffect(SupernaturalEffect(EffectUltravision()), PLG_FX_TAG);
        ApplyEffectToCreature(oPC, eUV, DURATION_TYPE_PERMANENT, 0.0);
    }

    if(nTotal >= PLG_TIER_3)
    {
        effect eCon = TagEffect(SupernaturalEffect(EffectAbilityIncrease(ABILITY_CONSTITUTION, 2)), PLG_FX_TAG);
        ApplyEffectToCreature(oPC, eCon, DURATION_TYPE_PERMANENT, 0.0);

        effect eDis = TagEffect(SupernaturalEffect(EffectImmunity(IMMUNITY_TYPE_DISEASE)), PLG_FX_TAG);
        ApplyEffectToCreature(oPC, eDis, DURATION_TYPE_PERMANENT, 0.0);
    }

    if(nTotal >= PLG_TIER_4)
    {
        // CON +1 more (→ +3 total), poison + paralysis immunity, CHA -4
        effect eCon2 = TagEffect(SupernaturalEffect(EffectAbilityIncrease(ABILITY_CONSTITUTION, 1)), PLG_FX_TAG);
        ApplyEffectToCreature(oPC, eCon2, DURATION_TYPE_PERMANENT, 0.0);

        effect ePoison = TagEffect(SupernaturalEffect(EffectImmunity(IMMUNITY_TYPE_POISON)), PLG_FX_TAG);
        ApplyEffectToCreature(oPC, ePoison, DURATION_TYPE_PERMANENT, 0.0);

        effect ePar = TagEffect(SupernaturalEffect(EffectImmunity(IMMUNITY_TYPE_PARALYSIS)), PLG_FX_TAG);
        ApplyEffectToCreature(oPC, ePar, DURATION_TYPE_PERMANENT, 0.0);

        // The price of the Damned's visage.
        effect eCha = TagEffect(SupernaturalEffect(EffectAbilityDecrease(ABILITY_CHARISMA, 4)), PLG_FX_TAG);
        ApplyEffectToCreature(oPC, eCha, DURATION_TYPE_PERMANENT, 0.0);
    }
}

// ----------------------------------------------------------------
// Shrine interaction logic
// ----------------------------------------------------------------

void PlgHandleShrine(object oPC, object oShrine)
{
    string sTag = GetTag(oShrine);

    // ---- Catharsis altar ----
    if(sTag == PLG_CATHARSIS_TAG)
    {
        json jP = PlgGetPilgrim(oPC);
        if(JsonGetType(jP) == JSON_TYPE_NULL)
        {
            SendMessageToPC(oPC, "[Pielgrzymka] Nie jesteś zapisany — wejdź do modułu ponownie.");
            return;
        }
        int nShadow = JsonGetInt(JsonObjectGet(jP, "burden_shadow"));
        int nBlood  = JsonGetInt(JsonObjectGet(jP, "burden_blood"));
        int nDeath  = JsonGetInt(JsonObjectGet(jP, "burden_death"));
        int nChaos  = JsonGetInt(JsonObjectGet(jP, "burden_chaos"));
        int nTotal  = nShadow + nBlood + nDeath + nChaos;

        if(nTotal <= 0)
        {
            SendMessageToPC(oPC, "[Pielgrzymka] Nie nosisz żadnego brzemienia — Katharsis zbędna.");
            return;
        }
        int nCost = PlgGetCatharsisCost(nTotal);
        if(GetGold(oPC) < nCost)
        {
            SendMessageToPC(oPC, "[Pielgrzymka] Katharsis kosztuje " + IntToString(nCost)
                + " złota. Nie stać cię na oczyszczenie.");
            return;
        }

        TakeGoldFromCreature(nCost, oPC, TRUE);
        PlgPerformCatharsis(oPC);
        PlgRemoveBurdenEffects(oPC);

        // Penance: body pays after spirit is cleansed.
        effect ePen1 = EffectAbilityDecrease(ABILITY_STRENGTH, 2);
        effect ePen2 = EffectAbilityDecrease(ABILITY_CONSTITUTION, 2);
        ApplyEffectToCreature(oPC, ePen1, DURATION_TYPE_TEMPORARY, 3600.0);
        ApplyEffectToCreature(oPC, ePen2, DURATION_TYPE_TEMPORARY, 3600.0);

        FloatingTextStringOnCreature(
            "Brzemię spłynęło z twoich ramion... lecz ciało płaci cenę.", oPC, FALSE);
        SendMessageToPC(oPC, "[Pielgrzymka] Katharsis dokonana. Zapłacono "
            + IntToString(nCost) + " złota. Kara ciała potrwa godzinę.");

        // Refresh UI if open.
        int nToken = NuiFindWindow(oPC, PLG_WINDOW);
        if(nToken != 0) PlgFeedStatus(oPC, nToken);
        return;
    }

    // ---- Regular shrine ----
    int nShrineId = PlgGetShrineId(sTag);
    if(nShrineId < 0)
    {
        SendMessageToPC(oPC, "[Pielgrzymka] To sanktuarium nie jest zarejestrowane w systemie.");
        return;
    }

    json jShrine = PlgGetShrine(nShrineId);
    string sType = JsonGetString(JsonObjectGet(jShrine, "burden_type"));
    int nVal     = JsonGetInt(JsonObjectGet(jShrine, "burden_val"));

    int bAlreadyVisited = PlgHasVisited(oPC, nShrineId);

    if(!bAlreadyVisited)
    {
        PlgRecordVisit(oPC, nShrineId, sType, nVal);
        PlgApplyBurdenEffects(oPC);

        if(PlgCheckCircuitCompletion(oPC))
        {
            PlgIncrementCircuits(oPC);
            PlgResetVisits(oPC);
            FloatingTextStringOnCreature(
                "Krąg pielgrzymki zamknięty. Brzemię twoich grzechów rośnie niepomiernie.", oPC, FALSE);
            SendMessageToPC(oPC, "[Pielgrzymka] Wszystkie sanktuaria odwiedzone. Obieg zamknięty.");
        }
        else
        {
            FloatingTextStringOnCreature(
                "Sanktuarium przyjmuje twą ofiarę... brzemię ciężeje.", oPC, FALSE);
        }
    }
    else
    {
        SendMessageToPC(oPC, "[Pielgrzymka] Już oddałeś hołd temu sanktuarium w tym obiegu.");
    }

    PlgShowShrinePopup(oPC, nShrineId, bAlreadyVisited);
}

// ----------------------------------------------------------------
// Shrine info popup
// ----------------------------------------------------------------

void PlgShowShrinePopup(object oPC, int nShrineId, int bAlreadyVisited)
{
    if(NuiFindWindow(oPC, PLG_WIN_SHRINE_INFO) != 0)
        NuiDestroy(oPC, NuiFindWindow(oPC, PLG_WIN_SHRINE_INFO));

    json jShrine = PlgGetShrine(nShrineId);
    if(JsonGetType(jShrine) == JSON_TYPE_NULL) return;

    string sName = JsonGetString(JsonObjectGet(jShrine, "name"));
    string sLore = JsonGetString(JsonObjectGet(jShrine, "lore"));
    string sType = JsonGetString(JsonObjectGet(jShrine, "burden_type"));

    float fW = GetNuiScaleDimension(oPC, 460.0);
    float fH = GetNuiScaleDimension(oPC, 290.0);
    float fX = (IntToFloat(GetPlayerDeviceProperty(oPC, PLAYER_DEVICE_PROPERTY_GUI_WIDTH))  - fW) / 2.0;
    float fY = (IntToFloat(GetPlayerDeviceProperty(oPC, PLAYER_DEVICE_PROPERTY_GUI_HEIGHT)) - fH) / 2.0;

    float fBtnH = GetNuiScaleDimension(oPC, 28.0);

    // Title
    json jName = NuiLabel(NuiBind(PLG_BIND_SINFO_NAME),
        JsonInt(NUI_HALIGN_CENTER), JsonInt(NUI_VALIGN_MIDDLE));
    jName = NuiHeight(jName, GetNuiScaleDimension(oPC, 30.0));

    // Type badge
    json jType = NuiLabel(NuiBind(PLG_BIND_SINFO_TYPE),
        JsonInt(NUI_HALIGN_CENTER), JsonInt(NUI_VALIGN_MIDDLE));
    jType = NuiHeight(jType, GetNuiScaleDimension(oPC, 22.0));

    // Lore text area
    json jLore = NuiText(NuiBind(PLG_BIND_SINFO_LORE), FALSE);
    jLore = NuiHeight(jLore, GetNuiScaleDimension(oPC, 130.0));

    // Visit status
    json jStat = NuiLabel(NuiBind(PLG_BIND_SINFO_STAT),
        JsonInt(NUI_HALIGN_CENTER), JsonInt(NUI_VALIGN_MIDDLE));
    jStat = NuiHeight(jStat, GetNuiScaleDimension(oPC, 22.0));

    // Close button
    json jClose = NuiButton(JsonString("Zamknij"));
    jClose = NuiId(jClose, PLG_BTN_SINFO_CLOSE);
    jClose = NuiWidth(jClose, GetNuiScaleDimension(oPC, 100.0));
    jClose = NuiHeight(jClose, fBtnH);

    json jBtnRow = JsonArray();
    jBtnRow = JsonArrayInsert(jBtnRow, NuiSpacer());
    jBtnRow = JsonArrayInsert(jBtnRow, jClose);
    jBtnRow = JsonArrayInsert(jBtnRow, NuiSpacer());

    json jCol = JsonArray();
    jCol = JsonArrayInsert(jCol, jName);
    jCol = JsonArrayInsert(jCol, jType);
    jCol = JsonArrayInsert(jCol, CreateEmptyRow(oPC, 6.0));
    jCol = JsonArrayInsert(jCol, jLore);
    jCol = JsonArrayInsert(jCol, jStat);
    jCol = JsonArrayInsert(jCol, CreateEmptyRow(oPC, 6.0));
    jCol = JsonArrayInsert(jCol, NuiRow(jBtnRow));

    json jWin = NuiWindow(NuiCol(jCol),
        JsonBool(FALSE),
        NuiBind(PLG_BIND_SINFO_GEOM),
        JsonBool(FALSE), JsonBool(FALSE), JsonBool(TRUE),
        JsonBool(FALSE), JsonBool(TRUE));

    int nToken = NuiCreate(oPC, jWin, PLG_WIN_SHRINE_INFO, PLG_EV_SCRIPT);
    NuiSetBind(oPC, nToken, PLG_BIND_SINFO_GEOM, NuiRect(fX, fY, fW, fH));
    NuiSetBind(oPC, nToken, PLG_BIND_SINFO_NAME, JsonString(sName));
    NuiSetBind(oPC, nToken, PLG_BIND_SINFO_TYPE,
        JsonString("[ " + PlgBurdenTypeLabel(sType) + " ]"));
    NuiSetBind(oPC, nToken, PLG_BIND_SINFO_LORE, JsonString(sLore));

    string sStat = bAlreadyVisited
        ? "Odwiedzone w tym obiegu."
        : "Sanktuarium przyjęło twą hołd po raz pierwszy.";
    NuiSetBind(oPC, nToken, PLG_BIND_SINFO_STAT, JsonString(sStat));
}

// ----------------------------------------------------------------
// NUI layout builders
// ----------------------------------------------------------------

json PlgBuildTabBar(object oPC)
{
    float fBtnH = GetNuiScaleDimension(oPC, 28.0);
    float fBtnW = GetNuiScaleDimension(oPC, 140.0);

    json jS = NuiButton(JsonString("Piętno"));
    jS = NuiId(jS, PLG_BTN_TAB_STATUS);
    jS = NuiWidth(jS, fBtnW);
    jS = NuiHeight(jS, fBtnH);

    json jSh = NuiButton(JsonString("Sanktuaria"));
    jSh = NuiId(jSh, PLG_BTN_TAB_SHRINES);
    jSh = NuiWidth(jSh, fBtnW);
    jSh = NuiHeight(jSh, fBtnH);

    json jB = NuiButton(JsonString("Potępieni"));
    jB = NuiId(jB, PLG_BTN_TAB_BOARD);
    jB = NuiWidth(jB, fBtnW);
    jB = NuiHeight(jB, fBtnH);

    json jClose = NuiButton(JsonString("X"));
    jClose = NuiId(jClose, PLG_BTN_CLOSE);
    jClose = NuiWidth(jClose, GetNuiScaleDimension(oPC, 30.0));
    jClose = NuiHeight(jClose, fBtnH);

    json jRow = JsonArray();
    jRow = JsonArrayInsert(jRow, jS);
    jRow = JsonArrayInsert(jRow, jSh);
    jRow = JsonArrayInsert(jRow, jB);
    jRow = JsonArrayInsert(jRow, NuiSpacer());
    jRow = JsonArrayInsert(jRow, jClose);
    return NuiRow(jRow);
}

// ---- Status tab ----

json PlgBuildStatusTab(object oPC)
{
    float fRowH  = GetNuiScaleDimension(oPC, 26.0);
    float fBtnH  = GetNuiScaleDimension(oPC, 30.0);
    float fLblW  = GetNuiScaleDimension(oPC, 100.0);
    float fValW  = GetNuiScaleDimension(oPC, 36.0);

    // Helper: one burden bar row [label | progress | value]
    // Repeats 4 times; uses separate binds per type.
    json jShadowLbl = NuiLabel(JsonString("Cień:"),
        JsonInt(NUI_HALIGN_LEFT), JsonInt(NUI_VALIGN_MIDDLE));
    jShadowLbl = NuiWidth(jShadowLbl, fLblW);

    json jBloodLbl = NuiLabel(JsonString("Krew:"),
        JsonInt(NUI_HALIGN_LEFT), JsonInt(NUI_VALIGN_MIDDLE));
    jBloodLbl = NuiWidth(jBloodLbl, fLblW);

    json jDeathLbl = NuiLabel(JsonString("Śmierć:"),
        JsonInt(NUI_HALIGN_LEFT), JsonInt(NUI_VALIGN_MIDDLE));
    jDeathLbl = NuiWidth(jDeathLbl, fLblW);

    json jChaosLbl = NuiLabel(JsonString("Chaos:"),
        JsonInt(NUI_HALIGN_LEFT), JsonInt(NUI_VALIGN_MIDDLE));
    jChaosLbl = NuiWidth(jChaosLbl, fLblW);

    json jShadowPrg = NuiProgress(NuiBind(PLG_BIND_SHADOW_PRG));
    json jBloodPrg  = NuiProgress(NuiBind(PLG_BIND_BLOOD_PRG));
    json jDeathPrg  = NuiProgress(NuiBind(PLG_BIND_DEATH_PRG));
    json jChaosPrg  = NuiProgress(NuiBind(PLG_BIND_CHAOS_PRG));

    json jShadowVal = NuiLabel(NuiBind(PLG_BIND_SHADOW_VAL),
        JsonInt(NUI_HALIGN_RIGHT), JsonInt(NUI_VALIGN_MIDDLE));
    jShadowVal = NuiWidth(jShadowVal, fValW);

    json jBloodVal = NuiLabel(NuiBind(PLG_BIND_BLOOD_VAL),
        JsonInt(NUI_HALIGN_RIGHT), JsonInt(NUI_VALIGN_MIDDLE));
    jBloodVal = NuiWidth(jBloodVal, fValW);

    json jDeathVal = NuiLabel(NuiBind(PLG_BIND_DEATH_VAL),
        JsonInt(NUI_HALIGN_RIGHT), JsonInt(NUI_VALIGN_MIDDLE));
    jDeathVal = NuiWidth(jDeathVal, fValW);

    json jChaosVal = NuiLabel(NuiBind(PLG_BIND_CHAOS_VAL),
        JsonInt(NUI_HALIGN_RIGHT), JsonInt(NUI_VALIGN_MIDDLE));
    jChaosVal = NuiWidth(jChaosVal, fValW);

    // Row builder macro (inline via json arrays)
    json jSRow = JsonArray();
    jSRow = JsonArrayInsert(jSRow, jShadowLbl);
    jSRow = JsonArrayInsert(jSRow, jShadowPrg);
    jSRow = JsonArrayInsert(jSRow, jShadowVal);

    json jBRow = JsonArray();
    jBRow = JsonArrayInsert(jBRow, jBloodLbl);
    jBRow = JsonArrayInsert(jBRow, jBloodPrg);
    jBRow = JsonArrayInsert(jBRow, jBloodVal);

    json jDRow = JsonArray();
    jDRow = JsonArrayInsert(jDRow, jDeathLbl);
    jDRow = JsonArrayInsert(jDRow, jDeathPrg);
    jDRow = JsonArrayInsert(jDRow, jDeathVal);

    json jCRow = JsonArray();
    jCRow = JsonArrayInsert(jCRow, jChaosLbl);
    jCRow = JsonArrayInsert(jCRow, jChaosPrg);
    jCRow = JsonArrayInsert(jCRow, jChaosVal);

    // Summary labels
    json jTotal = NuiLabel(NuiBind(PLG_BIND_TOTAL_LBL),
        JsonInt(NUI_HALIGN_LEFT), JsonInt(NUI_VALIGN_MIDDLE));
    jTotal = NuiHeight(jTotal, fRowH);

    json jTier = NuiLabel(NuiBind(PLG_BIND_TIER_LBL),
        JsonInt(NUI_HALIGN_LEFT), JsonInt(NUI_VALIGN_MIDDLE));
    jTier = NuiHeight(jTier, fRowH);

    json jVisits = NuiLabel(NuiBind(PLG_BIND_VISITS_LBL),
        JsonInt(NUI_HALIGN_LEFT), JsonInt(NUI_VALIGN_MIDDLE));
    jVisits = NuiHeight(jVisits, fRowH);

    json jCircuits = NuiLabel(NuiBind(PLG_BIND_CIRCUITS_LBL),
        JsonInt(NUI_HALIGN_LEFT), JsonInt(NUI_VALIGN_MIDDLE));
    jCircuits = NuiHeight(jCircuits, fRowH);

    // Active effects text area
    json jFxLbl = NuiLabel(JsonString("Aktywne efekty:"),
        JsonInt(NUI_HALIGN_LEFT), JsonInt(NUI_VALIGN_MIDDLE));
    jFxLbl = NuiHeight(jFxLbl, fRowH);

    json jFxArea = NuiText(NuiBind(PLG_BIND_FX_LBL), FALSE);
    jFxArea = NuiHeight(jFxArea, GetNuiScaleDimension(oPC, 100.0));

    // Catharsis button
    json jKathBtn = NuiButton(NuiBind(PLG_BIND_KATH_LBL));
    jKathBtn = NuiId(jKathBtn, PLG_BTN_CATHARSIS);
    jKathBtn = NuiEnabled(jKathBtn, NuiBind(PLG_BIND_KATH_ENA));
    jKathBtn = NuiTooltip(jKathBtn, NuiBind(PLG_BIND_KATH_TIP));
    jKathBtn = NuiHeight(jKathBtn, fBtnH);

    json jKathRow = JsonArray();
    jKathRow = JsonArrayInsert(jKathRow, NuiSpacer());
    jKathRow = JsonArrayInsert(jKathRow, jKathBtn);
    jKathRow = JsonArrayInsert(jKathRow, NuiSpacer());

    json jCol = JsonArray();
    jCol = JsonArrayInsert(jCol, CreateEmptyRow(oPC, 6.0));
    jCol = JsonArrayInsert(jCol, NuiHeight(NuiRow(jSRow), fRowH));
    jCol = JsonArrayInsert(jCol, NuiHeight(NuiRow(jBRow), fRowH));
    jCol = JsonArrayInsert(jCol, NuiHeight(NuiRow(jDRow), fRowH));
    jCol = JsonArrayInsert(jCol, NuiHeight(NuiRow(jCRow), fRowH));
    jCol = JsonArrayInsert(jCol, CreateEmptyRow(oPC, 8.0));
    jCol = JsonArrayInsert(jCol, jTotal);
    jCol = JsonArrayInsert(jCol, jTier);
    jCol = JsonArrayInsert(jCol, jVisits);
    jCol = JsonArrayInsert(jCol, jCircuits);
    jCol = JsonArrayInsert(jCol, CreateEmptyRow(oPC, 6.0));
    jCol = JsonArrayInsert(jCol, jFxLbl);
    jCol = JsonArrayInsert(jCol, jFxArea);
    jCol = JsonArrayInsert(jCol, CreateEmptyRow(oPC, 8.0));
    jCol = JsonArrayInsert(jCol, NuiRow(jKathRow));

    return NuiCol(jCol);
}

// ---- Shrines tab ----

json PlgBuildShrinesTab(object oPC)
{
    float fRowH = GetNuiScaleDimension(oPC, 26.0);
    float fListH = GetNuiScaleDimension(oPC, 390.0);
    float fTypeW  = GetNuiScaleDimension(oPC, 80.0);
    float fVisW   = GetNuiScaleDimension(oPC, 60.0);

    json jNameLbl = NuiLabel(NuiBind(PLG_BIND_SHRINE_NAME),
        JsonInt(NUI_HALIGN_LEFT), JsonInt(NUI_VALIGN_MIDDLE));

    json jTypeLbl = NuiLabel(NuiBind(PLG_BIND_SHRINE_TYPE),
        JsonInt(NUI_HALIGN_CENTER), JsonInt(NUI_VALIGN_MIDDLE));
    jTypeLbl = NuiWidth(jTypeLbl, fTypeW);

    json jVisLbl = NuiLabel(NuiBind(PLG_BIND_SHRINE_VIS),
        JsonInt(NUI_HALIGN_CENTER), JsonInt(NUI_VALIGN_MIDDLE));
    jVisLbl = NuiWidth(jVisLbl, fVisW);

    json jCellRow = JsonArray();
    jCellRow = JsonArrayInsert(jCellRow, jNameLbl);
    jCellRow = JsonArrayInsert(jCellRow, jTypeLbl);
    jCellRow = JsonArrayInsert(jCellRow, jVisLbl);

    json jCell = NuiGroup(NuiRow(jCellRow), TRUE, NUI_SCROLLBARS_NONE);
    jCell = NuiId(jCell, PLG_BTN_SHRINE_ROW);
    jCell = NuiEncouraged(jCell, NuiBind(PLG_BIND_SHRINE_ENC));

    json jTmpl = JsonArrayInsert(JsonArray(), NuiListTemplateCell(jCell, 0.0, TRUE));

    json jList = NuiList(jTmpl, NuiBind(PLG_BIND_SHRINE_CNT), fRowH);
    jList = NuiHeight(jList, fListH);

    // Header row
    json jHName = NuiLabel(JsonString("Sanktuarium"),
        JsonInt(NUI_HALIGN_LEFT), JsonInt(NUI_VALIGN_MIDDLE));
    json jHType = NuiLabel(JsonString("Typ"),
        JsonInt(NUI_HALIGN_CENTER), JsonInt(NUI_VALIGN_MIDDLE));
    jHType = NuiWidth(jHType, fTypeW);
    json jHVis = NuiLabel(JsonString("Status"),
        JsonInt(NUI_HALIGN_CENTER), JsonInt(NUI_VALIGN_MIDDLE));
    jHVis = NuiWidth(jHVis, fVisW);

    json jHRow = JsonArray();
    jHRow = JsonArrayInsert(jHRow, jHName);
    jHRow = JsonArrayInsert(jHRow, jHType);
    jHRow = JsonArrayInsert(jHRow, jHVis);

    json jCol = JsonArray();
    jCol = JsonArrayInsert(jCol, CreateEmptyRow(oPC, 4.0));
    jCol = JsonArrayInsert(jCol, NuiHeight(NuiRow(jHRow), GetNuiScaleDimension(oPC, 22.0)));
    jCol = JsonArrayInsert(jCol, jList);

    return NuiCol(jCol);
}

// ---- Leaderboard tab ----

json PlgBuildLeaderboardTab(object oPC)
{
    float fRowH  = GetNuiScaleDimension(oPC, 26.0);
    float fListH = GetNuiScaleDimension(oPC, 380.0);
    float fNumW  = GetNuiScaleDimension(oPC, 55.0);

    json jNameLbl = NuiLabel(NuiBind(PLG_BIND_BOARD_NAME),
        JsonInt(NUI_HALIGN_LEFT), JsonInt(NUI_VALIGN_MIDDLE));

    json jTotalLbl = NuiLabel(NuiBind(PLG_BIND_BOARD_TOTAL),
        JsonInt(NUI_HALIGN_CENTER), JsonInt(NUI_VALIGN_MIDDLE));
    jTotalLbl = NuiWidth(jTotalLbl, fNumW);

    json jCircLbl = NuiLabel(NuiBind(PLG_BIND_BOARD_CIRCUITS),
        JsonInt(NUI_HALIGN_CENTER), JsonInt(NUI_VALIGN_MIDDLE));
    jCircLbl = NuiWidth(jCircLbl, fNumW);

    json jCellRow = JsonArray();
    jCellRow = JsonArrayInsert(jCellRow, jNameLbl);
    jCellRow = JsonArrayInsert(jCellRow, jTotalLbl);
    jCellRow = JsonArrayInsert(jCellRow, jCircLbl);

    json jCell = NuiGroup(NuiRow(jCellRow), TRUE, NUI_SCROLLBARS_NONE);

    json jTmpl = JsonArrayInsert(JsonArray(), NuiListTemplateCell(jCell, 0.0, TRUE));

    json jList = NuiList(jTmpl, NuiBind(PLG_BIND_BOARD_CNT), fRowH);
    jList = NuiHeight(jList, fListH);

    // Header
    json jHName = NuiLabel(JsonString("Imię"),
        JsonInt(NUI_HALIGN_LEFT), JsonInt(NUI_VALIGN_MIDDLE));
    json jHTotal = NuiLabel(JsonString("Brzemię"),
        JsonInt(NUI_HALIGN_CENTER), JsonInt(NUI_VALIGN_MIDDLE));
    jHTotal = NuiWidth(jHTotal, fNumW);
    json jHCirc = NuiLabel(JsonString("Obiegi"),
        JsonInt(NUI_HALIGN_CENTER), JsonInt(NUI_VALIGN_MIDDLE));
    jHCirc = NuiWidth(jHCirc, fNumW);

    json jHRow = JsonArray();
    jHRow = JsonArrayInsert(jHRow, jHName);
    jHRow = JsonArrayInsert(jHRow, jHTotal);
    jHRow = JsonArrayInsert(jHRow, jHCirc);

    json jCol = JsonArray();
    jCol = JsonArrayInsert(jCol, CreateEmptyRow(oPC, 4.0));
    jCol = JsonArrayInsert(jCol, NuiHeight(NuiRow(jHRow), GetNuiScaleDimension(oPC, 22.0)));
    jCol = JsonArrayInsert(jCol, jList);

    return NuiCol(jCol);
}

// ---- Main window ----

json PlgBuildMainLayout(object oPC)
{
    json jSwapGrp = NuiGroup(PlgBuildStatusTab(oPC), FALSE, NUI_SCROLLBARS_NONE);
    jSwapGrp = NuiId(jSwapGrp, PLG_GRP_SWAP);

    json jRootCol = JsonArray();
    jRootCol = JsonArrayInsert(jRootCol, PlgBuildTabBar(oPC));
    jRootCol = JsonArrayInsert(jRootCol, jSwapGrp);

    return NuiCol(jRootCol);
}

// ----------------------------------------------------------------
// Window open / tab swap
// ----------------------------------------------------------------

void PlgOpenWindow(object oPC)
{
    int nToken = NuiFindWindow(oPC, PLG_WINDOW);
    if(nToken != 0)
    {
        PlgSwapTab(oPC, nToken, GetLocalInt(oPC, PLG_LVAR_TAB));
        return;
    }

    float fCX = (IntToFloat(GetPlayerDeviceProperty(oPC, PLAYER_DEVICE_PROPERTY_GUI_WIDTH))
                  - GetNuiScaleDimension(oPC, PLG_W)) / 2.0;
    float fCY = (IntToFloat(GetPlayerDeviceProperty(oPC, PLAYER_DEVICE_PROPERTY_GUI_HEIGHT))
                  - GetNuiScaleDimension(oPC, PLG_H)) / 2.0;

    json jGeom = NuiRect(fCX, fCY, GetNuiScaleDimension(oPC, PLG_W), GetNuiScaleDimension(oPC, PLG_H));

    json jWin = NuiWindow(PlgBuildMainLayout(oPC),
        JsonBool(FALSE),
        NuiBind(PLG_WIN_GEOM),
        JsonBool(FALSE), JsonBool(FALSE), JsonBool(FALSE),
        JsonBool(TRUE),  JsonBool(FALSE));

    nToken = NuiCreate(oPC, jWin, PLG_WINDOW, PLG_EV_SCRIPT);
    NuiSetBind(oPC, nToken, PLG_WIN_GEOM, jGeom);

    SetLocalInt(oPC, PLG_LVAR_TAB, 0);
    PlgFeedStatus(oPC, nToken);
}

void PlgSwapTab(object oPC, int nToken, int nTab)
{
    SetLocalInt(oPC, PLG_LVAR_TAB, nTab);
    if(nTab == 0)
    {
        NuiSetGroupLayout(oPC, nToken, PLG_GRP_SWAP, PlgBuildStatusTab(oPC));
        PlgFeedStatus(oPC, nToken);
    }
    else if(nTab == 1)
    {
        NuiSetGroupLayout(oPC, nToken, PLG_GRP_SWAP, PlgBuildShrinesTab(oPC));
        PlgFeedShrines(oPC, nToken);
    }
    else
    {
        NuiSetGroupLayout(oPC, nToken, PLG_GRP_SWAP, PlgBuildLeaderboardTab(oPC));
        PlgFeedLeaderboard(oPC, nToken);
    }
}

// ----------------------------------------------------------------
// Data feeding
// ----------------------------------------------------------------

void PlgFeedStatus(object oPC, int nToken)
{
    json jP = PlgGetPilgrim(oPC);
    int nShadow = 0;
    int nBlood  = 0;
    int nDeath  = 0;
    int nChaos  = 0;
    int nVisits = 0;
    int nCircs  = 0;

    if(JsonGetType(jP) != JSON_TYPE_NULL)
    {
        nShadow = JsonGetInt(JsonObjectGet(jP, "burden_shadow"));
        nBlood  = JsonGetInt(JsonObjectGet(jP, "burden_blood"));
        nDeath  = JsonGetInt(JsonObjectGet(jP, "burden_death"));
        nChaos  = JsonGetInt(JsonObjectGet(jP, "burden_chaos"));
        nVisits = JsonGetInt(JsonObjectGet(jP, "total_visits"));
        nCircs  = JsonGetInt(JsonObjectGet(jP, "circuits_done"));
    }
    int nTotal = nShadow + nBlood + nDeath + nChaos;

    // Progress bars (0.0–1.0)
    float fMax = IntToFloat(PLG_BAR_MAX);
    float fSh = IntToFloat(nShadow) / fMax; if(fSh > 1.0) fSh = 1.0;
    float fBl = IntToFloat(nBlood)  / fMax; if(fBl > 1.0) fBl = 1.0;
    float fDe = IntToFloat(nDeath)  / fMax; if(fDe > 1.0) fDe = 1.0;
    float fCh = IntToFloat(nChaos)  / fMax; if(fCh > 1.0) fCh = 1.0;
    NuiSetBind(oPC, nToken, PLG_BIND_SHADOW_PRG, JsonFloat(fSh));
    NuiSetBind(oPC, nToken, PLG_BIND_BLOOD_PRG,  JsonFloat(fBl));
    NuiSetBind(oPC, nToken, PLG_BIND_DEATH_PRG,  JsonFloat(fDe));
    NuiSetBind(oPC, nToken, PLG_BIND_CHAOS_PRG,  JsonFloat(fCh));

    NuiSetBind(oPC, nToken, PLG_BIND_SHADOW_VAL, JsonString(IntToString(nShadow)));
    NuiSetBind(oPC, nToken, PLG_BIND_BLOOD_VAL,  JsonString(IntToString(nBlood)));
    NuiSetBind(oPC, nToken, PLG_BIND_DEATH_VAL,  JsonString(IntToString(nDeath)));
    NuiSetBind(oPC, nToken, PLG_BIND_CHAOS_VAL,  JsonString(IntToString(nChaos)));

    NuiSetBind(oPC, nToken, PLG_BIND_TOTAL_LBL,
        JsonString("Łączne brzemię: " + IntToString(nTotal)));
    NuiSetBind(oPC, nToken, PLG_BIND_TIER_LBL,
        JsonString("Poziom: " + PlgGetTierName(nTotal)));
    NuiSetBind(oPC, nToken, PLG_BIND_VISITS_LBL,
        JsonString("Wizyty w sanktuariach: " + IntToString(nVisits)));
    NuiSetBind(oPC, nToken, PLG_BIND_CIRCUITS_LBL,
        JsonString("Ukończone obiegi: " + IntToString(nCircs)));

    NuiSetBind(oPC, nToken, PLG_BIND_FX_LBL, JsonString(PlgGetEffectSummary(nTotal)));

    // Catharsis button
    int nCost = PlgGetCatharsisCost(nTotal);
    int bHasBurden = nTotal > 0;
    NuiSetBind(oPC, nToken, PLG_BIND_KATH_ENA, JsonBool(bHasBurden));
    NuiSetBind(oPC, nToken, PLG_BIND_KATH_LBL,
        JsonString("Katharsis (" + IntToString(nCost) + " zł)"));
    NuiSetBind(oPC, nToken, PLG_BIND_KATH_TIP,
        JsonString("Oczyść brzemię w pobliskim ołtarzu pokuty za "
            + IntToString(nCost) + " złota.\nPrzez godzinę Siła i Budowa będą obniżone o 2."));
}

void PlgFeedShrines(object oPC, int nToken)
{
    json jShrines = PlgGetAllShrines(oPC);
    int nCount    = JsonGetLength(jShrines);

    json jNames = JsonArray();
    json jTypes = JsonArray();
    json jVis   = JsonArray();
    json jEncs  = JsonArray();

    int i;
    for(i = 0; i < nCount; i++)
    {
        json jS      = JsonArrayGet(jShrines, i);
        string sName = JsonGetString(JsonObjectGet(jS, "name"));
        string sType = JsonGetString(JsonObjectGet(jS, "burden_type"));
        int nVisited = JsonGetInt(JsonObjectGet(jS, "visited"));

        jNames = JsonArrayInsert(jNames, JsonString(sName));
        jTypes = JsonArrayInsert(jTypes, JsonString(PlgBurdenTypeLabel(sType)));
        jVis   = JsonArrayInsert(jVis,   JsonString(nVisited ? "Tak" : "—"));
        jEncs  = JsonArrayInsert(jEncs,  JsonBool(FALSE));
    }

    NuiSetBind(oPC, nToken, PLG_BIND_SHRINE_NAME, jNames);
    NuiSetBind(oPC, nToken, PLG_BIND_SHRINE_TYPE, jTypes);
    NuiSetBind(oPC, nToken, PLG_BIND_SHRINE_VIS,  jVis);
    NuiSetBind(oPC, nToken, PLG_BIND_SHRINE_ENC,  jEncs);
    NuiSetBind(oPC, nToken, PLG_BIND_SHRINE_CNT,  JsonInt(nCount));
}

void PlgFeedLeaderboard(object oPC, int nToken)
{
    json jBoard = PlgGetLeaderboard();
    int nCount  = JsonGetLength(jBoard);

    json jNames  = JsonArray();
    json jTotals = JsonArray();
    json jCircs  = JsonArray();

    int i;
    for(i = 0; i < nCount; i++)
    {
        json jRow = JsonArrayGet(jBoard, i);
        jNames  = JsonArrayInsert(jNames,  JsonString(JsonGetString(JsonObjectGet(jRow, "char_name"))));
        jTotals = JsonArrayInsert(jTotals, JsonString(IntToString(JsonGetInt(JsonObjectGet(jRow, "total")))));
        jCircs  = JsonArrayInsert(jCircs,  JsonString(IntToString(JsonGetInt(JsonObjectGet(jRow, "circuits_done")))));
    }

    NuiSetBind(oPC, nToken, PLG_BIND_BOARD_NAME,     jNames);
    NuiSetBind(oPC, nToken, PLG_BIND_BOARD_TOTAL,    jTotals);
    NuiSetBind(oPC, nToken, PLG_BIND_BOARD_CIRCUITS, jCircs);
    NuiSetBind(oPC, nToken, PLG_BIND_BOARD_CNT,      JsonInt(nCount));
}
