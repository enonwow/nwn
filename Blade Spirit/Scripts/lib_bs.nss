#include "lib_bs_def"

// ----------------------------------------------------------------
// Tier indicator color
// ----------------------------------------------------------------

json BsTierColor(int nTier)
{
    if(nTier == BS_TIER_DORMANT)    return NuiColor(160, 160, 160);
    if(nTier == BS_TIER_RESTLESS)   return NuiColor(220, 200, 100);
    if(nTier == BS_TIER_ACTIVE)     return NuiColor(255, 140, 40);
    return NuiColor(200, 80, 255);
}

// ----------------------------------------------------------------
// Next-tier kill threshold for display
// ----------------------------------------------------------------

int BsKillsToNextTier(int nTier)
{
    if(nTier == BS_TIER_DORMANT)  return BS_KILLS_RESTLESS;
    if(nTier == BS_TIER_RESTLESS) return BS_KILLS_ACTIVE;
    if(nTier == BS_TIER_ACTIVE)   return BS_KILLS_MANIFESTED;
    return -1;
}

string BsManifestAbilityName(int nClass)
{
    if(nClass == BS_CLASS_WARRIOR) return "Ostatnia Wola";
    if(nClass == BS_CLASS_MAGE)    return "Arcana Uwolniona";
    if(nClass == BS_CLASS_ROGUE)   return "Cień Śmierci";
    return "Boskie Wotum";
}

// ----------------------------------------------------------------
// Main window layout
// ----------------------------------------------------------------

