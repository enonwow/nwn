// lib_haz.nss — core logic, scoring, UI construction and feed functions
#include "lib_haz_def"

void HazFeedBetPhase(object oPC, int nToken);
void HazFeedRolledPhase(object oPC, int nToken);
void HazFeedResult(object oPC, int nToken, int nPlayerScore, int nDealerScore, int nPayout);
void HazUpdateGoldLabel(object oPC, int nToken);
void HazOpenStatsWindow(object oPC);

// ----------------------------------------------------------------
// Scoring
// Three-of-a-kind:  5000 + face*100          → 5100–5600
// Straight (low):   4000 + low_die*100        → 4100–4400
// Pair:             3000 + pair_face*100 + kicker → 3101–3605
// High card:        sum of dice               → 3–18
// ----------------------------------------------------------------

int HazScore(int d1, int d2, int d3)
{
    // Sort ascending
    int tmp;
    if(d1 > d2) { tmp = d1; d1 = d2; d2 = tmp; }
    if(d2 > d3) { tmp = d2; d2 = d3; d3 = tmp; }
    if(d1 > d2) { tmp = d1; d1 = d2; d2 = tmp; }

    if(d1 == d3)
        return 5000 + d1 * 100;                         // Dragon

    if(d2 == d1 + 1 && d3 == d1 + 2)
        return 4000 + d1 * 100;                         // Serpent (straight)

    if(d1 == d2)
        return 3000 + d1 * 100 + d3;                   // Wyvern (pair d1, kicker d3)

    if(d2 == d3)
        return 3000 + d2 * 100 + d1;                   // Wyvern (pair d2, kicker d1)

    return d1 + d2 + d3;                               // Demon's Hand (high card)
}

string HazHandName(int nScore)
{
    if(nScore >= 5000) return "Smok Trojaki";
    if(nScore >= 4000) return "Wąż Schodowy";
    if(nScore >= 3000) return "Para Bazyliszka";
    return "Wysoka Kość";
}

json HazHandColor(int nScore)
{
    if(nScore >= 5000) return NuiColor(255, 140,   0);  // fiery orange — Dragon
    if(nScore >= 4000) return NuiColor(140, 200, 255);  // ice blue   — Serpent
    if(nScore >= 3000) return NuiColor(180, 255, 180);  // pale green — Wyvern
    return NuiColor(180, 180, 180);                     // grey       — high card
}

// ----------------------------------------------------------------
// Dealer AI — rolls 3d6; rerolls single worst die once if score < pair-of-2s
// Stores final dice into PC LVARs HAZ_DD1/DD2/DD3 and returns final score
// ----------------------------------------------------------------

int HazDealerPlayFull(object oPC, int d1, int d2, int d3)
{
    int nScore = HazScore(d1, d2, d3);

    // Stand threshold: pair of 2s = 3000+200+highest_kicker ≥ 3201
    if(nScore < 3201)
    {
        // Reroll the single die not part of the best partial combination
        // Simple: if pair exists keep it; otherwise reroll the lowest die
        int bPair = (d1 == d2 || d1 == d3 || d2 == d3);
        if(bPair)
        {
            // Reroll the odd die out
            if(d1 != d2 && d1 != d3)      d1 = Random(6) + 1;
            else if(d2 != d1 && d2 != d3) d2 = Random(6) + 1;
            else                           d3 = Random(6) + 1;
        }
        else
        {
            // No pair — reroll lowest (d1 after sorting above)
            int lo = d1;
            if(d2 < lo) lo = d2;
            if(d3 < lo) lo = d3;
            if(d1 == lo)      d1 = Random(6) + 1;
            else if(d2 == lo) d2 = Random(6) + 1;
            else              d3 = Random(6) + 1;
        }
        nScore = HazScore(d1, d2, d3);
    }

    SetLocalInt(oPC, HAZ_LVAR_DD1, d1);
    SetLocalInt(oPC, HAZ_LVAR_DD2, d2);
    SetLocalInt(oPC, HAZ_LVAR_DD3, d3);
    return nScore;
}

// ----------------------------------------------------------------
// Payout calculation — returns signed gold delta for the player
// Positive = profit received; negative = gold taken
// Dragon win: 2× bet as profit; Serpent win: 1× bet + 50%; normal win: 1× bet
// Blood multiplier applies on top after the base calculation
// ----------------------------------------------------------------

int HazCalcPayout(int nPlayerScore, int nDealerScore, int nBet, int bBlood)
{
    int nMult = bBlood ? 3 : 1;

    if(nPlayerScore > nDealerScore)
    {
        int nBase = nBet;
        if(nPlayerScore >= 5000)      nBase = nBet * 2;      // Dragon
        else if(nPlayerScore >= 4000) nBase = nBet + nBet / 2; // Serpent (1.5×, floor)
        return nBase * nMult;
    }
    if(nPlayerScore < nDealerScore)
        return -(nBet * nMult);

    return 0; // push
}

