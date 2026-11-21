// lib_dice.nss — UI construction, feed functions, and roll logic for Kości Losu

#include "lib_dice_def"

// Forward declarations for mutual use
void DiceFeedRecord(object oPC, int nToken);
void DiceRevealResults(object oPC, int nToken, int nBet, json jPlayerDice, json jDealerDice);

// ---------------------------------------------------------------
// Layout helpers
// ---------------------------------------------------------------

// Builds one die widget: bordered group containing a single colored label.
// sValBind — scalar string bind for the displayed value ("1".."6" or "?" or "-")
// sColBind — scalar NuiColor bind shared across all dice in a row
json DiceBuildDie(object oPC, string sValBind, string sColBind)
{
    float fSz = GetNuiScaleDimension(oPC, 56.0);

    json jLbl = NuiLabel(NuiBind(sValBind), JsonInt(NUI_HALIGN_CENTER), JsonInt(NUI_VALIGN_MIDDLE));
    jLbl = NuiStyleForegroundColor(jLbl, NuiBind(sColBind));

    json jGrp = NuiGroup(NuiRow(JsonArrayInsert(JsonArray(), jLbl)), TRUE, NUI_SCROLLBARS_NONE);
    jGrp = NuiWidth(jGrp, fSz);
    jGrp = NuiHeight(jGrp, fSz);
    return jGrp;
}

// Builds the row of 5 dice for one side.
// sD1..sD5 — value bind names; sColBind — shared color bind.
json DiceBuildDiceRow(object oPC,
    string sD1, string sD2, string sD3, string sD4, string sD5,
    string sColBind)
{
    float fSpc = GetNuiScaleDimension(oPC, 6.0);

    json jRow = JsonArray();
    jRow = JsonArrayInsert(jRow, NuiSpacer());

    jRow = JsonArrayInsert(jRow, DiceBuildDie(oPC, sD1, sColBind));
    jRow = JsonArrayInsert(jRow, NuiHeight(NuiSpacer(), fSpc));
    jRow = JsonArrayInsert(jRow, DiceBuildDie(oPC, sD2, sColBind));
    jRow = JsonArrayInsert(jRow, NuiHeight(NuiSpacer(), fSpc));
    jRow = JsonArrayInsert(jRow, DiceBuildDie(oPC, sD3, sColBind));
    jRow = JsonArrayInsert(jRow, NuiHeight(NuiSpacer(), fSpc));
    jRow = JsonArrayInsert(jRow, DiceBuildDie(oPC, sD4, sColBind));
    jRow = JsonArrayInsert(jRow, NuiHeight(NuiSpacer(), fSpc));
    jRow = JsonArrayInsert(jRow, DiceBuildDie(oPC, sD5, sColBind));

    jRow = JsonArrayInsert(jRow, NuiSpacer());
    return NuiRow(jRow);
}

// ---------------------------------------------------------------
// Main window layout
// ---------------------------------------------------------------

