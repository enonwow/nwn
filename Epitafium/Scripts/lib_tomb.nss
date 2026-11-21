// lib_tomb.nss — NUI layout, window management and placeable spawning for Epitafium

#include "lib_tomb_def"

// ----------------------------------------------------------------
// Write-epitaph window
// ----------------------------------------------------------------

json BuildTombWriteLayout(object oPC)
{
    float fBtnH  = GetNuiScaleDimension(oPC, 32.0);
    float fRowH  = GetNuiScaleDimension(oPC, 28.0);
    float fEpiH  = GetNuiScaleDimension(oPC, 130.0);

    // Character name (read-only)
    json jNameLbl = NuiLabel(JsonString("Postać:"), JsonInt(NUI_HALIGN_LEFT), JsonInt(NUI_VALIGN_MIDDLE));
    jNameLbl = NuiWidth(jNameLbl, GetNuiScaleDimension(oPC, 80.0));
    jNameLbl = NuiHeight(jNameLbl, fRowH);

    json jNameVal = NuiLabel(NuiBind(TOMB_BIND_W_NAME), JsonInt(NUI_HALIGN_LEFT), JsonInt(NUI_VALIGN_MIDDLE));
    jNameVal = NuiStyleForegroundColor(jNameVal, NuiColor(220, 200, 140));
    jNameVal = NuiHeight(jNameVal, fRowH);

    json jNameRow = JsonArray();
    jNameRow = JsonArrayInsert(jNameRow, jNameLbl);
    jNameRow = JsonArrayInsert(jNameRow, jNameVal);

    // Separator label
    json jSepLbl = NuiLabel(
        JsonString("─────────────────────────────────────────────"),
        JsonInt(NUI_HALIGN_LEFT), JsonInt(NUI_VALIGN_MIDDLE));
    jSepLbl = NuiStyleForegroundColor(jSepLbl, NuiColor(80, 60, 40));
    jSepLbl = NuiHeight(jSepLbl, GetNuiScaleDimension(oPC, 18.0));

    // Cause of death (editable — player can adjust flavor)
    json jCauseLbl = NuiLabel(JsonString("Przyczyna:"), JsonInt(NUI_HALIGN_LEFT), JsonInt(NUI_VALIGN_MIDDLE));
    jCauseLbl = NuiWidth(jCauseLbl, GetNuiScaleDimension(oPC, 90.0));
    jCauseLbl = NuiHeight(jCauseLbl, fBtnH);

    json jCauseField = NuiTextEdit(JsonString(""), NuiBind(TOMB_BIND_W_CAUSE), TOMB_CAUSE_MAX, FALSE);
    jCauseField = NuiHeight(jCauseField, fBtnH);

    json jCauseRow = JsonArray();
    jCauseRow = JsonArrayInsert(jCauseRow, jCauseLbl);
    jCauseRow = JsonArrayInsert(jCauseRow, jCauseField);

    // Epitaph header
    json jEpiLbl = NuiLabel(
        JsonString("Ostatnie słowa (max 200 znaków):"),
        JsonInt(NUI_HALIGN_LEFT), JsonInt(NUI_VALIGN_MIDDLE));
    jEpiLbl = NuiStyleForegroundColor(jEpiLbl, NuiColor(180, 160, 100));
    jEpiLbl = NuiHeight(jEpiLbl, GetNuiScaleDimension(oPC, 22.0));

    // Epitaph text area
    json jEpiField = NuiTextEdit(
        JsonString("Tu spoczywają moje ostatnie słowa..."),
        NuiBind(TOMB_BIND_W_EPITAPH),
        TOMB_EPITAPH_MAX, TRUE);
    jEpiField = NuiHeight(jEpiField, fEpiH);

    // Remaining chars hint
    json jHintLbl = NuiLabel(NuiBind(TOMB_BIND_W_HINT), JsonInt(NUI_HALIGN_RIGHT), JsonInt(NUI_VALIGN_MIDDLE));
    jHintLbl = NuiStyleForegroundColor(jHintLbl, NuiColor(120, 100, 70));
    jHintLbl = NuiHeight(jHintLbl, GetNuiScaleDimension(oPC, 20.0));

    // Buttons
    json jEngraveBtn = NuiButton(JsonString("Wyryt napis"));
    jEngraveBtn = NuiId(jEngraveBtn, TOMB_BTN_ENGRAVE);
    jEngraveBtn = NuiWidth(jEngraveBtn, GetNuiScaleDimension(oPC, 130.0));
    jEngraveBtn = NuiHeight(jEngraveBtn, fBtnH);

    json jSkipBtn = NuiButton(JsonString("Pomiń"));
    jSkipBtn = NuiId(jSkipBtn, TOMB_BTN_SKIP);
    jSkipBtn = NuiWidth(jSkipBtn, GetNuiScaleDimension(oPC, 80.0));
    jSkipBtn = NuiHeight(jSkipBtn, fBtnH);

    json jBtnRow = JsonArray();
    jBtnRow = JsonArrayInsert(jBtnRow, NuiSpacer());
    jBtnRow = JsonArrayInsert(jBtnRow, jEngraveBtn);
    jBtnRow = JsonArrayInsert(jBtnRow, jSkipBtn);

    // Assemble
    json jCol = JsonArray();
    jCol = JsonArrayInsert(jCol, NuiRow(jNameRow));
    jCol = JsonArrayInsert(jCol, jSepLbl);
    jCol = JsonArrayInsert(jCol, NuiRow(jCauseRow));
    jCol = JsonArrayInsert(jCol, CreateEmptyRow(oPC, 6.0));
    jCol = JsonArrayInsert(jCol, jEpiLbl);
    jCol = JsonArrayInsert(jCol, jEpiField);
    jCol = JsonArrayInsert(jCol, jHintLbl);
    jCol = JsonArrayInsert(jCol, CreateEmptyRow(oPC, 6.0));
    jCol = JsonArrayInsert(jCol, NuiRow(jBtnRow));

    json jSide = NuiCol(JsonArrayInsert(JsonArray(), NuiSpacer()));
    float fContent = GetNuiScaleDimension(oPC, 500.0);
    json jMainRow = JsonArray();
    jMainRow = JsonArrayInsert(jMainRow, jSide);
    jMainRow = JsonArrayInsert(jMainRow, NuiWidth(NuiCol(jCol), fContent));
    jMainRow = JsonArrayInsert(jMainRow, jSide);
    return NuiRow(jMainRow);
}

