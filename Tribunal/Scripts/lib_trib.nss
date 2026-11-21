#include "lib_trib_def"

// ----------------------------------------------------------------
// Helpers
// ----------------------------------------------------------------

string TribVerdictLabel(int nVerdict)
{
    switch(nVerdict)
    {
        case TRIB_VERDICT_INNOCENT: return "Niewinny";
        case TRIB_VERDICT_JAIL:     return "Uwięziony";
        case TRIB_VERDICT_EXILE:    return "Wygnanie";
        case TRIB_VERDICT_DEATH:    return "Wyrok Śmierci";
    }
    return "W toku";
}

json TribVerdictColor(int nVerdict)
{
    switch(nVerdict)
    {
        case TRIB_VERDICT_INNOCENT: return NuiColor(100, 220, 100);
        case TRIB_VERDICT_JAIL:     return NuiColor(220, 180,  60);
        case TRIB_VERDICT_EXILE:    return NuiColor(200, 100,  40);
        case TRIB_VERDICT_DEATH:    return NuiColor(220,  50,  50);
    }
    return NuiColor(180, 180, 180);
}

// ----------------------------------------------------------------
// Case-list view
// ----------------------------------------------------------------

json BuildTribCaseListView(object oPC)
{
    float fBtnH  = GetNuiScaleDimension(oPC, 30.0);
    float fRowH  = GetNuiScaleDimension(oPC, 26.0);
    float fListH = GetNuiScaleDimension(oPC, 400.0);

    json jHdr = NuiLabel(JsonString("Sprawy Trybunału Inkwizycji"),
                         JsonInt(NUI_HALIGN_CENTER), JsonInt(NUI_VALIGN_MIDDLE));
    jHdr = NuiHeight(jHdr, fBtnH);

    float fNameW   = GetNuiScaleDimension(oPC, 190.0);
    float fStatusW = GetNuiScaleDimension(oPC, 120.0);

    json jNameLbl = NuiLabel(NuiBind(TRIB_BIND_LIST_NAME),
                             JsonInt(NUI_HALIGN_LEFT), JsonInt(NUI_VALIGN_MIDDLE));
    jNameLbl = NuiStyleForegroundColor(jNameLbl, NuiBind(TRIB_BIND_LIST_COLOR));

    json jChargeLbl = NuiLabel(NuiBind(TRIB_BIND_LIST_CHARGE),
                               JsonInt(NUI_HALIGN_LEFT), JsonInt(NUI_VALIGN_MIDDLE));
    jChargeLbl = NuiStyleForegroundColor(jChargeLbl, NuiBind(TRIB_BIND_LIST_COLOR));

    json jStatusLbl = NuiLabel(NuiBind(TRIB_BIND_LIST_STATUS),
                               JsonInt(NUI_HALIGN_CENTER), JsonInt(NUI_VALIGN_MIDDLE));
    jStatusLbl = NuiWidth(jStatusLbl, fStatusW);
    jStatusLbl = NuiStyleForegroundColor(jStatusLbl, NuiBind(TRIB_BIND_LIST_COLOR));

    json jCellCols = JsonArray();
    jCellCols = JsonArrayInsert(jCellCols,
        NuiWidth(NuiCol(JsonArrayInsert(JsonArray(), jNameLbl)), fNameW));
    jCellCols = JsonArrayInsert(jCellCols, jChargeLbl);
    jCellCols = JsonArrayInsert(jCellCols, jStatusLbl);

    json jCell = NuiGroup(NuiRow(jCellCols), TRUE, NUI_SCROLLBARS_NONE);
    jCell = NuiId(jCell, TRIB_BTN_ROW);
    jCell = NuiEncouraged(jCell, NuiBind(TRIB_BIND_LIST_ENC));

    json jTmpl = JsonArrayInsert(JsonArray(), NuiListTemplateCell(jCell, 0.0, TRUE));
    json jList = NuiList(jTmpl, NuiBind(TRIB_BIND_LIST_COUNT), fRowH);
    jList = NuiHeight(jList, fListH);

    json jAccuseBtn = NuiButton(JsonString("Złóż Oskarżenie"));
    jAccuseBtn = NuiId(jAccuseBtn, TRIB_BTN_ACCUSE);
    jAccuseBtn = NuiWidth(jAccuseBtn, GetNuiScaleDimension(oPC, 180.0));
    jAccuseBtn = NuiHeight(jAccuseBtn, fBtnH);

    json jBotRow = JsonArray();
    jBotRow = JsonArrayInsert(jBotRow, NuiSpacer());
    jBotRow = JsonArrayInsert(jBotRow, jAccuseBtn);

    json jCol = JsonArray();
    jCol = JsonArrayInsert(jCol, jHdr);
    jCol = JsonArrayInsert(jCol, jList);
    jCol = JsonArrayInsert(jCol, NuiRow(jBotRow));

    json jSide     = NuiCol(JsonArrayInsert(JsonArray(), NuiSpacer()));
    float fContent = GetNuiScaleDimension(oPC, 680.0);
    json jRoot = JsonArray();
    jRoot = JsonArrayInsert(jRoot, jSide);
    jRoot = JsonArrayInsert(jRoot, NuiWidth(NuiCol(jCol), fContent));
    jRoot = JsonArrayInsert(jRoot, jSide);
    return NuiRow(jRoot);
}

