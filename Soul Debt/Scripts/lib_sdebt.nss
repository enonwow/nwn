#include "lib_sdebt_def"

void SDebtOpenWindow(object oPC);
void SDebtFeedAll(object oPC, int nToken);
void SDebtFeedCredView(object oPC, int nToken);
void SDebtFeedDebtView(object oPC, int nToken);
void SDebtFeedDetail(object oPC, int nToken, int nId);
void SDebtShowProposePopup(object oPC);
void SDebtShowNotifyPopup(object oPC, int nDebtId, int bInvoke);
void SDebtApplyInvokePressure(object oPC);
void SDebtApplyRenounceCurse(object oPC);
void SDebtCheckOnLogin(object oPC);

// ----------------------------------------------------------------
// Helpers
// ----------------------------------------------------------------

string SDebtStatusLabel(string sStatus)
{
    if(sStatus == "pending") return "Oczekuje";
    if(sStatus == "active")  return "Aktywny";
    if(sStatus == "invoked") return "Wywołany!";
    return sStatus;
}

// ----------------------------------------------------------------
// NUI – creditor tab
// ----------------------------------------------------------------

json SDebtBuildCredView(object oPC)
{
    float fBtnH    = GetNuiScaleDimension(oPC, 28.0);
    float fRowH    = GetNuiScaleDimension(oPC, 26.0);
    float fListH   = GetNuiScaleDimension(oPC, 195.0);
    float fDetailH = GetNuiScaleDimension(oPC, 85.0);
    float fNameW   = GetNuiScaleDimension(oPC, 150.0);
    float fStatusW = GetNuiScaleDimension(oPC, 85.0);
    float fDateW   = GetNuiScaleDimension(oPC, 55.0);

    // List columns: name | status | date | description
    json jNameLbl   = NuiLabel(NuiBind(SDEBT_BIND_C_DEBTOR), JsonInt(NUI_HALIGN_LEFT),   JsonInt(NUI_VALIGN_MIDDLE));
    jNameLbl = NuiWidth(jNameLbl, fNameW);

    json jStatusLbl = NuiLabel(NuiBind(SDEBT_BIND_C_STATUS), JsonInt(NUI_HALIGN_CENTER), JsonInt(NUI_VALIGN_MIDDLE));
    jStatusLbl = NuiWidth(jStatusLbl, fStatusW);

    json jDateLbl   = NuiLabel(NuiBind(SDEBT_BIND_C_DATE),   JsonInt(NUI_HALIGN_CENTER), JsonInt(NUI_VALIGN_MIDDLE));
    jDateLbl = NuiWidth(jDateLbl, fDateW);

    json jDescLbl   = NuiLabel(NuiBind(SDEBT_BIND_C_DESC),   JsonInt(NUI_HALIGN_LEFT),   JsonInt(NUI_VALIGN_MIDDLE));

    json jCellRow = JsonArray();
    jCellRow = JsonArrayInsert(jCellRow, jNameLbl);
    jCellRow = JsonArrayInsert(jCellRow, jStatusLbl);
    jCellRow = JsonArrayInsert(jCellRow, jDateLbl);
    jCellRow = JsonArrayInsert(jCellRow, jDescLbl);

    json jCell = NuiGroup(NuiRow(jCellRow), TRUE, NUI_SCROLLBARS_NONE);
    jCell = NuiId(jCell, SDEBT_BTN_ROW_CRED);
    jCell = NuiEncouraged(jCell, NuiBind(SDEBT_BIND_C_ENC));

    json jTmpl = JsonArrayInsert(JsonArray(), NuiListTemplateCell(jCell, 0.0, TRUE));
    json jList = NuiList(jTmpl, NuiBind("sdebt_cred_cnt"), fRowH);
    jList = NuiHeight(jList, fListH);

    // Detail panel
    json jDetail = NuiGroup(NuiText(NuiBind(SDEBT_BIND_DETAIL), FALSE), TRUE, NUI_SCROLLBARS_NONE);
    jDetail = NuiHeight(jDetail, fDetailH);

    // Action row
    json jInvokeBtn = NuiButton(JsonString("Wywołaj dług"));
    jInvokeBtn = NuiId(jInvokeBtn, SDEBT_BTN_INVOKE);
    jInvokeBtn = NuiEnabled(jInvokeBtn, NuiBind(SDEBT_BIND_INVOKE_ENA));
    jInvokeBtn = NuiWidth(jInvokeBtn, GetNuiScaleDimension(oPC, 130.0));
    jInvokeBtn = NuiHeight(jInvokeBtn, fBtnH);
    jInvokeBtn = NuiTooltip(jInvokeBtn, JsonString("Zmuś dłużnika do stawienia się — straci HP co kilka minut."));

    json jForgiveBtn = NuiButton(JsonString("Odpuść dług"));
    jForgiveBtn = NuiId(jForgiveBtn, SDEBT_BTN_FORGIVE);
    jForgiveBtn = NuiEnabled(jForgiveBtn, NuiBind(SDEBT_BIND_FORGIVE_ENA));
    jForgiveBtn = NuiWidth(jForgiveBtn, GetNuiScaleDimension(oPC, 130.0));
    jForgiveBtn = NuiHeight(jForgiveBtn, fBtnH);
    jForgiveBtn = NuiTooltip(jForgiveBtn, JsonString("Zrzekasz się roszczenia bez konsekwencji dla dłużnika."));

    json jPropBtn = NuiButton(JsonString("Nowe roszczenie"));
    jPropBtn = NuiId(jPropBtn, SDEBT_BTN_PROPOSE);
    jPropBtn = NuiWidth(jPropBtn, GetNuiScaleDimension(oPC, 150.0));
    jPropBtn = NuiHeight(jPropBtn, fBtnH);
    jPropBtn = NuiTooltip(jPropBtn, JsonString("Prześlij propozycję długu innemu graczowi online."));

    json jBotRow = JsonArray();
    jBotRow = JsonArrayInsert(jBotRow, jInvokeBtn);
    jBotRow = JsonArrayInsert(jBotRow, NuiSpacer());
    jBotRow = JsonArrayInsert(jBotRow, jForgiveBtn);
    jBotRow = JsonArrayInsert(jBotRow, NuiSpacer());
    jBotRow = JsonArrayInsert(jBotRow, jPropBtn);

    json jCol = JsonArray();
    jCol = JsonArrayInsert(jCol, jList);
    jCol = JsonArrayInsert(jCol, jDetail);
    jCol = JsonArrayInsert(jCol, NuiRow(jBotRow));
    return NuiCol(jCol);
}

