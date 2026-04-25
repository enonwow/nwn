#include "lib_duel_def"

// ----------------------------------------------------------------
// Honor Duels — overlay HUD (active duel) + popups
// ----------------------------------------------------------------

void DestroyDuelHud(object oPC)
{
    int nTk = NuiFindWindow(oPC, DUEL_WIN_HUD);
    if(nTk != 0) NuiDestroy(oPC, nTk);
}

void CreateDuelHud(object oPC, int nDuelId)
{
    DestroyDuelHud(oPC);

    float fW = GetNuiScaleDimension(oPC, DUEL_HUD_W);
    float fH = GetNuiScaleDimension(oPC, DUEL_HUD_H);
    float fBarH = GetNuiScaleDimension(oPC, 18.0);
    float fLblH = GetNuiScaleDimension(oPC, 22.0);
    float fBtnH = GetNuiScaleDimension(oPC, 28.0);

    json jTitle = NuiLabel(NuiBind(DUEL_BIND_HUD_TITLE),
        JsonInt(NUI_HALIGN_CENTER), JsonInt(NUI_VALIGN_MIDDLE));
    jTitle = NuiHeight(jTitle, fLblH);

    json jOppLbl = NuiLabel(JsonString("Przeciwnik"),
        JsonInt(NUI_HALIGN_LEFT), JsonInt(NUI_VALIGN_MIDDLE));
    jOppLbl = NuiHeight(jOppLbl, fLblH);
    json jOppBar = NuiProgress(NuiBind(DUEL_BIND_HUD_OPP_HP));
    jOppBar = NuiTooltip(jOppBar, NuiBind(DUEL_BIND_HUD_OPP_HP_TIP));
    jOppBar = NuiHeight(jOppBar, fBarH);

    json jSelfLbl = NuiLabel(JsonString("Ty"),
        JsonInt(NUI_HALIGN_LEFT), JsonInt(NUI_VALIGN_MIDDLE));
    jSelfLbl = NuiHeight(jSelfLbl, fLblH);
    json jSelfBar = NuiProgress(NuiBind(DUEL_BIND_HUD_SELF_HP));
    jSelfBar = NuiTooltip(jSelfBar, NuiBind(DUEL_BIND_HUD_SELF_HP_TIP));
    jSelfBar = NuiHeight(jSelfBar, fBarH);

    json jBounds = NuiLabel(NuiBind(DUEL_BIND_HUD_BOUNDS),
        JsonInt(NUI_HALIGN_CENTER), JsonInt(NUI_VALIGN_MIDDLE));
    jBounds = NuiHeight(jBounds, fLblH);
    jBounds = NuiStyleForegroundColor(jBounds, NuiColor(220, 60, 60));

    json jYield = NuiButton(JsonString("Poddaj sie"));
    jYield = NuiId(jYield, DUEL_BTN_HUD_YIELD);
    jYield = NuiHeight(jYield, fBtnH);

    json jCol = JsonArray();
    jCol = JsonArrayInsert(jCol, jTitle);
    jCol = JsonArrayInsert(jCol, jOppLbl);
    jCol = JsonArrayInsert(jCol, jOppBar);
    jCol = JsonArrayInsert(jCol, jSelfLbl);
    jCol = JsonArrayInsert(jCol, jSelfBar);
    jCol = JsonArrayInsert(jCol, jBounds);
    jCol = JsonArrayInsert(jCol, jYield);

    json jRoot = NuiCol(jCol);

    json jNui = NuiWindow(jRoot,
        JsonString("Pojedynek"),
        NuiBind(DUEL_BIND_HUD_GEOM),
        JsonBool(FALSE),  // resizable
        JsonBool(FALSE),  // collapsed
        JsonBool(FALSE),  // closable — only via duel end
        JsonBool(FALSE),  // transparent
        JsonBool(TRUE));  // border

    int nTk = NuiCreate(oPC, jNui, DUEL_WIN_HUD, DUEL_EV_SCRIPT);

    NuiSetBind(oPC, nTk, DUEL_BIND_HUD_GEOM,
        NuiRect(20.0, 60.0, fW, fH));
    NuiSetBind(oPC, nTk, DUEL_BIND_HUD_TITLE,    JsonString("Pojedynek"));
    NuiSetBind(oPC, nTk, DUEL_BIND_HUD_OPP_HP,   JsonFloat(1.0));
    NuiSetBind(oPC, nTk, DUEL_BIND_HUD_SELF_HP,  JsonFloat(1.0));
    NuiSetBind(oPC, nTk, DUEL_BIND_HUD_OPP_HP_TIP,  JsonString("100%"));
    NuiSetBind(oPC, nTk, DUEL_BIND_HUD_SELF_HP_TIP, JsonString("100%"));
    NuiSetBind(oPC, nTk, DUEL_BIND_HUD_BOUNDS,   JsonString(""));
}

