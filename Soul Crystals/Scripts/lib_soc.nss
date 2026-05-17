// lib_soc.nss — Soul Crystals: NUI builder, game logic, soul binding.

#include "lib_soc_def"

// ---------------------------------------------------------------
// Utility
// ---------------------------------------------------------------

float SocClampF(float fVal, float fMin, float fMax)
{
    if (fVal < fMin) return fMin;
    if (fVal > fMax) return fMax;
    return fVal;
}

// Buff duration in seconds, scaled to crystal essence
float SocCalcDuration(int nEssence)
{
    return SocClampF((nEssence / 100.0) * SOC_DUR_PER_100, SOC_DUR_MIN, SOC_DUR_MAX);
}

string SocGetTierName(int nTier)
{
    if (nTier == SOC_TIER_FLAWLESS) return "Nieskazitelny";
    if (nTier == SOC_TIER_GREATER)  return "Wyższy";
    if (nTier == SOC_TIER_COMMON)   return "Zwykły";
    return "Popękany";
}

string SocGetRaceCatName(int nRaceCat)
{
    if (nRaceCat == SOC_RACE_OUTSIDER) return "Przybysz";
    if (nRaceCat == SOC_RACE_UNDEAD)   return "Nieumarły";
    if (nRaceCat == SOC_RACE_BEAST)    return "Bestia";
    return "Humanoid";
}

// Maps NWN racial type to our four-category system
int SocGetRaceCat(object oCreature)
{
    int nRace = GetRacialType(oCreature);

    if (nRace == RACIAL_TYPE_UNDEAD)
        return SOC_RACE_UNDEAD;

    if (nRace == RACIAL_TYPE_OUTSIDER || nRace == RACIAL_TYPE_ELEMENTAL)
        return SOC_RACE_OUTSIDER;

    if (nRace == RACIAL_TYPE_ANIMAL      || nRace == RACIAL_TYPE_BEAST
     || nRace == RACIAL_TYPE_MAGICAL_BEAST || nRace == RACIAL_TYPE_VERMIN
     || nRace == RACIAL_TYPE_DRAGON)
        return SOC_RACE_BEAST;

    return SOC_RACE_HUMANOID;
}

// Tier based on race category and creature HD
int SocGetSoulTier(object oCreature)
{
    int nRaceCat = SocGetRaceCat(oCreature);
    int nHD      = GetHitDice(oCreature);

    if (nRaceCat == SOC_RACE_OUTSIDER || nHD >= 15) return SOC_TIER_FLAWLESS;
    if (nRaceCat == SOC_RACE_UNDEAD   || nHD >= 8)  return SOC_TIER_GREATER;
    if (nRaceCat == SOC_RACE_BEAST    || nHD >= 4)  return SOC_TIER_COMMON;
    return SOC_TIER_CRACKED;
}

// Essence = 5 × HD, capped at 250
int SocGetSoulEssence(object oCreature)
{
    int nEss = GetHitDice(oCreature) * 5;
    if (nEss < 5)   nEss = 5;
    if (nEss > 250) nEss = 250;
    return nEss;
}

// ---------------------------------------------------------------
// Detail pane layouts
// ---------------------------------------------------------------

json SocBuildDetailEmpty(object oPC)
{
    float fBtnH = GetNuiScaleDimension(oPC, 28.0);

    json jHint = NuiLabel(
        JsonString("Wybierz kryształ z listy..."),
        JsonInt(NUI_HALIGN_CENTER),
        JsonInt(NUI_VALIGN_MIDDLE));

    json jHintRow = JsonArray();
    jHintRow = JsonArrayInsert(jHintRow, jHint);

    json jCol = JsonArray();
    jCol = JsonArrayInsert(jCol, NuiSpacer());
    jCol = JsonArrayInsert(jCol, NuiHeight(NuiRow(jHintRow), fBtnH));
    jCol = JsonArrayInsert(jCol, NuiSpacer());
    return NuiCol(jCol);
}