json DiceBuildMainLayout(object oPC)
{
    float fBtnH = GetNuiScaleDimension(oPC, 32.0);
    float fLblH = GetNuiScaleDimension(oPC, 26.0);

    // --- Info bar: gold + jackpot ---
    json jGoldLbl = NuiLabel(NuiBind(DICE_BIND_GOLD_LBL), JsonInt(NUI_HALIGN_LEFT), JsonInt(NUI_VALIGN_MIDDLE));
    jGoldLbl = NuiHeight(jGoldLbl, fLblH);

    json jJackpotLbl = NuiLabel(NuiBind(DICE_BIND_JACKPOT), JsonInt(NUI_HALIGN_RIGHT), JsonInt(NUI_VALIGN_MIDDLE));
    jJackpotLbl = NuiHeight(jJackpotLbl, fLblH);

    json jInfoRow = JsonArray();
    jInfoRow = JsonArrayInsert(jInfoRow, jGoldLbl);
    jInfoRow = JsonArrayInsert(jInfoRow, NuiSpacer());
    jInfoRow = JsonArrayInsert(jInfoRow, jJackpotLbl);

    // --- Player dice section ---
    json jPLeftLbl = NuiLabel(JsonString("TWOJE KOŚCI:"),
                              JsonInt(NUI_HALIGN_LEFT), JsonInt(NUI_VALIGN_MIDDLE));
    jPLeftLbl = NuiHeight(jPLeftLbl, fLblH);

    json jPHandLbl = NuiLabel(NuiBind(DICE_BIND_P_HAND),
                              JsonInt(NUI_HALIGN_RIGHT), JsonInt(NUI_VALIGN_MIDDLE));
    jPHandLbl = NuiHeight(jPHandLbl, fLblH);
    jPHandLbl = NuiStyleForegroundColor(jPHandLbl, NuiColor(230, 200, 60));

    json jPHdrRow = JsonArray();
    jPHdrRow = JsonArrayInsert(jPHdrRow, jPLeftLbl);
    jPHdrRow = JsonArrayInsert(jPHdrRow, NuiSpacer());
    jPHdrRow = JsonArrayInsert(jPHdrRow, jPHandLbl);

    json jPDiceRow = DiceBuildDiceRow(oPC,
        DICE_BIND_P_D1, DICE_BIND_P_D2, DICE_BIND_P_D3,
        DICE_BIND_P_D4, DICE_BIND_P_D5, DICE_BIND_P_COL);

    // --- Dealer dice section ---
    json jDLeftLbl = NuiLabel(JsonString("KOŚCI KARCZMIARZA:"),
                              JsonInt(NUI_HALIGN_LEFT), JsonInt(NUI_VALIGN_MIDDLE));
    jDLeftLbl = NuiHeight(jDLeftLbl, fLblH);

    json jDHandLbl = NuiLabel(NuiBind(DICE_BIND_D_HAND),
                              JsonInt(NUI_HALIGN_RIGHT), JsonInt(NUI_VALIGN_MIDDLE));
    jDHandLbl = NuiHeight(jDHandLbl, fLblH);
    jDHandLbl = NuiStyleForegroundColor(jDHandLbl, NuiColor(200, 80, 80));

    json jDHdrRow = JsonArray();
    jDHdrRow = JsonArrayInsert(jDHdrRow, jDLeftLbl);
    jDHdrRow = JsonArrayInsert(jDHdrRow, NuiSpacer());
    jDHdrRow = JsonArrayInsert(jDHdrRow, jDHandLbl);

    json jDDiceRow = DiceBuildDiceRow(oPC,
        DICE_BIND_D_D1, DICE_BIND_D_D2, DICE_BIND_D_D3,
        DICE_BIND_D_D4, DICE_BIND_D_D5, DICE_BIND_D_COL);

    // --- Result flavor text ---
    json jResultLbl = NuiLabel(NuiBind(DICE_BIND_RESULT),
                               JsonInt(NUI_HALIGN_CENTER), JsonInt(NUI_VALIGN_MIDDLE));
    jResultLbl = NuiHeight(jResultLbl, GetNuiScaleDimension(oPC, 50.0));
    jResultLbl = NuiStyleForegroundColor(jResultLbl, NuiColor(255, 220, 120));

    // --- Bet + roll ---
    json jBetLbl = NuiLabel(JsonString("Stawka (gp):"),
                            JsonInt(NUI_HALIGN_LEFT), JsonInt(NUI_VALIGN_MIDDLE));
    jBetLbl = NuiWidth(jBetLbl, GetNuiScaleDimension(oPC, 110.0));
    jBetLbl = NuiHeight(jBetLbl, fBtnH);

    json jBetEdit = NuiTextEdit(JsonString("100"), NuiBind(DICE_BIND_BET_TXT), 6, FALSE);
    jBetEdit = NuiWidth(jBetEdit, GetNuiScaleDimension(oPC, 90.0));
    jBetEdit = NuiHeight(jBetEdit, fBtnH);

    json jRollBtn = NuiButton(JsonString("RZUĆ KOŚCI"));
    jRollBtn = NuiId(jRollBtn, DICE_BTN_ROLL);
    jRollBtn = NuiEnabled(jRollBtn, NuiBind(DICE_BIND_ROLL_ENA));
    jRollBtn = NuiWidth(jRollBtn, GetNuiScaleDimension(oPC, 140.0));
    jRollBtn = NuiHeight(jRollBtn, fBtnH);

    json jBetRow = JsonArray();
    jBetRow = JsonArrayInsert(jBetRow, jBetLbl);
    jBetRow = JsonArrayInsert(jBetRow, jBetEdit);
    jBetRow = JsonArrayInsert(jBetRow, NuiSpacer());
    jBetRow = JsonArrayInsert(jBetRow, jRollBtn);

    // --- Personal record ---
    json jRecLbl = NuiLabel(NuiBind(DICE_BIND_REC_LBL),
                            JsonInt(NUI_HALIGN_LEFT), JsonInt(NUI_VALIGN_MIDDLE));
    jRecLbl = NuiHeight(jRecLbl, fLblH);
    jRecLbl = NuiStyleForegroundColor(jRecLbl, NuiColor(150, 150, 150));

    // --- Leaderboard button ---
    json jLbBtn = NuiButton(JsonString("Najlepsi gracze"));
    jLbBtn = NuiId(jLbBtn, DICE_BTN_LB);
    jLbBtn = NuiWidth(jLbBtn, GetNuiScaleDimension(oPC, 170.0));
    jLbBtn = NuiHeight(jLbBtn, fBtnH);

    json jBotRow = JsonArray();
    jBotRow = JsonArrayInsert(jBotRow, NuiSpacer());
    jBotRow = JsonArrayInsert(jBotRow, jLbBtn);

    // --- Assemble column ---
    json jCol = JsonArray();
    jCol = JsonArrayInsert(jCol, NuiRow(jInfoRow));
    jCol = JsonArrayInsert(jCol, CreateEmptyRow(oPC, 6.0));
    jCol = JsonArrayInsert(jCol, NuiRow(jPHdrRow));
    jCol = JsonArrayInsert(jCol, jPDiceRow);
    jCol = JsonArrayInsert(jCol, CreateEmptyRow(oPC, 6.0));
    jCol = JsonArrayInsert(jCol, NuiRow(jDHdrRow));
    jCol = JsonArrayInsert(jCol, jDDiceRow);
    jCol = JsonArrayInsert(jCol, CreateEmptyRow(oPC, 4.0));
    jCol = JsonArrayInsert(jCol, jResultLbl);
    jCol = JsonArrayInsert(jCol, CreateEmptyRow(oPC, 4.0));
    jCol = JsonArrayInsert(jCol, NuiRow(jBetRow));
    jCol = JsonArrayInsert(jCol, CreateEmptyRow(oPC, 6.0));
    jCol = JsonArrayInsert(jCol, jRecLbl);
    jCol = JsonArrayInsert(jCol, NuiRow(jBotRow));

    float fContentW = GetNuiScaleDimension(oPC, 480.0);
    json jSide      = NuiCol(JsonArrayInsert(JsonArray(), NuiSpacer()));
    json jMainRow   = JsonArray();
    jMainRow = JsonArrayInsert(jMainRow, jSide);
    jMainRow = JsonArrayInsert(jMainRow, NuiWidth(NuiCol(jCol), fContentW));
    jMainRow = JsonArrayInsert(jMainRow, jSide);
    return NuiRow(jMainRow);
}

