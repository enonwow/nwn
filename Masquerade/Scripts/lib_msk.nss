#include "lib_msk_def"

// ----------------------------------------------------------------
// Suspicion helpers
// ----------------------------------------------------------------

int MskGetSuspicion(object oPC)
{
    return GetLocalInt(oPC, MSK_LVAR_SUSPICION);
}

void MskSetSuspicion(object oPC, int nVal)
{
    if(nVal < 0)   nVal = 0;
    if(nVal > 100) nVal = 100;
    SetLocalInt(oPC, MSK_LVAR_SUSPICION, nVal);
}

int MskIsActive(object oPC)
{
    return GetLocalInt(oPC, MSK_LVAR_ACTIVE_ID) != 0;
}

// ----------------------------------------------------------------
// NUI helpers
// ----------------------------------------------------------------

json MskSuspicionColor(int nSusp)
{
    if(nSusp >= MSK_SUSP_DANGER)  return NuiColor(220, 50,  50);
    if(nSusp >= MSK_SUSP_WARN)    return NuiColor(210, 160, 30);
    return NuiColor(80, 200, 100);
}

string MskSuspicionLabel(int nSusp)
{
    if(nSusp >= MSK_SUSP_DANGER)  return "Tożsamość zagrożona! (" + IntToString(nSusp) + "/100)";
    if(nSusp >= MSK_SUSP_WARN)    return "Wzbudza podejrzenia (" + IntToString(nSusp) + "/100)";
    return "Maska bezpieczna (" + IntToString(nSusp) + "/100)";
}

// ----------------------------------------------------------------
// Build the status section (top half of window)
// ----------------------------------------------------------------

json MskBuildStatusSection(object oPC)
{
    float fW      = GetNuiScaleDimension(oPC, MSK_W - 40.0);
    float fBtnH   = GetNuiScaleDimension(oPC, 28.0);
    float fBarH   = GetNuiScaleDimension(oPC, 18.0);
    float fLabelW = GetNuiScaleDimension(oPC, 120.0);

    // Identity row
    json jIdentLabel = NuiLabel(
        JsonString("Aktywna tożsamość:"),
        JsonInt(NUI_HALIGN_LEFT), JsonInt(NUI_VALIGN_MIDDLE));
    jIdentLabel = NuiWidth(jIdentLabel, fLabelW);

    json jIdentVal = NuiLabel(
        NuiBind(MSK_BIND_IDENTITY_LBL),
        JsonInt(NUI_HALIGN_LEFT), JsonInt(NUI_VALIGN_MIDDLE));
    jIdentVal = NuiStyleForegroundColor(jIdentVal, NuiColor(200, 180, 120));

    json jIdentRow = JsonArray();
    jIdentRow = JsonArrayInsert(jIdentRow, jIdentLabel);
    jIdentRow = JsonArrayInsert(jIdentRow, jIdentVal);

    // Flavor text
    json jFlavorTxt = NuiGroup(
        NuiText(NuiBind(MSK_BIND_FLAVOR_TXT), FALSE),
        TRUE, NUI_SCROLLBARS_NONE);
    jFlavorTxt = NuiHeight(jFlavorTxt, GetNuiScaleDimension(oPC, 60.0));

    // Suspicion bar row: label + progress
    json jSuspLabel = NuiLabel(
        JsonString("Podejrzenia:"),
        JsonInt(NUI_HALIGN_LEFT), JsonInt(NUI_VALIGN_MIDDLE));
    jSuspLabel = NuiWidth(jSuspLabel, fLabelW);

    json jSuspBar = NuiProgress(NuiBind(MSK_BIND_SUSP_BAR));
    jSuspBar = NuiHeight(jSuspBar, fBarH);
    jSuspBar = NuiStyleForegroundColor(jSuspBar, NuiBind(MSK_BIND_SUSP_COLOR));

    json jSuspRow = JsonArray();
    jSuspRow = JsonArrayInsert(jSuspRow, jSuspLabel);
    jSuspRow = JsonArrayInsert(jSuspRow, jSuspBar);

    // Suspicion textual label
    json jSuspTxt = NuiLabel(
        NuiBind(MSK_BIND_SUSP_LBL),
        JsonInt(NUI_HALIGN_LEFT), JsonInt(NUI_VALIGN_MIDDLE));
    jSuspTxt = NuiStyleForegroundColor(jSuspTxt, NuiBind(MSK_BIND_SUSP_COLOR));
    jSuspTxt = NuiHeight(jSuspTxt, GetNuiScaleDimension(oPC, 20.0));

    // Remove button
    json jRemBtn = NuiButton(NuiBind(MSK_BIND_BTN_REMOVE_LBL));
    jRemBtn = NuiId(jRemBtn, MSK_BTN_REMOVE);
    jRemBtn = NuiEnabled(jRemBtn, NuiBind(MSK_BIND_BTN_REMOVE_ENA));
    jRemBtn = NuiWidth(jRemBtn, GetNuiScaleDimension(oPC, 160.0));
    jRemBtn = NuiHeight(jRemBtn, fBtnH);

    json jRemRow = JsonArray();
    jRemRow = JsonArrayInsert(jRemRow, NuiSpacer());
    jRemRow = JsonArrayInsert(jRemRow, jRemBtn);

    json jCol = JsonArray();
    jCol = JsonArrayInsert(jCol, NuiRow(jIdentRow));
    jCol = JsonArrayInsert(jCol, jFlavorTxt);
    jCol = JsonArrayInsert(jCol, CreateEmptyRow(oPC, 4.0));
    jCol = JsonArrayInsert(jCol, NuiRow(jSuspRow));
    jCol = JsonArrayInsert(jCol, jSuspTxt);
    jCol = JsonArrayInsert(jCol, CreateEmptyRow(oPC, 4.0));
    jCol = JsonArrayInsert(jCol, NuiRow(jRemRow));

    return NuiGroup(NuiCol(jCol), TRUE, NUI_SCROLLBARS_NONE);
}