// ----------------------------------------------------------------
// Case-detail view
// ----------------------------------------------------------------

json BuildTribDetailView(object oPC)
{
    float fBtnH   = GetNuiScaleDimension(oPC, 30.0);
    float fFieldH = GetNuiScaleDimension(oPC, 90.0);
    float fSentH  = GetNuiScaleDimension(oPC, 28.0);
    float fLblH   = GetNuiScaleDimension(oPC, 22.0);

    json jHdr = NuiLabel(NuiBind(TRIB_BIND_DETAIL_HDR),
                         JsonInt(NUI_HALIGN_LEFT), JsonInt(NUI_VALIGN_MIDDLE));
    jHdr = NuiHeight(jHdr, GetNuiScaleDimension(oPC, 28.0));

    json jChargeLbl = NuiLabel(NuiBind(TRIB_BIND_DETAIL_CHARGE),
                               JsonInt(NUI_HALIGN_LEFT), JsonInt(NUI_VALIGN_MIDDLE));
    jChargeLbl = NuiHeight(jChargeLbl, fLblH);

    json jAccLbl = NuiLabel(NuiBind(TRIB_BIND_DETAIL_ACC),
                            JsonInt(NUI_HALIGN_LEFT), JsonInt(NUI_VALIGN_MIDDLE));
    jAccLbl = NuiHeight(jAccLbl, fLblH);

    json jEvidSectionLbl = NuiLabel(JsonString("Dowody Inkwizycji:"),
                                    JsonInt(NUI_HALIGN_LEFT), JsonInt(NUI_VALIGN_MIDDLE));
    jEvidSectionLbl = NuiHeight(jEvidSectionLbl, fLblH);

    json jEvidTxt = NuiGroup(NuiText(NuiBind(TRIB_BIND_EVIDENCE_TXT), FALSE),
                             TRUE, NUI_SCROLLBARS_AUTO);
    jEvidTxt = NuiHeight(jEvidTxt, fFieldH);

    json jDefSectionLbl = NuiLabel(JsonString("Zeznanie Obrony:"),
                                   JsonInt(NUI_HALIGN_LEFT), JsonInt(NUI_VALIGN_MIDDLE));
    jDefSectionLbl = NuiHeight(jDefSectionLbl, fLblH);

    json jDefEdit = NuiTextEdit(JsonString(""), NuiBind(TRIB_BIND_DEFENSE_TXT),
                                TRIB_MAX_DEFENSE, TRUE);
    jDefEdit = NuiEnabled(jDefEdit, NuiBind(TRIB_BIND_DEF_ENA));
    jDefEdit = NuiHeight(jDefEdit, fFieldH);

    json jStatusLbl = NuiLabel(NuiBind(TRIB_BIND_STATUS_LBL),
                               JsonInt(NUI_HALIGN_CENTER), JsonInt(NUI_VALIGN_MIDDLE));
    jStatusLbl = NuiHeight(jStatusLbl, fLblH);

    // Sentence input (judge fills before clicking verdict)
    json jSentSection = NuiLabel(JsonString("Uzasadnienie wyroku:"),
                                 JsonInt(NUI_HALIGN_LEFT), JsonInt(NUI_VALIGN_MIDDLE));
    jSentSection = NuiHeight(jSentSection, fLblH);

    json jSentEdit = NuiTextEdit(JsonString(""), NuiBind(TRIB_BIND_SENTENCE_TXT),
                                 TRIB_MAX_SENTENCE, FALSE);
    jSentEdit = NuiEnabled(jSentEdit, NuiBind(TRIB_BIND_VERDICT_ENA));
    jSentEdit = NuiHeight(jSentEdit, fSentH);

    // Four verdict buttons
    float fVerdW = GetNuiScaleDimension(oPC, 148.0);

    json jJailBtn = NuiButton(JsonString("Uwięziony"));
    jJailBtn = NuiId(jJailBtn, TRIB_BTN_GUILTY_JAIL);
    jJailBtn = NuiEnabled(jJailBtn, NuiBind(TRIB_BIND_VERDICT_ENA));
    jJailBtn = NuiWidth(jJailBtn, fVerdW);
    jJailBtn = NuiHeight(jJailBtn, fBtnH);
    jJailBtn = NuiTooltip(jJailBtn, JsonString("Skazuje oskarżonego na dożywotnie więzienie."));

    json jExileBtn = NuiButton(JsonString("Wygnanie"));
    jExileBtn = NuiId(jExileBtn, TRIB_BTN_GUILTY_EXILE);
    jExileBtn = NuiEnabled(jExileBtn, NuiBind(TRIB_BIND_VERDICT_ENA));
    jExileBtn = NuiWidth(jExileBtn, fVerdW);
    jExileBtn = NuiHeight(jExileBtn, fBtnH);
    jExileBtn = NuiTooltip(jExileBtn, JsonString("Wypędza oskarżonego z terytorium. Pieczęć wygnania nie może być zdjęta bez Trybunału."));

    json jDeathBtn = NuiButton(JsonString("Wyrok Śmierci"));
    jDeathBtn = NuiId(jDeathBtn, TRIB_BTN_GUILTY_DEATH);
    jDeathBtn = NuiEnabled(jDeathBtn, NuiBind(TRIB_BIND_VERDICT_ENA));
    jDeathBtn = NuiWidth(jDeathBtn, fVerdW);
    jDeathBtn = NuiHeight(jDeathBtn, fBtnH);
    jDeathBtn = NuiTooltip(jDeathBtn, JsonString("Naznacza oskarżonego piętnem śmierci. Każdy gracz może go bezkarnie zabić."));

    json jInnocentBtn = NuiButton(JsonString("Niewinny"));
    jInnocentBtn = NuiId(jInnocentBtn, TRIB_BTN_INNOCENT);
    jInnocentBtn = NuiEnabled(jInnocentBtn, NuiBind(TRIB_BIND_VERDICT_ENA));
    jInnocentBtn = NuiWidth(jInnocentBtn, fVerdW);
    jInnocentBtn = NuiHeight(jInnocentBtn, fBtnH);
    jInnocentBtn = NuiTooltip(jInnocentBtn, JsonString("Oczyszcza oskarżonego z zarzutów. Znosi wszelkie kary."));

    json jVerdRow = JsonArray();
    jVerdRow = JsonArrayInsert(jVerdRow, jJailBtn);
    jVerdRow = JsonArrayInsert(jVerdRow, jExileBtn);
    jVerdRow = JsonArrayInsert(jVerdRow, jDeathBtn);
    jVerdRow = JsonArrayInsert(jVerdRow, jInnocentBtn);

    // Bottom action bar
    json jBackBtn = NuiButton(JsonString("Wróć"));
    jBackBtn = NuiId(jBackBtn, TRIB_BTN_BACK);
    jBackBtn = NuiWidth(jBackBtn, GetNuiScaleDimension(oPC, 80.0));
    jBackBtn = NuiHeight(jBackBtn, fBtnH);

    json jSubDefBtn = NuiButton(JsonString("Złóż Zeznanie"));
    jSubDefBtn = NuiId(jSubDefBtn, TRIB_BTN_SUBMIT_DEF);
    jSubDefBtn = NuiEnabled(jSubDefBtn, NuiBind(TRIB_BIND_DEF_ENA));
    jSubDefBtn = NuiWidth(jSubDefBtn, GetNuiScaleDimension(oPC, 140.0));
    jSubDefBtn = NuiHeight(jSubDefBtn, fBtnH);

    json jSubEvidBtn = NuiButton(JsonString("Zaktualizuj Dowody"));
    jSubEvidBtn = NuiId(jSubEvidBtn, TRIB_BTN_SUBMIT_EVID);
    jSubEvidBtn = NuiEnabled(jSubEvidBtn, NuiBind(TRIB_BIND_VERDICT_ENA));
    jSubEvidBtn = NuiWidth(jSubEvidBtn, GetNuiScaleDimension(oPC, 160.0));
    jSubEvidBtn = NuiHeight(jSubEvidBtn, fBtnH);

    json jBotRow = JsonArray();
    jBotRow = JsonArrayInsert(jBotRow, jBackBtn);
    jBotRow = JsonArrayInsert(jBotRow, NuiSpacer());
    jBotRow = JsonArrayInsert(jBotRow, jSubDefBtn);
    jBotRow = JsonArrayInsert(jBotRow, jSubEvidBtn);

    json jCol = JsonArray();
    jCol = JsonArrayInsert(jCol, jHdr);
    jCol = JsonArrayInsert(jCol, jChargeLbl);
    jCol = JsonArrayInsert(jCol, jAccLbl);
    jCol = JsonArrayInsert(jCol, jEvidSectionLbl);
    jCol = JsonArrayInsert(jCol, jEvidTxt);
    jCol = JsonArrayInsert(jCol, jDefSectionLbl);
    jCol = JsonArrayInsert(jCol, jDefEdit);
    jCol = JsonArrayInsert(jCol, jStatusLbl);
    jCol = JsonArrayInsert(jCol, jSentSection);
    jCol = JsonArrayInsert(jCol, jSentEdit);
    jCol = JsonArrayInsert(jCol, NuiRow(jVerdRow));
    jCol = JsonArrayInsert(jCol, NuiRow(jBotRow));

    json jSide     = NuiCol(JsonArrayInsert(JsonArray(), NuiSpacer()));
    float fContent = GetNuiScaleDimension(oPC, 680.0);
    json jRoot = JsonArray();
    jRoot = JsonArrayInsert(jRoot, jSide);
    jRoot = JsonArrayInsert(jRoot, NuiWidth(NuiCol(jCol), fContent));
    jRoot = JsonArrayInsert(jRoot, jSide);
    return NuiRow(jRoot);
}

