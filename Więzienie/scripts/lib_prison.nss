#include "lib_prison_def"

// ----------------------------------------------------------------
// Helpers
// ----------------------------------------------------------------

string PrisonCrimeLevelLabel(int nLevel)
{
    switch(nLevel)
    {
        case 1: return "Drobne wykroczenie";
        case 2: return "Kradzież";
        case 3: return "Przestępstwo";
        case 4: return "Ciężka zbrodnia";
        case 5: return "Zbrodnia przeciw Koronie";
    }
    return "Nieznana zbrodnia";
}

string PrisonOutcomeLabel(string sOutcome)
{
    if(sOutcome == "served")   return "Odsiedział";
    if(sOutcome == "bribed")   return "Przekupił";
    if(sOutcome == "escaped")  return "Uciekł";
    if(sOutcome == "recaught") return "Schwytano ponownie";
    return sOutcome;
}

json PrisonOutcomeColor(string sOutcome)
{
    if(sOutcome == "served")   return NuiColor(180, 180, 180);
    if(sOutcome == "bribed")   return NuiColor(210, 175,  55);
    if(sOutcome == "escaped")  return NuiColor( 80, 200,  80);
    if(sOutcome == "recaught") return NuiColor(200,  80,  80);
    return NuiColor(160, 160, 160);
}

// Returns TRUE if oPC has any thieves' tools in inventory.
int PrisonHasThievesTools(object oPC)
{
    if(GetIsObjectValid(GetItemPossessedBy(oPC, "NW_IT_PICKS001"))) return TRUE;
    if(GetIsObjectValid(GetItemPossessedBy(oPC, "NW_IT_PICKS002"))) return TRUE;
    if(GetIsObjectValid(GetItemPossessedBy(oPC, "NW_IT_PICKS003"))) return TRUE;
    return FALSE;
}

// ----------------------------------------------------------------
// NUI layout builders
// ----------------------------------------------------------------