json SocBuildDetailFilled(object oPC)
{
    float fBtnH  = GetNuiScaleDimension(oPC, 28.0);
    float fHdrH  = GetNuiScaleDimension(oPC, 34.0);
    float fLblW  = GetNuiScaleDimension(oPC, 88.0);
    float fGapH  = GetNuiScaleDimension(oPC, 6.0);

    // Soul name header (gold tint)
    json jNameLbl = NuiLabel(
        NuiBind(SOC_BIND_DET_NAME),
        JsonInt(NUI_HALIGN_CENTER),
        JsonInt(NUI_VALIGN_MIDDLE));
    jNameLbl = NuiStyleForegroundColor(jNameLbl, NuiColor(220, 160, 80));

    // Info row helper macros (inlined since NWScript has no nested functions)
    // --- Race row ---
    json jRaceLbl = NuiLabel(JsonString("Gatunek:"),
        JsonInt(NUI_HALIGN_RIGHT), JsonInt(NUI_VALIGN_MIDDLE));
    jRaceLbl = NuiWidth(jRaceLbl, fLblW);
    json jRaceVal = NuiLabel(NuiBind(SOC_BIND_DET_RACE),
        JsonInt(NUI_HALIGN_LEFT), JsonInt(NUI_VALIGN_MIDDLE));
    json jRaceRow = JsonArray();
    jRaceRow = JsonArrayInsert(jRaceRow, jRaceLbl);
    jRaceRow = JsonArrayInsert(jRaceRow, jRaceVal);

    // --- Essence row ---
    json jEssLbl = NuiLabel(JsonString("Esencja:"),
        JsonInt(NUI_HALIGN_RIGHT), JsonInt(NUI_VALIGN_MIDDLE));
    jEssLbl = NuiWidth(jEssLbl, fLblW);
    json jEssVal = NuiLabel(NuiBind(SOC_BIND_DET_ESS),
        JsonInt(NUI_HALIGN_LEFT), JsonInt(NUI_VALIGN_MIDDLE));
    json jEssRow = JsonArray();
    jEssRow = JsonArrayInsert(jEssRow, jEssLbl);
    jEssRow = JsonArrayInsert(jEssRow, jEssVal);

    // --- Tier row ---
    json jTierLbl = NuiLabel(JsonString("Kryształ:"),
        JsonInt(NUI_HALIGN_RIGHT), JsonInt(NUI_VALIGN_MIDDLE));
    jTierLbl = NuiWidth(jTierLbl, fLblW);
    json jTierVal = NuiLabel(NuiBind(SOC_BIND_DET_TIER),
        JsonInt(NUI_HALIGN_LEFT), JsonInt(NUI_VALIGN_MIDDLE));
    json jTierRow = JsonArray();
    jTierRow = JsonArrayInsert(jTierRow, jTierLbl);
    jTierRow = JsonArrayInsert(jTierRow, jTierVal);

    // Section label
    json jDivLbl = NuiLabel(JsonString("─── Wydaj Esencję ───"),
        JsonInt(NUI_HALIGN_CENTER), JsonInt(NUI_VALIGN_MIDDLE));

    // Buff button row 1: Strength | Wisdom+Int
    json jStrBtn = NuiButton(JsonString("Moc Siły"));
    jStrBtn = NuiId(jStrBtn, SOC_BTN_STR);
    jStrBtn = NuiEnabled(jStrBtn, NuiBind(SOC_BIND_BTN_STR_ENA));
    jStrBtn = NuiTooltip(jStrBtn, JsonString("Wzmocnienie Siły na kilka minut. Zużywa połowę esencji."));

    json jWisBtn = NuiButton(JsonString("Bystrość Ducha"));
    jWisBtn = NuiId(jWisBtn, SOC_BTN_WIS);
    jWisBtn = NuiEnabled(jWisBtn, NuiBind(SOC_BIND_BTN_WIS_ENA));
    jWisBtn = NuiTooltip(jWisBtn, JsonString("Wzmocnienie Mądrości i Inteligencji. Zużywa połowę esencji."));

    json jBuff1Row = JsonArray();
    jBuff1Row = JsonArrayInsert(jBuff1Row, jStrBtn);
    jBuff1Row = JsonArrayInsert(jBuff1Row, jWisBtn);

    // Buff button row 2: AC | Regen
    json jAcBtn = NuiButton(JsonString("Pancerz Duszy"));
    jAcBtn = NuiId(jAcBtn, SOC_BTN_AC);
    jAcBtn = NuiEnabled(jAcBtn, NuiBind(SOC_BIND_BTN_AC_ENA));
    jAcBtn = NuiTooltip(jAcBtn, JsonString("Eteryczna powłoka zwiększa Pancerz. Zużywa połowę esencji."));

    json jRegBtn = NuiButton(JsonString("Regeneracja"));
    jRegBtn = NuiId(jRegBtn, SOC_BTN_REGEN);
    jRegBtn = NuiEnabled(jRegBtn, NuiBind(SOC_BIND_BTN_REG_ENA));
    jRegBtn = NuiTooltip(jRegBtn, JsonString("Powolne odnawianie ran przez czas trwania efektu. Zużywa połowę esencji."));

    json jBuff2Row = JsonArray();
    jBuff2Row = JsonArrayInsert(jBuff2Row, jAcBtn);
    jBuff2Row = JsonArrayInsert(jBuff2Row, jRegBtn);

    // Full consume (uses whole crystal, 5min CD)
    json jFullBtn = NuiButton(JsonString("⚡ Wchłonij Całość"));
    jFullBtn = NuiId(jFullBtn, SOC_BTN_FULL);
    jFullBtn = NuiEnabled(jFullBtn, NuiBind(SOC_BIND_BTN_FULL_ENA));
    jFullBtn = NuiHeight(jFullBtn, fBtnH);
    jFullBtn = NuiTooltip(jFullBtn, JsonString(
        "Pochłania całą esencję — silne, krótkie wzmocnienie wszystkich statystyk. Odnowienie: 5 minut."));
    json jFullRow = JsonArray();
    jFullRow = JsonArrayInsert(jFullRow, jFullBtn);

    // Release for gold
    json jRelBtn = NuiButton(JsonString("Uwolnij Duszę"));
    jRelBtn = NuiId(jRelBtn, SOC_BTN_RELEASE);
    jRelBtn = NuiEnabled(jRelBtn, NuiBind(SOC_BIND_BTN_REL_ENA));
    jRelBtn = NuiHeight(jRelBtn, fBtnH);
    jRelBtn = NuiTooltip(jRelBtn, JsonString("Uwalnia duszę w zamian za odrobinę złota."));
    json jRelRow = JsonArray();
    jRelRow = JsonArrayInsert(jRelRow, jRelBtn);

    json jCol = JsonArray();
    jCol = JsonArrayInsert(jCol, NuiHeight(NuiRow(JsonArrayInsert(JsonArray(), jNameLbl)), fHdrH));
    jCol = JsonArrayInsert(jCol, CreateEmptyRow(oPC, fGapH));
    jCol = JsonArrayInsert(jCol, NuiRow(jRaceRow));
    jCol = JsonArrayInsert(jCol, NuiRow(jEssRow));
    jCol = JsonArrayInsert(jCol, NuiRow(jTierRow));
    jCol = JsonArrayInsert(jCol, CreateEmptyRow(oPC, fGapH * 2.0));
    jCol = JsonArrayInsert(jCol, NuiHeight(NuiRow(JsonArrayInsert(JsonArray(), jDivLbl)), fBtnH));
    jCol = JsonArrayInsert(jCol, CreateEmptyRow(oPC, fGapH));
    jCol = JsonArrayInsert(jCol, NuiRow(jBuff1Row));
    jCol = JsonArrayInsert(jCol, CreateEmptyRow(oPC, fGapH));
    jCol = JsonArrayInsert(jCol, NuiRow(jBuff2Row));
    jCol = JsonArrayInsert(jCol, CreateEmptyRow(oPC, fGapH));
    jCol = JsonArrayInsert(jCol, NuiRow(jFullRow));
    jCol = JsonArrayInsert(jCol, CreateEmptyRow(oPC, fGapH));
    jCol = JsonArrayInsert(jCol, NuiRow(jRelRow));
    jCol = JsonArrayInsert(jCol, NuiSpacer());
    return NuiCol(jCol);
}

