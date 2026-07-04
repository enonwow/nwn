#include "lib_sb_def"

void SbOpenWindow(object oPC);
void SbFeedWindow(object oPC, int nToken, json jWeapon);
void SbApplyBonuses(object oWeapon, int nRank);
void SbRemoveBonuses(object oWeapon);
void SbRestoreAllBonds(object oPC);
void SbInspectMainHand(object oPC);
void SbShowConfirmBreak(object oPC, string sUuid, string sWpName);

// ----------------------------------------------------------------
// Item property management
// ----------------------------------------------------------------

void SbRemoveBonuses(object oWeapon)
{
    itemproperty ip = GetFirstItemProperty(oWeapon);
    while(GetIsItemPropertyValid(ip))
    {
        if(GetItemPropertyTag(ip) == SB_TAG)
            RemoveItemProperty(oWeapon, ip);
        ip = GetNextItemProperty(oWeapon);
    }
}

void SbApplyBonuses(object oWeapon, int nRank)
{
    SbRemoveBonuses(oWeapon);
    if(nRank <= 0) return;

    itemproperty ip;

    // Enhancement bonus scales: 1,1,2,2,3
    int nEnh = 1;
    if(nRank >= 3) nEnh = 2;
    if(nRank >= 5) nEnh = 3;
    ip = TagItemProperty(ItemPropertyEnhancementBonus(nEnh), SB_TAG);
    AddItemProperty(DURATION_TYPE_PERMANENT, ip, oWeapon);

    // Cold damage from rank 2 onward
    if(nRank >= 2)
    {
        int nDmgType = (nRank >= 4) ? IP_CONST_DAMAGEBONUS_1D6 : IP_CONST_DAMAGEBONUS_1D4;
        ip = TagItemProperty(
            ItemPropertyDamageBonus(IP_CONST_DAMAGETYPE_COLD, nDmgType), SB_TAG);
        AddItemProperty(DURATION_TYPE_PERMANENT, ip, oWeapon);
    }

    // Intimidate bonus from rank 4
    if(nRank >= 4)
    {
        int nSkillBonus = (nRank >= 5) ? 4 : 2;
        ip = TagItemProperty(ItemPropertySkillBonus(SKILL_INTIMIDATE, nSkillBonus), SB_TAG);
        AddItemProperty(DURATION_TYPE_PERMANENT, ip, oWeapon);
    }

    // Regeneration at rank 5
    if(nRank >= 5)
    {
        ip = TagItemProperty(ItemPropertyRegeneration(1), SB_TAG);
        AddItemProperty(DURATION_TYPE_PERMANENT, ip, oWeapon);
    }
}

// Scans all inventory slots and equipped slots, re-applies bonuses for bonded weapons
void SbRestoreAllBonds(object oPC)
{
    // Check equipped main hand
    object oEquipped = GetItemInSlot(INVENTORY_SLOT_RIGHTHAND, oPC);
    if(GetIsObjectValid(oEquipped))
    {
        string sUuid = GetObjectUUID(oEquipped);
        json jData = SbGetWeapon(sUuid);
        if(JsonGetType(jData) != JSON_TYPE_NULL)
        {
            int nRank = JsonGetInt(JsonObjectGet(jData, "rank"));
            SbApplyBonuses(oEquipped, nRank);
        }
    }

    // Scan inventory
    object oItem = GetFirstItemInInventory(oPC);
    while(GetIsObjectValid(oItem))
    {
        string sUuid = GetObjectUUID(oItem);
        json jData = SbGetWeapon(sUuid);
        if(JsonGetType(jData) != JSON_TYPE_NULL)
        {
            int nRank = JsonGetInt(JsonObjectGet(jData, "rank"));
            SbApplyBonuses(oItem, nRank);
        }
        oItem = GetNextItemInInventory(oPC);
    }
}

// ----------------------------------------------------------------
// NUI layout
// ----------------------------------------------------------------