json PrisonBuildStatusPanel(object oPC)
{
    float fLblH = GetNuiScaleDimension(oPC, 26.0);
    float fBtnH = GetNuiScaleDimension(oPC, 34.0);
    float fBtnW = GetNuiScaleDimension(oPC, 200.0);
    float fKeyW = GetNuiScaleDimension(oPC, 130.0);

    // ---- Info rows ----
    json jCrimeKey = NuiLabel(JsonString("Zbrodnia:"),
        JsonInt(NUI_HALIGN_RIGHT), JsonInt(NUI_VALIGN_MIDDLE));
    jCrimeKey = NuiWidth(jCrimeKey, fKeyW);
    jCrimeKey = NuiHeight(jCrimeKey, fLblH);
    json jCrimeVal = NuiLabel(NuiBind(PRISON_BIND_CRIME_LBL),
        JsonInt(NUI_HALIGN_LEFT), JsonInt(NUI_VALIGN_MIDDLE));
    jCrimeVal = NuiHeight(jCrimeVal, fLblH);
    json jCrimeItems = JsonArray();
    jCrimeItems = JsonArrayInsert(jCrimeItems, jCrimeKey);
    jCrimeItems = JsonArrayInsert(jCrimeItems, jCrimeVal);

    json jLevelKey = NuiLabel(JsonString("Ciężkość:"),
        JsonInt(NUI_HALIGN_RIGHT), JsonInt(NUI_VALIGN_MIDDLE));
    jLevelKey = NuiWidth(jLevelKey, fKeyW);
    jLevelKey = NuiHeight(jLevelKey, fLblH);
    json jLevelVal = NuiLabel(NuiBind(PRISON_BIND_LEVEL_LBL),
        JsonInt(NUI_HALIGN_LEFT), JsonInt(NUI_VALIGN_MIDDLE));
    jLevelVal = NuiHeight(jLevelVal, fLblH);
    json jLevelItems = JsonArray();
    jLevelItems = JsonArrayInsert(jLevelItems, jLevelKey);
    jLevelItems = JsonArrayInsert(jLevelItems, jLevelVal);

    json jSentKey = NuiLabel(JsonString("Wymiar kary:"),
        JsonInt(NUI_HALIGN_RIGHT), JsonInt(NUI_VALIGN_MIDDLE));
    jSentKey = NuiWidth(jSentKey, fKeyW);
    jSentKey = NuiHeight(jSentKey, fLblH);
    json jSentVal = NuiLabel(NuiBind(PRISON_BIND_SENT_LBL),
        JsonInt(NUI_HALIGN_LEFT), JsonInt(NUI_VALIGN_MIDDLE));
    jSentVal = NuiHeight(jSentVal, fLblH);
    json jSentItems = JsonArray();
    jSentItems = JsonArrayInsert(jSentItems, jSentKey);
    jSentItems = JsonArrayInsert(jSentItems, jSentVal);

    json jTimeKey = NuiLabel(JsonString("Pozostało:"),
        JsonInt(NUI_HALIGN_RIGHT), JsonInt(NUI_VALIGN_MIDDLE));
    jTimeKey = NuiWidth(jTimeKey, fKeyW);
    jTimeKey = NuiHeight(jTimeKey, fLblH);
    json jTimeVal = NuiLabel(NuiBind(PRISON_BIND_TIME_LBL),
        JsonInt(NUI_HALIGN_LEFT), JsonInt(NUI_VALIGN_MIDDLE));
    jTimeVal = NuiHeight(jTimeVal, fLblH);
    json jTimeItems = JsonArray();
    jTimeItems = JsonArrayInsert(jTimeItems, jTimeKey);
    jTimeItems = JsonArrayInsert(jTimeItems, jTimeVal);

    json jAttKey = NuiLabel(JsonString("Próby ucieczki:"),
        JsonInt(NUI_HALIGN_RIGHT), JsonInt(NUI_VALIGN_MIDDLE));
    jAttKey = NuiWidth(jAttKey, fKeyW);
    jAttKey = NuiHeight(jAttKey, fLblH);
    json jAttVal = NuiLabel(NuiBind(PRISON_BIND_ATT_LBL),
        JsonInt(NUI_HALIGN_LEFT), JsonInt(NUI_VALIGN_MIDDLE));
    jAttVal = NuiHeight(jAttVal, fLblH);
    json jAttItems = JsonArray();
    jAttItems = JsonArrayInsert(jAttItems, jAttKey);
    jAttItems = JsonArrayInsert(jAttItems, jAttVal);

    // ---- Escape buttons (2x2 grid) ----
    json jServeBtn = NuiButton(JsonString("Odsiaduj karę"));
    jServeBtn = NuiId(jServeBtn, PRISON_BTN_SERVE);
    jServeBtn = NuiEnabled(jServeBtn, NuiBind(PRISON_BIND_SERVE_ENA));
    jServeBtn = NuiWidth(jServeBtn, fBtnW);
    jServeBtn = NuiHeight(jServeBtn, fBtnH);
    jServeBtn = NuiTooltip(jServeBtn, JsonString(
        "Poczekaj, aż wyrok minie. Bez ryzyka."));

    json jBribeBtn = NuiButton(JsonString("Przekup strażnika"));
    jBribeBtn = NuiId(jBribeBtn, PRISON_BTN_BRIBE);
    jBribeBtn = NuiEnabled(jBribeBtn, NuiBind(PRISON_BIND_BRIBE_ENA));
    jBribeBtn = NuiWidth(jBribeBtn, fBtnW);
    jBribeBtn = NuiHeight(jBribeBtn, fBtnH);
    jBribeBtn = NuiTooltip(jBribeBtn, NuiBind(PRISON_BIND_BRIBE_TIP));

    json jPickBtn = NuiButton(JsonString("Otwórz zamek wytrychem"));
    jPickBtn = NuiId(jPickBtn, PRISON_BTN_PICK);
    jPickBtn = NuiEnabled(jPickBtn, NuiBind(PRISON_BIND_PICK_ENA));
    jPickBtn = NuiWidth(jPickBtn, fBtnW);
    jPickBtn = NuiHeight(jPickBtn, fBtnH);
    jPickBtn = NuiTooltip(jPickBtn, NuiBind(PRISON_BIND_PICK_TIP));

    json jOverBtn = NuiButton(JsonString("Obezwładnij strażnika"));
    jOverBtn = NuiId(jOverBtn, PRISON_BTN_OVERPOWER);
    jOverBtn = NuiEnabled(jOverBtn, NuiBind(PRISON_BIND_OVER_ENA));
    jOverBtn = NuiWidth(jOverBtn, fBtnW);
    jOverBtn = NuiHeight(jOverBtn, fBtnH);
    jOverBtn = NuiTooltip(jOverBtn, NuiBind(PRISON_BIND_OVER_TIP));

    json jBtnRow1Items = JsonArray();
    jBtnRow1Items = JsonArrayInsert(jBtnRow1Items, NuiSpacer());
    jBtnRow1Items = JsonArrayInsert(jBtnRow1Items, jServeBtn);
    jBtnRow1Items = JsonArrayInsert(jBtnRow1Items, NuiSpacer());
    jBtnRow1Items = JsonArrayInsert(jBtnRow1Items, jBribeBtn);
    jBtnRow1Items = JsonArrayInsert(jBtnRow1Items, NuiSpacer());

    json jBtnRow2Items = JsonArray();
    jBtnRow2Items = JsonArrayInsert(jBtnRow2Items, NuiSpacer());
    jBtnRow2Items = JsonArrayInsert(jBtnRow2Items, jPickBtn);
    jBtnRow2Items = JsonArrayInsert(jBtnRow2Items, NuiSpacer());
    jBtnRow2Items = JsonArrayInsert(jBtnRow2Items, jOverBtn);
    jBtnRow2Items = JsonArrayInsert(jBtnRow2Items, NuiSpacer());

    // ---- Assemble column ----
    json jCol = JsonArray();
    jCol = JsonArrayInsert(jCol, NuiRow(jCrimeItems));
    jCol = JsonArrayInsert(jCol, NuiRow(jLevelItems));
    jCol = JsonArrayInsert(jCol, NuiRow(jSentItems));
    jCol = JsonArrayInsert(jCol, NuiRow(jTimeItems));
    jCol = JsonArrayInsert(jCol, NuiRow(jAttItems));
    jCol = JsonArrayInsert(jCol, NuiSpacer());
    jCol = JsonArrayInsert(jCol, NuiRow(jBtnRow1Items));
    jCol = JsonArrayInsert(jCol, NuiRow(jBtnRow2Items));

    return NuiCol(jCol);
}

