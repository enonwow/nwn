#include "lib_sgl_def"

// ----------------------------------------------------------------
// Sigil type metadata
// ----------------------------------------------------------------

string SglGetTypeName(int nType)
{
    switch(nType)
    {
        case SGL_TYPE_ALARM: return "Alarm";
        case SGL_TYPE_SHOCK: return "Porażenie";
        case SGL_TYPE_HOLD:  return "Unieruchomienie";
        case SGL_TYPE_FEAR:  return "Trwoga";
    }
    return "Nieznany";
}

string SglGetTypeDesc(int nType)
{
    switch(nType)
    {
        case SGL_TYPE_ALARM:
            return "Kamień pulsuje bladym blaskiem. Kiedy intruz wkroczy w krąg znaku, "
                 + "właściciel zostaje powiadomiony — cichy strażnik, co nie atakuje, "
                 + "lecz nigdy nie śpi.";
        case SGL_TYPE_SHOCK:
            return "Runa iskrzy mroczną elektrycznością, wyryta krwią i solą. Każdy, kto "
                 + "przekroczy granicę znaku bez klucza dostępu, przyjmie na siebie "
                 + "uderzenie piorunu.";
        case SGL_TYPE_HOLD:
            return "Symbol więzi, wyryta w kamieniu bladym ogniem. Intruz zastyga w miejscu, "
                 + "skuty niewidzialnym kajdanem przez kilka okrutnych sekund.";
        case SGL_TYPE_FEAR:
            return "Pieczęć strachu przemawia do pierwotnych lęków. Intruz traci odwagę "
                 + "i ucieka, ogarnięty paniką, której nie potrafi wyjaśnić.";
    }
    return "";
}

json SglGetTypeColor(int nType)
{
    switch(nType)
    {
        case SGL_TYPE_ALARM: return NuiColor(220, 220, 160);
        case SGL_TYPE_SHOCK: return NuiColor(100, 160, 255);
        case SGL_TYPE_HOLD:  return NuiColor(100, 220, 140);
        case SGL_TYPE_FEAR:  return NuiColor(200,  80, 200);
    }
    return NuiColor(200, 200, 200);
}

int SglGetDefaultCharges(int nType)
{
    switch(nType)
    {
        case SGL_TYPE_ALARM: return SGL_CHARGES_ALARM;
        case SGL_TYPE_SHOCK: return SGL_CHARGES_SHOCK;
        case SGL_TYPE_HOLD:  return SGL_CHARGES_HOLD;
        case SGL_TYPE_FEAR:  return SGL_CHARGES_FEAR;
    }
    return 5;
}

// Returns "3/5" style string for display
string SglChargesLabel(int nCurrent, int nType)
{
    return IntToString(nCurrent) + "/" + IntToString(SglGetDefaultCharges(nType));
}

// ----------------------------------------------------------------
// Notify owner if online
// ----------------------------------------------------------------

void SglNotifyOwner(string sOwnerUuid, int nSigilId, int nType,
                    string sAreaName, int nChargesLeft)
{
    string sTypeName = SglGetTypeName(nType);
    string sMsg;

    if(nChargesLeft <= 0)
        sMsg = "[Znak Ochronny] " + sTypeName + " w strefie „" + sAreaName
             + "" wyczerpał ładunki i zgasł.";
    else
        sMsg = "[Znak Ochronny] " + sTypeName + " wyzwolony w strefie „" + sAreaName
             + "" — pozostało " + IntToString(nChargesLeft) + " ładunków.";

    object oPC = GetFirstPC();
    while(GetIsObjectValid(oPC))
    {
        if(GetObjectUUID(oPC) == sOwnerUuid)
        {
            SendMessageToPC(oPC, sMsg);
            int nToken = NuiFindWindow(oPC, SGL_WINDOW);
            if(nToken != 0)
                FeedSglList(oPC, nToken);
            return;
        }
        oPC = GetNextPC();
    }
}

// ----------------------------------------------------------------
// Apply sigil trigger effect on oVictim
// ----------------------------------------------------------------