// ----------------------------------------------------------------
// NUI – debtor tab
// ----------------------------------------------------------------

json SDebtBuildDebtView(object oPC)
{
    float fBtnH    = GetNuiScaleDimension(oPC, 28.0);
    float fRowH    = GetNuiScaleDimension(oPC, 26.0);
    float fListH   = GetNuiScaleDimension(oPC, 195.0);
    float fDetailH = GetNuiScaleDimension(oPC, 85.0);
    float fNameW   = GetNuiScaleDimension(oPC, 150.0);
    float fStatusW = GetNuiScaleDimension(oPC, 85.0);
    float fDateW   = GetNuiScaleDimension(oPC, 55.0);

    json jNameLbl   = NuiLabel(NuiBind(SDEBT_BIND_D_CRED),   JsonInt(NUI_HALIGN_LEFT),   JsonInt(NUI_VALIGN_MIDDLE));
    jNameLbl = NuiWidth(jNameLbl, fNameW);

    json jStatusLbl = NuiLabel(NuiBind(SDEBT_BIND_D_STATUS), JsonInt(NUI_HALIGN_CENTER), JsonInt(NUI_VALIGN_MIDDLE));
    jStatusLbl = NuiWidth(jStatusLbl, fStatusW);

    json jDateLbl   = NuiLabel(NuiBind(SDEBT_BIND_D_DATE),   JsonInt(NUI_HALIGN_CENTER), JsonInt(NUI_VALIGN_MIDDLE));
    jDateLbl = NuiWidth(jDateLbl, fDateW);

    json jDescLbl   = NuiLabel(NuiBind(SDEBT_BIND_D_DESC),   JsonInt(NUI_HALIGN_LEFT),   JsonInt(NUI_VALIGN_MIDDLE));

    json jCellRow = JsonArray();
    jCellRow = JsonArrayInsert(jCellRow, jNameLbl);
    jCellRow = JsonArrayInsert(jCellRow, jStatusLbl);
    jCellRow = JsonArrayInsert(jCellRow, jDateLbl);
    jCellRow = JsonArrayInsert(jCellRow, jDescLbl);

    json jCell = NuiGroup(NuiRow(jCellRow), TRUE, NUI_SCROLLBARS_NONE);
    jCell = NuiId(jCell, SDEBT_BTN_ROW_DEBT);
    jCell = NuiEncouraged(jCell, NuiBind(SDEBT_BIND_D_ENC));

    json jTmpl = JsonArrayInsert(JsonArray(), NuiListTemplateCell(jCell, 0.0, TRUE));
    json jList = NuiList(jTmpl, NuiBind("sdebt_debt_cnt"), fRowH);
    jList = NuiHeight(jList, fListH);

    json jDetail = NuiGroup(NuiText(NuiBind(SDEBT_BIND_DETAIL), FALSE), TRUE, NUI_SCROLLBARS_NONE);
    jDetail = NuiHeight(jDetail, fDetailH);

    // Action buttons
    json jAcceptBtn = NuiButton(JsonString("Przyjmij dług"));
    jAcceptBtn = NuiId(jAcceptBtn, SDEBT_BTN_ACCEPT);
    jAcceptBtn = NuiEnabled(jAcceptBtn, NuiBind(SDEBT_BIND_ACCEPT_ENA));
    jAcceptBtn = NuiWidth(jAcceptBtn, GetNuiScaleDimension(oPC, 130.0));
    jAcceptBtn = NuiHeight(jAcceptBtn, fBtnH);
    jAcceptBtn = NuiTooltip(jAcceptBtn, JsonString("Uznajesz dług — wierzyciel może go wywołać."));

    string sRepayLbl = "Spłać (" + IntToString(SDEBT_REPAY_GOLD) + " sz.)";
    json jRepayBtn = NuiButton(JsonString(sRepayLbl));
    jRepayBtn = NuiId(jRepayBtn, SDEBT_BTN_REPAY);
    jRepayBtn = NuiEnabled(jRepayBtn, NuiBind(SDEBT_BIND_REPAY_ENA));
    jRepayBtn = NuiWidth(jRepayBtn, GetNuiScaleDimension(oPC, 150.0));
    jRepayBtn = NuiHeight(jRepayBtn, fBtnH);
    jRepayBtn = NuiTooltip(jRepayBtn, JsonString("Spłacasz dług złotem. Dług zostaje zamknięty."));

    json jRenounceBtn = NuiButton(JsonString("Odrzuć dług"));
    jRenounceBtn = NuiId(jRenounceBtn, SDEBT_BTN_RENOUNCE);
    jRenounceBtn = NuiEnabled(jRenounceBtn, NuiBind(SDEBT_BIND_RENOUNCE_ENA));
    jRenounceBtn = NuiWidth(jRenounceBtn, GetNuiScaleDimension(oPC, 130.0));
    jRenounceBtn = NuiHeight(jRenounceBtn, fBtnH);
    jRenounceBtn = NuiTooltip(jRenounceBtn, JsonString("Wyrzekasz się długu. Tracisz HP i ściągasz przekleństwo."));

    json jBotRow = JsonArray();
    jBotRow = JsonArrayInsert(jBotRow, jAcceptBtn);
    jBotRow = JsonArrayInsert(jBotRow, NuiSpacer());
    jBotRow = JsonArrayInsert(jBotRow, jRepayBtn);
    jBotRow = JsonArrayInsert(jBotRow, NuiSpacer());
    jBotRow = JsonArrayInsert(jBotRow, jRenounceBtn);

    json jCol = JsonArray();
    jCol = JsonArrayInsert(jCol, jList);
    jCol = JsonArrayInsert(jCol, jDetail);
    jCol = JsonArrayInsert(jCol, NuiRow(jBotRow));
    return NuiCol(jCol);
}