// ---------------------------------------------------------------
// Feed functions
// ---------------------------------------------------------------

void SocFeedDetail(object oPC, int nToken)
{
    int nId = GetLocalInt(oPC, SOC_LVAR_SEL_ID);
    if (nId <= 0)
    {
        NuiSetGroupLayout(oPC, nToken, SOC_GRP_DETAIL, SocBuildDetailEmpty(oPC));
        return;
    }

    json jCrystal = SocGetCrystalById(nId);
    if (JsonGetType(jCrystal) == JSON_TYPE_NULL)
    {
        // Crystal was deleted (consumed/released)
        SetLocalInt(oPC, SOC_LVAR_SEL_ID, 0);
        NuiSetGroupLayout(oPC, nToken, SOC_GRP_DETAIL, SocBuildDetailEmpty(oPC));
        return;
    }

    NuiSetGroupLayout(oPC, nToken, SOC_GRP_DETAIL, SocBuildDetailFilled(oPC));

    string sSoulName = JsonGetString(JsonObjectGet(jCrystal, "soul_name"));
    int nRaceCat     = JsonGetInt   (JsonObjectGet(jCrystal, "race_cat"));
    int nEssence     = JsonGetInt   (JsonObjectGet(jCrystal, "essence"));
    int nTier        = JsonGetInt   (JsonObjectGet(jCrystal, "tier"));

    NuiSetBind(oPC, nToken, SOC_BIND_DET_NAME,  JsonString(sSoulName));
    NuiSetBind(oPC, nToken, SOC_BIND_DET_RACE,  JsonString(SocGetRaceCatName(nRaceCat)));
    NuiSetBind(oPC, nToken, SOC_BIND_DET_ESS,   JsonString(IntToString(nEssence)));
    NuiSetBind(oPC, nToken, SOC_BIND_DET_TIER,  JsonString(SocGetTierName(nTier)));

    // Full-consume button respects 5-minute cooldown
    int bFullOk = TRUE;
    int nLast   = SocGetLastFullConsume(oPC);
    if (nLast > 0)
        bFullOk = ((SocGetNowUnix() - nLast) >= SOC_FULL_CD_SECS);

    NuiSetBind(oPC, nToken, SOC_BIND_BTN_STR_ENA,  JsonBool(TRUE));
    NuiSetBind(oPC, nToken, SOC_BIND_BTN_WIS_ENA,  JsonBool(TRUE));
    NuiSetBind(oPC, nToken, SOC_BIND_BTN_AC_ENA,   JsonBool(TRUE));
    NuiSetBind(oPC, nToken, SOC_BIND_BTN_REG_ENA,  JsonBool(TRUE));
    NuiSetBind(oPC, nToken, SOC_BIND_BTN_FULL_ENA, JsonBool(bFullOk));
    NuiSetBind(oPC, nToken, SOC_BIND_BTN_REL_ENA,  JsonBool(TRUE));
}