// ----------------------------------------------------------------
// Accuse view
// ----------------------------------------------------------------

json BuildTribAccuseView(object oPC)
{
    float fBtnH  = GetNuiScaleDimension(oPC, 30.0);
    float fEvidH = GetNuiScaleDimension(oPC, 200.0);
    float fLblH  = GetNuiScaleDimension(oPC, 22.0);

    json jHdr = NuiLabel(JsonString("Złóż Oskarżenie przed Inkwizycją"),
                         JsonInt(NUI_HALIGN_CENTER), JsonInt(NUI_VALIGN_MIDDLE));
    jHdr = NuiHeight(jHdr, fBtnH);

    // Target selection row
    json jTargetLbl = NuiLabel(NuiBind(TRIB_BIND_TARGET_LBL),
                               JsonInt(NUI_HALIGN_LEFT), JsonInt(NUI_VALIGN_MIDDLE));

    json jSearchEdit = NuiTextEdit(JsonString("Szukaj po imieniu..."),
                                   NuiBind(TRIB_BIND_SEARCH_TXT), 40, FALSE);
    jSearchEdit = NuiWidth(jSearchEdit, GetNuiScaleDimension(oPC, 200.0));
    jSearchEdit = NuiHeight(jSearchEdit, fBtnH);

    json jSearchBtn = NuiButton(JsonString("Szukaj"));
    jSearchBtn = NuiId(jSearchBtn, TRIB_BTN_SEARCH);
    jSearchBtn = NuiWidth(jSearchBtn, GetNuiScaleDimension(oPC, 80.0));
    jSearchBtn = NuiHeight(jSearchBtn, fBtnH);

    json jTargetRow = JsonArray();
    jTargetRow = JsonArrayInsert(jTargetRow, jTargetLbl);
    jTargetRow = JsonArrayInsert(jTargetRow, NuiSpacer());
    jTargetRow = JsonArrayInsert(jTargetRow, jSearchEdit);
    jTargetRow = JsonArrayInsert(jTargetRow, jSearchBtn);

    // Charge row
    json jChargePfx = NuiLabel(JsonString("Zarzut:"),
                               JsonInt(NUI_HALIGN_LEFT), JsonInt(NUI_VALIGN_MIDDLE));
    jChargePfx = NuiWidth(jChargePfx, GetNuiScaleDimension(oPC, 80.0));
    jChargePfx = NuiHeight(jChargePfx, fBtnH);

    json jChargeEdit = NuiTextEdit(JsonString(""), NuiBind(TRIB_BIND_CHARGE_TXT),
                                   TRIB_MAX_CHARGE, FALSE);
    jChargeEdit = NuiHeight(jChargeEdit, fBtnH);

    json jChargeRow = JsonArray();
    jChargeRow = JsonArrayInsert(jChargeRow, jChargePfx);
    jChargeRow = JsonArrayInsert(jChargeRow, jChargeEdit);

    // Evidence block
    json jEvidPfx = NuiLabel(JsonString("Dowody (opcjonalnie):"),
                             JsonInt(NUI_HALIGN_LEFT), JsonInt(NUI_VALIGN_MIDDLE));
    jEvidPfx = NuiHeight(jEvidPfx, fLblH);

    json jEvidEdit = NuiTextEdit(JsonString(""), NuiBind(TRIB_BIND_EVID2_TXT),
                                 TRIB_MAX_EVIDENCE, TRUE);
    jEvidEdit = NuiHeight(jEvidEdit, fEvidH);

    // Bottom bar
    json jSubmitBtn = NuiButton(JsonString("Złóż Oskarżenie"));
    jSubmitBtn = NuiId(jSubmitBtn, TRIB_BTN_SUBMIT_ACC);
    jSubmitBtn = NuiEnabled(jSubmitBtn, NuiBind(TRIB_BIND_SUBMIT_ENA));
    jSubmitBtn = NuiWidth(jSubmitBtn, GetNuiScaleDimension(oPC, 180.0));
    jSubmitBtn = NuiHeight(jSubmitBtn, fBtnH);

    json jBackBtn = NuiButton(JsonString("Anuluj"));
    jBackBtn = NuiId(jBackBtn, TRIB_BTN_BACK);
    jBackBtn = NuiWidth(jBackBtn, GetNuiScaleDimension(oPC, 80.0));
    jBackBtn = NuiHeight(jBackBtn, fBtnH);

    json jBotRow = JsonArray();
    jBotRow = JsonArrayInsert(jBotRow, jBackBtn);
    jBotRow = JsonArrayInsert(jBotRow, NuiSpacer());
    jBotRow = JsonArrayInsert(jBotRow, jSubmitBtn);

    json jCol = JsonArray();
    jCol = JsonArrayInsert(jCol, jHdr);
    jCol = JsonArrayInsert(jCol, NuiRow(jTargetRow));
    jCol = JsonArrayInsert(jCol, NuiRow(jChargeRow));
    jCol = JsonArrayInsert(jCol, jEvidPfx);
    jCol = JsonArrayInsert(jCol, jEvidEdit);
    jCol = JsonArrayInsert(jCol, NuiRow(jBotRow));

    json jSide     = NuiCol(JsonArrayInsert(JsonArray(), NuiSpacer()));
    float fContent = GetNuiScaleDimension(oPC, 680.0);
    json jRoot = JsonArray();
    jRoot = JsonArrayInsert(jRoot, jSide);
    jRoot = JsonArrayInsert(jRoot, NuiWidth(NuiCol(jCol), fContent));
    jRoot = JsonArrayInsert(jRoot, jSide);
    return NuiRow(jRoot);
}

