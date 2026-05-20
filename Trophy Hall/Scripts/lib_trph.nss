// lib_trph.nss — Trophy Hall: NUI layout, feed functions, deposit + crafting logic

#include "lib_trph_def"

// ============================================================
// Forward declarations
// ============================================================

void TrphCreateWindow(object oPC);
void TrphFeedCategories(object oPC, int nToken);
void TrphFeedDetail(object oPC, int nToken, int nCat);
int  TrphCountInInventory(object oPC, int nCat);
int  TrphDepositTrophies(object oPC, int nCat);
void TrphForgeTalisman(object oPC, int nToken, int nCat, int bMajor);

// ============================================================
// NUI — Category list (left column)
// ============================================================

json TrphBuildCatList(object oPC)
{
    float fRowH  = GetNuiScaleDimension(oPC, 38.0);
    float fListH = GetNuiScaleDimension(oPC, 400.0);
    float fW     = GetNuiScaleDimension(oPC, 160.0);

    json jNameCell = NuiLabel(
        NuiBind(TRPH_BIND_CAT_LABEL),
        JsonInt(NUI_HALIGN_LEFT),
        JsonInt(NUI_VALIGN_MIDDLE));

    json jCellGrp = NuiGroup(
        NuiRow(JsonArrayInsert(JsonArray(), jNameCell)),
        TRUE, NUI_SCROLLBARS_NONE);
    jCellGrp = NuiId(jCellGrp, TRPH_BTN_CAT_ROW);
    jCellGrp = NuiEncouraged(jCellGrp, NuiBind(TRPH_BIND_CAT_ENC));

    json jTmpl = JsonArrayInsert(
        JsonArray(),
        NuiListTemplateCell(jCellGrp, 0.0, TRUE));

    json jList = NuiList(jTmpl, JsonInt(TRPH_CAT_COUNT), fRowH);
    jList = NuiHeight(jList, fListH);

    return NuiWidth(NuiCol(JsonArrayInsert(JsonArray(), jList)), fW);
}

// ============================================================
// NUI — Detail panel (right column)
// ============================================================

