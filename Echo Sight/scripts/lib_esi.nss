// lib_esi.nss — Echo Sight: NUI construction and core gameplay logic

#include "lib_esi_def"

void EsiOpenCodex(object oPC);
void EsiCloseCodex(object oPC);
void EsiOpenVisionWindow(object oPC, json jPending);
void EsiFeedCodexList(object oPC, int nToken, json jCodex);
void EsiFeedDetail(object oPC, int nToken, string sEchoUuid);
void EsiClearDetail(object oPC, int nToken);
void EsiFeedFooter(object oPC, int nToken);
void EsiHandleEchoUse(object oPC, object oEchoObject);
void EsiDoAbsorb(object oPC, json jPending);
void EsiDoConsume(object oPC, int nCodexToken, string sEchoUuid);

// ----------------------------------------------------------------
// Vision window (popup shown when player first encounters an echo)
// ----------------------------------------------------------------

json EsiBuildVisionWindow(object oPC)
{
    float fW  = GetNuiScaleDimension(oPC, ESI_VISION_W);
    float fH  = GetNuiScaleDimension(oPC, ESI_VISION_H);
    float fBH = GetNuiScaleDimension(oPC, 30.0);
    float fTH = GetNuiScaleDimension(oPC, 22.0);

    // Header row: category badge + title
    json jCatLbl = NuiLabel(NuiBind(ESI_BIND_VIS_CAT), JsonInt(NUI_HALIGN_LEFT), JsonInt(NUI_VALIGN_MIDDLE));
    jCatLbl = NuiWidth(jCatLbl, GetNuiScaleDimension(oPC, 100.0));
    jCatLbl = NuiHeight(jCatLbl, fTH);
    jCatLbl = NuiStyleForegroundColor(jCatLbl, NuiColor(180, 80, 80));

    json jTitleLbl = NuiLabel(NuiBind(ESI_BIND_VIS_TITLE), JsonInt(NUI_HALIGN_LEFT), JsonInt(NUI_VALIGN_MIDDLE));
    jTitleLbl = NuiHeight(jTitleLbl, fTH);
    jTitleLbl = NuiStyleForegroundColor(jTitleLbl, NuiColor(220, 200, 160));

    json jHeaderRow = JsonArray();
    jHeaderRow = JsonArrayInsert(jHeaderRow, jCatLbl);
    jHeaderRow = JsonArrayInsert(jHeaderRow, jTitleLbl);

    // Trauma notice (empty string when no trauma)
    json jTraumaLbl = NuiLabel(NuiBind(ESI_BIND_VIS_TRAUMA), JsonInt(NUI_HALIGN_LEFT), JsonInt(NUI_VALIGN_MIDDLE));
    jTraumaLbl = NuiHeight(jTraumaLbl, fTH);
    jTraumaLbl = NuiStyleForegroundColor(jTraumaLbl, NuiColor(200, 60, 60));

    // Vision text area — NuiText handles long wrapped text; FALSE = read-only
    json jTextWidget = NuiText(NuiBind(ESI_BIND_VIS_TEXT), JsonBool(FALSE));

    json jTextGrp = NuiGroup(jTextWidget, TRUE, NUI_SCROLLBARS_Y);
    jTextGrp = NuiHeight(jTextGrp, GetNuiScaleDimension(oPC, 250.0));

    // Button row
    json jAbsorbBtn = NuiButton(JsonString("Wchłoń Wizję"));
    jAbsorbBtn = NuiId(jAbsorbBtn, ESI_BTN_ABSORB);
    jAbsorbBtn = NuiWidth(jAbsorbBtn, GetNuiScaleDimension(oPC, 160.0));
    jAbsorbBtn = NuiHeight(jAbsorbBtn, fBH);

    json jRejectBtn = NuiButton(JsonString("Odrzuć"));
    jRejectBtn = NuiId(jRejectBtn, ESI_BTN_REJECT);
    jRejectBtn = NuiWidth(jRejectBtn, GetNuiScaleDimension(oPC, 100.0));
    jRejectBtn = NuiHeight(jRejectBtn, fBH);

    json jBtnRow = JsonArray();
    jBtnRow = JsonArrayInsert(jBtnRow, jAbsorbBtn);
    jBtnRow = JsonArrayInsert(jBtnRow, NuiSpacer());
    jBtnRow = JsonArrayInsert(jBtnRow, jRejectBtn);

    // Outer column
    json jOuter = JsonArray();
    jOuter = JsonArrayInsert(jOuter, NuiRow(jHeaderRow));
    jOuter = JsonArrayInsert(jOuter, CreateEmptyRow(oPC, 4.0));
    jOuter = JsonArrayInsert(jOuter, NuiRow(JsonArrayInsert(JsonArray(), jTraumaLbl)));
    jOuter = JsonArrayInsert(jOuter, jTextGrp);
    jOuter = JsonArrayInsert(jOuter, CreateEmptyRow(oPC, 6.0));
    jOuter = JsonArrayInsert(jOuter, NuiRow(jBtnRow));

    json jLayout = NuiCol(jOuter);
    json jGeom   = NuiRect(100.0, 100.0, ESI_VISION_W, ESI_VISION_H);

    return NuiWindow(
        jLayout,
        JsonString("Wizja — Echo Przeszłości"),
        NuiBind(WINDOW_GEOMETRY),
        JsonBool(FALSE),
        JsonBool(FALSE),
        JsonBool(TRUE),
        JsonBool(FALSE),
        JsonBool(TRUE));
}