void SocFeedList(object oPC, int nToken)
{
    json jCrystals = SocGetCrystals(oPC);
    int nCount     = JsonGetLength(jCrystals);

    json jNames  = JsonArray();
    json jTiers  = JsonArray();
    json jEsss   = JsonArray();
    json jEncs   = JsonArray();
    json jColors = JsonArray();

    int nSelId = GetLocalInt(oPC, SOC_LVAR_SEL_ID);

    int i;
    for (i = 0; i < nCount; i++)
    {
        json jRow    = JsonArrayGet(jCrystals, i);
        int  nId     = JsonGetInt   (JsonObjectGet(jRow, "id"));
        string sName = JsonGetString(JsonObjectGet(jRow, "soul_name"));
        int  nTier   = JsonGetInt   (JsonObjectGet(jRow, "tier"));
        int  nEss    = JsonGetInt   (JsonObjectGet(jRow, "essence"));

        jNames = JsonArrayInsert(jNames, JsonString(sName));
        jTiers = JsonArrayInsert(jTiers, JsonString(SocGetTierName(nTier)));
        jEsss  = JsonArrayInsert(jEsss,  JsonString(IntToString(nEss)));
        jEncs  = JsonArrayInsert(jEncs,  JsonBool(nId == nSelId));

        json jColor = NuiColor(140, 130, 120);  // cracked: dim gray
        if      (nTier == SOC_TIER_FLAWLESS) jColor = NuiColor(220, 160,  80);  // gold
        else if (nTier == SOC_TIER_GREATER)  jColor = NuiColor(140, 190, 255);  // steel blue
        else if (nTier == SOC_TIER_COMMON)   jColor = NuiColor(200, 200, 200);  // light gray
        jColors = JsonArrayInsert(jColors, jColor);
    }

    NuiSetBind(oPC, nToken, SOC_BIND_ROW_NAME,  jNames);
    NuiSetBind(oPC, nToken, SOC_BIND_ROW_TIER,  jTiers);
    NuiSetBind(oPC, nToken, SOC_BIND_ROW_ESS,   jEsss);
    NuiSetBind(oPC, nToken, SOC_BIND_ROW_ENC,   jEncs);
    NuiSetBind(oPC, nToken, SOC_BIND_ROW_COLOR, jColors);

    NuiSetBind(oPC, nToken, SOC_BIND_CAP_LBL,
        JsonString("Pojemność: " + IntToString(nCount) + "/" + IntToString(SOC_MAX_CRYSTALS)));

    NuiSetBind(oPC, nToken, SOC_BIND_BTN_BIND_ENA, JsonBool(nCount < SOC_MAX_CRYSTALS));

    // row count LAST — triggers list re-render once all data is ready
    NuiSetBind(oPC, nToken, SOC_BIND_ROW_COUNT, JsonInt(nCount));
}

