// lib_brand.nss -- Core NUI layout, game logic and effect management for Brand System
#include "lib_brand_def"

// ----------------------------------------------------------------
// Effect management
// ----------------------------------------------------------------

void BrandRemoveAllEffects(object oPC)
{
    effect eEff = GetFirstEffect(oPC);
    while(GetIsEffectValid(eEff))
    {
        if(GetEffectTag(eEff) == BRAND_EFFECT_TAG)
            RemoveEffect(oPC, eEff);
        eEff = GetNextEffect(oPC);
    }
}

void BrandClearSocialFlags(object oPC)
{
    DeleteLocalInt(oPC, BRAND_LVAR_FX_SLAVE);
    DeleteLocalInt(oPC, BRAND_LVAR_FX_CRIM);
    DeleteLocalInt(oPC, BRAND_LVAR_FX_HERET);
    DeleteLocalInt(oPC, BRAND_LVAR_FX_HUNT);
    DeleteLocalInt(oPC, BRAND_LVAR_FX_INF);
    DeleteLocalInt(oPC, BRAND_LVAR_FX_BLOOD);
    DeleteLocalInt(oPC, BRAND_LVAR_FX_EXILE);
}

void BrandApplyOneEffect(object oPC, effect eEff)
{
    eEff = TagEffect(eEff, BRAND_EFFECT_TAG);
    ApplyEffectToObject(DURATION_TYPE_PERMANENT, eEff, oPC);
}

void BrandApplyEffects(object oPC)
{
    BrandRemoveAllEffects(oPC);
    BrandClearSocialFlags(oPC);

    json jAll = BrandGetAll(GetObjectUUID(oPC));
    int nCount = JsonGetLength(jAll);
    int i;
    for(i = 0; i < nCount; i++)
    {
        json jRow       = JsonArrayGet(jAll, i);
        int  nType      = JsonGetInt(JsonObjectGet(jRow, "type"));
        int  bConcealed = JsonGetInt(JsonObjectGet(jRow, "is_concealed"));

        switch(nType)
        {
            case BRAND_TYPE_SLAVE:
                BrandApplyOneEffect(oPC, EffectAbilityDecrease(ABILITY_STRENGTH,  2));
                BrandApplyOneEffect(oPC, EffectAbilityDecrease(ABILITY_CHARISMA,  4));
                if(!bConcealed)
                    SetLocalInt(oPC, BRAND_LVAR_FX_SLAVE, 1);
                break;

            case BRAND_TYPE_CRIMINAL:
                BrandApplyOneEffect(oPC, EffectSkillDecrease(SKILL_PERSUADE,      4));
                BrandApplyOneEffect(oPC, EffectSkillDecrease(SKILL_BLUFF,         2));
                if(!bConcealed)
                    SetLocalInt(oPC, BRAND_LVAR_FX_CRIM, 1);
                break;

            case BRAND_TYPE_HERETIC:
                BrandApplyOneEffect(oPC, EffectAbilityDecrease(ABILITY_WISDOM,    2));
                if(!bConcealed)
                    SetLocalInt(oPC, BRAND_LVAR_FX_HERET, 1);
                break;

            case BRAND_TYPE_HUNTER:
                BrandApplyOneEffect(oPC, EffectSkillIncrease(SKILL_SPOT,          2));
                BrandApplyOneEffect(oPC, EffectSkillIncrease(SKILL_LISTEN,        2));
                if(!bConcealed)
                    SetLocalInt(oPC, BRAND_LVAR_FX_HUNT, 1);
                break;

            case BRAND_TYPE_INFERNAL:
                BrandApplyOneEffect(oPC, EffectDamageResistance(DAMAGE_TYPE_FIRE, 5, 0));
                BrandApplyOneEffect(oPC, EffectAbilityDecrease(ABILITY_WISDOM,    2));
                if(!bConcealed)
                    SetLocalInt(oPC, BRAND_LVAR_FX_INF, 1);
                break;

            case BRAND_TYPE_BLOOD:
                BrandApplyOneEffect(oPC, EffectAbilityIncrease(ABILITY_CONSTITUTION, 2));
                if(!bConcealed)
                    SetLocalInt(oPC, BRAND_LVAR_FX_BLOOD, 1);
                break;

            case BRAND_TYPE_EXILE:
                BrandApplyOneEffect(oPC, EffectSkillIncrease(SKILL_HIDE,          2));
                BrandApplyOneEffect(oPC, EffectSkillIncrease(SKILL_MOVE_SILENTLY, 2));
                BrandApplyOneEffect(oPC, EffectAbilityDecrease(ABILITY_CHARISMA,  2));
                if(!bConcealed)
                    SetLocalInt(oPC, BRAND_LVAR_FX_EXILE, 1);
                break;
        }
    }
}