json BsBuildMainWindow(object oPC)
{
    float fBtnH  = GetNuiScaleDimension(oPC, 30.0);
    float fIconSz= GetNuiScaleDimension(oPC, 56.0);
    float fLabelH= GetNuiScaleDimension(oPC, 22.0);

    // -- Header: weapon icon + spirit name + close --
    json jIcon = NuiButtonImage(NuiBind(BS_BIND_WPN_ICON));
    jIcon = NuiWidth(jIcon, fIconSz);
    jIcon = NuiHeight(jIcon, fIconSz);

    json jNameLbl = NuiLabel(NuiBind(BS_BIND_SPIRIT_NAME),
        JsonInt(NUI_HALIGN_LEFT), JsonInt(NUI_VALIGN_MIDDLE));
    jNameLbl = NuiStyleForegroundColor(jNameLbl, NuiBind(BS_BIND_TIER_COLOR));
    jNameLbl = NuiHeight(jNameLbl, fLabelH);

    json jWpnLbl = NuiLabel(NuiBind(BS_BIND_WPNNAME_LBL),
        JsonInt(NUI_HALIGN_LEFT), JsonInt(NUI_VALIGN_MIDDLE));
    jWpnLbl = NuiHeight(jWpnLbl, fLabelH);

    json jCloseBtn = NuiButton(JsonString("X"));
    jCloseBtn = NuiId(jCloseBtn, BS_BTN_CLOSE);
    jCloseBtn = NuiWidth(jCloseBtn, GetNuiScaleDimension(oPC, 30.0));
    jCloseBtn = NuiHeight(jCloseBtn, fBtnH);

    json jNameCol = JsonArray();
    jNameCol = JsonArrayInsert(jNameCol, jNameLbl);
    jNameCol = JsonArrayInsert(jNameCol, jWpnLbl);

    json jHeaderRow = JsonArray();
    jHeaderRow = JsonArrayInsert(jHeaderRow, jIcon);
    jHeaderRow = JsonArrayInsert(jHeaderRow, NuiCol(jNameCol));
    jHeaderRow = JsonArrayInsert(jHeaderRow, NuiSpacer());
    jHeaderRow = JsonArrayInsert(jHeaderRow, jCloseBtn);

    // -- Tier / class row --
    json jTierLbl = NuiLabel(NuiBind(BS_BIND_TIER_LBL),
        JsonInt(NUI_HALIGN_LEFT), JsonInt(NUI_VALIGN_MIDDLE));
    jTierLbl = NuiStyleForegroundColor(jTierLbl, NuiBind(BS_BIND_TIER_COLOR));
    jTierLbl = NuiHeight(jTierLbl, fLabelH);

    json jClassLbl = NuiLabel(NuiBind(BS_BIND_CLASS_LBL),
        JsonInt(NUI_HALIGN_RIGHT), JsonInt(NUI_VALIGN_MIDDLE));
    jClassLbl = NuiHeight(jClassLbl, fLabelH);
    jClassLbl = NuiWidth(jClassLbl, GetNuiScaleDimension(oPC, 120.0));

    json jTierRow = JsonArray();
    jTierRow = JsonArrayInsert(jTierRow, jTierLbl);
    jTierRow = JsonArrayInsert(jTierRow, NuiSpacer());
    jTierRow = JsonArrayInsert(jTierRow, jClassLbl);

    // -- Kill progress row --
    json jKillsLbl = NuiLabel(NuiBind(BS_BIND_KILLS_LBL),
        JsonInt(NUI_HALIGN_LEFT), JsonInt(NUI_VALIGN_MIDDLE));
    jKillsLbl = NuiHeight(jKillsLbl, fLabelH);

    json jKillsNextLbl = NuiLabel(NuiBind(BS_BIND_KILLS_NEXT),
        JsonInt(NUI_HALIGN_RIGHT), JsonInt(NUI_VALIGN_MIDDLE));
    jKillsNextLbl = NuiHeight(jKillsNextLbl, fLabelH);
    jKillsNextLbl = NuiWidth(jKillsNextLbl, GetNuiScaleDimension(oPC, 200.0));

    json jKillRow = JsonArray();
    jKillRow = JsonArrayInsert(jKillRow, jKillsLbl);
    jKillRow = JsonArrayInsert(jKillRow, NuiSpacer());
    jKillRow = JsonArrayInsert(jKillRow, jKillsNextLbl);

    // -- Two-column area: bonuses (left) | whispers (right) --
    float fSectionH = GetNuiScaleDimension(oPC, 160.0);
    float fColW     = GetNuiScaleDimension(oPC, 280.0);

    json jBonusHdr = NuiLabel(JsonString("Premie ducha"),
        JsonInt(NUI_HALIGN_LEFT), JsonInt(NUI_VALIGN_MIDDLE));
    jBonusHdr = NuiHeight(jBonusHdr, fLabelH);
    jBonusHdr = NuiStyleForegroundColor(jBonusHdr, GetNuiColorNwnGold());

    json jBonusTxt = NuiGroup(
        NuiText(NuiBind(BS_BIND_BONUS_LBL), FALSE),
        TRUE, NUI_SCROLLBARS_NONE);
    jBonusTxt = NuiHeight(jBonusTxt, GetNuiScaleDimension(oPC, 130.0));

    json jBonusCol = JsonArray();
    jBonusCol = JsonArrayInsert(jBonusCol, jBonusHdr);
    jBonusCol = JsonArrayInsert(jBonusCol, jBonusTxt);

    json jWhisperHdr = NuiLabel(JsonString("Szepty ducha"),
        JsonInt(NUI_HALIGN_LEFT), JsonInt(NUI_VALIGN_MIDDLE));
    jWhisperHdr = NuiHeight(jWhisperHdr, fLabelH);
    jWhisperHdr = NuiStyleForegroundColor(jWhisperHdr, NuiColor(180, 120, 180));

    json jW0 = NuiLabel(NuiBind(BS_BIND_WHISPER_0),
        JsonInt(NUI_HALIGN_LEFT), JsonInt(NUI_VALIGN_MIDDLE));
    jW0 = NuiHeight(jW0, fLabelH);
    json jW1 = NuiLabel(NuiBind(BS_BIND_WHISPER_1),
        JsonInt(NUI_HALIGN_LEFT), JsonInt(NUI_VALIGN_MIDDLE));
    jW1 = NuiHeight(jW1, fLabelH);
    json jW2 = NuiLabel(NuiBind(BS_BIND_WHISPER_2),
        JsonInt(NUI_HALIGN_LEFT), JsonInt(NUI_VALIGN_MIDDLE));
    jW2 = NuiHeight(jW2, fLabelH);

    json jWhisperCol = JsonArray();
    jWhisperCol = JsonArrayInsert(jWhisperCol, jWhisperHdr);
    jWhisperCol = JsonArrayInsert(jWhisperCol, jW0);
    jWhisperCol = JsonArrayInsert(jWhisperCol, jW1);
    jWhisperCol = JsonArrayInsert(jWhisperCol, jW2);
    jWhisperCol = JsonArrayInsert(jWhisperCol, NuiSpacer());

    json jTwoCol = JsonArray();
    jTwoCol = JsonArrayInsert(jTwoCol, NuiWidth(NuiCol(jBonusCol), fColW));
    jTwoCol = JsonArrayInsert(jTwoCol, NuiWidth(NuiCol(jWhisperCol), fColW));
    json jTwoColRow = NuiHeight(NuiRow(jTwoCol), fSectionH);

    // -- Appease status label --
    json jAppeasedLbl = NuiLabel(NuiBind(BS_BIND_APPEASED_LBL),
        JsonInt(NUI_HALIGN_LEFT), JsonInt(NUI_VALIGN_MIDDLE));
    jAppeasedLbl = NuiHeight(jAppeasedLbl, fLabelH);
    jAppeasedLbl = NuiStyleForegroundColor(jAppeasedLbl, NuiColor(100, 220, 100));

    // -- Action buttons row 1: Commune + Appease + Exorcise --
    json jCommuneBtn = NuiButton(JsonString("Komunikuj się"));
    jCommuneBtn = NuiId(jCommuneBtn, BS_BTN_COMMUNE);
    jCommuneBtn = NuiHeight(jCommuneBtn, fBtnH);

    json jAppeaseLbl = NuiBind(BS_BIND_APPEASE_LBL);
    json jAppeaseBtn = NuiButton(jAppeaseLbl);
    jAppeaseBtn = NuiId(jAppeaseBtn, BS_BTN_APPEASE);
    jAppeaseBtn = NuiEnabled(jAppeaseBtn, NuiBind(BS_BIND_APPEASE_ENA));
    jAppeaseBtn = NuiHeight(jAppeaseBtn, fBtnH);

    json jExorciseBtn = NuiButton(JsonString("Wygnaj ducha"));
    jExorciseBtn = NuiId(jExorciseBtn, BS_BTN_EXORCISE);
    jExorciseBtn = NuiEnabled(jExorciseBtn, NuiBind(BS_BIND_EXORCISE_ENA));
    jExorciseBtn = NuiHeight(jExorciseBtn, fBtnH);

    json jActRow1 = JsonArray();
    jActRow1 = JsonArrayInsert(jActRow1, jCommuneBtn);
    jActRow1 = JsonArrayInsert(jActRow1, NuiSpacer());
    jActRow1 = JsonArrayInsert(jActRow1, jAppeaseBtn);
    jActRow1 = JsonArrayInsert(jActRow1, NuiSpacer());
    jActRow1 = JsonArrayInsert(jActRow1, jExorciseBtn);

    // -- Action buttons row 2: Manifest --
    json jManifestBtn = NuiButton(NuiBind(BS_BIND_MANIFEST_LBL));
    jManifestBtn = NuiId(jManifestBtn, BS_BTN_MANIFEST);
    jManifestBtn = NuiEnabled(jManifestBtn, NuiBind(BS_BIND_MANIFEST_ENA));
    jManifestBtn = NuiHeight(jManifestBtn, fBtnH);

    json jActRow2 = JsonArray();
    jActRow2 = JsonArrayInsert(jActRow2, jManifestBtn);

    // -- Assemble column --
    json jCol = JsonArray();
    jCol = JsonArrayInsert(jCol, NuiRow(jHeaderRow));
    jCol = JsonArrayInsert(jCol, CreateEmptyRow(oPC, 6.0));
    jCol = JsonArrayInsert(jCol, NuiRow(jTierRow));
    jCol = JsonArrayInsert(jCol, NuiRow(jKillRow));
    jCol = JsonArrayInsert(jCol, CreateEmptyRow(oPC, 6.0));
    jCol = JsonArrayInsert(jCol, jTwoColRow);
    jCol = JsonArrayInsert(jCol, NuiRow(JsonArrayInsert(JsonArray(), jAppeasedLbl)));
    jCol = JsonArrayInsert(jCol, CreateEmptyRow(oPC, 4.0));
    jCol = JsonArrayInsert(jCol, NuiRow(jActRow1));
    jCol = JsonArrayInsert(jCol, CreateEmptyRow(oPC, 4.0));
    jCol = JsonArrayInsert(jCol, NuiRow(jActRow2));

    json jSide = NuiCol(JsonArrayInsert(JsonArray(), NuiSpacer()));
    float fContentW = GetNuiScaleDimension(oPC, 640.0);
    json jMainRow = JsonArray();
    jMainRow = JsonArrayInsert(jMainRow, jSide);
    jMainRow = JsonArrayInsert(jMainRow, NuiWidth(NuiCol(jCol), fContentW));
    jMainRow = JsonArrayInsert(jMainRow, jSide);
    return NuiRow(jMainRow);
}

