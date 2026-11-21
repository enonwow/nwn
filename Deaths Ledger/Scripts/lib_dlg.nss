#include "lib_dlg_def"

void DlgCreateBargainWindow(object oPC);
void DlgCreateLedgerWindow(object oPC);

// ----------------------------------------------------------------
// Effect management
// ----------------------------------------------------------------

void DlgRemoveDebtEffects(object oPC)
{
    effect eEff = GetFirstEffect(oPC);
    while(GetIsEffectValid(eEff))
    {
        if(GetEffectTag(eEff) == "DLG_DEBT_EFFECT")
            RemoveEffect(oPC, eEff);
        eEff = GetNextEffect(oPC);
    }
}

void DlgApplyDebtEffects(object oPC)
{
    DlgRemoveDebtEffects(oPC);

    int nDebt = DlgGetDebt(oPC);
    if(nDebt <= 0) return;

    int nSavePen = (nDebt >= 7) ? -3 : (nDebt >= 4) ? -2 : -1;
    int nNegPen  = (nDebt >= 8) ? -4 : (nDebt >= 5) ? -3 : (nDebt >= 2) ? -2 : 0;
    int nStrPen  = (nDebt >= 9) ? -5 : (nDebt >= 6) ? -4 : (nDebt >= 4) ? -3 : (nDebt >= 3) ? -2 : 0;

    // Permanent supernatural effects tagged for later removal/reapplication
    effect eSave = TagEffect(
        EffectSavingThrowDecrease(SAVING_THROW_ALL, -nSavePen, SAVING_THROW_TYPE_DEATH),
        "DLG_DEBT_EFFECT");
    ApplyEffectToObject(DURATION_TYPE_PERMANENT, eSave, oPC);

    if(nNegPen < 0)
    {
        effect eNeg = TagEffect(
            EffectSavingThrowDecrease(SAVING_THROW_ALL, -nNegPen, SAVING_THROW_TYPE_NEGATIVE),
            "DLG_DEBT_EFFECT");
        ApplyEffectToObject(DURATION_TYPE_PERMANENT, eNeg, oPC);
    }

    if(nStrPen < 0)
    {
        effect eStr = TagEffect(
            EffectAbilityDecrease(ABILITY_STRENGTH, -nStrPen),
            "DLG_DEBT_EFFECT");
        ApplyEffectToObject(DURATION_TYPE_PERMANENT, eStr, oPC);
    }

    // Visual mark for debt >= 5
    if(nDebt >= 5)
    {
        effect eVis = TagEffect(EffectVisualEffect(VFX_DUR_AURA_BLEED), "DLG_DEBT_EFFECT");
        ApplyEffectToObject(DURATION_TYPE_PERMANENT, eVis, oPC);
    }
}

// ----------------------------------------------------------------
// Emissary spawning
// ----------------------------------------------------------------

string DlgGetEmissaryResref(int nDebt)
{
    if(nDebt >= 8) return DLG_EMISSARY_RESREF_3;
    if(nDebt >= 5) return DLG_EMISSARY_RESREF_2;
    return DLG_EMISSARY_RESREF_1;
}

