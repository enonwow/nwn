// lib_inq.nss - Inquisition: core logic, effect application, NUI layout

#include "lib_inq_def"

// ============================================================
// Effect management
// ============================================================

void InqRemoveRatingEffects(object oPC)
{
    effect eEff = GetFirstEffect(oPC);
    while(GetIsEffectValid(eEff))
    {
        string sTag = GetEffectTag(eEff);
        if(sTag == INQ_EFFECT_TAG_ACCUSED ||
           sTag == INQ_EFFECT_TAG_CONVICT ||
           sTag == INQ_EFFECT_TAG_CONDEMN)
        {
            RemoveEffect(oPC, eEff);
        }
        eEff = GetNextEffect(oPC);
    }
}

// Strips old effects then re-applies effects matching current rating tier.
void InqApplyRatingEffects(object oPC, int nRating)
{
    InqRemoveRatingEffects(oPC);

    if(nRating < INQ_THRESHOLD_ACCUSED)
        return;

    effect eSet;
    string sTag;

    if(nRating < INQ_THRESHOLD_CONVICTED)
    {
        sTag = INQ_EFFECT_TAG_ACCUSED;
        eSet = TagEffect(
            ExtraordinaryEffect(EffectAbilityDecrease(ABILITY_CHARISMA, 2)),
            sTag);
    }
    else if(nRating < INQ_THRESHOLD_CONDEMNED)
    {
        sTag = INQ_EFFECT_TAG_CONVICT;
        effect eCha = TagEffect(EffectAbilityDecrease(ABILITY_CHARISMA, 2), sTag);
        effect eAC  = TagEffect(EffectACDecrease(1),                        sTag);
        eSet = ExtraordinaryEffect(EffectLinkEffects(eCha, eAC));
    }
    else
    {
        sTag = INQ_EFFECT_TAG_CONDEMN;
        effect eCha  = TagEffect(EffectAbilityDecrease(ABILITY_CHARISMA, 4),        sTag);
        effect eAC   = TagEffect(EffectACDecrease(2),                               sTag);
        effect eSave = TagEffect(EffectSavingThrowDecrease(SAVING_THROW_ALL, 2),    sTag);
        eSet = ExtraordinaryEffect(EffectLinkEffects(eCha, EffectLinkEffects(eAC, eSave)));
    }

    ApplyEffectToObject(DURATION_TYPE_PERMANENT, eSet, oPC);
}

// ============================================================
// Public API: add a charge against a PC
// ============================================================

void InqAddCharge(object oPC, int nActId)
{
    if(!GetIsPC(oPC) || GetIsDMPossessed(oPC)) return;

    string sPcUuid = GetObjectUUID(oPC);
    string sPcName = GetName(oPC);
    int    nWeight = InqGetActWeight(nActId);

    int nOldRating = InqGetRating(sPcUuid);
    int nNewRating = InqInsertCharge(sPcUuid, sPcName, nActId, nWeight);

    InqApplyRatingEffects(oPC, nNewRating);

    if(nOldRating < INQ_THRESHOLD_ACCUSED && nNewRating >= INQ_THRESHOLD_ACCUSED)
        FloatingTextStringOnCreature(
            "Inkwizycja wydała nakaz twojego aresztowania. Uważaj.", oPC, FALSE);
    else if(nOldRating < INQ_THRESHOLD_CONVICTED && nNewRating >= INQ_THRESHOLD_CONVICTED)
        FloatingTextStringOnCreature(
            "Pieczęć heretyka wypala twoją skórę. Zostałeś skazany.", oPC, FALSE);
    else if(nOldRating < INQ_THRESHOLD_CONDEMNED && nNewRating >= INQ_THRESHOLD_CONDEMNED)
        FloatingTextStringOnCreature(
            "Jesteś wyklęty przez Inkwizycję. Polują na ciebie.", oPC, FALSE);
    else if(nOldRating < INQ_THRESHOLD_SUSPECT && nNewRating >= INQ_THRESHOLD_SUSPECT)
        FloatingTextStringOnCreature(
            "Inkwizycja odnotowała twój czyn. Jesteś obserwowany.", oPC, FALSE);

    int nToken = NuiFindWindow(oPC, INQ_WINDOW_DOSSIER);
    if(nToken) InqFeedDossier(oPC, nToken);
}