void SglFireEffect(object oVictim, int nType, int nSigilId,
                   string sOwnerUuid, location lSigil, string sAreaName)
{
    // Sigil-location visual pulse
    int nLocVfx = VFX_IMP_SONIC;
    switch(nType)
    {
        case SGL_TYPE_ALARM: nLocVfx = VFX_IMP_SONIC;       break;
        case SGL_TYPE_SHOCK: nLocVfx = VFX_IMP_LIGHTNING_S; break;
        case SGL_TYPE_HOLD:  nLocVfx = VFX_IMP_HOLD;        break;
        case SGL_TYPE_FEAR:  nLocVfx = VFX_IMP_FEAR_S;      break;
    }
    ApplyEffectAtLocation(DURATION_TYPE_INSTANT, EffectVisualEffect(nLocVfx), lSigil);

    // Victim effect
    switch(nType)
    {
        case SGL_TYPE_ALARM:
            // No combat effect — only notification
            FloatingTextStringOnCreature(
                "Signum Custodis!", oVictim, FALSE);
            SendMessageToPC(oVictim,
                "[Znak Ochronny] Alarm! Naruszasz chroniony krąg — właściciel zostaje powiadomiony.");
            break;

        case SGL_TYPE_SHOCK:
            ApplyEffectToObject(DURATION_TYPE_INSTANT,
                EffectVisualEffect(VFX_COM_HIT_ELECTRICAL), oVictim);
            ApplyEffectToObject(DURATION_TYPE_INSTANT,
                EffectDamage(d8(1), DAMAGE_TYPE_ELECTRICAL, DAMAGE_POWER_NORMAL), oVictim);
            SendMessageToPC(oVictim,
                "[Znak Ochronny] Runa porażenia uderza cię elektryczną mocą!");
            break;

        case SGL_TYPE_HOLD:
            ApplyEffectToObject(DURATION_TYPE_TEMPORARY,
                EffectParalyze(), oVictim, 6.0);
            ApplyEffectToObject(DURATION_TYPE_INSTANT,
                EffectVisualEffect(VFX_DUR_PARALYZED), oVictim);
            SendMessageToPC(oVictim,
                "[Znak Ochronny] Znak więzi zaciska się na tobie — nie możesz się ruszyć!");
            break;

        case SGL_TYPE_FEAR:
            ApplyEffectToObject(DURATION_TYPE_TEMPORARY,
                EffectFrightened(), oVictim, 8.0);
            ApplyEffectToObject(DURATION_TYPE_INSTANT,
                EffectVisualEffect(VFX_IMP_FEAR_S), oVictim);
            SendMessageToPC(oVictim,
                "[Znak Ochronny] Pieczęć trwogi wypełnia twój umysł pierwotnym strachem!");
            break;
    }

    int nRemaining = SglDecrementCharges(nSigilId);
    SglNotifyOwner(sOwnerUuid, nSigilId, nType, sAreaName, nRemaining);

    if(nRemaining <= 0)
        SglRemoveSigil(nSigilId);
}

// ----------------------------------------------------------------
// Heartbeat proximity check — called from sys_on_hb.nss
// ----------------------------------------------------------------

void SglCheckProximity()
{
    json jSigils = SglGetAllActiveSigils();
    int nSigilCount = JsonGetLength(jSigils);
    if(nSigilCount == 0) return;

    object oPC = GetFirstPC();
    while(GetIsObjectValid(oPC))
    {
        if(!GetIsPC(oPC) || GetIsDMPossessed(oPC))
        {
            oPC = GetNextPC();
            continue;
        }

        object oArea    = GetArea(oPC);
        string sPCArea  = GetTag(oArea);
        location lPC    = GetLocation(oPC);

        int i;
        for(i = 0; i < nSigilCount; i++)
        {
            json jSig = JsonArrayGet(jSigils, i);

            if(JsonGetString(JsonObjectGet(jSig, "area_tag")) != sPCArea) continue;

            int    nId        = JsonGetInt   (JsonObjectGet(jSig, "id"));
            string sOwnerUuid = JsonGetString(JsonObjectGet(jSig, "owner_uuid"));

            if(GetObjectUUID(oPC) == sOwnerUuid) continue;

            // Cooldown prevents re-triggering the same sigil within SGL_COOLDOWN_SECONDS
            string sCool = "SGL_COOL_" + IntToString(nId);
            if(GetLocalInt(oPC, sCool)) continue;

            float fX = JsonGetFloat(JsonObjectGet(jSig, "pos_x"));
            float fY = JsonGetFloat(JsonObjectGet(jSig, "pos_y"));
            float fZ = JsonGetFloat(JsonObjectGet(jSig, "pos_z"));

            location lSig = Location(oArea, Vector(fX, fY, fZ), 0.0);
            float fDist   = GetDistanceBetweenLocations(lPC, lSig);

            if(fDist < 0.0 || fDist > SGL_TRIGGER_RADIUS) continue;

            if(SglIsAttuned(nId, GetObjectUUID(oPC))) continue;

            // Arm cooldown before firing so re-entrant calls during effect don't double-fire
            SetLocalInt(oPC, sCool, 1);
            DelayCommand(IntToFloat(SGL_COOLDOWN_SECONDS), DeleteLocalInt(oPC, sCool));

            int    nType     = JsonGetInt   (JsonObjectGet(jSig, "sigil_type"));
            string sAreaName = JsonGetString(JsonObjectGet(jSig, "area_name"));
            SglFireEffect(oPC, nType, nId, sOwnerUuid, lSig, sAreaName);
        }

        oPC = GetNextPC();
    }
}