json SbBuildDetailView(object oPC)
{
    float fBtnH  = GetNuiScaleDimension(oPC, 28.0);
    float fProgH = GetNuiScaleDimension(oPC, 18.0);
    float fLabelW= GetNuiScaleDimension(oPC, 120.0);

    // Weapon name (large)
    json jWpName = NuiLabel(NuiBind(SB_BIND_WPNAME),
        JsonInt(NUI_HALIGN_CENTER), JsonInt(NUI_VALIGN_MIDDLE));
    jWpName = NuiHeight(jWpName, GetNuiScaleDimension(oPC, 32.0));
    jWpName = NuiStyleForegroundColor(jWpName, NuiColor(220, 200, 120));

    // Bond epithet
    json jBondName = NuiLabel(NuiBind(SB_BIND_BONDNAME),
        JsonInt(NUI_HALIGN_CENTER), JsonInt(NUI_VALIGN_MIDDLE));
    jBondName = NuiHeight(jBondName, GetNuiScaleDimension(oPC, 24.0));
    jBondName = NuiStyleForegroundColor(jBondName, NuiColor(180, 100, 100));

    // Rank label
    json jRankLbl = NuiLabel(NuiBind(SB_BIND_RANK_LBL),
        JsonInt(NUI_HALIGN_CENTER), JsonInt(NUI_VALIGN_MIDDLE));
    jRankLbl = NuiHeight(jRankLbl, GetNuiScaleDimension(oPC, 22.0));

    // Kill count label
    json jKillsLbl = NuiLabel(NuiBind(SB_BIND_KILLS_LBL),
        JsonInt(NUI_HALIGN_CENTER), JsonInt(NUI_VALIGN_MIDDLE));
    jKillsLbl = NuiHeight(jKillsLbl, GetNuiScaleDimension(oPC, 20.0));

    // Progress bar
    json jProg = NuiProgressBar(NuiBind(SB_BIND_PROGRESS));
    jProg = NuiHeight(jProg, fProgH);

    // Next rank label
    json jNextLbl = NuiLabel(NuiBind(SB_BIND_NEXT_LBL),
        JsonInt(NUI_HALIGN_LEFT), JsonInt(NUI_VALIGN_MIDDLE));
    jNextLbl = NuiHeight(jNextLbl, GetNuiScaleDimension(oPC, 20.0));
    jNextLbl = NuiStyleForegroundColor(jNextLbl, NuiColor(160, 160, 160));

    // Current bonuses section header
    json jBonusHdr = NuiLabel(JsonString("Aktywne premie:"),
        JsonInt(NUI_HALIGN_LEFT), JsonInt(NUI_VALIGN_MIDDLE));
    jBonusHdr = NuiHeight(jBonusHdr, GetNuiScaleDimension(oPC, 20.0));
    jBonusHdr = NuiStyleForegroundColor(jBonusHdr, NuiColor(140, 200, 140));

    json jBonusTxt = NuiText(NuiBind(SB_BIND_BONUS_TXT), FALSE);
    jBonusTxt = NuiHeight(jBonusTxt, GetNuiScaleDimension(oPC, 64.0));

    // Next bonus section header
    json jNextBonusHdr = NuiLabel(JsonString("Premie po awansie:"),
        JsonInt(NUI_HALIGN_LEFT), JsonInt(NUI_VALIGN_MIDDLE));
    jNextBonusHdr = NuiHeight(jNextBonusHdr, GetNuiScaleDimension(oPC, 20.0));
    jNextBonusHdr = NuiStyleForegroundColor(jNextBonusHdr, NuiColor(140, 140, 200));

    json jNextBonusTxt = NuiText(NuiBind(SB_BIND_NEXT_BONUS), FALSE);
    jNextBonusTxt = NuiHeight(jNextBonusTxt, GetNuiScaleDimension(oPC, 64.0));

    // Bonder name
    json jBonderLbl = NuiLabel(NuiBind(SB_BIND_BONDER_LBL),
        JsonInt(NUI_HALIGN_LEFT), JsonInt(NUI_VALIGN_MIDDLE));
    jBonderLbl = NuiHeight(jBonderLbl, GetNuiScaleDimension(oPC, 20.0));
    jBonderLbl = NuiStyleForegroundColor(jBonderLbl, NuiColor(140, 140, 140));

    // Status (shown when no weapon inspected)
    json jStatusLbl = NuiLabel(NuiBind(SB_BIND_STATUS_LBL),
        JsonInt(NUI_HALIGN_CENTER), JsonInt(NUI_VALIGN_MIDDLE));
    jStatusLbl = NuiHeight(jStatusLbl, GetNuiScaleDimension(oPC, 22.0));
    jStatusLbl = NuiStyleForegroundColor(jStatusLbl, NuiColor(160, 100, 80));

    // Inspect button
    json jInspectBtn = NuiButton(JsonString("Zbadaj prawą rękę"));
    jInspectBtn = NuiId(jInspectBtn, SB_BTN_INSPECT);
    jInspectBtn = NuiWidth(jInspectBtn, GetNuiScaleDimension(oPC, 180.0));
    jInspectBtn = NuiHeight(jInspectBtn, fBtnH);

    // Break bond button
    json jBreakBtn = NuiButton(JsonString("Zerw więź (" + IntToString(SB_BREAK_COST) + " zk)"));
    jBreakBtn = NuiId(jBreakBtn, SB_BTN_BREAK);
    jBreakBtn = NuiEnabled(jBreakBtn, NuiBind(SB_BIND_BREAK_ENA));
    jBreakBtn = NuiWidth(jBreakBtn, GetNuiScaleDimension(oPC, 200.0));
    jBreakBtn = NuiHeight(jBreakBtn, fBtnH);

    // Bottom row
    json jBotRow = JsonArray();
    jBotRow = JsonArrayInsert(jBotRow, jInspectBtn);
    jBotRow = JsonArrayInsert(jBotRow, NuiSpacer());
    jBotRow = JsonArrayInsert(jBotRow, jBreakBtn);

    // Separator spacer
    json jSep = CreateEmptyRow(oPC, 6.0);

    // Assemble column
    json jCol = JsonArray();
    jCol = JsonArrayInsert(jCol, jWpName);
    jCol = JsonArrayInsert(jCol, jBondName);
    jCol = JsonArrayInsert(jCol, jRankLbl);
    jCol = JsonArrayInsert(jCol, jKillsLbl);
    jCol = JsonArrayInsert(jCol, jProg);
    jCol = JsonArrayInsert(jCol, jNextLbl);
    jCol = JsonArrayInsert(jCol, jSep);
    jCol = JsonArrayInsert(jCol, jBonusHdr);
    jCol = JsonArrayInsert(jCol, NuiGroup(jBonusTxt, TRUE, NUI_SCROLLBARS_NONE));
    jCol = JsonArrayInsert(jCol, jNextBonusHdr);
    jCol = JsonArrayInsert(jCol, NuiGroup(jNextBonusTxt, TRUE, NUI_SCROLLBARS_NONE));
    jCol = JsonArrayInsert(jCol, jSep);
    jCol = JsonArrayInsert(jCol, jStatusLbl);
    jCol = JsonArrayInsert(jCol, jBonderLbl);
    jCol = JsonArrayInsert(jCol, NuiRow(jBotRow));

    float fContentW = GetNuiScaleDimension(oPC, 480.0);
    json jSide = NuiCol(JsonArrayInsert(JsonArray(), NuiSpacer()));
    json jMainRow = JsonArray();
    jMainRow = JsonArrayInsert(jMainRow, jSide);
    jMainRow = JsonArrayInsert(jMainRow, NuiWidth(NuiCol(jCol), fContentW));
    jMainRow = JsonArrayInsert(jMainRow, jSide);
    return NuiRow(jMainRow);
}

