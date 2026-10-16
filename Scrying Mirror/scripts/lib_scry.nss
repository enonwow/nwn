#include "lib_scry_def"

// ----------------------------------------------------------------
// Authorization helpers
// ----------------------------------------------------------------

int ScryCanAttune(object oPC)
{
    if(GetIsDM(oPC) || GetIsDMPossessed(oPC)) return TRUE;
    return GetIsObjectValid(GetItemPossessedBy(oPC, SCRY_ITEM_CRYSTAL));
}

int ScryCanDeactivate(object oPC, json jMirror)
{
    if(GetIsDM(oPC) || GetIsDMPossessed(oPC)) return TRUE;
    return (JsonGetString(JsonObjectGet(jMirror, "attuner_uuid")) == GetObjectUUID(oPC));
}

// ----------------------------------------------------------------
// Area query — returns {names: [], hps: []} for all PCs in area
// ----------------------------------------------------------------

json ScryGetPCsInArea(string sAreaTag)
{
    json jNames = JsonArray();
    json jHPs   = JsonArray();

    object oPC = GetFirstPC();
    while(GetIsObjectValid(oPC))
    {
        if(GetTag(GetArea(oPC)) == sAreaTag)
        {
            jNames = JsonArrayInsert(jNames, JsonString(GetName(oPC)));
            int nHP  = GetCurrentHitPoints(oPC);
            int nMax = GetMaxHitPoints(oPC);
            int nPct = (nMax > 0) ? (nHP * 100 / nMax) : 0;
            jHPs = JsonArrayInsert(jHPs, JsonInt(nPct));
        }
        oPC = GetNextPC();
    }

    json jResult = JsonObject();
    jResult = JsonObjectSet(jResult, "names", jNames);
    jResult = JsonObjectSet(jResult, "hps",   jHPs);
    return jResult;
}

// ----------------------------------------------------------------
// NUI layout builders
// ----------------------------------------------------------------

json ScryBuildListPanel(object oPC)
{
    float fRowH  = GetNuiScaleDimension(oPC, 42.0);
    float fBtnH  = GetNuiScaleDimension(oPC, 28.0);
    float fListH = GetNuiScaleDimension(oPC, SCRY_H - 110.0);
    float fListW = GetNuiScaleDimension(oPC, SCRY_LIST_W);

    // Section header
    json jHdr = NuiLabel(JsonString("Zwierciarta"), JsonInt(NUI_HALIGN_LEFT), JsonInt(NUI_VALIGN_MIDDLE));
    jHdr = NuiHeight(jHdr, GetNuiScaleDimension(oPC, 26.0));

    // List row template: mirror name + area name stacked
    json jNameLbl = NuiLabel(NuiBind(SCRY_BIND_ROW_NAME), JsonInt(NUI_HALIGN_LEFT), JsonInt(NUI_VALIGN_MIDDLE));

    json jAreaLbl = NuiLabel(NuiBind(SCRY_BIND_ROW_AREA), JsonInt(NUI_HALIGN_LEFT), JsonInt(NUI_VALIGN_MIDDLE));
    jAreaLbl = NuiStyleForegroundColor(jAreaLbl, NuiColor(160, 140, 120));

    json jCellCol = JsonArray();
    jCellCol = JsonArrayInsert(jCellCol, jNameLbl);
    jCellCol = JsonArrayInsert(jCellCol, jAreaLbl);

    json jCell = NuiGroup(NuiCol(jCellCol), TRUE, NUI_SCROLLBARS_NONE);
    jCell = NuiId(jCell, SCRY_BTN_ROW);
    jCell = NuiEncouraged(jCell, NuiBind(SCRY_BIND_ROW_ENC));

    json jTmpl = JsonArrayInsert(JsonArray(), NuiListTemplateCell(jCell, 0.0, TRUE));
    json jList  = NuiList(jTmpl, NuiBind(SCRY_BIND_ROW_COUNT), fRowH);
    jList = NuiHeight(jList, fListH);

    // Refresh button
    json jRefresh = NuiButton(JsonString("Odswiez"));
    jRefresh = NuiId(jRefresh, SCRY_BTN_REFRESH);
    jRefresh = NuiHeight(jRefresh, fBtnH);

    json jCol = JsonArray();
    jCol = JsonArrayInsert(jCol, NuiRow(JsonArrayInsert(JsonArray(), jHdr)));
    jCol = JsonArrayInsert(jCol, jList);
    jCol = JsonArrayInsert(jCol, NuiRow(JsonArrayInsert(JsonArray(), jRefresh)));

    return NuiWidth(NuiCol(jCol), fListW);
}