// ----------------------------------------------------------------
// Window open / view swap
// ----------------------------------------------------------------

void TribOpenWindow(object oPC)
{
    if(NuiFindWindow(oPC, TRIB_WINDOW) != 0)
    {
        NuiSetGroupLayout(oPC, NuiFindWindow(oPC, TRIB_WINDOW),
                          TRIB_GRP_SWAP, BuildTribCaseListView(oPC));
        SwapToCaseListView(oPC, NuiFindWindow(oPC, TRIB_WINDOW));
        return;
    }

    float fCX = (IntToFloat(GetPlayerDeviceProperty(oPC, PLAYER_DEVICE_PROPERTY_GUI_WIDTH))
                 - GetNuiScaleDimension(oPC, TRIB_W)) / 2.0;
    float fCY = (IntToFloat(GetPlayerDeviceProperty(oPC, PLAYER_DEVICE_PROPERTY_GUI_HEIGHT))
                 - GetNuiScaleDimension(oPC, TRIB_H)) / 2.0;
    json jGeom = NuiRect(fCX, fCY,
                         GetNuiScaleDimension(oPC, TRIB_W),
                         GetNuiScaleDimension(oPC, TRIB_H));

    float fBtnH = GetNuiScaleDimension(oPC, 30.0);
    json jCloseBtn = NuiButton(JsonString("X"));
    jCloseBtn = NuiId(jCloseBtn, TRIB_BTN_CLOSE);
    jCloseBtn = NuiWidth(jCloseBtn, GetNuiScaleDimension(oPC, 30.0));
    jCloseBtn = NuiHeight(jCloseBtn, fBtnH);

    json jTopBar = JsonArray();
    jTopBar = JsonArrayInsert(jTopBar, NuiSpacer());
    jTopBar = JsonArrayInsert(jTopBar, jCloseBtn);

    json jSwapGrp = NuiGroup(BuildTribCaseListView(oPC), FALSE, NUI_SCROLLBARS_NONE);
    jSwapGrp = NuiId(jSwapGrp, TRIB_GRP_SWAP);

    json jRootChildren = JsonArray();
    jRootChildren = JsonArrayInsert(jRootChildren, NuiRow(jTopBar));
    jRootChildren = JsonArrayInsert(jRootChildren, jSwapGrp);

    json jWin = NuiWindow(NuiCol(jRootChildren),
        JsonBool(FALSE),
        NuiBind(TRIB_WIN_GEOM),
        JsonBool(FALSE), JsonBool(FALSE),
        JsonBool(FALSE), JsonBool(TRUE),
        JsonBool(FALSE));

    int nToken = NuiCreate(oPC, jWin, TRIB_WINDOW, TRIB_EV_SCRIPT);
    NuiSetBind(oPC, nToken, TRIB_WIN_GEOM, jGeom);

    SwapToCaseListView(oPC, nToken);
}