void EsiOpenVisionWindow(object oPC, json jPending)
{
    int nToken = NuiFindWindow(oPC, ESI_WIN_VISION);
    if(nToken != 0)
        NuiDestroy(oPC, nToken);

    json jRoot  = EsiBuildVisionWindow(oPC);
    nToken = NuiCreate(oPC, jRoot, ESI_WIN_VISION, ESI_EV_SCRIPT);
    if(nToken == 0) return;

    NuiSetBind(oPC, nToken, WINDOW_GEOMETRY,
        NuiRect(80.0, 80.0, ESI_VISION_W, ESI_VISION_H));

    string sTitle    = JsonGetString(JsonObjectGet(jPending, "title"));
    int    nCategory = JsonGetInt   (JsonObjectGet(jPending, "category"));
    string sText     = JsonGetString(JsonObjectGet(jPending, "vision_text"));
    int    nTrauma   = JsonGetInt   (JsonObjectGet(jPending, "trauma"));

    NuiSetBind(oPC, nToken, ESI_BIND_VIS_TITLE, JsonString(sTitle));
    NuiSetBind(oPC, nToken, ESI_BIND_VIS_CAT,   JsonString(EsiCategoryName(nCategory)));
    NuiSetBind(oPC, nToken, ESI_BIND_VIS_TEXT,  JsonString(sText));

    string sTraumaText = nTrauma ? "⚠ Wizja traumatyczna — absorpcja wyrządzi obrażenia." : "";
    NuiSetBind(oPC, nToken, ESI_BIND_VIS_TRAUMA, JsonString(sTraumaText));
}

// ----------------------------------------------------------------
// Codex window construction
// ----------------------------------------------------------------