json ScryBuildDetailPanel(object oPC)
{
    float fBtnH  = GetNuiScaleDimension(oPC, 28.0);
    float fNoteH = GetNuiScaleDimension(oPC, 72.0);
    float fPresH = GetNuiScaleDimension(oPC, 190.0);

    // Mirror name (large, white)
    json jName = NuiLabel(NuiBind(SCRY_BIND_DET_NAME), JsonInt(NUI_HALIGN_LEFT), JsonInt(NUI_VALIGN_MIDDLE));
    jName = NuiHeight(jName, GetNuiScaleDimension(oPC, 28.0));

    // Area label (small, amber)
    json jArea = NuiLabel(NuiBind(SCRY_BIND_DET_AREA), JsonInt(NUI_HALIGN_LEFT), JsonInt(NUI_VALIGN_MIDDLE));
    jArea = NuiStyleForegroundColor(jArea, NuiColor(160, 140, 120));
    jArea = NuiHeight(jArea, GetNuiScaleDimension(oPC, 22.0));

    // Note text block
    json jNote = NuiGroup(NuiText(NuiBind(SCRY_BIND_DET_NOTE), FALSE), TRUE, NUI_SCROLLBARS_NONE);
    jNote = NuiHeight(jNote, fNoteH);

    // Presence / gaze result text block
    json jPres = NuiGroup(NuiText(NuiBind(SCRY_BIND_DET_PRES), FALSE), TRUE, NUI_SCROLLBARS_NONE);
    jPres = NuiHeight(jPres, fPresH);

    // Action buttons
    json jGaze = NuiButton(JsonString("Wpatrz sie (Lza)"));
    jGaze = NuiId(jGaze, SCRY_BTN_GAZE);
    jGaze = NuiEnabled(jGaze, NuiBind(SCRY_BIND_DET_GAZE));
    jGaze = NuiHeight(jGaze, fBtnH);

    json jAttune = NuiButton(JsonString("Nastraj..."));
    jAttune = NuiId(jAttune, SCRY_BTN_ATTUNE);
    jAttune = NuiEnabled(jAttune, NuiBind(SCRY_BIND_DET_ATT));
    jAttune = NuiWidth(jAttune, GetNuiScaleDimension(oPC, 90.0));
    jAttune = NuiHeight(jAttune, fBtnH);

    json jDeact = NuiButton(JsonString("Wygasz"));
    jDeact = NuiId(jDeact, SCRY_BTN_DEACT);
    jDeact = NuiEnabled(jDeact, NuiBind(SCRY_BIND_DET_DEACT));
    jDeact = NuiWidth(jDeact, GetNuiScaleDimension(oPC, 80.0));
    jDeact = NuiHeight(jDeact, fBtnH);

    json jBtnRow = JsonArray();
    jBtnRow = JsonArrayInsert(jBtnRow, jGaze);
    jBtnRow = JsonArrayInsert(jBtnRow, NuiSpacer());
    jBtnRow = JsonArrayInsert(jBtnRow, jAttune);
    jBtnRow = JsonArrayInsert(jBtnRow, jDeact);

    json jCol = JsonArray();
    jCol = JsonArrayInsert(jCol, NuiRow(JsonArrayInsert(JsonArray(), jName)));
    jCol = JsonArrayInsert(jCol, NuiRow(JsonArrayInsert(JsonArray(), jArea)));
    jCol = JsonArrayInsert(jCol, CreateEmptyRow(oPC, 4.0));
    jCol = JsonArrayInsert(jCol, jNote);
    jCol = JsonArrayInsert(jCol, jPres);
    jCol = JsonArrayInsert(jCol, NuiRow(jBtnRow));

    return NuiCol(jCol);
}