// ----------------------------------------------------------------
// Create / bind window layout
// ----------------------------------------------------------------

json BsBuildCreateWindow(object oPC)
{
    float fBtnH  = GetNuiScaleDimension(oPC, 30.0);
    float fIconSz= GetNuiScaleDimension(oPC, 48.0);
    float fLabelH= GetNuiScaleDimension(oPC, 22.0);

    // -- Weapon info row --
    json jWpnIcon = NuiButtonImage(NuiBind(BS_BIND_C_WPN_ICON));
    jWpnIcon = NuiWidth(jWpnIcon, fIconSz);
    jWpnIcon = NuiHeight(jWpnIcon, fIconSz);

    json jWpnLbl = NuiLabel(NuiBind(BS_BIND_C_WPN_NAME),
        JsonInt(NUI_HALIGN_LEFT), JsonInt(NUI_VALIGN_MIDDLE));

    json jWpnRow = JsonArray();
    jWpnRow = JsonArrayInsert(jWpnRow, jWpnIcon);
    jWpnRow = JsonArrayInsert(jWpnRow, jWpnLbl);

    // -- Spirit name field --
    json jSnameHdr = NuiLabel(JsonString("Imię ducha:"),
        JsonInt(NUI_HALIGN_LEFT), JsonInt(NUI_VALIGN_MIDDLE));
    jSnameHdr = NuiWidth(jSnameHdr, GetNuiScaleDimension(oPC, 90.0));
    jSnameHdr = NuiHeight(jSnameHdr, fBtnH);

    json jSnameEdit = NuiTextEdit(JsonString(""), NuiBind(BS_BIND_C_SNAME), 40, FALSE);
    jSnameEdit = NuiHeight(jSnameEdit, fBtnH);

    json jSnameRow = JsonArray();
    jSnameRow = JsonArrayInsert(jSnameRow, jSnameHdr);
    jSnameRow = JsonArrayInsert(jSnameRow, jSnameEdit);

    // -- Class selection: 4 toggle buttons --
    json jClHdr = NuiLabel(JsonString("Klasa ducha:"),
        JsonInt(NUI_HALIGN_LEFT), JsonInt(NUI_VALIGN_MIDDLE));
    jClHdr = NuiHeight(jClHdr, fLabelH);

    float fClW = GetNuiScaleDimension(oPC, 90.0);

    json jBtnW = NuiButton(JsonString("Wojownik"));
    jBtnW = NuiId(jBtnW, BS_BTN_C_W);
    jBtnW = NuiEncouraged(jBtnW, NuiBind(BS_BIND_C_CLASS_W));
    jBtnW = NuiWidth(jBtnW, fClW);
    jBtnW = NuiHeight(jBtnW, fBtnH);

    json jBtnM = NuiButton(JsonString("Czarownik"));
    jBtnM = NuiId(jBtnM, BS_BTN_C_M);
    jBtnM = NuiEncouraged(jBtnM, NuiBind(BS_BIND_C_CLASS_M));
    jBtnM = NuiWidth(jBtnM, fClW);
    jBtnM = NuiHeight(jBtnM, fBtnH);

    json jBtnR = NuiButton(JsonString("Łotrzyk"));
    jBtnR = NuiId(jBtnR, BS_BTN_C_R);
    jBtnR = NuiEncouraged(jBtnR, NuiBind(BS_BIND_C_CLASS_R));
    jBtnR = NuiWidth(jBtnR, fClW);
    jBtnR = NuiHeight(jBtnR, fBtnH);

    json jBtnC = NuiButton(JsonString("Kapłan"));
    jBtnC = NuiId(jBtnC, BS_BTN_C_C);
    jBtnC = NuiEncouraged(jBtnC, NuiBind(BS_BIND_C_CLASS_C));
    jBtnC = NuiWidth(jBtnC, fClW);
    jBtnC = NuiHeight(jBtnC, fBtnH);

    json jClassRow = JsonArray();
    jClassRow = JsonArrayInsert(jClassRow, jBtnW);
    jClassRow = JsonArrayInsert(jClassRow, jBtnM);
    jClassRow = JsonArrayInsert(jClassRow, jBtnR);
    jClassRow = JsonArrayInsert(jClassRow, jBtnC);

    // -- Status / info label --
    json jStatusLbl = NuiLabel(NuiBind(BS_BIND_C_STATUS),
        JsonInt(NUI_HALIGN_LEFT), JsonInt(NUI_VALIGN_MIDDLE));
    jStatusLbl = NuiHeight(jStatusLbl, GetNuiScaleDimension(oPC, 44.0));
    jStatusLbl = NuiStyleForegroundColor(jStatusLbl, NuiColor(200, 180, 100));

    // -- Bottom buttons: Bind + Cancel --
    json jBindBtn = NuiButton(JsonString("Związ ducha (" + IntToString(BS_BIND_COST) + " sz)"));
    jBindBtn = NuiId(jBindBtn, BS_BTN_C_BIND);
    jBindBtn = NuiEnabled(jBindBtn, NuiBind(BS_BIND_C_BIND_ENA));
    jBindBtn = NuiHeight(jBindBtn, fBtnH);

    json jCancelBtn = NuiButton(JsonString("Anuluj"));
    jCancelBtn = NuiId(jCancelBtn, BS_BTN_C_CANCEL);
    jCancelBtn = NuiHeight(jCancelBtn, fBtnH);

    json jBotRow = JsonArray();
    jBotRow = JsonArrayInsert(jBotRow, jCancelBtn);
    jBotRow = JsonArrayInsert(jBotRow, NuiSpacer());
    jBotRow = JsonArrayInsert(jBotRow, jBindBtn);

    // -- Assemble --
    json jCol = JsonArray();
    jCol = JsonArrayInsert(jCol, NuiRow(jWpnRow));
    jCol = JsonArrayInsert(jCol, CreateEmptyRow(oPC, 8.0));
    jCol = JsonArrayInsert(jCol, NuiRow(jSnameRow));
    jCol = JsonArrayInsert(jCol, CreateEmptyRow(oPC, 6.0));
    jCol = JsonArrayInsert(jCol, jClHdr);
    jCol = JsonArrayInsert(jCol, NuiRow(jClassRow));
    jCol = JsonArrayInsert(jCol, CreateEmptyRow(oPC, 6.0));
    jCol = JsonArrayInsert(jCol, jStatusLbl);
    jCol = JsonArrayInsert(jCol, NuiSpacer());
    jCol = JsonArrayInsert(jCol, NuiRow(jBotRow));

    json jSide = NuiCol(JsonArrayInsert(JsonArray(), NuiSpacer()));
    float fContentW = GetNuiScaleDimension(oPC, 420.0);
    json jMainRow = JsonArray();
    jMainRow = JsonArrayInsert(jMainRow, jSide);
    jMainRow = JsonArrayInsert(jMainRow, NuiWidth(NuiCol(jCol), fContentW));
    jMainRow = JsonArrayInsert(jMainRow, jSide);
    return NuiRow(jMainRow);
}

