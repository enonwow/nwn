#include "lib_vend_def"

// NUI layout forward declarations
json BuildVendMainView(object oPC);
void CreateVendConfirmPopup(object oPC, int nGrudgeId, string sWrongdoerName);

// ================================================================
// Effect management
// ================================================================

// Removes all Fury and Resentment passive effects from oPC.
// Uses restart-on-remove to safely iterate a live effect list.
void VendRemovePassiveEffects(object oPC)
{
    int bFound = TRUE;
    while (bFound)
    {
        bFound = FALSE;
        effect e = GetFirstEffect(oPC);
        while (GetIsEffectValid(e))
        {
            string sTag = GetEffectTag(e);
            if (sTag == VEND_TAG_FURY || sTag == VEND_TAG_RESENT)
            {
                RemoveEffect(oPC, e);
                bFound = TRUE;
                break;
            }
            e = GetNextEffect(oPC);
        }
    }
}

void ApplyVendEffects(object oPC)
{
    VendRemovePassiveEffects(oPC);

    int nActive  = VendGetActiveCount(oPC);
    int nOverdue = VendGetOverdueCount(oPC);
    int nFury    = nActive  < VEND_MAX_FURY   ? nActive  : VEND_MAX_FURY;
    int nResent  = nOverdue < VEND_MAX_RESENT  ? nOverdue : VEND_MAX_RESENT;

    if (nFury > 0)
    {
        effect eAtk = TagEffect(EffectAttackIncrease(nFury), VEND_TAG_FURY);
        effect eDmg = TagEffect(EffectDamageIncrease(nFury, DAMAGE_TYPE_MAGICAL), VEND_TAG_FURY);
        ApplyEffectToObject(DURATION_TYPE_PERMANENT, eAtk, oPC);
        ApplyEffectToObject(DURATION_TYPE_PERMANENT, eDmg, oPC);
    }

    if (nResent > 0)
    {
        effect eAC = TagEffect(EffectACDecrease(nResent), VEND_TAG_RESENT);
        ApplyEffectToObject(DURATION_TYPE_PERMANENT, eAC, oPC);
    }
}

// ================================================================
// Public API
// ================================================================

// Adds a grudge entry for oVictim against oWrongdoer.
// No-ops if an active grudge of the same type already exists between this pair.
void VendAddGrudge(object oVictim, object oWrongdoer, int nWrongType, string sItemTag)
{
    if (!GetIsObjectValid(oVictim) || !GetIsObjectValid(oWrongdoer)) return;
    if (oVictim == oWrongdoer) return;

    string sVictimUuid    = GetObjectUUID(oVictim);
    string sWrongdoerUuid = GetObjectUUID(oWrongdoer);
    string sWrongdoerName = GetName(oWrongdoer);

    if (VendHasActiveGrudge(sVictimUuid, sWrongdoerUuid, nWrongType)) return;

    VendAddGrudgeDB(sVictimUuid, sWrongdoerUuid, sWrongdoerName, nWrongType, sItemTag);

    SendMessageToPC(oVictim,
        "[Księga Krzywd] " + sWrongdoerName +
        " wpisany do Księgi: " + VendWrongTypeName(nWrongType) + ".");
    FloatingTextStringOnCreature("Krew woła o zemstę...", oVictim, FALSE);

    ApplyVendEffects(oVictim);

    int nToken = NuiFindWindow(oVictim, VEND_WINDOW);
    if (nToken != 0) FeedVendWindow(oVictim, nToken);
}