// ---------------------------------------------------------------
// Feed helpers
// ---------------------------------------------------------------

// Sets all 10 dice binds to a placeholder string and resets color to neutral.
void DiceFeedBlankDice(object oPC, int nToken, string sPlaceholder)
{
    json cNorm = NuiColor(220, 220, 220);
    NuiSetBind(oPC, nToken, DICE_BIND_P_D1, JsonString(sPlaceholder));
    NuiSetBind(oPC, nToken, DICE_BIND_P_D2, JsonString(sPlaceholder));
    NuiSetBind(oPC, nToken, DICE_BIND_P_D3, JsonString(sPlaceholder));
    NuiSetBind(oPC, nToken, DICE_BIND_P_D4, JsonString(sPlaceholder));
    NuiSetBind(oPC, nToken, DICE_BIND_P_D5, JsonString(sPlaceholder));
    NuiSetBind(oPC, nToken, DICE_BIND_D_D1, JsonString(sPlaceholder));
    NuiSetBind(oPC, nToken, DICE_BIND_D_D2, JsonString(sPlaceholder));
    NuiSetBind(oPC, nToken, DICE_BIND_D_D3, JsonString(sPlaceholder));
    NuiSetBind(oPC, nToken, DICE_BIND_D_D4, JsonString(sPlaceholder));
    NuiSetBind(oPC, nToken, DICE_BIND_D_D5, JsonString(sPlaceholder));
    NuiSetBind(oPC, nToken, DICE_BIND_P_COL, cNorm);
    NuiSetBind(oPC, nToken, DICE_BIND_D_COL, cNorm);
}