void DlgSpawnEmissary(object oPC)
{
    if(!GetIsObjectValid(oPC) || !GetIsPC(oPC)) return;

    int nDebt = DlgGetDebt(oPC);
    if(nDebt < 3) return;

    sqlquery qNow = SqlPrepareQueryCampaign("deaths_ledger", "SELECT strftime('%s','now')");
    int nUnixNow  = SqlStep(qNow) ? SqlGetInt(qNow, 0) : 0;
    int nLast     = DlgGetLastEmissary(oPC);

    if(nUnixNow - nLast < DLG_EMISSARY_HOURS * 3600) return;

    string sResref = DlgGetEmissaryResref(nDebt);
    location lPC   = GetLocation(oPC);

    object oEmissary = CreateObject(OBJECT_TYPE_CREATURE, sResref, lPC, FALSE, DLG_EMISSARY_TAG);
    if(!GetIsObjectValid(oEmissary)) return;

    SetLocalObject(oEmissary, "DLG_TARGET", oPC);
    DlgSetLastEmissary(oPC);

    // Scale emissary HP/level via effect bonus HP proportional to debt
    int nBonusHP = (nDebt - 2) * 20;
    if(nBonusHP > 0)
        ApplyEffectToObject(DURATION_TYPE_PERMANENT, EffectTemporaryHitpoints(nBonusHP), oEmissary);

    AssignCommand(oEmissary, ActionAttack(oPC));

    string sMsg = "";
    if(nDebt <= 4) sMsg = "[Dług Śmierci] Posłaniec nadszedł po swoje. Słyszysz echo kroków.";
    else if(nDebt <= 7) sMsg = "[Dług Śmierci] Cień Posłańca materializuje się przed tobą. Dług rośnie.";
    else           sMsg = "[Dług Śmierci] Sama Śmierć zesłała swą rękę. Twoje dni są policzone.";

    FloatingTextStringOnCreature(sMsg, oPC, FALSE);
    SendMessageToPC(oPC, sMsg);
}

// ----------------------------------------------------------------
// Bargain window — shown when PC is dying
// ----------------------------------------------------------------

json BuildBargainView(object oPC)
{
    float fBtnH   = GetNuiScaleDimension(oPC, 36.0);
    float fFlavorH= GetNuiScaleDimension(oPC, 160.0);

    json jFlavor = NuiGroup(NuiText(NuiBind(DLG_BIND_BARG_FLAVOR), FALSE), FALSE, NUI_SCROLLBARS_NONE);
    jFlavor = NuiHeight(jFlavor, fFlavorH);

    json jDebtLbl = NuiLabel(NuiBind(DLG_BIND_BARG_DEBT_LBL),
        JsonInt(NUI_HALIGN_CENTER), JsonInt(NUI_VALIGN_MIDDLE));
    jDebtLbl = NuiHeight(jDebtLbl, GetNuiScaleDimension(oPC, 26.0));

    json jWarnLbl = NuiLabel(NuiBind(DLG_BIND_BARG_WARN),
        JsonInt(NUI_HALIGN_CENTER), JsonInt(NUI_VALIGN_MIDDLE));
    jWarnLbl = NuiHeight(jWarnLbl, GetNuiScaleDimension(oPC, 24.0));
    jWarnLbl = NuiStyleForegroundColor(jWarnLbl, NuiColor(220, 80, 60));

    json jAccept = NuiButton(JsonString("Przyjmij pakt — wskrześ mnie"));
    jAccept = NuiId(jAccept, DLG_BTN_BARGAIN_ACCEPT);
    jAccept = NuiHeight(jAccept, fBtnH);

    json jRefuse = NuiButton(JsonString("Odmów — zaakceptuj śmierć"));
    jRefuse = NuiId(jRefuse, DLG_BTN_BARGAIN_REFUSE);
    jRefuse = NuiHeight(jRefuse, fBtnH);

    json jSep = CreateEmptyRow(oPC, 8.0);

    json jCol = JsonArray();
    jCol = JsonArrayInsert(jCol, jFlavor);
    jCol = JsonArrayInsert(jCol, jDebtLbl);
    jCol = JsonArrayInsert(jCol, jWarnLbl);
    jCol = JsonArrayInsert(jCol, jSep);
    jCol = JsonArrayInsert(jCol, jAccept);
    jCol = JsonArrayInsert(jCol, jSep);
    jCol = JsonArrayInsert(jCol, jRefuse);

    json jSide = NuiCol(JsonArrayInsert(JsonArray(), NuiSpacer()));
    float fContentW = GetNuiScaleDimension(oPC, 440.0);
    json jMain = JsonArray();
    jMain = JsonArrayInsert(jMain, jSide);
    jMain = JsonArrayInsert(jMain, NuiWidth(NuiCol(jCol), fContentW));
    jMain = JsonArrayInsert(jMain, jSide);
    return NuiRow(jMain);
}