// ----------------------------------------------------------------
// Apply / remove a brand
// ----------------------------------------------------------------

void BrandApply(object oBrander, object oBranded, int nLoc, int nType, string sName, string sOrigin)
{
    if(!GetIsObjectValid(oBranded) || !GetIsPC(oBranded)) return;
    if(nLoc < 0 || nLoc >= BRAND_LOC_COUNT)              return;
    if(nType < BRAND_TYPE_SLAVE || nType > BRAND_TYPE_EXILE) return;

    string sUuid        = GetObjectUUID(oBranded);
    string sBranderName = GetIsObjectValid(oBrander) ? GetName(oBrander) : "Nieznany";
    if(sName   == "") sName   = BrandTypeName(nType);
    if(sOrigin == "") sOrigin = BrandOriginDefault(nType);

    BrandWrite(sUuid, nLoc, nType, sName, sOrigin, sBranderName);
    BrandLogEntry(GetObjectUUID(oBrander), sUuid, nLoc, nType);
    BrandApplyEffects(oBranded);

    string sLocName = BrandLocationName(nLoc);
    FloatingTextStringOnCreature(
        "Pieczen pulsuje na twoim " + sLocName + ". " + sName + " zostalo wypalzone.",
        oBranded, FALSE);
    SendMessageToPC(oBranded,
        "[Pietna] " + sName + " naniesione na " + sLocName + ". Otwórz okno piet, by zobaczyc efekty.");
}

void BrandRemoveAtLocation(object oPC, int nLoc)
{
    string sUuid = GetObjectUUID(oPC);
    int nGold    = GetGold(oPC);

    if(nGold < BRAND_REMOVE_GOLD)
    {
        SendMessageToPC(oPC, "[Pietna] Potrzebujesz " + IntToString(BRAND_REMOVE_GOLD) + " sztuk zlota na usluge chirurga.");
        return;
    }

    json jBrand = BrandGetAtLoc(sUuid, nLoc);
    if(JsonGetType(jBrand) == JSON_TYPE_NULL) return;

    AssignCommand(oPC, TakeGoldFromCreature(BRAND_REMOVE_GOLD, oPC, TRUE));

    int nHeal    = GetSkillRank(SKILL_HEAL, oPC);
    int nRoll    = d20();
    int nTotal   = nRoll + nHeal;

    string sLocName = BrandLocationName(nLoc);

    if(nTotal >= BRAND_REMOVE_DC)
    {
        // Success: brand removed, only scar remains in log
        BrandDeleteAtLoc(sUuid, nLoc);
        BrandApplyEffects(oPC);
        FloatingTextStringOnCreature("Pieczen zostala usnieta z " + sLocName + ".", oPC, FALSE);
        SendMessageToPC(oPC, "[Pietna] Usuwanie powiodlo sie (rzut " + IntToString(nTotal) + " vs DC " + IntToString(BRAND_REMOVE_DC) + "). Blizna pozostanie.");
    }
    else
    {
        // Failure: damage, brand stays, scarred flag set
        BrandSetScarred(sUuid, nLoc);
        effect eDmg = EffectDamage(BRAND_REMOVE_FAIL_DMG + d6(2), DAMAGE_TYPE_FIRE);
        ApplyEffectToObject(DURATION_TYPE_INSTANT, eDmg, oPC);
        SendMessageToPC(oPC, "[Pietna] Usuwanie zawiodlo (rzut " + IntToString(nTotal) + " vs DC " + IntToString(BRAND_REMOVE_DC) + "). Pieczen pozostaje, rana jest powazna.");
        FloatingTextStringOnCreature("Pieczen opiera sie! Skóra gore bolem.", oPC, FALSE);
    }
}