void SwapToCaseListView(object oPC, int nToken)
{
    NuiSetGroupLayout(oPC, nToken, TRIB_GRP_SWAP, BuildTribCaseListView(oPC));
    DeleteLocalInt(oPC, TRIB_LVAR_CASE_ID);
    FeedCaseList(oPC, nToken);
}

void SwapToCaseDetailView(object oPC, int nToken, int nCaseId)
{
    NuiSetGroupLayout(oPC, nToken, TRIB_GRP_SWAP, BuildTribDetailView(oPC));
    SetLocalInt(oPC, TRIB_LVAR_CASE_ID, nCaseId);
    FeedCaseDetail(oPC, nToken, nCaseId);
}

void SwapToAccuseView(object oPC, int nToken)
{
    DeleteLocalString(oPC, TRIB_LVAR_TARGET_UUID);
    DeleteLocalString(oPC, TRIB_LVAR_TARGET_NAME);
    NuiSetGroupLayout(oPC, nToken, TRIB_GRP_SWAP, BuildTribAccuseView(oPC));
    FeedAccuseView(oPC, nToken);
    NuiSetBindWatch(oPC, nToken, TRIB_BIND_CHARGE_TXT, TRUE);
}

// ----------------------------------------------------------------
// Feed – case list
// ----------------------------------------------------------------

