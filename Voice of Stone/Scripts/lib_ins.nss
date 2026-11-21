#include "lib_ins_def"

// ----------------------------------------------------------------
// Read view layout
// ----------------------------------------------------------------

json BuildInsReadView(object oPC)
{
    float fBtnH  = GetNuiScaleDimension(oPC, 28.0);
    float fRowH  = GetNuiScaleDimension(oPC, 26.0);
    float fTypeW = GetNuiScaleDimension(oPC, 96.0);
    float fAuthW = GetNuiScaleDimension(oPC, 110.0);
    float fAgeW  = GetNuiScaleDimension(oPC, 40.0);

    // Row template: type | author | preview (elastic) | age | select button
    json jTypeLbl = NuiLabel(NuiBind(INS_BIND_LST_TYPE),
        JsonInt(NUI_HALIGN_CENTER), JsonInt(NUI_VALIGN_MIDDLE));
    jTypeLbl = NuiStyleForegroundColor(jTypeLbl, NuiBind(INS_BIND_LST_TCOL));
    jTypeLbl = NuiWidth(jTypeLbl, fTypeW);

    json jAuthLbl = NuiLabel(NuiBind(INS_BIND_LST_AUTH),
        JsonInt(NUI_HALIGN_LEFT), JsonInt(NUI_VALIGN_MIDDLE));
    jAuthLbl = NuiWidth(jAuthLbl, fAuthW);

    json jPrevLbl = NuiLabel(NuiBind(INS_BIND_LST_PREV),
        JsonInt(NUI_HALIGN_LEFT), JsonInt(NUI_VALIGN_MIDDLE));

    json jAgeLbl = NuiLabel(NuiBind(INS_BIND_LST_AGE),
        JsonInt(NUI_HALIGN_RIGHT), JsonInt(NUI_VALIGN_MIDDLE));
    jAgeLbl = NuiWidth(jAgeLbl, fAgeW);

    json jRowCells = JsonArray();
    jRowCells = JsonArrayInsert(jRowCells, jTypeLbl);
    jRowCells = JsonArrayInsert(jRowCells, jAuthLbl);
    jRowCells = JsonArrayInsert(jRowCells, jPrevLbl);
    jRowCells = JsonArrayInsert(jRowCells, jAgeLbl);

    json jRowGrp = NuiGroup(NuiRow(jRowCells), FALSE, NUI_SCROLLBARS_NONE);
    jRowGrp = NuiId(jRowGrp, INS_BTN_ROW);
    jRowGrp = NuiEncouraged(jRowGrp, NuiBind(INS_BIND_LST_ENC));

    json jTmpl = JsonArrayInsert(JsonArray(),
        NuiListTemplateCell(jRowGrp, 0.0, TRUE));

    float fListH = GetNuiScaleDimension(oPC, 218.0);
    json jList = NuiList(jTmpl, NuiBind(INS_BIND_LST_CNT), fRowH);
    jList = NuiHeight(jList, fListH);

    // Pagination row
    json jPrevBtn = NuiButton(JsonString("< Poprzednia"));
    jPrevBtn = NuiId(jPrevBtn, INS_BTN_PREV_PAGE);
    jPrevBtn = NuiEnabled(jPrevBtn, NuiBind(INS_BIND_PREV_ENA));
    jPrevBtn = NuiWidth(jPrevBtn, GetNuiScaleDimension(oPC, 110.0));
    jPrevBtn = NuiHeight(jPrevBtn, fBtnH);

    json jNextBtn = NuiButton(JsonString("Nastepna >"));
    jNextBtn = NuiId(jNextBtn, INS_BTN_NEXT_PAGE);
    jNextBtn = NuiEnabled(jNextBtn, NuiBind(INS_BIND_NEXT_ENA));
    jNextBtn = NuiWidth(jNextBtn, GetNuiScaleDimension(oPC, 110.0));
    jNextBtn = NuiHeight(jNextBtn, fBtnH);

    json jPageLbl = NuiLabel(NuiBind(INS_BIND_PAGE_LBL),
        JsonInt(NUI_HALIGN_CENTER), JsonInt(NUI_VALIGN_MIDDLE));

    json jPagRow = JsonArray();
    jPagRow = JsonArrayInsert(jPagRow, jPrevBtn);
    jPagRow = JsonArrayInsert(jPagRow, jPageLbl);
    jPagRow = JsonArrayInsert(jPagRow, jNextBtn);

    // Detail section: always present, content changes on row selection
    float fDetTextH = GetNuiScaleDimension(oPC, 80.0);

    json jDetHdr = NuiLabel(NuiBind(INS_BIND_DET_HDR),
        JsonInt(NUI_HALIGN_LEFT), JsonInt(NUI_VALIGN_MIDDLE));
    jDetHdr = NuiHeight(jDetHdr, GetNuiScaleDimension(oPC, 22.0));

    json jDetTextGrp = NuiGroup(NuiText(NuiBind(INS_BIND_DET_TEXT), FALSE),
        TRUE, NUI_SCROLLBARS_AUTO);
    jDetTextGrp = NuiHeight(jDetTextGrp, fDetTextH);

    json jDetRate = NuiLabel(NuiBind(INS_BIND_DET_RATE),
        JsonInt(NUI_HALIGN_LEFT), JsonInt(NUI_VALIGN_MIDDLE));
    jDetRate = NuiHeight(jDetRate, GetNuiScaleDimension(oPC, 22.0));

    json jBlessBtn = NuiButton(JsonString("Poblogoslaw"));
    jBlessBtn = NuiId(jBlessBtn, INS_BTN_BLESS);
    jBlessBtn = NuiEnabled(jBlessBtn, NuiBind(INS_BIND_BLESS_ENA));
    jBlessBtn = NuiWidth(jBlessBtn, GetNuiScaleDimension(oPC, 120.0));
    jBlessBtn = NuiHeight(jBlessBtn, fBtnH);

    json jBackBtn = NuiButton(JsonString("Wróc do listy"));
    jBackBtn = NuiId(jBackBtn, INS_BTN_BACK_LIST);
    jBackBtn = NuiWidth(jBackBtn, GetNuiScaleDimension(oPC, 120.0));
    jBackBtn = NuiHeight(jBackBtn, fBtnH);

    json jDetBtnRow = JsonArray();
    jDetBtnRow = JsonArrayInsert(jDetBtnRow, jBlessBtn);
    jDetBtnRow = JsonArrayInsert(jDetBtnRow, NuiSpacer());
    jDetBtnRow = JsonArrayInsert(jDetBtnRow, jBackBtn);

    json jDetCol = JsonArray();
    jDetCol = JsonArrayInsert(jDetCol, jDetHdr);
    jDetCol = JsonArrayInsert(jDetCol, jDetTextGrp);
    jDetCol = JsonArrayInsert(jDetCol, jDetRate);
    jDetCol = JsonArrayInsert(jDetCol, NuiRow(jDetBtnRow));

    json jDetGrp = NuiGroup(NuiCol(jDetCol), TRUE, NUI_SCROLLBARS_NONE);
    jDetGrp = NuiHeight(jDetGrp, GetNuiScaleDimension(oPC, 166.0));

    // Assemble read column
    json jCol = JsonArray();
    jCol = JsonArrayInsert(jCol, jList);
    jCol = JsonArrayInsert(jCol, NuiRow(jPagRow));
    jCol = JsonArrayInsert(jCol, jDetGrp);
    return NuiCol(jCol);
}

