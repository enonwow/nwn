// lib_anc.nss — Ancestor Spirits: NUI building, data feeding, open/close

#include "lib_anc_def"

// ---------------------------------------------------------------
// NUI layout builders
// ---------------------------------------------------------------

json AncBuildAncestorRow(object oPC, int nSlot)
{
    string sSuffix  = IntToString(nSlot);
    float fRowH     = GetNuiScaleDimension(oPC, 70.0);
    float fBtnW     = GetNuiScaleDimension(oPC, 82.0);
    float fBtnH     = GetNuiScaleDimension(oPC, 26.0);
    float fCostW    = GetNuiScaleDimension(oPC, 90.0);
    float fLblH     = GetNuiScaleDimension(oPC, 20.0);

    // Text column: name / desc / status
    json jName = NuiLabel(NuiBind(ANC_BIND_ANAME + sSuffix),
        JsonInt(NUI_HALIGN_LEFT), JsonInt(NUI_VALIGN_MIDDLE));
    jName = NuiHeight(jName, fLblH);

    json jDesc = NuiLabel(NuiBind(ANC_BIND_ADESC + sSuffix),
        JsonInt(NUI_HALIGN_LEFT), JsonInt(NUI_VALIGN_MIDDLE));
    jDesc = NuiHeight(jDesc, fLblH);

    json jStat = NuiLabel(NuiBind(ANC_BIND_ASTAT + sSuffix),
        JsonInt(NUI_HALIGN_LEFT), JsonInt(NUI_VALIGN_MIDDLE));
    jStat = NuiStyleForegroundColor(jStat, NuiBind(ANC_BIND_ASTATCOL + sSuffix));
    jStat = NuiHeight(jStat, fLblH);

    json jInfoElems = JsonArray();
    jInfoElems = JsonArrayInsert(jInfoElems, jName);
    jInfoElems = JsonArrayInsert(jInfoElems, jDesc);
    jInfoElems = JsonArrayInsert(jInfoElems, jStat);

    // Cost label
    json jCost = NuiLabel(NuiBind(ANC_BIND_ACOST + sSuffix),
        JsonInt(NUI_HALIGN_RIGHT), JsonInt(NUI_VALIGN_MIDDLE));
    jCost = NuiWidth(jCost, fCostW);

    // Invoke button
    json jBtn = NuiButton(JsonString("Wezwij"));
    jBtn = NuiId(jBtn, ANC_BTN_INVOKE + sSuffix);
    jBtn = NuiEnabled(jBtn, NuiBind(ANC_BIND_ABTN_ENA + sSuffix));
    jBtn = NuiWidth(jBtn, fBtnW);
    jBtn = NuiHeight(jBtn, fBtnH);

    json jCells = JsonArray();
    jCells = JsonArrayInsert(jCells, NuiCol(jInfoElems));
    jCells = JsonArrayInsert(jCells, jCost);
    jCells = JsonArrayInsert(jCells, jBtn);

    json jGrp = NuiGroup(NuiRow(jCells), FALSE, NUI_SCROLLBARS_NONE);
    jGrp = NuiHeight(jGrp, fRowH);
    return jGrp;
}

