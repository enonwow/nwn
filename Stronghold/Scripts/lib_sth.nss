#include "lib_sth_def"

// ----------------------------------------------------------------
// Bonus application
// ----------------------------------------------------------------

void StrongholdRemoveBonuses(object oPC)
{
    RemoveEffectByTag(oPC, STH_EFFECT_TAG);
}

void StrongholdApplyBuildingBonus(object oPC, int nBldId, int nLevel)
{
    if(nLevel <= 0) return;

    switch(nBldId)
    {
        case STH_BLD_BARRACKS:
        {
            int nAB = (nLevel >= 2) ? 2 : 1;
            effect eAB = TagEffect(EffectAttackIncrease(nAB, ATTACK_BONUS_MISC), STH_EFFECT_TAG);
            ApplyEffectToObject(EFFECT_DURATION_TYPE_PERMANENT, eAB, oPC);
            if(nLevel >= 3)
            {
                effect eDmg = TagEffect(EffectDamageIncrease(DAMAGE_BONUS_2, DAMAGE_TYPE_BASE_WEAPON), STH_EFFECT_TAG);
                ApplyEffectToObject(EFFECT_DURATION_TYPE_PERMANENT, eDmg, oPC);
            }
        } break;

        case STH_BLD_LAB:
        {
            int nST = (nLevel >= 2) ? 2 : 1;
            effect eST = TagEffect(EffectSavingThrowIncrease(SAVING_THROW_ALL, nST, SAVING_THROW_TYPE_ALL), STH_EFFECT_TAG);
            ApplyEffectToObject(EFFECT_DURATION_TYPE_PERMANENT, eST, oPC);
            if(nLevel >= 3)
            {
                effect eSR = TagEffect(EffectSpellResistanceIncrease(4), STH_EFFECT_TAG);
                ApplyEffectToObject(EFFECT_DURATION_TYPE_PERMANENT, eSR, oPC);
            }
        } break;

        case STH_BLD_CHAPEL:
        {
            int nTHP = nLevel * 10;
            effect eTHP = TagEffect(EffectTemporaryHitpoints(nTHP), STH_EFFECT_TAG);
            ApplyEffectToObject(EFFECT_DURATION_TYPE_PERMANENT, eTHP, oPC);
        } break;

        case STH_BLD_LIBRARY:
        {
            int nLore = (nLevel >= 2) ? 5 : 3;
            effect eLore = TagEffect(EffectSkillIncrease(SKILL_LORE, nLore), STH_EFFECT_TAG);
            effect eApp  = TagEffect(EffectSkillIncrease(SKILL_APPRAISE, nLore), STH_EFFECT_TAG);
            ApplyEffectToObject(EFFECT_DURATION_TYPE_PERMANENT, eLore, oPC);
            ApplyEffectToObject(EFFECT_DURATION_TYPE_PERMANENT, eApp,  oPC);
            if(nLevel >= 3)
            {
                effect eInt = TagEffect(EffectAbilityIncrease(ABILITY_INTELLIGENCE, 1), STH_EFFECT_TAG);
                ApplyEffectToObject(EFFECT_DURATION_TYPE_PERMANENT, eInt, oPC);
            }
        } break;

        case STH_BLD_DUNGEON:
        {
            int nIntim = (nLevel >= 3) ? 4 : 3;
            effect eInt = TagEffect(EffectSkillIncrease(SKILL_INTIMIDATE, nIntim), STH_EFFECT_TAG);
            ApplyEffectToObject(EFFECT_DURATION_TYPE_PERMANENT, eInt, oPC);
            if(nLevel >= 2)
            {
                int nPer = (nLevel >= 3) ? 3 : 2;
                effect ePer = TagEffect(EffectSkillIncrease(SKILL_PERSUADE, nPer), STH_EFFECT_TAG);
                ApplyEffectToObject(EFFECT_DURATION_TYPE_PERMANENT, ePer, oPC);
            }
            if(nLevel >= 3)
            {
                effect eAC = TagEffect(EffectACIncrease(1, AC_DODGE_BONUS), STH_EFFECT_TAG);
                ApplyEffectToObject(EFFECT_DURATION_TYPE_PERMANENT, eAC, oPC);
            }
        } break;

        case STH_BLD_WATCHTOWER:
        {
            int nSpot = (nLevel >= 2) ? (nLevel >= 3 ? 5 : 4) : 3;
            effect eSpot   = TagEffect(EffectSkillIncrease(SKILL_SPOT,   nSpot), STH_EFFECT_TAG);
            effect eListen = TagEffect(EffectSkillIncrease(SKILL_LISTEN, nSpot), STH_EFFECT_TAG);
            ApplyEffectToObject(EFFECT_DURATION_TYPE_PERMANENT, eSpot,   oPC);
            ApplyEffectToObject(EFFECT_DURATION_TYPE_PERMANENT, eListen, oPC);
            if(nLevel >= 2)
            {
                int nSearch = (nLevel >= 3) ? 5 : 3;
                effect eSearch = TagEffect(EffectSkillIncrease(SKILL_SEARCH, nSearch), STH_EFFECT_TAG);
                ApplyEffectToObject(EFFECT_DURATION_TYPE_PERMANENT, eSearch, oPC);
            }
            if(nLevel >= 3)
            {
                effect eTmb = TagEffect(EffectSkillIncrease(SKILL_TUMBLE, 2), STH_EFFECT_TAG);
                ApplyEffectToObject(EFFECT_DURATION_TYPE_PERMANENT, eTmb, oPC);
            }
        } break;
    }
}