void DlgCreateBargainWindow(object oPC)
{
    if(NuiFindWindow(oPC, DLG_WIN_BARGAIN) != 0)
        NuiDestroy(oPC, NuiFindWindow(oPC, DLG_WIN_BARGAIN));

    float fX = (IntToFloat(GetPlayerDeviceProperty(oPC, PLAYER_DEVICE_PROPERTY_GUI_WIDTH))
                - GetNuiScaleDimension(oPC, DLG_W_BARG)) / 2.0;
    float fY = (IntToFloat(GetPlayerDeviceProperty(oPC, PLAYER_DEVICE_PROPERTY_GUI_HEIGHT))
                - GetNuiScaleDimension(oPC, DLG_H_BARG)) / 2.0;
    json jGeom = NuiRect(fX, fY,
        GetNuiScaleDimension(oPC, DLG_W_BARG),
        GetNuiScaleDimension(oPC, DLG_H_BARG));

    json jWin = NuiWindow(BuildBargainView(oPC),
        JsonString("Oblicze Śmierci"),
        NuiBind(DLG_BIND_GEOM_BARG),
        JsonBool(FALSE), JsonBool(FALSE), JsonBool(FALSE),
        JsonBool(FALSE), JsonBool(FALSE));

    int nToken = NuiCreate(oPC, jWin, DLG_WIN_BARGAIN, DLG_EV_SCRIPT);
    NuiSetBind(oPC, nToken, DLG_BIND_GEOM_BARG, jGeom);

    int nDebt = DlgGetDebt(oPC);
    NuiSetBind(oPC, nToken, DLG_BIND_BARG_FLAVOR,   JsonString(DlgBargainFlavor(nDebt)));
    NuiSetBind(oPC, nToken, DLG_BIND_BARG_DEBT_LBL, JsonString(DlgDebtLabel(nDebt)));

    string sWarn = "";
    if(nDebt >= 9)
        sWarn = "Kolejny pakt będzie ostatnim. Śmierć czeka.";
    else if(nDebt >= 5)
        sWarn = "Nowy dług: " + DlgDebtLabel(nDebt + 1) + " — kary wzrosną.";
    else if(nDebt >= 1)
        sWarn = "Twój dług wzrośnie do poziomu " + IntToString(nDebt + 1) + ".";
    NuiSetBind(oPC, nToken, DLG_BIND_BARG_WARN, JsonString(sWarn));
}

// ----------------------------------------------------------------
// Ledger window — opened via altar or command
// ----------------------------------------------------------------