// ============================================================
// NUI layout — dossier charge row (fixed-count, visibility-toggled)
// ============================================================

json InqChargeRow(object oPC, int nIdx)
{
    float fH    = GetNuiScaleDimension(oPC, 26.0);
    float fValW = GetNuiScaleDimension(oPC, 60.0);

    json jName = NuiLabel(
        NuiBind(INQ_BIND_CHARGE_NAME + IntToString(nIdx)),
        JsonInt(NUI_HALIGN_LEFT),
        JsonInt(NUI_VALIGN_MIDDLE));
    jName = NuiHeight(jName, fH);

    json jVal = NuiLabel(
        NuiBind(INQ_BIND_CHARGE_TOTAL + IntToString(nIdx)),
        JsonInt(NUI_HALIGN_RIGHT),
        JsonInt(NUI_VALIGN_MIDDLE));
    jVal = NuiWidth(jVal, fValW);
    jVal = NuiHeight(jVal, fH);

    json jChildren = JsonArray();
    jChildren = JsonArrayInsert(jChildren, jName);
    jChildren = JsonArrayInsert(jChildren, jVal);

    json jRow = NuiRow(jChildren);
    jRow = NuiVisible(jRow, NuiBind(INQ_BIND_CHARGE_VIS + IntToString(nIdx)));
    jRow = NuiHeight(jRow, fH);
    return jRow;
}

// ============================================================
// NUI layout — dossier window
// ============================================================