void DiceFeedInitialState(object oPC, int nToken)
{
    DiceFeedBlankDice(oPC, nToken, "-");
    NuiSetBind(oPC, nToken, DICE_BIND_P_HAND, JsonString(""));
    NuiSetBind(oPC, nToken, DICE_BIND_D_HAND, JsonString(""));
    NuiSetBind(oPC, nToken, DICE_BIND_RESULT, JsonString("Wrzuć stawkę i rzuć kości..."));
    NuiSetBind(oPC, nToken, DICE_BIND_GOLD_LBL,
        JsonString("Złoto: " + IntToString(GetGold(oPC)) + " gp"));
    NuiSetBind(oPC, nToken, DICE_BIND_BET_TXT,  JsonString("100"));
    NuiSetBind(oPC, nToken, DICE_BIND_ROLL_ENA, JsonBool(TRUE));
    NuiSetBind(oPC, nToken, DICE_BIND_JACKPOT,
        JsonString("Pula jackpotu: " + IntToString(DiceGetJackpot()) + " gp"));
    DiceFeedRecord(oPC, nToken);
}

void DiceFeedRecord(object oPC, int nToken)
{
    DiceRegisterPlayer(oPC);
    json jRec = DiceGetRecord(oPC);
    if(JsonGetType(jRec) == JSON_TYPE_NULL)
    {
        NuiSetBind(oPC, nToken, DICE_BIND_REC_LBL, JsonString("Brak rekordów."));
        return;
    }

    int nW  = JsonGetInt(JsonObjectGet(jRec, "wins"));
    int nL  = JsonGetInt(JsonObjectGet(jRec, "losses"));
    int nGW = JsonGetInt(JsonObjectGet(jRec, "gold_won"));
    int nGL = JsonGetInt(JsonObjectGet(jRec, "gold_lost"));
    int nBH = JsonGetInt(JsonObjectGet(jRec, "best_hand"));
    int nSB = JsonGetInt(JsonObjectGet(jRec, "streak_best"));
    int nNet = nGW - nGL;

    string sNet = (nNet >= 0 ? "+" : "") + IntToString(nNet);
    string sRec = "Bilans: " + IntToString(nW) + "W/" + IntToString(nL) + "P"
                + "  Złoto: " + sNet + " gp"
                + "  Najlepszy układ: " + DiceHandName(nBH)
                + "  Seria: " + IntToString(nSB) + "W";
    NuiSetBind(oPC, nToken, DICE_BIND_REC_LBL, JsonString(sRec));
}

// ---------------------------------------------------------------
// Leaderboard popup
// ---------------------------------------------------------------