json BuildLedgerView(object oPC)
{
    float fBtnH  = GetNuiScaleDimension(oPC, 34.0);
    float fFxH   = GetNuiScaleDimension(oPC, 180.0);

    json jTitle = NuiLabel(NuiBind(DLG_BIND_LED_TITLE),
        JsonInt(NUI_HALIGN_CENTER), JsonInt(NUI_VALIGN_MIDDLE));
    jTitle = NuiHeight(jTitle, GetNuiScaleDimension(oPC, 30.0));
    jTitle = NuiStyleForegroundColor(jTitle, NuiColor(200, 60, 60));

    json jDebtLbl = NuiLabel(NuiBind(DLG_BIND_LED_DEBT_LBL),
        JsonInt(NUI_HALIGN_CENTER), JsonInt(NUI_VALIGN_MIDDLE));
    jDebtLbl = NuiHeight(jDebtLbl, GetNuiScaleDimension(oPC, 26.0));

    json jFx = NuiGroup(NuiText(NuiBind(DLG_BIND_LED_EFFECTS), FALSE), FALSE, NUI_SCROLLBARS_AUTO);
    jFx = NuiHeight(jFx, fFxH);

    // Gold cost row
    json jGoldLbl = NuiLabel(NuiBind(DLG_BIND_LED_GOLD_COST),
        JsonInt(NUI_HALIGN_LEFT), JsonInt(NUI_VALIGN_MIDDLE));
    json jPayGold = NuiButton(JsonString("Zapłać złotem"));
    jPayGold = NuiId(jPayGold, DLG_BTN_PAY_GOLD);
    jPayGold = NuiEnabled(jPayGold, NuiBind(DLG_BIND_LED_PAY_ENA));
    jPayGold = NuiWidth(jPayGold, GetNuiScaleDimension(oPC, 150.0));
    jPayGold = NuiHeight(jPayGold, fBtnH);

    json jGoldRow = JsonArray();
    jGoldRow = JsonArrayInsert(jGoldRow, jGoldLbl);
    jGoldRow = JsonArrayInsert(jGoldRow, NuiSpacer());
    jGoldRow = JsonArrayInsert(jGoldRow, jPayGold);

    // HP cost row
    json jHpLbl = NuiLabel(NuiBind(DLG_BIND_LED_HP_COST),
        JsonInt(NUI_HALIGN_LEFT), JsonInt(NUI_VALIGN_MIDDLE));
    json jPayHp = NuiButton(JsonString("Złóż ofiarę z krwi"));
    jPayHp = NuiId(jPayHp, DLG_BTN_PAY_HP);
    jPayHp = NuiEnabled(jPayHp, NuiBind(DLG_BIND_LED_HP_ENA));
    jPayHp = NuiWidth(jPayHp, GetNuiScaleDimension(oPC, 150.0));
    jPayHp = NuiHeight(jPayHp, fBtnH);

    json jHpRow = JsonArray();
    jHpRow = JsonArrayInsert(jHpRow, jHpLbl);
    jHpRow = JsonArrayInsert(jHpRow, NuiSpacer());
    jHpRow = JsonArrayInsert(jHpRow, jPayHp);

    // Penance row
    json jPenLbl = NuiLabel(NuiBind(DLG_BIND_LED_PEN_LBL),
        JsonInt(NUI_HALIGN_LEFT), JsonInt(NUI_VALIGN_MIDDLE));
    json jPenance = NuiButton(JsonString("Złóż przysięgę pokuty"));
    jPenance = NuiId(jPenance, DLG_BTN_PENANCE);
    jPenance = NuiEnabled(jPenance, NuiBind(DLG_BIND_LED_PEN_ENA));
    jPenance = NuiWidth(jPenance, GetNuiScaleDimension(oPC, 150.0));
    jPenance = NuiHeight(jPenance, fBtnH);

    json jPenRow = JsonArray();
    jPenRow = JsonArrayInsert(jPenRow, jPenLbl);
    jPenRow = JsonArrayInsert(jPenRow, NuiSpacer());
    jPenRow = JsonArrayInsert(jPenRow, jPenance);

    json jClose = NuiButton(JsonString("Zamknij"));
    jClose = NuiId(jClose, DLG_BTN_CLOSE);
    jClose = NuiWidth(jClose, GetNuiScaleDimension(oPC, 100.0));
    jClose = NuiHeight(jClose, fBtnH);

    json jBotRow = JsonArray();
    jBotRow = JsonArrayInsert(jBotRow, NuiSpacer());
    jBotRow = JsonArrayInsert(jBotRow, jClose);

    json jSep = CreateEmptyRow(oPC, 6.0);

    json jCol = JsonArray();
    jCol = JsonArrayInsert(jCol, jTitle);
    jCol = JsonArrayInsert(jCol, jDebtLbl);
    jCol = JsonArrayInsert(jCol, jFx);
    jCol = JsonArrayInsert(jCol, jSep);
    jCol = JsonArrayInsert(jCol, NuiRow(jGoldRow));
    jCol = JsonArrayInsert(jCol, NuiRow(jHpRow));
    jCol = JsonArrayInsert(jCol, NuiRow(jPenRow));
    jCol = JsonArrayInsert(jCol, jSep);
    jCol = JsonArrayInsert(jCol, NuiRow(jBotRow));

    json jSide = NuiCol(JsonArrayInsert(JsonArray(), NuiSpacer()));
    float fContentW = GetNuiScaleDimension(oPC, 500.0);
    json jMain = JsonArray();
    jMain = JsonArrayInsert(jMain, jSide);
    jMain = JsonArrayInsert(jMain, NuiWidth(NuiCol(jCol), fContentW));
    jMain = JsonArrayInsert(jMain, jSide);
    return NuiRow(jMain);
}

