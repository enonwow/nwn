#include "lib_bur_def"

// ----------------------------------------------------------------
// Text helpers
// ----------------------------------------------------------------

string BurRiteName(int nRiteType)
{
    if(nRiteType == BUR_RITE_SIMPLE)  return "Prosty Pochówek";
    if(nRiteType == BUR_RITE_HONORED) return "Zaszczytny Pochówek";
    if(nRiteType == BUR_RITE_CURSED)  return "Przeklęty Pochówek";
    return "Nieznany";
}

string BurRiteDesc(int nRiteType)
{
    if(nRiteType == BUR_RITE_SIMPLE)
        return "Duch odchodzi w spokoju. " +
               "Dostajesz regenerację HP +2 przez 1 godzinę.";
    if(nRiteType == BUR_RITE_HONORED)
        return IntToString(BUR_HONORED_COST) + " sz. Ryt godny wojownika. " +
               "Premia +1 do ataku przez 2 godziny.";
    if(nRiteType == BUR_RITE_CURSED)
        return "Duch zostaje uwięziony w grobie. " +
               "Klątwa czeka na tego, kto grób zbezcześci.";
    return "";
}

// ----------------------------------------------------------------
// Register view layout
// ----------------------------------------------------------------

json BurBuildRegisterView(object oPC)
{
    float fBtnH  = GetNuiScaleDimension(oPC, 30.0);
    float fRowH  = GetNuiScaleDimension(oPC, 26.0);
    float fListH = GetNuiScaleDimension(oPC, 280.0);
    float fInfoH = GetNuiScaleDimension(oPC, 80.0);

    // --- Top bar: title + Pogrzeb button ---
    json jTitle = NuiLabel(NuiBind(BUR_BIND_TITLE),
        JsonInt(NUI_HALIGN_LEFT), JsonInt(NUI_VALIGN_MIDDLE));
    jTitle = NuiHeight(jTitle, fBtnH);

    json jBuryBtn = NuiButton(JsonString("Pogrzeb"));
    jBuryBtn = NuiId(jBuryBtn, BUR_BTN_BURY_NEW);
    jBuryBtn = NuiWidth(jBuryBtn, GetNuiScaleDimension(oPC, 90.0));
    jBuryBtn = NuiHeight(jBuryBtn, fBtnH);

    json jTopItems = JsonArray();
    jTopItems = JsonArrayInsert(jTopItems, jTitle);
    jTopItems = JsonArrayInsert(jTopItems, NuiSpacer());
    jTopItems = JsonArrayInsert(jTopItems, jBuryBtn);

    // --- Grave list ---
    float fVicW  = GetNuiScaleDimension(oPC, 165.0);
    float fRiteW = GetNuiScaleDimension(oPC, 140.0);
    float fDateW = GetNuiScaleDimension(oPC, 55.0);
    float fStatW = GetNuiScaleDimension(oPC, 110.0);

    json jVicLbl = NuiLabel(NuiBind(BUR_BIND_ROW_VICTIM),
        JsonInt(NUI_HALIGN_LEFT), JsonInt(NUI_VALIGN_MIDDLE));
    json jRiteLbl = NuiLabel(NuiBind(BUR_BIND_ROW_RITE),
        JsonInt(NUI_HALIGN_LEFT), JsonInt(NUI_VALIGN_MIDDLE));
    json jDateLbl = NuiLabel(NuiBind(BUR_BIND_ROW_DATE),
        JsonInt(NUI_HALIGN_CENTER), JsonInt(NUI_VALIGN_MIDDLE));
    jDateLbl = NuiWidth(jDateLbl, fDateW);
    json jStatLbl = NuiLabel(NuiBind(BUR_BIND_ROW_STATUS),
        JsonInt(NUI_HALIGN_CENTER), JsonInt(NUI_VALIGN_MIDDLE));
    jStatLbl = NuiWidth(jStatLbl, fStatW);

    json jCellItems = JsonArray();
    jCellItems = JsonArrayInsert(jCellItems,
        NuiWidth(NuiCol(JsonArrayInsert(JsonArray(), jVicLbl)),  fVicW));
    jCellItems = JsonArrayInsert(jCellItems,
        NuiWidth(NuiCol(JsonArrayInsert(JsonArray(), jRiteLbl)), fRiteW));
    jCellItems = JsonArrayInsert(jCellItems, jDateLbl);
    jCellItems = JsonArrayInsert(jCellItems, jStatLbl);

    json jCell = NuiGroup(NuiRow(jCellItems), TRUE, NUI_SCROLLBARS_NONE);
    jCell = NuiId(jCell, BUR_BTN_ROW);
    jCell = NuiEncouraged(jCell, NuiBind(BUR_BIND_ROW_ENC));

    json jTmpl = JsonArrayInsert(JsonArray(), NuiListTemplateCell(jCell, 0.0, TRUE));
    json jList = NuiList(jTmpl, NuiBind(BUR_BIND_ROW_COUNT), fRowH);
    jList = NuiHeight(jList, fListH);

    // --- Info text for selected grave ---
    json jInfoGrp = NuiGroup(NuiText(NuiBind(BUR_BIND_INFO), FALSE),
        TRUE, NUI_SCROLLBARS_NONE);
    jInfoGrp = NuiHeight(jInfoGrp, fInfoH);

    // --- Bottom: Medytuj + Zbezcześć ---
    json jMedBtn = NuiButton(JsonString("Medytuj"));
    jMedBtn = NuiId(jMedBtn, BUR_BTN_MEDITATE);
    jMedBtn = NuiEnabled(jMedBtn, NuiBind(BUR_BIND_MEDITATE_ENA));
    jMedBtn = NuiWidth(jMedBtn, GetNuiScaleDimension(oPC, 110.0));
    jMedBtn = NuiHeight(jMedBtn, fBtnH);

    json jDesBtn = NuiButton(JsonString("Zbezcześć"));
    jDesBtn = NuiId(jDesBtn, BUR_BTN_DESECRATE);
    jDesBtn = NuiEnabled(jDesBtn, NuiBind(BUR_BIND_DESECRATE_ENA));
    jDesBtn = NuiWidth(jDesBtn, GetNuiScaleDimension(oPC, 110.0));
    jDesBtn = NuiHeight(jDesBtn, fBtnH);

    json jBotItems = JsonArray();
    jBotItems = JsonArrayInsert(jBotItems, jMedBtn);
    jBotItems = JsonArrayInsert(jBotItems, NuiSpacer());
    jBotItems = JsonArrayInsert(jBotItems, jDesBtn);

    // --- Assemble column ---
    json jCol = JsonArray();
    jCol = JsonArrayInsert(jCol, NuiRow(jTopItems));
    jCol = JsonArrayInsert(jCol, jList);
    jCol = JsonArrayInsert(jCol, jInfoGrp);
    jCol = JsonArrayInsert(jCol, NuiRow(jBotItems));

    json jSide = NuiCol(JsonArrayInsert(JsonArray(), NuiSpacer()));
    float fContentW = GetNuiScaleDimension(oPC, 640.0);
    json jMainItems = JsonArray();
    jMainItems = JsonArrayInsert(jMainItems, jSide);
    jMainItems = JsonArrayInsert(jMainItems,
        NuiWidth(NuiCol(jCol), fContentW));
    jMainItems = JsonArrayInsert(jMainItems, jSide);
    return NuiRow(jMainItems);
}