void SocFeedStats(object oPC, int nToken)
{
    json jStats = SocGetPlayerStats(oPC);
    if (JsonGetType(jStats) == JSON_TYPE_NULL) return;

    int nCap   = JsonGetInt(JsonObjectGet(jStats, "total_captured"));
    int nSpent = JsonGetInt(JsonObjectGet(jStats, "total_essence_spent"));

    NuiSetBind(oPC, nToken, SOC_BIND_STATS_LBL,
        JsonString("Schwytano: " + IntToString(nCap) + "  |  Wydano esencji: " + IntToString(nSpent)));
}

// ---------------------------------------------------------------
// Window construction
// ---------------------------------------------------------------

void SocOpenWindow(object oPC)
{
    // Reopen: destroy existing instance first
    int nExisting = NuiFindWindow(oPC, SOC_WINDOW);
    if (nExisting != 0)
        NuiDestroy(oPC, nExisting);

    float fW     = GetNuiScaleDimension(oPC, SOC_WIN_W);
    float fH     = GetNuiScaleDimension(oPC, SOC_WIN_H);
    float fBtnH  = GetNuiScaleDimension(oPC, 28.0);
    float fRowH  = GetNuiScaleDimension(oPC, 26.0);
    float fListH = GetNuiScaleDimension(oPC, 320.0);
    float fLeftW = GetNuiScaleDimension(oPC, 240.0);

    // ---- Title bar ----
    json jTitleLbl = NuiLabel(
        JsonString("⚗  Kryształy Dusz"),
        JsonInt(NUI_HALIGN_LEFT),
        JsonInt(NUI_VALIGN_MIDDLE));
    jTitleLbl = NuiStyleForegroundColor(jTitleLbl, NuiColor(220, 160, 80));

    json jCloseBtn = NuiButton(JsonString("X"));
    jCloseBtn = NuiId(jCloseBtn, SOC_BTN_CLOSE);
    jCloseBtn = NuiWidth (jCloseBtn, GetNuiScaleDimension(oPC, 28.0));
    jCloseBtn = NuiHeight(jCloseBtn, fBtnH);

    json jTopRow = JsonArray();
    jTopRow = JsonArrayInsert(jTopRow, jTitleLbl);
    jTopRow = JsonArrayInsert(jTopRow, jCloseBtn);

    // ---- Crystal list template ----
    float fTierW = GetNuiScaleDimension(oPC, 72.0);
    float fEssW  = GetNuiScaleDimension(oPC, 44.0);

    json jRowName = NuiLabel(NuiBind(SOC_BIND_ROW_NAME),
        JsonInt(NUI_HALIGN_LEFT), JsonInt(NUI_VALIGN_MIDDLE));
    jRowName = NuiStyleForegroundColor(jRowName, NuiBind(SOC_BIND_ROW_COLOR));

    json jRowTier = NuiLabel(NuiBind(SOC_BIND_ROW_TIER),
        JsonInt(NUI_HALIGN_CENTER), JsonInt(NUI_VALIGN_MIDDLE));
    jRowTier = NuiWidth(jRowTier, fTierW);
    jRowTier = NuiStyleForegroundColor(jRowTier, NuiBind(SOC_BIND_ROW_COLOR));

    json jRowEss = NuiLabel(NuiBind(SOC_BIND_ROW_ESS),
        JsonInt(NUI_HALIGN_RIGHT), JsonInt(NUI_VALIGN_MIDDLE));
    jRowEss = NuiWidth(jRowEss, fEssW);
    jRowEss = NuiStyleForegroundColor(jRowEss, NuiBind(SOC_BIND_ROW_COLOR));

    json jCellRow = JsonArray();
    jCellRow = JsonArrayInsert(jCellRow, jRowName);
    jCellRow = JsonArrayInsert(jCellRow, jRowTier);
    jCellRow = JsonArrayInsert(jCellRow, jRowEss);

    json jCell = NuiGroup(NuiRow(jCellRow), TRUE, NUI_SCROLLBARS_NONE);
    jCell = NuiId(jCell, SOC_BTN_ROW);
    jCell = NuiEncouraged(jCell, NuiBind(SOC_BIND_ROW_ENC));

    json jTmpl = JsonArrayInsert(JsonArray(), NuiListTemplateCell(jCell, 0.0, TRUE));
    json jList = NuiList(jTmpl, NuiBind(SOC_BIND_ROW_COUNT), fRowH);
    jList = NuiHeight(jList, fListH);

    // ---- Bind + capacity row ----
    json jBindBtn = NuiButton(JsonString("Zwiąż Duszę"));
    jBindBtn = NuiId(jBindBtn, SOC_BTN_BIND);
    jBindBtn = NuiEnabled(jBindBtn, NuiBind(SOC_BIND_BTN_BIND_ENA));
    jBindBtn = NuiTooltip(jBindBtn,
        JsonString("Celuj w osłabione stworzenie (HP ≤ 25%), by schwytać jego duszę."));

    json jCapLbl = NuiLabel(NuiBind(SOC_BIND_CAP_LBL),
        JsonInt(NUI_HALIGN_RIGHT), JsonInt(NUI_VALIGN_MIDDLE));
    jCapLbl = NuiWidth(jCapLbl, GetNuiScaleDimension(oPC, 88.0));

    json jBindRow = JsonArray();
    jBindRow = JsonArrayInsert(jBindRow, jBindBtn);
    jBindRow = JsonArrayInsert(jBindRow, jCapLbl);

    // Left column
    json jLeftCol = JsonArray();
    jLeftCol = JsonArrayInsert(jLeftCol, jList);
    jLeftCol = JsonArrayInsert(jLeftCol, NuiRow(jBindRow));
    json jLeftGrp = NuiWidth(NuiCol(jLeftCol), fLeftW);

    // Right column: detail group (content filled on demand by SocFeedDetail)
    json jDetailGrp = NuiGroup(JsonNull(), TRUE, NUI_SCROLLBARS_NONE);
    jDetailGrp = NuiId(jDetailGrp, SOC_GRP_DETAIL);

    json jMainRow = JsonArray();
    jMainRow = JsonArrayInsert(jMainRow, jLeftGrp);
    jMainRow = JsonArrayInsert(jMainRow, jDetailGrp);

    // Stats footer
    json jStatsLbl = NuiLabel(NuiBind(SOC_BIND_STATS_LBL),
        JsonInt(NUI_HALIGN_LEFT), JsonInt(NUI_VALIGN_MIDDLE));
    jStatsLbl = NuiHeight(jStatsLbl, GetNuiScaleDimension(oPC, 22.0));

    // Root
    json jRootCol = JsonArray();
    jRootCol = JsonArrayInsert(jRootCol, NuiHeight(NuiRow(jTopRow), fBtnH));
    jRootCol = JsonArrayInsert(jRootCol, NuiRow(jMainRow));
    jRootCol = JsonArrayInsert(jRootCol, NuiRow(JsonArrayInsert(JsonArray(), jStatsLbl)));

    json jRoot = NuiCol(jRootCol);

    float fGuiW = IntToFloat(GetPlayerDeviceProperty(oPC, PLAYER_DEVICE_PROPERTY_GUI_WIDTH));
    float fGuiH = IntToFloat(GetPlayerDeviceProperty(oPC, PLAYER_DEVICE_PROPERTY_GUI_HEIGHT));
    json jGeom  = NuiRect((fGuiW - SOC_WIN_W) / 2.0, (fGuiH - SOC_WIN_H) / 2.0, fW, fH);

    json jWin = NuiWindow(jRoot,
        JsonBool(FALSE),
        NuiBind(SOC_WIN_GEOM),
        JsonBool(FALSE),
        JsonBool(FALSE),
        JsonBool(FALSE),
        JsonBool(TRUE),
        JsonBool(FALSE));

    int nToken = NuiCreate(oPC, jWin, SOC_WINDOW, SOC_EV_SCRIPT);
    NuiSetBind(oPC, nToken, SOC_WIN_GEOM, jGeom);

    SocFeedList  (oPC, nToken);
    SocFeedDetail(oPC, nToken);
    SocFeedStats (oPC, nToken);
}