void StrongholdApplyBonuses(object oPC)
{
    StrongholdRemoveBonuses(oPC);
    string sUuid = GetObjectUUID(oPC);
    int i;
    for(i = 0; i < STH_BLD_COUNT; i++)
        StrongholdApplyBuildingBonus(oPC, i, StrongholdGetLevel(sUuid, i));
}

// Check if any in-progress upgrades have completed and advance their level.
void StrongholdCheckUpgrades(object oPC)
{
    string sUuid = GetObjectUUID(oPC);
    int nNow     = StrongholdNow();
    int i;
    for(i = 0; i < STH_BLD_COUNT; i++)
    {
        int nFinish = StrongholdGetUpgradeFinish(sUuid, i);
        if(nFinish > 0 && nNow >= nFinish)
        {
            int nLevel = StrongholdGetLevel(sUuid, i);
            int nNew   = nLevel + 1;
            StrongholdSetLevel(sUuid, i, nNew);
            string sMsg = "[Twierdza] " + StrongholdBuildingName(i)
                + " — rozbudowa zakończona! Nowy poziom: " + IntToString(nNew) + ".";
            SendMessageToPC(oPC, sMsg);
            FloatingTextStringOnCreature(sMsg, oPC, FALSE);
        }
    }
}

// ----------------------------------------------------------------
// NUI — build layout
// ----------------------------------------------------------------

json StrongholdBuildBldButton(object oPC, int i)
{
    float fBtnW = GetNuiScaleDimension(oPC, 180.0);
    float fBtnH = GetNuiScaleDimension(oPC, 90.0);
    float fLblH = GetNuiScaleDimension(oPC, 22.0);

    string sNameBind = STH_BIND_BLD_NAME + IntToString(i);
    string sLvlBind  = STH_BIND_BLD_LVL  + IntToString(i);
    string sSubBind  = STH_BIND_BLD_SUB  + IntToString(i);
    string sEncBind  = STH_BIND_BLD_ENC  + IntToString(i);
    string sBtnId    = STH_BTN_BLD       + IntToString(i);

    json jName = NuiLabel(NuiBind(sNameBind), JsonInt(NUI_HALIGN_CENTER), JsonInt(NUI_VALIGN_MIDDLE));
    jName = NuiHeight(jName, fLblH);

    json jLvl = NuiLabel(NuiBind(sLvlBind), JsonInt(NUI_HALIGN_CENTER), JsonInt(NUI_VALIGN_MIDDLE));
    jLvl = NuiHeight(jLvl, fLblH);
    jLvl = NuiStyleForegroundColor(jLvl, NuiColor(180, 160, 100));

    json jSub = NuiLabel(NuiBind(sSubBind), JsonInt(NUI_HALIGN_CENTER), JsonInt(NUI_VALIGN_MIDDLE));
    jSub = NuiHeight(jSub, fLblH);
    jSub = NuiStyleForegroundColor(jSub, NuiColor(200, 120, 60));

    json jInner = JsonArray();
    jInner = JsonArrayInsert(jInner, jName);
    jInner = JsonArrayInsert(jInner, jLvl);
    jInner = JsonArrayInsert(jInner, jSub);

    json jCell = NuiGroup(NuiCol(jInner), TRUE, NUI_SCROLLBARS_NONE);
    jCell = NuiId(jCell, sBtnId);
    jCell = NuiEncouraged(jCell, NuiBind(sEncBind));
    jCell = NuiWidth(jCell,  fBtnW);
    jCell = NuiHeight(jCell, fBtnH);

    return jCell;
}