json TrphBuildDetailPanel(object oPC)
{
    float fBtnH  = GetNuiScaleDimension(oPC, 32.0);
    float fFlvH  = GetNuiScaleDimension(oPC, 90.0);
    float fLbH   = GetNuiScaleDimension(oPC, 132.0);
    float fRowH  = GetNuiScaleDimension(oPC, 24.0);
    float fLblH  = GetNuiScaleDimension(oPC, 24.0);

    // ---- Title ----
    json jTitle = NuiLabel(
        NuiBind(TRPH_BIND_DET_TITLE),
        JsonInt(NUI_HALIGN_LEFT),
        JsonInt(NUI_VALIGN_MIDDLE));
    jTitle = NuiHeight(jTitle, GetNuiScaleDimension(oPC, 30.0));

    // ---- Flavor text (scrollable block) ----
    json jFlavor = NuiGroup(
        NuiText(NuiBind(TRPH_BIND_DET_FLAVOR), FALSE),
        TRUE, NUI_SCROLLBARS_NONE);
    jFlavor = NuiHeight(jFlavor, fFlvH);

    // ---- "Twoje trofea: X dostępnych" ----
    json jMyCount = NuiLabel(
        NuiBind(TRPH_BIND_MY_COUNT),
        JsonInt(NUI_HALIGN_LEFT),
        JsonInt(NUI_VALIGN_MIDDLE));
    jMyCount = NuiHeight(jMyCount, fLblH);

    // ---- Craft cost reminder ----
    json jCraftInfo = NuiLabel(
        NuiBind(TRPH_BIND_CRAFT_INFO),
        JsonInt(NUI_HALIGN_LEFT),
        JsonInt(NUI_VALIGN_MIDDLE));
    jCraftInfo = NuiHeight(jCraftInfo, fLblH);

    // ---- Leaderboard header ----
    json jLbHdr = NuiLabel(
        JsonString("Ranking myśliwych:"),
        JsonInt(NUI_HALIGN_LEFT),
        JsonInt(NUI_VALIGN_MIDDLE));
    jLbHdr = NuiHeight(jLbHdr, GetNuiScaleDimension(oPC, 20.0));

    // ---- Leaderboard list (fixed TRPH_LB_ROWS rows) ----
    json jLbName  = NuiLabel(NuiBind(TRPH_BIND_LB_NAME),  JsonInt(NUI_HALIGN_LEFT),  JsonInt(NUI_VALIGN_MIDDLE));
    json jLbCount = NuiLabel(NuiBind(TRPH_BIND_LB_COUNT), JsonInt(NUI_HALIGN_RIGHT), JsonInt(NUI_VALIGN_MIDDLE));
    jLbCount = NuiWidth(jLbCount, GetNuiScaleDimension(oPC, 60.0));

    json jLbCellRow = JsonArray();
    jLbCellRow = JsonArrayInsert(jLbCellRow, jLbName);
    jLbCellRow = JsonArrayInsert(jLbCellRow, jLbCount);

    json jLbCell = NuiGroup(NuiRow(jLbCellRow), FALSE, NUI_SCROLLBARS_NONE);
    json jLbTmpl = JsonArrayInsert(JsonArray(), NuiListTemplateCell(jLbCell, 0.0, TRUE));
    json jLbList = NuiList(jLbTmpl, JsonInt(TRPH_LB_ROWS), fRowH);
    jLbList = NuiHeight(jLbList, fLbH);

    // ---- Action buttons ----
    json jDepBtn = NuiButton(JsonString("Złóż trofea"));
    jDepBtn = NuiId(jDepBtn, TRPH_BTN_DEPOSIT);
    jDepBtn = NuiEnabled(jDepBtn, NuiBind(TRPH_BIND_DEP_ENA));
    jDepBtn = NuiWidth(jDepBtn, GetNuiScaleDimension(oPC, 140.0));
    jDepBtn = NuiHeight(jDepBtn, fBtnH);

    json jFMinBtn = NuiButton(JsonString("Wykuj Talizman  (5)"));
    jFMinBtn = NuiId(jFMinBtn, TRPH_BTN_FORGE_MINOR);
    jFMinBtn = NuiEnabled(jFMinBtn, NuiBind(TRPH_BIND_FMIN_ENA));
    jFMinBtn = NuiWidth(jFMinBtn, GetNuiScaleDimension(oPC, 180.0));
    jFMinBtn = NuiHeight(jFMinBtn, fBtnH);

    json jFMajBtn = NuiButton(JsonString("Wykuj Wielki Talizman  (15)"));
    jFMajBtn = NuiId(jFMajBtn, TRPH_BTN_FORGE_MAJOR);
    jFMajBtn = NuiEnabled(jFMajBtn, NuiBind(TRPH_BIND_FMAJ_ENA));
    jFMajBtn = NuiWidth(jFMajBtn, GetNuiScaleDimension(oPC, 220.0));
    jFMajBtn = NuiHeight(jFMajBtn, fBtnH);

    json jBtnRow = JsonArray();
    jBtnRow = JsonArrayInsert(jBtnRow, jDepBtn);
    jBtnRow = JsonArrayInsert(jBtnRow, NuiSpacer());
    jBtnRow = JsonArrayInsert(jBtnRow, jFMinBtn);
    jBtnRow = JsonArrayInsert(jBtnRow, jFMajBtn);

    // ---- Assemble detail column ----
    json jCol = JsonArray();
    jCol = JsonArrayInsert(jCol, jTitle);
    jCol = JsonArrayInsert(jCol, jFlavor);
    jCol = JsonArrayInsert(jCol, jMyCount);
    jCol = JsonArrayInsert(jCol, jCraftInfo);
    jCol = JsonArrayInsert(jCol, jLbHdr);
    jCol = JsonArrayInsert(jCol, jLbList);
    jCol = JsonArrayInsert(jCol, NuiRow(jBtnRow));

    return NuiCol(jCol);
}