// ---------------------------------------------------------------
// Consume logic
// ---------------------------------------------------------------

// nConsumeType: 1=STR, 2=WIS+INT, 3=AC, 4=REGEN, 5=FULL
void SocConsumeFor(object oPC, int nToken, int nCrystalId, int nConsumeType)
{
    json jCrystal = SocGetCrystalById(nCrystalId);
    if (JsonGetType(jCrystal) == JSON_TYPE_NULL) return;

    int nEssence = JsonGetInt(JsonObjectGet(jCrystal, "essence"));
    float fDur   = SocCalcDuration(nEssence);

    effect eEffect;
    string sMsg;
    int nCostEss;
    int bRemoveCrystal = FALSE;

    if (nConsumeType == 1)
    {
        int nBonus = 2 + (nEssence / 50);
        if (nBonus > 8) nBonus = 8;
        eEffect  = EffectAbilityIncrease(ABILITY_STRENGTH, nBonus);
        nCostEss = nEssence / 2;
        sMsg     = "Esencja duszy wzmacnia twe mięśnie. Siła wzrosła o " + IntToString(nBonus) + ".";
    }
    else if (nConsumeType == 2)
    {
        int nBonus = 2 + (nEssence / 50);
        if (nBonus > 8) nBonus = 8;
        eEffect  = EffectLinkEffects(
            EffectAbilityIncrease(ABILITY_WISDOM,       nBonus),
            EffectAbilityIncrease(ABILITY_INTELLIGENCE, nBonus));
        nCostEss = nEssence / 2;
        sMsg     = "Duch rozjaśnia umysł i percepcję. Mądrość i Inteligencja wzrosły o " + IntToString(nBonus) + ".";
    }
    else if (nConsumeType == 3)
    {
        int nAc  = 1 + (nEssence / 60);
        if (nAc > 6) nAc = 6;
        eEffect  = EffectACIncrease(nAc);
        nCostEss = nEssence / 2;
        sMsg     = "Eteryczna powłoka otacza twe ciało. Pancerz wzrósł o " + IntToString(nAc) + ".";
    }
    else if (nConsumeType == 4)
    {
        int nRegen = 1 + (nEssence / 80);
        if (nRegen > 5) nRegen = 5;
        eEffect  = EffectRegenerate(nRegen, 6.0);
        nCostEss = nEssence / 2;
        sMsg     = "Esencja duszy zszywa twe rany. Regenerujesz " + IntToString(nRegen) + " HP co rundę.";
    }
    else if (nConsumeType == 5)
    {
        int nLast = SocGetLastFullConsume(oPC);
        if (nLast > 0 && (SocGetNowUnix() - nLast) < SOC_FULL_CD_SECS)
        {
            SendMessageToPC(oPC, "[Kryształy Dusz] Moc wchłonięcia jeszcze się nie odnowiła.");
            return;
        }

        fDur = SocClampF(fDur * 0.5, 30.0, 300.0);
        int nStr  = 4 + (nEssence / 50);  if (nStr  > 10) nStr  = 10;
        int nAc   = 2 + (nEssence / 60);  if (nAc   > 8)  nAc   = 8;
        int nReg  = 2 + (nEssence / 80);  if (nReg  > 6)  nReg  = 6;
        int nWis  = nStr / 2 + 1;

        eEffect = EffectLinkEffects(EffectAbilityIncrease(ABILITY_STRENGTH,     nStr),
                  EffectLinkEffects(EffectAbilityIncrease(ABILITY_WISDOM,        nWis),
                  EffectLinkEffects(EffectACIncrease(nAc),
                  EffectLinkEffects(EffectRegenerate(nReg, 6.0),
                                    EffectHaste()))));

        nCostEss       = nEssence;
        bRemoveCrystal = TRUE;
        SocSetLastFullConsume(oPC);
        sMsg = "Cała esencja wylewa się w falach mrocznej mocy. Duch przenika twe ciało...";
    }

    if (nCostEss < 5) nCostEss = 5;

    ApplyEffectToObject(DURATION_TYPE_TEMPORARY, eEffect, oPC, fDur);
    FloatingTextStringOnCreature(sMsg, oPC, FALSE);
    SocRecordEssenceSpent(oPC, nCostEss);

    if (bRemoveCrystal)
    {
        SocRemoveCrystal(nCrystalId);
        SetLocalInt(oPC, SOC_LVAR_SEL_ID, 0);
    }
    else
    {
        int nNewEss = nEssence - nCostEss;
        if (nNewEss <= 0)
        {
            SocRemoveCrystal(nCrystalId);
            SetLocalInt(oPC, SOC_LVAR_SEL_ID, 0);
            FloatingTextStringOnCreature("Kryształ rozsypuje się w pył — esencja wyczerpana.", oPC, FALSE);
        }
        else
        {
            SocSetCrystalEssence(nCrystalId, nNewEss);
        }
    }

    SocFeedList  (oPC, nToken);
    SocFeedDetail(oPC, nToken);
    SocFeedStats (oPC, nToken);
}