// ----------------------------------------------------------------
// NUI helpers
// ----------------------------------------------------------------

json BuildBrandDetailEmpty(object oPC)
{
    float fBtnH = GetNuiScaleDimension(oPC, 26.0);
    float fH    = GetNuiScaleDimension(oPC, 160.0);

    json jLbl = NuiLabel(
        JsonString("Wybierz lokalizacje na liscie, aby zobaczyc szczegoly pietna."),
        JsonInt(NUI_HALIGN_CENTER), JsonInt(NUI_VALIGN_MIDDLE));
    jLbl = NuiHeight(jLbl, fH);

    return NuiCol(JsonArrayInsert(JsonArray(), jLbl));
}

json BuildBrandDetailPanel(object oPC)
{
    float fBtnH  = GetNuiScaleDimension(oPC, 28.0);
    float fLblH  = GetNuiScaleDimension(oPC, 20.0);
    float fFxH   = GetNuiScaleDimension(oPC, 80.0);
    float fLblW  = GetNuiScaleDimension(oPC, 100.0);

    // Brand name header
    json jNameRow = JsonArray();
    json jNameLbl  = NuiLabel(JsonString("Pietno:"), JsonInt(NUI_HALIGN_LEFT), JsonInt(NUI_VALIGN_MIDDLE));
    jNameLbl = NuiWidth(jNameLbl, fLblW);
    json jNameVal  = NuiLabel(NuiBind(BRAND_BIND_DET_NAME), JsonInt(NUI_HALIGN_LEFT), JsonInt(NUI_VALIGN_MIDDLE));
    jNameVal = NuiStyleForegroundColor(jNameVal, NuiColor(220, 100, 60));
    jNameRow = JsonArrayInsert(jNameRow, jNameLbl);
    jNameRow = JsonArrayInsert(jNameRow, jNameVal);

    // Type row
    json jTypeRow = JsonArray();
    json jTypeLbl  = NuiLabel(JsonString("Rodzaj:"), JsonInt(NUI_HALIGN_LEFT), JsonInt(NUI_VALIGN_MIDDLE));
    jTypeLbl = NuiWidth(jTypeLbl, fLblW);
    json jTypeVal  = NuiLabel(NuiBind(BRAND_BIND_DET_TYPE), JsonInt(NUI_HALIGN_LEFT), JsonInt(NUI_VALIGN_MIDDLE));
    jTypeRow = JsonArrayInsert(jTypeRow, jTypeLbl);
    jTypeRow = JsonArrayInsert(jTypeRow, jTypeVal);

    // Brander row
    json jBranderRow = JsonArray();
    json jBranderLbl  = NuiLabel(JsonString("Wymierzone przez:"), JsonInt(NUI_HALIGN_LEFT), JsonInt(NUI_VALIGN_MIDDLE));
    jBranderLbl = NuiWidth(jBranderLbl, fLblW);
    json jBranderVal  = NuiLabel(NuiBind(BRAND_BIND_DET_BRANDER), JsonInt(NUI_HALIGN_LEFT), JsonInt(NUI_VALIGN_MIDDLE));
    jBranderRow = JsonArrayInsert(jBranderRow, jBranderLbl);
    jBranderRow = JsonArrayInsert(jBranderRow, jBranderVal);

    // Origin text
    json jOriginLbl = NuiLabel(JsonString("Pochodzenie:"), JsonInt(NUI_HALIGN_LEFT), JsonInt(NUI_VALIGN_MIDDLE));
    jOriginLbl = NuiHeight(jOriginLbl, fLblH);
    json jOriginTxt = NuiGroup(NuiText(NuiBind(BRAND_BIND_DET_ORIGIN), FALSE), TRUE, NUI_SCROLLBARS_NONE);
    jOriginTxt = NuiHeight(jOriginTxt, GetNuiScaleDimension(oPC, 50.0));

    // Effects
    json jFxLbl = NuiLabel(JsonString("Efekty:"), JsonInt(NUI_HALIGN_LEFT), JsonInt(NUI_VALIGN_MIDDLE));
    jFxLbl = NuiHeight(jFxLbl, fLblH);
    json jFxTxt = NuiGroup(NuiText(NuiBind(BRAND_BIND_DET_FX), FALSE), TRUE, NUI_SCROLLBARS_NONE);
    jFxTxt = NuiHeight(jFxTxt, fFxH);

    // Conceal state + button
    json jCstateRow = JsonArray();
    json jCstateLbl = NuiLabel(JsonString("Stan:"), JsonInt(NUI_HALIGN_LEFT), JsonInt(NUI_VALIGN_MIDDLE));
    jCstateLbl = NuiWidth(jCstateLbl, fLblW);
    json jCstateVal = NuiLabel(NuiBind(BRAND_BIND_DET_CSTATE), JsonInt(NUI_HALIGN_LEFT), JsonInt(NUI_VALIGN_MIDDLE));
    json jConcBtn   = NuiButton(NuiBind(BRAND_BIND_BTN_CONCEAL_L));
    jConcBtn = NuiId(jConcBtn, BRAND_BTN_CONCEAL);
    jConcBtn = NuiWidth(jConcBtn, GetNuiScaleDimension(oPC, 100.0));
    jConcBtn = NuiHeight(jConcBtn, fBtnH);
    jCstateRow = JsonArrayInsert(jCstateRow, jCstateLbl);
    jCstateRow = JsonArrayInsert(jCstateRow, jCstateVal);
    jCstateRow = JsonArrayInsert(jCstateRow, NuiSpacer());
    jCstateRow = JsonArrayInsert(jCstateRow, jConcBtn);

    // Remove button
    json jRemoveBtn = NuiButton(JsonString("Usun Pietno"));
    jRemoveBtn = NuiId(jRemoveBtn, BRAND_BTN_REMOVE);
    jRemoveBtn = NuiEnabled(jRemoveBtn, NuiBind(BRAND_BIND_BTN_REM_ENA));
    jRemoveBtn = NuiHeight(jRemoveBtn, fBtnH);
    json jRemoveRow = JsonArray();
    jRemoveRow = JsonArrayInsert(jRemoveRow, NuiSpacer());
    jRemoveRow = JsonArrayInsert(jRemoveRow, NuiWidth(jRemoveBtn, GetNuiScaleDimension(oPC, 160.0)));
    jRemoveRow = JsonArrayInsert(jRemoveRow, NuiSpacer());

    json jCol = JsonArray();
    jCol = JsonArrayInsert(jCol, NuiRow(jNameRow));
    jCol = JsonArrayInsert(jCol, NuiRow(jTypeRow));
    jCol = JsonArrayInsert(jCol, NuiRow(jBranderRow));
    jCol = JsonArrayInsert(jCol, jOriginLbl);
    jCol = JsonArrayInsert(jCol, jOriginTxt);
    jCol = JsonArrayInsert(jCol, jFxLbl);
    jCol = JsonArrayInsert(jCol, jFxTxt);
    jCol = JsonArrayInsert(jCol, NuiRow(jCstateRow));
    jCol = JsonArrayInsert(jCol, CreateEmptyRow(oPC, 6.0));
    jCol = JsonArrayInsert(jCol, NuiRow(jRemoveRow));

    return NuiCol(jCol);
}