json AncBuildAltarView(object oPC)
{
    float fBtnH  = GetNuiScaleDimension(oPC, 28.0);
    float fBarH  = GetNuiScaleDimension(oPC, 16.0);
    float fSpcH  = GetNuiScaleDimension(oPC, 8.0);
    float fHdrH  = GetNuiScaleDimension(oPC, 22.0);
    float fFldW  = GetNuiScaleDimension(oPC, 90.0);
    float fBtnOfW= GetNuiScaleDimension(oPC, 90.0);

    // -- Header: lineage name | favor label --
    json jLinLbl = NuiLabel(NuiBind(ANC_BIND_LINEAGE_LBL),
        JsonInt(NUI_HALIGN_LEFT), JsonInt(NUI_VALIGN_MIDDLE));
    jLinLbl = NuiHeight(jLinLbl, fHdrH);

    json jFavLbl = NuiLabel(NuiBind(ANC_BIND_FAVOR_LBL),
        JsonInt(NUI_HALIGN_RIGHT), JsonInt(NUI_VALIGN_MIDDLE));
    jFavLbl = NuiHeight(jFavLbl, fHdrH);

    json jHdrRow = JsonArray();
    jHdrRow = JsonArrayInsert(jHdrRow, jLinLbl);
    jHdrRow = JsonArrayInsert(jHdrRow, jFavLbl);

    // -- Favor progress bar --
    json jBar = NuiProgress(NuiBind(ANC_BIND_FAVOR_VAL));
    jBar = NuiHeight(jBar, fBarH);

    // -- Offer row: label | text input | button --
    json jOfferLbl = NuiLabel(JsonString("Ofiara:"),
        JsonInt(NUI_HALIGN_LEFT), JsonInt(NUI_VALIGN_MIDDLE));
    jOfferLbl = NuiWidth(jOfferLbl, GetNuiScaleDimension(oPC, 60.0));

    json jOfferFld = NuiTextEdit(JsonString("ilosc zlota"),
        NuiBind(ANC_BIND_OFFER_TXT), 8, FALSE);
    jOfferFld = NuiWidth(jOfferFld, fFldW);
    jOfferFld = NuiHeight(jOfferFld, fBtnH);

    json jOfferBtn = NuiButton(JsonString("Ofiaruj"));
    jOfferBtn = NuiId(jOfferBtn, ANC_BTN_OFFER);
    jOfferBtn = NuiEnabled(jOfferBtn, NuiBind(ANC_BIND_OFFER_ENA));
    jOfferBtn = NuiWidth(jOfferBtn, fBtnOfW);
    jOfferBtn = NuiHeight(jOfferBtn, fBtnH);

    json jOfferRow = JsonArray();
    jOfferRow = JsonArrayInsert(jOfferRow, jOfferLbl);
    jOfferRow = JsonArrayInsert(jOfferRow, jOfferFld);
    jOfferRow = JsonArrayInsert(jOfferRow, NuiSpacer());
    jOfferRow = JsonArrayInsert(jOfferRow, jOfferBtn);

    // -- Ancestor section header --
    json jAncHdr = NuiLabel(JsonString("-- Duchy Przodkow --"),
        JsonInt(NUI_HALIGN_CENTER), JsonInt(NUI_VALIGN_MIDDLE));
    jAncHdr = NuiHeight(jAncHdr, fHdrH);

    // -- 3 ancestor rows --
    json jAnc0 = AncBuildAncestorRow(oPC, 0);
    json jAnc1 = AncBuildAncestorRow(oPC, 1);
    json jAnc2 = AncBuildAncestorRow(oPC, 2);

    // -- History section --
    json jHistHdr = NuiLabel(JsonString("-- Historia Przyzwan --"),
        JsonInt(NUI_HALIGN_CENTER), JsonInt(NUI_VALIGN_MIDDLE));
    jHistHdr = NuiHeight(jHistHdr, fHdrH);

    json jHistLbl = NuiLabel(NuiBind(ANC_BIND_HIST_ROWS),
        JsonInt(NUI_HALIGN_LEFT), JsonInt(NUI_VALIGN_MIDDLE));

    float fHistRowH = GetNuiScaleDimension(oPC, 20.0);
    json jHistTmpl  = JsonArrayInsert(JsonArray(),
        NuiListTemplateCell(jHistLbl, 0.0, TRUE));
    json jHistList  = NuiList(jHistTmpl, NuiBind(ANC_BIND_HIST_CNT), fHistRowH);
    jHistList = NuiHeight(jHistList, GetNuiScaleDimension(oPC, 110.0));

    // -- Assemble --
    json jCol = JsonArray();
    jCol = JsonArrayInsert(jCol, NuiRow(jHdrRow));
    jCol = JsonArrayInsert(jCol, jBar);
    jCol = JsonArrayInsert(jCol, NuiHeight(NuiSpacer(), fSpcH));
    jCol = JsonArrayInsert(jCol, NuiRow(jOfferRow));
    jCol = JsonArrayInsert(jCol, NuiHeight(NuiSpacer(), fSpcH));
    jCol = JsonArrayInsert(jCol, NuiRow(JsonArrayInsert(JsonArray(), jAncHdr)));
    jCol = JsonArrayInsert(jCol, jAnc0);
    jCol = JsonArrayInsert(jCol, jAnc1);
    jCol = JsonArrayInsert(jCol, jAnc2);
    jCol = JsonArrayInsert(jCol, NuiHeight(NuiSpacer(), fSpcH));
    jCol = JsonArrayInsert(jCol, NuiRow(JsonArrayInsert(JsonArray(), jHistHdr)));
    jCol = JsonArrayInsert(jCol, jHistList);

    float fContentW = GetNuiScaleDimension(oPC, ANC_W - 20.0);
    json jSide      = NuiCol(JsonArrayInsert(JsonArray(), NuiSpacer()));
    json jMainRow   = JsonArray();
    jMainRow = JsonArrayInsert(jMainRow, jSide);
    jMainRow = JsonArrayInsert(jMainRow, NuiWidth(NuiCol(jCol), fContentW));
    jMainRow = JsonArrayInsert(jMainRow, jSide);
    return NuiRow(jMainRow);
}