// ----------------------------------------------------------------
// Rite selection view layout
// ----------------------------------------------------------------

json BurBuildRiteView(object oPC)
{
    float fBtnH  = GetNuiScaleDimension(oPC, 50.0);
    float fDescH = GetNuiScaleDimension(oPC, 90.0);
    float fRiteW = GetNuiScaleDimension(oPC, 200.0);
    float fHdrH  = GetNuiScaleDimension(oPC, 40.0);
    float fCancelH = GetNuiScaleDimension(oPC, 30.0);

    // Victim header
    json jHeader = NuiLabel(NuiBind(BUR_BIND_VICTIM_NAME),
        JsonInt(NUI_HALIGN_CENTER), JsonInt(NUI_VALIGN_MIDDLE));
    jHeader = NuiHeight(jHeader, fHdrH);

    // Helper: one rite column (button + description)
    json jR0Btn = NuiButton(JsonString("Prosty Pochowek"));
    jR0Btn = NuiId(jR0Btn, BUR_BTN_RITE0);
    jR0Btn = NuiHeight(jR0Btn, fBtnH);
    json jR0Desc = NuiGroup(NuiText(NuiBind(BUR_BIND_RITE0_DESC), FALSE),
        TRUE, NUI_SCROLLBARS_NONE);
    jR0Desc = NuiHeight(jR0Desc, fDescH);
    json jR0Col = JsonArray();
    jR0Col = JsonArrayInsert(jR0Col, jR0Btn);
    jR0Col = JsonArrayInsert(jR0Col, jR0Desc);

    json jR1Btn = NuiButton(JsonString("Zaszczytny Pochowek"));
    jR1Btn = NuiId(jR1Btn, BUR_BTN_RITE1);
    jR1Btn = NuiHeight(jR1Btn, fBtnH);
    json jR1Desc = NuiGroup(NuiText(NuiBind(BUR_BIND_RITE1_DESC), FALSE),
        TRUE, NUI_SCROLLBARS_NONE);
    jR1Desc = NuiHeight(jR1Desc, fDescH);
    json jR1Col = JsonArray();
    jR1Col = JsonArrayInsert(jR1Col, jR1Btn);
    jR1Col = JsonArrayInsert(jR1Col, jR1Desc);

    json jR2Btn = NuiButton(JsonString("Przeklety Pochowek"));
    jR2Btn = NuiId(jR2Btn, BUR_BTN_RITE2);
    jR2Btn = NuiHeight(jR2Btn, fBtnH);
    json jR2Desc = NuiGroup(NuiText(NuiBind(BUR_BIND_RITE2_DESC), FALSE),
        TRUE, NUI_SCROLLBARS_NONE);
    jR2Desc = NuiHeight(jR2Desc, fDescH);
    json jR2Col = JsonArray();
    jR2Col = JsonArrayInsert(jR2Col, jR2Btn);
    jR2Col = JsonArrayInsert(jR2Col, jR2Desc);

    json jRiteItems = JsonArray();
    jRiteItems = JsonArrayInsert(jRiteItems,
        NuiWidth(NuiCol(jR0Col), fRiteW));
    jRiteItems = JsonArrayInsert(jRiteItems,
        NuiWidth(NuiCol(jR1Col), fRiteW));
    jRiteItems = JsonArrayInsert(jRiteItems,
        NuiWidth(NuiCol(jR2Col), fRiteW));

    // Cancel button
    json jCancelBtn = NuiButton(JsonString("Anuluj"));
    jCancelBtn = NuiId(jCancelBtn, BUR_BTN_CANCEL);
    jCancelBtn = NuiWidth(jCancelBtn, GetNuiScaleDimension(oPC, 100.0));
    jCancelBtn = NuiHeight(jCancelBtn, fCancelH);

    json jBotItems = JsonArray();
    jBotItems = JsonArrayInsert(jBotItems, NuiSpacer());
    jBotItems = JsonArrayInsert(jBotItems, jCancelBtn);
    jBotItems = JsonArrayInsert(jBotItems, NuiSpacer());

    json jCol = JsonArray();
    jCol = JsonArrayInsert(jCol, jHeader);
    jCol = JsonArrayInsert(jCol, NuiSpacer());
    jCol = JsonArrayInsert(jCol, NuiRow(jRiteItems));
    jCol = JsonArrayInsert(jCol, NuiSpacer());
    jCol = JsonArrayInsert(jCol, NuiRow(jBotItems));

    json jSide = NuiCol(JsonArrayInsert(JsonArray(), NuiSpacer()));
    float fContentW = GetNuiScaleDimension(oPC, 640.0);
    json jMainItems = JsonArray();
    jMainItems = JsonArrayInsert(jMainItems, jSide);
    jMainItems = JsonArrayInsert(jMainItems,
        NuiWidth(NuiCol(jCol), fContentW));
    jMainItems = JsonArrayInsert(jMainItems, jSide);
    return NuiRow(jMainItems);
}