// ============================================================
// Window creation / refresh
// ============================================================

void TrphCreateWindow(object oPC)
{
    int nToken = NuiFindWindow(oPC, TRPH_WINDOW);
    if(nToken != 0)
    {
        // Already open — just refresh data
        TrphFeedCategories(oPC, nToken);
        TrphFeedDetail(oPC, nToken, GetLocalInt(oPC, TRPH_LVAR_SEL_CAT));
        return;
    }

    float fW = GetNuiScaleDimension(oPC, TRPH_W);
    float fH = GetNuiScaleDimension(oPC, TRPH_H);
    float fCX = (IntToFloat(GetPlayerDeviceProperty(oPC, PLAYER_DEVICE_PROPERTY_GUI_WIDTH))  - fW) / 2.0;
    float fCY = (IntToFloat(GetPlayerDeviceProperty(oPC, PLAYER_DEVICE_PROPERTY_GUI_HEIGHT)) - fH) / 2.0;
    json jGeom = NuiRect(fCX, fCY, fW, fH);

    // Close button (top-right)
    json jCloseBtn = NuiButton(JsonString("X"));
    jCloseBtn = NuiId(jCloseBtn, TRPH_BTN_CLOSE);
    jCloseBtn = NuiWidth(jCloseBtn,  GetNuiScaleDimension(oPC, 30.0));
    jCloseBtn = NuiHeight(jCloseBtn, GetNuiScaleDimension(oPC, 30.0));

    json jTopBar = JsonArray();
    jTopBar = JsonArrayInsert(jTopBar, NuiSpacer());
    jTopBar = JsonArrayInsert(jTopBar, jCloseBtn);

    // Content: cat list | spacer | detail
    json jSep = NuiWidth(
        NuiCol(JsonArrayInsert(JsonArray(), NuiSpacer())),
        GetNuiScaleDimension(oPC, 8.0));

    json jContent = JsonArray();
    jContent = JsonArrayInsert(jContent, TrphBuildCatList(oPC));
    jContent = JsonArrayInsert(jContent, jSep);
    jContent = JsonArrayInsert(jContent, TrphBuildDetailPanel(oPC));

    json jRoot = JsonArray();
    jRoot = JsonArrayInsert(jRoot, NuiRow(jTopBar));
    jRoot = JsonArrayInsert(jRoot, NuiRow(jContent));

    json jWin = NuiWindow(
        NuiCol(jRoot),
        JsonString("Sala Trofeów"),
        NuiBind(TRPH_BIND_GEOM),
        JsonBool(FALSE),
        JsonBool(FALSE),
        JsonBool(FALSE),
        JsonBool(TRUE),
        JsonBool(FALSE));

    nToken = NuiCreate(oPC, jWin, TRPH_WINDOW, TRPH_EV_SCRIPT);
    NuiSetBind(oPC, nToken, TRPH_BIND_GEOM, jGeom);

    SetLocalInt(oPC, TRPH_LVAR_SEL_CAT, TRPH_CAT_UNDEAD);
    TrphFeedCategories(oPC, nToken);
    TrphFeedDetail(oPC, nToken, TRPH_CAT_UNDEAD);
}

// ============================================================
// Feed — category list
// ============================================================

void TrphFeedCategories(object oPC, int nToken)
{
    int nSel = GetLocalInt(oPC, TRPH_LVAR_SEL_CAT);

    json jLabels = JsonArray();
    json jEncs   = JsonArray();

    int i;
    for(i = 0; i < TRPH_CAT_COUNT; i++)
    {
        int nAvail  = TrphGetAvailable(oPC, i);
        int nInInv  = TrphCountInInventory(oPC, i);
        string sLbl = TrphCatName(i);
        if(nAvail > 0 || nInInv > 0)
        {
            // Show total (deposited available + inventory) so player sees their "wealth"
            int nTotal = nAvail + nInInv;
            sLbl = sLbl + "  (" + IntToString(nTotal) + ")";
        }
        jLabels = JsonArrayInsert(jLabels, JsonString(sLbl));
        jEncs   = JsonArrayInsert(jEncs,   JsonBool(i == nSel));
    }

    NuiSetBind(oPC, nToken, TRPH_BIND_CAT_LABEL, jLabels);
    NuiSetBind(oPC, nToken, TRPH_BIND_CAT_ENC,   jEncs);
}