// ----------------------------------------------------------------
// Build the mask list section (bottom half)
// ----------------------------------------------------------------

json MskBuildMaskListSection(object oPC)
{
    float fRowH  = GetNuiScaleDimension(oPC, 44.0);
    float fBtnW  = GetNuiScaleDimension(oPC, 90.0);
    float fBtnH  = GetNuiScaleDimension(oPC, 28.0);
    float fListH = GetNuiScaleDimension(oPC, 220.0);

    // Row template: [name+flavor col | "Załóż" button]
    json jNameLbl = NuiLabel(
        NuiBind(MSK_BIND_ROW_NAME),
        JsonInt(NUI_HALIGN_LEFT), JsonInt(NUI_VALIGN_MIDDLE));
    jNameLbl = NuiStyleForegroundColor(jNameLbl, NuiColor(200, 180, 120));

    json jFlavorLbl = NuiLabel(
        NuiBind(MSK_BIND_ROW_FLAVOR),
        JsonInt(NUI_HALIGN_LEFT), JsonInt(NUI_VALIGN_MIDDLE));
    jFlavorLbl = NuiStyleForegroundColor(jFlavorLbl, NuiColor(150, 140, 120));

    json jTextCol = JsonArray();
    jTextCol = JsonArrayInsert(jTextCol, jNameLbl);
    jTextCol = JsonArrayInsert(jTextCol, jFlavorLbl);

    json jWearBtn = NuiButton(JsonString("Załóż"));
    jWearBtn = NuiId(jWearBtn, MSK_BTN_WEAR);
    jWearBtn = NuiEnabled(jWearBtn, NuiBind(MSK_BIND_ROW_BTN_ENA));
    jWearBtn = NuiWidth(jWearBtn, fBtnW);
    jWearBtn = NuiHeight(jWearBtn, fBtnH);

    json jCell = NuiGroup(
        NuiRow(JsonArrayInsert(JsonArrayInsert(JsonArray(),
            NuiCol(jTextCol)),
            jWearBtn)),
        TRUE, NUI_SCROLLBARS_NONE);
    jCell = NuiEncouraged(jCell, NuiBind(MSK_BIND_ROW_ENC));

    json jTmpl = JsonArrayInsert(JsonArray(),
        NuiListTemplateCell(jCell, 0.0, TRUE));

    json jList = NuiList(jTmpl, NuiBind("msk_rowcount"), fRowH);
    jList = NuiHeight(jList, fListH);

    json jHeader = NuiLabel(
        JsonString("Dostępne maski:"),
        JsonInt(NUI_HALIGN_LEFT), JsonInt(NUI_VALIGN_MIDDLE));
    jHeader = NuiHeight(jHeader, GetNuiScaleDimension(oPC, 22.0));

    json jCol = JsonArray();
    jCol = JsonArrayInsert(jCol, jHeader);
    jCol = JsonArrayInsert(jCol, jList);

    return NuiGroup(NuiCol(jCol), TRUE, NUI_SCROLLBARS_NONE);
}