json AncBuildLineageView(object oPC)
{
    float fHdrH   = GetNuiScaleDimension(oPC, 24.0);
    float fSubH   = GetNuiScaleDimension(oPC, 18.0);
    float fRowH   = GetNuiScaleDimension(oPC, 74.0);
    float fListH  = GetNuiScaleDimension(oPC, 380.0);

    json jTitle = NuiLabel(
        JsonString("Wybierz Rod Krwi"),
        JsonInt(NUI_HALIGN_CENTER), JsonInt(NUI_VALIGN_MIDDLE));
    jTitle = NuiHeight(jTitle, fHdrH);

    json jSub = NuiLabel(
        JsonString("To dziedzictwo zostanie zapisane w kosci — nie mozna go zmienic."),
        JsonInt(NUI_HALIGN_CENTER), JsonInt(NUI_VALIGN_MIDDLE));
    jSub = NuiHeight(jSub, fSubH);

    // List row template: clickable group with name + desc stacked
    json jName = NuiLabel(NuiBind(ANC_BIND_LIN_NAMES),
        JsonInt(NUI_HALIGN_LEFT), JsonInt(NUI_VALIGN_MIDDLE));
    jName = NuiHeight(jName, GetNuiScaleDimension(oPC, 26.0));

    json jDesc = NuiLabel(NuiBind(ANC_BIND_LIN_DESCS),
        JsonInt(NUI_HALIGN_LEFT), JsonInt(NUI_VALIGN_TOP));
    jDesc = NuiHeight(jDesc, GetNuiScaleDimension(oPC, 38.0));

    json jInnerCol = JsonArray();
    jInnerCol = JsonArrayInsert(jInnerCol, jName);
    jInnerCol = JsonArrayInsert(jInnerCol, jDesc);

    json jRowGrp = NuiGroup(NuiCol(jInnerCol), TRUE, NUI_SCROLLBARS_NONE);
    jRowGrp = NuiId(jRowGrp, ANC_BTN_LIN_ROW);
    jRowGrp = NuiEncouraged(jRowGrp, NuiBind(ANC_BIND_LIN_ENC));

    json jLinTmpl = JsonArrayInsert(JsonArray(),
        NuiListTemplateCell(jRowGrp, 0.0, TRUE));
    json jLinList = NuiList(jLinTmpl, NuiBind(ANC_BIND_LIN_ROWCOUNT), fRowH);
    jLinList = NuiHeight(jLinList, fListH);

    json jCol = JsonArray();
    jCol = JsonArrayInsert(jCol, NuiRow(JsonArrayInsert(JsonArray(), jTitle)));
    jCol = JsonArrayInsert(jCol, NuiRow(JsonArrayInsert(JsonArray(), jSub)));
    jCol = JsonArrayInsert(jCol, jLinList);

    float fContentW = GetNuiScaleDimension(oPC, ANC_W - 20.0);
    json jSide      = NuiCol(JsonArrayInsert(JsonArray(), NuiSpacer()));
    json jMainRow   = JsonArray();
    jMainRow = JsonArrayInsert(jMainRow, jSide);
    jMainRow = JsonArrayInsert(jMainRow, NuiWidth(NuiCol(jCol), fContentW));
    jMainRow = JsonArrayInsert(jMainRow, jSide);
    return NuiRow(jMainRow);
}