json EsiBuildCodexListPanel(object oPC)
{
    float fRowH  = GetNuiScaleDimension(oPC, 26.0);
    float fPrefW = GetNuiScaleDimension(oPC, 36.0);
    float fStatW = GetNuiScaleDimension(oPC, 26.0);

    // List item cell (list-bound via NuiList)
    json jPrefixLbl = NuiLabel(NuiBind(ESI_BIND_ROW_CAT), JsonInt(NUI_HALIGN_CENTER), JsonInt(NUI_VALIGN_MIDDLE));
    jPrefixLbl = NuiWidth(jPrefixLbl, fPrefW);
    jPrefixLbl = NuiHeight(jPrefixLbl, fRowH);
    jPrefixLbl = NuiStyleForegroundColor(jPrefixLbl, NuiBind(ESI_BIND_ROW_COLOR));

    json jTitleLbl = NuiLabel(NuiBind(ESI_BIND_ROW_TITLE), JsonInt(NUI_HALIGN_LEFT), JsonInt(NUI_VALIGN_MIDDLE));
    jTitleLbl = NuiHeight(jTitleLbl, fRowH);
    jTitleLbl = NuiStyleForegroundColor(jTitleLbl, NuiBind(ESI_BIND_ROW_COLOR));

    json jStatusLbl = NuiLabel(NuiBind(ESI_BIND_ROW_STATUS), JsonInt(NUI_HALIGN_CENTER), JsonInt(NUI_VALIGN_MIDDLE));
    jStatusLbl = NuiWidth(jStatusLbl, fStatW);
    jStatusLbl = NuiHeight(jStatusLbl, fRowH);
    jStatusLbl = NuiStyleForegroundColor(jStatusLbl, NuiBind(ESI_BIND_ROW_COLOR));

    json jRowCols = JsonArray();
    jRowCols = JsonArrayInsert(jRowCols, NuiWidth(NuiCol(JsonArrayInsert(JsonArray(), jPrefixLbl)), fPrefW));
    jRowCols = JsonArrayInsert(jRowCols, jTitleLbl);
    jRowCols = JsonArrayInsert(jRowCols, NuiWidth(NuiCol(JsonArrayInsert(JsonArray(), jStatusLbl)), fStatW));

    json jCell = NuiGroup(NuiRow(jRowCols), FALSE, NUI_SCROLLBARS_NONE);
    jCell = NuiId(jCell, ESI_BTN_ROW);
    jCell = NuiEncouraged(jCell, NuiBind(ESI_BIND_ROW_ENC));
    jCell = NuiHeight(jCell, fRowH);

    // NuiList requires a template array + a row-count bind
    json jTmpl = JsonArrayInsert(JsonArray(), NuiListTemplateCell(jCell, 0.0, TRUE));
    json jList = NuiList(jTmpl, NuiBind(ESI_BIND_ROW_CNT), fRowH);
    jList = NuiHeight(jList, GetNuiScaleDimension(oPC, 420.0));

    json jListGrp = NuiGroup(jList, TRUE, NUI_SCROLLBARS_NONE);
    jListGrp = NuiWidth(jListGrp, GetNuiScaleDimension(oPC, 280.0));

    return jListGrp;
}

json EsiBuildCodexDetailPanel(object oPC)
{
    float fTH  = GetNuiScaleDimension(oPC, 22.0);
    float fBH  = GetNuiScaleDimension(oPC, 28.0);
    float fTextH = GetNuiScaleDimension(oPC, 220.0);

    // Title
    json jTitle = NuiLabel(NuiBind(ESI_BIND_DET_TITLE), JsonInt(NUI_HALIGN_LEFT), JsonInt(NUI_VALIGN_MIDDLE));
    jTitle = NuiHeight(jTitle, fTH);
    jTitle = NuiStyleForegroundColor(jTitle, NuiColor(220, 200, 160));

    // Category
    json jCat = NuiLabel(NuiBind(ESI_BIND_DET_CAT), JsonInt(NUI_HALIGN_LEFT), JsonInt(NUI_VALIGN_MIDDLE));
    jCat = NuiHeight(jCat, fTH);
    jCat = NuiStyleForegroundColor(jCat, NuiColor(160, 120, 100));

    // Vision text (scrollable) — NuiText wraps long atmospheric descriptions
    json jText = NuiText(NuiBind(ESI_BIND_DET_TEXT), JsonBool(FALSE));

    json jTextGrp = NuiGroup(jText, TRUE, NUI_SCROLLBARS_Y);
    jTextGrp = NuiHeight(jTextGrp, fTextH);

    // Bonus line
    json jBonus = NuiLabel(NuiBind(ESI_BIND_DET_BONUS), JsonInt(NUI_HALIGN_LEFT), JsonInt(NUI_VALIGN_MIDDLE));
    jBonus = NuiHeight(jBonus, fTH);
    jBonus = NuiStyleForegroundColor(jBonus, NuiColor(120, 200, 120));

    // Consume button
    json jConsBtn = NuiButton(NuiBind(ESI_BIND_DET_CONS_LBL));
    jConsBtn = NuiId(jConsBtn, ESI_BTN_CONSUME);
    jConsBtn = NuiEnabled(jConsBtn, NuiBind(ESI_BIND_CONSUME_ENA));
    jConsBtn = NuiHeight(jConsBtn, fBH);
    jConsBtn = NuiWidth(jConsBtn, GetNuiScaleDimension(oPC, 180.0));

    json jBtnRow = JsonArray();
    jBtnRow = JsonArrayInsert(jBtnRow, jConsBtn);
    jBtnRow = JsonArrayInsert(jBtnRow, NuiSpacer());

    json jCol = JsonArray();
    jCol = JsonArrayInsert(jCol, NuiRow(JsonArrayInsert(JsonArray(), jTitle)));
    jCol = JsonArrayInsert(jCol, NuiRow(JsonArrayInsert(JsonArray(), jCat)));
    jCol = JsonArrayInsert(jCol, CreateEmptyRow(oPC, 4.0));
    jCol = JsonArrayInsert(jCol, jTextGrp);
    jCol = JsonArrayInsert(jCol, CreateEmptyRow(oPC, 4.0));
    jCol = JsonArrayInsert(jCol, NuiRow(JsonArrayInsert(JsonArray(), jBonus)));
    jCol = JsonArrayInsert(jCol, CreateEmptyRow(oPC, 4.0));
    jCol = JsonArrayInsert(jCol, NuiRow(jBtnRow));

    json jPanel = NuiGroup(NuiCol(jCol), TRUE, NUI_SCROLLBARS_NONE);
    return jPanel;
}