// Call after oAvenger kills oWrongdoer.
// Fulfills any active grudges oAvenger held against oWrongdoer and rewards them.
void VendCheckFulfillment(object oAvenger, object oWrongdoer)
{
    if (!GetIsObjectValid(oAvenger) || !GetIsObjectValid(oWrongdoer)) return;

    string sAvengerUuid   = GetObjectUUID(oAvenger);
    string sWrongdoerUuid = GetObjectUUID(oWrongdoer);
    int    nFulfilled     = VendFulfillGrudgesAgainst(sAvengerUuid, sWrongdoerUuid);
    if (nFulfilled <= 0) return;

    // Vengeance Fulfilled: +2 AB, +2 magical damage, +2 all saves for 1h
    effect eAtk  = EffectAttackIncrease(2);
    effect eDmg  = EffectDamageIncrease(2, DAMAGE_TYPE_MAGICAL);
    effect eSave = EffectSavingThrowIncrease(SAVING_THROW_ALL, 2, SAVING_THROW_TYPE_ALL);
    effect eFull = EffectLinkEffects(eAtk, EffectLinkEffects(eDmg, eSave));
    eFull = TagEffect(eFull, VEND_TAG_FULFILL);
    ApplyEffectToObject(DURATION_TYPE_TEMPORARY, eFull, oAvenger, IntToFloat(VEND_FULFILL_DURATION));

    SendMessageToPC(oAvenger,
        "[Księga Krzywd] Zemsta spełniona! Krew została zmyta krwią. (" +
        IntToString(nFulfilled) + " wpisów rozliczono)");
    FloatingTextStringOnCreature("Zemsta!", oAvenger, FALSE);

    ApplyVendEffects(oAvenger);

    int nToken = NuiFindWindow(oAvenger, VEND_WINDOW);
    if (nToken != 0) FeedVendWindow(oAvenger, nToken);
}

// ================================================================
// Feed functions
// ================================================================

void FeedVendActiveList(object oPC, int nToken)
{
    json jActive  = VendGetActiveGrudges(oPC);
    int  nCount   = JsonGetLength(jActive);

    // Derive active/overdue counts from the already-fetched rows
    int nActive  = nCount;
    int nOverdue = 0;
    int k;
    for (k = 0; k < nCount; k++)
    {
        if (JsonGetInt(JsonObjectGet(JsonArrayGet(jActive, k), "is_overdue")))
            nOverdue++;
    }

    int  nFury    = nActive  < VEND_MAX_FURY  ? nActive  : VEND_MAX_FURY;
    int  nResent  = nOverdue < VEND_MAX_RESENT ? nOverdue : VEND_MAX_RESENT;

    string sFuryLbl   = "Furia:  +" + IntToString(nFury)   + " AB / +" + IntToString(nFury)   + " OBR";
    string sResentLbl = "Żal:  -"   + IntToString(nResent) + " PP";

    json jFuryColor   = nFury   > 0 ? NuiColor(210, 150,  60) : NuiColor(100, 100, 100);
    json jResentColor = nResent > 0 ? NuiColor(190,  50,  50) : NuiColor(100, 100, 100);

    NuiSetBind(oPC, nToken, VEND_BIND_FURY_LBL,    JsonString(sFuryLbl));
    NuiSetBind(oPC, nToken, VEND_BIND_FURY_COLOR,  jFuryColor);
    NuiSetBind(oPC, nToken, VEND_BIND_RESENT_LBL,  JsonString(sResentLbl));
    NuiSetBind(oPC, nToken, VEND_BIND_RESENT_COLOR, jResentColor);

    json jNames    = JsonArray();
    json jTypes    = JsonArray();
    json jDates    = JsonArray();
    json jODs      = JsonArray();
    json jODColors = JsonArray();
    json jEncs     = JsonArray();

    int  nSelId  = GetLocalInt(oPC, VEND_LVAR_SEL_ID);
    json jRed    = NuiColor(200, 50, 50);
    json jGray   = NuiColor(80, 80, 80);

    int i;
    for (i = 0; i < nCount; i++)
    {
        json   jRow   = JsonArrayGet(jActive, i);
        int    nId    = JsonGetInt(JsonObjectGet(jRow, "id"));
        int    nType  = JsonGetInt(JsonObjectGet(jRow, "wrong_type"));
        int    nTs    = JsonGetInt(JsonObjectGet(jRow, "created_at"));
        int    nOD    = JsonGetInt(JsonObjectGet(jRow, "is_overdue"));

        jNames    = JsonArrayInsert(jNames,    JsonString(JsonGetString(JsonObjectGet(jRow, "wrongdoer_name"))));
        jTypes    = JsonArrayInsert(jTypes,    JsonString(VendWrongTypeName(nType)));
        jDates    = JsonArrayInsert(jDates,    JsonString(VendFormatDate(nTs)));
        jODs      = JsonArrayInsert(jODs,      JsonString(nOD ? "!" : ""));
        jODColors = JsonArrayInsert(jODColors, nOD ? jRed : jGray);
        jEncs     = JsonArrayInsert(jEncs,     JsonBool(nSelId != 0 && nId == nSelId));
    }

    NuiSetBind(oPC, nToken, VEND_BIND_ACT_NAME,    jNames);
    NuiSetBind(oPC, nToken, VEND_BIND_ACT_TYPE,    jTypes);
    NuiSetBind(oPC, nToken, VEND_BIND_ACT_DATE,    jDates);
    NuiSetBind(oPC, nToken, VEND_BIND_ACT_OD,      jODs);
    NuiSetBind(oPC, nToken, VEND_BIND_ACT_ODCOLOR, jODColors);
    NuiSetBind(oPC, nToken, VEND_BIND_ACT_ENC,     jEncs);
    NuiSetBind(oPC, nToken, VEND_BIND_ACT_COUNT,   JsonInt(nCount));
    NuiSetBind(oPC, nToken, VEND_BIND_FORSW_ENA,   JsonBool(nSelId != 0));
}