json StrongholdBuildGridPanel(object oPC)
{
    float fGapH = GetNuiScaleDimension(oPC, 8.0);
    float fRowH = GetNuiScaleDimension(oPC, 90.0);

    json jRow1 = JsonArray();
    jRow1 = JsonArrayInsert(jRow1, StrongholdBuildBldButton(oPC, 0));
    jRow1 = JsonArrayInsert(jRow1, StrongholdBuildBldButton(oPC, 1));
    jRow1 = JsonArrayInsert(jRow1, StrongholdBuildBldButton(oPC, 2));

    json jRow2 = JsonArray();
    jRow2 = JsonArrayInsert(jRow2, StrongholdBuildBldButton(oPC, 3));
    jRow2 = JsonArrayInsert(jRow2, StrongholdBuildBldButton(oPC, 4));
    jRow2 = JsonArrayInsert(jRow2, StrongholdBuildBldButton(oPC, 5));

    json jGrid = JsonArray();
    jGrid = JsonArrayInsert(jGrid, NuiHeight(NuiRow(jRow1), fRowH));
    jGrid = JsonArrayInsert(jGrid, NuiHeight(NuiSpacer(), fGapH));
    jGrid = JsonArrayInsert(jGrid, NuiHeight(NuiRow(jRow2), fRowH));

    return NuiCol(jGrid);
}

json StrongholdBuildDetailPanel(object oPC)
{
    float fBtnH  = GetNuiScaleDimension(oPC, 30.0);
    float fHdrH  = GetNuiScaleDimension(oPC, 28.0);
    float fDescH = GetNuiScaleDimension(oPC, 110.0);
    float fEffH  = GetNuiScaleDimension(oPC, 44.0);
    float fNextH = GetNuiScaleDimension(oPC, 44.0);

    json jNone = NuiLabel(
        JsonString("Wybierz budynek po lewej, aby zobaczyć szczegóły i opcję rozbudowy."),
        JsonInt(NUI_HALIGN_CENTER), JsonInt(NUI_VALIGN_MIDDLE));
    jNone = NuiStyleForegroundColor(jNone, NuiColor(160, 140, 100));

    json jHdr = NuiLabel(NuiBind(STH_BIND_SEL_HDR), JsonInt(NUI_HALIGN_LEFT), JsonInt(NUI_VALIGN_MIDDLE));
    jHdr = NuiHeight(jHdr, fHdrH);
    jHdr = NuiStyleForegroundColor(jHdr, NuiColor(220, 200, 130));

    json jDesc = NuiGroup(NuiText(NuiBind(STH_BIND_SEL_DESC), FALSE), FALSE, NUI_SCROLLBARS_NONE);
    jDesc = NuiHeight(jDesc, fDescH);

    json jEffLbl = NuiLabel(JsonString("Aktywne efekty:"), JsonInt(NUI_HALIGN_LEFT), JsonInt(NUI_VALIGN_MIDDLE));
    jEffLbl = NuiStyleForegroundColor(jEffLbl, NuiColor(150, 200, 150));
    json jEff = NuiGroup(NuiText(NuiBind(STH_BIND_SEL_EFF), FALSE), FALSE, NUI_SCROLLBARS_NONE);
    jEff = NuiHeight(jEff, fEffH);

    json jNextLbl = NuiLabel(NuiBind(STH_BIND_UPG_LBL), JsonInt(NUI_HALIGN_LEFT), JsonInt(NUI_VALIGN_MIDDLE));
    jNextLbl = NuiStyleForegroundColor(jNextLbl, NuiColor(180, 160, 220));
    json jNext = NuiGroup(NuiText(NuiBind(STH_BIND_SEL_NEXT), FALSE), FALSE, NUI_SCROLLBARS_NONE);
    jNext = NuiHeight(jNext, fNextH);

    json jUpgBtn = NuiButton(JsonString("Rozbuduj"));
    jUpgBtn = NuiId(jUpgBtn, STH_BTN_UPGRADE);
    jUpgBtn = NuiEnabled(jUpgBtn, NuiBind(STH_BIND_UPG_ENA));
    jUpgBtn = NuiHeight(jUpgBtn, fBtnH);

    json jCanBtn = NuiButton(JsonString("Anuluj rozbudowę"));
    jCanBtn = NuiId(jCanBtn, STH_BTN_CANCEL);
    jCanBtn = NuiEnabled(jCanBtn, NuiBind(STH_BIND_CAN_ENA));
    jCanBtn = NuiHeight(jCanBtn, fBtnH);

    json jBtnRow = JsonArray();
    jBtnRow = JsonArrayInsert(jBtnRow, jUpgBtn);
    jBtnRow = JsonArrayInsert(jBtnRow, NuiSpacer());
    jBtnRow = JsonArrayInsert(jBtnRow, jCanBtn);

    json jDetail = JsonArray();
    jDetail = JsonArrayInsert(jDetail, jHdr);
    jDetail = JsonArrayInsert(jDetail, jDesc);
    jDetail = JsonArrayInsert(jDetail, jEffLbl);
    jDetail = JsonArrayInsert(jDetail, jEff);
    jDetail = JsonArrayInsert(jDetail, jNextLbl);
    jDetail = JsonArrayInsert(jDetail, jNext);
    jDetail = JsonArrayInsert(jDetail, NuiSpacer());
    jDetail = JsonArrayInsert(jDetail, NuiRow(jBtnRow));

    // Swap group: "none" state vs "detail" state
    json jNoSel = NuiGroup(NuiCol(JsonArrayInsert(JsonArray(), jNone)), FALSE, NUI_SCROLLBARS_NONE);
    json jSel   = NuiGroup(NuiCol(jDetail),                             FALSE, NUI_SCROLLBARS_NONE);
    jNoSel = NuiVisible(jNoSel, NuiBind(STH_BIND_SEL_VIS + "_none"));
    jSel   = NuiVisible(jSel,   NuiBind(STH_BIND_SEL_VIS + "_sel"));

    json jPanelItems = JsonArray();
    jPanelItems = JsonArrayInsert(jPanelItems, jNoSel);
    jPanelItems = JsonArrayInsert(jPanelItems, jSel);

    return NuiCol(jPanelItems);
}