// ----------------------------------------------------------------
// Write view layout
// ----------------------------------------------------------------

json BuildInsWriteView(object oPC)
{
    float fBtnH = GetNuiScaleDimension(oPC, 28.0);

    json jTypeLbl = NuiLabel(JsonString("Typ inskrypcji:"),
        JsonInt(NUI_HALIGN_LEFT), JsonInt(NUI_VALIGN_MIDDLE));
    jTypeLbl = NuiHeight(jTypeLbl, GetNuiScaleDimension(oPC, 22.0));

    json jTypeBtns = JsonArray();
    int i;
    for(i = 0; i < INS_TYPE_COUNT; i++)
    {
        json jBtn = NuiButton(JsonString(InsTypeName(i)));
        jBtn = NuiId(jBtn, INS_BTN_TYPE_PFX + IntToString(i));
        jBtn = NuiEncouraged(jBtn, NuiBind(INS_BIND_TYPE_ENC + IntToString(i)));
        jBtn = NuiHeight(jBtn, fBtnH);
        jTypeBtns = JsonArrayInsert(jTypeBtns, jBtn);
    }

    json jTxtLbl = NuiLabel(JsonString("Tresc:"),
        JsonInt(NUI_HALIGN_LEFT), JsonInt(NUI_VALIGN_MIDDLE));
    jTxtLbl = NuiHeight(jTxtLbl, GetNuiScaleDimension(oPC, 22.0));

    json jTxtEdit = NuiTextEdit(
        JsonString("Wyryj tu slowa, które przetrwaja próbe czasu..."),
        NuiBind(INS_BIND_WRITE_TXT), INS_TEXT_MAX, TRUE);
    jTxtEdit = NuiHeight(jTxtEdit, GetNuiScaleDimension(oPC, 200.0));

    json jBloodChk = NuiCheck(
        JsonString("Krwawa Inskrypcja (koszt: 10% HP; trwa 3x dluzej; daje czytelnikom +1 Wiedze)"),
        NuiBind(INS_BIND_BLOOD_CHK));
    jBloodChk = NuiHeight(jBloodChk, GetNuiScaleDimension(oPC, 28.0));

    json jCharsLbl = NuiLabel(NuiBind(INS_BIND_CHARS_LBL),
        JsonInt(NUI_HALIGN_RIGHT), JsonInt(NUI_VALIGN_MIDDLE));
    jCharsLbl = NuiHeight(jCharsLbl, GetNuiScaleDimension(oPC, 20.0));

    json jInsBtn = NuiButton(JsonString("Zapisz inskrypcje"));
    jInsBtn = NuiId(jInsBtn, INS_BTN_INSCRIBE);
    jInsBtn = NuiEnabled(jInsBtn, NuiBind(INS_BIND_WRITE_ENA));
    jInsBtn = NuiWidth(jInsBtn, GetNuiScaleDimension(oPC, 180.0));
    jInsBtn = NuiHeight(jInsBtn, GetNuiScaleDimension(oPC, 34.0));

    json jBtnRow = JsonArray();
    jBtnRow = JsonArrayInsert(jBtnRow, NuiSpacer());
    jBtnRow = JsonArrayInsert(jBtnRow, jInsBtn);

    json jCol = JsonArray();
    jCol = JsonArrayInsert(jCol, jTypeLbl);
    jCol = JsonArrayInsert(jCol, NuiRow(jTypeBtns));
    jCol = JsonArrayInsert(jCol, CreateEmptyRow(oPC, 6.0));
    jCol = JsonArrayInsert(jCol, jTxtLbl);
    jCol = JsonArrayInsert(jCol, jTxtEdit);
    jCol = JsonArrayInsert(jCol, jBloodChk);
    jCol = JsonArrayInsert(jCol, jCharsLbl);
    jCol = JsonArrayInsert(jCol, NuiRow(jBtnRow));
    return NuiCol(jCol);
}