void DlgFeedLedger(object oPC, int nToken)
{
    int nDebt = DlgGetDebt(oPC);
    int nGold = GetGold(oPC);
    int nGoldCost = nDebt * DLG_GOLD_PER_DEBT;
    int nMaxHP    = GetMaxHitPoints(oPC);
    int nHpPenBefore = DlgGetHpPenalty(oPC);
    // HP sacrifice: 10% max HP per debt point, capped so they can't go below 1 hp total penalty
    int nHpCost = (nMaxHP * DLG_HP_PCT_PER_DEBT * nDebt) / 100;
    if(nHpCost < 1 && nDebt > 0) nHpCost = 1;

    int nPenDeadline = DlgGetPenanceDeadline(oPC);
    int bPenActive   = (nPenDeadline > 0);

    sqlquery qNow = SqlPrepareQueryCampaign("deaths_ledger", "SELECT strftime('%s','now')");
    int nUnixNow  = SqlStep(qNow) ? SqlGetInt(qNow, 0) : 0;
    int bPenExpired = bPenActive && (nUnixNow > nPenDeadline);

    NuiSetBind(oPC, nToken, DLG_BIND_LED_TITLE,
        JsonString("Księga Długu"));
    NuiSetBind(oPC, nToken, DLG_BIND_LED_DEBT_LBL,
        JsonString(DlgDebtLabel(nDebt)));
    NuiSetBind(oPC, nToken, DLG_BIND_LED_EFFECTS,
        JsonString(DlgEffectDesc(nDebt)));

    string sGoldLbl;
    if(nDebt <= 0)
        sGoldLbl = "Brak długu do spłacenia złotem.";
    else
        sGoldLbl = "Koszt odkupienia złotem: " + IntToString(nGoldCost) + " gp (" + IntToString(nDebt) + " pkt)";
    NuiSetBind(oPC, nToken, DLG_BIND_LED_GOLD_COST, JsonString(sGoldLbl));
    NuiSetBind(oPC, nToken, DLG_BIND_LED_PAY_ENA,   JsonBool(nDebt > 0 && nGold >= nGoldCost));

    string sHpLbl;
    if(nDebt <= 0)
        sHpLbl = "Brak długu do spłacenia krwią.";
    else
        sHpLbl = "Ofiara z krwi: trwała utrata " + IntToString(nHpCost) + " HP maks. (" + IntToString(nDebt) + " pkt)";
    NuiSetBind(oPC, nToken, DLG_BIND_LED_HP_COST, JsonString(sHpLbl));
    NuiSetBind(oPC, nToken, DLG_BIND_LED_HP_ENA,
        JsonBool(nDebt > 0 && (nMaxHP - nHpPenBefore - nHpCost) >= 10));

    string sPenLbl;
    if(nDebt <= 0)
        sPenLbl = "Brak długu — pokuta nie jest wymagana.";
    else if(bPenActive && !bPenExpired)
    {
        sqlquery qLeft = SqlPrepareQueryCampaign("deaths_ledger",
            "SELECT strftime('%d', @dl - strftime('%s','now'), 'unixepoch')");
        SqlBindInt(qLeft, "@dl", nPenDeadline);
        int nDaysLeft = SqlStep(qLeft) ? SqlGetInt(qLeft, 0) : 0;
        sPenLbl = "Pokuta trwa... pozostało ~" + IntToString(nDaysLeft) + " dni. Wróć po zakończeniu.";
    }
    else if(bPenExpired)
        sPenLbl = "Pokuta dobiegła końca! Kliknij, by odebrać przebaczenie.";
    else
        sPenLbl = "Złóż przysięgę 7-dniowej pokuty (bez walki przez 7 dni).";

    NuiSetBind(oPC, nToken, DLG_BIND_LED_PEN_LBL, JsonString(sPenLbl));
    // Can start penance if debt>0 and no active non-expired penance; can collect if expired
    NuiSetBind(oPC, nToken, DLG_BIND_LED_PEN_ENA,
        JsonBool(nDebt > 0 && (!bPenActive || bPenExpired)));
}