json StrongholdBuildWindow(object oPC)
{
    float fBtnH     = GetNuiScaleDimension(oPC, 30.0);
    float fHdrH     = GetNuiScaleDimension(oPC, 28.0);
    float fGridW    = GetNuiScaleDimension(oPC, 360.0);
    float fGapW     = GetNuiScaleDimension(oPC, 12.0);
    float fDetailW  = GetNuiScaleDimension(oPC, 230.0);

    // Top bar
    json jTitle = NuiLabel(NuiBind(STH_BIND_HEADER), JsonInt(NUI_HALIGN_LEFT), JsonInt(NUI_VALIGN_MIDDLE));
    jTitle = NuiHeight(jTitle, fHdrH);
    jTitle = NuiStyleForegroundColor(jTitle, NuiColor(220, 200, 130));

    json jGold = NuiLabel(NuiBind(STH_BIND_GOLD), JsonInt(NUI_HALIGN_RIGHT), JsonInt(NUI_VALIGN_MIDDLE));
    jGold = NuiHeight(jGold, fHdrH);
    jGold = NuiWidth(jGold, GetNuiScaleDimension(oPC, 180.0));
    jGold = NuiStyleForegroundColor(jGold, NuiColor(220, 180, 60));

    json jCloseBtn = NuiButton(JsonString("X"));
    jCloseBtn = NuiId(jCloseBtn, STH_BTN_CLOSE);
    jCloseBtn = NuiWidth(jCloseBtn, GetNuiScaleDimension(oPC, 32.0));
    jCloseBtn = NuiHeight(jCloseBtn, fBtnH);

    json jTopRow = JsonArray();
    jTopRow = JsonArrayInsert(jTopRow, jTitle);
    jTopRow = JsonArrayInsert(jTopRow, NuiSpacer());
    jTopRow = JsonArrayInsert(jTopRow, jGold);
    jTopRow = JsonArrayInsert(jTopRow, jCloseBtn);

    // Content row: grid + detail
    json jContent = JsonArray();
    jContent = JsonArrayInsert(jContent, NuiWidth(StrongholdBuildGridPanel(oPC),   fGridW));
    jContent = JsonArrayInsert(jContent, NuiWidth(NuiSpacer(),                     fGapW));
    jContent = JsonArrayInsert(jContent, NuiWidth(StrongholdBuildDetailPanel(oPC), fDetailW));

    json jRoot = JsonArray();
    jRoot = JsonArrayInsert(jRoot, NuiRow(jTopRow));
    jRoot = JsonArrayInsert(jRoot, NuiSpacer());
    jRoot = JsonArrayInsert(jRoot, NuiRow(jContent));

    float fCX = (IntToFloat(GetPlayerDeviceProperty(oPC, PLAYER_DEVICE_PROPERTY_GUI_WIDTH))  - GetNuiScaleDimension(oPC, STH_W)) / 2.0;
    float fCY = (IntToFloat(GetPlayerDeviceProperty(oPC, PLAYER_DEVICE_PROPERTY_GUI_HEIGHT)) - GetNuiScaleDimension(oPC, STH_H)) / 2.0;
    json jGeom = NuiRect(fCX, fCY, GetNuiScaleDimension(oPC, STH_W), GetNuiScaleDimension(oPC, STH_H));

    json jWin = NuiWindow(NuiCol(jRoot),
        JsonString("Twierdza"),
        NuiBind(STH_WIN_GEOM),
        JsonBool(FALSE),
        JsonBool(FALSE),
        JsonBool(FALSE),
        JsonBool(TRUE),
        JsonBool(FALSE));

    return jWin;
}