// ---------------------------------------------------------------
// Window creation
// ---------------------------------------------------------------

void AncCreateWindow(object oPC)
{
    if(NuiFindWindow(oPC, ANC_WINDOW) != 0)
    {
        int nToken = NuiFindWindow(oPC, ANC_WINDOW);
        int nLin   = AncGetLineage(oPC);
        if(nLin == ANC_LINEAGE_NONE)
        {
            NuiSetGroupLayout(oPC, nToken, ANC_GRP_SWAP, AncBuildLineageView(oPC));
            AncFeedLineage(oPC, nToken);
        }
        else
        {
            NuiSetGroupLayout(oPC, nToken, ANC_GRP_SWAP, AncBuildAltarView(oPC));
            AncFeedAltar(oPC, nToken);
        }
        return;
    }

    int nLineage    = AncGetLineage(oPC);
    json jInitView  = (nLineage == ANC_LINEAGE_NONE)
                    ? AncBuildLineageView(oPC)
                    : AncBuildAltarView(oPC);

    json jSwapGrp = NuiGroup(jInitView, FALSE, NUI_SCROLLBARS_NONE);
    jSwapGrp = NuiId(jSwapGrp, ANC_GRP_SWAP);

    float fBtnH = GetNuiScaleDimension(oPC, 28.0);
    json jCloseBtn = NuiButton(JsonString("X"));
    jCloseBtn = NuiId(jCloseBtn, ANC_BTN_CLOSE);
    jCloseBtn = NuiWidth(jCloseBtn, GetNuiScaleDimension(oPC, 28.0));
    jCloseBtn = NuiHeight(jCloseBtn, fBtnH);

    json jTopBar = JsonArray();
    jTopBar = JsonArrayInsert(jTopBar, NuiSpacer());
    jTopBar = JsonArrayInsert(jTopBar, jCloseBtn);

    json jRootElems = JsonArray();
    jRootElems = JsonArrayInsert(jRootElems, NuiRow(jTopBar));
    jRootElems = JsonArrayInsert(jRootElems, jSwapGrp);
    json jRoot = NuiCol(jRootElems);

    float fCX = (IntToFloat(GetPlayerDeviceProperty(oPC, PLAYER_DEVICE_PROPERTY_GUI_WIDTH))
                 - GetNuiScaleDimension(oPC, ANC_W)) / 2.0;
    float fCY = (IntToFloat(GetPlayerDeviceProperty(oPC, PLAYER_DEVICE_PROPERTY_GUI_HEIGHT))
                 - GetNuiScaleDimension(oPC, ANC_H)) / 2.0;
    json jGeom = NuiRect(fCX, fCY,
        GetNuiScaleDimension(oPC, ANC_W),
        GetNuiScaleDimension(oPC, ANC_H));

    json jWin = NuiWindow(jRoot,
        JsonBool(FALSE),        // no text title bar
        NuiBind(ANC_WIN_GEOM),
        JsonBool(FALSE),        // not resizable
        JsonBool(FALSE),        // not collapsed
        JsonBool(FALSE),        // closable = FALSE (own close btn)
        JsonBool(FALSE),        // not transparent
        JsonBool(TRUE));        // border visible

    int nToken = NuiCreate(oPC, jWin, ANC_WINDOW, ANC_EV_SCRIPT);
    NuiSetBind(oPC, nToken, ANC_WIN_GEOM, jGeom);

    if(nLineage == ANC_LINEAGE_NONE)
        AncFeedLineage(oPC, nToken);
    else
        AncFeedAltar(oPC, nToken);
}

