// lib_lch.nss — NUI layout builders, window management, and game-action API

#include "lib_lch_def"

// ----------------------------------------------------------------
// Main window layout
// ----------------------------------------------------------------

json BuildLchMainLayout(object oPC)
{
    float fBtnH = GetNuiScaleDimension(oPC, 30.0);
    float fRowH = GetNuiScaleDimension(oPC, 26.0);
    float fLblW = GetNuiScaleDimension(oPC, 165.0);

    json jCol = JsonArray();

    // --- Dług ---
    json jDebtKey = NuiLabel(JsonString("Aktualny dług:"), JsonInt(NUI_HALIGN_LEFT), JsonInt(NUI_VALIGN_MIDDLE));
    jDebtKey = NuiWidth(jDebtKey, fLblW);
    jDebtKey = NuiHeight(jDebtKey, fRowH);
    json jDebtVal = NuiLabel(NuiBind(LCH_BIND_DEBT_LBL), JsonInt(NUI_HALIGN_LEFT), JsonInt(NUI_VALIGN_MIDDLE));
    jDebtVal = NuiHeight(jDebtVal, fRowH);
    json jDebtRow = JsonArray();
    jDebtRow = JsonArrayInsert(jDebtRow, jDebtKey);
    jDebtRow = JsonArrayInsert(jDebtRow, jDebtVal);
    jCol = JsonArrayInsert(jCol, NuiRow(jDebtRow));

    // --- Pożyczono łącznie ---
    json jPrincKey = NuiLabel(JsonString("Pożyczono łącznie:"), JsonInt(NUI_HALIGN_LEFT), JsonInt(NUI_VALIGN_MIDDLE));
    jPrincKey = NuiWidth(jPrincKey, fLblW);
    jPrincKey = NuiHeight(jPrincKey, fRowH);
    json jPrincVal = NuiLabel(NuiBind(LCH_BIND_PRINCIPAL_LBL), JsonInt(NUI_HALIGN_LEFT), JsonInt(NUI_VALIGN_MIDDLE));
    jPrincVal = NuiHeight(jPrincVal, fRowH);
    json jPrincRow = JsonArray();
    jPrincRow = JsonArrayInsert(jPrincRow, jPrincKey);
    jPrincRow = JsonArrayInsert(jPrincRow, jPrincVal);
    jCol = JsonArrayInsert(jCol, NuiRow(jPrincRow));

    // --- Spłacono łącznie ---
    json jRepKey = NuiLabel(JsonString("Spłacono łącznie:"), JsonInt(NUI_HALIGN_LEFT), JsonInt(NUI_VALIGN_MIDDLE));
    jRepKey = NuiWidth(jRepKey, fLblW);
    jRepKey = NuiHeight(jRepKey, fRowH);
    json jRepVal = NuiLabel(NuiBind(LCH_BIND_REPAID_LBL), JsonInt(NUI_HALIGN_LEFT), JsonInt(NUI_VALIGN_MIDDLE));
    jRepVal = NuiHeight(jRepVal, fRowH);
    json jRepRow = JsonArray();
    jRepRow = JsonArrayInsert(jRepRow, jRepKey);
    jRepRow = JsonArrayInsert(jRepRow, jRepVal);
    jCol = JsonArrayInsert(jCol, NuiRow(jRepRow));

    jCol = JsonArrayInsert(jCol, CreateEmptyRow(oPC, 10.0));

    // --- Oprocentowanie ---
    json jRateKey = NuiLabel(JsonString("Oprocentowanie:"), JsonInt(NUI_HALIGN_LEFT), JsonInt(NUI_VALIGN_MIDDLE));
    jRateKey = NuiWidth(jRateKey, fLblW);
    jRateKey = NuiHeight(jRateKey, fRowH);
    json jRateVal = NuiLabel(NuiBind(LCH_BIND_RATE_LBL), JsonInt(NUI_HALIGN_LEFT), JsonInt(NUI_VALIGN_MIDDLE));
    jRateVal = NuiHeight(jRateVal, fRowH);
    json jRateRow = JsonArray();
    jRateRow = JsonArrayInsert(jRateRow, jRateKey);
    jRateRow = JsonArrayInsert(jRateRow, jRateVal);
    jCol = JsonArrayInsert(jCol, NuiRow(jRateRow));

    // --- Następne naliczenie ---
    json jTickKey = NuiLabel(JsonString("Następne naliczenie:"), JsonInt(NUI_HALIGN_LEFT), JsonInt(NUI_VALIGN_MIDDLE));
    jTickKey = NuiWidth(jTickKey, fLblW);
    jTickKey = NuiHeight(jTickKey, fRowH);
    json jTickVal = NuiLabel(NuiBind(LCH_BIND_TICK_LBL), JsonInt(NUI_HALIGN_LEFT), JsonInt(NUI_VALIGN_MIDDLE));
    jTickVal = NuiHeight(jTickVal, fRowH);
    json jTickRow = JsonArray();
    jTickRow = JsonArrayInsert(jTickRow, jTickKey);
    jTickRow = JsonArrayInsert(jTickRow, jTickVal);
    jCol = JsonArrayInsert(jCol, NuiRow(jTickRow));

    jCol = JsonArrayInsert(jCol, CreateEmptyRow(oPC, 10.0));

    // --- Kara (colored) ---
    json jPenKey = NuiLabel(JsonString("Kara:"), JsonInt(NUI_HALIGN_LEFT), JsonInt(NUI_VALIGN_MIDDLE));
    jPenKey = NuiWidth(jPenKey, fLblW);
    jPenKey = NuiHeight(jPenKey, fRowH);
    json jPenVal = NuiLabel(NuiBind(LCH_BIND_PENALTY_LBL), JsonInt(NUI_HALIGN_LEFT), JsonInt(NUI_VALIGN_MIDDLE));
    jPenVal = NuiStyleForegroundColor(jPenVal, NuiBind(LCH_BIND_PENALTY_COL));
    jPenVal = NuiHeight(jPenVal, fRowH);
    json jPenRow = JsonArray();
    jPenRow = JsonArrayInsert(jPenRow, jPenKey);
    jPenRow = JsonArrayInsert(jPenRow, jPenVal);
    jCol = JsonArrayInsert(jCol, NuiRow(jPenRow));

    // --- Spacer pushes buttons to bottom ---
    jCol = JsonArrayInsert(jCol, NuiSpacer());

    // --- Flavor text ---
    json jFlavorLbl = NuiLabel(
        JsonString("„Złoto jest cierpliwe. Lichwiarz też — ale nie na zawsze.""),
        JsonInt(NUI_HALIGN_CENTER), JsonInt(NUI_VALIGN_MIDDLE));
    jFlavorLbl = NuiHeight(jFlavorLbl, GetNuiScaleDimension(oPC, 22.0));
    jFlavorLbl = NuiStyleForegroundColor(jFlavorLbl, NuiColor(160, 130, 80));
    jCol = JsonArrayInsert(jCol, jFlavorLbl);

    jCol = JsonArrayInsert(jCol, CreateEmptyRow(oPC, 8.0));

    // --- Buttons ---
    json jBorrowBtn = NuiButton(JsonString("Pożycz złoto"));
    jBorrowBtn = NuiId(jBorrowBtn, LCH_BTN_BORROW);
    jBorrowBtn = NuiEnabled(jBorrowBtn, NuiBind(LCH_BIND_BORROW_ENA));
    jBorrowBtn = NuiWidth(jBorrowBtn, GetNuiScaleDimension(oPC, 160.0));
    jBorrowBtn = NuiHeight(jBorrowBtn, fBtnH);

    json jRepayBtn = NuiButton(JsonString("Spłać dług"));
    jRepayBtn = NuiId(jRepayBtn, LCH_BTN_REPAY);
    jRepayBtn = NuiEnabled(jRepayBtn, NuiBind(LCH_BIND_REPAY_ENA));
    jRepayBtn = NuiWidth(jRepayBtn, GetNuiScaleDimension(oPC, 160.0));
    jRepayBtn = NuiHeight(jRepayBtn, fBtnH);

    json jBtnRow = JsonArray();
    jBtnRow = JsonArrayInsert(jBtnRow, jBorrowBtn);
    jBtnRow = JsonArrayInsert(jBtnRow, NuiSpacer());
    jBtnRow = JsonArrayInsert(jBtnRow, jRepayBtn);
    jCol = JsonArrayInsert(jCol, NuiRow(jBtnRow));

    // Side spacers for horizontal centering (following Mailbox pattern)
    float fContentW = GetNuiScaleDimension(oPC, 440.0);
    json jSide = NuiCol(JsonArrayInsert(JsonArray(), NuiSpacer()));
    json jMainRow = JsonArray();
    jMainRow = JsonArrayInsert(jMainRow, jSide);
    jMainRow = JsonArrayInsert(jMainRow, NuiWidth(NuiCol(jCol), fContentW));
    jMainRow = JsonArrayInsert(jMainRow, jSide);
    return NuiRow(jMainRow);
}

// ----------------------------------------------------------------
// Open / refresh main window
// ----------------------------------------------------------------

void LchOpenWindow(object oPC)
{
    LchCheckAndApplyPenalties(oPC);

    int nExisting = NuiFindWindow(oPC, LCH_WINDOW);
    if(nExisting != 0)
    {
        FeedLchMain(oPC, nExisting);
        return;
    }

    float fScreenW = IntToFloat(GetPlayerDeviceProperty(oPC, PLAYER_DEVICE_PROPERTY_GUI_WIDTH));
    float fScreenH = IntToFloat(GetPlayerDeviceProperty(oPC, PLAYER_DEVICE_PROPERTY_GUI_HEIGHT));
    float fWinW    = GetNuiScaleDimension(oPC, LCH_W);
    float fWinH    = GetNuiScaleDimension(oPC, LCH_H);
    float fCX      = (fScreenW - fWinW) / 2.0;
    float fCY      = (fScreenH - fWinH) / 2.0;

    json jWin = NuiWindow(
        BuildLchMainLayout(oPC),
        JsonString("LICHWIARZ — Dług i Fatum"),
        NuiBind(LCH_BIND_WIN_GEOM),
        JsonBool(FALSE),
        JsonBool(FALSE),
        JsonBool(FALSE),
        JsonBool(TRUE),
        JsonBool(FALSE));

    int nToken = NuiCreate(oPC, jWin, LCH_WINDOW, LCH_EV_SCRIPT);
    NuiSetBind(oPC, nToken, LCH_BIND_WIN_GEOM, NuiRect(fCX, fCY, fWinW, fWinH));
    FeedLchMain(oPC, nToken);
}

// ----------------------------------------------------------------
// Feed main window binds
// ----------------------------------------------------------------

void FeedLchMain(object oPC, int nToken)
{
    json jLoan = LchGetLoan(oPC);
    int  nNow  = LchNow();

    if(JsonGetType(jLoan) == JSON_TYPE_NULL)
    {
        NuiSetBind(oPC, nToken, LCH_BIND_DEBT_LBL,      JsonString("0 sz."));
        NuiSetBind(oPC, nToken, LCH_BIND_PRINCIPAL_LBL, JsonString("0 sz."));
        NuiSetBind(oPC, nToken, LCH_BIND_REPAID_LBL,    JsonString("0 sz."));
        NuiSetBind(oPC, nToken, LCH_BIND_RATE_LBL,      JsonString("5% / godz."));
        NuiSetBind(oPC, nToken, LCH_BIND_TICK_LBL,      JsonString("—"));
        NuiSetBind(oPC, nToken, LCH_BIND_PENALTY_LBL,   JsonString("Brak"));
        NuiSetBind(oPC, nToken, LCH_BIND_PENALTY_COL,   LchPenaltyColor(0));
        NuiSetBind(oPC, nToken, LCH_BIND_BORROW_ENA,    JsonBool(TRUE));
        NuiSetBind(oPC, nToken, LCH_BIND_REPAY_ENA,     JsonBool(FALSE));
        return;
    }

    int   nDebt      = JsonGetInt  (JsonObjectGet(jLoan, "current_debt"));
    int   nPrincipal = JsonGetInt  (JsonObjectGet(jLoan, "principal"));
    int   nRepaid    = JsonGetInt  (JsonObjectGet(jLoan, "total_repaid"));
    float fRate      = JsonGetFloat(JsonObjectGet(jLoan, "interest_rate"));
    int   nPenalty   = JsonGetInt  (JsonObjectGet(jLoan, "penalty_level"));
    int   nLastTick  = JsonGetInt  (JsonObjectGet(jLoan, "last_tick"));

    int nElapsed     = nNow - nLastTick;
    int nSecondsLeft = (nElapsed < LCH_TICK_SECONDS) ? (LCH_TICK_SECONDS - nElapsed) : 0;

    NuiSetBind(oPC, nToken, LCH_BIND_DEBT_LBL,      JsonString(IntToString(nDebt) + " sz."));
    NuiSetBind(oPC, nToken, LCH_BIND_PRINCIPAL_LBL, JsonString(IntToString(nPrincipal) + " sz."));
    NuiSetBind(oPC, nToken, LCH_BIND_REPAID_LBL,    JsonString(IntToString(nRepaid) + " sz."));
    NuiSetBind(oPC, nToken, LCH_BIND_RATE_LBL,      JsonString(IntToString(FloatToInt(fRate * 100.0)) + "% / godz."));
    NuiSetBind(oPC, nToken, LCH_BIND_TICK_LBL,      JsonString(nSecondsLeft > 0 ? "za " + LchFormatTime(nSecondsLeft) : "teraz"));
    NuiSetBind(oPC, nToken, LCH_BIND_PENALTY_LBL,   JsonString(LchPenaltyName(nPenalty)));
    NuiSetBind(oPC, nToken, LCH_BIND_PENALTY_COL,   LchPenaltyColor(nPenalty));
    NuiSetBind(oPC, nToken, LCH_BIND_BORROW_ENA,    JsonBool(nDebt < LCH_MAX_LOAN));
    NuiSetBind(oPC, nToken, LCH_BIND_REPAY_ENA,     JsonBool(nDebt > 0));
}

// ----------------------------------------------------------------
// Borrow popup
// ----------------------------------------------------------------

void LchCreateBorrowPopup(object oPC)
{
    if(NuiFindWindow(oPC, LCH_WIN_BORROW) != 0)
        NuiDestroy(oPC, NuiFindWindow(oPC, LCH_WIN_BORROW));

    float fBtnH = GetNuiScaleDimension(oPC, 30.0);
    float fRowH = GetNuiScaleDimension(oPC, 22.0);
    float fW    = GetNuiScaleDimension(oPC, LCH_POPUP_W);
    float fH    = GetNuiScaleDimension(oPC, LCH_POPUP_H);
    float fX    = (IntToFloat(GetPlayerDeviceProperty(oPC, PLAYER_DEVICE_PROPERTY_GUI_WIDTH))  - fW) / 2.0;
    float fY    = (IntToFloat(GetPlayerDeviceProperty(oPC, PLAYER_DEVICE_PROPERTY_GUI_HEIGHT)) - fH) / 2.0;

    json jRangeLbl = NuiLabel(
        JsonString("Kwota (min. " + IntToString(LCH_MIN_LOAN) + " — max. " + IntToString(LCH_MAX_LOAN) + " sz.):"),
        JsonInt(NUI_HALIGN_LEFT), JsonInt(NUI_VALIGN_MIDDLE));
    jRangeLbl = NuiHeight(jRangeLbl, fRowH);

    json jAmtField = NuiTextEdit(JsonString(""), NuiBind(LCH_BIND_BORROW_AMT), 6, FALSE);
    jAmtField = NuiHeight(jAmtField, fBtnH);

    json jRateLbl = NuiLabel(
        JsonString("Oprocentowanie: 5% / godz. Dług rośnie z każdą godziną braku spłaty."),
        JsonInt(NUI_HALIGN_LEFT), JsonInt(NUI_VALIGN_MIDDLE));
    jRateLbl = NuiHeight(jRateLbl, GetNuiScaleDimension(oPC, 40.0));
    jRateLbl = NuiStyleForegroundColor(jRateLbl, NuiColor(200, 160, 60));

    json jFlavorLbl = NuiLabel(
        JsonString("„Złoto mam — pytań nie zadaję.\nSpłacisz, bo wszyscy spłacają… w końcu.""),
        JsonInt(NUI_HALIGN_LEFT), JsonInt(NUI_VALIGN_MIDDLE));
    jFlavorLbl = NuiHeight(jFlavorLbl, GetNuiScaleDimension(oPC, 44.0));
    jFlavorLbl = NuiStyleForegroundColor(jFlavorLbl, NuiColor(160, 130, 80));

    json jConfirmBtn = NuiButton(JsonString("Bierz złoto"));
    jConfirmBtn = NuiId(jConfirmBtn, LCH_BTN_BORROW_OK);
    jConfirmBtn = NuiEnabled(jConfirmBtn, NuiBind(LCH_BIND_CONFIRM_ENA));
    jConfirmBtn = NuiWidth(jConfirmBtn, GetNuiScaleDimension(oPC, 150.0));
    jConfirmBtn = NuiHeight(jConfirmBtn, fBtnH);

    json jCancelBtn = NuiButton(JsonString("Anuluj"));
    jCancelBtn = NuiId(jCancelBtn, LCH_BTN_BORROW_X);
    jCancelBtn = NuiWidth(jCancelBtn, GetNuiScaleDimension(oPC, 100.0));
    jCancelBtn = NuiHeight(jCancelBtn, fBtnH);

    json jBtnRow = JsonArray();
    jBtnRow = JsonArrayInsert(jBtnRow, jConfirmBtn);
    jBtnRow = JsonArrayInsert(jBtnRow, NuiSpacer());
    jBtnRow = JsonArrayInsert(jBtnRow, jCancelBtn);

    json jCol = JsonArray();
    jCol = JsonArrayInsert(jCol, jRangeLbl);
    jCol = JsonArrayInsert(jCol, CreateEmptyRow(oPC, 4.0));
    jCol = JsonArrayInsert(jCol, jAmtField);
    jCol = JsonArrayInsert(jCol, CreateEmptyRow(oPC, 6.0));
    jCol = JsonArrayInsert(jCol, jRateLbl);
    jCol = JsonArrayInsert(jCol, CreateEmptyRow(oPC, 4.0));
    jCol = JsonArrayInsert(jCol, jFlavorLbl);
    jCol = JsonArrayInsert(jCol, NuiSpacer());
    jCol = JsonArrayInsert(jCol, NuiRow(jBtnRow));

    json jWin = NuiWindow(NuiCol(jCol),
        JsonString("Pożyczka u Lichwiarza"),
        NuiRect(fX, fY, fW, fH),
        JsonBool(FALSE), JsonBool(FALSE), JsonBool(TRUE),
        JsonBool(FALSE), JsonBool(TRUE));

    int nToken = NuiCreate(oPC, jWin, LCH_WIN_BORROW, LCH_EV_SCRIPT);
    NuiSetBind(oPC, nToken, LCH_BIND_BORROW_AMT,  JsonString(""));
    NuiSetBind(oPC, nToken, LCH_BIND_CONFIRM_ENA, JsonBool(FALSE));
    NuiSetBindWatch(oPC, nToken, LCH_BIND_BORROW_AMT, TRUE);
}

// ----------------------------------------------------------------
// Repay popup
// ----------------------------------------------------------------

void LchCreateRepayPopup(object oPC)
{
    if(NuiFindWindow(oPC, LCH_WIN_REPAY) != 0)
        NuiDestroy(oPC, NuiFindWindow(oPC, LCH_WIN_REPAY));

    json jLoan = LchGetLoan(oPC);
    if(JsonGetType(jLoan) == JSON_TYPE_NULL) return;

    int nDebt = JsonGetInt(JsonObjectGet(jLoan, "current_debt"));
    int nGold = GetGold(oPC);

    float fBtnH = GetNuiScaleDimension(oPC, 30.0);
    float fRowH = GetNuiScaleDimension(oPC, 22.0);
    float fW    = GetNuiScaleDimension(oPC, LCH_POPUP_W);
    float fH    = GetNuiScaleDimension(oPC, LCH_POPUP_H);
    float fX    = (IntToFloat(GetPlayerDeviceProperty(oPC, PLAYER_DEVICE_PROPERTY_GUI_WIDTH))  - fW) / 2.0;
    float fY    = (IntToFloat(GetPlayerDeviceProperty(oPC, PLAYER_DEVICE_PROPERTY_GUI_HEIGHT)) - fH) / 2.0;

    json jDebtLbl = NuiLabel(NuiBind(LCH_BIND_REPAY_DEBT), JsonInt(NUI_HALIGN_LEFT), JsonInt(NUI_VALIGN_MIDDLE));
    jDebtLbl = NuiHeight(jDebtLbl, fRowH);

    json jGoldLbl = NuiLabel(NuiBind(LCH_BIND_REPAY_GOLD), JsonInt(NUI_HALIGN_LEFT), JsonInt(NUI_VALIGN_MIDDLE));
    jGoldLbl = NuiHeight(jGoldLbl, fRowH);

    json jPromptLbl = NuiLabel(JsonString("Kwota spłaty:"), JsonInt(NUI_HALIGN_LEFT), JsonInt(NUI_VALIGN_MIDDLE));
    jPromptLbl = NuiHeight(jPromptLbl, fRowH);

    json jAmtField = NuiTextEdit(JsonString(""), NuiBind(LCH_BIND_REPAY_AMT), 8, FALSE);
    jAmtField = NuiHeight(jAmtField, fBtnH);

    json jDoBtn = NuiButton(JsonString("Spłać podaną kwotę"));
    jDoBtn = NuiId(jDoBtn, LCH_BTN_REPAY_DO);
    jDoBtn = NuiEnabled(jDoBtn, NuiBind(LCH_BIND_DO_REPAY_ENA));
    jDoBtn = NuiHeight(jDoBtn, fBtnH);

    json jFullBtn = NuiButton(NuiBind(LCH_BIND_FULL_LBL));
    jFullBtn = NuiId(jFullBtn, LCH_BTN_REPAY_FULL);
    jFullBtn = NuiEnabled(jFullBtn, NuiBind(LCH_BIND_FULL_ENA));
    jFullBtn = NuiHeight(jFullBtn, fBtnH);

    json jCancelBtn = NuiButton(JsonString("Anuluj"));
    jCancelBtn = NuiId(jCancelBtn, LCH_BTN_REPAY_X);
    jCancelBtn = NuiWidth(jCancelBtn, GetNuiScaleDimension(oPC, 100.0));
    jCancelBtn = NuiHeight(jCancelBtn, fBtnH);

    json jBotRow = JsonArray();
    jBotRow = JsonArrayInsert(jBotRow, NuiSpacer());
    jBotRow = JsonArrayInsert(jBotRow, jCancelBtn);

    json jCol = JsonArray();
    jCol = JsonArrayInsert(jCol, jDebtLbl);
    jCol = JsonArrayInsert(jCol, jGoldLbl);
    jCol = JsonArrayInsert(jCol, CreateEmptyRow(oPC, 8.0));
    jCol = JsonArrayInsert(jCol, jPromptLbl);
    jCol = JsonArrayInsert(jCol, jAmtField);
    jCol = JsonArrayInsert(jCol, CreateEmptyRow(oPC, 6.0));
    jCol = JsonArrayInsert(jCol, jDoBtn);
    jCol = JsonArrayInsert(jCol, CreateEmptyRow(oPC, 4.0));
    jCol = JsonArrayInsert(jCol, jFullBtn);
    jCol = JsonArrayInsert(jCol, NuiSpacer());
    jCol = JsonArrayInsert(jCol, NuiRow(jBotRow));

    json jWin = NuiWindow(NuiCol(jCol),
        JsonString("Spłata długu"),
        NuiRect(fX, fY, fW, fH),
        JsonBool(FALSE), JsonBool(FALSE), JsonBool(TRUE),
        JsonBool(FALSE), JsonBool(TRUE));

    int nToken = NuiCreate(oPC, jWin, LCH_WIN_REPAY, LCH_EV_SCRIPT);
    NuiSetBind(oPC, nToken, LCH_BIND_REPAY_DEBT,   JsonString("Aktualny dług: " + IntToString(nDebt) + " sz."));
    NuiSetBind(oPC, nToken, LCH_BIND_REPAY_GOLD,   JsonString("Twoje złoto: "   + IntToString(nGold) + " sz."));
    NuiSetBind(oPC, nToken, LCH_BIND_REPAY_AMT,    JsonString(""));
    NuiSetBind(oPC, nToken, LCH_BIND_DO_REPAY_ENA, JsonBool(FALSE));
    NuiSetBind(oPC, nToken, LCH_BIND_FULL_LBL,     JsonString("Spłać całość (" + IntToString(nDebt) + " sz.)"));
    NuiSetBind(oPC, nToken, LCH_BIND_FULL_ENA,     JsonBool(nGold >= nDebt && nDebt > 0));
    NuiSetBindWatch(oPC, nToken, LCH_BIND_REPAY_AMT, TRUE);
}

// ----------------------------------------------------------------
// Game actions: borrow and repay
// ----------------------------------------------------------------

void LchHandleBorrow(object oPC)
{
    int nToken = NuiFindWindow(oPC, LCH_WIN_BORROW);
    if(nToken == 0) return;

    string sAmt = JsonGetString(NuiGetBind(oPC, nToken, LCH_BIND_BORROW_AMT));
    int    nAmt = StringToInt(sAmt);

    if(nAmt < LCH_MIN_LOAN || nAmt > LCH_MAX_LOAN)
    {
        SendMessageToPC(oPC, "[Lichwiarz] Kwota musi wynosić od " +
            IntToString(LCH_MIN_LOAN) + " do " + IntToString(LCH_MAX_LOAN) + " sz.");
        return;
    }

    json jLoan       = LchGetLoan(oPC);
    int  nCurrentDebt = (JsonGetType(jLoan) != JSON_TYPE_NULL)
                        ? JsonGetInt(JsonObjectGet(jLoan, "current_debt")) : 0;

    if(nCurrentDebt + nAmt > LCH_MAX_LOAN)
    {
        SendMessageToPC(oPC, "[Lichwiarz] Łączny dług przekroczyłby limit " + IntToString(LCH_MAX_LOAN) + " sz.");
        return;
    }

    LchBorrow(oPC, nAmt);
    GiveGoldToCreature(oPC, nAmt);
    NuiDestroy(oPC, nToken);

    int nMain = NuiFindWindow(oPC, LCH_WINDOW);
    if(nMain != 0) FeedLchMain(oPC, nMain);

    SendMessageToPC(oPC, "[Lichwiarz] Otrzymałeś " + IntToString(nAmt) + " sz. Pamiętaj — dług rośnie każdą godziną.");
    FloatingTextStringOnCreature("Pożyczka: " + IntToString(nAmt) + " sz.", oPC, FALSE);
}

void LchHandleRepay(object oPC, int bFull)
{
    int nToken = NuiFindWindow(oPC, LCH_WIN_REPAY);
    if(nToken == 0) return;

    json jLoan = LchGetLoan(oPC);
    if(JsonGetType(jLoan) == JSON_TYPE_NULL)
    {
        NuiDestroy(oPC, nToken);
        return;
    }

    int nDebt = JsonGetInt(JsonObjectGet(jLoan, "current_debt"));
    int nGold = GetGold(oPC);
    int nAmt;

    if(bFull)
    {
        nAmt = nDebt;
    }
    else
    {
        string sAmt = JsonGetString(NuiGetBind(oPC, nToken, LCH_BIND_REPAY_AMT));
        nAmt = StringToInt(sAmt);
    }

    if(nAmt <= 0)
    {
        SendMessageToPC(oPC, "[Lichwiarz] Podaj kwotę większą od zera.");
        return;
    }
    if(nAmt > nGold)
    {
        SendMessageToPC(oPC, "[Lichwiarz] Nie masz tyle złota.");
        return;
    }
    if(nAmt > nDebt) nAmt = nDebt;

    TakeGoldFromCreature(nAmt, oPC, TRUE);
    int nRemaining = LchRepay(oPC, nAmt);
    NuiDestroy(oPC, nToken);

    if(nRemaining == 0)
    {
        LchOnDebtCleared(oPC);
    }
    else
    {
        LchCheckAndApplyPenalties(oPC);
        SendMessageToPC(oPC, "[Lichwiarz] Spłaciłeś " + IntToString(nAmt) +
            " sz. Pozostały dług: " + IntToString(nRemaining) + " sz.");
    }

    int nMain = NuiFindWindow(oPC, LCH_WINDOW);
    if(nMain != 0) FeedLchMain(oPC, nMain);
}