// ----------------------------------------------------------------
// Window create / reopen
// ----------------------------------------------------------------

void ScryCreateWindow(object oPC)
{
    if(NuiFindWindow(oPC, SCRY_WINDOW) != 0)
    {
        int nToken = NuiFindWindow(oPC, SCRY_WINDOW);
        SetLocalInt(oPC, SCRY_LVAR_SEL_ID, 0);
        ScryFeedMirrorList(oPC, nToken);
        ScryFeedDetail(oPC, nToken, 0);
        return;
    }

    float fCX = (IntToFloat(GetPlayerDeviceProperty(oPC, PLAYER_DEVICE_PROPERTY_GUI_WIDTH))  - GetNuiScaleDimension(oPC, SCRY_W)) / 2.0;
    float fCY = (IntToFloat(GetPlayerDeviceProperty(oPC, PLAYER_DEVICE_PROPERTY_GUI_HEIGHT)) - GetNuiScaleDimension(oPC, SCRY_H)) / 2.0;
    json jGeom = NuiRect(fCX, fCY, GetNuiScaleDimension(oPC, SCRY_W), GetNuiScaleDimension(oPC, SCRY_H));

    float fBtnH = GetNuiScaleDimension(oPC, 28.0);

    // Top bar: title + close button
    json jTitle = NuiLabel(JsonString("Zwierciadlo Dalekowzrocznosci"), JsonInt(NUI_HALIGN_LEFT), JsonInt(NUI_VALIGN_MIDDLE));
    jTitle = NuiHeight(jTitle, fBtnH);

    json jClose = NuiButton(JsonString("X"));
    jClose = NuiId(jClose, SCRY_BTN_CLOSE);
    jClose = NuiWidth(jClose, GetNuiScaleDimension(oPC, 28.0));
    jClose = NuiHeight(jClose, fBtnH);

    json jTopRow = JsonArray();
    jTopRow = JsonArrayInsert(jTopRow, jTitle);
    jTopRow = JsonArrayInsert(jTopRow, NuiSpacer());
    jTopRow = JsonArrayInsert(jTopRow, jClose);

    // Body: list panel (left) + detail panel (right)
    json jBody = JsonArray();
    jBody = JsonArrayInsert(jBody, ScryBuildListPanel(oPC));
    jBody = JsonArrayInsert(jBody, ScryBuildDetailPanel(oPC));

    json jRoot = JsonArray();
    jRoot = JsonArrayInsert(jRoot, NuiRow(jTopRow));
    jRoot = JsonArrayInsert(jRoot, NuiRow(jBody));

    json jWin = NuiWindow(NuiCol(jRoot),
        JsonBool(FALSE),
        NuiBind(SCRY_WIN_GEOM),
        JsonBool(FALSE),
        JsonBool(FALSE),
        JsonBool(FALSE),
        JsonBool(FALSE),
        JsonBool(TRUE));

    int nToken = NuiCreate(oPC, jWin, SCRY_WINDOW, SCRY_EV_SCRIPT);
    NuiSetBind(oPC, nToken, SCRY_WIN_GEOM, jGeom);

    SetLocalInt(oPC, SCRY_LVAR_SEL_ID, 0);
    ScryFeedMirrorList(oPC, nToken);
    ScryFeedDetail(oPC, nToken, 0);
}

// ----------------------------------------------------------------
// Feed: mirror list
// ----------------------------------------------------------------