json InqBuildDossierLayout(object oPC)
{
    float fBtnH  = GetNuiScaleDimension(oPC, 32.0);
    float fLblH  = GetNuiScaleDimension(oPC, 28.0);
    float fMtrH  = GetNuiScaleDimension(oPC, 22.0);
    float fFlvH  = GetNuiScaleDimension(oPC, 60.0);
    float fBtnW  = GetNuiScaleDimension(oPC, 150.0);
    float fRatW  = GetNuiScaleDimension(oPC, 65.0);

    // Header: title + close button
    json jTitle = NuiLabel(JsonString("Dossier Inkwizycji"),
        JsonInt(NUI_HALIGN_LEFT), JsonInt(NUI_VALIGN_MIDDLE));
    jTitle = NuiHeight(jTitle, fBtnH);

    json jClose = NuiButton(JsonString("X"));
    jClose = NuiId(jClose, INQ_BTN_CLOSE);
    jClose = NuiWidth(jClose, GetNuiScaleDimension(oPC, 30.0));
    jClose = NuiHeight(jClose, fBtnH);

    json jHdr = JsonArray();
    jHdr = JsonArrayInsert(jHdr, jTitle);
    jHdr = JsonArrayInsert(jHdr, jClose);
    json jHeader = NuiRow(jHdr);
    jHeader = NuiHeight(jHeader, fBtnH);

    // Status label
    json jStatusLbl = NuiLabel(NuiBind(INQ_BIND_STATUS_LBL),
        JsonInt(NUI_HALIGN_CENTER), JsonInt(NUI_VALIGN_MIDDLE));
    jStatusLbl = NuiStyleForegroundColor(jStatusLbl, NuiBind(INQ_BIND_STATUS_COLOR));
    jStatusLbl = NuiHeight(jStatusLbl, fLblH);

    // Rating meter + text
    json jMeter = NuiProgress(NuiBind(INQ_BIND_METER_VAL));
    jMeter = NuiHeight(jMeter, fMtrH);

    json jRatLbl = NuiLabel(NuiBind(INQ_BIND_RATING_TXT),
        JsonInt(NUI_HALIGN_RIGHT), JsonInt(NUI_VALIGN_MIDDLE));
    jRatLbl = NuiWidth(jRatLbl, fRatW);
    jRatLbl = NuiHeight(jRatLbl, fMtrH);

    json jMeterRow = JsonArray();
    jMeterRow = JsonArrayInsert(jMeterRow, jMeter);
    jMeterRow = JsonArrayInsert(jMeterRow, jRatLbl);
    json jMRow = NuiRow(jMeterRow);
    jMRow = NuiHeight(jMRow, fMtrH);

    // Charges section heading
    json jChrgHdr = NuiLabel(JsonString("Zarzuty:"),
        JsonInt(NUI_HALIGN_LEFT), JsonInt(NUI_VALIGN_MIDDLE));
    jChrgHdr = NuiHeight(jChrgHdr, fLblH);

    // Charge rows
    json jChrgRows = JsonArray();
    int i;
    for(i = 0; i < INQ_ACT_COUNT; i++)
        jChrgRows = JsonArrayInsert(jChrgRows, InqChargeRow(oPC, i));
    json jChrgGroup = NuiCol(jChrgRows);

    // Flavor text (multi-line)
    json jFlavor = NuiLabel(NuiBind(INQ_BIND_FLAVOR_TXT),
        JsonInt(NUI_HALIGN_LEFT), JsonInt(NUI_VALIGN_TOP));
    jFlavor = NuiHeight(jFlavor, fFlvH);

    // Action buttons
    json jConfess = NuiButton(JsonString("Wyznaj grzechy"));
    jConfess = NuiId(jConfess, INQ_BTN_CONFESS);
    jConfess = NuiEnabled(jConfess, NuiBind(INQ_BIND_CONFESS_ENA));
    jConfess = NuiWidth(jConfess, fBtnW);
    jConfess = NuiHeight(jConfess, fBtnH);
    jConfess = NuiTooltip(jConfess, JsonString(
        "Wyznaj winy kapłanowi za złoto. Redukuje ocenę o "
        + IntToString(INQ_CONFESS_REDUCTION) + " punktów."));

    json jRecant = NuiButton(JsonString("Odwołaj publicznie"));
    jRecant = NuiId(jRecant, INQ_BTN_RECANT);
    jRecant = NuiEnabled(jRecant, NuiBind(INQ_BIND_RECANT_ENA));
    jRecant = NuiWidth(jRecant, fBtnW);
    jRecant = NuiHeight(jRecant, fBtnH);
    jRecant = NuiTooltip(jRecant, JsonString(
        "Publiczne odwołanie. Większa redukcja (" + IntToString(INQ_RECANT_REDUCTION)
        + " pkt), lecz dozwolone raz na godzinę."));

    json jBtnRow = JsonArray();
    jBtnRow = JsonArrayInsert(jBtnRow, jConfess);
    jBtnRow = JsonArrayInsert(jBtnRow, jRecant);
    json jButtons = NuiRow(jBtnRow);
    jButtons = NuiHeight(jButtons, fBtnH);

    // Assemble root column
    json jCol = JsonArray();
    jCol = JsonArrayInsert(jCol, jHeader);
    jCol = JsonArrayInsert(jCol, jStatusLbl);
    jCol = JsonArrayInsert(jCol, jMRow);
    jCol = JsonArrayInsert(jCol, NuiSpacer());
    jCol = JsonArrayInsert(jCol, jChrgHdr);
    jCol = JsonArrayInsert(jCol, jChrgGroup);
    jCol = JsonArrayInsert(jCol, NuiSpacer());
    jCol = JsonArrayInsert(jCol, jFlavor);
    jCol = JsonArrayInsert(jCol, NuiSpacer());
    jCol = JsonArrayInsert(jCol, jButtons);

    return NuiCol(jCol);
}

// ============================================================
// Dossier window: open + feed
// ============================================================

void InqOpenDossierWindow(object oPC)
{
    int nToken = NuiFindWindow(oPC, INQ_WINDOW_DOSSIER);
    if(!nToken)
    {
        json jWin = NuiWindow(
            InqBuildDossierLayout(oPC),
            JsonString("Dossier Inkwizycji"),
            NuiBind(INQ_WIN_GEOM),
            JsonBool(FALSE),
            JsonBool(FALSE),
            JsonBool(TRUE),
            JsonBool(FALSE),
            JsonBool(TRUE));
        nToken = NuiCreate(oPC, jWin, INQ_WINDOW_DOSSIER, INQ_EV_SCRIPT);
    }

    SetLocalInt(oPC, INQ_LVAR_TOKEN, nToken);
    InqFeedDossier(oPC, nToken);
}