// ----------------------------------------------------------------
// Window create / view swap
// ----------------------------------------------------------------

void BurCreateWindow(object oPC)
{
    if(NuiFindWindow(oPC, BUR_WIN) != 0)
    {
        BurSwapToRegister(oPC, NuiFindWindow(oPC, BUR_WIN));
        return;
    }

    float fCX = (IntToFloat(GetPlayerDeviceProperty(oPC,
        PLAYER_DEVICE_PROPERTY_GUI_WIDTH))  - GetNuiScaleDimension(oPC, BUR_W)) / 2.0;
    float fCY = (IntToFloat(GetPlayerDeviceProperty(oPC,
        PLAYER_DEVICE_PROPERTY_GUI_HEIGHT)) - GetNuiScaleDimension(oPC, BUR_H)) / 2.0;
    json jGeom = NuiRect(fCX, fCY,
        GetNuiScaleDimension(oPC, BUR_W),
        GetNuiScaleDimension(oPC, BUR_H));

    float fBtnH = GetNuiScaleDimension(oPC, 30.0);
    json jCloseBtn = NuiButton(JsonString("X"));
    jCloseBtn = NuiId(jCloseBtn, BUR_BTN_CLOSE);
    jCloseBtn = NuiWidth(jCloseBtn, GetNuiScaleDimension(oPC, 30.0));
    jCloseBtn = NuiHeight(jCloseBtn, fBtnH);
    json jTopBarItems = JsonArray();
    jTopBarItems = JsonArrayInsert(jTopBarItems, NuiSpacer());
    jTopBarItems = JsonArrayInsert(jTopBarItems, jCloseBtn);

    json jSwapGrp = NuiGroup(BurBuildRegisterView(oPC), FALSE, NUI_SCROLLBARS_NONE);
    jSwapGrp = NuiId(jSwapGrp, BUR_GRP_SWAP);

    json jRootChildren = JsonArray();
    jRootChildren = JsonArrayInsert(jRootChildren, NuiRow(jTopBarItems));
    jRootChildren = JsonArrayInsert(jRootChildren, jSwapGrp);
    json jRoot = NuiCol(jRootChildren);

    json jWin = NuiWindow(jRoot,
        JsonBool(FALSE),
        NuiBind(BUR_WIN_GEOM),
        JsonBool(FALSE), JsonBool(FALSE), JsonBool(FALSE),
        JsonBool(TRUE),  JsonBool(FALSE));

    int nToken = NuiCreate(oPC, jWin, BUR_WIN, BUR_EV_SCRIPT);
    NuiSetBind(oPC, nToken, BUR_WIN_GEOM, jGeom);
    BurSwapToRegister(oPC, nToken);
}