// ----------------------------------------------------------------
// Place a new sigil at caller's location
// ----------------------------------------------------------------

void SglPlaceAtLocation(object oPC, int nType)
{
    if(SglGetPlayerSigilCount(oPC) >= SGL_MAX_SIGILS)
    {
        SendMessageToPC(oPC, "[Znak Ochronny] Nie możesz utrzymać więcej niż "
            + IntToString(SGL_MAX_SIGILS) + " aktywnych znaków.");
        return;
    }

    object oArea    = GetArea(oPC);
    vector vPos     = GetPosition(oPC);
    string sAreaTag = GetTag(oArea);
    string sAreaName= GetName(oArea);
    int    nCharges = SglGetDefaultCharges(nType);

    int nId = SglPlaceSigil(oPC, sAreaTag, sAreaName,
                             vPos.x, vPos.y, vPos.z, nType, nCharges);
    if(nId <= 0)
    {
        SendMessageToPC(oPC, "[Znak Ochronny] Nie udało się wpisać znaku w kamień.");
        return;
    }

    // Temporary glow at placement site (1 hour; cleared on restart, restored by sys_on_load)
    location lPlace = Location(oArea, vPos, 0.0);
    ApplyEffectAtLocation(DURATION_TYPE_TEMPORARY,
        EffectVisualEffect(VFX_DUR_PROT_PREMONITION), lPlace, 3600.0);

    SendMessageToPC(oPC, "[Znak Ochronny] " + SglGetTypeName(nType)
        + " wpisany w kamień. Ładunki: " + IntToString(nCharges) + ".");
}

// ----------------------------------------------------------------
// Build — List View
// ----------------------------------------------------------------

json BuildSglListView(object oPC)
{
    float fBtnH  = GetNuiScaleDimension(oPC, 28.0);
    float fRowH  = GetNuiScaleDimension(oPC, 26.0);
    float fListH = GetNuiScaleDimension(oPC, 280.0);
    float fTypeW = GetNuiScaleDimension(oPC, 130.0);
    float fChgW  = GetNuiScaleDimension(oPC, 70.0);

    // Header label
    json jHeader = NuiLabel(NuiBind(SGL_BIND_HEADER),
        JsonInt(NUI_HALIGN_LEFT), JsonInt(NUI_VALIGN_MIDDLE));
    jHeader = NuiHeight(jHeader, fBtnH);

    json jPlaceBtn = NuiButton(JsonString("Nowy Znak"));
    jPlaceBtn = NuiId(jPlaceBtn, SGL_BTN_PLACE_OPEN);
    jPlaceBtn = NuiWidth(jPlaceBtn, GetNuiScaleDimension(oPC, 110.0));
    jPlaceBtn = NuiHeight(jPlaceBtn, fBtnH);

    json jTopRow = JsonArray();
    jTopRow = JsonArrayInsert(jTopRow, jHeader);
    jTopRow = JsonArrayInsert(jTopRow, NuiSpacer());
    jTopRow = JsonArrayInsert(jTopRow, jPlaceBtn);

    // Row template: [Typ | Strefa (elastic) | Ładunki]
    json jTypeLbl = NuiLabel(NuiBind(SGL_BIND_ROW_TYPE),
        JsonInt(NUI_HALIGN_LEFT), JsonInt(NUI_VALIGN_MIDDLE));
    jTypeLbl = NuiStyleForegroundColor(jTypeLbl, NuiBind(SGL_BIND_ROW_COLOR));
    jTypeLbl = NuiWidth(jTypeLbl, fTypeW);

    json jAreaLbl = NuiLabel(NuiBind(SGL_BIND_ROW_AREA),
        JsonInt(NUI_HALIGN_LEFT), JsonInt(NUI_VALIGN_MIDDLE));
    jAreaLbl = NuiStyleForegroundColor(jAreaLbl, NuiBind(SGL_BIND_ROW_COLOR));

    json jChgLbl = NuiLabel(NuiBind(SGL_BIND_ROW_CHARGES),
        JsonInt(NUI_HALIGN_RIGHT), JsonInt(NUI_VALIGN_MIDDLE));
    jChgLbl = NuiStyleForegroundColor(jChgLbl, NuiBind(SGL_BIND_ROW_COLOR));
    jChgLbl = NuiWidth(jChgLbl, fChgW);

    json jCellCols = JsonArray();
    jCellCols = JsonArrayInsert(jCellCols, jTypeLbl);
    jCellCols = JsonArrayInsert(jCellCols, jAreaLbl);
    jCellCols = JsonArrayInsert(jCellCols, jChgLbl);

    json jCell = NuiGroup(NuiRow(jCellCols), TRUE, NUI_SCROLLBARS_NONE);
    jCell = NuiId(jCell, SGL_BTN_ROW);
    jCell = NuiEncouraged(jCell, NuiBind(SGL_BIND_ROW_ENC));

    json jTmpl = JsonArrayInsert(JsonArray(), NuiListTemplateCell(jCell, 0.0, TRUE));
    json jList = NuiList(jTmpl, NuiBind(SGL_BIND_LIST_COUNT), fRowH);
    jList = NuiHeight(jList, fListH);

    // Bottom action bar
    json jDisarmBtn = NuiButton(JsonString("Rozbrój"));
    jDisarmBtn = NuiId(jDisarmBtn, SGL_BTN_DISARM);
    jDisarmBtn = NuiEnabled(jDisarmBtn, NuiBind(SGL_BIND_DISARM_ENA));
    jDisarmBtn = NuiWidth(jDisarmBtn, GetNuiScaleDimension(oPC, 100.0));
    jDisarmBtn = NuiHeight(jDisarmBtn, fBtnH);
    jDisarmBtn = NuiTooltip(jDisarmBtn, JsonString("Usuń wybrany znak i odzyskaj kamień."));

    json jAttBtn = NuiButton(JsonString("Dostęp"));
    jAttBtn = NuiId(jAttBtn, SGL_BTN_ATT_OPEN);
    jAttBtn = NuiEnabled(jAttBtn, NuiBind(SGL_BIND_ATT_ENA));
    jAttBtn = NuiWidth(jAttBtn, GetNuiScaleDimension(oPC, 100.0));
    jAttBtn = NuiHeight(jAttBtn, fBtnH);
    jAttBtn = NuiTooltip(jAttBtn, JsonString("Zarządzaj kto może przejść przez wybrany znak."));

    json jBotRow = JsonArray();
    jBotRow = JsonArrayInsert(jBotRow, jDisarmBtn);
    jBotRow = JsonArrayInsert(jBotRow, NuiSpacer());
    jBotRow = JsonArrayInsert(jBotRow, jAttBtn);

    // Column assembly
    json jCol = JsonArray();
    jCol = JsonArrayInsert(jCol, NuiRow(jTopRow));
    jCol = JsonArrayInsert(jCol, CreateEmptyRow(oPC, 4.0));
    jCol = JsonArrayInsert(jCol, jList);
    jCol = JsonArrayInsert(jCol, CreateEmptyRow(oPC, 4.0));
    jCol = JsonArrayInsert(jCol, NuiRow(jBotRow));

    float fContentW = GetNuiScaleDimension(oPC, SGL_W - 40.0);
    json jSide      = NuiCol(JsonArrayInsert(JsonArray(), NuiSpacer()));
    json jMainRow   = JsonArray();
    jMainRow = JsonArrayInsert(jMainRow, jSide);
    jMainRow = JsonArrayInsert(jMainRow, NuiWidth(NuiCol(jCol), fContentW));
    jMainRow = JsonArrayInsert(jMainRow, jSide);
    return NuiRow(jMainRow);
}