json EsiBuildCodexWindow(object oPC)
{
    float fBH = GetNuiScaleDimension(oPC, 28.0);
    float fFH = GetNuiScaleDimension(oPC, 22.0);

    // Top bar
    json jHeaderLbl = NuiLabel(JsonString("Kodeks Ech"), JsonInt(NUI_HALIGN_LEFT), JsonInt(NUI_VALIGN_MIDDLE));
    jHeaderLbl = NuiHeight(jHeaderLbl, fBH);
    jHeaderLbl = NuiStyleForegroundColor(jHeaderLbl, NuiColor(210, 185, 140));

    json jCloseBtn = NuiButton(JsonString("Zamknij"));
    jCloseBtn = NuiId(jCloseBtn, ESI_BTN_CLOSE);
    jCloseBtn = NuiWidth(jCloseBtn, GetNuiScaleDimension(oPC, 80.0));
    jCloseBtn = NuiHeight(jCloseBtn, fBH);

    json jTopRow = JsonArray();
    jTopRow = JsonArrayInsert(jTopRow, jHeaderLbl);
    jTopRow = JsonArrayInsert(jTopRow, jCloseBtn);

    // Main body: list on left, detail on right
    json jList   = EsiBuildCodexListPanel(oPC);
    json jDetail = EsiBuildCodexDetailPanel(oPC);

    json jBodyRow = JsonArray();
    jBodyRow = JsonArrayInsert(jBodyRow, jList);
    jBodyRow = JsonArrayInsert(jBodyRow, NuiSpacer());
    jBodyRow = JsonArrayInsert(jBodyRow, jDetail);

    // Footer: echo count
    json jCountLbl = NuiLabel(NuiBind(ESI_BIND_COUNT), JsonInt(NUI_HALIGN_LEFT), JsonInt(NUI_VALIGN_MIDDLE));
    jCountLbl = NuiHeight(jCountLbl, fFH);
    jCountLbl = NuiStyleForegroundColor(jCountLbl, NuiColor(140, 120, 90));

    json jOuter = JsonArray();
    jOuter = JsonArrayInsert(jOuter, NuiRow(jTopRow));
    jOuter = JsonArrayInsert(jOuter, CreateEmptyRow(oPC, 4.0));
    jOuter = JsonArrayInsert(jOuter, NuiRow(jBodyRow));
    jOuter = JsonArrayInsert(jOuter, CreateEmptyRow(oPC, 4.0));
    jOuter = JsonArrayInsert(jOuter, NuiRow(JsonArrayInsert(JsonArray(), jCountLbl)));

    json jLayout = NuiCol(jOuter);

    return NuiWindow(
        jLayout,
        JsonString("Kodeks Ech — Echo Sight"),
        NuiBind(WINDOW_GEOMETRY),
        JsonBool(TRUE),
        JsonBool(FALSE),
        JsonBool(TRUE),
        JsonBool(FALSE),
        JsonBool(TRUE));
}

// ----------------------------------------------------------------
// Feed functions
// ----------------------------------------------------------------