void InqFeedDossier(object oPC, int nToken)
{
    string sPcUuid = GetObjectUUID(oPC);
    int    nRating = InqGetRating(sPcUuid);

    NuiSetBind(oPC, nToken, INQ_BIND_STATUS_LBL,   JsonString(InqGetStatusLabel(nRating)));
    NuiSetBind(oPC, nToken, INQ_BIND_STATUS_COLOR,  InqGetStatusColor(nRating));
    NuiSetBind(oPC, nToken, INQ_BIND_RATING_TXT,
        JsonString(IntToString(nRating) + " / " + IntToString(INQ_RATING_MAX)));
    NuiSetBind(oPC, nToken, INQ_BIND_METER_VAL,
        JsonFloat(IntToFloat(nRating) / IntToFloat(INQ_RATING_MAX)));
    NuiSetBind(oPC, nToken, INQ_BIND_FLAVOR_TXT, JsonString(InqGetStatusFlavor(nRating)));

    int bHasCharges = (nRating > 0);
    NuiSetBind(oPC, nToken, INQ_BIND_CONFESS_ENA, JsonBool(bHasCharges));
    NuiSetBind(oPC, nToken, INQ_BIND_RECANT_ENA,  JsonBool(bHasCharges));

    json jCharges = InqGetChargesSummary(sPcUuid);
    int  nCount   = JsonGetLength(jCharges);
    int i;
    for(i = 0; i < INQ_ACT_COUNT; i++)
    {
        int bVis = (i < nCount);
        NuiSetBind(oPC, nToken, INQ_BIND_CHARGE_VIS + IntToString(i), JsonBool(bVis));
        if(bVis)
        {
            json jEntry = JsonArrayGet(jCharges, i);
            int  nActId = JsonGetInt(JsonObjectGet(jEntry, "act_id"));
            int  nTotal = JsonGetInt(JsonObjectGet(jEntry, "total_weight"));
            int  nCnt   = JsonGetInt(JsonObjectGet(jEntry, "count"));

            string sName = InqGetActName(nActId);
            if(nCnt > 1) sName += " (x" + IntToString(nCnt) + ")";

            NuiSetBind(oPC, nToken, INQ_BIND_CHARGE_NAME  + IntToString(i), JsonString(sName));
            NuiSetBind(oPC, nToken, INQ_BIND_CHARGE_TOTAL + IntToString(i),
                JsonString("+" + IntToString(nTotal)));
        }
    }
}

// ============================================================
// Confession handler
// ============================================================

void InqHandleConfess(object oPC, int nToken)
{
    string sPcUuid = GetObjectUUID(oPC);
    string sPcName = GetName(oPC);
    int    nRating = InqGetRating(sPcUuid);

    if(nRating <= 0)
    {
        SendMessageToPC(oPC, "[Inkwizycja] Nie masz nic do wyznania.");
        return;
    }

    int nGoldCost = (nRating / 10 + 1) * INQ_CONFESS_GOLD_PER_10;
    if(GetGold(oPC) < nGoldCost)
    {
        SendMessageToPC(oPC, "[Inkwizycja] Spowiedź kosztuje "
            + IntToString(nGoldCost) + " szt. złota. Brakuje ci funduszy.");
        return;
    }

    AssignCommand(oPC, TakeGoldFromCreature(nGoldCost, oPC, TRUE));

    int nNewRating = InqReduceRating(sPcUuid, sPcName, INQ_CONFESS_REDUCTION);
    InqApplyRatingEffects(oPC, nNewRating);

    SendMessageToPC(oPC, "[Inkwizycja] Spowiedź wysłuchana. Zapłacono "
        + IntToString(nGoldCost) + " zł. Nowa ocena: " + IntToString(nNewRating) + ".");
    FloatingTextStringOnCreature(
        "Kapłan Inkwizycji przyjął twoją spowiedź.", oPC, FALSE);

    InqFeedDossier(oPC, nToken);
}

// ============================================================
// Recantation handler (once per in-game hour)
// ============================================================