void TombCreateWriteWindow(object oPC)
{
    if(NuiFindWindow(oPC, TOMB_WIN_WRITE) != 0)
        NuiDestroy(oPC, NuiFindWindow(oPC, TOMB_WIN_WRITE));

    float fW = GetNuiScaleDimension(oPC, TOMB_WRITE_W);
    float fH = GetNuiScaleDimension(oPC, TOMB_WRITE_H);
    float fX = (IntToFloat(GetPlayerDeviceProperty(oPC, PLAYER_DEVICE_PROPERTY_GUI_WIDTH))  - fW) / 2.0;
    float fY = (IntToFloat(GetPlayerDeviceProperty(oPC, PLAYER_DEVICE_PROPERTY_GUI_HEIGHT)) - fH) / 2.0;

    json jWin = NuiWindow(
        BuildTombWriteLayout(oPC),
        JsonString("Ostatnie Słowa"),
        NuiRect(fX, fY, fW, fH),
        JsonBool(FALSE),
        JsonBool(FALSE),
        JsonBool(TRUE),
        JsonBool(FALSE),
        JsonBool(TRUE));

    int nToken = NuiCreate(oPC, jWin, TOMB_WIN_WRITE, TOMB_EV_SCRIPT);

    // Pre-fill fields
    string sCause = GetLocalString(oPC, TOMB_LVAR_CAUSE);
    if(sCause == "") sCause = "poległ(a) w walce";

    NuiSetBind(oPC, nToken, TOMB_BIND_W_NAME,    JsonString(GetName(oPC)));
    NuiSetBind(oPC, nToken, TOMB_BIND_W_CAUSE,   JsonString(sCause));
    NuiSetBind(oPC, nToken, TOMB_BIND_W_EPITAPH, JsonString(""));
    NuiSetBind(oPC, nToken, TOMB_BIND_W_HINT,    JsonString("0 / 200"));

    NuiSetBindWatch(oPC, nToken, TOMB_BIND_W_EPITAPH, TRUE);
}