json BuildBrandLocationList(object oPC)
{
    float fRowH = GetNuiScaleDimension(oPC, 28.0);
    float fLocW = GetNuiScaleDimension(oPC, 120.0);
    float fStW  = GetNuiScaleDimension(oPC, 70.0);

    json jLocLbl = NuiLabel(NuiBind(BRAND_BIND_ROW_LOC_NAME), JsonInt(NUI_HALIGN_LEFT), JsonInt(NUI_VALIGN_MIDDLE));
    jLocLbl = NuiStyleForegroundColor(jLocLbl, NuiBind(BRAND_BIND_ROW_COLOR));
    jLocLbl = NuiWidth(jLocLbl, fLocW);

    json jBrandLbl = NuiLabel(NuiBind(BRAND_BIND_ROW_NAME), JsonInt(NUI_HALIGN_LEFT), JsonInt(NUI_VALIGN_MIDDLE));
    jBrandLbl = NuiStyleForegroundColor(jBrandLbl, NuiBind(BRAND_BIND_ROW_COLOR));

    json jStatusLbl = NuiLabel(NuiBind(BRAND_BIND_ROW_STATUS), JsonInt(NUI_HALIGN_CENTER), JsonInt(NUI_VALIGN_MIDDLE));
    jStatusLbl = NuiStyleForegroundColor(jStatusLbl, NuiBind(BRAND_BIND_ROW_COLOR));
    jStatusLbl = NuiWidth(jStatusLbl, fStW);

    json jCell = NuiGroup(NuiRow(
        JsonArrayInsert(JsonArrayInsert(JsonArrayInsert(JsonArray(),
            jLocLbl), jBrandLbl), jStatusLbl)),
        TRUE, NUI_SCROLLBARS_NONE);
    jCell = NuiId(jCell, BRAND_BTN_ROW);
    jCell = NuiEncouraged(jCell, NuiBind(BRAND_BIND_ROW_ENC));

    json jTmpl = JsonArrayInsert(JsonArray(), NuiListTemplateCell(jCell, 0.0, TRUE));
    float fListH = GetNuiScaleDimension(oPC, 210.0);
    json jList = NuiList(jTmpl, NuiBind(BRAND_BIND_ROW_COUNT), fRowH);
    jList = NuiHeight(jList, fListH);
    return jList;
}