// ----------------------------------------------------------------
// UI helpers
// ----------------------------------------------------------------

void HazUpdateGoldLabel(object oPC, int nToken)
{
    json jStats = HazGetStats(oPC);
    int nWins   = JsonGetInt(JsonObjectGet(jStats, "wins"));
    int nLosses = JsonGetInt(JsonObjectGet(jStats, "losses"));
    int nGold   = GetGold(oPC);
    string sLbl = "Złoto: " + IntToString(nGold) + " szt."
                + "   |   W: " + IntToString(nWins)
                + "  P: " + IntToString(nLosses);
    NuiSetBind(oPC, nToken, HAZ_BIND_GOLD_LBL, JsonString(sLbl));
}

json HazBuildDieButton(object oPC, string sBtnId, string sBindFace, string sBindEnc, float fSz)
{
    json jBtn = NuiButton(NuiBind(sBindFace));
    jBtn = NuiId(jBtn, sBtnId);
    jBtn = NuiWidth(jBtn, fSz);
    jBtn = NuiHeight(jBtn, fSz);
    jBtn = NuiEncouraged(jBtn, NuiBind(sBindEnc));
    return jBtn;
}

json HazBuildDealerDieBox(object oPC, string sBindFace, float fSz)
{
    json jLbl = NuiLabel(NuiBind(sBindFace),
        JsonInt(NUI_HALIGN_CENTER), JsonInt(NUI_VALIGN_MIDDLE));
    json jGrp = NuiGroup(jLbl, FALSE, NUI_SCROLLBARS_NONE);
    jGrp = NuiWidth(jGrp, fSz);
    jGrp = NuiHeight(jGrp, fSz);
    return jGrp;
}

// ----------------------------------------------------------------
// Window layout — built once, state driven entirely through binds
// ----------------------------------------------------------------