// ----------------------------------------------------------------
// Build — Place View
// ----------------------------------------------------------------

json BuildSglPlaceView(object oPC)
{
    float fBtnH    = GetNuiScaleDimension(oPC, 28.0);
    float fDescH   = GetNuiScaleDimension(oPC, 130.0);
    float fArrowW  = GetNuiScaleDimension(oPC, 36.0);

    // Type picker row: [◄] Type Name [►]
    json jPrev = NuiButton(JsonString("◄"));
    jPrev = NuiId(jPrev, SGL_BTN_TYPE_PREV);
    jPrev = NuiWidth(jPrev, fArrowW);
    jPrev = NuiHeight(jPrev, fBtnH);

    json jTypeLbl = NuiLabel(NuiBind(SGL_BIND_PLACE_TYPE_LBL),
        JsonInt(NUI_HALIGN_CENTER), JsonInt(NUI_VALIGN_MIDDLE));
    json jNext = NuiButton(JsonString("►"));
    jNext = NuiId(jNext, SGL_BTN_TYPE_NEXT);
    jNext = NuiWidth(jNext, fArrowW);
    jNext = NuiHeight(jNext, fBtnH);

    json jPickerRow = JsonArray();
    jPickerRow = JsonArrayInsert(jPickerRow, jPrev);
    jPickerRow = JsonArrayInsert(jPickerRow, jTypeLbl);
    jPickerRow = JsonArrayInsert(jPickerRow, jNext);

    // Description text
    json jDesc = NuiGroup(NuiText(NuiBind(SGL_BIND_PLACE_TYPE_DESC), FALSE),
        TRUE, NUI_SCROLLBARS_NONE);
    jDesc = NuiHeight(jDesc, fDescH);

    // Charges info
    json jChgLbl = NuiLabel(NuiBind(SGL_BIND_PLACE_CHARGES),
        JsonInt(NUI_HALIGN_CENTER), JsonInt(NUI_VALIGN_MIDDLE));
    jChgLbl = NuiHeight(jChgLbl, GetNuiScaleDimension(oPC, 22.0));

    // Confirm / Back
    json jConfBtn = NuiButton(JsonString("Wpisz Znak Tutaj"));
    jConfBtn = NuiId(jConfBtn, SGL_BTN_PLACE_CONF);
    jConfBtn = NuiWidth(jConfBtn, GetNuiScaleDimension(oPC, 170.0));
    jConfBtn = NuiHeight(jConfBtn, fBtnH);

    json jBackBtn = NuiButton(JsonString("Anuluj"));
    jBackBtn = NuiId(jBackBtn, SGL_BTN_BACK);
    jBackBtn = NuiWidth(jBackBtn, GetNuiScaleDimension(oPC, 90.0));
    jBackBtn = NuiHeight(jBackBtn, fBtnH);

    json jBotRow = JsonArray();
    jBotRow = JsonArrayInsert(jBotRow, jBackBtn);
    jBotRow = JsonArrayInsert(jBotRow, NuiSpacer());
    jBotRow = JsonArrayInsert(jBotRow, jConfBtn);

    json jCol = JsonArray();
    jCol = JsonArrayInsert(jCol, CreateEmptyRow(oPC, 8.0));
    jCol = JsonArrayInsert(jCol, NuiRow(jPickerRow));
    jCol = JsonArrayInsert(jCol, CreateEmptyRow(oPC, 6.0));
    jCol = JsonArrayInsert(jCol, jDesc);
    jCol = JsonArrayInsert(jCol, jChgLbl);
    jCol = JsonArrayInsert(jCol, CreateEmptyRow(oPC, 8.0));
    jCol = JsonArrayInsert(jCol, NuiRow(jBotRow));

    float fContentW = GetNuiScaleDimension(oPC, SGL_W - 40.0);
    json jSide      = NuiCol(JsonArrayInsert(JsonArray(), NuiSpacer()));
    json jMainRow   = JsonArray();
    jMainRow = JsonArrayInsert(jMainRow, jSide);
    jMainRow = JsonArrayInsert(jMainRow, NuiWidth(NuiCol(jCol), fContentW));
    jMainRow = JsonArrayInsert(jMainRow, jSide);
    return NuiRow(jMainRow);
}