json PrisonBuildHistoryPanel(object oPC)
{
    float fHdrH = GetNuiScaleDimension(oPC, 22.0);
    float fRowH = GetNuiScaleDimension(oPC, 26.0);
    float fDateW = GetNuiScaleDimension(oPC, 80.0);
    float fOutW  = GetNuiScaleDimension(oPC, 100.0);

    // ---- Header row ----
    json jHdrCrime = NuiLabel(JsonString("Zbrodnia"),
        JsonInt(NUI_HALIGN_LEFT), JsonInt(NUI_VALIGN_MIDDLE));
    jHdrCrime = NuiHeight(jHdrCrime, fHdrH);

    json jHdrDate = NuiLabel(JsonString("Data"),
        JsonInt(NUI_HALIGN_CENTER), JsonInt(NUI_VALIGN_MIDDLE));
    jHdrDate = NuiWidth(jHdrDate, fDateW);
    jHdrDate = NuiHeight(jHdrDate, fHdrH);

    json jHdrOut = NuiLabel(JsonString("Wynik"),
        JsonInt(NUI_HALIGN_CENTER), JsonInt(NUI_VALIGN_MIDDLE));
    jHdrOut = NuiWidth(jHdrOut, fOutW);
    jHdrOut = NuiHeight(jHdrOut, fHdrH);

    json jHdrItems = JsonArray();
    jHdrItems = JsonArrayInsert(jHdrItems, jHdrCrime);
    jHdrItems = JsonArrayInsert(jHdrItems, jHdrDate);
    jHdrItems = JsonArrayInsert(jHdrItems, jHdrOut);

    // ---- List template ----
    json jCrimeLbl = NuiLabel(NuiBind(PRISON_BIND_HIST_CRIME),
        JsonInt(NUI_HALIGN_LEFT), JsonInt(NUI_VALIGN_MIDDLE));
    jCrimeLbl = NuiStyleForegroundColor(jCrimeLbl, NuiBind(PRISON_BIND_HIST_COLOR));

    json jDateLbl = NuiLabel(NuiBind(PRISON_BIND_HIST_DATE),
        JsonInt(NUI_HALIGN_CENTER), JsonInt(NUI_VALIGN_MIDDLE));
    jDateLbl = NuiWidth(jDateLbl, fDateW);
    jDateLbl = NuiStyleForegroundColor(jDateLbl, NuiBind(PRISON_BIND_HIST_COLOR));

    json jOutLbl = NuiLabel(NuiBind(PRISON_BIND_HIST_OUT),
        JsonInt(NUI_HALIGN_CENTER), JsonInt(NUI_VALIGN_MIDDLE));
    jOutLbl = NuiWidth(jOutLbl, fOutW);
    jOutLbl = NuiStyleForegroundColor(jOutLbl, NuiBind(PRISON_BIND_HIST_COLOR));

    json jCellItems = JsonArray();
    jCellItems = JsonArrayInsert(jCellItems, jCrimeLbl);
    jCellItems = JsonArrayInsert(jCellItems, jDateLbl);
    jCellItems = JsonArrayInsert(jCellItems, jOutLbl);

    json jCell = NuiGroup(NuiRow(jCellItems), FALSE, NUI_SCROLLBARS_NONE);

    json jTmpl = JsonArrayInsert(JsonArray(), NuiListTemplateCell(jCell, 0.0, TRUE));
    json jList = NuiList(jTmpl, NuiBind(PRISON_BIND_HIST_CNT), fRowH);
    jList = NuiHeight(jList, GetNuiScaleDimension(oPC, 280.0));

    json jCol = JsonArray();
    jCol = JsonArrayInsert(jCol, NuiRow(jHdrItems));
    jCol = JsonArrayInsert(jCol, jList);
    jCol = JsonArrayInsert(jCol, NuiSpacer());

    return NuiCol(jCol);
}