void EsiFeedCodexList(object oPC, int nToken, json jCodex)
{
    int nCount = JsonGetLength(jCodex);

    json jTitles   = JsonArray();
    json jCats     = JsonArray();
    json jStatuses = JsonArray();
    json jColors   = JsonArray();
    json jEncs     = JsonArray();

    int i;
    for(i = 0; i < nCount; i++)
    {
        json   jE       = JsonArrayGet(jCodex, i);
        string sTitle   = JsonGetString(JsonObjectGet(jE, "title"));
        int    nCat     = JsonGetInt   (JsonObjectGet(jE, "category"));
        int    nConsumed= JsonGetInt   (JsonObjectGet(jE, "consumed"));

        jTitles   = JsonArrayInsert(jTitles,   JsonString(sTitle));
        jCats     = JsonArrayInsert(jCats,     JsonString(EsiCategoryPrefix(nCat)));
        jStatuses = JsonArrayInsert(jStatuses, JsonString(nConsumed ? "✓" : "·"));
        jEncs     = JsonArrayInsert(jEncs,     JsonBool(FALSE));

        json jColor = nConsumed ? NuiColor(100, 90, 80) : NuiColor(200, 185, 155);
        jColors = JsonArrayInsert(jColors, jColor);
    }

    NuiSetBind(oPC, nToken, ESI_BIND_ROW_TITLE,  jTitles);
    NuiSetBind(oPC, nToken, ESI_BIND_ROW_CAT,    jCats);
    NuiSetBind(oPC, nToken, ESI_BIND_ROW_STATUS, jStatuses);
    NuiSetBind(oPC, nToken, ESI_BIND_ROW_COLOR,  jColors);
    NuiSetBind(oPC, nToken, ESI_BIND_ROW_ENC,    jEncs);
    NuiSetBind(oPC, nToken, ESI_BIND_ROW_CNT,    JsonInt(nCount));
}

void EsiFeedDetail(object oPC, int nToken, string sEchoUuid)
{
    json jEcho = EsiGetEchoDetail(oPC, sEchoUuid);
    if(JsonGetType(jEcho) == JSON_TYPE_NULL)
    {
        EsiClearDetail(oPC, nToken);
        return;
    }

    string sTitle    = JsonGetString(JsonObjectGet(jEcho, "title"));
    int    nCategory = JsonGetInt   (JsonObjectGet(jEcho, "category"));
    string sText     = JsonGetString(JsonObjectGet(jEcho, "vision_text"));
    int    nBonusType= JsonGetInt   (JsonObjectGet(jEcho, "bonus_type"));
    int    nBonusVal = JsonGetInt   (JsonObjectGet(jEcho, "bonus_val"));
    int    nConsumed = JsonGetInt   (JsonObjectGet(jEcho, "consumed"));

    NuiSetBind(oPC, nToken, ESI_BIND_DET_TITLE,   JsonString(sTitle));
    NuiSetBind(oPC, nToken, ESI_BIND_DET_CAT,     JsonString(EsiCategoryName(nCategory)));
    NuiSetBind(oPC, nToken, ESI_BIND_DET_TEXT,    JsonString(sText));
    NuiSetBind(oPC, nToken, ESI_BIND_DET_BONUS,   JsonString(EsiBonusDescription(nBonusType, nBonusVal)));

    string sConsLabel = nConsumed ? "Pochłonięta" : "Pochłoń Echo";
    NuiSetBind(oPC, nToken, ESI_BIND_DET_CONS_LBL, JsonString(sConsLabel));
    NuiSetBind(oPC, nToken, ESI_BIND_CONSUME_ENA,  JsonBool(!nConsumed && nBonusType != ESI_BONUS_NONE));
}

void EsiClearDetail(object oPC, int nToken)
{
    NuiSetBind(oPC, nToken, ESI_BIND_DET_TITLE,    JsonString(""));
    NuiSetBind(oPC, nToken, ESI_BIND_DET_CAT,      JsonString(""));
    NuiSetBind(oPC, nToken, ESI_BIND_DET_TEXT,     JsonString("Wybierz wizję z listy, by przeczytać jej treść."));
    NuiSetBind(oPC, nToken, ESI_BIND_DET_BONUS,    JsonString(""));
    NuiSetBind(oPC, nToken, ESI_BIND_DET_CONS_LBL, JsonString("Pochłoń Echo"));
    NuiSetBind(oPC, nToken, ESI_BIND_CONSUME_ENA,  JsonBool(FALSE));
}