// ----------------------------------------------------------------
// Build — Attune View
// ----------------------------------------------------------------

json BuildSglAttuneView(object oPC)
{
    float fBtnH  = GetNuiScaleDimension(oPC, 28.0);
    float fRowH  = GetNuiScaleDimension(oPC, 24.0);
    float fListH = GetNuiScaleDimension(oPC, 130.0);

    // Sigil info header
    json jHeader = NuiLabel(NuiBind(SGL_BIND_ATT_HEADER),
        JsonInt(NUI_HALIGN_LEFT), JsonInt(NUI_VALIGN_MIDDLE));
    jHeader = NuiHeight(jHeader, fBtnH);

    // Attuned player list
    json jAttLbl = NuiLabel(NuiBind(SGL_BIND_ATT_NAME),
        JsonInt(NUI_HALIGN_LEFT), JsonInt(NUI_VALIGN_MIDDLE));
    json jAttCell = NuiGroup(NuiRow(JsonArrayInsert(JsonArray(), jAttLbl)),
        TRUE, NUI_SCROLLBARS_NONE);
    jAttCell = NuiId(jAttCell, SGL_BTN_ATT_ROW);
    jAttCell = NuiEncouraged(jAttCell, NuiBind(SGL_BIND_ATT_ENC));

    json jAttTmpl = JsonArrayInsert(JsonArray(), NuiListTemplateCell(jAttCell, 0.0, TRUE));
    json jAttList = NuiList(jAttTmpl, NuiBind(SGL_BIND_ATT_COUNT), fRowH);
    jAttList = NuiHeight(jAttList, fListH);

    json jRevoke = NuiButton(JsonString("Usuń dostęp"));
    jRevoke = NuiId(jRevoke, SGL_BTN_REVOKE);
    jRevoke = NuiEnabled(jRevoke, NuiBind(SGL_BIND_REVOKE_ENA));
    jRevoke = NuiWidth(jRevoke, GetNuiScaleDimension(oPC, 130.0));
    jRevoke = NuiHeight(jRevoke, fBtnH);

    // Online player list to grant access
    json jOnlineLbl = NuiLabel(JsonString("Gracze online (kliknij by nadać dostęp):"),
        JsonInt(NUI_HALIGN_LEFT), JsonInt(NUI_VALIGN_MIDDLE));
    jOnlineLbl = NuiHeight(jOnlineLbl, GetNuiScaleDimension(oPC, 20.0));

    json jOLbl = NuiLabel(NuiBind(SGL_BIND_ONLINE_NAME),
        JsonInt(NUI_HALIGN_LEFT), JsonInt(NUI_VALIGN_MIDDLE));
    json jOCell = NuiGroup(NuiRow(JsonArrayInsert(JsonArray(), jOLbl)),
        TRUE, NUI_SCROLLBARS_NONE);
    jOCell = NuiId(jOCell, SGL_BTN_ONLINE_ROW);
    jOCell = NuiEncouraged(jOCell, NuiBind(SGL_BIND_ONLINE_ENC));

    json jOTmpl = JsonArrayInsert(JsonArray(), NuiListTemplateCell(jOCell, 0.0, TRUE));
    json jOList = NuiList(jOTmpl, NuiBind(SGL_BIND_ONLINE_CNT), fRowH);
    jOList = NuiHeight(jOList, fListH);

    // Back
    json jBackBtn = NuiButton(JsonString("Wstecz"));
    jBackBtn = NuiId(jBackBtn, SGL_BTN_BACK);
    jBackBtn = NuiWidth(jBackBtn, GetNuiScaleDimension(oPC, 90.0));
    jBackBtn = NuiHeight(jBackBtn, fBtnH);

    json jRevRow = JsonArray();
    jRevRow = JsonArrayInsert(jRevRow, NuiSpacer());
    jRevRow = JsonArrayInsert(jRevRow, jRevoke);

    json jBotRow = JsonArray();
    jBotRow = JsonArrayInsert(jBotRow, jBackBtn);
    jBotRow = JsonArrayInsert(jBotRow, NuiSpacer());

    json jCol = JsonArray();
    jCol = JsonArrayInsert(jCol, jHeader);
    jCol = JsonArrayInsert(jCol, CreateEmptyRow(oPC, 4.0));
    jCol = JsonArrayInsert(jCol, jAttList);
    jCol = JsonArrayInsert(jCol, NuiRow(jRevRow));
    jCol = JsonArrayInsert(jCol, CreateEmptyRow(oPC, 6.0));
    jCol = JsonArrayInsert(jCol, jOnlineLbl);
    jCol = JsonArrayInsert(jCol, jOList);
    jCol = JsonArrayInsert(jCol, CreateEmptyRow(oPC, 4.0));
    jCol = JsonArrayInsert(jCol, NuiRow(jBotRow));

    float fContentW = GetNuiScaleDimension(oPC, SGL_W - 40.0);
    json jSide      = NuiCol(JsonArrayInsert(JsonArray(), NuiSpacer()));
    json jMainRow   = JsonArray();
    jMainRow = JsonArrayInsert(jMainRow, jSide);
    jMainRow = JsonArrayInsert(jMainRow, NuiWidth(NuiCol(jCol), fContentW));
    jMainRow = JsonArrayInsert(jMainRow, jSide);
    return NuiRow(jMainRow);
}