void ScryFeedMirrorList(object oPC, int nToken)
{
    json jMirrors = ScryGetMirrors();
    int  nCount   = JsonGetLength(jMirrors);
    int  nSel     = GetLocalInt(oPC, SCRY_LVAR_SEL_ID);

    SetLocalJson(oPC, SCRY_LVAR_MIRRORS, jMirrors);

    json jNames = JsonArray();
    json jAreas = JsonArray();
    json jEncs  = JsonArray();

    int i;
    for(i = 0; i < nCount; i++)
    {
        json jRow  = JsonArrayGet(jMirrors, i);
        int  nId   = JsonGetInt   (JsonObjectGet(jRow, "id"));
        string sN  = JsonGetString(JsonObjectGet(jRow, "mirror_name"));
        string sA  = JsonGetString(JsonObjectGet(jRow, "area_name"));

        jNames = JsonArrayInsert(jNames, JsonString(sN));
        jAreas = JsonArrayInsert(jAreas, JsonString(sA));
        jEncs  = JsonArrayInsert(jEncs,  JsonBool(nSel > 0 && nId == nSel));
    }

    NuiSetBind(oPC, nToken, SCRY_BIND_ROW_NAME,  jNames);
    NuiSetBind(oPC, nToken, SCRY_BIND_ROW_AREA,  jAreas);
    NuiSetBind(oPC, nToken, SCRY_BIND_ROW_ENC,   jEncs);
    NuiSetBind(oPC, nToken, SCRY_BIND_ROW_COUNT, JsonInt(nCount));
}

// ----------------------------------------------------------------
// Feed: detail panel
// ----------------------------------------------------------------

void ScryFeedDetail(object oPC, int nToken, int nMirrorId)
{
    int bCanAttune = ScryCanAttune(oPC);

    if(nMirrorId <= 0)
    {
        NuiSetBind(oPC, nToken, SCRY_BIND_DET_NAME,  JsonString("Wybierz zwierciadlo..."));
        NuiSetBind(oPC, nToken, SCRY_BIND_DET_AREA,  JsonString(""));
        NuiSetBind(oPC, nToken, SCRY_BIND_DET_NOTE,  JsonString("Krysztalna powierzchnia jest milczaca i ciemna."));
        NuiSetBind(oPC, nToken, SCRY_BIND_DET_PRES,  JsonString(""));
        NuiSetBind(oPC, nToken, SCRY_BIND_DET_GAZE,  JsonBool(FALSE));
        NuiSetBind(oPC, nToken, SCRY_BIND_DET_DEACT, JsonBool(FALSE));
        NuiSetBind(oPC, nToken, SCRY_BIND_DET_ATT,   JsonBool(bCanAttune));
        return;
    }

    json jMirror = ScryGetMirrorById(nMirrorId);
    if(JsonGetType(jMirror) == JSON_TYPE_NULL)
    {
        SetLocalInt(oPC, SCRY_LVAR_SEL_ID, 0);
        ScryFeedDetail(oPC, nToken, 0);
        return;
    }

    string sMirrorName = JsonGetString(JsonObjectGet(jMirror, "mirror_name"));
    string sAreaName   = JsonGetString(JsonObjectGet(jMirror, "area_name"));
    string sAreaTag    = JsonGetString(JsonObjectGet(jMirror, "area_tag"));
    string sNote       = JsonGetString(JsonObjectGet(jMirror, "note"));
    string sAttuner    = JsonGetString(JsonObjectGet(jMirror, "attuner_name"));

    // Quick presence count without consuming a reagent
    json jPCs    = ScryGetPCsInArea(sAreaTag);
    int  nPresent = JsonGetLength(JsonObjectGet(jPCs, "names"));

    string sPresLabel;
    if(nPresent == 0)
        sPresLabel = "W tym miejscu nie wyczuwasz zadnych obecnosci.\n[Wpatrz sie, aby sprawdzic szczegoly]";
    else if(nPresent == 1)
        sPresLabel = "Wyczuwasz jedna obecnosc w tym miejscu.\n[Wpatrz sie, aby zobaczyc kogo]";
    else
        sPresLabel = "Wyczuwasz " + IntToString(nPresent) + " obecnosci w tym miejscu.\n[Wpatrz sie, aby zobaczyc kogo]";

    string sNoteDisp = (sNote != "") ? ("\"" + sNote + "\"") : "(Brak notatki)";
    sNoteDisp = sNoteDisp + "\n-- nastrojone przez " + sAttuner;

    NuiSetBind(oPC, nToken, SCRY_BIND_DET_NAME,  JsonString(sMirrorName));
    NuiSetBind(oPC, nToken, SCRY_BIND_DET_AREA,  JsonString("Obszar: " + sAreaName));
    NuiSetBind(oPC, nToken, SCRY_BIND_DET_NOTE,  JsonString(sNoteDisp));
    NuiSetBind(oPC, nToken, SCRY_BIND_DET_PRES,  JsonString(sPresLabel));
    NuiSetBind(oPC, nToken, SCRY_BIND_DET_GAZE,  JsonBool(TRUE));
    NuiSetBind(oPC, nToken, SCRY_BIND_DET_DEACT, JsonBool(ScryCanDeactivate(oPC, jMirror)));
    NuiSetBind(oPC, nToken, SCRY_BIND_DET_ATT,   JsonBool(bCanAttune));
}