void CreateBrandWindow(object oPC)
{
    if(NuiFindWindow(oPC, BRAND_WINDOW) != 0)
    {
        FeedBrandLocations(oPC, NuiFindWindow(oPC, BRAND_WINDOW));
        return;
    }

    float fW  = GetNuiScaleDimension(oPC, BRAND_W);
    float fH  = GetNuiScaleDimension(oPC, BRAND_H);
    float fCX = (IntToFloat(GetPlayerDeviceProperty(oPC, PLAYER_DEVICE_PROPERTY_GUI_WIDTH))  - fW) / 2.0;
    float fCY = (IntToFloat(GetPlayerDeviceProperty(oPC, PLAYER_DEVICE_PROPERTY_GUI_HEIGHT)) - fH) / 2.0;

    float fBtnH = GetNuiScaleDimension(oPC, 28.0);

    // Title bar
    json jTitle = NuiLabel(JsonString("Pietna i Znaczenia"),
        JsonInt(NUI_HALIGN_LEFT), JsonInt(NUI_VALIGN_MIDDLE));
    jTitle = NuiStyleForegroundColor(jTitle, NuiColor(185, 150, 100));
    json jClose = NuiButton(JsonString("X"));
    jClose = NuiId(jClose, BRAND_BTN_CLOSE);
    jClose = NuiWidth(jClose, GetNuiScaleDimension(oPC, 28.0));
    jClose = NuiHeight(jClose, fBtnH);
    json jTitleRow = JsonArray();
    jTitleRow = JsonArrayInsert(jTitleRow, jTitle);
    jTitleRow = JsonArrayInsert(jTitleRow, NuiSpacer());
    jTitleRow = JsonArrayInsert(jTitleRow, jClose);

    // Location list
    json jList = BuildBrandLocationList(oPC);

    // Separator label
    json jSepLbl = NuiLabel(JsonString("--- Szczegoly pietna ---"),
        JsonInt(NUI_HALIGN_CENTER), JsonInt(NUI_VALIGN_MIDDLE));
    jSepLbl = NuiHeight(jSepLbl, GetNuiScaleDimension(oPC, 20.0));
    jSepLbl = NuiStyleForegroundColor(jSepLbl, NuiColor(140, 100, 60));

    // Detail group (swappable)
    json jDetGrp = NuiGroup(BuildBrandDetailEmpty(oPC), FALSE, NUI_SCROLLBARS_NONE);
    jDetGrp = NuiId(jDetGrp, BRAND_GRP_DETAIL);
    jDetGrp = NuiHeight(jDetGrp, GetNuiScaleDimension(oPC, 270.0));

    // Status bar
    json jStatus = NuiLabel(NuiBind(BRAND_BIND_STATUS),
        JsonInt(NUI_HALIGN_LEFT), JsonInt(NUI_VALIGN_MIDDLE));
    jStatus = NuiStyleForegroundColor(jStatus, NuiColor(140, 140, 140));
    jStatus = NuiHeight(jStatus, GetNuiScaleDimension(oPC, 20.0));

    // Root column
    json jRoot = JsonArray();
    jRoot = JsonArrayInsert(jRoot, NuiRow(jTitleRow));
    jRoot = JsonArrayInsert(jRoot, CreateEmptyRow(oPC, 4.0));
    jRoot = JsonArrayInsert(jRoot, jList);
    jRoot = JsonArrayInsert(jRoot, jSepLbl);
    jRoot = JsonArrayInsert(jRoot, jDetGrp);
    jRoot = JsonArrayInsert(jRoot, jStatus);

    json jGeom = NuiRect(fCX, fCY, fW, fH);
    json jWin = NuiWindow(NuiCol(jRoot),
        JsonBool(FALSE),
        NuiBind(BRAND_WIN_GEOM),
        JsonBool(FALSE),
        JsonBool(FALSE),
        JsonBool(FALSE),
        JsonBool(TRUE),
        JsonBool(FALSE));

    int nToken = NuiCreate(oPC, jWin, BRAND_WINDOW, BRAND_EV_SCRIPT);
    NuiSetBind(oPC, nToken, BRAND_WIN_GEOM, jGeom);
    SetLocalInt(oPC, BRAND_LVAR_SEL_LOC, -1);
    FeedBrandLocations(oPC, nToken);
}