json HazBuildRoot(object oPC)
{
    float fBtnH  = GetNuiScaleDimension(oPC, 32.0);
    float fDieSz = GetNuiScaleDimension(oPC, 76.0);
    float fLblH  = GetNuiScaleDimension(oPC, 24.0);
    float fGap   = GetNuiScaleDimension(oPC, 6.0);

    // -- Title --
    json jTitle = NuiLabel(JsonString("Trzy Smocze Kości"),
        JsonInt(NUI_HALIGN_CENTER), JsonInt(NUI_VALIGN_MIDDLE));
    jTitle = NuiHeight(jTitle, GetNuiScaleDimension(oPC, 30.0));
    jTitle = NuiStyleForegroundColor(jTitle, NuiColor(200, 160, 60));

    // -- Bet row --
    json jBetLbl = NuiLabel(JsonString("Zakład:"),
        JsonInt(NUI_HALIGN_RIGHT), JsonInt(NUI_VALIGN_MIDDLE));
    jBetLbl = NuiWidth(jBetLbl, GetNuiScaleDimension(oPC, 65.0));

    json jBetField = NuiTextEdit(JsonString("100"), NuiBind(HAZ_BIND_BET), 6, FALSE);
    jBetField = NuiWidth(jBetField, GetNuiScaleDimension(oPC, 90.0));
    jBetField = NuiHeight(jBetField, fBtnH);
    jBetField = NuiEnabled(jBetField, NuiBind(HAZ_BIND_BET_ENA));

    json jBetUnit = NuiLabel(JsonString("szt."),
        JsonInt(NUI_HALIGN_LEFT), JsonInt(NUI_VALIGN_MIDDLE));
    jBetUnit = NuiWidth(jBetUnit, GetNuiScaleDimension(oPC, 32.0));

    json jBloodChk = NuiCheckbox(JsonString("Cena Krwi"), NuiBind(HAZ_BIND_BLOOD));
    jBloodChk = NuiEnabled(jBloodChk, NuiBind(HAZ_BIND_BET_ENA));
    jBloodChk = NuiTooltip(jBloodChk,
        JsonString("Wygrana ×3, lecz porażka kosztuje 10% maksymalnego zdrowia."));

    json jBetRow = JsonArray();
    jBetRow = JsonArrayInsert(jBetRow, jBetLbl);
    jBetRow = JsonArrayInsert(jBetRow, jBetField);
    jBetRow = JsonArrayInsert(jBetRow, jBetUnit);
    jBetRow = JsonArrayInsert(jBetRow, NuiSpacer());
    jBetRow = JsonArrayInsert(jBetRow, jBloodChk);

    // -- Player dice header --
    json jPHdr = NuiLabel(JsonString("~~~ Twoje Kości ~~~"),
        JsonInt(NUI_HALIGN_CENTER), JsonInt(NUI_VALIGN_MIDDLE));
    jPHdr = NuiHeight(jPHdr, fLblH);
    jPHdr = NuiStyleForegroundColor(jPHdr, NuiColor(210, 210, 210));

    // -- Player dice row --
    json jD1 = HazBuildDieButton(oPC, HAZ_BTN_D1, HAZ_BIND_D1_FACE, HAZ_BIND_D1_ENC, fDieSz);
    json jD2 = HazBuildDieButton(oPC, HAZ_BTN_D2, HAZ_BIND_D2_FACE, HAZ_BIND_D2_ENC, fDieSz);
    json jD3 = HazBuildDieButton(oPC, HAZ_BTN_D3, HAZ_BIND_D3_FACE, HAZ_BIND_D3_ENC, fDieSz);

    json jDiceRow = JsonArray();
    jDiceRow = JsonArrayInsert(jDiceRow, NuiSpacer());
    jDiceRow = JsonArrayInsert(jDiceRow, jD1);
    jDiceRow = JsonArrayInsert(jDiceRow, NuiSpacer());
    jDiceRow = JsonArrayInsert(jDiceRow, jD2);
    jDiceRow = JsonArrayInsert(jDiceRow, NuiSpacer());
    jDiceRow = JsonArrayInsert(jDiceRow, jD3);
    jDiceRow = JsonArrayInsert(jDiceRow, NuiSpacer());

    // -- Player hand label --
    json jHandLbl = NuiLabel(NuiBind(HAZ_BIND_HAND_LBL),
        JsonInt(NUI_HALIGN_CENTER), JsonInt(NUI_VALIGN_MIDDLE));
    jHandLbl = NuiHeight(jHandLbl, fLblH);
    jHandLbl = NuiStyleForegroundColor(jHandLbl, NuiBind(HAZ_BIND_HAND_COL));

    // -- Dealer dice header --
    json jDHdr = NuiLabel(JsonString("~~~ Kości Krupiera ~~~"),
        JsonInt(NUI_HALIGN_CENTER), JsonInt(NUI_VALIGN_MIDDLE));
    jDHdr = NuiHeight(jDHdr, fLblH);
    jDHdr = NuiStyleForegroundColor(jDHdr, NuiColor(210, 210, 210));

    // -- Dealer dice row (non-interactive boxes) --
    json jDD1 = HazBuildDealerDieBox(oPC, HAZ_BIND_DD1_FACE, fDieSz);
    json jDD2 = HazBuildDealerDieBox(oPC, HAZ_BIND_DD2_FACE, fDieSz);
    json jDD3 = HazBuildDealerDieBox(oPC, HAZ_BIND_DD3_FACE, fDieSz);

    json jDDiceRow = JsonArray();
    jDDiceRow = JsonArrayInsert(jDDiceRow, NuiSpacer());
    jDDiceRow = JsonArrayInsert(jDDiceRow, jDD1);
    jDDiceRow = JsonArrayInsert(jDDiceRow, NuiSpacer());
    jDDiceRow = JsonArrayInsert(jDDiceRow, jDD2);
    jDDiceRow = JsonArrayInsert(jDDiceRow, NuiSpacer());
    jDDiceRow = JsonArrayInsert(jDDiceRow, jDD3);
    jDDiceRow = JsonArrayInsert(jDDiceRow, NuiSpacer());

    // -- Dealer hand label --
    json jDHandLbl = NuiLabel(NuiBind(HAZ_BIND_DHAND_LBL),
        JsonInt(NUI_HALIGN_CENTER), JsonInt(NUI_VALIGN_MIDDLE));
    jDHandLbl = NuiHeight(jDHandLbl, fLblH);
    jDHandLbl = NuiStyleForegroundColor(jDHandLbl, NuiBind(HAZ_BIND_DHAND_COL));

    // -- Hint / result label --
    json jHint = NuiLabel(NuiBind(HAZ_BIND_HINT_LBL),
        JsonInt(NUI_HALIGN_CENTER), JsonInt(NUI_VALIGN_MIDDLE));
    jHint = NuiHeight(jHint, fLblH);
    jHint = NuiStyleForegroundColor(jHint, NuiBind(HAZ_BIND_HINT_COL));

    json jResult = NuiLabel(NuiBind(HAZ_BIND_RESULT),
        JsonInt(NUI_HALIGN_CENTER), JsonInt(NUI_VALIGN_MIDDLE));
    jResult = NuiHeight(jResult, GetNuiScaleDimension(oPC, 28.0));
    jResult = NuiStyleForegroundColor(jResult, NuiBind(HAZ_BIND_RESULT_COL));

    // -- Action buttons: Roll | Reroll | Stand --
    float fActW = GetNuiScaleDimension(oPC, 130.0);

    json jRollBtn = NuiButton(JsonString("Rzuć kości"));
    jRollBtn = NuiId(jRollBtn, HAZ_BTN_ROLL);
    jRollBtn = NuiEnabled(jRollBtn, NuiBind(HAZ_BIND_ROLL_ENA));
    jRollBtn = NuiWidth(jRollBtn, fActW);
    jRollBtn = NuiHeight(jRollBtn, fBtnH);

    json jRerollBtn = NuiButton(JsonString("Przerzuć wolne"));
    jRerollBtn = NuiId(jRerollBtn, HAZ_BTN_REROLL);
    jRerollBtn = NuiEnabled(jRerollBtn, NuiBind(HAZ_BIND_REROLL_ENA));
    jRerollBtn = NuiWidth(jRerollBtn, GetNuiScaleDimension(oPC, 145.0));
    jRerollBtn = NuiHeight(jRerollBtn, fBtnH);
    jRerollBtn = NuiTooltip(jRerollBtn,
        JsonString("Przerzuca kości, których nie trzymasz. Można użyć raz na rundę."));

    json jStandBtn = NuiButton(JsonString("Stój"));
    jStandBtn = NuiId(jStandBtn, HAZ_BTN_STAND);
    jStandBtn = NuiEnabled(jStandBtn, NuiBind(HAZ_BIND_STAND_ENA));
    jStandBtn = NuiWidth(jStandBtn, fActW);
    jStandBtn = NuiHeight(jStandBtn, fBtnH);

    json jActRow = JsonArray();
    jActRow = JsonArrayInsert(jActRow, NuiSpacer());
    jActRow = JsonArrayInsert(jActRow, jRollBtn);
    jActRow = JsonArrayInsert(jActRow, jRerollBtn);
    jActRow = JsonArrayInsert(jActRow, jStandBtn);
    jActRow = JsonArrayInsert(jActRow, NuiSpacer());

    // -- New Round button --
    json jNewBtn = NuiButton(JsonString("Nowa Runda"));
    jNewBtn = NuiId(jNewBtn, HAZ_BTN_NEW);
    jNewBtn = NuiEnabled(jNewBtn, NuiBind(HAZ_BIND_NEW_ENA));
    jNewBtn = NuiWidth(jNewBtn, GetNuiScaleDimension(oPC, 180.0));
    jNewBtn = NuiHeight(jNewBtn, fBtnH);

    json jNewRow = JsonArray();
    jNewRow = JsonArrayInsert(jNewRow, NuiSpacer());
    jNewRow = JsonArrayInsert(jNewRow, jNewBtn);
    jNewRow = JsonArrayInsert(jNewRow, NuiSpacer());

    // -- Status bar: gold + stats button --
    json jGoldLbl = NuiLabel(NuiBind(HAZ_BIND_GOLD_LBL),
        JsonInt(NUI_HALIGN_LEFT), JsonInt(NUI_VALIGN_MIDDLE));

    json jStatBtn = NuiButton(JsonString("Statystyki"));
    jStatBtn = NuiId(jStatBtn, HAZ_BTN_STATS);
    jStatBtn = NuiWidth(jStatBtn, GetNuiScaleDimension(oPC, 100.0));
    jStatBtn = NuiHeight(jStatBtn, GetNuiScaleDimension(oPC, 26.0));

    json jStatusRow = JsonArray();
    jStatusRow = JsonArrayInsert(jStatusRow, jGoldLbl);
    jStatusRow = JsonArrayInsert(jStatusRow, NuiSpacer());
    jStatusRow = JsonArrayInsert(jStatusRow, jStatBtn);

    // -- Top bar: title + close --
    json jCloseBtn = NuiButton(JsonString("X"));
    jCloseBtn = NuiId(jCloseBtn, HAZ_BTN_CLOSE);
    jCloseBtn = NuiWidth(jCloseBtn, GetNuiScaleDimension(oPC, 30.0));
    jCloseBtn = NuiHeight(jCloseBtn, GetNuiScaleDimension(oPC, 26.0));

    json jTopRow = JsonArray();
    jTopRow = JsonArrayInsert(jTopRow, jTitle);
    jTopRow = JsonArrayInsert(jTopRow, NuiSpacer());
    jTopRow = JsonArrayInsert(jTopRow, jCloseBtn);

    // -- Assemble root column --
    json jCol = JsonArray();
    jCol = JsonArrayInsert(jCol, NuiRow(jTopRow));
    jCol = JsonArrayInsert(jCol, CreateEmptyRow(oPC, 4.0));
    jCol = JsonArrayInsert(jCol, NuiRow(jBetRow));
    jCol = JsonArrayInsert(jCol, CreateEmptyRow(oPC, 6.0));
    jCol = JsonArrayInsert(jCol, jPHdr);
    jCol = JsonArrayInsert(jCol, NuiRow(jDiceRow));
    jCol = JsonArrayInsert(jCol, jHandLbl);
    jCol = JsonArrayInsert(jCol, CreateEmptyRow(oPC, 6.0));
    jCol = JsonArrayInsert(jCol, jDHdr);
    jCol = JsonArrayInsert(jCol, NuiRow(jDDiceRow));
    jCol = JsonArrayInsert(jCol, jDHandLbl);
    jCol = JsonArrayInsert(jCol, CreateEmptyRow(oPC, 6.0));
    jCol = JsonArrayInsert(jCol, jHint);
    jCol = JsonArrayInsert(jCol, jResult);
    jCol = JsonArrayInsert(jCol, CreateEmptyRow(oPC, 4.0));
    jCol = JsonArrayInsert(jCol, NuiRow(jActRow));
    jCol = JsonArrayInsert(jCol, NuiRow(jNewRow));
    jCol = JsonArrayInsert(jCol, NuiSpacer());
    jCol = JsonArrayInsert(jCol, NuiRow(jStatusRow));

    // -- Centre content with side spacers --
    float fContentW = GetNuiScaleDimension(oPC, 500.0);
    json jSide = NuiCol(JsonArrayInsert(JsonArray(), NuiSpacer()));
    json jMainRow = JsonArray();
    jMainRow = JsonArrayInsert(jMainRow, jSide);
    jMainRow = JsonArrayInsert(jMainRow, NuiWidth(NuiCol(jCol), fContentW));
    jMainRow = JsonArrayInsert(jMainRow, jSide);
    return NuiRow(jMainRow);
}