void AncOpen(object oPC)
{
    if(!GetIsPC(oPC)) return;
    AncRegisterPC(oPC);
    AncCreateWindow(oPC);
}

// ---------------------------------------------------------------
// Data feed — lineage selection view
// ---------------------------------------------------------------

void AncFeedLineage(object oPC, int nToken)
{
    json jNames = JsonArray();
    json jDescs = JsonArray();
    json jEncs  = JsonArray();
    int i;
    for(i = 0; i < ANC_LINEAGE_COUNT; i++)
    {
        jNames = JsonArrayInsert(jNames, JsonString(AncGetLineageName(i)));
        jDescs = JsonArrayInsert(jDescs, JsonString(AncGetLineageDesc(i)));
        jEncs  = JsonArrayInsert(jEncs,  JsonBool(FALSE));
    }
    NuiSetBind(oPC, nToken, ANC_BIND_LIN_NAMES,    jNames);
    NuiSetBind(oPC, nToken, ANC_BIND_LIN_DESCS,    jDescs);
    NuiSetBind(oPC, nToken, ANC_BIND_LIN_ENC,      jEncs);
    NuiSetBind(oPC, nToken, ANC_BIND_LIN_ROWCOUNT, JsonInt(ANC_LINEAGE_COUNT));
}

// ---------------------------------------------------------------
// Data feed — altar view
// ---------------------------------------------------------------

void AncFeedAncestors(object oPC, int nToken)
{
    int nLineage = AncGetLineage(oPC);
    int nFavor   = AncGetFavor(oPC);
    int nSlot;

    for(nSlot = 0; nSlot < 3; nSlot++)
    {
        int nAncId    = nLineage * 3 + nSlot;
        int nCost     = AncGetCostBySlot(nSlot);
        int nCooldown = AncGetCooldownRemaining(oPC, nAncId);
        int bAvail    = (nCooldown == 0) && (nFavor >= nCost);

        string sSuffix = IntToString(nSlot);
        string sStatus = AncFormatCooldown(nCooldown);
        json jColor;
        if(bAvail)
            jColor = NuiColor(80, 220, 80);    // green — available
        else if(nCooldown > 0)
            jColor = NuiColor(210, 160, 60);   // orange — on cooldown
        else
            jColor = NuiColor(190, 70, 70);    // red — insufficient Favor

        NuiSetBind(oPC, nToken, ANC_BIND_ANAME    + sSuffix, JsonString(AncGetAncestorName(nAncId)));
        NuiSetBind(oPC, nToken, ANC_BIND_ADESC    + sSuffix, JsonString(AncGetAncestorDesc(nAncId)));
        NuiSetBind(oPC, nToken, ANC_BIND_ACOST    + sSuffix, JsonString(IntToString(nCost) + " Laski"));
        NuiSetBind(oPC, nToken, ANC_BIND_ASTAT    + sSuffix, JsonString(sStatus));
        NuiSetBind(oPC, nToken, ANC_BIND_ASTATCOL + sSuffix, jColor);
        NuiSetBind(oPC, nToken, ANC_BIND_ABTN_ENA + sSuffix, JsonBool(bAvail));
    }
}

void AncFeedHistory(object oPC, int nToken)
{
    json jHist  = AncGetHistory(oPC);
    int  nCount = JsonGetLength(jHist);
    json jRows  = JsonArray();
    int i;
    for(i = 0; i < nCount; i++)
    {
        json jEntry  = JsonArrayGet(jHist, i);
        string sName = JsonGetString(JsonObjectGet(jEntry, "name"));
        string sDate = JsonGetString(JsonObjectGet(jEntry, "date"));
        jRows = JsonArrayInsert(jRows, JsonString(sDate + "  " + sName));
    }
    NuiSetBind(oPC, nToken, ANC_BIND_HIST_ROWS, jRows);
    NuiSetBind(oPC, nToken, ANC_BIND_HIST_CNT,  JsonInt(nCount));
}