// ----------------------------------------------------------------
// Window create / swap
// ----------------------------------------------------------------

void InsOpenWindow(object oPC, object oTablet)
{
    SetLocalString(oPC, INS_LVAR_TABLET,   GetTag(oTablet));
    SetLocalInt   (oPC, INS_LVAR_PAGE,     0);
    SetLocalInt   (oPC, INS_LVAR_SEL_ID,   0);
    SetLocalInt   (oPC, INS_LVAR_SEL_TYPE, INS_TYPE_WARNING);

    if(NuiFindWindow(oPC, INS_WINDOW) != 0)
    {
        int nToken = NuiFindWindow(oPC, INS_WINDOW);
        NuiSetGroupLayout(oPC, nToken, INS_GRP_SWAP, BuildInsReadView(oPC));
        SwapToReadView(oPC, nToken);
        return;
    }

    float fGX = (IntToFloat(GetPlayerDeviceProperty(oPC, PLAYER_DEVICE_PROPERTY_GUI_WIDTH))
                 - GetNuiScaleDimension(oPC, INS_W)) / 2.0;
    float fGY = (IntToFloat(GetPlayerDeviceProperty(oPC, PLAYER_DEVICE_PROPERTY_GUI_HEIGHT))
                 - GetNuiScaleDimension(oPC, INS_H)) / 2.0;
    json jGeom = NuiRect(fGX, fGY,
        GetNuiScaleDimension(oPC, INS_W),
        GetNuiScaleDimension(oPC, INS_H));

    float fBtnH = GetNuiScaleDimension(oPC, 28.0);

    json jReadTab = NuiButton(JsonString("Czytaj"));
    jReadTab = NuiId(jReadTab, INS_BTN_TAB_READ);
    jReadTab = NuiWidth(jReadTab, GetNuiScaleDimension(oPC, 90.0));
    jReadTab = NuiHeight(jReadTab, fBtnH);

    json jWriteTab = NuiButton(JsonString("Zapisz"));
    jWriteTab = NuiId(jWriteTab, INS_BTN_TAB_WRITE);
    jWriteTab = NuiWidth(jWriteTab, GetNuiScaleDimension(oPC, 90.0));
    jWriteTab = NuiHeight(jWriteTab, fBtnH);

    json jCloseBtn = NuiButton(JsonString("X"));
    jCloseBtn = NuiId(jCloseBtn, INS_BTN_CLOSE);
    jCloseBtn = NuiWidth(jCloseBtn, GetNuiScaleDimension(oPC, 30.0));
    jCloseBtn = NuiHeight(jCloseBtn, fBtnH);

    json jTopRow = JsonArray();
    jTopRow = JsonArrayInsert(jTopRow, jReadTab);
    jTopRow = JsonArrayInsert(jTopRow, jWriteTab);
    jTopRow = JsonArrayInsert(jTopRow, NuiSpacer());
    jTopRow = JsonArrayInsert(jTopRow, jCloseBtn);

    json jSwapGrp = NuiGroup(BuildInsReadView(oPC), FALSE, NUI_SCROLLBARS_NONE);
    jSwapGrp = NuiId(jSwapGrp, INS_GRP_SWAP);

    json jRootCol = JsonArray();
    jRootCol = JsonArrayInsert(jRootCol, NuiRow(jTopRow));
    jRootCol = JsonArrayInsert(jRootCol, jSwapGrp);

    json jWin = NuiWindow(NuiCol(jRootCol),
        JsonBool(FALSE),
        NuiBind(INS_WIN_GEOM),
        JsonBool(FALSE),
        JsonBool(FALSE),
        JsonBool(FALSE),
        JsonBool(TRUE),
        JsonBool(FALSE));

    int nToken = NuiCreate(oPC, jWin, INS_WINDOW, INS_EV_SCRIPT);
    NuiSetBind(oPC, nToken, INS_WIN_GEOM, jGeom);
    SwapToReadView(oPC, nToken);
}