void FeedVendHistoryList(object oPC, int nToken)
{
    json jHistory = VendGetHistoryGrudges(oPC);
    int  nCount   = JsonGetLength(jHistory);

    json jNames    = JsonArray();
    json jTypes    = JsonArray();
    json jDates    = JsonArray();
    json jStatuses = JsonArray();
    json jColors   = JsonArray();

    json jGreen = NuiColor(70, 180, 70);
    json jGray  = NuiColor(100, 100, 100);

    int i;
    for (i = 0; i < nCount; i++)
    {
        json   jRow    = JsonArrayGet(jHistory, i);
        int    nType   = JsonGetInt(JsonObjectGet(jRow, "wrong_type"));
        int    nStatus = JsonGetInt(JsonObjectGet(jRow, "status"));
        int    nTs     = nStatus == 1
            ? JsonGetInt(JsonObjectGet(jRow, "fulfilled_at"))
            : JsonGetInt(JsonObjectGet(jRow, "forsworn_at"));
        string sStatus = nStatus == 1 ? "Zemsta" : "Wybaczone";

        jNames    = JsonArrayInsert(jNames,    JsonString(JsonGetString(JsonObjectGet(jRow, "wrongdoer_name"))));
        jTypes    = JsonArrayInsert(jTypes,    JsonString(VendWrongTypeName(nType)));
        jDates    = JsonArrayInsert(jDates,    JsonString(VendFormatDate(nTs)));
        jStatuses = JsonArrayInsert(jStatuses, JsonString(sStatus));
        jColors   = JsonArrayInsert(jColors,   nStatus == 1 ? jGreen : jGray);
    }

    NuiSetBind(oPC, nToken, VEND_BIND_HIS_NAME,   jNames);
    NuiSetBind(oPC, nToken, VEND_BIND_HIS_TYPE,   jTypes);
    NuiSetBind(oPC, nToken, VEND_BIND_HIS_DATE,   jDates);
    NuiSetBind(oPC, nToken, VEND_BIND_HIS_STATUS, jStatuses);
    NuiSetBind(oPC, nToken, VEND_BIND_HIS_COLOR,  jColors);
    NuiSetBind(oPC, nToken, VEND_BIND_HIS_COUNT,  JsonInt(nCount));
}

void FeedVendWindow(object oPC, int nToken)
{
    FeedVendActiveList(oPC, nToken);
    FeedVendHistoryList(oPC, nToken);
}

// ================================================================
// NUI layout
// ================================================================