void BurOpenRiteView(object oPC, object oCorpse)
{
    SetLocalObject(oPC, BUR_LVAR_TARGET_OBJ,  oCorpse);
    SetLocalString(oPC, BUR_LVAR_VICTIM_NAME, GetName(oCorpse));

    if(NuiFindWindow(oPC, BUR_WIN) == 0)
        BurCreateWindow(oPC);

    BurSwapToRite(oPC, NuiFindWindow(oPC, BUR_WIN));
}

void BurSwapToRegister(object oPC, int nToken)
{
    NuiSetGroupLayout(oPC, nToken, BUR_GRP_SWAP, BurBuildRegisterView(oPC));
    SetLocalInt(oPC, BUR_LVAR_SEL_GRAVE, 0);
    BurFeedRegister(oPC, nToken);
}

void BurSwapToRite(object oPC, int nToken)
{
    NuiSetGroupLayout(oPC, nToken, BUR_GRP_SWAP, BurBuildRiteView(oPC));
    BurFeedRite(oPC, nToken);
}

// ----------------------------------------------------------------
// Feed — register
// ----------------------------------------------------------------

void BurFeedRegister(object oPC, int nToken)
{
    NuiSetBind(oPC, nToken, BUR_BIND_TITLE, JsonString("Rejestr Grobów"));

    json jGraves = BurGetMyGraves(oPC);
    int  nCount  = JsonGetLength(jGraves);

    json jVictims  = JsonArray();
    json jRites    = JsonArray();
    json jDates    = JsonArray();
    json jStatuses = JsonArray();
    json jEncs     = JsonArray();

    int nSelId = GetLocalInt(oPC, BUR_LVAR_SEL_GRAVE);
    int i;
    for(i = 0; i < nCount; i++)
    {
        json jRow    = JsonArrayGet(jGraves, i);
        int  nId     = JsonGetInt   (JsonObjectGet(jRow, "id"));
        string sVic  = JsonGetString(JsonObjectGet(jRow, "victim_name"));
        int nRite    = JsonGetInt   (JsonObjectGet(jRow, "rite_type"));
        int nBurAt   = JsonGetInt   (JsonObjectGet(jRow, "buried_at"));
        int nDes     = JsonGetInt   (JsonObjectGet(jRow, "desecrated"));

        jVictims  = JsonArrayInsert(jVictims,  JsonString(sVic));
        jRites    = JsonArrayInsert(jRites,    JsonString(BurRiteName(nRite)));
        jDates    = JsonArrayInsert(jDates,    JsonString(BurFormatDate(nBurAt)));
        jStatuses = JsonArrayInsert(jStatuses, JsonString(nDes ? "Zbezczeszczony" : "Nienaruszony"));
        jEncs     = JsonArrayInsert(jEncs,     JsonBool(nSelId > 0 && nId == nSelId));
    }

    NuiSetBind(oPC, nToken, BUR_BIND_ROW_VICTIM,  jVictims);
    NuiSetBind(oPC, nToken, BUR_BIND_ROW_RITE,    jRites);
    NuiSetBind(oPC, nToken, BUR_BIND_ROW_DATE,    jDates);
    NuiSetBind(oPC, nToken, BUR_BIND_ROW_STATUS,  jStatuses);
    NuiSetBind(oPC, nToken, BUR_BIND_ROW_ENC,     jEncs);
    NuiSetBind(oPC, nToken, BUR_BIND_ROW_COUNT,   JsonInt(nCount));

    int bSel = (nSelId > 0);
    NuiSetBind(oPC, nToken, BUR_BIND_MEDITATE_ENA,  JsonBool(bSel));
    NuiSetBind(oPC, nToken, BUR_BIND_DESECRATE_ENA, JsonBool(bSel));
    NuiSetBind(oPC, nToken, BUR_BIND_INFO,
        JsonString(nCount == 0
            ? "Nie pochowałeś jeszcze nikogo. Użyj przycisku [Pogrzeb]."
            : "Wybierz grób, by zobaczyć szczegóły."));
}