void SwapToReadView(object oPC, int nToken)
{
    NuiSetGroupLayout(oPC, nToken, INS_GRP_SWAP, BuildInsReadView(oPC));
    SetLocalInt(oPC, INS_LVAR_SEL_ID, 0);
    FeedInsList  (oPC, nToken);
    FeedInsDetail(oPC, nToken, 0);
    NuiSetBindWatch(oPC, nToken, INS_BIND_WRITE_TXT, FALSE);
}

void SwapToWriteView(object oPC, int nToken)
{
    NuiSetGroupLayout(oPC, nToken, INS_GRP_SWAP, BuildInsWriteView(oPC));
    SetLocalInt(oPC, INS_LVAR_SEL_TYPE, INS_TYPE_WARNING);

    int i;
    for(i = 0; i < INS_TYPE_COUNT; i++)
        NuiSetBind(oPC, nToken, INS_BIND_TYPE_ENC + IntToString(i), JsonBool(i == 0));

    NuiSetBind(oPC, nToken, INS_BIND_WRITE_TXT,  JsonString(""));
    NuiSetBind(oPC, nToken, INS_BIND_BLOOD_CHK,  JsonBool(FALSE));
    NuiSetBind(oPC, nToken, INS_BIND_CHARS_LBL,
        JsonString(IntToString(INS_TEXT_MAX) + "/" + IntToString(INS_TEXT_MAX) + " znaków"));
    NuiSetBind(oPC, nToken, INS_BIND_WRITE_ENA,  JsonBool(FALSE));
    NuiSetBindWatch(oPC, nToken, INS_BIND_WRITE_TXT, TRUE);
}