json BuildVendMainView(object oPC)
{
    float fBtnH   = GetNuiScaleDimension(oPC, 28.0);
    float fRowH   = GetNuiScaleDimension(oPC, 26.0);
    float fSmH    = GetNuiScaleDimension(oPC, 22.0);
    float fListH  = GetNuiScaleDimension(oPC, 158.0);
    float fHisH   = GetNuiScaleDimension(oPC, 106.0);

    float fColName = GetNuiScaleDimension(oPC, 172.0);
    float fColType = GetNuiScaleDimension(oPC, 90.0);
    float fColDate = GetNuiScaleDimension(oPC, 58.0);
    float fColOD   = GetNuiScaleDimension(oPC, 18.0);
    float fColStat = GetNuiScaleDimension(oPC, 78.0);

    // --- Status bar ---
    json jFuryLbl = NuiLabel(NuiBind(VEND_BIND_FURY_LBL), JsonInt(NUI_HALIGN_LEFT), JsonInt(NUI_VALIGN_MIDDLE));
    jFuryLbl = NuiStyleForegroundColor(jFuryLbl, NuiBind(VEND_BIND_FURY_COLOR));

    json jResentLbl = NuiLabel(NuiBind(VEND_BIND_RESENT_LBL), JsonInt(NUI_HALIGN_RIGHT), JsonInt(NUI_VALIGN_MIDDLE));
    jResentLbl = NuiStyleForegroundColor(jResentLbl, NuiBind(VEND_BIND_RESENT_COLOR));

    json jStatusRow = JsonArray();
    jStatusRow = JsonArrayInsert(jStatusRow, jFuryLbl);
    jStatusRow = JsonArrayInsert(jStatusRow, NuiSpacer());
    jStatusRow = JsonArrayInsert(jStatusRow, jResentLbl);

    // --- Active grudge list row template ---
    json jActName = NuiLabel(NuiBind(VEND_BIND_ACT_NAME), JsonInt(NUI_HALIGN_LEFT), JsonInt(NUI_VALIGN_MIDDLE));
    jActName = NuiWidth(jActName, fColName);

    json jActType = NuiLabel(NuiBind(VEND_BIND_ACT_TYPE), JsonInt(NUI_HALIGN_LEFT), JsonInt(NUI_VALIGN_MIDDLE));
    jActType = NuiWidth(jActType, fColType);

    json jActDate = NuiLabel(NuiBind(VEND_BIND_ACT_DATE), JsonInt(NUI_HALIGN_CENTER), JsonInt(NUI_VALIGN_MIDDLE));
    jActDate = NuiWidth(jActDate, fColDate);

    json jActOD = NuiLabel(NuiBind(VEND_BIND_ACT_OD), JsonInt(NUI_HALIGN_CENTER), JsonInt(NUI_VALIGN_MIDDLE));
    jActOD = NuiStyleForegroundColor(jActOD, NuiBind(VEND_BIND_ACT_ODCOLOR));
    jActOD = NuiWidth(jActOD, fColOD);

    json jActCells = JsonArray();
    jActCells = JsonArrayInsert(jActCells, jActName);
    jActCells = JsonArrayInsert(jActCells, jActType);
    jActCells = JsonArrayInsert(jActCells, jActDate);
    jActCells = JsonArrayInsert(jActCells, jActOD);

    json jActCell = NuiGroup(NuiRow(jActCells), TRUE, NUI_SCROLLBARS_NONE);
    jActCell = NuiId(jActCell, VEND_BTN_ROW_ACT);
    jActCell = NuiEncouraged(jActCell, NuiBind(VEND_BIND_ACT_ENC));

    json jActTmpl = JsonArrayInsert(JsonArray(), NuiListTemplateCell(jActCell, 0.0, TRUE));
    json jActList = NuiList(jActTmpl, NuiBind(VEND_BIND_ACT_COUNT), fRowH);
    jActList = NuiHeight(jActList, fListH);

    // Forswear action row
    json jForswBtn = NuiButton(JsonString("Wyrzeknij się krzywdy"));
    jForswBtn = NuiId(jForswBtn, VEND_BTN_FORSWEAR);
    jForswBtn = NuiEnabled(jForswBtn, NuiBind(VEND_BIND_FORSW_ENA));
    jForswBtn = NuiWidth(jForswBtn, GetNuiScaleDimension(oPC, 200.0));
    jForswBtn = NuiHeight(jForswBtn, fBtnH);

    json jForswRow = JsonArray();
    jForswRow = JsonArrayInsert(jForswRow, NuiSpacer());
    jForswRow = JsonArrayInsert(jForswRow, jForswBtn);

    // --- History list row template ---
    json jHisName = NuiLabel(NuiBind(VEND_BIND_HIS_NAME), JsonInt(NUI_HALIGN_LEFT), JsonInt(NUI_VALIGN_MIDDLE));
    jHisName = NuiWidth(jHisName, fColName);
    jHisName = NuiStyleForegroundColor(jHisName, NuiBind(VEND_BIND_HIS_COLOR));

    json jHisType = NuiLabel(NuiBind(VEND_BIND_HIS_TYPE), JsonInt(NUI_HALIGN_LEFT), JsonInt(NUI_VALIGN_MIDDLE));
    jHisType = NuiWidth(jHisType, fColType);
    jHisType = NuiStyleForegroundColor(jHisType, NuiBind(VEND_BIND_HIS_COLOR));

    json jHisDate = NuiLabel(NuiBind(VEND_BIND_HIS_DATE), JsonInt(NUI_HALIGN_CENTER), JsonInt(NUI_VALIGN_MIDDLE));
    jHisDate = NuiWidth(jHisDate, fColDate);
    jHisDate = NuiStyleForegroundColor(jHisDate, NuiBind(VEND_BIND_HIS_COLOR));

    json jHisStat = NuiLabel(NuiBind(VEND_BIND_HIS_STATUS), JsonInt(NUI_HALIGN_CENTER), JsonInt(NUI_VALIGN_MIDDLE));
    jHisStat = NuiWidth(jHisStat, fColStat);
    jHisStat = NuiStyleForegroundColor(jHisStat, NuiBind(VEND_BIND_HIS_COLOR));

    json jHisCells = JsonArray();
    jHisCells = JsonArrayInsert(jHisCells, jHisName);
    jHisCells = JsonArrayInsert(jHisCells, jHisType);
    jHisCells = JsonArrayInsert(jHisCells, jHisDate);
    jHisCells = JsonArrayInsert(jHisCells, jHisStat);

    json jHisCell = NuiGroup(NuiRow(jHisCells), TRUE, NUI_SCROLLBARS_NONE);

    json jHisTmpl = JsonArrayInsert(JsonArray(), NuiListTemplateCell(jHisCell, 0.0, TRUE));
    json jHisList = NuiList(jHisTmpl, NuiBind(VEND_BIND_HIS_COUNT), fSmH);
    jHisList = NuiHeight(jHisList, fHisH);

    // Section headers
    json jActHdr = NuiLabel(JsonString("— Aktywne Krzywdy —"), JsonInt(NUI_HALIGN_LEFT), JsonInt(NUI_VALIGN_MIDDLE));
    jActHdr = NuiStyleForegroundColor(jActHdr, NuiColor(180, 60, 60));

    json jHisHdr = NuiLabel(JsonString("— Historia —"), JsonInt(NUI_HALIGN_LEFT), JsonInt(NUI_VALIGN_MIDDLE));
    jHisHdr = NuiStyleForegroundColor(jHisHdr, NuiColor(110, 110, 110));

    // Main column assembly
    json jCol = JsonArray();
    jCol = JsonArrayInsert(jCol, NuiRow(jStatusRow));
    jCol = JsonArrayInsert(jCol, CreateEmptyRow(oPC, 6.0));
    jCol = JsonArrayInsert(jCol, jActHdr);
    jCol = JsonArrayInsert(jCol, jActList);
    jCol = JsonArrayInsert(jCol, NuiRow(jForswRow));
    jCol = JsonArrayInsert(jCol, CreateEmptyRow(oPC, 6.0));
    jCol = JsonArrayInsert(jCol, jHisHdr);
    jCol = JsonArrayInsert(jCol, jHisList);

    json jSide    = NuiCol(JsonArrayInsert(JsonArray(), NuiSpacer()));
    float fConW   = GetNuiScaleDimension(oPC, 540.0);

    json jMain = JsonArray();
    jMain = JsonArrayInsert(jMain, jSide);
    jMain = JsonArrayInsert(jMain, NuiWidth(NuiCol(jCol), fConW));
    jMain = JsonArrayInsert(jMain, jSide);
    return NuiRow(jMain);
}