void DlgOpenLedger(object oPC)
{
    if(NuiFindWindow(oPC, DLG_WIN_LEDGER) != 0)
    {
        DlgFeedLedger(oPC, NuiFindWindow(oPC, DLG_WIN_LEDGER));
        return;
    }

    float fX = (IntToFloat(GetPlayerDeviceProperty(oPC, PLAYER_DEVICE_PROPERTY_GUI_WIDTH))
                - GetNuiScaleDimension(oPC, DLG_W_LED)) / 2.0;
    float fY = (IntToFloat(GetPlayerDeviceProperty(oPC, PLAYER_DEVICE_PROPERTY_GUI_HEIGHT))
                - GetNuiScaleDimension(oPC, DLG_H_LED)) / 2.0;
    json jGeom = NuiRect(fX, fY,
        GetNuiScaleDimension(oPC, DLG_W_LED),
        GetNuiScaleDimension(oPC, DLG_H_LED));

    json jWin = NuiWindow(BuildLedgerView(oPC),
        JsonBool(FALSE),
        NuiBind(DLG_BIND_GEOM_LED),
        JsonBool(FALSE), JsonBool(FALSE), JsonBool(FALSE),
        JsonBool(TRUE),  JsonBool(FALSE));

    int nToken = NuiCreate(oPC, jWin, DLG_WIN_LEDGER, DLG_EV_SCRIPT);
    NuiSetBind(oPC, nToken, DLG_BIND_GEOM_LED, jGeom);
    DlgFeedLedger(oPC, nToken);
}

// ----------------------------------------------------------------
// Gold payment — reduce entire debt at once if affordable
// ----------------------------------------------------------------

void DlgPayWithGold(object oPC)
{
    int nDebt = DlgGetDebt(oPC);
    if(nDebt <= 0) return;

    int nCost = nDebt * DLG_GOLD_PER_DEBT;
    if(GetGold(oPC) < nCost)
    {
        SendMessageToPC(oPC, "[Dług Śmierci] Nie masz dość złota. Potrzebujesz " + IntToString(nCost) + " gp.");
        return;
    }

    AssignCommand(oPC, TakeGoldFromCreature(nCost, oPC, TRUE));
    DlgReduceDebt(oPC, nDebt);
    DlgApplyDebtEffects(oPC);

    SendMessageToPC(oPC, "[Dług Śmierci] Dług spłacony złotem. Śmierć jest zaspokojona... na razie.");
    FloatingTextStringOnCreature("Dług spłacony.", oPC, FALSE);

    int nToken = NuiFindWindow(oPC, DLG_WIN_LEDGER);
    if(nToken != 0) DlgFeedLedger(oPC, nToken);
}

// ----------------------------------------------------------------
// HP sacrifice — permanent max HP reduction
// ----------------------------------------------------------------