void DiceOpenLeaderboard(object oPC)
{
    if(NuiFindWindow(oPC, DICE_WIN_LB) != 0)
    {
        NuiDestroy(oPC, NuiFindWindow(oPC, DICE_WIN_LB));
        return;
    }

    float fW    = GetNuiScaleDimension(oPC, 500.0);
    float fH    = GetNuiScaleDimension(oPC, 380.0);
    float fRowH = GetNuiScaleDimension(oPC, 26.0);
    float fX    = (IntToFloat(GetPlayerDeviceProperty(oPC, PLAYER_DEVICE_PROPERTY_GUI_WIDTH))  - fW) / 2.0;
    float fY    = (IntToFloat(GetPlayerDeviceProperty(oPC, PLAYER_DEVICE_PROPERTY_GUI_HEIGHT)) - fH) / 2.0;

    float fNameW = GetNuiScaleDimension(oPC, 180.0);
    float fWLW   = GetNuiScaleDimension(oPC, 90.0);

    json jNameLbl = NuiLabel(NuiBind(DICE_BIND_LB_NAME), JsonInt(NUI_HALIGN_LEFT),   JsonInt(NUI_VALIGN_MIDDLE));
    json jWLLbl   = NuiLabel(NuiBind(DICE_BIND_LB_WL),   JsonInt(NUI_HALIGN_CENTER), JsonInt(NUI_VALIGN_MIDDLE));
    jWLLbl = NuiWidth(jWLLbl, fWLW);
    json jGoldLbl = NuiLabel(NuiBind(DICE_BIND_LB_GOLD), JsonInt(NUI_HALIGN_RIGHT),  JsonInt(NUI_VALIGN_MIDDLE));
    jGoldLbl = NuiWidth(jGoldLbl, GetNuiScaleDimension(oPC, 120.0));

    json jCellRow = JsonArray();
    jCellRow = JsonArrayInsert(jCellRow, NuiWidth(NuiCol(JsonArrayInsert(JsonArray(), jNameLbl)), fNameW));
    jCellRow = JsonArrayInsert(jCellRow, jWLLbl);
    jCellRow = JsonArrayInsert(jCellRow, NuiSpacer());
    jCellRow = JsonArrayInsert(jCellRow, jGoldLbl);

    json jCell = NuiGroup(NuiRow(jCellRow), FALSE, NUI_SCROLLBARS_NONE);
    jCell = NuiEncouraged(jCell, NuiBind(DICE_BIND_LB_ENC));

    json jTmpl   = JsonArrayInsert(JsonArray(), NuiListTemplateCell(jCell, 0.0, TRUE));
    json jList   = NuiList(jTmpl, NuiBind("dice_lb_count"), fRowH);
    jList = NuiHeight(jList, GetNuiScaleDimension(oPC, 300.0));

    json jWin = NuiWindow(NuiCol(JsonArrayInsert(JsonArray(), jList)),
        JsonString("Najlepsi gracze — Kości Losu"),
        NuiRect(fX, fY, fW, fH),
        JsonBool(FALSE), JsonBool(FALSE), JsonBool(TRUE),
        JsonBool(FALSE), JsonBool(TRUE));

    int nLbToken = NuiCreate(oPC, jWin, DICE_WIN_LB, DICE_EV_SCRIPT);

    json jRows = DiceGetLeaderboard(DICE_LB_ROWS);
    int nCount = JsonGetLength(jRows);
    json jNames = JsonArray();
    json jWLs   = JsonArray();
    json jGolds = JsonArray();
    json jEncs  = JsonArray();

    int i;
    for(i = 0; i < nCount; i++)
    {
        json jRow = JsonArrayGet(jRows, i);
        int nNet  = JsonGetInt(JsonObjectGet(jRow, "gold_net"));
        jNames = JsonArrayInsert(jNames, JsonString(JsonGetString(JsonObjectGet(jRow, "char_name"))));
        jWLs   = JsonArrayInsert(jWLs,   JsonString(
                     IntToString(JsonGetInt(JsonObjectGet(jRow, "wins"))) + "W / " +
                     IntToString(JsonGetInt(JsonObjectGet(jRow, "losses"))) + "P"));
        jGolds = JsonArrayInsert(jGolds, JsonString((nNet >= 0 ? "+" : "") + IntToString(nNet) + " gp"));
        jEncs  = JsonArrayInsert(jEncs,  JsonBool(FALSE));
    }

    NuiSetBind(oPC, nLbToken, DICE_BIND_LB_NAME,  jNames);
    NuiSetBind(oPC, nLbToken, DICE_BIND_LB_WL,    jWLs);
    NuiSetBind(oPC, nLbToken, DICE_BIND_LB_GOLD,  jGolds);
    NuiSetBind(oPC, nLbToken, DICE_BIND_LB_ENC,   jEncs);
    NuiSetBind(oPC, nLbToken, "dice_lb_count",     JsonInt(nCount));
}

// ---------------------------------------------------------------
// Roll resolution (called via DelayCommand after suspense)
// ---------------------------------------------------------------