void FeedCaseList(object oPC, int nToken)
{
    json jCases = TribGetAllCases();
    int  nCount = JsonGetLength(jCases);

    json jNames    = JsonArray();
    json jCharges  = JsonArray();
    json jStatuses = JsonArray();
    json jColors   = JsonArray();
    json jEncs     = JsonArray();

    int i;
    for(i = 0; i < nCount; i++)
    {
        json jRow    = JsonArrayGet(jCases, i);
        string sDef  = JsonGetString(JsonObjectGet(jRow, "defendant_name"));
        string sChg  = JsonGetString(JsonObjectGet(jRow, "charge"));
        int nVerdict = JsonGetInt   (JsonObjectGet(jRow, "verdict"));

        jNames    = JsonArrayInsert(jNames,    JsonString(sDef));
        jCharges  = JsonArrayInsert(jCharges,  JsonString(sChg));
        jStatuses = JsonArrayInsert(jStatuses, JsonString(TribVerdictLabel(nVerdict)));
        jColors   = JsonArrayInsert(jColors,   TribVerdictColor(nVerdict));
        jEncs     = JsonArrayInsert(jEncs,     JsonBool(FALSE));
    }

    NuiSetBind(oPC, nToken, TRIB_BIND_LIST_NAME,   jNames);
    NuiSetBind(oPC, nToken, TRIB_BIND_LIST_CHARGE,  jCharges);
    NuiSetBind(oPC, nToken, TRIB_BIND_LIST_STATUS,  jStatuses);
    NuiSetBind(oPC, nToken, TRIB_BIND_LIST_COLOR,   jColors);
    NuiSetBind(oPC, nToken, TRIB_BIND_LIST_ENC,     jEncs);
    NuiSetBind(oPC, nToken, TRIB_BIND_LIST_COUNT,   JsonInt(nCount));
}

// ----------------------------------------------------------------
// Feed – case detail
// ----------------------------------------------------------------

void FeedCaseDetail(object oPC, int nToken, int nCaseId)
{
    json jCase = TribGetCase(nCaseId);
    if(JsonGetType(jCase) == JSON_TYPE_NULL)
    {
        SwapToCaseListView(oPC, nToken);
        return;
    }

    string sDefName  = JsonGetString(JsonObjectGet(jCase, "defendant_name"));
    string sAccName  = JsonGetString(JsonObjectGet(jCase, "accuser_name"));
    string sCharge   = JsonGetString(JsonObjectGet(jCase, "charge"));
    string sEvidence = JsonGetString(JsonObjectGet(jCase, "evidence"));
    string sDefense  = JsonGetString(JsonObjectGet(jCase, "defense"));
    string sSentence = JsonGetString(JsonObjectGet(jCase, "sentence"));
    int    nVerdict  = JsonGetInt   (JsonObjectGet(jCase, "verdict"));
    int    nCreated  = JsonGetInt   (JsonObjectGet(jCase, "created_at"));
    string sDefUUID  = JsonGetString(JsonObjectGet(jCase, "defendant_uuid"));
    string sAccUUID  = JsonGetString(JsonObjectGet(jCase, "accuser_uuid"));

    string sHdr = "Sprawa #" + IntToString(nCaseId)
                  + "  —  " + sDefName
                  + "  —  " + TribFormatDateSQL(nCreated);

    string sEvidDisplay = sEvidence;
    if(sEvidDisplay == "") sEvidDisplay = "(Inkwizycja nie przedstawiła jeszcze dowodów)";

    NuiSetBind(oPC, nToken, TRIB_BIND_DETAIL_HDR,    JsonString(sHdr));
    NuiSetBind(oPC, nToken, TRIB_BIND_DETAIL_CHARGE,
               JsonString("Zarzut: " + sCharge));
    NuiSetBind(oPC, nToken, TRIB_BIND_DETAIL_ACC,
               JsonString("Oskarżyciel: " + sAccName));
    NuiSetBind(oPC, nToken, TRIB_BIND_EVIDENCE_TXT,  JsonString(sEvidDisplay));
    NuiSetBind(oPC, nToken, TRIB_BIND_DEFENSE_TXT,   JsonString(sDefense));
    NuiSetBind(oPC, nToken, TRIB_BIND_SENTENCE_TXT,  JsonString(sSentence));
    NuiSetBind(oPC, nToken, TRIB_BIND_STATUS_LBL,
               JsonString("Status: " + TribVerdictLabel(nVerdict)));

    string sMyUUID = GetObjectUUID(oPC);
    int bIsJudge   = GetIsDM(oPC);
    int bIsDef     = (sMyUUID == sDefUUID);
    int bIsAcc     = (sMyUUID == sAccUUID);
    int bPending   = (nVerdict == TRIB_VERDICT_PENDING);

    // Verdict buttons and evidence editing: DM only, pending cases only
    NuiSetBind(oPC, nToken, TRIB_BIND_VERDICT_ENA, JsonBool(bIsJudge && bPending));
    // Defense textarea: defendant or accuser (supplementing evidence) while pending
    NuiSetBind(oPC, nToken, TRIB_BIND_DEF_ENA,     JsonBool((bIsDef || bIsAcc) && bPending));

    NuiSetBindWatch(oPC, nToken, TRIB_BIND_DEFENSE_TXT, bPending);
}