// ----------------------------------------------------------------
// Incoming challenge popup (target sees this)
// ----------------------------------------------------------------

void DuelShowIncomingPopup(object oPC, int nDuelId)
{
    int nExisting = NuiFindWindow(oPC, DUEL_WIN_INCOMING);
    if(nExisting != 0) NuiDestroy(oPC, nExisting);

    json jD = DuelGetById(nDuelId);
    if(JsonGetType(jD) == JSON_TYPE_NULL) return;

    SetLocalInt(oPC, DUEL_LVAR_INCOMING_ID, nDuelId);

    string sName  = JsonGetString(JsonObjectGet(jD, "challenger_name"));
    int nRules    = JsonGetInt   (JsonObjectGet(jD, "rules_mask"));
    int nWinCond  = JsonGetInt   (JsonObjectGet(jD, "win_cond"));
    int nStake    = JsonGetInt   (JsonObjectGet(jD, "stake_gold"));

    float fW = GetNuiScaleDimension(oPC, DUEL_INCOMING_W);
    float fH = GetNuiScaleDimension(oPC, DUEL_INCOMING_H);
    float fLblH = GetNuiScaleDimension(oPC, 24.0);
    float fBtnH = GetNuiScaleDimension(oPC, 32.0);

    json jTitle = NuiLabel(NuiBind(DUEL_BIND_INC_TITLE),
        JsonInt(NUI_HALIGN_CENTER), JsonInt(NUI_VALIGN_MIDDLE));
    jTitle = NuiHeight(jTitle, fLblH);

    json jWin = NuiLabel(NuiBind(DUEL_BIND_INC_WIN),
        JsonInt(NUI_HALIGN_LEFT), JsonInt(NUI_VALIGN_MIDDLE));
    jWin = NuiHeight(jWin, fLblH);

    json jRules = NuiLabel(NuiBind(DUEL_BIND_INC_RULES),
        JsonInt(NUI_HALIGN_LEFT), JsonInt(NUI_VALIGN_MIDDLE));
    jRules = NuiHeight(jRules, fLblH);

    json jStake = NuiLabel(NuiBind(DUEL_BIND_INC_STAKE),
        JsonInt(NUI_HALIGN_LEFT), JsonInt(NUI_VALIGN_MIDDLE));
    jStake = NuiHeight(jStake, fLblH);

    json jAccept = NuiButton(JsonString("Przyjmij"));
    jAccept = NuiId(jAccept, DUEL_BTN_INC_ACCEPT);
    jAccept = NuiHeight(jAccept, fBtnH);

    json jDecline = NuiButton(JsonString("Odrzuc"));
    jDecline = NuiId(jDecline, DUEL_BTN_INC_DECLINE);
    jDecline = NuiHeight(jDecline, fBtnH);

    json jBtnRow = JsonArray();
    jBtnRow = JsonArrayInsert(jBtnRow, jAccept);
    jBtnRow = JsonArrayInsert(jBtnRow, jDecline);

    json jCol = JsonArray();
    jCol = JsonArrayInsert(jCol, jTitle);
    jCol = JsonArrayInsert(jCol, jWin);
    jCol = JsonArrayInsert(jCol, jRules);
    jCol = JsonArrayInsert(jCol, jStake);
    jCol = JsonArrayInsert(jCol, NuiSpacer());
    jCol = JsonArrayInsert(jCol, NuiRow(jBtnRow));

    json jRoot = NuiCol(jCol);

    json jNui = NuiWindow(jRoot,
        JsonString("Wyzwanie"),
        NuiRect(-1.0, -1.0, fW, fH),
        JsonBool(FALSE),
        JsonBool(FALSE),
        JsonBool(TRUE),
        JsonBool(FALSE),
        JsonBool(TRUE));

    int nTk = NuiCreate(oPC, jNui, DUEL_WIN_INCOMING, DUEL_EV_SCRIPT);

    NuiSetBind(oPC, nTk, DUEL_BIND_INC_TITLE,
        JsonString(sName + " rzuca ci wyzwanie."));
    NuiSetBind(oPC, nTk, DUEL_BIND_INC_WIN,
        JsonString("Warunek zwyciestwa: " + DuelWinConditionToString(nWinCond)));
    NuiSetBind(oPC, nTk, DUEL_BIND_INC_RULES,
        JsonString("Reguly: " + DuelRulesToString(nRules)));
    NuiSetBind(oPC, nTk, DUEL_BIND_INC_STAKE,
        JsonString(nStake > 0
            ? "Stawka: " + IntToString(nStake) + " zlota (musisz dolozyc tyle samo)"
            : "Stawka: brak"));
}