void DiceRevealResults(object oPC, int nToken, int nBet, json jPlayerDice, json jDealerDice)
{
    // Guard: window may have closed during delay
    if(NuiFindWindow(oPC, DICE_WINDOW) != nToken)
    {
        DeleteLocalInt(oPC, DICE_LVAR_BUSY);
        return;
    }

    int nPScore = DiceEvaluateHand(jPlayerDice);
    int nDScore = DiceEvaluateHand(jDealerDice);
    int nPRank  = DiceHandRank(nPScore);
    int nDRank  = DiceHandRank(nDScore);

    // Reveal dice values
    NuiSetBind(oPC, nToken, DICE_BIND_P_D1, JsonString(IntToString(JsonGetInt(JsonArrayGet(jPlayerDice, 0)))));
    NuiSetBind(oPC, nToken, DICE_BIND_P_D2, JsonString(IntToString(JsonGetInt(JsonArrayGet(jPlayerDice, 1)))));
    NuiSetBind(oPC, nToken, DICE_BIND_P_D3, JsonString(IntToString(JsonGetInt(JsonArrayGet(jPlayerDice, 2)))));
    NuiSetBind(oPC, nToken, DICE_BIND_P_D4, JsonString(IntToString(JsonGetInt(JsonArrayGet(jPlayerDice, 3)))));
    NuiSetBind(oPC, nToken, DICE_BIND_P_D5, JsonString(IntToString(JsonGetInt(JsonArrayGet(jPlayerDice, 4)))));
    NuiSetBind(oPC, nToken, DICE_BIND_D_D1, JsonString(IntToString(JsonGetInt(JsonArrayGet(jDealerDice, 0)))));
    NuiSetBind(oPC, nToken, DICE_BIND_D_D2, JsonString(IntToString(JsonGetInt(JsonArrayGet(jDealerDice, 1)))));
    NuiSetBind(oPC, nToken, DICE_BIND_D_D3, JsonString(IntToString(JsonGetInt(JsonArrayGet(jDealerDice, 2)))));
    NuiSetBind(oPC, nToken, DICE_BIND_D_D4, JsonString(IntToString(JsonGetInt(JsonArrayGet(jDealerDice, 3)))));
    NuiSetBind(oPC, nToken, DICE_BIND_D_D5, JsonString(IntToString(JsonGetInt(JsonArrayGet(jDealerDice, 4)))));

    // Jackpot contribution (rounds down, minimum 1 gp)
    int nContrib = nBet / DICE_JACKPOT_FRAC;
    if(nContrib < 1) nContrib = 1;

    // Special case: five 1s beats regular five-of-a-kind (curse, no jackpot payout)
    int bFiveOfAKind = (nPRank == DICE_HAND_FIVE);
    int bAllOnes     = (bFiveOfAKind && DiceHandValue(nPScore) == 1);

    int bPlayerWins = (nPScore > nDScore);
    int bTie        = (nPScore == nDScore);

    string sPHand = DiceHandName(nPRank);
    string sDHand = DiceHandName(nDRank);
    string sResult;
    int nGoldDelta = 0;
    int nStreak    = GetLocalInt(oPC, DICE_LVAR_STREAK);

    if(bAllOnes)
    {
        // Worst outcome: lose bet regardless of dealer's hand
        AssignCommand(oPC, TakeGoldFromCreature(nBet, oPC, TRUE));
        DiceAddToJackpot(nContrib);
        nGoldDelta  = -nBet;
        bPlayerWins = FALSE;
        nStreak     = (nStreak < 0 ? nStreak - 1 : -1);
        sResult = "Pięć jedynek... Fortuna odwraca od ciebie wzrok. Tracisz "
                + IntToString(nBet) + " gp.";
        DiceApplyLuckCurse(oPC);
    }
    else if(bFiveOfAKind)
    {
        // Jackpot: win the entire pool regardless of dealer's hand
        int nJackpot = DiceGetJackpot();
        GiveGoldToCreature(oPC, nJackpot);
        DiceResetJackpot();
        nGoldDelta  = nJackpot;
        bPlayerWins = TRUE;
        nStreak     = (nStreak > 0 ? nStreak + 1 : 1);
        sResult = "PIĘĆ JEDNAKOWYCH! Jackpot " + IntToString(nJackpot)
                + " gp trafia w twoje ręce!";
        DiceApplyLuckBoon(oPC);
    }
    else if(bTie)
    {
        sResult    = "Remis — kości milczą. Stawka wraca do twojej sakwy.";
        nGoldDelta = 0;
        nStreak    = 0;
    }
    else if(bPlayerWins)
    {
        GiveGoldToCreature(oPC, nBet);
        DiceAddToJackpot(nContrib);
        nGoldDelta = nBet;
        nStreak    = (nStreak > 0 ? nStreak + 1 : 1);

        if(nStreak >= 5)
            sResult = "SERIA " + IntToString(nStreak) + "! Kostki śpiewają twoje imię! +"
                    + IntToString(nBet) + " gp.";
        else
            sResult = "Wygrywasz! " + sPHand + " bije " + sDHand + ". +"
                    + IntToString(nBet) + " gp.";
    }
    else
    {
        AssignCommand(oPC, TakeGoldFromCreature(nBet, oPC, TRUE));
        DiceAddToJackpot(nContrib);
        nGoldDelta = -nBet;
        nStreak    = (nStreak < 0 ? nStreak - 1 : -1);

        if(nStreak <= -5)
            sResult = "Seria " + IntToString(-nStreak) + " porażek. Może jutro szczęście się uśmiechnie. -"
                    + IntToString(nBet) + " gp.";
        else
            sResult = "Przegrywasz. " + sDHand + " bije " + sPHand + ". -"
                    + IntToString(nBet) + " gp.";
    }

    SetLocalInt(oPC, DICE_LVAR_STREAK, nStreak);

    // Update color per side
    json cWin  = NuiColor(230, 200,  60);
    json cLose = NuiColor(200,  70,  70);
    json cTie  = NuiColor(160, 160, 160);
    NuiSetBind(oPC, nToken, DICE_BIND_P_COL, bTie ? cTie : (bPlayerWins ? cWin : cLose));
    NuiSetBind(oPC, nToken, DICE_BIND_D_COL, bTie ? cTie : (bPlayerWins ? cLose : cWin));

    NuiSetBind(oPC, nToken, DICE_BIND_P_HAND, JsonString(sPHand));
    NuiSetBind(oPC, nToken, DICE_BIND_D_HAND, JsonString(sDHand));
    NuiSetBind(oPC, nToken, DICE_BIND_RESULT, JsonString(sResult));

    // Persist record (ties are not recorded)
    if(!bTie)
        DiceUpdateRecord(oPC, bPlayerWins, nGoldDelta, nPRank, nStreak > 0 ? nStreak : 0);

    // Refresh gold and jackpot labels
    NuiSetBind(oPC, nToken, DICE_BIND_GOLD_LBL,
        JsonString("Złoto: " + IntToString(GetGold(oPC)) + " gp"));
    NuiSetBind(oPC, nToken, DICE_BIND_JACKPOT,
        JsonString("Pula jackpotu: " + IntToString(DiceGetJackpot()) + " gp"));

    DiceFeedRecord(oPC, nToken);

    DeleteLocalInt(oPC, DICE_LVAR_BUSY);
    NuiSetBind(oPC, nToken, DICE_BIND_ROLL_ENA, JsonBool(TRUE));
}