// ================================================================
// Window creation
// ================================================================

void CreateVendWindow(object oPC)
{
    int nExist = NuiFindWindow(oPC, VEND_WINDOW);
    if (nExist != 0)
    {
        FeedVendWindow(oPC, nExist);
        return;
    }

    float fSW  = IntToFloat(GetPlayerDeviceProperty(oPC, PLAYER_DEVICE_PROPERTY_GUI_WIDTH));
    float fSH  = IntToFloat(GetPlayerDeviceProperty(oPC, PLAYER_DEVICE_PROPERTY_GUI_HEIGHT));
    float fW   = GetNuiScaleDimension(oPC, VEND_W);
    float fH   = GetNuiScaleDimension(oPC, VEND_H);
    json  jGeom = NuiRect((fSW - fW) / 2.0, (fSH - fH) / 2.0, fW, fH);

    float fBtnH   = GetNuiScaleDimension(oPC, 28.0);
    json  jCloseBtn = NuiButton(JsonString("X"));
    jCloseBtn = NuiId(jCloseBtn, VEND_BTN_CLOSE);
    jCloseBtn = NuiWidth(jCloseBtn, GetNuiScaleDimension(oPC, 28.0));
    jCloseBtn = NuiHeight(jCloseBtn, fBtnH);

    json jTopRow = JsonArray();
    jTopRow = JsonArrayInsert(jTopRow, NuiSpacer());
    jTopRow = JsonArrayInsert(jTopRow, jCloseBtn);

    json jRoot = JsonArray();
    jRoot = JsonArrayInsert(jRoot, NuiRow(jTopRow));
    jRoot = JsonArrayInsert(jRoot, BuildVendMainView(oPC));

    json jWin = NuiWindow(NuiCol(jRoot),
        JsonString("Księga Krzywd"),
        NuiBind(VEND_WIN_GEOM),
        JsonBool(FALSE),
        JsonBool(FALSE),
        JsonBool(FALSE),
        JsonBool(TRUE),
        JsonBool(FALSE));

    int nToken = NuiCreate(oPC, jWin, VEND_WINDOW, VEND_EV_SCRIPT);
    NuiSetBind(oPC, nToken, VEND_WIN_GEOM, jGeom);
    FeedVendWindow(oPC, nToken);
}