// ----------------------------------------------------------------
// Window open / feed
// ----------------------------------------------------------------

void SbOpenWindow(object oPC)
{
    if(NuiFindWindow(oPC, SB_WINDOW) != 0)
    {
        SbInspectMainHand(oPC);
        return;
    }

    float fCX = (IntToFloat(GetPlayerDeviceProperty(oPC, PLAYER_DEVICE_PROPERTY_GUI_WIDTH))
                 - GetNuiScaleDimension(oPC, SB_W)) / 2.0;
    float fCY = (IntToFloat(GetPlayerDeviceProperty(oPC, PLAYER_DEVICE_PROPERTY_GUI_HEIGHT))
                 - GetNuiScaleDimension(oPC, SB_H)) / 2.0;
    json jGeom = NuiRect(fCX, fCY,
        GetNuiScaleDimension(oPC, SB_W),
        GetNuiScaleDimension(oPC, SB_H));

    float fBtnH = GetNuiScaleDimension(oPC, 28.0);
    json jCloseBtn = NuiButton(JsonString("X"));
    jCloseBtn = NuiId(jCloseBtn, SB_BTN_CLOSE);
    jCloseBtn = NuiWidth(jCloseBtn, GetNuiScaleDimension(oPC, 28.0));
    jCloseBtn = NuiHeight(jCloseBtn, fBtnH);

    json jTitleLbl = NuiLabel(JsonString("Więź Duszy"),
        JsonInt(NUI_HALIGN_LEFT), JsonInt(NUI_VALIGN_MIDDLE));
    jTitleLbl = NuiStyleForegroundColor(jTitleLbl, NuiColor(200, 160, 80));

    json jTopRow = JsonArray();
    jTopRow = JsonArrayInsert(jTopRow, jTitleLbl);
    jTopRow = JsonArrayInsert(jTopRow, NuiSpacer());
    jTopRow = JsonArrayInsert(jTopRow, jCloseBtn);

    json jDetailGrp = NuiGroup(SbBuildDetailView(oPC), FALSE, NUI_SCROLLBARS_AUTO);
    jDetailGrp = NuiId(jDetailGrp, SB_GRP_DETAIL);

    json jRoot = JsonArray();
    jRoot = JsonArrayInsert(jRoot, NuiRow(jTopRow));
    jRoot = JsonArrayInsert(jRoot, jDetailGrp);

    json jWin = NuiWindow(NuiCol(jRoot),
        JsonBool(FALSE),
        NuiBind(SB_WIN_GEOM),
        JsonBool(FALSE),
        JsonBool(FALSE),
        JsonBool(FALSE),
        JsonBool(TRUE),
        JsonBool(FALSE));

    int nToken = NuiCreate(oPC, jWin, SB_WINDOW, SB_EV_SCRIPT);
    NuiSetBind(oPC, nToken, SB_WIN_GEOM, jGeom);

    SbInspectMainHand(oPC);
}