// ----------------------------------------------------------------
// Window create / tab switch
// ----------------------------------------------------------------

void SDebtSwitchTab(object oPC, int nToken, int nTab)
{
    SetLocalInt(oPC, SDEBT_LVAR_TAB,    nTab);
    SetLocalInt(oPC, SDEBT_LVAR_SEL_ID, 0);
    NuiSetGroupLayout(oPC, nToken, SDEBT_GRP_SWAP,
        nTab == 0 ? SDebtBuildCredView(oPC) : SDebtBuildDebtView(oPC));
    SDebtFeedAll(oPC, nToken);
}

void SDebtOpenWindow(object oPC)
{
    int nToken = NuiFindWindow(oPC, SDEBT_WINDOW);
    if(nToken != 0)
    {
        SDebtSwitchTab(oPC, nToken, GetLocalInt(oPC, SDEBT_LVAR_TAB));
        return;
    }

    int   nGuiW = GetPlayerDeviceProperty(oPC, PLAYER_DEVICE_PROPERTY_GUI_WIDTH);
    int   nGuiH = GetPlayerDeviceProperty(oPC, PLAYER_DEVICE_PROPERTY_GUI_HEIGHT);
    float fCX   = (IntToFloat(nGuiW) - GetNuiScaleDimension(oPC, SDEBT_W)) / 2.0;
    float fCY   = (IntToFloat(nGuiH) - GetNuiScaleDimension(oPC, SDEBT_H)) / 2.0;
    json  jGeom = NuiRect(fCX, fCY, GetNuiScaleDimension(oPC, SDEBT_W), GetNuiScaleDimension(oPC, SDEBT_H));

    float fBtnH = GetNuiScaleDimension(oPC, 28.0);

    json jTabCred = NuiButton(JsonString("Należności"));
    jTabCred = NuiId(jTabCred, SDEBT_BTN_TAB_CRED);
    jTabCred = NuiWidth(jTabCred, GetNuiScaleDimension(oPC, 120.0));
    jTabCred = NuiHeight(jTabCred, fBtnH);
    jTabCred = NuiTooltip(jTabCred, JsonString("Dusze, które ci są winne."));

    json jTabDebt = NuiButton(JsonString("Moje długi"));
    jTabDebt = NuiId(jTabDebt, SDEBT_BTN_TAB_DEBT);
    jTabDebt = NuiWidth(jTabDebt, GetNuiScaleDimension(oPC, 120.0));
    jTabDebt = NuiHeight(jTabDebt, fBtnH);
    jTabDebt = NuiTooltip(jTabDebt, JsonString("Długi, które ty jesteś winien."));

    json jHeaderLbl = NuiLabel(NuiBind(SDEBT_BIND_HEADER), JsonInt(NUI_HALIGN_LEFT), JsonInt(NUI_VALIGN_MIDDLE));

    json jCloseBtn = NuiButton(JsonString("X"));
    jCloseBtn = NuiId(jCloseBtn, SDEBT_BTN_CLOSE);
    jCloseBtn = NuiWidth(jCloseBtn, GetNuiScaleDimension(oPC, 30.0));
    jCloseBtn = NuiHeight(jCloseBtn, fBtnH);

    json jTabRow = JsonArray();
    jTabRow = JsonArrayInsert(jTabRow, jTabCred);
    jTabRow = JsonArrayInsert(jTabRow, jTabDebt);
    jTabRow = JsonArrayInsert(jTabRow, NuiSpacer());
    jTabRow = JsonArrayInsert(jTabRow, jHeaderLbl);
    jTabRow = JsonArrayInsert(jTabRow, jCloseBtn);

    json jSwapGrp = NuiGroup(SDebtBuildCredView(oPC), FALSE, NUI_SCROLLBARS_NONE);
    jSwapGrp = NuiId(jSwapGrp, SDEBT_GRP_SWAP);

    json jRootChildren = JsonArray();
    jRootChildren = JsonArrayInsert(jRootChildren, NuiRow(jTabRow));
    jRootChildren = JsonArrayInsert(jRootChildren, jSwapGrp);

    json jWin = NuiWindow(
        NuiCol(jRootChildren),
        JsonString("Księga Dusz"),
        NuiBind(SDEBT_WIN_GEOM),
        JsonBool(FALSE),
        JsonBool(FALSE),
        JsonBool(FALSE),
        JsonBool(TRUE),
        JsonBool(FALSE));

    nToken = NuiCreate(oPC, jWin, SDEBT_WINDOW, SDEBT_EV_SCRIPT);
    NuiSetBind(oPC, nToken, SDEBT_WIN_GEOM, jGeom);

    SetLocalInt(oPC, SDEBT_LVAR_TAB,    0);
    SetLocalInt(oPC, SDEBT_LVAR_SEL_ID, 0);
    SDebtFeedAll(oPC, nToken);
}