// ----------------------------------------------------------------
// Feed — rite selection
// ----------------------------------------------------------------

void BurFeedRite(object oPC, int nToken)
{
    string sVictim = GetLocalString(oPC, BUR_LVAR_VICTIM_NAME);
    NuiSetBind(oPC, nToken, BUR_BIND_VICTIM_NAME,
        JsonString("Pochówek: " + sVictim));
    NuiSetBind(oPC, nToken, BUR_BIND_RITE0_DESC,
        JsonString(BurRiteDesc(BUR_RITE_SIMPLE)));
    NuiSetBind(oPC, nToken, BUR_BIND_RITE1_DESC,
        JsonString(BurRiteDesc(BUR_RITE_HONORED)));
    NuiSetBind(oPC, nToken, BUR_BIND_RITE2_DESC,
        JsonString(BurRiteDesc(BUR_RITE_CURSED)));
}

// ----------------------------------------------------------------
// Desecration confirmation popup
// ----------------------------------------------------------------

void BurShowDesecrateConfirm(object oPC, int nGraveId)
{
    if(NuiFindWindow(oPC, BUR_WIN_DESECRATE) != 0)
        NuiDestroy(oPC, NuiFindWindow(oPC, BUR_WIN_DESECRATE));

    float fW = GetNuiScaleDimension(oPC, 380.0);
    float fH = GetNuiScaleDimension(oPC, 170.0);
    float fX = (IntToFloat(GetPlayerDeviceProperty(oPC,
        PLAYER_DEVICE_PROPERTY_GUI_WIDTH))  - fW) / 2.0;
    float fY = (IntToFloat(GetPlayerDeviceProperty(oPC,
        PLAYER_DEVICE_PROPERTY_GUI_HEIGHT)) - fH) / 2.0;

    float fBtnH = GetNuiScaleDimension(oPC, 30.0);
    json jMsg = NuiLabel(
        JsonString("Zbezcześcić grób?\nMożesz znaleźć złoto, lecz ryzykujesz klątwę."),
        JsonInt(NUI_HALIGN_CENTER), JsonInt(NUI_VALIGN_MIDDLE));

    json jYes = NuiButton(JsonString("Zbezcześć"));
    jYes = NuiId(jYes, BUR_BTN_DES_CONFIRM);
    jYes = NuiWidth(jYes, GetNuiScaleDimension(oPC, 110.0));
    jYes = NuiHeight(jYes, fBtnH);

    json jNo = NuiButton(JsonString("Anuluj"));
    jNo = NuiId(jNo, BUR_BTN_DES_CANCEL);
    jNo = NuiWidth(jNo, GetNuiScaleDimension(oPC, 90.0));
    jNo = NuiHeight(jNo, fBtnH);

    json jBtnItems = JsonArray();
    jBtnItems = JsonArrayInsert(jBtnItems, NuiSpacer());
    jBtnItems = JsonArrayInsert(jBtnItems, jYes);
    jBtnItems = JsonArrayInsert(jBtnItems, NuiSpacer());
    jBtnItems = JsonArrayInsert(jBtnItems, jNo);
    jBtnItems = JsonArrayInsert(jBtnItems, NuiSpacer());

    json jCol = JsonArray();
    jCol = JsonArrayInsert(jCol, NuiSpacer());
    jCol = JsonArrayInsert(jCol, jMsg);
    jCol = JsonArrayInsert(jCol, NuiSpacer());
    jCol = JsonArrayInsert(jCol, NuiRow(jBtnItems));
    jCol = JsonArrayInsert(jCol, NuiSpacer());

    json jWin = NuiWindow(NuiCol(jCol),
        JsonString("Profanacja Grobu"),
        NuiRect(fX, fY, fW, fH),
        JsonBool(FALSE), JsonBool(FALSE), JsonBool(TRUE),
        JsonBool(FALSE), JsonBool(TRUE));

    NuiCreate(oPC, jWin, BUR_WIN_DESECRATE, BUR_EV_SCRIPT);
}