// ================================================================
// Forswear confirmation popup
// ================================================================

void CreateVendConfirmPopup(object oPC, int nGrudgeId, string sWrongdoerName)
{
    SetLocalInt(oPC, VEND_LVAR_PENDING_ID, nGrudgeId);

    if (NuiFindWindow(oPC, VEND_WIN_CONFIRM) != 0)
        NuiDestroy(oPC, NuiFindWindow(oPC, VEND_WIN_CONFIRM));

    float fSW = IntToFloat(GetPlayerDeviceProperty(oPC, PLAYER_DEVICE_PROPERTY_GUI_WIDTH));
    float fSH = IntToFloat(GetPlayerDeviceProperty(oPC, PLAYER_DEVICE_PROPERTY_GUI_HEIGHT));
    float fW  = GetNuiScaleDimension(oPC, 400.0);
    float fH  = GetNuiScaleDimension(oPC, 170.0);

    json jMsg = NuiLabel(
        JsonString("Wyrzekasz się zemsty na " + sWrongdoerName + ".\n"
                 + "Koszt: " + IntToString(VEND_FORSW_XP_PENALTY) + " PD."),
        JsonInt(NUI_HALIGN_CENTER), JsonInt(NUI_VALIGN_MIDDLE));

    json jYes = NuiButton(JsonString("Wyrzeknij się"));
    jYes = NuiId(jYes, VEND_BTN_FORSW_OK);
    jYes = NuiWidth(jYes, GetNuiScaleDimension(oPC, 130.0));

    json jNo = NuiButton(JsonString("Anuluj"));
    jNo = NuiId(jNo, VEND_BTN_FORSW_CANCEL);
    jNo = NuiWidth(jNo, GetNuiScaleDimension(oPC, 80.0));

    json jBtnRow = JsonArray();
    jBtnRow = JsonArrayInsert(jBtnRow, NuiSpacer());
    jBtnRow = JsonArrayInsert(jBtnRow, jYes);
    jBtnRow = JsonArrayInsert(jBtnRow, NuiSpacer());
    jBtnRow = JsonArrayInsert(jBtnRow, jNo);
    jBtnRow = JsonArrayInsert(jBtnRow, NuiSpacer());

    json jCol = JsonArray();
    jCol = JsonArrayInsert(jCol, jMsg);
    jCol = JsonArrayInsert(jCol, CreateEmptyRow(oPC, 10.0));
    jCol = JsonArrayInsert(jCol, NuiRow(jBtnRow));

    json jWin = NuiWindow(NuiCol(jCol),
        JsonString("Wyrzeczenie"),
        NuiRect((fSW - fW) / 2.0, (fSH - fH) / 2.0, fW, fH),
        JsonBool(FALSE), JsonBool(FALSE), JsonBool(TRUE),
        JsonBool(FALSE), JsonBool(TRUE));

    NuiCreate(oPC, jWin, VEND_WIN_CONFIRM, VEND_EV_SCRIPT);
}