// ----------------------------------------------------------------
// Feed – list
// ----------------------------------------------------------------

void FeedInsList(object oPC, int nToken)
{
    string sTag  = GetLocalString(oPC, INS_LVAR_TABLET);
    int nPage    = GetLocalInt   (oPC, INS_LVAR_PAGE);
    int nTotal   = InsGetCount(sTag);
    int nPages   = (nTotal + INS_PAGE_SIZE - 1) / INS_PAGE_SIZE;
    if(nPages < 1) nPages = 1;
    if(nPage >= nPages) nPage = nPages - 1;
    if(nPage < 0)       nPage = 0;
    SetLocalInt(oPC, INS_LVAR_PAGE, nPage);

    json jRows  = InsGetPage(sTag, nPage * INS_PAGE_SIZE, INS_PAGE_SIZE);
    int  nCount = JsonGetLength(jRows);
    SetLocalJson(oPC, INS_LVAR_LIST_JSON, jRows);

    json jTypes = JsonArray();
    json jTCols = JsonArray();
    json jAuths = JsonArray();
    json jPrevs = JsonArray();
    json jAges  = JsonArray();
    json jEncs  = JsonArray();

    int nSelId = GetLocalInt(oPC, INS_LVAR_SEL_ID);

    int i;
    for(i = 0; i < nCount; i++)
    {
        json   jRow   = JsonArrayGet(jRows, i);
        int    nId    = JsonGetInt   (JsonObjectGet(jRow, "id"));
        string sAuth  = JsonGetString(JsonObjectGet(jRow, "author_name"));
        string sBody  = JsonGetString(JsonObjectGet(jRow, "body"));
        int    nType  = JsonGetInt   (JsonObjectGet(jRow, "type"));
        int    bBlood = JsonGetInt   (JsonObjectGet(jRow, "is_blood"));
        int    nAt    = JsonGetInt   (JsonObjectGet(jRow, "created_at"));

        string sTypeMark = InsTypeName(nType) + (bBlood ? " [K]" : "");
        jTypes = JsonArrayInsert(jTypes, JsonString(sTypeMark));
        jTCols = JsonArrayInsert(jTCols, InsTypeColor(nType));
        jAuths = JsonArrayInsert(jAuths, JsonString(sAuth));
        jPrevs = JsonArrayInsert(jPrevs, JsonString(InsTruncate(sBody, 38)));
        jAges  = JsonArrayInsert(jAges,  JsonString(InsFormatAge(nAt)));
        jEncs  = JsonArrayInsert(jEncs,  JsonBool(nSelId > 0 && nId == nSelId));
    }

    NuiSetBind(oPC, nToken, INS_BIND_LST_TYPE, jTypes);
    NuiSetBind(oPC, nToken, INS_BIND_LST_TCOL, jTCols);
    NuiSetBind(oPC, nToken, INS_BIND_LST_AUTH, jAuths);
    NuiSetBind(oPC, nToken, INS_BIND_LST_PREV, jPrevs);
    NuiSetBind(oPC, nToken, INS_BIND_LST_AGE,  jAges);
    NuiSetBind(oPC, nToken, INS_BIND_LST_ENC,  jEncs);
    NuiSetBind(oPC, nToken, INS_BIND_LST_CNT,  JsonInt(nCount));

    string sPageLbl = nTotal > 0
        ? "Strona " + IntToString(nPage + 1) + "/" + IntToString(nPages)
        : "Brak inskrypcji na tej tablicy";
    NuiSetBind(oPC, nToken, INS_BIND_PAGE_LBL, JsonString(sPageLbl));
    NuiSetBind(oPC, nToken, INS_BIND_PREV_ENA, JsonBool(nPage > 0));
    NuiSetBind(oPC, nToken, INS_BIND_NEXT_ENA, JsonBool(nPage < nPages - 1 && nTotal > 0));
}

// ----------------------------------------------------------------
// Feed – detail
// ----------------------------------------------------------------