void AncFeedAltar(object oPC, int nToken)
{
    int   nLineage = AncGetLineage(oPC);
    int   nFavor   = AncGetFavor(oPC);
    float fRatio   = IntToFloat(nFavor) / IntToFloat(ANC_FAVOR_MAX);

    NuiSetBind(oPC, nToken, ANC_BIND_LINEAGE_LBL,
        JsonString(AncGetLineageName(nLineage)));
    NuiSetBind(oPC, nToken, ANC_BIND_FAVOR_LBL,
        JsonString("Laska: " + IntToString(nFavor) + " / " + IntToString(ANC_FAVOR_MAX)));
    NuiSetBind(oPC, nToken, ANC_BIND_FAVOR_VAL,
        JsonFloat(fRatio));
    NuiSetBind(oPC, nToken, ANC_BIND_OFFER_ENA, JsonBool(TRUE));

    AncFeedAncestors(oPC, nToken);
    AncFeedHistory(oPC, nToken);
}

// ---------------------------------------------------------------
// Action handlers (called from event script)
// ---------------------------------------------------------------

void AncHandleSelectLineage(object oPC, int nToken, int nLineageIdx)
{
    if(nLineageIdx < 0 || nLineageIdx >= ANC_LINEAGE_COUNT) return;
    if(AncGetLineage(oPC) != ANC_LINEAGE_NONE)
    {
        SendMessageToPC(oPC, "[Przodkowie] Rod krwi zostal juz wybrany i nie moze byc zmieniony.");
        return;
    }

    AncSetLineage(oPC, nLineageIdx);

    SendMessageToPC(oPC,
        "[Przodkowie] Wybrano " + AncGetLineageName(nLineageIdx) + ". "
        + "Krew przodkow przyjela twoje slowo.");
    FloatingTextStringOnCreature(
        "Pieczen rodu " + AncGetLineageName(nLineageIdx) + " wypalona w pamiec...",
        oPC, FALSE);

    NuiSetGroupLayout(oPC, nToken, ANC_GRP_SWAP, AncBuildAltarView(oPC));
    AncFeedAltar(oPC, nToken);
}

void AncHandleOffer(object oPC, int nToken)
{
    string sVal = JsonGetString(NuiGetBind(oPC, nToken, ANC_BIND_OFFER_TXT));
    int nGold   = StringToInt(sVal);

    if(nGold <= 0)
    {
        SendMessageToPC(oPC, "[Przodkowie] Wpisz prawidlowa ilosc zlota.");
        return;
    }
    if(GetGold(oPC) < nGold)
    {
        SendMessageToPC(oPC,
            "[Przodkowie] Nie posiadasz " + IntToString(nGold) + " sztuk zlota.");
        return;
    }
    if(AncGetFavor(oPC) >= ANC_FAVOR_MAX)
    {
        SendMessageToPC(oPC,
            "[Przodkowie] Laska przodkow osiagnela pelen poziom. "
            "Wezwij duchy, by zwolnic miejsce.");
        return;
    }

    AssignCommand(oPC, TakeGoldFromCreature(nGold, oPC, TRUE));
    int nAdded = AncAddFavor(oPC, nGold);

    FloatingTextStringOnCreature(
        "Ofiara z " + IntToString(nGold) + " zlota przyjeta przez przodkow.",
        oPC, FALSE);
    SendMessageToPC(oPC,
        "[Przodkowie] +" + IntToString(nAdded) + " Laski.");

    NuiSetBind(oPC, nToken, ANC_BIND_OFFER_TXT, JsonString(""));
    AncFeedAltar(oPC, nToken);
}

void AncHandleInvoke(object oPC, int nToken, int nSlot)
{
    AncInvokeAncestor(oPC, nSlot);
    AncFeedAltar(oPC, nToken);
}