// ----------------------------------------------------------------
// Window creation
// ----------------------------------------------------------------

void HazOpenWindow(object oPC)
{
    if(NuiFindWindow(oPC, HAZ_WINDOW) != 0)
    {
        NuiDestroy(oPC, NuiFindWindow(oPC, HAZ_WINDOW));
        return;
    }

    HazRegisterPlayer(oPC);

    float fCX = (IntToFloat(GetPlayerDeviceProperty(oPC, PLAYER_DEVICE_PROPERTY_GUI_WIDTH))
                 - GetNuiScaleDimension(oPC, HAZ_W)) / 2.0;
    float fCY = (IntToFloat(GetPlayerDeviceProperty(oPC, PLAYER_DEVICE_PROPERTY_GUI_HEIGHT))
                 - GetNuiScaleDimension(oPC, HAZ_H)) / 2.0;
    json jGeom = NuiRect(fCX, fCY,
                         GetNuiScaleDimension(oPC, HAZ_W),
                         GetNuiScaleDimension(oPC, HAZ_H));

    json jWin = NuiWindow(
        HazBuildRoot(oPC),
        JsonBool(FALSE),
        NuiBind(HAZ_WIN_GEOM),
        JsonBool(FALSE),
        JsonBool(FALSE),
        JsonBool(FALSE),
        JsonBool(TRUE),
        JsonBool(FALSE));

    int nToken = NuiCreate(oPC, jWin, HAZ_WINDOW, HAZ_EV_SCRIPT);
    NuiSetBind(oPC, nToken, HAZ_WIN_GEOM, jGeom);
    NuiSetBindWatch(oPC, nToken, HAZ_BIND_BET, TRUE);

    SetLocalInt(oPC, HAZ_LVAR_PHASE, HAZ_PHASE_BET);
    HazFeedBetPhase(oPC, nToken);
}