// ----------------------------------------------------------------
// Read-memorial window
// ----------------------------------------------------------------

json BuildTombReadLayout(object oPC)
{
    float fBtnH  = GetNuiScaleDimension(oPC, 32.0);
    float fEpiH  = GetNuiScaleDimension(oPC, 120.0);

    // "Tu spoczywa..." header
    json jHeader = NuiLabel(NuiBind(TOMB_BIND_R_HEADER),
        JsonInt(NUI_HALIGN_CENTER), JsonInt(NUI_VALIGN_MIDDLE));
    jHeader = NuiStyleForegroundColor(jHeader, NuiColor(220, 200, 140));
    jHeader = NuiHeight(jHeader, GetNuiScaleDimension(oPC, 34.0));

    // Ornamental separator
    json jOrn = NuiLabel(
        JsonString("✦ ─────────────────────────── ✦"),
        JsonInt(NUI_HALIGN_CENTER), JsonInt(NUI_VALIGN_MIDDLE));
    jOrn = NuiStyleForegroundColor(jOrn, NuiColor(90, 70, 45));
    jOrn = NuiHeight(jOrn, GetNuiScaleDimension(oPC, 20.0));

    // Date + cause row
    json jDateLbl = NuiLabel(NuiBind(TOMB_BIND_R_DATE),
        JsonInt(NUI_HALIGN_LEFT), JsonInt(NUI_VALIGN_MIDDLE));
    jDateLbl = NuiStyleForegroundColor(jDateLbl, NuiColor(160, 140, 100));
    jDateLbl = NuiHeight(jDateLbl, GetNuiScaleDimension(oPC, 24.0));

    json jCauseLbl = NuiLabel(NuiBind(TOMB_BIND_R_CAUSE),
        JsonInt(NUI_HALIGN_RIGHT), JsonInt(NUI_VALIGN_MIDDLE));
    jCauseLbl = NuiStyleForegroundColor(jCauseLbl, NuiColor(160, 100, 80));
    jCauseLbl = NuiHeight(jCauseLbl, GetNuiScaleDimension(oPC, 24.0));

    json jMetaRow = JsonArray();
    jMetaRow = JsonArrayInsert(jMetaRow, jDateLbl);
    jMetaRow = JsonArrayInsert(jMetaRow, NuiSpacer());
    jMetaRow = JsonArrayInsert(jMetaRow, jCauseLbl);

    // Epitaph text block
    json jEpiText = NuiGroup(NuiText(NuiBind(TOMB_BIND_R_EPITAPH), FALSE), TRUE, NUI_SCROLLBARS_AUTO);
    jEpiText = NuiHeight(jEpiText, fEpiH);

    // Tribute count
    json jTribLbl = NuiLabel(NuiBind(TOMB_BIND_R_TRIBUTE),
        JsonInt(NUI_HALIGN_CENTER), JsonInt(NUI_VALIGN_MIDDLE));
    jTribLbl = NuiStyleForegroundColor(jTribLbl, NuiColor(130, 110, 80));
    jTribLbl = NuiHeight(jTribLbl, GetNuiScaleDimension(oPC, 22.0));

    // Buttons
    json jTribBtn = NuiButton(NuiBind(TOMB_BIND_R_BTN_TRB));
    jTribBtn = NuiId(jTribBtn, TOMB_BTN_TRIBUTE);
    jTribBtn = NuiEnabled(jTribBtn, NuiBind(TOMB_BIND_R_BTN_ENA));
    jTribBtn = NuiWidth(jTribBtn, GetNuiScaleDimension(oPC, 180.0));
    jTribBtn = NuiHeight(jTribBtn, fBtnH);
    jTribBtn = NuiTooltip(jTribBtn, JsonString(
        "Złóż hołd poległemu. Kosztuje " + IntToString(TOMB_TRIBUTE_COST)
        + " zł, lecz błogosławieństwo poległego sprzyja ci przez godzinę."));

    json jCloseBtn = NuiButton(JsonString("Zamknij"));
    jCloseBtn = NuiId(jCloseBtn, TOMB_BTN_CLOSE);
    jCloseBtn = NuiWidth(jCloseBtn, GetNuiScaleDimension(oPC, 90.0));
    jCloseBtn = NuiHeight(jCloseBtn, fBtnH);

    json jBtnRow = JsonArray();
    jBtnRow = JsonArrayInsert(jBtnRow, jTribBtn);
    jBtnRow = JsonArrayInsert(jBtnRow, NuiSpacer());
    jBtnRow = JsonArrayInsert(jBtnRow, jCloseBtn);

    // Assemble
    json jCol = JsonArray();
    jCol = JsonArrayInsert(jCol, jHeader);
    jCol = JsonArrayInsert(jCol, jOrn);
    jCol = JsonArrayInsert(jCol, NuiRow(jMetaRow));
    jCol = JsonArrayInsert(jCol, CreateEmptyRow(oPC, 4.0));
    jCol = JsonArrayInsert(jCol, jEpiText);
    jCol = JsonArrayInsert(jCol, CreateEmptyRow(oPC, 4.0));
    jCol = JsonArrayInsert(jCol, jTribLbl);
    jCol = JsonArrayInsert(jCol, CreateEmptyRow(oPC, 6.0));
    jCol = JsonArrayInsert(jCol, NuiRow(jBtnRow));

    json jSide = NuiCol(JsonArrayInsert(JsonArray(), NuiSpacer()));
    float fContent = GetNuiScaleDimension(oPC, 460.0);
    json jMainRow = JsonArray();
    jMainRow = JsonArrayInsert(jMainRow, jSide);
    jMainRow = JsonArrayInsert(jMainRow, NuiWidth(NuiCol(jCol), fContent));
    jMainRow = JsonArrayInsert(jMainRow, jSide);
    return NuiRow(jMainRow);
}