// ----------------------------------------------------------------
// Window open
// ----------------------------------------------------------------

void BsOpenWindow(object oPC, string sItemUUID)
{
    json jSpirit = BsGetSpirit(sItemUUID);
    if(JsonGetType(jSpirit) == JSON_TYPE_NULL)
    {
        SendMessageToPC(oPC, "[Duch Ostrza] To ostrze nie jest nawiedzone.");
        return;
    }

    SetLocalString(oPC, BS_LVAR_ACTIVE_UUID, sItemUUID);

    if(NuiFindWindow(oPC, BS_WIN) != 0)
    {
        BsFeedMainWindow(oPC, NuiFindWindow(oPC, BS_WIN));
        return;
    }

    float fCX = (IntToFloat(GetPlayerDeviceProperty(oPC, PLAYER_DEVICE_PROPERTY_GUI_WIDTH))
                 - GetNuiScaleDimension(oPC, BS_WIN_W)) / 2.0;
    float fCY = (IntToFloat(GetPlayerDeviceProperty(oPC, PLAYER_DEVICE_PROPERTY_GUI_HEIGHT))
                 - GetNuiScaleDimension(oPC, BS_WIN_H)) / 2.0;

    json jWin = NuiWindow(
        BsBuildMainWindow(oPC),
        JsonString("Duch Ostrza"),
        NuiBind(BS_WIN_GEOM),
        JsonBool(FALSE),
        JsonBool(FALSE),
        JsonBool(FALSE),
        JsonBool(TRUE),
        JsonBool(FALSE));

    int nToken = NuiCreate(oPC, jWin, BS_WIN, BS_WIN_EV);
    NuiSetBind(oPC, nToken, BS_WIN_GEOM,
        NuiRect(fCX, fCY,
            GetNuiScaleDimension(oPC, BS_WIN_W),
            GetNuiScaleDimension(oPC, BS_WIN_H)));
    NuiSetBindWatch(oPC, nToken, BS_BIND_C_SNAME, TRUE);

    BsFeedMainWindow(oPC, nToken);
}