void EsiFeedFooter(object oPC, int nToken)
{
    int nTotal    = EsiGetAbsorbedCount(oPC);
    int nConsumed = EsiGetConsumedCount(oPC);
    NuiSetBind(oPC, nToken, ESI_BIND_COUNT,
        JsonString("Wchłonięte: " + IntToString(nTotal) + "/" + IntToString(ESI_MAX_ECHOES)
                   + "   Pochłonięte: " + IntToString(nConsumed)));
}

// ----------------------------------------------------------------
// Window lifecycle
// ----------------------------------------------------------------

void EsiOpenCodex(object oPC)
{
    int nToken = NuiFindWindow(oPC, ESI_WIN_CODEX);
    if(nToken != 0)
    {
        NuiDestroy(oPC, nToken);
    }

    json jRoot = EsiBuildCodexWindow(oPC);
    nToken = NuiCreate(oPC, jRoot, ESI_WIN_CODEX, ESI_EV_SCRIPT);
    if(nToken == 0) return;

    NuiSetBind(oPC, nToken, WINDOW_GEOMETRY,
        NuiRect(60.0, 60.0, ESI_CODEX_W, ESI_CODEX_H));

    json jCodex = EsiGetCodex(oPC);
    EsiFeedCodexList(oPC, nToken, jCodex);
    EsiClearDetail(oPC, nToken);
    EsiFeedFooter(oPC, nToken);
}

void EsiCloseCodex(object oPC)
{
    int nToken = NuiFindWindow(oPC, ESI_WIN_CODEX);
    if(nToken != 0)
        NuiDestroy(oPC, nToken);
}

// ----------------------------------------------------------------
// Core gameplay: absorbing an echo
// ----------------------------------------------------------------

void EsiDoAbsorb(object oPC, json jPending)
{
    string sEchoUuid  = JsonGetString(JsonObjectGet(jPending, "echo_uuid"));
    string sTitle     = JsonGetString(JsonObjectGet(jPending, "title"));
    string sText      = JsonGetString(JsonObjectGet(jPending, "vision_text"));
    int    nCategory  = JsonGetInt   (JsonObjectGet(jPending, "category"));
    string sFlavor    = JsonGetString(JsonObjectGet(jPending, "flavor"));
    int    nBonusType = JsonGetInt   (JsonObjectGet(jPending, "bonus_type"));
    int    nBonusVal  = JsonGetInt   (JsonObjectGet(jPending, "bonus_val"));
    int    nTrauma    = JsonGetInt   (JsonObjectGet(jPending, "trauma"));

    if(EsiHasAbsorbed(oPC, sEchoUuid))
    {
        SendMessageToPC(oPC, "[Echo] Wizja ta jest już zapisana w twoim Kodeksie.");
        return;
    }

    int nCurrentCount = EsiGetAbsorbedCount(oPC);
    if(nCurrentCount >= ESI_MAX_ECHOES)
    {
        SendMessageToPC(oPC, "[Echo] Twój Kodeks jest pełny. Pochłoń starsze echa, by zrobić miejsce.");
        return;
    }

    EsiAbsorbEcho(oPC, sEchoUuid, sTitle, sText, nCategory, sFlavor, nBonusType, nBonusVal, nTrauma);

    if(nTrauma)
    {
        int nDmg = d4(1);
        // Negative energy approximates psychic trauma; NWN:EE has no dedicated psychic type
        effect eDmg = EffectDamage(nDmg, DAMAGE_TYPE_NEGATIVE);
        ApplyEffectToObject(DURATION_TYPE_INSTANT, eDmg, oPC);
        SendMessageToPC(oPC, "[Echo] Pieczęć bólu rozdziera twój umysł... Pochłonięto (" + IntToString(nDmg) + " obrażeń).");
    }
    else
    {
        SendMessageToPC(oPC, "[Echo] Wizja " + sTitle + " zastyga w twojej pamięci.");
    }

    // Refresh codex if open
    int nCodexToken = NuiFindWindow(oPC, ESI_WIN_CODEX);
    if(nCodexToken != 0)
    {
        json jCodex = EsiGetCodex(oPC);
        EsiFeedCodexList(oPC, nCodexToken, jCodex);
        EsiFeedFooter(oPC, nCodexToken);
    }
}

// ----------------------------------------------------------------
// Core gameplay: consuming an echo for its bonus
// ----------------------------------------------------------------