// ----------------------------------------------------------------
// Feed functions
// ----------------------------------------------------------------

void FeedBrandLocations(object oPC, int nToken)
{
    string sUuid = GetObjectUUID(oPC);
    json jAll    = BrandGetAll(sUuid);
    int  nTotal  = JsonGetLength(jAll);

    // Build a lookup map: location -> brand row
    json jByLoc = JsonObject();
    int i;
    for(i = 0; i < nTotal; i++)
    {
        json jRow  = JsonArrayGet(jAll, i);
        int  nLoc  = JsonGetInt(JsonObjectGet(jRow, "location"));
        jByLoc = JsonObjectSet(jByLoc, IntToString(nLoc), jRow);
    }

    int    nSelLoc  = GetLocalInt(oPC, BRAND_LVAR_SEL_LOC);
    json   jWhite   = NuiColor(255, 255, 255);
    json   jGray    = NuiColor(100, 100, 100);
    json   jRed     = NuiColor(200, 70,  50);
    json   jYellow  = NuiColor(200, 180, 60);

    json jLocNames = JsonArray();
    json jNames    = JsonArray();
    json jColors   = JsonArray();
    json jEncs     = JsonArray();
    json jStatuses = JsonArray();

    int nActiveBrands = 0;

    for(i = 0; i < BRAND_LOC_COUNT; i++)
    {
        string sLocName = BrandLocationName(i);
        json   jBrand   = JsonObjectGet(jByLoc, IntToString(i));
        int    bHas     = (JsonGetType(jBrand) != JSON_TYPE_NULL);
        int    bConc    = bHas ? JsonGetInt(JsonObjectGet(jBrand, "is_concealed")) : 0;
        string sBName   = bHas ? JsonGetString(JsonObjectGet(jBrand, "name")) : "-- wolne --";

        string sStatus  = "";
        json   jColor;
        if(!bHas)
        {
            jColor  = jGray;
        }
        else if(bConc)
        {
            jColor  = jYellow;
            sStatus = "Ukryta";
            nActiveBrands++;
        }
        else
        {
            jColor  = jRed;
            sStatus = "Aktywna";
            nActiveBrands++;
        }

        jLocNames = JsonArrayInsert(jLocNames, JsonString(sLocName));
        jNames    = JsonArrayInsert(jNames,    JsonString(sBName));
        jColors   = JsonArrayInsert(jColors,   jColor);
        jEncs     = JsonArrayInsert(jEncs,     JsonBool(i == nSelLoc));
        jStatuses = JsonArrayInsert(jStatuses, JsonString(sStatus));
    }

    NuiSetBind(oPC, nToken, BRAND_BIND_ROW_LOC_NAME, jLocNames);
    NuiSetBind(oPC, nToken, BRAND_BIND_ROW_NAME,      jNames);
    NuiSetBind(oPC, nToken, BRAND_BIND_ROW_COLOR,     jColors);
    NuiSetBind(oPC, nToken, BRAND_BIND_ROW_ENC,       jEncs);
    NuiSetBind(oPC, nToken, BRAND_BIND_ROW_STATUS,    jStatuses);
    NuiSetBind(oPC, nToken, BRAND_BIND_ROW_COUNT,     JsonInt(BRAND_LOC_COUNT));

    string sStatusMsg = "Aktywne pietna: " + IntToString(nActiveBrands) + " / " + IntToString(BRAND_LOC_COUNT) + "   |   Zloto na usuniecie: " + IntToString(BRAND_REMOVE_GOLD) + " sz (Leczenie DC " + IntToString(BRAND_REMOVE_DC) + ")";
    NuiSetBind(oPC, nToken, BRAND_BIND_STATUS, JsonString(sStatusMsg));
}