// ----------------------------------------------------------------
// Feed – accuse view
// ----------------------------------------------------------------

void FeedAccuseView(object oPC, int nToken)
{
    string sName  = GetLocalString(oPC, TRIB_LVAR_TARGET_NAME);
    int    bHas   = (sName != "");

    NuiSetBind(oPC, nToken, TRIB_BIND_TARGET_LBL,
               JsonString(bHas ? "Oskarżony: " + sName : "Oskarżony: (nie wybrano)"));
    NuiSetBind(oPC, nToken, TRIB_BIND_SEARCH_TXT,  JsonString(""));
    NuiSetBind(oPC, nToken, TRIB_BIND_CHARGE_TXT,  JsonString(""));
    NuiSetBind(oPC, nToken, TRIB_BIND_EVID2_TXT,   JsonString(""));
    NuiSetBind(oPC, nToken, TRIB_BIND_SUBMIT_ENA,  JsonBool(FALSE));
}

// ----------------------------------------------------------------
// Verdict enforcement – game consequences
// ----------------------------------------------------------------

void TribApplyVerdict(object oPC, int nCaseId, int nVerdict, string sSentence)
{
    json jCase = TribGetCase(nCaseId);
    if(JsonGetType(jCase) == JSON_TYPE_NULL) return;
    if(JsonGetInt(JsonObjectGet(jCase, "verdict")) != TRIB_VERDICT_PENDING) return;

    string sDefUUID = JsonGetString(JsonObjectGet(jCase, "defendant_uuid"));
    string sDefName = JsonGetString(JsonObjectGet(jCase, "defendant_name"));

    TribSetVerdict(nCaseId, nVerdict, sSentence);

    // Build global announcement
    string sVerd = TribVerdictLabel(nVerdict);
    string sMsg  = "[Trybunał] Wyrok w sprawie " + sDefName + ": " + sVerd + ".";
    if(sSentence != "") sMsg = sMsg + " " + sSentence;

    // Broadcast to all online players
    object oBroadcast = GetFirstPC();
    while(GetIsObjectValid(oBroadcast))
    {
        SendMessageToPC(oBroadcast, sMsg);
        oBroadcast = GetNextPC();
    }

    // Find defendant online; effects only apply if present
    object oTarget = GetFirstPC();
    while(GetIsObjectValid(oTarget))
    {
        if(GetObjectUUID(oTarget) == sDefUUID) break;
        oTarget = GetNextPC();
    }
    if(!GetIsObjectValid(oTarget)) return;

    switch(nVerdict)
    {
        case TRIB_VERDICT_JAIL:
            SetLocalInt(oTarget, TRIB_LVAR_IMPRISONED, 1);
            // Slow + ethereal shimmer as visual marker; other systems check TRIB_IMPRISONED
            ApplyEffectToObject(DURATION_TYPE_PERMANENT,
                EffectLinkEffects(EffectSlow(),
                    EffectVisualEffect(VFX_DUR_ETHEREAL_VISAGE)),
                oTarget);
            FloatingTextStringOnCreature(
                "Pieczęć Inkwizycji oplata cię łańcuchami winy. Nie ma ucieczki.",
                oTarget, FALSE);
            break;

        case TRIB_VERDICT_EXILE:
            SetLocalInt(oTarget, TRIB_LVAR_EXILED, 1);
            FloatingTextStringOnCreature(
                "Wygnanie! Piętno Trybunału wskazuje ci bramę. Nie wracaj.",
                oTarget, FALSE);
            // Jump to exile landing waypoint if placed in the module
            object oExile = GetWaypointByTag(TRIB_EXILE_AREA_TAG);
            if(GetIsObjectValid(oExile))
                AssignCommand(oTarget, ActionJumpToObject(oExile, FALSE));
            break;

        case TRIB_VERDICT_DEATH:
            SetLocalInt(oTarget, TRIB_LVAR_DEATH_MARK, 1);
            // Persistent evil aura marks the condemned visually
            ApplyEffectToObject(DURATION_TYPE_PERMANENT,
                EffectVisualEffect(VFX_DUR_EVIL_PROTECTION),
                oTarget);
            FloatingTextStringOnCreature(
                "Nosisz piętno wyroku śmierci. Inkwizycja wyciągnie ku tobie rękę.",
                oTarget, FALSE);
            break;

        case TRIB_VERDICT_INNOCENT:
            // Clear all tribunal state and remove penalty effects
            DeleteLocalInt(oTarget, TRIB_LVAR_IMPRISONED);
            DeleteLocalInt(oTarget, TRIB_LVAR_EXILED);
            DeleteLocalInt(oTarget, TRIB_LVAR_DEATH_MARK);
            RemoveAllEffects(oTarget);
            ApplyEffectToObject(DURATION_TYPE_TEMPORARY,
                EffectVisualEffect(VFX_IMP_HOLY_AID), oTarget, 3.0);
            FloatingTextStringOnCreature(
                "Trybunał uznał cię za niewinnego. Niechaj blask prawdy cię ochroni.",
                oTarget, FALSE);
            break;
    }
}