// ----------------------------------------------------------------
// Feed
// ----------------------------------------------------------------

void SDebtFeedAll(object oPC, int nToken)
{
    json jCredRows = SDebtGetAsCreditor(GetObjectUUID(oPC));
    json jDebtRows = SDebtGetAsDebtor(GetObjectUUID(oPC));

    string sHeader = "Należności: " + IntToString(JsonGetLength(jCredRows))
                   + "   |   Długi: " + IntToString(JsonGetLength(jDebtRows));
    NuiSetBind(oPC, nToken, SDEBT_BIND_HEADER, JsonString(sHeader));

    if(GetLocalInt(oPC, SDEBT_LVAR_TAB) == 0)
        SDebtFeedCredView(oPC, nToken);
    else
        SDebtFeedDebtView(oPC, nToken);
}

void SDebtFeedCredView(object oPC, int nToken)
{
    json jRows  = SDebtGetAsCreditor(GetObjectUUID(oPC));
    int  nCount = JsonGetLength(jRows);
    int  nSelId = GetLocalInt(oPC, SDEBT_LVAR_SEL_ID);

    json jDebtors  = JsonArray();
    json jStatuses = JsonArray();
    json jDates    = JsonArray();
    json jDescs    = JsonArray();
    json jEncs     = JsonArray();

    int i;
    for(i = 0; i < nCount; i++)
    {
        json   jRow    = JsonArrayGet(jRows, i);
        int    nId     = JsonGetInt   (JsonObjectGet(jRow, "id"));
        string sName   = JsonGetString(JsonObjectGet(jRow, "debtor_name"));
        string sStatus = JsonGetString(JsonObjectGet(jRow, "status"));
        int    nDate   = JsonGetInt   (JsonObjectGet(jRow, "sealed_at"));
        string sDesc   = JsonGetString(JsonObjectGet(jRow, "description"));

        jDebtors  = JsonArrayInsert(jDebtors,  JsonString(sName));
        jStatuses = JsonArrayInsert(jStatuses, JsonString(SDebtStatusLabel(sStatus)));
        jDates    = JsonArrayInsert(jDates,    JsonString(SDebtFormatDate(nDate)));
        jDescs    = JsonArrayInsert(jDescs,    JsonString(sDesc != "" ? sDesc : "—"));
        jEncs     = JsonArrayInsert(jEncs,     JsonBool(nSelId > 0 && nId == nSelId));
    }

    NuiSetBind(oPC, nToken, SDEBT_BIND_C_DEBTOR, jDebtors);
    NuiSetBind(oPC, nToken, SDEBT_BIND_C_STATUS, jStatuses);
    NuiSetBind(oPC, nToken, SDEBT_BIND_C_DATE,   jDates);
    NuiSetBind(oPC, nToken, SDEBT_BIND_C_DESC,   jDescs);
    NuiSetBind(oPC, nToken, SDEBT_BIND_C_ENC,    jEncs);
    NuiSetBind(oPC, nToken, "sdebt_cred_cnt",    JsonInt(nCount));

    int bSel = (nSelId > 0);
    NuiSetBind(oPC, nToken, SDEBT_BIND_FORGIVE_ENA, JsonBool(bSel));

    if(bSel)
    {
        json jSel = SDebtGetById(nSelId);
        string sSt = JsonGetType(jSel) != JSON_TYPE_NULL ? JsonGetString(JsonObjectGet(jSel, "status")) : "";
        NuiSetBind(oPC, nToken, SDEBT_BIND_INVOKE_ENA, JsonBool(sSt == "active"));
        SDebtFeedDetail(oPC, nToken, nSelId);
    }
    else
    {
        NuiSetBind(oPC, nToken, SDEBT_BIND_INVOKE_ENA, JsonBool(FALSE));
        NuiSetBind(oPC, nToken, SDEBT_BIND_DETAIL,
            JsonString("Wybierz pozycję z listy, aby zobaczyć szczegóły."));
    }
}