void FeedBrandDetail(object oPC, int nToken, int nLoc)
{
    string sUuid = GetObjectUUID(oPC);
    json   jBrand = BrandGetAtLoc(sUuid, nLoc);

    if(JsonGetType(jBrand) == JSON_TYPE_NULL)
    {
        NuiSetGroupLayout(oPC, nToken, BRAND_GRP_DETAIL, BuildBrandDetailEmpty(oPC));
        return;
    }

    NuiSetGroupLayout(oPC, nToken, BRAND_GRP_DETAIL, BuildBrandDetailPanel(oPC));

    int    nType     = JsonGetInt   (JsonObjectGet(jBrand, "type"));
    int    bConc     = JsonGetInt   (JsonObjectGet(jBrand, "is_concealed"));
    int    bScarred  = JsonGetInt   (JsonObjectGet(jBrand, "is_scarred"));
    string sName     = JsonGetString(JsonObjectGet(jBrand, "name"));
    string sOrigin   = JsonGetString(JsonObjectGet(jBrand, "origin"));
    string sBrander  = JsonGetString(JsonObjectGet(jBrand, "brander_name"));

    string sCState   = bConc    ? "Ukryta (efekty spoleczne nieaktywne)" : "Widoczna (wszystkie efekty aktywne)";
    if(bScarred) sCState = sCState + " [Blizna po probie usuniecia]";
    string sConcBtn  = bConc    ? "Odslon" : "Ukryj";

    NuiSetBind(oPC, nToken, BRAND_BIND_DET_NAME,      JsonString(sName));
    NuiSetBind(oPC, nToken, BRAND_BIND_DET_TYPE,      JsonString(BrandTypeName(nType)));
    NuiSetBind(oPC, nToken, BRAND_BIND_DET_BRANDER,   JsonString(sBrander));
    NuiSetBind(oPC, nToken, BRAND_BIND_DET_ORIGIN,    JsonString(sOrigin));
    NuiSetBind(oPC, nToken, BRAND_BIND_DET_FX,        JsonString(BrandEffectDesc(nType)));
    NuiSetBind(oPC, nToken, BRAND_BIND_DET_CSTATE,    JsonString(sCState));
    NuiSetBind(oPC, nToken, BRAND_BIND_BTN_CONCEAL_L, JsonString(sConcBtn));
    NuiSetBind(oPC, nToken, BRAND_BIND_BTN_REM_ENA,   JsonBool(TRUE));
}