// ---------------------------------------------------------------
// Roll entry point — validates bet, shows suspense, schedules reveal
// ---------------------------------------------------------------

void DiceRollStart(object oPC, int nToken)
{
    if(GetLocalInt(oPC, DICE_LVAR_BUSY)) return;

    string sBetStr = JsonGetString(NuiGetBind(oPC, nToken, DICE_BIND_BET_TXT));
    int nBet       = StringToInt(sBetStr);

    if(nBet < DICE_MIN_BET)
    {
        SendMessageToPC(oPC, "[Kości Losu] Minimalna stawka to " + IntToString(DICE_MIN_BET) + " gp.");
        return;
    }
    if(nBet > DICE_MAX_BET)
    {
        SendMessageToPC(oPC, "[Kości Losu] Maksymalna stawka to " + IntToString(DICE_MAX_BET) + " gp.");
        return;
    }
    if(GetGold(oPC) < nBet)
    {
        SendMessageToPC(oPC, "[Kości Losu] Nie masz wystarczająco złota.");
        return;
    }

    SetLocalInt(oPC, DICE_LVAR_BUSY, 1);
    NuiSetBind(oPC, nToken, DICE_BIND_ROLL_ENA, JsonBool(FALSE));

    // Suspense: all dice show "?"
    DiceFeedBlankDice(oPC, nToken, "?");
    NuiSetBind(oPC, nToken, DICE_BIND_P_HAND, JsonString("..."));
    NuiSetBind(oPC, nToken, DICE_BIND_D_HAND, JsonString("..."));
    NuiSetBind(oPC, nToken, DICE_BIND_RESULT, JsonString("Kości toczą się po stole..."));

    // Roll now; reveal after delay
    json jPlayerDice = DiceRollFive();
    json jDealerDice = DiceRollFive();

    DelayCommand(1.5, DiceRevealResults(oPC, nToken, nBet, jPlayerDice, jDealerDice));
}