// ----------------------------------------------------------------
// Window create / swap
// ----------------------------------------------------------------

void CreateSglWindow(object oPC)
{
    if(NuiFindWindow(oPC, SGL_WINDOW) != 0)
    {
        NuiSetGroupLayout(oPC, NuiFindWindow(oPC, SGL_WINDOW),
            SGL_GRP_SWAP, BuildSglListView(oPC));
        FeedSglList(oPC, NuiFindWindow(oPC, SGL_WINDOW));
        return;
    }

    float fW = GetNuiScaleDimension(oPC, SGL_W);
    float fH = GetNuiScaleDimension(oPC, SGL_H);
    float fX = (IntToFloat(GetPlayerDeviceProperty(oPC, PLAYER_DEVICE_PROPERTY_GUI_WIDTH))  - fW) / 2.0;
    float fY = (IntToFloat(GetPlayerDeviceProperty(oPC, PLAYER_DEVICE_PROPERTY_GUI_HEIGHT)) - fH) / 2.0;
    json jGeom = NuiRect(fX, fY, fW, fH);

    float fBtnH = GetNuiScaleDimension(oPC, 28.0);
    json jCloseBtn = NuiButton(JsonString("X"));
    jCloseBtn = NuiId(jCloseBtn, SGL_BTN_CLOSE);
    jCloseBtn = NuiWidth(jCloseBtn, GetNuiScaleDimension(oPC, 28.0));
    jCloseBtn = NuiHeight(jCloseBtn, fBtnH);

    json jTitleRow = JsonArray();
    jTitleRow = JsonArrayInsert(jTitleRow, NuiSpacer());
    jTitleRow = JsonArrayInsert(jTitleRow, jCloseBtn);

    json jSwapGrp = NuiGroup(BuildSglListView(oPC), FALSE, NUI_SCROLLBARS_NONE);
    jSwapGrp = NuiId(jSwapGrp, SGL_GRP_SWAP);

    json jRootCols = JsonArray();
    jRootCols = JsonArrayInsert(jRootCols, NuiRow(jTitleRow));
    jRootCols = JsonArrayInsert(jRootCols, jSwapGrp);
    json jRoot = NuiCol(jRootCols);

    json jWin = NuiWindow(jRoot,
        JsonString("Znaki Ochronne"),
        NuiBind(SGL_WIN_GEOM),
        JsonBool(FALSE),
        JsonBool(FALSE),
        JsonBool(FALSE),
        JsonBool(TRUE),
        JsonBool(FALSE));

    int nToken = NuiCreate(oPC, jWin, SGL_WINDOW, SGL_EV_SCRIPT);
    NuiSetBind(oPC, nToken, SGL_WIN_GEOM, jGeom);

    FeedSglList(oPC, nToken);
}