void FeedInsDetail(object oPC, int nToken, int nId)
{
    SetLocalInt(oPC, INS_LVAR_SEL_ID, nId);

    if(nId <= 0)
    {
        NuiSetBind(oPC, nToken, INS_BIND_DET_HDR,   JsonString("Wybierz inskrypcje z listy powyzej."));
        NuiSetBind(oPC, nToken, INS_BIND_DET_TEXT,  JsonString(""));
        NuiSetBind(oPC, nToken, INS_BIND_DET_RATE,  JsonString(""));
        NuiSetBind(oPC, nToken, INS_BIND_BLESS_ENA, JsonBool(FALSE));
        return;
    }

    json jIns = InsGetById(nId);
    if(JsonGetType(jIns) == JSON_TYPE_NULL) return;

    string sAuthorUuid = JsonGetString(JsonObjectGet(jIns, "author_uuid"));
    string sAuthorName = JsonGetString(JsonObjectGet(jIns, "author_name"));
    string sBody       = JsonGetString(JsonObjectGet(jIns, "body"));
    int    nType       = JsonGetInt   (JsonObjectGet(jIns, "type"));
    int    bBlood      = JsonGetInt   (JsonObjectGet(jIns, "is_blood"));
    int    nBless      = JsonGetInt   (JsonObjectGet(jIns, "blessings"));

    string sUuid      = GetObjectUUID(oPC);
    int    bOwn       = (sAuthorUuid == sUuid);
    int    bVoted     = InsHasVoted(nId, sUuid);
    int    bCanBless  = (!bOwn && !bVoted);

    string sBloodTag = bBlood ? "  [Krwawa]" : "";
    string sHdr = InsTypeName(nType) + "  |  " + sAuthorName + sBloodTag;

    NuiSetBind(oPC, nToken, INS_BIND_DET_HDR,   JsonString(sHdr));
    NuiSetBind(oPC, nToken, INS_BIND_DET_TEXT,  JsonString(sBody));
    NuiSetBind(oPC, nToken, INS_BIND_DET_RATE,  JsonString(InsFormatBlessings(nBless)));
    NuiSetBind(oPC, nToken, INS_BIND_BLESS_ENA, JsonBool(bCanBless));

    // Blood inscription bonus: +1 Lore for 1h, stacks up to INS_BLOOD_BONUS_MAX
    if(bBlood && !bOwn && !InsHasReadBonus(nId, sUuid))
    {
        InsMarkReadBonus(nId, sUuid);
        InsApplyBloodBonus(oPC);
    }
}

// ----------------------------------------------------------------
// Actions
// ----------------------------------------------------------------

void InsDoInscribe(object oPC, int nToken)
{
    string sBody = JsonGetString(NuiGetBind(oPC, nToken, INS_BIND_WRITE_TXT));
    if(GetStringLength(sBody) < 3)
    {
        SendMessageToPC(oPC, "[Glos Kamienia] Tresc jest zbyt krótka.");
        return;
    }
    if(GetStringLength(sBody) > INS_TEXT_MAX)
    {
        SendMessageToPC(oPC, "[Glos Kamienia] Tresc przekracza dozwolona dlugosc.");
        return;
    }

    int bBlood = JsonGetInt(NuiGetBind(oPC, nToken, INS_BIND_BLOOD_CHK));
    if(bBlood)
    {
        int nCurHP = GetCurrentHitPoints(oPC);
        int nCost  = (nCurHP * INS_BLOOD_HP_PCT) / 100;
        if(nCost < 1) nCost = 1;
        if(nCurHP <= nCost)
        {
            SendMessageToPC(oPC,
                "[Glos Kamienia] Jestes zbyt ranny, by pisac krwia.");
            return;
        }
        ApplyEffectToObject(DURATION_TYPE_INSTANT,
            EffectDamage(nCost, DAMAGE_TYPE_MAGICAL), oPC);
        ApplyEffectToObject(DURATION_TYPE_INSTANT,
            EffectVisualEffect(VFX_COM_BLOOD_CRT_RED), oPC);
        SendMessageToPC(oPC,
            "[Glos Kamienia] Wyryzujesz slowa wlasna krwia. (" +
            IntToString(nCost) + " HP)");
    }

    int    nType = GetLocalInt   (oPC, INS_LVAR_SEL_TYPE);
    string sTag  = GetLocalString(oPC, INS_LVAR_TABLET);

    InsAdd(sTag, GetObjectUUID(oPC), GetName(oPC), sBody, nType, bBlood);

    string sFlavor;
    switch(nType)
    {
        case INS_TYPE_WARNING:   sFlavor = "Ostrzezenie wyryto w kamieniu. Niechaj zyje wiecznie."; break;
        case INS_TYPE_DISCOVERY: sFlavor = "Odkrycie uwiecznione. Moze inni tez skorzystaja.";       break;
        case INS_TYPE_GUIDANCE:  sFlavor = "Porada wyryta. Wiedza dzielona to wiedza podwojna.";     break;
        case INS_TYPE_MOCKERY:   sFlavor = "Szpila wyryta. Slowa tnac moga ostrze jak miecz.";       break;
        case INS_TYPE_TRIBUTE:   sFlavor = "Hold oddany. Pamiec trwa w kamieniu dluzej niz w sercach."; break;
        default:                 sFlavor = "Inskrypcja wyryta."; break;
    }
    SendMessageToPC(oPC, "[Glos Kamienia] " + sFlavor);
    ApplyEffectToObject(DURATION_TYPE_INSTANT,
        EffectVisualEffect(VFX_IMP_MAGIC_PROTECTION), oPC);

    SetLocalInt(oPC, INS_LVAR_PAGE, 0);
    SwapToReadView(oPC, nToken);
}