// ----------------------------------------------------------------
// Window creation
// ----------------------------------------------------------------

void PrisonCreateWindow(object oPC)
{
    float fCX = (IntToFloat(GetPlayerDeviceProperty(oPC, PLAYER_DEVICE_PROPERTY_GUI_WIDTH))  - GetNuiScaleDimension(oPC, PRISON_W)) / 2.0;
    float fCY = (IntToFloat(GetPlayerDeviceProperty(oPC, PLAYER_DEVICE_PROPERTY_GUI_HEIGHT)) - GetNuiScaleDimension(oPC, PRISON_H)) / 2.0;
    json jGeom = NuiRect(fCX, fCY, GetNuiScaleDimension(oPC, PRISON_W), GetNuiScaleDimension(oPC, PRISON_H));

    float fBtnH = GetNuiScaleDimension(oPC, 28.0);
    float fTabW = GetNuiScaleDimension(oPC, 120.0);

    // ---- Title bar: label + close ----
    json jTitle = NuiLabel(JsonString("Więzienie Królewskie"),
        JsonInt(NUI_HALIGN_LEFT), JsonInt(NUI_VALIGN_MIDDLE));
    jTitle = NuiHeight(jTitle, fBtnH);

    json jClose = NuiButton(JsonString("X"));
    jClose = NuiId(jClose, PRISON_BTN_CLOSE);
    jClose = NuiWidth(jClose, GetNuiScaleDimension(oPC, 28.0));
    jClose = NuiHeight(jClose, fBtnH);

    json jTopItems = JsonArray();
    jTopItems = JsonArrayInsert(jTopItems, jTitle);
    jTopItems = JsonArrayInsert(jTopItems, NuiSpacer());
    jTopItems = JsonArrayInsert(jTopItems, jClose);

    // ---- Tab buttons ----
    json jTabStatus = NuiButton(JsonString("Stan"));
    jTabStatus = NuiId(jTabStatus, PRISON_BTN_TAB_STATUS);
    jTabStatus = NuiWidth(jTabStatus, fTabW);
    jTabStatus = NuiHeight(jTabStatus, fBtnH);

    json jTabHist = NuiButton(JsonString("Historia"));
    jTabHist = NuiId(jTabHist, PRISON_BTN_TAB_HISTORY);
    jTabHist = NuiWidth(jTabHist, fTabW);
    jTabHist = NuiHeight(jTabHist, fBtnH);

    json jTabItems = JsonArray();
    jTabItems = JsonArrayInsert(jTabItems, jTabStatus);
    jTabItems = JsonArrayInsert(jTabItems, jTabHist);
    jTabItems = JsonArrayInsert(jTabItems, NuiSpacer());

    // ---- Swap group ----
    json jSwapGrp = NuiGroup(PrisonBuildStatusPanel(oPC), FALSE, NUI_SCROLLBARS_NONE);
    jSwapGrp = NuiId(jSwapGrp, PRISON_GRP_SWAP);

    // ---- Root column ----
    json jRootItems = JsonArray();
    jRootItems = JsonArrayInsert(jRootItems, NuiRow(jTopItems));
    jRootItems = JsonArrayInsert(jRootItems, NuiRow(jTabItems));
    jRootItems = JsonArrayInsert(jRootItems, jSwapGrp);
    json jRoot = NuiCol(jRootItems);

    json jWin = NuiWindow(jRoot,
        JsonBool(FALSE),
        NuiBind(PRISON_WIN_GEOM),
        JsonBool(FALSE),
        JsonBool(FALSE),
        JsonBool(FALSE),
        JsonBool(FALSE),
        JsonBool(TRUE));

    int nToken = NuiCreate(oPC, jWin, PRISON_WINDOW, PRISON_EV_SCRIPT);
    NuiSetBind(oPC, nToken, PRISON_WIN_GEOM, jGeom);

    PrisonRefreshStatus(oPC, nToken);
}