void SDebtFeedDebtView(object oPC, int nToken)
{
    json jRows  = SDebtGetAsDebtor(GetObjectUUID(oPC));
    int  nCount = JsonGetLength(jRows);
    int  nSelId = GetLocalInt(oPC, SDEBT_LVAR_SEL_ID);

    json jCreds    = JsonArray();
    json jStatuses = JsonArray();
    json jDates    = JsonArray();
    json jDescs    = JsonArray();
    json jEncs     = JsonArray();

    int i;
    for(i = 0; i < nCount; i++)
    {
        json   jRow    = JsonArrayGet(jRows, i);
        int    nId     = JsonGetInt   (JsonObjectGet(jRow, "id"));
        string sName   = JsonGetString(JsonObjectGet(jRow, "creditor_name"));
        string sStatus = JsonGetString(JsonObjectGet(jRow, "status"));
        int    nDate   = JsonGetInt   (JsonObjectGet(jRow, "sealed_at"));
        string sDesc   = JsonGetString(JsonObjectGet(jRow, "description"));

        jCreds    = JsonArrayInsert(jCreds,    JsonString(sName));
        jStatuses = JsonArrayInsert(jStatuses, JsonString(SDebtStatusLabel(sStatus)));
        jDates    = JsonArrayInsert(jDates,    JsonString(SDebtFormatDate(nDate)));
        jDescs    = JsonArrayInsert(jDescs,    JsonString(sDesc != "" ? sDesc : "—"));
        jEncs     = JsonArrayInsert(jEncs,     JsonBool(nSelId > 0 && nId == nSelId));
    }

    NuiSetBind(oPC, nToken, SDEBT_BIND_D_CRED,   jCreds);
    NuiSetBind(oPC, nToken, SDEBT_BIND_D_STATUS, jStatuses);
    NuiSetBind(oPC, nToken, SDEBT_BIND_D_DATE,   jDates);
    NuiSetBind(oPC, nToken, SDEBT_BIND_D_DESC,   jDescs);
    NuiSetBind(oPC, nToken, SDEBT_BIND_D_ENC,    jEncs);
    NuiSetBind(oPC, nToken, "sdebt_debt_cnt",    JsonInt(nCount));

    if(nSelId > 0)
    {
        json   jSel = SDebtGetById(nSelId);
        string sSt  = JsonGetType(jSel) != JSON_TYPE_NULL
                        ? JsonGetString(JsonObjectGet(jSel, "status")) : "";

        NuiSetBind(oPC, nToken, SDEBT_BIND_ACCEPT_ENA,   JsonBool(sSt == "pending"));
        NuiSetBind(oPC, nToken, SDEBT_BIND_REPAY_ENA,    JsonBool(sSt == "active" || sSt == "invoked"));
        NuiSetBind(oPC, nToken, SDEBT_BIND_RENOUNCE_ENA, JsonBool(sSt == "pending" || sSt == "active" || sSt == "invoked"));
        SDebtFeedDetail(oPC, nToken, nSelId);
    }
    else
    {
        NuiSetBind(oPC, nToken, SDEBT_BIND_ACCEPT_ENA,   JsonBool(FALSE));
        NuiSetBind(oPC, nToken, SDEBT_BIND_REPAY_ENA,    JsonBool(FALSE));
        NuiSetBind(oPC, nToken, SDEBT_BIND_RENOUNCE_ENA, JsonBool(FALSE));
        NuiSetBind(oPC, nToken, SDEBT_BIND_DETAIL,
            JsonString("Wybierz pozycję z listy, aby zobaczyć szczegóły."));
    }
}