// ----------------------------------------------------------------
// Window create
// ----------------------------------------------------------------

void MskOpenPanel(object oPC)
{
    if(NuiFindWindow(oPC, MSK_WINDOW) != 0)
    {
        MskFeedPanel(oPC, NuiFindWindow(oPC, MSK_WINDOW));
        return;
    }

    float fCX = (IntToFloat(GetPlayerDeviceProperty(oPC, PLAYER_DEVICE_PROPERTY_GUI_WIDTH))
                 - GetNuiScaleDimension(oPC, MSK_W)) / 2.0;
    float fCY = (IntToFloat(GetPlayerDeviceProperty(oPC, PLAYER_DEVICE_PROPERTY_GUI_HEIGHT))
                 - GetNuiScaleDimension(oPC, MSK_H)) / 2.0;
    json jGeom = NuiRect(fCX, fCY,
        GetNuiScaleDimension(oPC, MSK_W),
        GetNuiScaleDimension(oPC, MSK_H));

    float fBtnH = GetNuiScaleDimension(oPC, 28.0);

    json jCloseBtn = NuiButton(JsonString("X"));
    jCloseBtn = NuiId(jCloseBtn, MSK_BTN_CLOSE);
    jCloseBtn = NuiWidth(jCloseBtn, GetNuiScaleDimension(oPC, 28.0));
    jCloseBtn = NuiHeight(jCloseBtn, fBtnH);

    json jTitleLbl = NuiLabel(
        JsonString("Masquerade — Oblicza i Tożsamości"),
        JsonInt(NUI_HALIGN_LEFT), JsonInt(NUI_VALIGN_MIDDLE));
    jTitleLbl = NuiHeight(jTitleLbl, fBtnH);

    json jTitleRow = JsonArray();
    jTitleRow = JsonArrayInsert(jTitleRow, jTitleLbl);
    jTitleRow = JsonArrayInsert(jTitleRow, NuiSpacer());
    jTitleRow = JsonArrayInsert(jTitleRow, jCloseBtn);

    json jStatusGrp = NuiGroup(MskBuildStatusSection(oPC), FALSE, NUI_SCROLLBARS_NONE);
    jStatusGrp = NuiId(jStatusGrp, MSK_GRP_STATUS);

    json jListGrp = NuiGroup(MskBuildMaskListSection(oPC), FALSE, NUI_SCROLLBARS_NONE);
    jListGrp = NuiId(jListGrp, MSK_GRP_LIST);

    json jRoot = JsonArray();
    jRoot = JsonArrayInsert(jRoot, NuiRow(jTitleRow));
    jRoot = JsonArrayInsert(jRoot, jStatusGrp);
    jRoot = JsonArrayInsert(jRoot, CreateEmptyRow(oPC, 4.0));
    jRoot = JsonArrayInsert(jRoot, jListGrp);

    json jWin = NuiWindow(NuiCol(jRoot),
        JsonBool(FALSE),
        NuiBind(MSK_WIN_GEOM),
        JsonBool(FALSE), JsonBool(FALSE),
        JsonBool(FALSE), JsonBool(TRUE), JsonBool(FALSE));

    int nToken = NuiCreate(oPC, jWin, MSK_WINDOW, MSK_EV_SCRIPT);
    NuiSetBind(oPC, nToken, MSK_WIN_GEOM, jGeom);

    MskFeedPanel(oPC, nToken);
}