// ----------------------------------------------------------------
// View switching
// ----------------------------------------------------------------

void PrisonOpenStatus(object oPC, int nToken)
{
    NuiSetGroupLayout(oPC, nToken, PRISON_GRP_SWAP, PrisonBuildStatusPanel(oPC));
    PrisonRefreshStatus(oPC, nToken);
}

void PrisonOpenHistory(object oPC, int nToken)
{
    NuiSetGroupLayout(oPC, nToken, PRISON_GRP_SWAP, PrisonBuildHistoryPanel(oPC));

    json jHistory = PrisonGetHistory(oPC);
    int nCount = JsonGetLength(jHistory);

    json jCrimes = JsonArray();
    json jDates  = JsonArray();
    json jOuts   = JsonArray();
    json jColors = JsonArray();

    int i;
    for(i = 0; i < nCount; i++)
    {
        json jRow    = JsonArrayGet(jHistory, i);
        string sCrime = JsonGetString(JsonObjectGet(jRow, "crime_desc"));
        int nAt      = JsonGetInt   (JsonObjectGet(jRow, "arrested_at"));
        string sOut  = JsonGetString(JsonObjectGet(jRow, "outcome"));

        jCrimes = JsonArrayInsert(jCrimes, JsonString(sCrime));
        jDates  = JsonArrayInsert(jDates,  JsonString(PrisonFormatDateSQL(nAt)));
        jOuts   = JsonArrayInsert(jOuts,   JsonString(PrisonOutcomeLabel(sOut)));
        jColors = JsonArrayInsert(jColors, PrisonOutcomeColor(sOut));
    }

    NuiSetBind(oPC, nToken, PRISON_BIND_HIST_CRIME, jCrimes);
    NuiSetBind(oPC, nToken, PRISON_BIND_HIST_DATE,  jDates);
    NuiSetBind(oPC, nToken, PRISON_BIND_HIST_OUT,   jOuts);
    NuiSetBind(oPC, nToken, PRISON_BIND_HIST_COLOR, jColors);
    NuiSetBind(oPC, nToken, PRISON_BIND_HIST_CNT,   JsonInt(nCount));
}

// ----------------------------------------------------------------
// Feed — populate status binds
// ----------------------------------------------------------------