void SwapToListView(object oPC, int nToken)
{
    SetLocalInt(oPC, SGL_LVAR_SEL_ID, 0);
    DeleteLocalString(oPC, SGL_LVAR_SEL_ATT);
    NuiSetGroupLayout(oPC, nToken, SGL_GRP_SWAP, BuildSglListView(oPC));
    FeedSglList(oPC, nToken);
}

void SwapToPlaceView(object oPC, int nToken)
{
    SetLocalInt(oPC, SGL_LVAR_TYPE_IDX, SGL_TYPE_ALARM);
    NuiSetGroupLayout(oPC, nToken, SGL_GRP_SWAP, BuildSglPlaceView(oPC));
    FeedSglPlace(oPC, nToken);
}

void SwapToAttuneView(object oPC, int nToken)
{
    DeleteLocalString(oPC, SGL_LVAR_SEL_ATT);
    NuiSetGroupLayout(oPC, nToken, SGL_GRP_SWAP, BuildSglAttuneView(oPC));
    FeedSglAttune(oPC, nToken);
}

// ----------------------------------------------------------------
// Feed — List View
// ----------------------------------------------------------------

void FeedSglList(object oPC, int nToken)
{
    json jSigils = SglGetPlayerSigils(oPC);
    int  nCount  = JsonGetLength(jSigils);
    int  nMax    = SGL_MAX_SIGILS;

    NuiSetBind(oPC, nToken, SGL_BIND_HEADER,
        JsonString("Aktywne znaki: " + IntToString(nCount) + "/" + IntToString(nMax)));

    json jTypes   = JsonArray();
    json jAreas   = JsonArray();
    json jCharges = JsonArray();
    json jEncs    = JsonArray();
    json jColors  = JsonArray();

    int nSelId = GetLocalInt(oPC, SGL_LVAR_SEL_ID);

    int i;
    for(i = 0; i < nCount; i++)
    {
        json   jSig    = JsonArrayGet(jSigils, i);
        int    nId     = JsonGetInt   (JsonObjectGet(jSig, "id"));
        int    nType   = JsonGetInt   (JsonObjectGet(jSig, "sigil_type"));
        int    nChg    = JsonGetInt   (JsonObjectGet(jSig, "charges"));
        string sArea   = JsonGetString(JsonObjectGet(jSig, "area_name"));

        jTypes   = JsonArrayInsert(jTypes,   JsonString(SglGetTypeName(nType)));
        jAreas   = JsonArrayInsert(jAreas,   JsonString(sArea));
        jCharges = JsonArrayInsert(jCharges, JsonString(SglChargesLabel(nChg, nType)));
        jEncs    = JsonArrayInsert(jEncs,    JsonBool(nSelId > 0 && nId == nSelId));
        jColors  = JsonArrayInsert(jColors,  SglGetTypeColor(nType));
    }

    NuiSetBind(oPC, nToken, SGL_BIND_ROW_TYPE,    jTypes);
    NuiSetBind(oPC, nToken, SGL_BIND_ROW_AREA,    jAreas);
    NuiSetBind(oPC, nToken, SGL_BIND_ROW_CHARGES, jCharges);
    NuiSetBind(oPC, nToken, SGL_BIND_ROW_ENC,     jEncs);
    NuiSetBind(oPC, nToken, SGL_BIND_ROW_COLOR,   jColors);
    NuiSetBind(oPC, nToken, SGL_BIND_LIST_COUNT,  JsonInt(nCount));

    int bSel = (nSelId > 0);
    NuiSetBind(oPC, nToken, SGL_BIND_DISARM_ENA, JsonBool(bSel));
    NuiSetBind(oPC, nToken, SGL_BIND_ATT_ENA,    JsonBool(bSel));
}

// ----------------------------------------------------------------
// Feed — Place View
// ----------------------------------------------------------------

void FeedSglPlace(object oPC, int nToken)
{
    int nType = GetLocalInt(oPC, SGL_LVAR_TYPE_IDX);
    NuiSetBind(oPC, nToken, SGL_BIND_PLACE_TYPE_LBL,
        JsonString(SglGetTypeName(nType)));
    NuiSetBind(oPC, nToken, SGL_BIND_PLACE_TYPE_DESC,
        JsonString(SglGetTypeDesc(nType)));
    NuiSetBind(oPC, nToken, SGL_BIND_PLACE_CHARGES,
        JsonString("Ładunki: " + IntToString(SglGetDefaultCharges(nType))));
}