void InqHandleRecant(object oPC, int nToken)
{
    string sPcUuid = GetObjectUUID(oPC);
    string sPcName = GetName(oPC);

    string sLastKey = "INQ_RECANT_" + sPcUuid;
    int    nLastT   = GetLocalInt(GetModule(), sLastKey);
    int    nNow     = FloatToInt(GetGameTime());

    if(nLastT > 0 && (nNow - nLastT) < 3600)
    {
        SendMessageToPC(oPC, "[Inkwizycja] Odwołanie publiczne możliwe raz na godzinę.");
        return;
    }

    int nRating = InqGetRating(sPcUuid);
    if(nRating <= 0)
    {
        SendMessageToPC(oPC, "[Inkwizycja] Nie masz przed czym się odwoływać.");
        return;
    }

    SetLocalInt(GetModule(), sLastKey, nNow);

    int nNewRating = InqReduceRating(sPcUuid, sPcName, INQ_RECANT_REDUCTION);
    InqApplyRatingEffects(oPC, nNewRating);

    // Broadcast recantation to all PCs in the same area
    string sMsg = GetName(oPC) + " publicznie odwołuje wszelkie czyny heretyckie!";
    object oOther = GetFirstPC();
    while(GetIsObjectValid(oOther))
    {
        if(GetArea(oOther) == GetArea(oPC))
            SendMessageToPC(oOther, "[Inkwizycja] " + sMsg);
        oOther = GetNextPC();
    }

    SendMessageToPC(oPC, "[Inkwizycja] Odwołanie ogłoszone. Nowa ocena: "
        + IntToString(nNewRating) + ".");
    InqFeedDossier(oPC, nToken);
}

// ============================================================
// DM window layout — suspect list template
// ============================================================

json InqBuildDmListTemplate(object oDM)
{
    float fNameW   = GetNuiScaleDimension(oDM, 175.0);
    float fRatW    = GetNuiScaleDimension(oDM, 52.0);
    float fStatW   = GetNuiScaleDimension(oDM, 155.0);
    float fBtnW    = GetNuiScaleDimension(oDM, 70.0);
    float fRowH    = GetNuiScaleDimension(oDM, 28.0);

    json jName = NuiLabel(NuiBind(INQ_BIND_DM_LIST_NAME),
        JsonInt(NUI_HALIGN_LEFT), JsonInt(NUI_VALIGN_MIDDLE));
    jName = NuiWidth(jName, fNameW);
    jName = NuiHeight(jName, fRowH);

    json jRat = NuiLabel(NuiBind(INQ_BIND_DM_LIST_RATING),
        JsonInt(NUI_HALIGN_CENTER), JsonInt(NUI_VALIGN_MIDDLE));
    jRat = NuiWidth(jRat, fRatW);
    jRat = NuiHeight(jRat, fRowH);

    json jStat = NuiLabel(NuiBind(INQ_BIND_DM_LIST_STATUS),
        JsonInt(NUI_HALIGN_LEFT), JsonInt(NUI_VALIGN_MIDDLE));
    jStat = NuiWidth(jStat, fStatW);
    jStat = NuiHeight(jStat, fRowH);

    json jBtn = NuiButton(JsonString("Wybierz"));
    jBtn = NuiId(jBtn, INQ_BTN_DM_ROW);
    jBtn = NuiWidth(jBtn, fBtnW);
    jBtn = NuiHeight(jBtn, fRowH);

    json jCells = JsonArray();
    jCells = JsonArrayInsert(jCells, jName);
    jCells = JsonArrayInsert(jCells, jRat);
    jCells = JsonArrayInsert(jCells, jStat);
    jCells = JsonArrayInsert(jCells, jBtn);
    json jRow = NuiRow(jCells);
    jRow = NuiEncouraged(jRow, NuiBind(INQ_BIND_DM_LIST_ENC));
    jRow = NuiHeight(jRow, fRowH);

    return JsonArrayInsert(JsonArray(), NuiListTemplateCell(jRow, 0.0, TRUE));
}