void PrisonRefreshStatus(object oPC, int nToken)
{
    json jRec = PrisonGetActiveRecord(oPC);
    if(JsonGetType(jRec) == JSON_TYPE_NULL) return;

    int nLevel    = JsonGetInt   (JsonObjectGet(jRec, "crime_level"));
    string sDesc  = JsonGetString(JsonObjectGet(jRec, "crime_desc"));
    int nSentSec  = JsonGetInt   (JsonObjectGet(jRec, "sentence_sec"));
    int nEscAtt   = JsonGetInt   (JsonObjectGet(jRec, "esc_attempts"));
    int nRemaining = PrisonGetSecondsRemaining(oPC);

    int bLockdown = (nEscAtt >= PRISON_MAX_ESC_ATTEMPTS);
    int nBribeCost = PRISON_BRIBE_COST_BASE * nLevel;
    int bCanAfford = (GetGold(oPC) >= nBribeCost);

    int nPickDC = PRISON_PICK_DC_BASE + nLevel * 2;
    int nOverDC = PRISON_OVER_DC_BASE + nLevel * 2;

    string sSentMin = PrisonFormatSeconds(nSentSec);
    string sRemMin  = PrisonFormatSeconds((nRemaining > 0) ? nRemaining : 0);

    NuiSetBind(oPC, nToken, PRISON_BIND_CRIME_LBL, JsonString(sDesc));
    NuiSetBind(oPC, nToken, PRISON_BIND_LEVEL_LBL, JsonString(PrisonCrimeLevelLabel(nLevel)));
    NuiSetBind(oPC, nToken, PRISON_BIND_SENT_LBL,  JsonString(sSentMin));
    NuiSetBind(oPC, nToken, PRISON_BIND_TIME_LBL,  JsonString(sRemMin));
    NuiSetBind(oPC, nToken, PRISON_BIND_ATT_LBL,
        JsonString(IntToString(nEscAtt) + " / " + IntToString(PRISON_MAX_ESC_ATTEMPTS) +
            (bLockdown ? "  [ZAKAZ PRÓB]" : "")));

    NuiSetBind(oPC, nToken, PRISON_BIND_SERVE_ENA, JsonBool(TRUE));
    NuiSetBind(oPC, nToken, PRISON_BIND_BRIBE_ENA, JsonBool(!bLockdown));
    NuiSetBind(oPC, nToken, PRISON_BIND_PICK_ENA,  JsonBool(!bLockdown && PrisonHasThievesTools(oPC)));
    NuiSetBind(oPC, nToken, PRISON_BIND_OVER_ENA,  JsonBool(!bLockdown));

    NuiSetBind(oPC, nToken, PRISON_BIND_BRIBE_TIP,
        JsonString("Koszt: " + IntToString(nBribeCost) + " gp. Szansa: " +
            IntToString(PRISON_BRIBE_CHANCE) + "%. Przy niepowodzeniu — kara rośnie."));
    NuiSetBind(oPC, nToken, PRISON_BIND_PICK_TIP,
        JsonString("Wymaga wytrycha. Trudność zamku: DC " + IntToString(nPickDC) +
            ". Przy niepowodzeniu — nowe próby blokowane."));
    NuiSetBind(oPC, nToken, PRISON_BIND_OVER_TIP,
        JsonString("Test Siły DC " + IntToString(nOverDC) +
            ". Przy niepowodzeniu — 2 minuty dodatkowe i ogłuszenie."));
}

// ----------------------------------------------------------------
// Entry point
// ----------------------------------------------------------------

void PrisonShowWindow(object oPC)
{
    int nToken = NuiFindWindow(oPC, PRISON_WINDOW);
    if(nToken != 0)
    {
        PrisonOpenStatus(oPC, nToken);
        return;
    }
    PrisonCreateWindow(oPC);
}

// ----------------------------------------------------------------
// Heartbeat — checks countdown every 60 s
// ----------------------------------------------------------------

void PrisonHeartbeat(object oPC)
{
    if(!GetIsObjectValid(oPC)) return;
    if(!PrisonIsActive(oPC))
    {
        DeleteLocalInt(oPC, PRISON_LVAR_HB);
        return;
    }

    int nRemaining = PrisonGetSecondsRemaining(oPC);
    if(nRemaining <= 0)
    {
        PrisonReleasePlayer(oPC, "served");
        return;
    }

    int nToken = NuiFindWindow(oPC, PRISON_WINDOW);
    if(nToken != 0)
        PrisonRefreshStatus(oPC, nToken);

    DelayCommand(60.0, PrisonHeartbeat(oPC));
}