void FeedTombReadWindow(object oPC, int nToken, json jMem)
{
    string sName    = JsonGetString(JsonObjectGet(jMem, "char_name"));
    string sCause   = JsonGetString(JsonObjectGet(jMem, "cause"));
    string sEpitaph = JsonGetString(JsonObjectGet(jMem, "epitaph"));
    int    nDiedAt  = JsonGetInt   (JsonObjectGet(jMem, "died_at"));
    int    nTribs   = JsonGetInt   (JsonObjectGet(jMem, "tribute_cnt"));

    string sDate = TombFormatDate(nDiedAt);

    NuiSetBind(oPC, nToken, TOMB_BIND_R_HEADER,
        JsonString("Tu spoczywa " + sName));
    NuiSetBind(oPC, nToken, TOMB_BIND_R_DATE,
        JsonString(sDate));
    NuiSetBind(oPC, nToken, TOMB_BIND_R_CAUSE,
        JsonString(sCause));
    NuiSetBind(oPC, nToken, TOMB_BIND_R_EPITAPH,
        JsonString(sEpitaph != "" ? "\"" + sEpitaph + "\"" : "— brak słów —"));

    string sTribText;
    if(nTribs == 0)     sTribText = "Nikt jeszcze nie złożył tu hołdu.";
    else if(nTribs == 1) sTribText = "1 pielgrzym złożył tu hołd.";
    else                sTribText = IntToString(nTribs) + " pielgrzymów złożyło tu hołd.";
    NuiSetBind(oPC, nToken, TOMB_BIND_R_TRIBUTE, JsonString(sTribText));

    // Tribute button — disabled for own tombstone
    string sMyUuid = GetObjectUUID(oPC);
    string sOwner  = JsonGetString(JsonObjectGet(jMem, "char_uuid"));
    int bCanTrib   = (sMyUuid != sOwner);
    NuiSetBind(oPC, nToken, TOMB_BIND_R_BTN_TRB,
        JsonString("Złóż hołd (" + IntToString(TOMB_TRIBUTE_COST) + " zł)"));
    NuiSetBind(oPC, nToken, TOMB_BIND_R_BTN_ENA, JsonBool(bCanTrib));
}