void DlgPayWithBlood(object oPC)
{
    int nDebt = DlgGetDebt(oPC);
    if(nDebt <= 0) return;

    int nMaxHP    = GetMaxHitPoints(oPC);
    int nHpCost   = (nMaxHP * DLG_HP_PCT_PER_DEBT * nDebt) / 100;
    if(nHpCost < 1) nHpCost = 1;

    int nPenBefore = DlgGetHpPenalty(oPC);
    if((nMaxHP - nPenBefore - nHpCost) < 10)
    {
        SendMessageToPC(oPC, "[Dług Śmierci] Nie możesz poświęcić tyle krwi — zostałoby zbyt mało życia.");
        return;
    }

    // NWN has no "reduce max HP" effect; we drain CON as a proxy (~2 Con ≈ 1 HP/HD)
    int nConDrain = (nHpCost / 5) + 1;
    effect eCon = TagEffect(EffectAbilityDecrease(ABILITY_CONSTITUTION, nConDrain), "DLG_DEBT_HP_SACRIFICE");
    ApplyEffectToObject(DURATION_TYPE_PERMANENT, eCon, oPC);

    DlgAddHpPenalty(oPC, nHpCost);
    DlgReduceDebt(oPC, nDebt);
    DlgApplyDebtEffects(oPC);

    SendMessageToPC(oPC, "[Dług Śmierci] Krew spłynęła na ołtarz. Dług zmazany — lecz blizna pozostanie.");
    FloatingTextStringOnCreature("Ofiara z krwi przyjęta.", oPC, FALSE);
    ApplyEffectToObject(DURATION_TYPE_INSTANT, EffectVisualEffect(VFX_IMP_REDUCE_ABILITY_SCORE), oPC);

    int nToken = NuiFindWindow(oPC, DLG_WIN_LEDGER);
    if(nToken != 0) DlgFeedLedger(oPC, nToken);
}

// ----------------------------------------------------------------
// Penance — start or collect
// ----------------------------------------------------------------

void DlgHandlePenance(object oPC)
{
    int nDebt = DlgGetDebt(oPC);
    if(nDebt <= 0) return;

    int nPenDeadline = DlgGetPenanceDeadline(oPC);
    sqlquery qNow = SqlPrepareQueryCampaign("deaths_ledger", "SELECT strftime('%s','now')");
    int nUnixNow  = SqlStep(qNow) ? SqlGetInt(qNow, 0) : 0;

    if(nPenDeadline > 0 && nUnixNow > nPenDeadline)
    {
        // Collect completed penance — reduce 1 debt point
        DlgReduceDebt(oPC, 1);
        DlgClearPenanceDeadline(oPC);
        DlgApplyDebtEffects(oPC);
        SendMessageToPC(oPC, "[Dług Śmierci] Pokuta zakończona. Śmierć docenia twoje poświęcenie — jeden dług zmazany.");
        FloatingTextStringOnCreature("Pokuta zakończona.", oPC, FALSE);
        ApplyEffectToObject(DURATION_TYPE_INSTANT, EffectVisualEffect(VFX_IMP_HOLY_AID), oPC);
    }
    else if(nPenDeadline <= 0)
    {
        // Start penance
        DlgSetPenanceDeadline(oPC, DLG_PENANCE_DAYS);
        SendMessageToPC(oPC, "[Dług Śmierci] Przysięga złożona. Przez " + IntToString(DLG_PENANCE_DAYS)
            + " dni unikaj walki. Wróć do ołtarza, by odebrać przebaczenie.");
        FloatingTextStringOnCreature("Pokuta rozpoczęta.", oPC, FALSE);
    }
    else
    {
        SendMessageToPC(oPC, "[Dług Śmierci] Pokuta wciąż trwa. Wróć za kilka dni.");
    }

    int nToken = NuiFindWindow(oPC, DLG_WIN_LEDGER);
    if(nToken != 0) DlgFeedLedger(oPC, nToken);
}