// ----------------------------------------------------------------
// Feed — Bet phase (initial state, new round)
// ----------------------------------------------------------------

void HazFeedBetPhase(object oPC, int nToken)
{
    NuiSetBind(oPC, nToken, HAZ_BIND_D1_FACE, JsonString("—"));
    NuiSetBind(oPC, nToken, HAZ_BIND_D2_FACE, JsonString("—"));
    NuiSetBind(oPC, nToken, HAZ_BIND_D3_FACE, JsonString("—"));
    NuiSetBind(oPC, nToken, HAZ_BIND_D1_ENC,  JsonBool(FALSE));
    NuiSetBind(oPC, nToken, HAZ_BIND_D2_ENC,  JsonBool(FALSE));
    NuiSetBind(oPC, nToken, HAZ_BIND_D3_ENC,  JsonBool(FALSE));

    NuiSetBind(oPC, nToken, HAZ_BIND_DD1_FACE, JsonString("?"));
    NuiSetBind(oPC, nToken, HAZ_BIND_DD2_FACE, JsonString("?"));
    NuiSetBind(oPC, nToken, HAZ_BIND_DD3_FACE, JsonString("?"));

    NuiSetBind(oPC, nToken, HAZ_BIND_HAND_LBL,  JsonString(""));
    NuiSetBind(oPC, nToken, HAZ_BIND_HAND_COL,  NuiColor(200, 200, 200));
    NuiSetBind(oPC, nToken, HAZ_BIND_DHAND_LBL, JsonString(""));
    NuiSetBind(oPC, nToken, HAZ_BIND_DHAND_COL, NuiColor(200, 200, 200));

    NuiSetBind(oPC, nToken, HAZ_BIND_HINT_LBL,   JsonString("Postaw zakład i rzuć kośćmi..."));
    NuiSetBind(oPC, nToken, HAZ_BIND_HINT_COL,   NuiColor(180, 180, 180));
    NuiSetBind(oPC, nToken, HAZ_BIND_RESULT,      JsonString(""));
    NuiSetBind(oPC, nToken, HAZ_BIND_RESULT_COL,  NuiColor(200, 200, 200));
    NuiSetBind(oPC, nToken, HAZ_BIND_BLOOD,       JsonBool(FALSE));

    NuiSetBind(oPC, nToken, HAZ_BIND_BET_ENA,    JsonBool(TRUE));
    NuiSetBind(oPC, nToken, HAZ_BIND_ROLL_ENA,   JsonBool(TRUE));
    NuiSetBind(oPC, nToken, HAZ_BIND_REROLL_ENA, JsonBool(FALSE));
    NuiSetBind(oPC, nToken, HAZ_BIND_STAND_ENA,  JsonBool(FALSE));
    NuiSetBind(oPC, nToken, HAZ_BIND_NEW_ENA,    JsonBool(FALSE));

    HazUpdateGoldLabel(oPC, nToken);
}