// ============================================================
// Feed — detail panel for selected category
// ============================================================

void TrphFeedDetail(object oPC, int nToken, int nCat)
{
    int nDeposited = TrphGetDeposited(oPC, nCat);
    int nAvail     = TrphGetAvailable(oPC, nCat);
    int nInInv     = TrphCountInInventory(oPC, nCat);
    int nCrMin     = TrphGetCraftedMinor(oPC, nCat);
    int nCrMaj     = TrphGetCraftedMajor(oPC, nCat);

    string sTitle  = TrphCatName(nCat) + "  —  " + TrphItemName(nCat);
    string sFlavor = TrphCatFlavor(nCat);

    string sMyCnt  = "Twoje trofea: " + IntToString(nAvail) + " dostępnych"
                   + "  |  złożone: " + IntToString(nDeposited)
                   + "  |  w ekwipunku: " + IntToString(nInInv);

    string sCraft  = "Talizman mały: 5 trofeów (+1 AB)  |  Wielki talizman: 15 trofeów (+2 AB, +1k6 obrażeń)"
                   + "  |  wykute: " + IntToString(nCrMin) + " / " + IntToString(nCrMaj);

    NuiSetBind(oPC, nToken, TRPH_BIND_DET_TITLE,  JsonString(sTitle));
    NuiSetBind(oPC, nToken, TRPH_BIND_DET_FLAVOR, JsonString(sFlavor));
    NuiSetBind(oPC, nToken, TRPH_BIND_MY_COUNT,   JsonString(sMyCnt));
    NuiSetBind(oPC, nToken, TRPH_BIND_CRAFT_INFO, JsonString(sCraft));

    NuiSetBind(oPC, nToken, TRPH_BIND_DEP_ENA,  JsonBool(nInInv > 0));
    NuiSetBind(oPC, nToken, TRPH_BIND_FMIN_ENA, JsonBool(nAvail >= TRPH_CRAFT_MINOR));
    NuiSetBind(oPC, nToken, TRPH_BIND_FMAJ_ENA, JsonBool(nAvail >= TRPH_CRAFT_MAJOR));

    // Leaderboard — pad to TRPH_LB_ROWS
    json jLb     = TrphGetLeaderboard(nCat);
    int  nLbLen  = JsonGetLength(jLb);

    json jNames  = JsonArray();
    json jCounts = JsonArray();

    int i;
    for(i = 0; i < TRPH_LB_ROWS; i++)
    {
        if(i < nLbLen)
        {
            json jRow    = JsonArrayGet(jLb, i);
            string sName = JsonGetString(JsonObjectGet(jRow, "pc_name"));
            int nDep     = JsonGetInt   (JsonObjectGet(jRow, "deposited"));
            jNames  = JsonArrayInsert(jNames,  JsonString(IntToString(i + 1) + ".  " + sName));
            jCounts = JsonArrayInsert(jCounts, JsonString(IntToString(nDep)));
        }
        else
        {
            jNames  = JsonArrayInsert(jNames,  JsonString("—"));
            jCounts = JsonArrayInsert(jCounts, JsonString(""));
        }
    }

    NuiSetBind(oPC, nToken, TRPH_BIND_LB_NAME,  jNames);
    NuiSetBind(oPC, nToken, TRPH_BIND_LB_COUNT, jCounts);
}

// ============================================================
// Inventory helpers
// ============================================================