json InqBuildDmLayout(object oDM)
{
    float fBtnH  = GetNuiScaleDimension(oDM, 32.0);
    float fLblH  = GetNuiScaleDimension(oDM, 26.0);
    float fListH = GetNuiScaleDimension(oDM, 220.0);
    float fRowH  = GetNuiScaleDimension(oDM, 28.0);
    float fBtnW  = GetNuiScaleDimension(oDM, 120.0);

    // Header
    json jTitle = NuiLabel(JsonString("Rejestr Inkwizycji"),
        JsonInt(NUI_HALIGN_LEFT), JsonInt(NUI_VALIGN_MIDDLE));
    jTitle = NuiHeight(jTitle, fBtnH);

    json jClose = NuiButton(JsonString("X"));
    jClose = NuiId(jClose, INQ_BTN_DM_CLOSE);
    jClose = NuiWidth(jClose, GetNuiScaleDimension(oDM, 30.0));
    jClose = NuiHeight(jClose, fBtnH);

    json jHdrRow = JsonArray();
    jHdrRow = JsonArrayInsert(jHdrRow, jTitle);
    jHdrRow = JsonArrayInsert(jHdrRow, jClose);
    json jHeader = NuiRow(jHdrRow);
    jHeader = NuiHeight(jHeader, fBtnH);

    // Column header labels
    json jColHdr = NuiLabel(JsonString("Imię                        Ocena  Status"),
        JsonInt(NUI_HALIGN_LEFT), JsonInt(NUI_VALIGN_MIDDLE));
    jColHdr = NuiHeight(jColHdr, fLblH);

    // Suspect list
    json jList = NuiList(InqBuildDmListTemplate(oDM), NuiBind(INQ_BIND_DM_LIST_COUNT), fRowH);
    jList = NuiHeight(jList, fListH);

    // Selected suspect detail
    json jDetail = NuiLabel(NuiBind(INQ_BIND_DM_DETAIL_LBL),
        JsonInt(NUI_HALIGN_LEFT), JsonInt(NUI_VALIGN_MIDDLE));
    jDetail = NuiHeight(jDetail, fLblH);

    // Action buttons
    json jAdd = NuiButton(JsonString("Dodaj zarzut"));
    jAdd = NuiId(jAdd, INQ_BTN_DM_ADD_ACT);
    jAdd = NuiWidth(jAdd, fBtnW);
    jAdd = NuiHeight(jAdd, fBtnH);

    json jPardon = NuiButton(JsonString("Ułaskaw"));
    jPardon = NuiId(jPardon, INQ_BTN_DM_PARDON);
    jPardon = NuiWidth(jPardon, fBtnW);
    jPardon = NuiHeight(jPardon, fBtnH);

    json jClear = NuiButton(JsonString("Wyczyść zarzuty"));
    jClear = NuiId(jClear, INQ_BTN_DM_CLEAR);
    jClear = NuiWidth(jClear, fBtnW);
    jClear = NuiHeight(jClear, fBtnH);

    json jActBtns = JsonArray();
    jActBtns = JsonArrayInsert(jActBtns, jAdd);
    jActBtns = JsonArrayInsert(jActBtns, jPardon);
    jActBtns = JsonArrayInsert(jActBtns, jClear);
    json jBtnsRow = NuiRow(jActBtns);
    jBtnsRow = NuiHeight(jBtnsRow, fBtnH);

    json jCol = JsonArray();
    jCol = JsonArrayInsert(jCol, jHeader);
    jCol = JsonArrayInsert(jCol, NuiSpacer());
    jCol = JsonArrayInsert(jCol, jColHdr);
    jCol = JsonArrayInsert(jCol, jList);
    jCol = JsonArrayInsert(jCol, NuiSpacer());
    jCol = JsonArrayInsert(jCol, jDetail);
    jCol = JsonArrayInsert(jCol, jBtnsRow);

    return NuiCol(jCol);
}

// ============================================================
// DM window: open + feed
// ============================================================

void InqOpenDmWindow(object oDM)
{
    int nToken = NuiFindWindow(oDM, INQ_WINDOW_DM);
    if(!nToken)
    {
        json jWin = NuiWindow(
            InqBuildDmLayout(oDM),
            JsonString("Rejestr Inkwizycji [DM]"),
            NuiBind(INQ_WIN_GEOM),
            JsonBool(FALSE),
            JsonBool(FALSE),
            JsonBool(TRUE),
            JsonBool(FALSE),
            JsonBool(TRUE));
        nToken = NuiCreate(oDM, jWin, INQ_WINDOW_DM, INQ_EV_SCRIPT);
    }

    SetLocalInt(oDM, INQ_LVAR_DM_TOKEN, nToken);
    InqFeedDmPanel(oDM, nToken);
}