// ---------------------------------------------------------------
// Window open / re-open
// ---------------------------------------------------------------

void DiceOpenWindow(object oPC)
{
    DiceRegisterPlayer(oPC);

    int nToken = NuiFindWindow(oPC, DICE_WINDOW);
    if(nToken != 0)
    {
        DiceFeedInitialState(oPC, nToken);
        return;
    }

    float fX = (IntToFloat(GetPlayerDeviceProperty(oPC, PLAYER_DEVICE_PROPERTY_GUI_WIDTH))
                - GetNuiScaleDimension(oPC, DICE_W)) / 2.0;
    float fY = (IntToFloat(GetPlayerDeviceProperty(oPC, PLAYER_DEVICE_PROPERTY_GUI_HEIGHT))
                - GetNuiScaleDimension(oPC, DICE_H)) / 2.0;
    json jGeom = NuiRect(fX, fY,
                         GetNuiScaleDimension(oPC, DICE_W),
                         GetNuiScaleDimension(oPC, DICE_H));

    float fBtnH    = GetNuiScaleDimension(oPC, 32.0);
    json jCloseBtn = NuiButton(JsonString("X"));
    jCloseBtn = NuiId(jCloseBtn, DICE_BTN_CLOSE);
    jCloseBtn = NuiWidth(jCloseBtn, GetNuiScaleDimension(oPC, 32.0));
    jCloseBtn = NuiHeight(jCloseBtn, fBtnH);

    json jTitleLbl = NuiLabel(JsonString("Kości Losu"),
                              JsonInt(NUI_HALIGN_LEFT), JsonInt(NUI_VALIGN_MIDDLE));
    jTitleLbl = NuiHeight(jTitleLbl, fBtnH);
    jTitleLbl = NuiStyleForegroundColor(jTitleLbl, NuiColor(230, 200, 60));

    json jTitleRow = JsonArray();
    jTitleRow = JsonArrayInsert(jTitleRow, jTitleLbl);
    jTitleRow = JsonArrayInsert(jTitleRow, NuiSpacer());
    jTitleRow = JsonArrayInsert(jTitleRow, jCloseBtn);

    json jRootCol = JsonArray();
    jRootCol = JsonArrayInsert(jRootCol, NuiRow(jTitleRow));
    jRootCol = JsonArrayInsert(jRootCol, DiceBuildMainLayout(oPC));

    json jWin = NuiWindow(NuiCol(jRootCol),
        JsonBool(FALSE),
        NuiBind(DICE_WIN_GEOM),
        JsonBool(FALSE),
        JsonBool(FALSE),
        JsonBool(FALSE),
        JsonBool(TRUE),
        JsonBool(FALSE));

    nToken = NuiCreate(oPC, jWin, DICE_WINDOW, DICE_EV_SCRIPT);
    NuiSetBind(oPC, nToken, DICE_WIN_GEOM, jGeom);
    NuiSetBindWatch(oPC, nToken, DICE_BIND_BET_TXT, TRUE);

    DiceFeedInitialState(oPC, nToken);
}