// ----------------------------------------------------------------
// Search popup (select defendant)
// ----------------------------------------------------------------

void TribShowSearchPopup(object oPC, json jResults)
{
    if(NuiFindWindow(oPC, TRIB_WIN_SEARCH) != 0)
        NuiDestroy(oPC, NuiFindWindow(oPC, TRIB_WIN_SEARCH));

    int   nCount = JsonGetLength(jResults);
    float fRowH  = GetNuiScaleDimension(oPC, 26.0);
    float fW     = GetNuiScaleDimension(oPC, 380.0);
    float fH     = GetNuiScaleDimension(oPC, 220.0);
    float fX = (IntToFloat(GetPlayerDeviceProperty(oPC, PLAYER_DEVICE_PROPERTY_GUI_WIDTH))  - fW) / 2.0;
    float fY = (IntToFloat(GetPlayerDeviceProperty(oPC, PLAYER_DEVICE_PROPERTY_GUI_HEIGHT)) - fH) / 2.0;

    json jNameLbl = NuiLabel(NuiBind(TRIB_BIND_SRCH_NAME),
                             JsonInt(NUI_HALIGN_LEFT), JsonInt(NUI_VALIGN_MIDDLE));
    json jCell = NuiGroup(NuiRow(JsonArrayInsert(JsonArray(), jNameLbl)),
                          TRUE, NUI_SCROLLBARS_NONE);
    jCell = NuiId(jCell, TRIB_BTN_SRCH_ROW);
    jCell = NuiEncouraged(jCell, NuiBind(TRIB_BIND_SRCH_ENC));

    json jTmpl = JsonArrayInsert(JsonArray(), NuiListTemplateCell(jCell, 0.0, TRUE));
    json jList = NuiList(jTmpl, NuiBind(TRIB_BIND_SRCH_COUNT), fRowH);
    jList = NuiHeight(jList, GetNuiScaleDimension(oPC, 160.0));

    json jWin = NuiWindow(NuiCol(JsonArrayInsert(JsonArray(), jList)),
        JsonString("Wybierz Oskarżonego"),
        NuiRect(fX, fY, fW, fH),
        JsonBool(FALSE), JsonBool(FALSE), JsonBool(TRUE),
        JsonBool(FALSE), JsonBool(TRUE));

    int nPopToken = NuiCreate(oPC, jWin, TRIB_WIN_SEARCH, TRIB_EV_SCRIPT);

    json jNames = JsonArray();
    json jEncs  = JsonArray();
    int i;
    for(i = 0; i < nCount; i++)
    {
        json jEntry = JsonArrayGet(jResults, i);
        jNames = JsonArrayInsert(jNames,
            JsonString(JsonGetString(JsonObjectGet(jEntry, "char_name"))));
        jEncs  = JsonArrayInsert(jEncs, JsonBool(FALSE));
    }
    NuiSetBind(oPC, nPopToken, TRIB_BIND_SRCH_NAME,  jNames);
    NuiSetBind(oPC, nPopToken, TRIB_BIND_SRCH_ENC,   jEncs);
    NuiSetBind(oPC, nPopToken, TRIB_BIND_SRCH_COUNT, JsonInt(nCount));
}