void InqFeedDmPanel(object oDM, int nToken)
{
    json jSuspects = InqGetAllSuspects();
    int  nCount    = JsonGetLength(jSuspects);

    json jNames   = JsonArray();
    json jRatings = JsonArray();
    json jStats   = JsonArray();
    json jEncs    = JsonArray();

    string sSelUuid = GetLocalString(oDM, INQ_LVAR_DM_SEL_UUID);
    int i;
    for(i = 0; i < nCount; i++)
    {
        json   jRow  = JsonArrayGet(jSuspects, i);
        string sUuid = JsonGetString(JsonObjectGet(jRow, "uuid"));
        string sName = JsonGetString(JsonObjectGet(jRow, "name"));
        int    nRat  = JsonGetInt   (JsonObjectGet(jRow, "rating"));

        jNames   = JsonArrayInsert(jNames,   JsonString(sName));
        jRatings = JsonArrayInsert(jRatings, JsonString(IntToString(nRat)));
        jStats   = JsonArrayInsert(jStats,   JsonString(InqGetStatusLabel(nRat)));
        jEncs    = JsonArrayInsert(jEncs,    JsonBool(sUuid == sSelUuid));
    }

    NuiSetBind(oDM, nToken, INQ_BIND_DM_LIST_COUNT,  JsonInt(nCount));
    NuiSetBind(oDM, nToken, INQ_BIND_DM_LIST_NAME,   jNames);
    NuiSetBind(oDM, nToken, INQ_BIND_DM_LIST_RATING, jRatings);
    NuiSetBind(oDM, nToken, INQ_BIND_DM_LIST_STATUS, jStats);
    NuiSetBind(oDM, nToken, INQ_BIND_DM_LIST_ENC,    jEncs);

    string sSelName = GetLocalString(oDM, INQ_LVAR_DM_SEL_NAME);
    if(sSelName == "" || sSelUuid == "")
        NuiSetBind(oDM, nToken, INQ_BIND_DM_DETAIL_LBL, JsonString("Wybierz postać z listy."));
    else
    {
        int nRat = InqGetRating(sSelUuid);
        NuiSetBind(oDM, nToken, INQ_BIND_DM_DETAIL_LBL,
            JsonString("Wybrany: " + sSelName + "  |  Ocena: " + IntToString(nRat)
                + "  |  " + InqGetStatusLabel(nRat)));
    }
}

// ============================================================
// Act picker popup (DM selects which heretical act to apply)
// ============================================================

json InqBuildActPickerLayout(object oDM)
{
    float fBtnH = GetNuiScaleDimension(oDM, 32.0);
    float fBtnW = GetNuiScaleDimension(oDM, 290.0);
    float fLblH = GetNuiScaleDimension(oDM, 28.0);

    json jTitleRow = JsonArray();
    json jTitleLbl = NuiLabel(JsonString("Wybierz zarzut do dodania:"),
        JsonInt(NUI_HALIGN_LEFT), JsonInt(NUI_VALIGN_MIDDLE));
    jTitleLbl = NuiHeight(jTitleLbl, fLblH);
    jTitleRow = JsonArrayInsert(jTitleRow, jTitleLbl);

    json jCol = JsonArray();
    jCol = JsonArrayInsert(jCol, NuiRow(jTitleRow));

    int i;
    for(i = 0; i < INQ_ACT_COUNT; i++)
    {
        string sLabel = InqGetActName(i) + "  (+" + IntToString(InqGetActWeight(i)) + " pkt)";
        json jBtn = NuiButton(JsonString(sLabel));
        jBtn = NuiId(jBtn, INQ_BTN_DM_ACT_ROW + IntToString(i));
        jBtn = NuiWidth(jBtn, fBtnW);
        jBtn = NuiHeight(jBtn, fBtnH);
        jCol = JsonArrayInsert(jCol, jBtn);
    }

    json jCancel = NuiButton(JsonString("Anuluj"));
    jCancel = NuiId(jCancel, INQ_BTN_DM_ACT_CLOSE);
    jCancel = NuiWidth(jCancel, fBtnW);
    jCancel = NuiHeight(jCancel, fBtnH);
    jCol = JsonArrayInsert(jCol, jCancel);

    return NuiCol(jCol);
}