void SDebtFeedDetail(object oPC, int nToken, int nId)
{
    json jRow = SDebtGetById(nId);
    if(JsonGetType(jRow) == JSON_TYPE_NULL) return;

    string sCred    = JsonGetString(JsonObjectGet(jRow, "creditor_name"));
    string sDebt    = JsonGetString(JsonObjectGet(jRow, "debtor_name"));
    string sStatus  = JsonGetString(JsonObjectGet(jRow, "status"));
    string sDesc    = JsonGetString(JsonObjectGet(jRow, "description"));
    int    nSealed  = JsonGetInt   (JsonObjectGet(jRow, "sealed_at"));
    int    nInvoked = JsonGetInt   (JsonObjectGet(jRow, "invoked_at"));

    string sTxt = "Wierzyciel: " + sCred + "   Dłużnik: " + sDebt + "\n"
                + "Stan: " + SDebtStatusLabel(sStatus) + "   Data: " + SDebtFormatDate(nSealed) + "\n"
                + "Opis: " + (sDesc != "" ? sDesc : "—");
    if(sStatus == "invoked" && nInvoked > 0)
        sTxt += "\nWywołano: " + SDebtFormatDate(nInvoked);

    NuiSetBind(oPC, nToken, SDEBT_BIND_DETAIL, JsonString(sTxt));
}

// ----------------------------------------------------------------
// Propose debt popup
// ----------------------------------------------------------------

void SDebtShowProposePopup(object oPC)
{
    if(NuiFindWindow(oPC, SDEBT_WIN_PROPOSE) != 0)
        NuiDestroy(oPC, NuiFindWindow(oPC, SDEBT_WIN_PROPOSE));

    json jOnline = SDebtGetOnlinePlayers(oPC);
    int  nCount  = JsonGetLength(jOnline);
    if(nCount == 0)
    {
        SendMessageToPC(oPC, "[Dług Duszy] Brak innych graczy online.");
        return;
    }
    SetLocalJson(oPC, SDEBT_LVAR_PROP_LIST, jOnline);

    float fRowH  = GetNuiScaleDimension(oPC, 26.0);
    float fBtnH  = GetNuiScaleDimension(oPC, 28.0);
    float fW     = GetNuiScaleDimension(oPC, 440.0);
    float fH     = GetNuiScaleDimension(oPC, 310.0);
    float fListH = GetNuiScaleDimension(oPC, 155.0);
    float fX     = (IntToFloat(GetPlayerDeviceProperty(oPC, PLAYER_DEVICE_PROPERTY_GUI_WIDTH))  - fW) / 2.0;
    float fY     = (IntToFloat(GetPlayerDeviceProperty(oPC, PLAYER_DEVICE_PROPERTY_GUI_HEIGHT)) - fH) / 2.0;

    json jNameLbl = NuiLabel(NuiBind(SDEBT_BIND_PROP_NAMES), JsonInt(NUI_HALIGN_LEFT), JsonInt(NUI_VALIGN_MIDDLE));
    json jCell = NuiGroup(NuiRow(JsonArrayInsert(JsonArray(), jNameLbl)), TRUE, NUI_SCROLLBARS_NONE);
    jCell = NuiId(jCell, SDEBT_BTN_PROP_ROW);
    jCell = NuiEncouraged(jCell, NuiBind(SDEBT_BIND_PROP_ENC));

    json jTmpl = JsonArrayInsert(JsonArray(), NuiListTemplateCell(jCell, 0.0, TRUE));
    json jList = NuiList(jTmpl, NuiBind("sdebt_prop_cnt"), fRowH);
    jList = NuiHeight(jList, fListH);

    json jDescEdit = NuiTextEdit(JsonString("Powód (opcjonalnie)..."), NuiBind(SDEBT_BIND_PROP_DESC), 120, FALSE);
    jDescEdit = NuiHeight(jDescEdit, fBtnH);

    json jConfirm = NuiButton(JsonString("Prześlij roszczenie"));
    jConfirm = NuiId(jConfirm, SDEBT_BTN_PROP_CONFIRM);
    jConfirm = NuiWidth(jConfirm, GetNuiScaleDimension(oPC, 160.0));
    jConfirm = NuiHeight(jConfirm, fBtnH);

    json jCancel = NuiButton(JsonString("Anuluj"));
    jCancel = NuiId(jCancel, SDEBT_BTN_PROP_CANCEL);
    jCancel = NuiWidth(jCancel, GetNuiScaleDimension(oPC, 80.0));
    jCancel = NuiHeight(jCancel, fBtnH);

    json jBtnRow = JsonArray();
    jBtnRow = JsonArrayInsert(jBtnRow, jConfirm);
    jBtnRow = JsonArrayInsert(jBtnRow, NuiSpacer());
    jBtnRow = JsonArrayInsert(jBtnRow, jCancel);

    json jCol = JsonArray();
    jCol = JsonArrayInsert(jCol, jList);
    jCol = JsonArrayInsert(jCol, CreateEmptyRow(oPC, 4.0));
    jCol = JsonArrayInsert(jCol, jDescEdit);
    jCol = JsonArrayInsert(jCol, CreateEmptyRow(oPC, 4.0));
    jCol = JsonArrayInsert(jCol, NuiRow(jBtnRow));

    json jWin = NuiWindow(NuiCol(jCol),
        JsonString("Wyznacz dłużnika"),
        NuiRect(fX, fY, fW, fH),
        JsonBool(FALSE), JsonBool(FALSE), JsonBool(TRUE),
        JsonBool(FALSE), JsonBool(TRUE));

    int nPopToken = NuiCreate(oPC, jWin, SDEBT_WIN_PROPOSE, SDEBT_EV_SCRIPT);

    json jNames = JsonArray();
    json jEncs  = JsonArray();
    int i;
    for(i = 0; i < nCount; i++)
    {
        json jEntry = JsonArrayGet(jOnline, i);
        jNames = JsonArrayInsert(jNames, JsonString(JsonGetString(JsonObjectGet(jEntry, "name"))));
        jEncs  = JsonArrayInsert(jEncs,  JsonBool(FALSE));
    }
    NuiSetBind(oPC, nPopToken, SDEBT_BIND_PROP_NAMES, jNames);
    NuiSetBind(oPC, nPopToken, SDEBT_BIND_PROP_ENC,   jEncs);
    NuiSetBind(oPC, nPopToken, "sdebt_prop_cnt",      JsonInt(nCount));
    NuiSetBind(oPC, nPopToken, SDEBT_BIND_PROP_DESC,  JsonString(""));

    DeleteLocalString(oPC, SDEBT_LVAR_PROP_UUID);
    DeleteLocalString(oPC, SDEBT_LVAR_PROP_NAME);
}