// ----------------------------------------------------------------
// Feed all binds
// ----------------------------------------------------------------

void MskFeedPanel(object oPC, int nToken)
{
    MskFeedMaskList(oPC, nToken);

    int nSusp     = MskGetSuspicion(oPC);
    int bActive   = MskIsActive(oPC);
    string sName  = bActive ? GetLocalString(oPC, MSK_LVAR_ACTIVE_NAME) : "— brak —";
    int nMaskId   = GetLocalInt(oPC, MSK_LVAR_ACTIVE_ID);
    string sFlavor = "";

    if(bActive)
    {
        json jMask = MskGetMaskById(nMaskId);
        if(JsonGetType(jMask) != JSON_TYPE_NULL)
            sFlavor = JsonGetString(JsonObjectGet(jMask, "flavor"));
    }
    else
    {
        sFlavor = "Nie nosisz żadnego oblicza. Twoja twarz jest twoja własna — na dobre i złe.";
        nSusp   = 0;
    }

    NuiSetBind(oPC, nToken, MSK_BIND_IDENTITY_LBL,   JsonString(sName));
    NuiSetBind(oPC, nToken, MSK_BIND_FLAVOR_TXT,      JsonString(sFlavor));
    NuiSetBind(oPC, nToken, MSK_BIND_SUSP_BAR,        JsonFloat(IntToFloat(nSusp) / 100.0));
    NuiSetBind(oPC, nToken, MSK_BIND_SUSP_LBL,        JsonString(MskSuspicionLabel(nSusp)));
    NuiSetBind(oPC, nToken, MSK_BIND_SUSP_COLOR,      MskSuspicionColor(nSusp));
    NuiSetBind(oPC, nToken, MSK_BIND_BTN_REMOVE_ENA,  JsonBool(bActive));
    NuiSetBind(oPC, nToken, MSK_BIND_BTN_REMOVE_LBL,  JsonString(bActive ? "Zdejmij oblicze" : "Brak aktywnej maski"));
}