void SocReleaseCrystal(object oPC, int nToken, int nCrystalId)
{
    json jCrystal = SocGetCrystalById(nCrystalId);
    if (JsonGetType(jCrystal) == JSON_TYPE_NULL) return;

    int nEssence = JsonGetInt(JsonObjectGet(jCrystal, "essence"));
    int nTier    = JsonGetInt(JsonObjectGet(jCrystal, "tier"));
    int nGold    = nTier * 5 + (nEssence / 10);
    if (nGold < 1) nGold = 1;

    GiveGoldToCreature(oPC, nGold);
    FloatingTextStringOnCreature(
        "Duch ulatuje w nicość. Otrzymujesz " + IntToString(nGold) + " sztuk złota.",
        oPC, FALSE);

    SocRemoveCrystal(nCrystalId);
    SetLocalInt(oPC, SOC_LVAR_SEL_ID, 0);

    SocFeedList  (oPC, nToken);
    SocFeedDetail(oPC, nToken);
    SocFeedStats (oPC, nToken);
}

// ---------------------------------------------------------------
// Soul binding — called from sys_on_target.nss
// ---------------------------------------------------------------

void SocOnPlayerTarget(object oPC, object oTarget)
{
    DeleteLocalInt(oPC, SOC_LVAR_BINDING);

    if (!GetIsObjectValid(oTarget) || GetObjectType(oTarget) != OBJECT_TYPE_CREATURE)
    {
        SendMessageToPC(oPC, "[Kryształy Dusz] Cel musi być żywą istotą.");
        return;
    }

    if (GetIsPC(oTarget))
    {
        SendMessageToPC(oPC, "[Kryształy Dusz] Nie możesz schwytać duszy innego gracza.");
        return;
    }

    if (GetIsDead(oTarget))
    {
        SendMessageToPC(oPC, "[Kryształy Dusz] Stworzenie już nie żyje — duch zdążył uciec.");
        return;
    }

    // Must be weakened to ≤25% HP
    int nMaxHP  = GetMaxHitPoints(oTarget);
    int nCurHP  = GetCurrentHitPoints(oTarget);
    if (nCurHP > (nMaxHP / 4))
    {
        SendMessageToPC(oPC,
            "[Kryształy Dusz] Duch jest zbyt mocno osadzony w ciele — najpierw osłab swego wroga.");
        return;
    }

    if (SocGetCrystalCount(oPC) >= SOC_MAX_CRYSTALS)
    {
        SendMessageToPC(oPC, "[Kryształy Dusz] Wszystkie sloty kryształów są zajęte.");
        return;
    }

    string sSoulName = GetName(oTarget);
    int    nRaceCat  = SocGetRaceCat(oTarget);
    int    nEssence  = SocGetSoulEssence(oTarget);
    int    nTier     = SocGetSoulTier(oTarget);

    // Soul rend: kill the target and trigger visual on caster
    ApplyEffectToObject(DURATION_TYPE_INSTANT, EffectDeath(TRUE, FALSE), oTarget);
    ApplyEffectToObject(DURATION_TYPE_INSTANT, EffectVisualEffect(VFX_IMP_NEGATIVE_ENERGY), oPC);

    SocAddCrystal(oPC, sSoulName, nRaceCat, nEssence, nTier);
    SocRecordCapture(oPC);

    FloatingTextStringOnCreature(
        "Dusza „" + sSoulName + "" uwięziona w krysztale " + SocGetTierName(nTier) +
        ". Esencja: " + IntToString(nEssence) + ".",
        oPC, FALSE);

    // Refresh the window if it's open
    int nToken = NuiFindWindow(oPC, SOC_WINDOW);
    if (nToken != 0)
    {
        SocFeedList (oPC, nToken);
        SocFeedStats(oPC, nToken);
    }
}