void InsDoBless(object oPC, int nToken)
{
    int nId = GetLocalInt(oPC, INS_LVAR_SEL_ID);
    if(nId <= 0) return;

    string sUuid = GetObjectUUID(oPC);
    if(InsHasVoted(nId, sUuid))
    {
        SendMessageToPC(oPC, "[Glos Kamienia] Juz poblogoslawiłes te inskrypcje.");
        return;
    }

    json jIns = InsGetById(nId);
    if(JsonGetType(jIns) != JSON_TYPE_NULL &&
       JsonGetString(JsonObjectGet(jIns, "author_uuid")) == sUuid)
    {
        SendMessageToPC(oPC,
            "[Glos Kamienia] Nie mozesz blogoslawic wlasnej inskrypcji.");
        return;
    }

    InsBless(nId, sUuid);

    int nBless = JsonGetInt(JsonObjectGet(InsGetById(nId), "blessings"));
    string sFlavor = (nBless >= INS_BLESS_PERMANENT)
        ? "[Glos Kamienia] Inskrypcja osiagnela Pieczen Wieczna. Trwa na zawsze."
        : "[Glos Kamienia] Twoje blogoslawienstwo wzmacnia inskrypcje.";
    SendMessageToPC(oPC, sFlavor);

    ApplyEffectToObject(DURATION_TYPE_INSTANT,
        EffectVisualEffect(VFX_IMP_HEAD_HOLY), oPC);

    FeedInsList  (oPC, nToken);
    FeedInsDetail(oPC, nToken, nId);
}

// Grants +1 Lore for INS_BLOOD_BONUS_DUR seconds, up to INS_BLOOD_BONUS_MAX stacks.
void InsApplyBloodBonus(object oPC)
{
    int nStacks = 0;
    effect eChk = GetFirstEffect(oPC);
    while(GetIsEffectValid(eChk))
    {
        if(GetEffectTag(eChk) == "INS_BLOOD_LORE") nStacks++;
        eChk = GetNextEffect(oPC);
    }
    if(nStacks >= INS_BLOOD_BONUS_MAX) return;

    effect eBonus = TagEffect(EffectSkillIncrease(SKILL_LORE, 1), "INS_BLOOD_LORE");
    eBonus = SupernaturalEffect(eBonus);
    ApplyEffectToObject(DURATION_TYPE_TEMPORARY, eBonus, oPC, INS_BLOOD_BONUS_DUR);
    ApplyEffectToObject(DURATION_TYPE_INSTANT,
        EffectVisualEffect(VFX_IMP_HEAD_ODD), oPC);
    SendMessageToPC(oPC,
        "[Glos Kamienia] Krwawa inskrypcja przekazuje ci wiedze. (+1 Wiedza, 1h)");
}