void BsOpenCreateWindow(object oPC, string sItemUUID, string sWeaponName, string sWeaponIcon)
{
    SetLocalString(oPC, BS_LVAR_CREATE_UUID,  sItemUUID);
    SetLocalInt   (oPC, BS_LVAR_CREATE_CLASS, BS_CLASS_WARRIOR);

    if(NuiFindWindow(oPC, BS_WIN_CREATE) != 0)
        NuiDestroy(oPC, NuiFindWindow(oPC, BS_WIN_CREATE));

    float fCX = (IntToFloat(GetPlayerDeviceProperty(oPC, PLAYER_DEVICE_PROPERTY_GUI_WIDTH))
                 - GetNuiScaleDimension(oPC, BS_CREATE_W)) / 2.0;
    float fCY = (IntToFloat(GetPlayerDeviceProperty(oPC, PLAYER_DEVICE_PROPERTY_GUI_HEIGHT))
                 - GetNuiScaleDimension(oPC, BS_CREATE_H)) / 2.0;

    json jWin = NuiWindow(
        BsBuildCreateWindow(oPC),
        JsonString("Ołtarz Poległych — Związanie Ducha"),
        NuiBind(BS_WIN_CREATE_GEOM),
        JsonBool(FALSE),
        JsonBool(FALSE),
        JsonBool(FALSE),
        JsonBool(TRUE),
        JsonBool(FALSE));

    int nToken = NuiCreate(oPC, jWin, BS_WIN_CREATE, BS_WIN_EV);
    NuiSetBind(oPC, nToken, BS_WIN_CREATE_GEOM,
        NuiRect(fCX, fCY,
            GetNuiScaleDimension(oPC, BS_CREATE_W),
            GetNuiScaleDimension(oPC, BS_CREATE_H)));
    NuiSetBindWatch(oPC, nToken, BS_BIND_C_SNAME, TRUE);

    NuiSetBind(oPC, nToken, BS_BIND_C_WPN_ICON, JsonString(sWeaponIcon));
    NuiSetBind(oPC, nToken, BS_BIND_C_WPN_NAME, JsonString(sWeaponName));
    NuiSetBind(oPC, nToken, BS_BIND_C_SNAME,    JsonString(""));
    NuiSetBind(oPC, nToken, BS_BIND_C_BIND_ENA, JsonBool(FALSE));

    BsFeedCreateWindow(oPC, nToken);
}