void TombCreateReadWindow(object oPC, int nMemorialId)
{
    json jMem = TombGetMemorial(nMemorialId);
    if(JsonGetType(jMem) == JSON_TYPE_NULL)
    {
        SendMessageToPC(oPC, "[Epitafium] Nagrobek jest zniszczony — zapis zatarł czas.");
        return;
    }

    if(NuiFindWindow(oPC, TOMB_WIN_READ) != 0)
        NuiDestroy(oPC, NuiFindWindow(oPC, TOMB_WIN_READ));

    float fW = GetNuiScaleDimension(oPC, TOMB_READ_W);
    float fH = GetNuiScaleDimension(oPC, TOMB_READ_H);
    float fX = (IntToFloat(GetPlayerDeviceProperty(oPC, PLAYER_DEVICE_PROPERTY_GUI_WIDTH))  - fW) / 2.0;
    float fY = (IntToFloat(GetPlayerDeviceProperty(oPC, PLAYER_DEVICE_PROPERTY_GUI_HEIGHT)) - fH) / 2.0;

    json jWin = NuiWindow(
        BuildTombReadLayout(oPC),
        JsonString("Nagrobek"),
        NuiRect(fX, fY, fW, fH),
        JsonBool(FALSE),
        JsonBool(FALSE),
        JsonBool(TRUE),
        JsonBool(FALSE),
        JsonBool(TRUE));

    int nToken = NuiCreate(oPC, jWin, TOMB_WIN_READ, TOMB_EV_SCRIPT);

    SetLocalInt(oPC, TOMB_LVAR_MEM_ID, nMemorialId);
    FeedTombReadWindow(oPC, nToken, jMem);
}

// ----------------------------------------------------------------
// Tombstone placeable
// ----------------------------------------------------------------

void TombSpawnStone(int nId, json jMem)
{
    string sAreaTag = JsonGetString(JsonObjectGet(jMem, "area_tag"));
    float  fX       = JsonGetFloat (JsonObjectGet(jMem, "pos_x"));
    float  fY       = JsonGetFloat (JsonObjectGet(jMem, "pos_y"));
    float  fZ       = JsonGetFloat (JsonObjectGet(jMem, "pos_z"));
    string sName    = JsonGetString(JsonObjectGet(jMem, "char_name"));

    object oArea = GetObjectByTag(sAreaTag);
    if(!GetIsObjectValid(oArea)) return;

    string sStoneTag = "tomb_" + IntToString(nId);
    location lSpawn  = Location(oArea, Vector(fX, fY, fZ), 0.0);

    object oStone = CreateObject(OBJECT_TYPE_PLACEABLE, TOMB_STONE_RESREF, lSpawn, FALSE, sStoneTag);
    if(!GetIsObjectValid(oStone)) return;

    SetName(oStone, "Nagrobek — " + sName);
    SetDescription(oStone, TombBuildStoneDesc(jMem));
    SetLocalInt(oStone, TOMB_LVAR_STONE_ID, nId);
    SetEventScript(oStone, EVENT_SCRIPT_PLACEABLE_ON_USED, TOMB_STONE_SCRIPT);
}

// ----------------------------------------------------------------
// Finalise — called when PC clicks "Wyryt napis"
// ----------------------------------------------------------------