// ----------------------------------------------------------------
// Notification popup for debtor (proposal or invocation)
// ----------------------------------------------------------------

void SDebtShowNotifyPopup(object oPC, int nDebtId, int bInvoke)
{
    if(NuiFindWindow(oPC, SDEBT_WIN_NOTIFY) != 0)
        NuiDestroy(oPC, NuiFindWindow(oPC, SDEBT_WIN_NOTIFY));

    SetLocalInt(oPC, SDEBT_LVAR_NOTIF_ID, nDebtId);

    json jRow = SDebtGetById(nDebtId);
    if(JsonGetType(jRow) == JSON_TYPE_NULL) return;

    string sCredName = JsonGetString(JsonObjectGet(jRow, "creditor_name"));
    string sDesc     = JsonGetString(JsonObjectGet(jRow, "description"));

    float fW    = GetNuiScaleDimension(oPC, 440.0);
    float fH    = GetNuiScaleDimension(oPC, 210.0);
    float fBtnH = GetNuiScaleDimension(oPC, 28.0);
    float fX    = (IntToFloat(GetPlayerDeviceProperty(oPC, PLAYER_DEVICE_PROPERTY_GUI_WIDTH))  - fW) / 2.0;
    float fY    = (IntToFloat(GetPlayerDeviceProperty(oPC, PLAYER_DEVICE_PROPERTY_GUI_HEIGHT)) - fH) / 2.0;

    string sTitle;
    string sMsgText;
    if(bInvoke)
    {
        sTitle   = "Dług Duszy — Wezwanie";
        sMsgText = sCredName + " wzywa cię, byś spłacił dług duszy.\n"
                 + "Tracisz " + IntToString(SDEBT_INVOKE_DMG) + " HP co 5 minut, dopóki dług nie zostanie spłacony.\n"
                 + "Otwórz Księgę Dusz, by uregulować zobowiązanie.";
    }
    else
    {
        sTitle   = "Propozycja długu duszy";
        sMsgText = sCredName + " twierdzi, że ocali ci życie i żąda uznania długu.\n"
                 + "Powód: " + (sDesc != "" ? sDesc : "—") + "\n"
                 + "Czy przyjmujesz ciężar tego długu?";
    }

    json jMsg = NuiLabel(JsonString(sMsgText), JsonInt(NUI_HALIGN_CENTER), JsonInt(NUI_VALIGN_MIDDLE));

    json jCol = JsonArray();
    jCol = JsonArrayInsert(jCol, jMsg);
    jCol = JsonArrayInsert(jCol, CreateEmptyRow(oPC, 8.0));

    if(!bInvoke)
    {
        json jAcceptBtn = NuiButton(JsonString("Przyjmij dług"));
        jAcceptBtn = NuiId(jAcceptBtn, SDEBT_BTN_NOTIF_ACC);
        jAcceptBtn = NuiWidth(jAcceptBtn, GetNuiScaleDimension(oPC, 130.0));
        jAcceptBtn = NuiHeight(jAcceptBtn, fBtnH);

        json jRejectBtn = NuiButton(JsonString("Odrzuć"));
        jRejectBtn = NuiId(jRejectBtn, SDEBT_BTN_NOTIF_REJ);
        jRejectBtn = NuiWidth(jRejectBtn, GetNuiScaleDimension(oPC, 100.0));
        jRejectBtn = NuiHeight(jRejectBtn, fBtnH);

        json jBtnRow = JsonArray();
        jBtnRow = JsonArrayInsert(jBtnRow, NuiSpacer());
        jBtnRow = JsonArrayInsert(jBtnRow, jAcceptBtn);
        jBtnRow = JsonArrayInsert(jBtnRow, NuiSpacer());
        jBtnRow = JsonArrayInsert(jBtnRow, jRejectBtn);
        jBtnRow = JsonArrayInsert(jBtnRow, NuiSpacer());
        jCol = JsonArrayInsert(jCol, NuiRow(jBtnRow));
    }
    else
    {
        json jOkBtn = NuiButton(JsonString("Zrozumiałem"));
        jOkBtn = NuiId(jOkBtn, SDEBT_BTN_NOTIF_OK);
        jOkBtn = NuiWidth(jOkBtn, GetNuiScaleDimension(oPC, 120.0));
        jOkBtn = NuiHeight(jOkBtn, fBtnH);

        json jRow2 = JsonArray();
        jRow2 = JsonArrayInsert(jRow2, NuiSpacer());
        jRow2 = JsonArrayInsert(jRow2, jOkBtn);
        jRow2 = JsonArrayInsert(jRow2, NuiSpacer());
        jCol = JsonArrayInsert(jCol, NuiRow(jRow2));
    }

    json jWin = NuiWindow(NuiCol(jCol),
        JsonString(sTitle),
        NuiRect(fX, fY, fW, fH),
        JsonBool(FALSE), JsonBool(FALSE), JsonBool(TRUE),
        JsonBool(FALSE), JsonBool(TRUE));
    NuiCreate(oPC, jWin, SDEBT_WIN_NOTIFY, SDEBT_EV_SCRIPT);
}