// ----------------------------------------------------------------
// Feed main window
// ----------------------------------------------------------------

void BsFeedMainWindow(object oPC, int nToken)
{
    string sUUID   = GetLocalString(oPC, BS_LVAR_ACTIVE_UUID);
    json   jSpirit = BsGetSpirit(sUUID);
    if(JsonGetType(jSpirit) == JSON_TYPE_NULL)
    {
        NuiDestroy(oPC, nToken);
        return;
    }

    string sSpiritName = JsonGetString(JsonObjectGet(jSpirit, "spirit_name"));
    int    nClass      = JsonGetInt   (JsonObjectGet(jSpirit, "spirit_class"));
    int    nKills      = JsonGetInt   (JsonObjectGet(jSpirit, "kill_count"));
    int    nTier       = BsGetTier(nKills);
    int    bAppeased   = BsIsAppeased(jSpirit);

    // Weapon info
    object oRH = GetItemInSlot(INVENTORY_SLOT_RIGHTHAND, oPC);
    string sWpnIcon = "ir_longsword";
    string sWpnName = "Nieznana broń";
    if(GetIsObjectValid(oRH) && GetObjectUUID(oRH) == sUUID)
    {
        sWpnIcon = GetStringLowerCase(
            Get2DAString("baseitems", "DefaultIcon", GetBaseItemType(oRH)));
        sWpnName = GetName(oRH);
    }

    NuiSetBind(oPC, nToken, BS_BIND_WPN_ICON,    JsonString(sWpnIcon));
    NuiSetBind(oPC, nToken, BS_BIND_WPNNAME_LBL, JsonString(sWpnName));
    NuiSetBind(oPC, nToken, BS_BIND_SPIRIT_NAME, JsonString(sSpiritName));
    NuiSetBind(oPC, nToken, BS_BIND_TIER_LBL,
        JsonString("Poziom " + IntToString(nTier + 1) + ": " + BsTierName(nTier)));
    NuiSetBind(oPC, nToken, BS_BIND_TIER_COLOR,  BsTierColor(nTier));
    NuiSetBind(oPC, nToken, BS_BIND_CLASS_LBL,   JsonString(BsSpiritClassName(nClass)));

    // Kill progress
    int nNext = BsKillsToNextTier(nTier);
    NuiSetBind(oPC, nToken, BS_BIND_KILLS_LBL,
        JsonString("Pokonani wrogowie: " + IntToString(nKills)));
    string sNextTxt = nNext >= 0
        ? "do " + BsTierName(nTier + 1) + ": " + IntToString(nNext - nKills) + " pozostało"
        : "Szczyt mocy osiągnięty";
    NuiSetBind(oPC, nToken, BS_BIND_KILLS_NEXT, JsonString(sNextTxt));

    // Bonuses
    NuiSetBind(oPC, nToken, BS_BIND_BONUS_LBL,
        JsonString(BsGetBonusDescription(nClass, nTier, bAppeased)));

    // Whispers — 3 cycling whispers based on tier
    NuiSetBind(oPC, nToken, BS_BIND_WHISPER_0,
        JsonString("„" + BsGetWhisper(nClass, nTier, nKills)     + """));
    NuiSetBind(oPC, nToken, BS_BIND_WHISPER_1,
        JsonString("„" + BsGetWhisper(nClass, nTier, nKills + 1) + """));
    NuiSetBind(oPC, nToken, BS_BIND_WHISPER_2,
        JsonString("„" + BsGetWhisper(nClass, nTier, nKills + 2) + """));

    // Appeased status
    NuiSetBind(oPC, nToken, BS_BIND_APPEASED_LBL,
        JsonString(bAppeased
            ? "Duch jest uspokojony — premie wzmocnione."
            : ""));

    // Appease button
    NuiSetBind(oPC, nToken, BS_BIND_APPEASE_LBL,
        JsonString("Ubłagaj (" + IntToString(BS_APPEASE_COST) + " sz)"));
    NuiSetBind(oPC, nToken, BS_BIND_APPEASE_ENA,
        JsonBool(!bAppeased));

    // Exorcise — requires cleric level
    int nClericLevel = GetLevelByClass(CLASS_TYPE_CLERIC, oPC)
                     + GetLevelByClass(CLASS_TYPE_PALADIN, oPC);
    NuiSetBind(oPC, nToken, BS_BIND_EXORCISE_ENA,
        JsonBool(nClericLevel >= BS_EXORCISE_MIN_CLERIC));

    // Manifest
    int bCanManifest = (nTier == BS_TIER_MANIFESTED && !BsManifestOnCooldown(jSpirit));
    NuiSetBind(oPC, nToken, BS_BIND_MANIFEST_ENA, JsonBool(bCanManifest));
    NuiSetBind(oPC, nToken, BS_BIND_MANIFEST_LBL,
        JsonString(bCanManifest
            ? "Manifestacja: " + BsManifestAbilityName(nClass)
            : "Manifestacja — niedostępna"));
}

// ----------------------------------------------------------------
// Feed create window
// ----------------------------------------------------------------

void BsFeedCreateWindow(object oPC, int nToken)
{
    int nClass = GetLocalInt(oPC, BS_LVAR_CREATE_CLASS);

    NuiSetBind(oPC, nToken, BS_BIND_C_CLASS_W, JsonBool(nClass == BS_CLASS_WARRIOR));
    NuiSetBind(oPC, nToken, BS_BIND_C_CLASS_M, JsonBool(nClass == BS_CLASS_MAGE));
    NuiSetBind(oPC, nToken, BS_BIND_C_CLASS_R, JsonBool(nClass == BS_CLASS_ROGUE));
    NuiSetBind(oPC, nToken, BS_BIND_C_CLASS_C, JsonBool(nClass == BS_CLASS_CLERIC));

    string sName = JsonGetString(NuiGetBind(oPC, nToken, BS_BIND_C_SNAME));
    int bHasName = (sName != "");
    int bHasGold = (GetGold(oPC) >= BS_BIND_COST);

    NuiSetBind(oPC, nToken, BS_BIND_C_BIND_ENA, JsonBool(bHasName && bHasGold));
    NuiSetBind(oPC, nToken, BS_BIND_C_STATUS,
        JsonString("Koszt rytuału: " + IntToString(BS_BIND_COST) + " sz. "
            + (bHasGold ? "" : "Brak środków. ")
            + "Duch przyjmuje klasę poległego wojownika."));
}

// ----------------------------------------------------------------
// Manifest power execution
// ----------------------------------------------------------------

void BsDoManifest(object oPC, string sUUID, int nClass)
{
    location lPC = GetLocation(oPC);

    if(nClass == BS_CLASS_WARRIOR)
    {
        // Ostatnia Wola: AoE knockdown + damage
        ApplyEffectToObject(DURATION_TYPE_INSTANT,
            EffectVisualEffect(VFX_FNF_SCREEN_SHAKE), oPC);
        object oTarget = GetFirstObjectInShape(SHAPE_SPHERE, 5.0, lPC, TRUE, OBJECT_TYPE_CREATURE);
        while(GetIsObjectValid(oTarget))
        {
            if(GetIsEnemy(oTarget, oPC))
            {
                ApplyEffectToObject(DURATION_TYPE_TEMPORARY,
                    EffectKnockdown(), oTarget, 6.0);
                ApplyEffectToObject(DURATION_TYPE_INSTANT,
                    EffectDamage(d10(2), DAMAGE_TYPE_BLUDGEONING), oTarget);
                ApplyEffectToObject(DURATION_TYPE_INSTANT,
                    EffectVisualEffect(VFX_IMP_STUN), oTarget);
            }
            oTarget = GetNextObjectInShape(SHAPE_SPHERE, 5.0, lPC, TRUE, OBJECT_TYPE_CREATURE);
        }
        FloatingTextStringOnCreature(
            "Ostatnia wola ducha eksploduje w obszarze wokół ciebie!", oPC, FALSE);
    }
    else if(nClass == BS_CLASS_MAGE)
    {
        // Arcana Uwolniona: force damage AoE
        ApplyEffectToObject(DURATION_TYPE_INSTANT,
            EffectVisualEffect(VFX_FNF_LOS_NORMAL_10), oPC);
        object oTarget = GetFirstObjectInShape(SHAPE_SPHERE, 7.0, lPC, TRUE, OBJECT_TYPE_CREATURE);
        while(GetIsObjectValid(oTarget))
        {
            if(GetIsEnemy(oTarget, oPC))
            {
                ApplyEffectToObject(DURATION_TYPE_INSTANT,
                    EffectDamage(d10(3), DAMAGE_TYPE_MAGICAL), oTarget);
                ApplyEffectToObject(DURATION_TYPE_INSTANT,
                    EffectVisualEffect(VFX_IMP_MAGBLUE), oTarget);
            }
            oTarget = GetNextObjectInShape(SHAPE_SPHERE, 7.0, lPC, TRUE, OBJECT_TYPE_CREATURE);
        }
        FloatingTextStringOnCreature(
            "Skuta magia pęka — fala arkanej energii rozrywa wszystko wokół!", oPC, FALSE);
    }
    else if(nClass == BS_CLASS_ROGUE)
    {
        // Cień Śmierci: improved invisibility + attack bonus, 3 rounds
        ApplyEffectToObject(DURATION_TYPE_TEMPORARY,
            EffectInvisibility(INVISIBILITY_TYPE_IMPROVED), oPC, 18.0);
        ApplyEffectToObject(DURATION_TYPE_TEMPORARY,
            TagEffect(EffectAttackIncrease(4), "BS_MANIFEST_TEMP"), oPC, 18.0);
        ApplyEffectToObject(DURATION_TYPE_INSTANT,
            EffectVisualEffect(VFX_IMP_SHADOW_INVISIBILITY), oPC);
        FloatingTextStringOnCreature(
            "Cień ducha pochłania cię — stajesz się niewidzialny i śmiertelny.", oPC, FALSE);
    }
    else if(nClass == BS_CLASS_CLERIC)
    {
        // Boskie Wotum: self heal + divine smite undead
        int nHeal = d10(3) + 10;
        ApplyEffectToObject(DURATION_TYPE_INSTANT, EffectHeal(nHeal), oPC);
        ApplyEffectToObject(DURATION_TYPE_INSTANT,
            EffectVisualEffect(VFX_IMP_HOLY_AID), oPC);

        object oTarget = GetFirstObjectInShape(SHAPE_SPHERE, 7.0, lPC, TRUE, OBJECT_TYPE_CREATURE);
        while(GetIsObjectValid(oTarget))
        {
            if(GetIsEnemy(oTarget, oPC))
            {
                ApplyEffectToObject(DURATION_TYPE_INSTANT,
                    EffectDamage(d10(3), DAMAGE_TYPE_DIVINE), oTarget);
                ApplyEffectToObject(DURATION_TYPE_INSTANT,
                    EffectVisualEffect(VFX_IMP_SUNSTRIKE), oTarget);
            }
            oTarget = GetNextObjectInShape(SHAPE_SPHERE, 7.0, lPC, TRUE, OBJECT_TYPE_CREATURE);
        }
        FloatingTextStringOnCreature(
            "Boskie wotum ducha uzdrawia cię i spala wrogów ogniem niebios!", oPC, FALSE);
    }

    BsSetManifested(sUUID);
    SendMessageToPC(oPC, "[Duch Ostrza] Manifestacja użyta. Dostępna ponownie za 20 godzin.");
}