void InqOpenActPicker(object oDM)
{
    int nToken = NuiFindWindow(oDM, INQ_WINDOW_DM_ACT);
    if(nToken) NuiDestroy(oDM, nToken);

    json jWin = NuiWindow(
        InqBuildActPickerLayout(oDM),
        JsonString("Dodaj zarzut"),
        NuiBind(INQ_WIN_ACT_GEOM),
        JsonBool(FALSE),
        JsonBool(FALSE),
        JsonBool(TRUE),
        JsonBool(FALSE),
        JsonBool(FALSE));
    NuiCreate(oDM, jWin, INQ_WINDOW_DM_ACT, INQ_EV_SCRIPT);
}

// ============================================================
// DM: apply a charge to the selected PC
// ============================================================

void InqDmApplyCharge(object oDM, int nActId)
{
    string sSelUuid = GetLocalString(oDM, INQ_LVAR_DM_SEL_UUID);
    string sSelName = GetLocalString(oDM, INQ_LVAR_DM_SEL_NAME);

    if(sSelUuid == "")
    {
        SendMessageToPC(oDM, "[Inkwizycja] Wybierz najpierw postać.");
        return;
    }

    // Find the PC online to apply effects live
    object oTarget = OBJECT_INVALID;
    object oPC = GetFirstPC();
    while(GetIsObjectValid(oPC))
    {
        if(GetObjectUUID(oPC) == sSelUuid) { oTarget = oPC; break; }
        oPC = GetNextPC();
    }

    int nNewRating;
    if(GetIsObjectValid(oTarget))
    {
        InqAddCharge(oTarget, nActId);
        nNewRating = InqGetRating(sSelUuid);
        SendMessageToPC(oTarget, "[Inkwizycja] Odnotowano: " + InqGetActName(nActId) + ".");
    }
    else
    {
        int nWeight = InqGetActWeight(nActId);
        nNewRating  = InqInsertCharge(sSelUuid, sSelName, nActId, nWeight);
    }

    SendMessageToPC(oDM, "[Inkwizycja] Zarzut dodany: " + InqGetActName(nActId)
        + " (" + sSelName + "). Nowa ocena: " + IntToString(nNewRating) + ".");

    int nDmToken = NuiFindWindow(oDM, INQ_WINDOW_DM);
    if(nDmToken) InqFeedDmPanel(oDM, nDmToken);
}

// ============================================================
// DM: full pardon for selected PC
// ============================================================

void InqDmPardon(object oDM)
{
    string sSelUuid = GetLocalString(oDM, INQ_LVAR_DM_SEL_UUID);
    string sSelName = GetLocalString(oDM, INQ_LVAR_DM_SEL_NAME);

    if(sSelUuid == "")
    {
        SendMessageToPC(oDM, "[Inkwizycja] Wybierz najpierw postać.");
        return;
    }

    InqClearAll(sSelUuid, sSelName);

    object oPC = GetFirstPC();
    while(GetIsObjectValid(oPC))
    {
        if(GetObjectUUID(oPC) == sSelUuid)
        {
            InqRemoveRatingEffects(oPC);
            SendMessageToPC(oPC,
                "[Inkwizycja] Zostałeś ułaskawiony przez biskupa. Twoja karta jest czysta.");
            int nPcToken = NuiFindWindow(oPC, INQ_WINDOW_DOSSIER);
            if(nPcToken) InqFeedDossier(oPC, nPcToken);
            break;
        }
        oPC = GetNextPC();
    }

    SendMessageToPC(oDM, "[Inkwizycja] " + sSelName + " ułaskawiony.");

    int nDmToken = NuiFindWindow(oDM, INQ_WINDOW_DM);
    if(nDmToken) InqFeedDmPanel(oDM, nDmToken);
}