void SbFeedWindow(object oPC, int nToken, json jWeapon)
{
    if(JsonGetType(jWeapon) == JSON_TYPE_NULL)
    {
        NuiSetBind(oPC, nToken, SB_BIND_WPNAME,     JsonString("— brak broni —"));
        NuiSetBind(oPC, nToken, SB_BIND_BONDNAME,   JsonString(""));
        NuiSetBind(oPC, nToken, SB_BIND_RANK_LBL,   JsonString("Ranga: Uśpiona [0/5]"));
        NuiSetBind(oPC, nToken, SB_BIND_KILLS_LBL,  JsonString("Nie wykryto więzi."));
        NuiSetBind(oPC, nToken, SB_BIND_PROGRESS,   JsonFloat(0.0));
        NuiSetBind(oPC, nToken, SB_BIND_NEXT_LBL,   JsonString("Zdobądź 10 zabójstw, by przebudzić ostrze."));
        NuiSetBind(oPC, nToken, SB_BIND_BONUS_TXT,  JsonString("—"));
        NuiSetBind(oPC, nToken, SB_BIND_NEXT_BONUS, JsonString("—"));
        NuiSetBind(oPC, nToken, SB_BIND_BONDER_LBL, JsonString(""));
        NuiSetBind(oPC, nToken, SB_BIND_STATUS_LBL, JsonString("Ekwipuj broń w prawą rękę i kliknij [Zbadaj]."));
        NuiSetBind(oPC, nToken, SB_BIND_BREAK_ENA,  JsonBool(FALSE));
        return;
    }

    string sWpName    = JsonGetString(JsonObjectGet(jWeapon, "weapon_name"));
    string sBondName  = JsonGetString(JsonObjectGet(jWeapon, "bond_name"));
    string sBonder    = JsonGetString(JsonObjectGet(jWeapon, "bonder_name"));
    int    nKills     = JsonGetInt   (JsonObjectGet(jWeapon, "kills"));
    int    nRank      = JsonGetInt   (JsonObjectGet(jWeapon, "rank"));

    string sRankLbl = "Ranga: " + SbRankLabel(nRank) + " [" + IntToString(nRank) + "/" + IntToString(SB_MAX_RANK) + "]";

    string sKillsLbl;
    if(nRank >= SB_MAX_RANK)
        sKillsLbl = "Zabójstwa: " + IntToString(nKills) + " (maks. ranga osiągnięta)";
    else
    {
        int nNext = SbRankThreshold(nRank + 1);
        sKillsLbl = "Zabójstwa: " + IntToString(nKills) + " / " + IntToString(nNext);
    }

    string sNextLbl;
    if(nRank >= SB_MAX_RANK)
        sNextLbl = "Pieczęć krwi pulsuje słabo — ostrze jest pełne.";
    else
    {
        int nLeft = SbRankThreshold(nRank + 1) - nKills;
        sNextLbl = "Do rangi " + SbRankLabel(nRank + 1) + ": " + IntToString(nLeft) + " zabójstw.";
    }

    string sBonderLbl = sBonder != "" ? "Pierwsze krople: " + sBonder : "";

    NuiSetBind(oPC, nToken, SB_BIND_WPNAME,     JsonString(sWpName));
    NuiSetBind(oPC, nToken, SB_BIND_BONDNAME,   JsonString(sBondName != "" ? "\"" + sBondName + "\"" : ""));
    NuiSetBind(oPC, nToken, SB_BIND_RANK_LBL,   JsonString(sRankLbl));
    NuiSetBind(oPC, nToken, SB_BIND_KILLS_LBL,  JsonString(sKillsLbl));
    NuiSetBind(oPC, nToken, SB_BIND_PROGRESS,   JsonFloat(SbCalcProgress(nKills, nRank)));
    NuiSetBind(oPC, nToken, SB_BIND_NEXT_LBL,   JsonString(sNextLbl));
    NuiSetBind(oPC, nToken, SB_BIND_BONUS_TXT,  JsonString(SbBonusDescription(nRank)));
    NuiSetBind(oPC, nToken, SB_BIND_NEXT_BONUS, JsonString(SbNextBonusDescription(nRank)));
    NuiSetBind(oPC, nToken, SB_BIND_BONDER_LBL, JsonString(sBonderLbl));
    NuiSetBind(oPC, nToken, SB_BIND_STATUS_LBL, JsonString(""));
    NuiSetBind(oPC, nToken, SB_BIND_BREAK_ENA,  JsonBool(nRank > 0));
}