void EsiDoConsume(object oPC, int nCodexToken, string sEchoUuid)
{
    json jEcho = EsiGetEchoDetail(oPC, sEchoUuid);
    if(JsonGetType(jEcho) == JSON_TYPE_NULL) return;

    int nConsumed = JsonGetInt(JsonObjectGet(jEcho, "consumed"));
    if(nConsumed) return;

    int nBonusType = JsonGetInt(JsonObjectGet(jEcho, "bonus_type"));
    int nBonusVal  = JsonGetInt(JsonObjectGet(jEcho, "bonus_val"));
    string sTitle  = JsonGetString(JsonObjectGet(jEcho, "title"));

    EsiConsumeEcho(oPC, sEchoUuid);

    if(nBonusType != ESI_BONUS_NONE)
    {
        EsiInsertActiveBonus(oPC, sEchoUuid, nBonusType, nBonusVal);
        EsiApplyBonus(oPC, nBonusType, nBonusVal);
        SendMessageToPC(oPC, "[Echo] Pochłaniasz wizję \"" + sTitle + "\" — " + EsiBonusDescription(nBonusType, nBonusVal) + " (trwale).");
    }
    else
    {
        SendMessageToPC(oPC, "[Echo] Pochłaniasz wizję \"" + sTitle + "\". Pamięć rozpływa się w ciemności.");
    }

    // Refresh list and detail
    if(nCodexToken != 0)
    {
        json jCodex = EsiGetCodex(oPC);
        EsiFeedCodexList(oPC, nCodexToken, jCodex);
        EsiFeedDetail(oPC, nCodexToken, sEchoUuid);
        EsiFeedFooter(oPC, nCodexToken);
    }
}

// ----------------------------------------------------------------
// Activation: called when PC uses an echo placeable
// ----------------------------------------------------------------

void EsiHandleEchoUse(object oPC, object oEchoObject)
{
    string sEchoUuid = GetObjectUUID(oEchoObject);

    if(EsiHasAbsorbed(oPC, sEchoUuid))
    {
        SendMessageToPC(oPC, "[Echo] Pamiętasz już tę wizję — otwórz Kodeks Ech, by ją przejrzeć.");
        return;
    }

    string sTitle  = GetLocalString(oEchoObject, ESI_VAR_TITLE);
    string sText   = GetLocalString(oEchoObject, ESI_VAR_TEXT);
    int nCategory  = GetLocalInt   (oEchoObject, ESI_VAR_CATEGORY);
    int nDC        = GetLocalInt   (oEchoObject, ESI_VAR_DC);
    int nBonusType = GetLocalInt   (oEchoObject, ESI_VAR_BONUS_TYPE);
    int nBonusVal  = GetLocalInt   (oEchoObject, ESI_VAR_BONUS_VAL);
    int nTrauma    = GetLocalInt   (oEchoObject, ESI_VAR_TRAUMA);
    string sFlavor = GetLocalString(oEchoObject, ESI_VAR_FLAVOR);

    if(sTitle == "") sTitle = "Nieznana Wizja";
    if(sText  == "") sText  = "Mglisty obraz przemyka przez twój umysł... lecz szybko blednie, nie zostawiając śladu.";

    // Spot check
    if(nDC > 0)
    {
        int nSpot = GetSkillRank(SKILL_SPOT, oPC) + d20();
        if(nSpot < nDC)
        {
            SendMessageToPC(oPC, "[Echo] Nie dostrzegasz niczego niezwykłego w tym miejscu.");
            return;
        }
    }

    // Store pending data on PC and open vision window
    json jPending = JsonObject();
    jPending = JsonObjectSet(jPending, "echo_uuid",   JsonString(sEchoUuid));
    jPending = JsonObjectSet(jPending, "title",       JsonString(sTitle));
    jPending = JsonObjectSet(jPending, "vision_text", JsonString(sText));
    jPending = JsonObjectSet(jPending, "category",    JsonInt   (nCategory));
    jPending = JsonObjectSet(jPending, "flavor",      JsonString(sFlavor));
    jPending = JsonObjectSet(jPending, "bonus_type",  JsonInt   (nBonusType));
    jPending = JsonObjectSet(jPending, "bonus_val",   JsonInt   (nBonusVal));
    jPending = JsonObjectSet(jPending, "trauma",      JsonInt   (nTrauma));

    SetLocalJson(oPC, ESI_LVAR_PENDING, jPending);

    EsiOpenVisionWindow(oPC, jPending);
}