// ----------------------------------------------------------------
// Feed — Rolled phase (can hold dice, reroll, or stand)
// ----------------------------------------------------------------

void HazFeedRolledPhase(object oPC, int nToken)
{
    int d1 = GetLocalInt(oPC, HAZ_LVAR_D1);
    int d2 = GetLocalInt(oPC, HAZ_LVAR_D2);
    int d3 = GetLocalInt(oPC, HAZ_LVAR_D3);
    int h1 = GetLocalInt(oPC, HAZ_LVAR_H1);
    int h2 = GetLocalInt(oPC, HAZ_LVAR_H2);
    int h3 = GetLocalInt(oPC, HAZ_LVAR_H3);

    NuiSetBind(oPC, nToken, HAZ_BIND_D1_FACE, JsonString(IntToString(d1)));
    NuiSetBind(oPC, nToken, HAZ_BIND_D2_FACE, JsonString(IntToString(d2)));
    NuiSetBind(oPC, nToken, HAZ_BIND_D3_FACE, JsonString(IntToString(d3)));
    NuiSetBind(oPC, nToken, HAZ_BIND_D1_ENC,  JsonBool(h1));
    NuiSetBind(oPC, nToken, HAZ_BIND_D2_ENC,  JsonBool(h2));
    NuiSetBind(oPC, nToken, HAZ_BIND_D3_ENC,  JsonBool(h3));

    int nScore = HazScore(d1, d2, d3);
    NuiSetBind(oPC, nToken, HAZ_BIND_HAND_LBL,
        JsonString(HazHandName(nScore) + "  (" + IntToString(nScore) + " pkt)"));
    NuiSetBind(oPC, nToken, HAZ_BIND_HAND_COL, HazHandColor(nScore));

    NuiSetBind(oPC, nToken, HAZ_BIND_DD1_FACE, JsonString("?"));
    NuiSetBind(oPC, nToken, HAZ_BIND_DD2_FACE, JsonString("?"));
    NuiSetBind(oPC, nToken, HAZ_BIND_DD3_FACE, JsonString("?"));
    NuiSetBind(oPC, nToken, HAZ_BIND_DHAND_LBL, JsonString("Krupier czeka..."));
    NuiSetBind(oPC, nToken, HAZ_BIND_DHAND_COL, NuiColor(180, 180, 180));

    int bRerolled = GetLocalInt(oPC, HAZ_LVAR_REROLLED);
    NuiSetBind(oPC, nToken, HAZ_BIND_HINT_LBL,
        JsonString(bRerolled
            ? "Przerzut już użyty. Stój lub zmień trzymane kości."
            : "Kliknij kości, by trzymać. Przerzuć wolne lub Stój."));
    NuiSetBind(oPC, nToken, HAZ_BIND_HINT_COL,  NuiColor(180, 180, 180));
    NuiSetBind(oPC, nToken, HAZ_BIND_RESULT,     JsonString(""));

    NuiSetBind(oPC, nToken, HAZ_BIND_BET_ENA,    JsonBool(FALSE));
    NuiSetBind(oPC, nToken, HAZ_BIND_ROLL_ENA,   JsonBool(FALSE));
    NuiSetBind(oPC, nToken, HAZ_BIND_REROLL_ENA, JsonBool(!bRerolled));
    NuiSetBind(oPC, nToken, HAZ_BIND_STAND_ENA,  JsonBool(TRUE));
    NuiSetBind(oPC, nToken, HAZ_BIND_NEW_ENA,    JsonBool(FALSE));
}

// ----------------------------------------------------------------
// Feed — Result phase (round finished)
// ----------------------------------------------------------------