// ----------------------------------------------------------------
// Inspect / kill counting
// ----------------------------------------------------------------

void SbInspectMainHand(object oPC)
{
    int nToken = NuiFindWindow(oPC, SB_WINDOW);
    if(nToken == 0) return;

    object oWeapon = GetItemInSlot(INVENTORY_SLOT_RIGHTHAND, oPC);
    if(!GetIsObjectValid(oWeapon))
    {
        DeleteLocalString(oPC, SB_LVAR_INSPECTED);
        SbFeedWindow(oPC, nToken, JsonNull());
        return;
    }

    string sUuid = GetObjectUUID(oWeapon);
    SetLocalString(oPC, SB_LVAR_INSPECTED, sUuid);

    json jData = SbGetWeapon(sUuid);
    SbFeedWindow(oPC, nToken, jData);
}

// Called from sys_on_death to credit a kill to the wielded weapon
void SbCreditKill(object oKiller)
{
    if(!GetIsPC(oKiller)) return;

    object oWeapon = GetItemInSlot(INVENTORY_SLOT_RIGHTHAND, oKiller);
    if(!GetIsObjectValid(oWeapon)) return;

    // Ignore gloves (unarmed combat stand-in)
    int nBaseType = GetBaseItemType(oWeapon);
    if(nBaseType == BASE_ITEM_GLOVES) return;

    string sUuid = GetObjectUUID(oWeapon);

    // Register on first kill
    json jData = SbGetWeapon(sUuid);
    if(JsonGetType(jData) == JSON_TYPE_NULL)
        SbRegisterWeapon(sUuid, GetName(oWeapon), GetName(oKiller));

    int nNewKills = SbIncrementKills(sUuid);

    // Re-fetch for current rank
    jData = SbGetWeapon(sUuid);
    int nRank = JsonGetInt(JsonObjectGet(jData, "rank"));

    // Check rank advancement
    int nNewRank = nRank;
    int r;
    for(r = nRank + 1; r <= SB_MAX_RANK; r++)
    {
        if(nNewKills >= SbRankThreshold(r))
            nNewRank = r;
        else
            break;
    }

    if(nNewRank > nRank)
    {
        string sEpithet = SbPickEpithet(nNewRank, nNewKills);
        SbSetRank(sUuid, nNewRank, sEpithet);
        SbApplyBonuses(oWeapon, nNewRank);

        string sMsg = "Pieczęć krwi pulsuje — " + GetName(oWeapon) +
                      " osiąga rangę " + SbRankLabel(nNewRank) +
                      " [\"" + sEpithet + "\"].";
        SendMessageToPC(oKiller, sMsg);
        FloatingTextStringOnCreature(sMsg, oKiller, FALSE);
    }

    // Refresh open window if inspecting this weapon
    int nToken = NuiFindWindow(oKiller, SB_WINDOW);
    if(nToken != 0 && GetLocalString(oKiller, SB_LVAR_INSPECTED) == sUuid)
    {
        jData = SbGetWeapon(sUuid);
        SbFeedWindow(oKiller, nToken, jData);
    }
}

// ----------------------------------------------------------------
// Break bond
// ----------------------------------------------------------------