// ----------------------------------------------------------------
// Core mechanics
// ----------------------------------------------------------------

void PrisonArrestPlayer(object oPC, int nCrimeLevel, string sCrimeDesc)
{
    if(nCrimeLevel < 1) nCrimeLevel = 1;
    if(nCrimeLevel > 5) nCrimeLevel = 5;

    int nSentenceSec = PRISON_SENTENCE_BASE * nCrimeLevel;

    PrisonWriteActive(oPC, nCrimeLevel, sCrimeDesc, nSentenceSec);
    PrisonIssueWarrant(oPC, nCrimeLevel, sCrimeDesc);

    // Teleport to cell if waypoint exists
    object oCell = GetWaypointByTag("PRISON_CELL_WP");
    if(GetIsObjectValid(oCell))
        AssignCommand(oPC, JumpToObject(oCell));

    // Apply dazed visual
    effect eVfx = EffectVisualEffect(VFX_DUR_PROT_EPIC_ARMOR);
    ApplyEffectToObject(DURATION_TYPE_TEMPORARY, eVfx, oPC, 3.0);

    SendMessageToPC(oPC, "[Więzienie] Zostałeś aresztowany za: " + sCrimeDesc +
        ". Wyrok: " + PrisonFormatSeconds(nSentenceSec) + ".");
    SendMessageToPC(oPC, "[Więzienie] Cela zamknięta. Poczekaj lub spróbuj uciec.");

    // Delete any existing crime level var
    DeleteLocalInt(oPC, "PRISON_CRIME_LEVEL");

    PrisonShowWindow(oPC);

    // Start heartbeat if not already running
    if(!GetLocalInt(oPC, PRISON_LVAR_HB))
    {
        SetLocalInt(oPC, PRISON_LVAR_HB, 1);
        DelayCommand(60.0, PrisonHeartbeat(oPC));
    }
}

void PrisonReleasePlayer(object oPC, string sOutcome)
{
    json jRec = PrisonGetActiveRecord(oPC);
    if(JsonGetType(jRec) == JSON_TYPE_NULL) return;

    int nLevel   = JsonGetInt   (JsonObjectGet(jRec, "crime_level"));
    string sDesc = JsonGetString(JsonObjectGet(jRec, "crime_desc"));
    int nArr     = JsonGetInt   (JsonObjectGet(jRec, "arrested_at"));
    int nSent    = JsonGetInt   (JsonObjectGet(jRec, "sentence_sec"));

    PrisonWriteRecord(oPC, nLevel, sDesc, nArr, nSent, sOutcome);
    PrisonDeleteActive(oPC);
    PrisonClearWarrant(oPC);
    DeleteLocalInt(oPC, PRISON_LVAR_HB);

    // Close window
    int nToken = NuiFindWindow(oPC, PRISON_WINDOW);
    if(nToken != 0)
        NuiDestroy(oPC, nToken);

    // Teleport to release point if it exists
    object oRelease = GetWaypointByTag("PRISON_RELEASE_WP");
    if(GetIsObjectValid(oRelease))
        AssignCommand(oPC, JumpToObject(oRelease));

    string sMsgMap = "";
    if(sOutcome == "served")
        sMsgMap = "Kara odsiadzona. Bramy więzienia otwierają się przed tobą.";
    else if(sOutcome == "bribed")
        sMsgMap = "Strażnik chowa monety i uchyla kratę. Wolność smakuje złotem.";
    else if(sOutcome == "escaped")
        sMsgMap = "Zamek ustępuje. Uciekasz, nim ktokolwiek zauważy.";

    if(sMsgMap != "")
        SendMessageToPC(oPC, "[Więzienie] " + sMsgMap);
}

// ----------------------------------------------------------------
// Escape attempts
// ----------------------------------------------------------------