// ----------------------------------------------------------------
// Gaze mechanic: consumes Lza Jasnowidza, reveals presences,
// triggers detection rolls for observed PCs
// ----------------------------------------------------------------

void ScryPerformGaze(object oPC, int nToken, int nMirrorId)
{
    json jMirror = ScryGetMirrorById(nMirrorId);
    if(JsonGetType(jMirror) == JSON_TYPE_NULL)
    {
        SendMessageToPC(oPC, "[Zwierciadlo] To zwierciadlo zostalo zgaszone.");
        return;
    }

    object oTear = GetItemPossessedBy(oPC, SCRY_ITEM_TEAR);
    if(!GetIsObjectValid(oTear))
    {
        SendMessageToPC(oPC, "[Zwierciadlo] Potrzebujesz Lzy Jasnowidza, aby wpatrzec sie w zwierciadlo.");
        return;
    }

    string sAreaTag  = JsonGetString(JsonObjectGet(jMirror, "area_tag"));
    string sAreaName = JsonGetString(JsonObjectGet(jMirror, "area_name"));

    // Consume one tear (stack-aware)
    int nStack = GetItemStackSize(oTear);
    if(nStack > 1)
        SetItemStackSize(oTear, nStack - 1);
    else
        DestroyObject(oTear);

    int nINTMod = GetAbilityModifier(ABILITY_INTELLIGENCE, oPC);
    int nDC     = 15 + nINTMod;

    string sResult = "Twoj wzrok przenika przez powierzchnie zwierciadla...\n\n";
    int nFound = 0;

    object oTarget = GetFirstPC();
    while(GetIsObjectValid(oTarget))
    {
        if(GetTag(GetArea(oTarget)) == sAreaTag && oTarget != oPC)
        {
            nFound++;
            int nHP  = GetCurrentHitPoints(oTarget);
            int nMax = GetMaxHitPoints(oTarget);
            int nPct = (nMax > 0) ? (nHP * 100 / nMax) : 0;

            string sCond;
            if(nPct >= 90)      sCond = "bez szwanku";
            else if(nPct >= 60) sCond = "lekko ranny";
            else if(nPct >= 30) sCond = "powazanie ranny";
            else                sCond = "o krok od smierci";

            sResult = sResult + "- " + GetName(oTarget) + " [" + sCond + "]\n";

            // Spot check: DC 15 + scryer's INT modifier
            int nRoll = d20() + GetSkillRank(SKILL_SPOT, oTarget);
            if(nRoll >= nDC)
            {
                string sDetMsg;
                if(nRoll >= 25)
                    sDetMsg = "Twarz " + GetName(oPC) + " miga w twoim umysle niczym zlowroga zjawa — ktos cie szpieguje przez zwierciadlo!";
                else
                    sDetMsg = "Czujesz na sobie obce spojrzenie... ktos obserwuje cie przez zwierciadlo.";
                FloatingTextStringOnCreature(sDetMsg, oTarget, FALSE);
                SendMessageToPC(oTarget, "[Zwierciadlo] " + sDetMsg);
            }
        }
        oTarget = GetNextPC();
    }

    if(nFound == 0)
        sResult = sResult + "Miejsce jest puste. Jedynie ciszе i cien widzisz w krysztale.";

    NuiSetBind(oPC, nToken, SCRY_BIND_DET_PRES, JsonString(sResult));
    FloatingTextStringOnCreature("Pieczen krysztalu pulsuje slabo...", oPC, FALSE);
}

// ----------------------------------------------------------------
// Attune popup
// ----------------------------------------------------------------