int TrphCountInInventory(object oPC, int nCat)
{
    string sTag  = TRPH_ITEM_TAG + IntToString(nCat);
    int    nCount = 0;
    object oItem  = GetFirstItemInInventory(oPC);
    while(GetIsObjectValid(oItem))
    {
        if(GetTag(oItem) == sTag)
            nCount++;
        oItem = GetNextItemInInventory(oPC);
    }
    return nCount;
}

// Destroys all matching trophy items in PC inventory, records in SQL.
// Returns number deposited.
int TrphDepositTrophies(object oPC, int nCat)
{
    string sTag  = TRPH_ITEM_TAG + IntToString(nCat);
    int    nCount = 0;
    object oItem  = GetFirstItemInInventory(oPC);
    while(GetIsObjectValid(oItem))
    {
        object oNext = GetNextItemInInventory(oPC);
        if(GetTag(oItem) == sTag)
        {
            nCount++;
            DestroyObject(oItem);
        }
        oItem = oNext;
    }
    if(nCount > 0)
        TrphAddDeposit(oPC, nCat, nCount);
    return nCount;
}

// ============================================================
// Crafting — forge talisman
// ============================================================

void TrphForgeTalisman(object oPC, int nToken, int nCat, int bMajor)
{
    int nCost  = bMajor ? TRPH_CRAFT_MAJOR : TRPH_CRAFT_MINOR;
    int nAvail = TrphGetAvailable(oPC, nCat);

    if(nAvail < nCost)
    {
        SendMessageToPC(oPC, "[Trofea] Za mało złożonych trofeów — brakuje " + IntToString(nCost - nAvail) + ".");
        return;
    }

    // Try custom resref from HAK first; fall back to generic amulet
    string sSuffix = bMajor ? "_maj" : "_min";
    string sResref = TRPH_TALISMAN_RESREF_BASE + IntToString(nCat) + sSuffix;
    object oItem   = CreateItemOnObject(sResref, oPC);

    if(!GetIsObjectValid(oItem))
    {
        // Fallback: generic amulet with dynamic item properties
        oItem = CreateItemOnObject("nw_it_mneck001", oPC);
    }

    if(!GetIsObjectValid(oItem))
    {
        SendMessageToPC(oPC, "[Trofea] Nie udało się wykuć talizmanu. Skontaktuj się z administratorem.");
        return;
    }

    string sTalName = bMajor ? TrphTalismanMajorName(nCat) : TrphTalismanMinorName(nCat);
    SetName(oItem, sTalName);
    SetTag(oItem, "trph_talisman_" + IntToString(nCat) + sSuffix);

    int nIPRacial = TrphCatIPRacial(nCat);
    if(nIPRacial >= 0)
    {
        int nABBonus = bMajor ? 2 : 1;
        AddItemProperty(DURATION_TYPE_PERMANENT,
            ItemPropertyAttackBonusVsRace(nIPRacial, nABBonus),
            oItem);

        if(bMajor)
            AddItemProperty(DURATION_TYPE_PERMANENT,
                ItemPropertyDamageVsRace(nIPRacial, IP_CONST_DAMAGEBONUS_1d6),
                oItem);
    }

    // Flavor description
    string sDesc = "Talizman wykuty z trofeów: " + TrphCatName(nCat) + ". "
                 + (bMajor
                    ? "Potężna magia łowiecka chroni swego właściciela i wzmacnia ciosy."
                    : "Podstawowa magia łowiecka czyni myśliwego groźniejszym.");
    SetDescription(oItem, sDesc);

    // Record crafting cost
    if(bMajor)
        TrphAddCraftedMajor(oPC, nCat);
    else
        TrphAddCraftedMinor(oPC, nCat);

    string sMsg = bMajor
        ? "Wykuto Wielki Talizman: " + sTalName + "."
        : "Wykuto Talizman: " + sTalName + ".";
    SendMessageToPC(oPC, "[Trofea] " + sMsg);
    FloatingTextStringOnCreature(sTalName + " — gotowe!", oPC, FALSE);

    // Refresh UI
    TrphFeedCategories(oPC, nToken);
    TrphFeedDetail(oPC, nToken, nCat);
}