// ----------------------------------------------------------------
// Game logic — applying burial rites
// ----------------------------------------------------------------

void BurApplyRite(object oPC, int nRiteType, object oCorpse)
{
    if(!GetIsObjectValid(oCorpse) || !GetIsDead(oCorpse))
    {
        SendMessageToPC(oPC, "[Pochówek] Ciało zniknęło lub ofiara wróciła do życia.");
        int nToken = NuiFindWindow(oPC, BUR_WIN);
        if(nToken != 0) BurSwapToRegister(oPC, nToken);
        return;
    }

    if(nRiteType == BUR_RITE_HONORED)
    {
        if(GetGold(oPC) < BUR_HONORED_COST)
        {
            SendMessageToPC(oPC,
                "[Pochówek] Brakuje ci " + IntToString(BUR_HONORED_COST) +
                " sz na zaszczytny ryt.");
            return;
        }
        AssignCommand(oPC, TakeGoldFromCreature(BUR_HONORED_COST, oPC, TRUE));
    }

    string sVictimName = GetName(oCorpse);
    BurInsertGrave(oPC, sVictimName, nRiteType);

    if(nRiteType == BUR_RITE_SIMPLE)
    {
        FloatingTextStringOnCreature("Duch odchodzi spokojnie...", oPC, FALSE);
        SendMessageToPC(oPC, "[Pochówek] Odmawiasz krótką modlitwę. Ziemia przyjmuje ciało.");
        effect eRegen = SupernaturalEffect(EffectRegenerate(2, 6.0));
        ApplyEffectToObject(DURATION_TYPE_TEMPORARY, eRegen, oPC, 3600.0);
    }
    else if(nRiteType == BUR_RITE_HONORED)
    {
        FloatingTextStringOnCreature("Wojownik odchodzi z honorem.", oPC, FALSE);
        SendMessageToPC(oPC,
            "[Pochówek] Zaszczytny pochówek. Złoto zamknęło powieki wojownika.");
        effect eAB = SupernaturalEffect(EffectAttackIncrease(1));
        ApplyEffectToObject(DURATION_TYPE_TEMPORARY, eAB, oPC, 7200.0);
    }
    else if(nRiteType == BUR_RITE_CURSED)
    {
        FloatingTextStringOnCreature("Pieczęć krwi pulsuje słabo...", oPC, FALSE);
        SendMessageToPC(oPC,
            "[Pochówek] Wymawiasz słowa pieczęci. Duch zostaje uwięziony.");
    }

    DestroyObject(oCorpse, 0.5);

    DeleteLocalObject(oPC, BUR_LVAR_TARGET_OBJ);
    DeleteLocalString(oPC, BUR_LVAR_VICTIM_NAME);

    int nToken = NuiFindWindow(oPC, BUR_WIN);
    if(nToken != 0)
        BurSwapToRegister(oPC, nToken);
}