// ----------------------------------------------------------------
// Feed functions
// ----------------------------------------------------------------

void StrongholdFeedGrid(object oPC, int nToken)
{
    string sUuid  = GetObjectUUID(oPC);
    int    nNow   = StrongholdNow();
    int    nSelId = GetLocalInt(oPC, STH_LVAR_SEL);
    int i;
    for(i = 0; i < STH_BLD_COUNT; i++)
    {
        int nLevel  = StrongholdGetLevel(sUuid, i);
        int nFinish = StrongholdGetUpgradeFinish(sUuid, i);
        int bUpging = (nFinish > 0 && nNow < nFinish);

        string sLvl = (nLevel == 0) ? "Ruina" : "Poziom " + IntToString(nLevel);
        string sSub = "";
        if(bUpging)
        {
            int nSec = nFinish - nNow;
            sSub = "(trwa rozbudowa... " + IntToString(nSec / 60) + "m " + IntToString(nSec % 60) + "s)";
        }

        NuiSetBind(oPC, nToken, STH_BIND_BLD_NAME + IntToString(i), JsonString(StrongholdBuildingName(i)));
        NuiSetBind(oPC, nToken, STH_BIND_BLD_LVL  + IntToString(i), JsonString(sLvl));
        NuiSetBind(oPC, nToken, STH_BIND_BLD_SUB  + IntToString(i), JsonString(sSub));
        NuiSetBind(oPC, nToken, STH_BIND_BLD_ENC  + IntToString(i), JsonBool(i == nSelId));
    }

    NuiSetBind(oPC, nToken, STH_BIND_GOLD,   JsonString("Złoto: " + IntToString(GetGold(oPC)) + " szt."));
    NuiSetBind(oPC, nToken, STH_BIND_HEADER, JsonString("Twierdza — " + GetName(oPC)));
}