void HazFeedResult(object oPC, int nToken, int nPlayerScore, int nDealerScore, int nPayout)
{
    NuiSetBind(oPC, nToken, HAZ_BIND_D1_FACE,
        JsonString(IntToString(GetLocalInt(oPC, HAZ_LVAR_D1))));
    NuiSetBind(oPC, nToken, HAZ_BIND_D2_FACE,
        JsonString(IntToString(GetLocalInt(oPC, HAZ_LVAR_D2))));
    NuiSetBind(oPC, nToken, HAZ_BIND_D3_FACE,
        JsonString(IntToString(GetLocalInt(oPC, HAZ_LVAR_D3))));
    NuiSetBind(oPC, nToken, HAZ_BIND_D1_ENC, JsonBool(FALSE));
    NuiSetBind(oPC, nToken, HAZ_BIND_D2_ENC, JsonBool(FALSE));
    NuiSetBind(oPC, nToken, HAZ_BIND_D3_ENC, JsonBool(FALSE));

    NuiSetBind(oPC, nToken, HAZ_BIND_DD1_FACE,
        JsonString(IntToString(GetLocalInt(oPC, HAZ_LVAR_DD1))));
    NuiSetBind(oPC, nToken, HAZ_BIND_DD2_FACE,
        JsonString(IntToString(GetLocalInt(oPC, HAZ_LVAR_DD2))));
    NuiSetBind(oPC, nToken, HAZ_BIND_DD3_FACE,
        JsonString(IntToString(GetLocalInt(oPC, HAZ_LVAR_DD3))));

    NuiSetBind(oPC, nToken, HAZ_BIND_HAND_LBL,
        JsonString(HazHandName(nPlayerScore) + "  (" + IntToString(nPlayerScore) + " pkt)"));
    NuiSetBind(oPC, nToken, HAZ_BIND_HAND_COL, HazHandColor(nPlayerScore));

    NuiSetBind(oPC, nToken, HAZ_BIND_DHAND_LBL,
        JsonString(HazHandName(nDealerScore) + "  (" + IntToString(nDealerScore) + " pkt)"));
    NuiSetBind(oPC, nToken, HAZ_BIND_DHAND_COL, HazHandColor(nDealerScore));

    string sResult;
    json jResCol;
    if(nPayout > 0)
    {
        sResult  = "WYGRYWASZ!  Zdobywasz " + IntToString(nPayout) + " szt.";
        jResCol  = NuiColor(80, 220, 80);
    }
    else if(nPayout < 0)
    {
        sResult  = "PRZEGRYWASZ.  Tracisz " + IntToString(-nPayout) + " szt.";
        jResCol  = NuiColor(220, 80, 80);
    }
    else
    {
        sResult  = "REMIS.  Zakład zwrócony.";
        jResCol  = NuiColor(200, 200, 200);
    }

    NuiSetBind(oPC, nToken, HAZ_BIND_HINT_LBL,    JsonString(""));
    NuiSetBind(oPC, nToken, HAZ_BIND_RESULT,       JsonString(sResult));
    NuiSetBind(oPC, nToken, HAZ_BIND_RESULT_COL,   jResCol);

    NuiSetBind(oPC, nToken, HAZ_BIND_BET_ENA,    JsonBool(FALSE));
    NuiSetBind(oPC, nToken, HAZ_BIND_ROLL_ENA,   JsonBool(FALSE));
    NuiSetBind(oPC, nToken, HAZ_BIND_REROLL_ENA, JsonBool(FALSE));
    NuiSetBind(oPC, nToken, HAZ_BIND_STAND_ENA,  JsonBool(FALSE));
    NuiSetBind(oPC, nToken, HAZ_BIND_NEW_ENA,    JsonBool(TRUE));

    HazUpdateGoldLabel(oPC, nToken);
}

// ----------------------------------------------------------------
// Stats popup
// ----------------------------------------------------------------