// ----------------------------------------------------------------
// Game logic — meditation
// ----------------------------------------------------------------

void BurMeditate(object oPC, int nGraveId)
{
    json jGrave = BurGetGrave(nGraveId);
    if(JsonGetType(jGrave) == JSON_TYPE_NULL)
    {
        SendMessageToPC(oPC, "[Pochówek] Nie można znaleźć tego grobu w rejestrze.");
        return;
    }

    int nLastMed = BurGetLastMeditated(oPC, nGraveId);
    int nNow     = BurNow();

    if(nNow - nLastMed < BUR_MEDITATE_COOLDOWN)
    {
        int nHoursLeft = (BUR_MEDITATE_COOLDOWN - (nNow - nLastMed)) / 3600 + 1;
        SendMessageToPC(oPC,
            "[Pochówek] Medytowałeś już przy tym grobie. Wróć za około " +
            IntToString(nHoursLeft) + " godz.");
        return;
    }

    BurSetMeditated(oPC, nGraveId);

    int nRiteType  = JsonGetInt   (JsonObjectGet(jGrave, "rite_type"));
    int nDesecrated= JsonGetInt   (JsonObjectGet(jGrave, "desecrated"));
    string sVictim = JsonGetString(JsonObjectGet(jGrave, "victim_name"));

    if(nDesecrated)
    {
        SendMessageToPC(oPC,
            "[Pochówek] Grób jest zbezczeszczony. Nie ma tu czego szukać.");
        return;
    }

    // Cursed grave punishes meditation
    if(nRiteType == BUR_RITE_CURSED)
    {
        FloatingTextStringOnCreature("Pieczęć krwi dręczy cię...", oPC, FALSE);
        SendMessageToPC(oPC,
            "[Pochówek] Uwięziony duch burzy spokój. Twój umysł pęka.");
        effect ePen = SupernaturalEffect(EffectSavingThrowDecrease(SAVING_THROW_ALL, 1));
        ApplyEffectToObject(DURATION_TYPE_TEMPORARY, ePen, oPC, 1800.0);
        return;
    }

    FloatingTextStringOnCreature("Refleksja przy grobie...", oPC, FALSE);
    SendMessageToPC(oPC,
        "[Pochówek] Oddajesz hołd " + sVictim + ". Spokój przenika twój umysł.");

    if(nRiteType == BUR_RITE_SIMPLE)
    {
        GiveXPToCreature(oPC, BUR_SIMPLE_XP);
        SendMessageToPC(oPC, "[Pochówek] Zyskujesz " + IntToString(BUR_SIMPLE_XP) + " PD.");
    }
    else if(nRiteType == BUR_RITE_HONORED)
    {
        GiveXPToCreature(oPC, BUR_HONORED_XP);
        effect eSave = SupernaturalEffect(EffectSavingThrowIncrease(SAVING_THROW_ALL, 1));
        ApplyEffectToObject(DURATION_TYPE_TEMPORARY, eSave, oPC, 3600.0);
        SendMessageToPC(oPC,
            "[Pochówek] Zyskujesz " + IntToString(BUR_HONORED_XP) +
            " PD oraz +1 do rzutów obronnych na 1 godz.");
    }
}