void StrongholdFeedDetail(object oPC, int nToken, int nBldId)
{
    if(nBldId < 0)
    {
        NuiSetBind(oPC, nToken, STH_BIND_SEL_VIS + "_none", JsonBool(TRUE));
        NuiSetBind(oPC, nToken, STH_BIND_SEL_VIS + "_sel",  JsonBool(FALSE));
        NuiSetBind(oPC, nToken, STH_BIND_UPG_ENA, JsonBool(FALSE));
        NuiSetBind(oPC, nToken, STH_BIND_CAN_ENA, JsonBool(FALSE));
        return;
    }

    string sUuid   = GetObjectUUID(oPC);
    int    nLevel  = StrongholdGetLevel(sUuid, nBldId);
    int    nFinish = StrongholdGetUpgradeFinish(sUuid, nBldId);
    int    nNow    = StrongholdNow();
    int    bUpging = (nFinish > 0 && nNow < nFinish);

    string sHdr = StrongholdBuildingName(nBldId) + " — "
        + ((nLevel == 0) ? "Ruina" : "Poziom " + IntToString(nLevel));

    string sCurrEff = StrongholdBuildingEffectDesc(nBldId, nLevel);
    string sDesc    = StrongholdBuildingDesc(nBldId);

    string sNextLbl = "";
    string sNextEff = "";
    int bCanUpgrade = FALSE;
    int bCanCancel  = FALSE;

    if(bUpging)
    {
        int nSec = nFinish - nNow;
        sNextLbl = "Rozbudowa w toku... pozostało " + IntToString(nSec / 60) + "m " + IntToString(nSec % 60) + "s.";
        sNextEff = "(Anuluj, aby odzyskać połowę złota)";
        bCanCancel = TRUE;
    }
    else if(nLevel < STH_MAX_LEVEL)
    {
        int nTargetLvl = nLevel + 1;
        int nCost      = StrongholdUpgradeCost(nTargetLvl);
        float fDelay   = StrongholdUpgradeDelay(nTargetLvl);
        int nMins      = FloatToInt(fDelay) / 60;
        int nSecs      = FloatToInt(fDelay) % 60;

        sNextLbl = "Następny poziom " + IntToString(nTargetLvl)
            + " — koszt: " + IntToString(nCost) + " szt. złota"
            + " (" + IntToString(nMins) + "m " + IntToString(nSecs) + "s)";
        sNextEff = StrongholdBuildingEffectDesc(nBldId, nTargetLvl);
        bCanUpgrade = (GetGold(oPC) >= nCost);
    }
    else
    {
        sNextLbl = "Budynek jest na maksymalnym poziomie.";
        sNextEff = "";
    }

    NuiSetBind(oPC, nToken, STH_BIND_SEL_VIS + "_none", JsonBool(FALSE));
    NuiSetBind(oPC, nToken, STH_BIND_SEL_VIS + "_sel",  JsonBool(TRUE));
    NuiSetBind(oPC, nToken, STH_BIND_SEL_HDR,  JsonString(sHdr));
    NuiSetBind(oPC, nToken, STH_BIND_SEL_DESC, JsonString(sDesc));
    NuiSetBind(oPC, nToken, STH_BIND_SEL_EFF,  JsonString(sCurrEff));
    NuiSetBind(oPC, nToken, STH_BIND_UPG_LBL,  JsonString(sNextLbl));
    NuiSetBind(oPC, nToken, STH_BIND_SEL_NEXT, JsonString(sNextEff));
    NuiSetBind(oPC, nToken, STH_BIND_UPG_ENA,  JsonBool(bCanUpgrade));
    NuiSetBind(oPC, nToken, STH_BIND_CAN_ENA,  JsonBool(bCanCancel));
}

// ----------------------------------------------------------------
// Open
// ----------------------------------------------------------------

void StrongholdOpen(object oPC)
{
    StrongholdCheckUpgrades(oPC);

    int nToken = NuiFindWindow(oPC, STH_WINDOW);
    if(nToken != 0)
    {
        StrongholdFeedGrid(oPC, nToken);
        int nSel = GetLocalInt(oPC, STH_LVAR_SEL);
        if(!GetLocalInt(oPC, "STH_HAS_SEL")) nSel = -1;
        StrongholdFeedDetail(oPC, nToken, nSel);
        return;
    }

    SetLocalInt(oPC, STH_LVAR_SEL, -1);
    DeleteLocalInt(oPC, "STH_HAS_SEL");

    json jWin  = StrongholdBuildWindow(oPC);
    nToken     = NuiCreate(oPC, jWin, STH_WINDOW, STH_EV_SCRIPT);

    float fCX = (IntToFloat(GetPlayerDeviceProperty(oPC, PLAYER_DEVICE_PROPERTY_GUI_WIDTH))  - GetNuiScaleDimension(oPC, STH_W)) / 2.0;
    float fCY = (IntToFloat(GetPlayerDeviceProperty(oPC, PLAYER_DEVICE_PROPERTY_GUI_HEIGHT)) - GetNuiScaleDimension(oPC, STH_H)) / 2.0;
    NuiSetBind(oPC, nToken, STH_WIN_GEOM,
        NuiRect(fCX, fCY, GetNuiScaleDimension(oPC, STH_W), GetNuiScaleDimension(oPC, STH_H)));

    StrongholdFeedGrid(oPC, nToken);
    StrongholdFeedDetail(oPC, nToken, -1);
}