void HazOpenStatsWindow(object oPC)
{
    if(NuiFindWindow(oPC, HAZ_WIN_STATS) != 0)
    {
        NuiDestroy(oPC, NuiFindWindow(oPC, HAZ_WIN_STATS));
        return;
    }

    float fW = GetNuiScaleDimension(oPC, 440.0);
    float fH = GetNuiScaleDimension(oPC, 360.0);
    float fX = (IntToFloat(GetPlayerDeviceProperty(oPC, PLAYER_DEVICE_PROPERTY_GUI_WIDTH))  - fW) / 2.0;
    float fY = (IntToFloat(GetPlayerDeviceProperty(oPC, PLAYER_DEVICE_PROPERTY_GUI_HEIGHT)) - fH) / 2.0;
    float fRowH = GetNuiScaleDimension(oPC, 24.0);

    // Player stats
    json jStats  = HazGetStats(oPC);
    int nWins    = JsonGetInt(JsonObjectGet(jStats, "wins"));
    int nLosses  = JsonGetInt(JsonObjectGet(jStats, "losses"));
    int nPushes  = JsonGetInt(JsonObjectGet(jStats, "pushes"));
    int nWon     = JsonGetInt(JsonObjectGet(jStats, "gold_won"));
    int nLost    = JsonGetInt(JsonObjectGet(jStats, "gold_lost"));

    string sMyStats = "Twoje wyniki:  W: " + IntToString(nWins)
        + "  P: " + IntToString(nLosses)
        + "  R: " + IntToString(nPushes)
        + "\nSaldo:  " + (nWon >= nLost
            ? "+" + IntToString(nWon - nLost)
            : IntToString(nWon - nLost)) + " szt.";

    json jMyLbl = NuiLabel(JsonString(sMyStats),
        JsonInt(NUI_HALIGN_LEFT), JsonInt(NUI_VALIGN_MIDDLE));
    jMyLbl = NuiHeight(jMyLbl, GetNuiScaleDimension(oPC, 52.0));

    // Leaderboard header
    json jLBHdr = NuiLabel(JsonString("Tablica sławy (wygrane):"),
        JsonInt(NUI_HALIGN_LEFT), JsonInt(NUI_VALIGN_MIDDLE));
    jLBHdr = NuiHeight(jLBHdr, fRowH);

    // Leaderboard rows (static list, built at open time)
    json jBoard = HazGetLeaderboard();
    int nBCount = JsonGetLength(jBoard);
    json jBoardCol = JsonArray();
    int i;
    for(i = 0; i < nBCount; i++)
    {
        json jEntry  = JsonArrayGet(jBoard, i);
        string sName = JsonGetString(JsonObjectGet(jEntry, "name"));
        int nW       = JsonGetInt   (JsonObjectGet(jEntry, "wins"));
        int nL       = JsonGetInt   (JsonObjectGet(jEntry, "losses"));
        int nBal     = JsonGetInt   (JsonObjectGet(jEntry, "balance"));
        string sRow  = IntToString(i + 1) + ". " + sName
            + "   W:" + IntToString(nW)
            + " P:" + IntToString(nL)
            + "   saldo: " + IntToString(nBal) + " szt.";

        json jRowLbl = NuiLabel(JsonString(sRow),
            JsonInt(NUI_HALIGN_LEFT), JsonInt(NUI_VALIGN_MIDDLE));
        jRowLbl = NuiHeight(jRowLbl, fRowH);
        jBoardCol = JsonArrayInsert(jBoardCol, jRowLbl);
    }
    if(nBCount == 0)
    {
        json jEmpty = NuiLabel(JsonString("Brak danych."),
            JsonInt(NUI_HALIGN_CENTER), JsonInt(NUI_VALIGN_MIDDLE));
        jEmpty = NuiHeight(jEmpty, fRowH);
        jBoardCol = JsonArrayInsert(jBoardCol, jEmpty);
    }

    json jCloseBtn = NuiButton(JsonString("Zamknij"));
    jCloseBtn = NuiId(jCloseBtn, HAZ_BTN_CLOSE);
    jCloseBtn = NuiWidth(jCloseBtn, GetNuiScaleDimension(oPC, 100.0));
    jCloseBtn = NuiHeight(jCloseBtn, GetNuiScaleDimension(oPC, 28.0));

    json jCloseRow = JsonArray();
    jCloseRow = JsonArrayInsert(jCloseRow, NuiSpacer());
    jCloseRow = JsonArrayInsert(jCloseRow, jCloseBtn);
    jCloseRow = JsonArrayInsert(jCloseRow, NuiSpacer());

    json jCol = JsonArray();
    jCol = JsonArrayInsert(jCol, jMyLbl);
    jCol = JsonArrayInsert(jCol, CreateEmptyRow(oPC, 8.0));
    jCol = JsonArrayInsert(jCol, jLBHdr);
    jCol = JsonArrayInsert(jCol, NuiCol(jBoardCol));
    jCol = JsonArrayInsert(jCol, NuiSpacer());
    jCol = JsonArrayInsert(jCol, NuiRow(jCloseRow));

    json jWin = NuiWindow(
        NuiCol(jCol),
        JsonString("Statystyki — Trzy Smocze Kości"),
        NuiRect(fX, fY, fW, fH),
        JsonBool(FALSE), JsonBool(FALSE), JsonBool(TRUE),
        JsonBool(FALSE), JsonBool(TRUE));

    NuiCreate(oPC, jWin, HAZ_WIN_STATS, HAZ_EV_SCRIPT);
}

// ----------------------------------------------------------------
// Cleanup LVARs on window close
// ----------------------------------------------------------------

void HazCleanupLvars(object oPC)
{
    DeleteLocalInt(oPC, HAZ_LVAR_PHASE);
    DeleteLocalInt(oPC, HAZ_LVAR_BET);
    DeleteLocalInt(oPC, HAZ_LVAR_D1);
    DeleteLocalInt(oPC, HAZ_LVAR_D2);
    DeleteLocalInt(oPC, HAZ_LVAR_D3);
    DeleteLocalInt(oPC, HAZ_LVAR_H1);
    DeleteLocalInt(oPC, HAZ_LVAR_H2);
    DeleteLocalInt(oPC, HAZ_LVAR_H3);
    DeleteLocalInt(oPC, HAZ_LVAR_REROLLED);
    DeleteLocalInt(oPC, HAZ_LVAR_BLOOD);
    DeleteLocalInt(oPC, HAZ_LVAR_DD1);
    DeleteLocalInt(oPC, HAZ_LVAR_DD2);
    DeleteLocalInt(oPC, HAZ_LVAR_DD3);
}