// ----------------------------------------------------------------
// Gameplay effects
// ----------------------------------------------------------------

void SDebtApplyInvokePressure(object oPC)
{
    if(!GetIsObjectValid(oPC) || !GetIsPC(oPC)) return;

    int nInvoked = SDebtGetInvokedCount(GetObjectUUID(oPC));
    if(nInvoked <= 0) return;

    int nDmg = SDEBT_INVOKE_DMG * nInvoked;
    if(GetCurrentHitPoints(oPC) > 1)
    {
        effect eHurt = EffectDamage(nDmg, DAMAGE_TYPE_MAGICAL, DAMAGE_POWER_NORMAL);
        ApplyEffectToObject(DURATION_TYPE_INSTANT, eHurt, oPC);
        FloatingTextStringOnCreature(
            "Dług duszy pali jak rozżarzone żelazo... (" + IntToString(nDmg) + " obrażeń magicznych)",
            oPC, FALSE);
    }
    DelayCommand(SDEBT_INVOKE_TICK, SDebtApplyInvokePressure(oPC));
}

void SDebtApplyRenounceCurse(object oPC)
{
    effect eCurse = EffectSavingThrowDecrease(SAVING_THROW_ALL, 2);
    effect eVfx   = EffectVisualEffect(VFX_DUR_CESSATE_NEGATIVE);
    effect eLink  = EffectLinkEffects(eCurse, eVfx);
    eLink = ExtraordinaryEffect(eLink);
    ApplyEffectToObject(DURATION_TYPE_TEMPORARY, eLink, oPC, IntToFloat(SDEBT_CURSE_DURATION));
    ApplyEffectToObject(DURATION_TYPE_INSTANT,
        EffectDamage(SDEBT_RENOUNCE_DMG, DAMAGE_TYPE_MAGICAL, DAMAGE_POWER_NORMAL), oPC);
    FloatingTextStringOnCreature(
        "Mrok zapada się na twoją duszę. Przekleństwo ciąży na twoich kościach przez 24 godziny.",
        oPC, FALSE);
    SendMessageToPC(oPC, "[Dług Duszy] Wyrzekłeś się długu. Przekleństwo ściągnięte na twoje kości.");
}

void SDebtCheckOnLogin(object oPC)
{
    int nInvoked = SDebtGetInvokedCount(GetObjectUUID(oPC));
    if(nInvoked > 0)
    {
        string sMsg = "[Dług Duszy] Masz wywołany dług! HP będzie tracone co 5 minut — otwórz Księgę Dusz.";
        SendMessageToPC(oPC, sMsg);
        FloatingTextStringOnCreature(sMsg, oPC, FALSE);
        DelayCommand(5.0, SDebtApplyInvokePressure(oPC));
    }

    json jPending = SDebtGetPendingForDebtor(GetObjectUUID(oPC));
    int nPend = JsonGetLength(jPending);
    if(nPend > 0)
    {
        SendMessageToPC(oPC, "[Dług Duszy] Masz " + IntToString(nPend)
            + " oczekującą propozycję długu. Otwórz Księgę Dusz.");
    }
}