// ----------------------------------------------------------------
// Remove confirm popup
// ----------------------------------------------------------------

void CreateBrandRemoveConfirm(object oPC, int nLoc)
{
    SetLocalInt(oPC, BRAND_LVAR_PENDING, nLoc);

    if(NuiFindWindow(oPC, BRAND_WIN_CONFIRM) != 0)
        NuiDestroy(oPC, NuiFindWindow(oPC, BRAND_WIN_CONFIRM));

    float fW = GetNuiScaleDimension(oPC, 440.0);
    float fH = GetNuiScaleDimension(oPC, 180.0);
    float fX = (IntToFloat(GetPlayerDeviceProperty(oPC, PLAYER_DEVICE_PROPERTY_GUI_WIDTH))  - fW) / 2.0;
    float fY = (IntToFloat(GetPlayerDeviceProperty(oPC, PLAYER_DEVICE_PROPERTY_GUI_HEIGHT)) - fH) / 2.0;
    float fBtnH = GetNuiScaleDimension(oPC, 28.0);

    string sMsg = "Usuniecie pietna kosztuje " + IntToString(BRAND_REMOVE_GOLD) + " sztuk zlota.\n"
                + "Wymagany test Leczenia DC " + IntToString(BRAND_REMOVE_DC) + ".\n"
                + "Niepowodzenie: obra zenia ogniowe " + IntToString(BRAND_REMOVE_FAIL_DMG) + "+2k6.\n\n"
                + "Czy kontynuowac?";

    json jMsg = NuiLabel(JsonString(sMsg), JsonInt(NUI_HALIGN_CENTER), JsonInt(NUI_VALIGN_MIDDLE));

    json jYes = NuiButton(JsonString("Tak, usun"));
    jYes = NuiId(jYes, BRAND_BTN_CONFIRM_YES);
    jYes = NuiWidth(jYes, GetNuiScaleDimension(oPC, 120.0));
    jYes = NuiHeight(jYes, fBtnH);

    json jNo = NuiButton(JsonString("Anuluj"));
    jNo = NuiId(jNo, BRAND_BTN_CONFIRM_NO);
    jNo = NuiWidth(jNo, GetNuiScaleDimension(oPC, 100.0));
    jNo = NuiHeight(jNo, fBtnH);

    json jBtnRow = JsonArray();
    jBtnRow = JsonArrayInsert(jBtnRow, NuiSpacer());
    jBtnRow = JsonArrayInsert(jBtnRow, jYes);
    jBtnRow = JsonArrayInsert(jBtnRow, NuiSpacer());
    jBtnRow = JsonArrayInsert(jBtnRow, jNo);
    jBtnRow = JsonArrayInsert(jBtnRow, NuiSpacer());

    json jCol = JsonArray();
    jCol = JsonArrayInsert(jCol, jMsg);
    jCol = JsonArrayInsert(jCol, CreateEmptyRow(oPC, 8.0));
    jCol = JsonArrayInsert(jCol, NuiRow(jBtnRow));

    json jWin = NuiWindow(NuiCol(jCol),
        JsonString("Usun Pietno"),
        NuiRect(fX, fY, fW, fH),
        JsonBool(FALSE), JsonBool(FALSE), JsonBool(TRUE),
        JsonBool(FALSE), JsonBool(TRUE));

    NuiCreate(oPC, jWin, BRAND_WIN_CONFIRM, BRAND_EV_SCRIPT);
}