// ----------------------------------------------------------------
// Game logic — desecration
// ----------------------------------------------------------------

void BurDesecrate(object oPC, int nGraveId)
{
    json jGrave = BurGetGrave(nGraveId);
    if(JsonGetType(jGrave) == JSON_TYPE_NULL)
    {
        SendMessageToPC(oPC, "[Pochówek] Grób nie istnieje.");
        return;
    }

    int nDesecrated = JsonGetInt(JsonObjectGet(jGrave, "desecrated"));
    if(nDesecrated)
    {
        SendMessageToPC(oPC,
            "[Pochówek] Ten grób jest już zbezczeszczony. Nic tu nie zostało.");
        return;
    }

    BurMarkDesecrated(nGraveId);

    int nRiteType  = JsonGetInt   (JsonObjectGet(jGrave, "rite_type"));
    string sVictim = JsonGetString(JsonObjectGet(jGrave, "victim_name"));

    int nGold = BUR_DESECRATE_GOLD_MIN +
                Random(BUR_DESECRATE_GOLD_MAX - BUR_DESECRATE_GOLD_MIN + 1);

    FloatingTextStringOnCreature("Profanacja grobu...", oPC, FALSE);

    if(nRiteType == BUR_RITE_CURSED)
    {
        // Cursed grave retaliates hard
        SendMessageToPC(oPC,
            "[Pochówek] Pieczęć krwi wybucha! Duch obdarza cię złotem i klątwą.");
        GiveGoldToCreature(oPC, nGold);
        SendMessageToPC(oPC, "[Pochówek] Otrzymujesz " + IntToString(nGold) + " sz.");
        effect eCurse = SupernaturalEffect(EffectCurse(2, 2, 2, 2, 2, 2));
        ApplyEffectToObject(DURATION_TYPE_TEMPORARY, eCurse, oPC, 7200.0);
        SendMessageToPC(oPC,
            "[Pochówek] Klątwa dręczy cię — wszystkie cechy -2 przez 2 godziny.");
    }
    else if(nRiteType == BUR_RITE_HONORED)
    {
        // Honored gives bonus gold but minor AB penalty
        int nBonusGold = nGold + 50;
        GiveGoldToCreature(oPC, nBonusGold);
        SendMessageToPC(oPC,
            "[Pochówek] Zbezczeszczasz grób " + sVictim + ". Znajdujesz " +
            IntToString(nBonusGold) + " sz.");
        effect ePen = SupernaturalEffect(EffectAttackDecrease(1));
        ApplyEffectToObject(DURATION_TYPE_TEMPORARY, ePen, oPC, 3600.0);
        SendMessageToPC(oPC,
            "[Pochówek] Duch wojownika karze cię za hańbę: -1 do ataku na 1 godz.");
    }
    else
    {
        GiveGoldToCreature(oPC, nGold);
        SendMessageToPC(oPC,
            "[Pochówek] Zbezczeszczasz grób " + sVictim + ". Znajdujesz " +
            IntToString(nGold) + " sz.");
    }

    int nToken = NuiFindWindow(oPC, BUR_WIN);
    if(nToken != 0)
        BurFeedRegister(oPC, nToken);
}

// ----------------------------------------------------------------
// Targeting handler (called from sys_on_target.nss)
// ----------------------------------------------------------------

void BurOnPlayerTarget(object oPC)
{
    if(!GetLocalInt(oPC, BUR_LVAR_TARGETING)) return;
    DeleteLocalInt(oPC, BUR_LVAR_TARGETING);

    object oTarget = GetTargetingModeSelectedObject();

    if(!GetIsObjectValid(oTarget))
    {
        SendMessageToPC(oPC, "[Pochówek] Anulowano wybór.");
        return;
    }

    if(!GetIsDead(oTarget))
    {
        SendMessageToPC(oPC, "[Pochówek] Możesz pochować tylko poległych wrogów.");
        return;
    }

    if(GetIsPC(oTarget))
    {
        SendMessageToPC(oPC, "[Pochówek] Nie możesz pochować innego gracza.");
        return;
    }

    BurOpenRiteView(oPC, oTarget);
}