void ScryFeedAttunePopup(object oPC)
{
    int nToken = NuiFindWindow(oPC, SCRY_WIN_ATTUNE);
    if(nToken == 0) return;

    string sAreaName = GetName(GetArea(oPC));
    NuiSetBind(oPC, nToken, SCRY_BIND_ATT_AREA, JsonString("Obszar: " + sAreaName));
    NuiSetBind(oPC, nToken, SCRY_BIND_ATT_NAME, JsonString(""));
    NuiSetBind(oPC, nToken, SCRY_BIND_ATT_NOTE, JsonString(""));
    NuiSetBind(oPC, nToken, SCRY_BIND_ATT_SAVE, JsonBool(FALSE));
    NuiSetBindWatch(oPC, nToken, SCRY_BIND_ATT_NAME, TRUE);
}

void ScryCreateAttunePopup(object oPC)
{
    if(!ScryCanAttune(oPC))
    {
        SendMessageToPC(oPC, "[Zwierciadlo] Potrzebujesz Kamienia Krysztalowego, aby nastroic nowe zwierciadlo.");
        return;
    }
    if(ScryGetActiveMirrorCount() >= SCRY_MAX_MIRRORS)
    {
        SendMessageToPC(oPC, "[Zwierciadlo] Osiagnieto limit aktywnych zwierciatel (" + IntToString(SCRY_MAX_MIRRORS) + ").");
        return;
    }
    if(NuiFindWindow(oPC, SCRY_WIN_ATTUNE) != 0)
        NuiDestroy(oPC, NuiFindWindow(oPC, SCRY_WIN_ATTUNE));

    float fW    = GetNuiScaleDimension(oPC, 400.0);
    float fH    = GetNuiScaleDimension(oPC, 300.0);
    float fBtnH = GetNuiScaleDimension(oPC, 28.0);
    float fX = (IntToFloat(GetPlayerDeviceProperty(oPC, PLAYER_DEVICE_PROPERTY_GUI_WIDTH))  - fW) / 2.0;
    float fY = (IntToFloat(GetPlayerDeviceProperty(oPC, PLAYER_DEVICE_PROPERTY_GUI_HEIGHT)) - fH) / 2.0;

    // Current area label
    json jAreaLbl = NuiLabel(NuiBind(SCRY_BIND_ATT_AREA), JsonInt(NUI_HALIGN_LEFT), JsonInt(NUI_VALIGN_MIDDLE));
    jAreaLbl = NuiStyleForegroundColor(jAreaLbl, NuiColor(160, 140, 120));
    jAreaLbl = NuiHeight(jAreaLbl, GetNuiScaleDimension(oPC, 22.0));

    // Name row
    json jNameLbl = NuiLabel(JsonString("Nazwa:"), JsonInt(NUI_HALIGN_LEFT), JsonInt(NUI_VALIGN_MIDDLE));
    jNameLbl = NuiWidth(jNameLbl, GetNuiScaleDimension(oPC, 60.0));
    jNameLbl = NuiHeight(jNameLbl, fBtnH);
    json jNameEdit = NuiTextEdit(JsonString("np. Oko Burzy..."), NuiBind(SCRY_BIND_ATT_NAME), SCRY_NAME_MAX, FALSE);
    jNameEdit = NuiHeight(jNameEdit, fBtnH);
    json jNameRow = JsonArray();
    jNameRow = JsonArrayInsert(jNameRow, jNameLbl);
    jNameRow = JsonArrayInsert(jNameRow, jNameEdit);

    // Note field
    json jNoteLbl = NuiLabel(JsonString("Notatka (opcjonalna):"), JsonInt(NUI_HALIGN_LEFT), JsonInt(NUI_VALIGN_MIDDLE));
    jNoteLbl = NuiHeight(jNoteLbl, GetNuiScaleDimension(oPC, 20.0));
    json jNoteEdit = NuiTextEdit(JsonString(""), NuiBind(SCRY_BIND_ATT_NOTE), SCRY_NOTE_MAX, TRUE);
    jNoteEdit = NuiHeight(jNoteEdit, GetNuiScaleDimension(oPC, 110.0));

    // Buttons
    json jSave = NuiButton(JsonString("Nastraj"));
    jSave = NuiId(jSave, SCRY_BTN_ATT_SAVE);
    jSave = NuiEnabled(jSave, NuiBind(SCRY_BIND_ATT_SAVE));
    jSave = NuiWidth(jSave, GetNuiScaleDimension(oPC, 100.0));
    jSave = NuiHeight(jSave, fBtnH);

    json jCancel = NuiButton(JsonString("Anuluj"));
    jCancel = NuiId(jCancel, SCRY_BTN_ATT_CANCEL);
    jCancel = NuiWidth(jCancel, GetNuiScaleDimension(oPC, 80.0));
    jCancel = NuiHeight(jCancel, fBtnH);

    json jBtnRow = JsonArray();
    jBtnRow = JsonArrayInsert(jBtnRow, NuiSpacer());
    jBtnRow = JsonArrayInsert(jBtnRow, jSave);
    jBtnRow = JsonArrayInsert(jBtnRow, jCancel);

    json jCol = JsonArray();
    jCol = JsonArrayInsert(jCol, NuiRow(JsonArrayInsert(JsonArray(), jAreaLbl)));
    jCol = JsonArrayInsert(jCol, CreateEmptyRow(oPC, 4.0));
    jCol = JsonArrayInsert(jCol, NuiRow(jNameRow));
    jCol = JsonArrayInsert(jCol, NuiRow(JsonArrayInsert(JsonArray(), jNoteLbl)));
    jCol = JsonArrayInsert(jCol, jNoteEdit);
    jCol = JsonArrayInsert(jCol, NuiRow(jBtnRow));

    json jWin = NuiWindow(NuiCol(jCol),
        JsonString("Nastrojenie Zwierciadla"),
        NuiRect(fX, fY, fW, fH),
        JsonBool(FALSE), JsonBool(FALSE), JsonBool(TRUE),
        JsonBool(FALSE), JsonBool(TRUE));

    NuiCreate(oPC, jWin, SCRY_WIN_ATTUNE, SCRY_EV_SCRIPT);
    ScryFeedAttunePopup(oPC);
}