void MskFeedMaskList(object oPC, int nToken)
{
    json jOwned   = MskGetOwnedMasks(oPC);
    int nCount    = JsonGetLength(jOwned);
    int nActiveId = GetLocalInt(oPC, MSK_LVAR_ACTIVE_ID);

    json jNames   = JsonArray();
    json jFlavors = JsonArray();
    json jEncs    = JsonArray();
    json jBtnEna  = JsonArray();

    int i;
    for(i = 0; i < nCount; i++)
    {
        json jRow    = JsonArrayGet(jOwned, i);
        int nMaskId  = JsonGetInt   (JsonObjectGet(jRow, "mask_id"));
        string sName = JsonGetString(JsonObjectGet(jRow, "name"));
        string sFl   = JsonGetString(JsonObjectGet(jRow, "flavor"));
        int nBurned  = JsonGetInt   (JsonObjectGet(jRow, "burned"));
        int bIsActive = (nMaskId == nActiveId && nActiveId != 0);

        string sDisplayName = sName;
        if(nBurned)  sDisplayName = sDisplayName + " [spłonęła]";
        if(bIsActive) sDisplayName = sDisplayName + " [aktywna]";

        // Skrocony flavor w liscie
        string sShortFl = sFl;
        if(GetStringLength(sShortFl) > 55)
            sShortFl = GetStringLeft(sShortFl, 52) + "...";

        jNames   = JsonArrayInsert(jNames,   JsonString(sDisplayName));
        jFlavors = JsonArrayInsert(jFlavors, JsonString(sShortFl));
        jEncs    = JsonArrayInsert(jEncs,    JsonBool(bIsActive));
        // Przycisk "Załóż" dostepny gdy maska nie jest splacona i nie jest aktywna
        jBtnEna  = JsonArrayInsert(jBtnEna,  JsonBool(!nBurned && !bIsActive));
    }

    NuiSetBind(oPC, nToken, MSK_BIND_ROW_NAME,    jNames);
    NuiSetBind(oPC, nToken, MSK_BIND_ROW_FLAVOR,  jFlavors);
    NuiSetBind(oPC, nToken, MSK_BIND_ROW_ENC,     jEncs);
    NuiSetBind(oPC, nToken, MSK_BIND_ROW_BTN_ENA, jBtnEna);
    NuiSetBind(oPC, nToken, "msk_rowcount",        JsonInt(nCount));
}

// ----------------------------------------------------------------
// Activate / Deactivate
// ----------------------------------------------------------------

void MskActivate(object oPC, int nToken, int nMaskId)
{
    if(MskIsActive(oPC))
        MskDeactivate(oPC, nToken);

    json jMask = MskGetMaskById(nMaskId);
    if(JsonGetType(jMask) == JSON_TYPE_NULL)
    {
        SendMessageToPC(oPC, "[Masquerade] Nie można odnaleźć definicji maski.");
        return;
    }

    string sName = JsonGetString(JsonObjectGet(jMask, "name"));

    SetLocalInt   (oPC, MSK_LVAR_ACTIVE_ID,   nMaskId);
    SetLocalString(oPC, MSK_LVAR_ACTIVE_NAME,  sName);
    MskSetSuspicion(oPC, 0);

    // Podmiana wyswietlanej nazwy dla wszystkich obserwatorow
    SetPCNameOverride(oPC, sName, OBJECT_INVALID, PC_NAME_OVERRIDE_TYPE_REPLACE_ALWAYS);

    FloatingTextStringOnCreature(
        "Przybierasz oblicze: " + sName + ".",
        oPC, FALSE);

    // Uruchom heartbeat podejrzen
    MskScheduleHeartbeat(oPC);

    MskFeedPanel(oPC, nToken);
}

void MskDeactivate(object oPC, int nToken)
{
    if(!MskIsActive(oPC)) return;

    // Przywroc prawdziwa nazwe
    SetPCNameOverride(oPC, "", OBJECT_INVALID, PC_NAME_OVERRIDE_TYPE_REPLACE_ALWAYS);

    DeleteLocalInt   (oPC, MSK_LVAR_ACTIVE_ID);
    DeleteLocalString(oPC, MSK_LVAR_ACTIVE_NAME);
    MskSetSuspicion  (oPC, 0);

    FloatingTextStringOnCreature(
        "Zdejmujesz oblicze. Twoja prawdziwa twarz wraca na swoje miejsce.",
        oPC, FALSE);

    MskFeedPanel(oPC, nToken);
}