// ----------------------------------------------------------------
// Challenge config popup (challenger fills before sending)
// ----------------------------------------------------------------

void DuelShowChallengeConfig(object oPC, string sTargetUuid, string sTargetName)
{
    int nExisting = NuiFindWindow(oPC, DUEL_WIN_CHALLENGE);
    if(nExisting != 0) NuiDestroy(oPC, nExisting);

    SetLocalString(oPC, DUEL_LVAR_DRAFT_TARGET, sTargetUuid);
    SetLocalString(oPC, DUEL_LVAR_DRAFT_NAME,   sTargetName);
    SetLocalInt   (oPC, DUEL_LVAR_DRAFT_RULES,  0);
    SetLocalInt   (oPC, DUEL_LVAR_DRAFT_WIN,    DUEL_WIN_FIRST_BLOOD);
    SetLocalInt   (oPC, DUEL_LVAR_DRAFT_STAKE,  0);

    float fW = GetNuiScaleDimension(oPC, DUEL_CHALLENGE_W);
    float fH = GetNuiScaleDimension(oPC, DUEL_CHALLENGE_H);
    float fLblH = GetNuiScaleDimension(oPC, 22.0);
    float fBtnH = GetNuiScaleDimension(oPC, 28.0);

    json jTarget = NuiLabel(NuiBind(DUEL_BIND_CH_TARGET_LBL),
        JsonInt(NUI_HALIGN_CENTER), JsonInt(NUI_VALIGN_MIDDLE));
    jTarget = NuiHeight(jTarget, fLblH);

    // Win condition group
    json jWinLbl = NuiLabel(JsonString("Warunek zwyciestwa:"),
        JsonInt(NUI_HALIGN_LEFT), JsonInt(NUI_VALIGN_MIDDLE));
    jWinLbl = NuiHeight(jWinLbl, fLblH);

    json jWinFb = NuiCheck(JsonString("Pierwsza krew"), NuiBind(DUEL_BIND_CH_WIN_FB));
    jWinFb = NuiId(jWinFb, DUEL_BTN_CH_WIN_FB);
    json jWinDeath = NuiCheck(JsonString("Na smierc"), NuiBind(DUEL_BIND_CH_WIN_DEATH));
    jWinDeath = NuiId(jWinDeath, DUEL_BTN_CH_WIN_DEATH);
    json jWinYield = NuiCheck(JsonString("Do poddania"), NuiBind(DUEL_BIND_CH_WIN_YIELD));
    jWinYield = NuiId(jWinYield, DUEL_BTN_CH_WIN_YIELD);

    // Rules group
    json jRulesLbl = NuiLabel(JsonString("Reguly:"),
        JsonInt(NUI_HALIGN_LEFT), JsonInt(NUI_VALIGN_MIDDLE));
    jRulesLbl = NuiHeight(jRulesLbl, fLblH);

    json jR1 = NuiCheck(JsonString("Bez magii"), NuiBind(DUEL_BIND_CH_RULE_NOMAGIC));
    jR1 = NuiId(jR1, DUEL_BTN_CH_RULE_NOMAGIC);
    json jR2 = NuiCheck(JsonString("Bez mikstur i zwojow"), NuiBind(DUEL_BIND_CH_RULE_NOITEMS));
    jR2 = NuiId(jR2, DUEL_BTN_CH_RULE_NOITEMS);
    json jR3 = NuiCheck(JsonString("Bez krytykow"), NuiBind(DUEL_BIND_CH_RULE_NOCRIT));
    jR3 = NuiId(jR3, DUEL_BTN_CH_RULE_NOCRIT);

    // Stake
    json jStakeLbl = NuiLabel(JsonString("Stawka (zloto):"),
        JsonInt(NUI_HALIGN_LEFT), JsonInt(NUI_VALIGN_MIDDLE));
    jStakeLbl = NuiHeight(jStakeLbl, fLblH);

    json jStake = NuiTextEdit(JsonString("0"), NuiBind(DUEL_BIND_CH_STAKE_TXT), 8, FALSE);
    jStake = NuiHeight(jStake, fLblH);

    // Buttons
    json jSend = NuiButton(JsonString("Rzuc rekawice"));
    jSend = NuiId(jSend, DUEL_BTN_CH_SEND);
    jSend = NuiEnabled(jSend, NuiBind(DUEL_BIND_CH_SEND_ENA));
    jSend = NuiHeight(jSend, fBtnH);

    json jCancel = NuiButton(JsonString("Anuluj"));
    jCancel = NuiId(jCancel, DUEL_BTN_CH_CANCEL);
    jCancel = NuiHeight(jCancel, fBtnH);

    json jBtnRow = JsonArray();
    jBtnRow = JsonArrayInsert(jBtnRow, jSend);
    jBtnRow = JsonArrayInsert(jBtnRow, jCancel);

    json jCol = JsonArray();
    jCol = JsonArrayInsert(jCol, jTarget);
    jCol = JsonArrayInsert(jCol, jWinLbl);
    jCol = JsonArrayInsert(jCol, jWinFb);
    jCol = JsonArrayInsert(jCol, jWinDeath);
    jCol = JsonArrayInsert(jCol, jWinYield);
    jCol = JsonArrayInsert(jCol, jRulesLbl);
    jCol = JsonArrayInsert(jCol, jR1);
    jCol = JsonArrayInsert(jCol, jR2);
    jCol = JsonArrayInsert(jCol, jR3);
    jCol = JsonArrayInsert(jCol, jStakeLbl);
    jCol = JsonArrayInsert(jCol, jStake);
    jCol = JsonArrayInsert(jCol, NuiSpacer());
    jCol = JsonArrayInsert(jCol, NuiRow(jBtnRow));

    json jRoot = NuiCol(jCol);

    json jNui = NuiWindow(jRoot,
        JsonString("Wyzwanie na pojedynek"),
        NuiRect(-1.0, -1.0, fW, fH),
        JsonBool(FALSE), JsonBool(FALSE),
        JsonBool(TRUE),  JsonBool(FALSE), JsonBool(TRUE));

    int nTk = NuiCreate(oPC, jNui, DUEL_WIN_CHALLENGE, DUEL_EV_SCRIPT);

    NuiSetBind(oPC, nTk, DUEL_BIND_CH_TARGET_LBL,
        JsonString("Wyzywasz: " + sTargetName));
    NuiSetBind(oPC, nTk, DUEL_BIND_CH_WIN_FB,        JsonBool(TRUE));
    NuiSetBind(oPC, nTk, DUEL_BIND_CH_WIN_DEATH,     JsonBool(FALSE));
    NuiSetBind(oPC, nTk, DUEL_BIND_CH_WIN_YIELD,     JsonBool(FALSE));
    NuiSetBind(oPC, nTk, DUEL_BIND_CH_RULE_NOMAGIC,  JsonBool(FALSE));
    NuiSetBind(oPC, nTk, DUEL_BIND_CH_RULE_NOITEMS,  JsonBool(FALSE));
    NuiSetBind(oPC, nTk, DUEL_BIND_CH_RULE_NOCRIT,   JsonBool(FALSE));
    NuiSetBind(oPC, nTk, DUEL_BIND_CH_STAKE_TXT,     JsonString("0"));
    NuiSetBind(oPC, nTk, DUEL_BIND_CH_SEND_ENA,      JsonBool(TRUE));
}