void PrisonTryBribe(object oPC, int nToken)
{
    json jRec = PrisonGetActiveRecord(oPC);
    if(JsonGetType(jRec) == JSON_TYPE_NULL) return;

    int nLevel   = JsonGetInt(JsonObjectGet(jRec, "crime_level"));
    int nCost    = PRISON_BRIBE_COST_BASE * nLevel;

    if(GetGold(oPC) < nCost)
    {
        SendMessageToPC(oPC, "[Więzienie] Nie masz dość złota. Potrzebujesz " +
            IntToString(nCost) + " gp.");
        return;
    }

    AssignCommand(oPC, TakeGoldFromCreature(nCost, oPC, TRUE));

    int bSuccess = (d100() <= PRISON_BRIBE_CHANCE);
    if(bSuccess)
    {
        SendMessageToPC(oPC, "[Więzienie] Strażnik liczy monety i kiwa głową. Szybko — nim zmieni zdanie.");
        PrisonReleasePlayer(oPC, "bribed");
    }
    else
    {
        int nExtra = PRISON_BRIBE_FAIL_EXTRA * nLevel;
        PrisonAddExtraTime(oPC, nExtra);
        PrisonIncrEscapeAttempts(oPC);
        SendMessageToPC(oPC, "[Więzienie] Strażnik bierze złoto i woła wartę. Kara wydłużona o " +
            IntToString(nExtra / 60) + " minut.");
        PrisonRefreshStatus(oPC, nToken);
    }
}

void PrisonTryPickLock(object oPC, int nToken)
{
    if(!PrisonHasThievesTools(oPC))
    {
        SendMessageToPC(oPC, "[Więzienie] Nie masz wytrycha.");
        return;
    }

    json jRec = PrisonGetActiveRecord(oPC);
    if(JsonGetType(jRec) == JSON_TYPE_NULL) return;

    int nLevel = JsonGetInt(JsonObjectGet(jRec, "crime_level"));
    int nDC    = PRISON_PICK_DC_BASE + nLevel * 2;

    int bSuccess = GetIsSkillSuccessful(oPC, SKILL_OPEN_LOCK, nDC);
    if(bSuccess)
    {
        SendMessageToPC(oPC, "[Więzienie] Zamek ustępuje z cichym kliknięciem. Wolność.");
        PrisonReleasePlayer(oPC, "escaped");
    }
    else
    {
        PrisonIncrEscapeAttempts(oPC);
        int nEscAtt = JsonGetInt(JsonObjectGet(PrisonGetActiveRecord(oPC), "esc_attempts"));
        if(nEscAtt >= PRISON_MAX_ESC_ATTEMPTS)
            SendMessageToPC(oPC, "[Więzienie] Strażnik słyszy skrzypienie. Kraty zostaną wzmocnione — nie masz już szans na ucieczkę.");
        else
            SendMessageToPC(oPC, "[Więzienie] Wytrych łamie się w zamku. Próba nieudana.");
        PrisonRefreshStatus(oPC, nToken);
    }
}

void PrisonTryOverpower(object oPC, int nToken)
{
    json jRec = PrisonGetActiveRecord(oPC);
    if(JsonGetType(jRec) == JSON_TYPE_NULL) return;

    int nLevel = JsonGetInt(JsonObjectGet(jRec, "crime_level"));
    int nDC    = PRISON_OVER_DC_BASE + nLevel * 2;
    int nRoll  = d20() + GetAbilityModifier(ABILITY_STRENGTH, oPC);

    if(nRoll >= nDC)
    {
        SendMessageToPC(oPC, "[Więzienie] Rzucasz się na strażnika. Pada bez świadomości.");
        PrisonReleasePlayer(oPC, "escaped");
    }
    else
    {
        PrisonAddExtraTime(oPC, PRISON_OVER_FAIL_EXTRA);
        PrisonIncrEscapeAttempts(oPC);
        // Apply stun
        effect eStun = EffectStunned();
        ApplyEffectToObject(DURATION_TYPE_TEMPORARY, eStun, oPC, 30.0);
        int nEscAtt = JsonGetInt(JsonObjectGet(PrisonGetActiveRecord(oPC), "esc_attempts"));
        if(nEscAtt >= PRISON_MAX_ESC_ATTEMPTS)
            SendMessageToPC(oPC, "[Więzienie] Strażnik rzuca cię o ziemię. Następują kajdany. Nie wstaniesz stąd siłą.");
        else
            SendMessageToPC(oPC, "[Więzienie] Strażnik okazuje się silniejszy. Dostajesz obuchem w głowę.");
        PrisonRefreshStatus(oPC, nToken);
    }
}