// Maska zostaje "spalona" — nie mozna jej ponownie uzyc (az do resetu DM)
void MskBlowCover(object oPC)
{
    int nMaskId = GetLocalInt(oPC, MSK_LVAR_ACTIVE_ID);
    if(nMaskId == 0) return;

    string sName = GetLocalString(oPC, MSK_LVAR_ACTIVE_NAME);

    SetPCNameOverride(oPC, "", OBJECT_INVALID, PC_NAME_OVERRIDE_TYPE_REPLACE_ALWAYS);
    DeleteLocalInt   (oPC, MSK_LVAR_ACTIVE_ID);
    DeleteLocalString(oPC, MSK_LVAR_ACTIVE_NAME);
    MskSetSuspicion  (oPC, 0);

    MskBurnMask(oPC, nMaskId);

    SendMessageToPC(oPC, "[Masquerade] Oblicze \"" + sName + "\" zostało przejrzane — maska spłonęła na twarzy!");
    FloatingTextStringOnCreature(
        "TOŻSAMOŚĆ ODKRYTA!",
        oPC, FALSE);

    // Efekt wizualny — VFX gory/zaskoczenia na postaci
    ApplyEffectToObject(DURATION_TYPE_TEMPORARY,
        EffectVisualEffect(VFX_IMP_FLAME_M),
        oPC, 2.0);

    int nToken = NuiFindWindow(oPC, MSK_WINDOW);
    if(nToken != 0)
        MskFeedPanel(oPC, nToken);
}

// ----------------------------------------------------------------
// Suspicion heartbeat
// ----------------------------------------------------------------

void MskScheduleHeartbeat(object oPC)
{
    // Zapobiega kolejkowaniu wielu instancji przez flage
    if(GetLocalInt(oPC, MSK_LVAR_HB_DELAY) == 1) return;
    SetLocalInt(oPC, MSK_LVAR_HB_DELAY, 1);
    DelayCommand(MSK_HB_INTERVAL, MskTickSuspicion(oPC));
}

void MskTickSuspicion(object oPC)
{
    DeleteLocalInt(oPC, MSK_LVAR_HB_DELAY);
    if(!GetIsObjectValid(oPC) || !GetIsPC(oPC)) return;
    if(!MskIsActive(oPC)) return;

    int nMaskId = GetLocalInt(oPC, MSK_LVAR_ACTIVE_ID);
    json jMask  = MskGetMaskById(nMaskId);
    int nRate   = 1;
    if(JsonGetType(jMask) != JSON_TYPE_NULL)
        nRate = JsonGetInt(JsonObjectGet(jMask, "susp_rate"));

    int nInc = MSK_SUSP_PASSIVE * nRate;

    // Bonus podejrzen za walke
    if(GetIsInCombat(oPC))
        nInc += MSK_SUSP_COMBAT;

    int nSusp = MskGetSuspicion(oPC) + nInc;
    MskSetSuspicion(oPC, nSusp);

    // Aktualizuj panel jesli otwarty
    int nToken = NuiFindWindow(oPC, MSK_WINDOW);
    if(nToken != 0)
        MskFeedPanel(oPC, nToken);

    if(MskGetSuspicion(oPC) >= MSK_SUSP_MAX)
    {
        MskBlowCover(oPC);
        return;
    }

    // Ostrzezenie przy przekroczeniu progu
    int nPrev = nSusp - nInc;
    if(nPrev < MSK_SUSP_WARN && MskGetSuspicion(oPC) >= MSK_SUSP_WARN)
        SendMessageToPC(oPC, "[Masquerade] Pieczęć oblicza pulsuje słabo… ktoś zaraz zacznie się przyglądać.");
    if(nPrev < MSK_SUSP_DANGER && MskGetSuspicion(oPC) >= MSK_SUSP_DANGER)
        SendMessageToPC(oPC, "[Masquerade] Maska drżeje — zaraz pęknie. Uciekaj lub zdejmij oblicze!");

    // Zaplanuj nastepny tick
    MskScheduleHeartbeat(oPC);
}

// Wywoływane przez sys_on_spell lub inny zewnetrzny hook
void MskAddSpellSuspicion(object oPC)
{
    if(!MskIsActive(oPC)) return;
    MskSetSuspicion(oPC, MskGetSuspicion(oPC) + MSK_SUSP_SPELL);

    int nToken = NuiFindWindow(oPC, MSK_WINDOW);
    if(nToken != 0)
        MskFeedPanel(oPC, nToken);
}