void TombFinalizeMemorial(object oPC, int nToken)
{
    string sEpitaph = JsonGetString(NuiGetBind(oPC, nToken, TOMB_BIND_W_EPITAPH));
    string sCause   = JsonGetString(NuiGetBind(oPC, nToken, TOMB_BIND_W_CAUSE));
    string sAreaTag = GetLocalString(oPC, TOMB_LVAR_AREA);
    float  fX       = GetLocalFloat (oPC, TOMB_LVAR_POS_X);
    float  fY       = GetLocalFloat (oPC, TOMB_LVAR_POS_Y);
    float  fZ       = GetLocalFloat (oPC, TOMB_LVAR_POS_Z);

    if(sAreaTag == "")
    {
        SendMessageToPC(oPC, "[Epitafium] Nie można ustalić miejsca śmierci.");
        NuiDestroy(oPC, nToken);
        TombClearDeathLvars(oPC);
        return;
    }

    if(sCause == "") sCause = "poległ(a) w walce";

    int nId = TombInsertMemorial(
        GetObjectUUID(oPC), GetName(oPC), sAreaTag,
        fX, fY, fZ, sCause, sEpitaph);

    NuiDestroy(oPC, nToken);
    TombClearDeathLvars(oPC);

    if(nId <= 0)
    {
        SendMessageToPC(oPC, "[Epitafium] Błąd zapisu — dłuto ześlizgnęło się z kamienia.");
        return;
    }

    json jMem = TombGetMemorial(nId);
    TombSpawnStone(nId, jMem);

    FloatingTextStringOnCreature(
        "Kamień przyjął twoje ostatnie słowa...", oPC, FALSE);
}

// ----------------------------------------------------------------
// Tribute — called from event handler
// ----------------------------------------------------------------

void TombPayTribute(object oPC, int nToken, int nMemId)
{
    if(GetGold(oPC) < TOMB_TRIBUTE_COST)
    {
        SendMessageToPC(oPC, "[Epitafium] Nie masz dość złota, by złożyć godny hołd (" +
            IntToString(TOMB_TRIBUTE_COST) + " zł).");
        return;
    }

    AssignCommand(oPC, TakeGoldFromCreature(TOMB_TRIBUTE_COST, oPC, TRUE));
    TombAddTribute(nMemId, 1);

    // Blessing: AC +1 / Spot +2 for 1 hour
    effect eFx = EffectLinkEffects(
        EffectACIncrease(1, AC_DEFLECTION_BONUS),
        EffectSkillIncrease(SKILL_SPOT, 2));
    eFx = SupernaturalEffect(EffectLinkEffects(eFx,
        EffectVisualEffect(VFX_DUR_GLOW_LIGHT_YELLOW)));
    ApplyEffectToObject(DURATION_TYPE_TEMPORARY, eFx, oPC,
        IntToFloat(TOMB_TRIBUTE_DUR));

    FloatingTextStringOnCreature(
        "Błogosławieństwo Poległego spływa na ciebie...", oPC, FALSE);

    // Refresh read window
    json jMem = TombGetMemorial(nMemId);
    if(JsonGetType(jMem) != JSON_TYPE_NULL)
        FeedTombReadWindow(oPC, nToken, jMem);

    // Update stone description if it exists in the current area
    string sStoneTag = "tomb_" + IntToString(nMemId);
    object oStone = GetObjectByTag(sStoneTag);
    if(GetIsObjectValid(oStone))
        SetDescription(oStone, TombBuildStoneDesc(jMem));
}

// ----------------------------------------------------------------
// Respawn all persisted memorials on module load
// ----------------------------------------------------------------

void TombRespawnAll()
{
    json jAll  = TombGetAllActive();
    int  nCount = JsonGetLength(jAll);
    int  i;
    for(i = 0; i < nCount; i++)
    {
        json jMem = JsonArrayGet(jAll, i);
        int  nId  = JsonGetInt(JsonObjectGet(jMem, "id"));
        TombSpawnStone(nId, jMem);
    }
}