// ----------------------------------------------------------------
// Feed — Attune View
// ----------------------------------------------------------------

void FeedSglAttune(object oPC, int nToken)
{
    int nSigilId = GetLocalInt(oPC, SGL_LVAR_SEL_ID);

    // Header
    json jSig = SglGetSigilById(nSigilId);
    string sHeader = "Brak wybranego znaku";
    if(JsonGetType(jSig) != JSON_TYPE_NULL)
    {
        int    nType  = JsonGetInt   (JsonObjectGet(jSig, "sigil_type"));
        string sArea  = JsonGetString(JsonObjectGet(jSig, "area_name"));
        sHeader = "Dostęp do znaku: " + SglGetTypeName(nType) + " [" + sArea + "]";
    }
    NuiSetBind(oPC, nToken, SGL_BIND_ATT_HEADER, JsonString(sHeader));

    // Attuned list
    json jAttuned = SglGetAttuned(nSigilId);
    int  nAttCount = JsonGetLength(jAttuned);
    json jAttNames = JsonArray();
    json jAttEncs  = JsonArray();
    string sSelAtt = GetLocalString(oPC, SGL_LVAR_SEL_ATT);

    int i;
    for(i = 0; i < nAttCount; i++)
    {
        json   jA    = JsonArrayGet(jAttuned, i);
        string sUuid = JsonGetString(JsonObjectGet(jA, "uuid"));
        string sName = JsonGetString(JsonObjectGet(jA, "name"));
        jAttNames = JsonArrayInsert(jAttNames, JsonString(sName));
        jAttEncs  = JsonArrayInsert(jAttEncs,  JsonBool(sUuid == sSelAtt && sSelAtt != ""));
    }
    NuiSetBind(oPC, nToken, SGL_BIND_ATT_NAME,  jAttNames);
    NuiSetBind(oPC, nToken, SGL_BIND_ATT_ENC,   jAttEncs);
    NuiSetBind(oPC, nToken, SGL_BIND_ATT_COUNT, JsonInt(nAttCount));
    NuiSetBind(oPC, nToken, SGL_BIND_REVOKE_ENA, JsonBool(sSelAtt != ""));

    // Online players list (excluding self and already-attuned)
    json jOnlineNames = JsonArray();
    json jOnlineEncs  = JsonArray();
    int  nOnlineCnt   = 0;
    string sSelfUuid  = GetObjectUUID(oPC);

    object oOther = GetFirstPC();
    while(GetIsObjectValid(oOther))
    {
        if(oOther != oPC && !GetIsDMPossessed(oOther))
        {
            string sOtherUuid = GetObjectUUID(oOther);
            if(!SglIsAttuned(nSigilId, sOtherUuid))
            {
                jOnlineNames = JsonArrayInsert(jOnlineNames, JsonString(GetName(oOther)));
                jOnlineEncs  = JsonArrayInsert(jOnlineEncs,  JsonBool(FALSE));
                nOnlineCnt++;
            }
        }
        oOther = GetNextPC();
    }
    NuiSetBind(oPC, nToken, SGL_BIND_ONLINE_NAME, jOnlineNames);
    NuiSetBind(oPC, nToken, SGL_BIND_ONLINE_ENC,  jOnlineEncs);
    NuiSetBind(oPC, nToken, SGL_BIND_ONLINE_CNT,  JsonInt(nOnlineCnt));
}

// ----------------------------------------------------------------
// Restore visual glows for all active sigils after server restart
// ----------------------------------------------------------------

void SglRestoreVisuals()
{
    json jSigils = SglGetAllActiveSigils();
    int nCount   = JsonGetLength(jSigils);
    int i;
    for(i = 0; i < nCount; i++)
    {
        json   jSig   = JsonArrayGet(jSigils, i);
        string sArea  = JsonGetString(JsonObjectGet(jSig, "area_tag"));
        float  fX     = JsonGetFloat (JsonObjectGet(jSig, "pos_x"));
        float  fY     = JsonGetFloat (JsonObjectGet(jSig, "pos_y"));
        float  fZ     = JsonGetFloat (JsonObjectGet(jSig, "pos_z"));

        // GetObjectByTag finds the first area with this tag
        object oArea = GetObjectByTag(sArea);
        if(!GetIsObjectValid(oArea)) continue;

        location lSig = Location(oArea, Vector(fX, fY, fZ), 0.0);
        ApplyEffectAtLocation(DURATION_TYPE_TEMPORARY,
            EffectVisualEffect(VFX_DUR_PROT_PREMONITION), lSig, 3600.0);
    }
}