void SbShowConfirmBreak(object oPC, string sUuid, string sWpName)
{
    if(NuiFindWindow(oPC, SB_WIN_CONFIRM) != 0)
        NuiDestroy(oPC, NuiFindWindow(oPC, SB_WIN_CONFIRM));

    SetLocalString(oPC, "SB_BREAK_UUID", sUuid);

    float fW = GetNuiScaleDimension(oPC, 420.0);
    float fH = GetNuiScaleDimension(oPC, 180.0);
    float fX = (IntToFloat(GetPlayerDeviceProperty(oPC, PLAYER_DEVICE_PROPERTY_GUI_WIDTH))  - fW) / 2.0;
    float fY = (IntToFloat(GetPlayerDeviceProperty(oPC, PLAYER_DEVICE_PROPERTY_GUI_HEIGHT)) - fH) / 2.0;

    string sMsg = "Zerwać więź z \"" + sWpName + "\"?\n\n" +
                  "Kosztuje " + IntToString(SB_BREAK_COST) + " złotych kruszczynów.\n" +
                  "Broń straci wszystkie premie rezonansowe.";

    json jMsgLbl = NuiLabel(JsonString(sMsg),
        JsonInt(NUI_HALIGN_CENTER), JsonInt(NUI_VALIGN_MIDDLE));

    float fBtnH = GetNuiScaleDimension(oPC, 28.0);
    json jYes = NuiButton(JsonString("Zerw więź"));
    jYes = NuiId(jYes, SB_BTN_CONF_YES);
    jYes = NuiWidth(jYes, GetNuiScaleDimension(oPC, 120.0));
    jYes = NuiHeight(jYes, fBtnH);

    json jNo = NuiButton(JsonString("Anuluj"));
    jNo = NuiId(jNo, SB_BTN_CONF_NO);
    jNo = NuiWidth(jNo, GetNuiScaleDimension(oPC, 120.0));
    jNo = NuiHeight(jNo, fBtnH);

    json jBtnRow = JsonArray();
    jBtnRow = JsonArrayInsert(jBtnRow, NuiSpacer());
    jBtnRow = JsonArrayInsert(jBtnRow, jYes);
    jBtnRow = JsonArrayInsert(jBtnRow, NuiSpacer());
    jBtnRow = JsonArrayInsert(jBtnRow, jNo);
    jBtnRow = JsonArrayInsert(jBtnRow, NuiSpacer());

    json jCol = JsonArray();
    jCol = JsonArrayInsert(jCol, jMsgLbl);
    jCol = JsonArrayInsert(jCol, CreateEmptyRow(oPC, 8.0));
    jCol = JsonArrayInsert(jCol, NuiRow(jBtnRow));

    json jWin = NuiWindow(NuiCol(jCol),
        JsonString("Potwierdzenie"),
        NuiRect(fX, fY, fW, fH),
        JsonBool(FALSE), JsonBool(FALSE), JsonBool(TRUE),
        JsonBool(FALSE), JsonBool(TRUE));

    NuiCreate(oPC, jWin, SB_WIN_CONFIRM, SB_EV_SCRIPT);
}

void SbExecuteBreak(object oPC, string sUuid)
{
    if(GetGold(oPC) < SB_BREAK_COST)
    {
        SendMessageToPC(oPC, "[Więź Duszy] Za mało złota. Potrzebujesz " + IntToString(SB_BREAK_COST) + " kruszczynów.");
        return;
    }

    AssignCommand(oPC, TakeGoldFromCreature(SB_BREAK_COST, oPC, TRUE));

    // Find the weapon object in PC's possession
    object oItem = GetItemInSlot(INVENTORY_SLOT_RIGHTHAND, oPC);
    if(GetIsObjectValid(oItem) && GetObjectUUID(oItem) == sUuid)
        SbRemoveBonuses(oItem);
    else
    {
        oItem = GetFirstItemInInventory(oPC);
        while(GetIsObjectValid(oItem))
        {
            if(GetObjectUUID(oItem) == sUuid)
            {
                SbRemoveBonuses(oItem);
                break;
            }
            oItem = GetNextItemInInventory(oPC);
        }
    }

    SbDeleteWeapon(sUuid);
    DeleteLocalString(oPC, SB_LVAR_INSPECTED);

    SendMessageToPC(oPC, "[Więź Duszy] Więź zerwana. Ostrze milczy.");

    int nToken = NuiFindWindow(oPC, SB_WINDOW);
    if(nToken != 0) SbFeedWindow(oPC, nToken, JsonNull());
}