void ScryHandleSaveAttunement(object oPC)
{
    int nToken = NuiFindWindow(oPC, SCRY_WIN_ATTUNE);
    if(nToken == 0) return;

    string sName = JsonGetString(NuiGetBind(oPC, nToken, SCRY_BIND_ATT_NAME));
    string sNote = JsonGetString(NuiGetBind(oPC, nToken, SCRY_BIND_ATT_NOTE));

    if(sName == "")
    {
        SendMessageToPC(oPC, "[Zwierciadlo] Nazwa zwierciadla nie moze byc pusta.");
        return;
    }

    // Non-DMs must have and consume the crystal
    if(!GetIsDM(oPC) && !GetIsDMPossessed(oPC))
    {
        object oCrystal = GetItemPossessedBy(oPC, SCRY_ITEM_CRYSTAL);
        if(!GetIsObjectValid(oCrystal))
        {
            SendMessageToPC(oPC, "[Zwierciadlo] Brak Kamienia Krysztalowego — nastrojenie niemozliwe.");
            NuiDestroy(oPC, nToken);
            return;
        }
        int nStack = GetItemStackSize(oCrystal);
        if(nStack > 1)
            SetItemStackSize(oCrystal, nStack - 1);
        else
            DestroyObject(oCrystal);
    }

    int nNewId = ScryAddMirror(oPC, sName, sNote);
    NuiDestroy(oPC, nToken);

    int nMainToken = NuiFindWindow(oPC, SCRY_WINDOW);
    if(nMainToken != 0)
    {
        SetLocalInt(oPC, SCRY_LVAR_SEL_ID, nNewId);
        ScryFeedMirrorList(oPC, nMainToken);
        ScryFeedDetail(oPC, nMainToken, nNewId);
    }

    SendMessageToPC(oPC, "[Zwierciadlo] Zwierciadlo \"" + sName + "\" nastrojone pomyslnie.");
    FloatingTextStringOnCreature("Pieczen krysztalu pulsuje slabo, po czym gasnie.", oPC, FALSE);
}
