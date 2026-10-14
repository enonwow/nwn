#include "lib_tatu_def"

// ----------------------------------------------------------------
// Effect application helpers
// ----------------------------------------------------------------

void TatuRemoveEffectsForSlot(object oPC, int nSlotIdx)
{
    int nTag = TATU_EFFECT_TAG_BASE + nSlotIdx;
    effect eEff  = GetFirstEffect(oPC);
    effect eNext;
    while(GetIsEffectValid(eEff))
    {
        eNext = GetNextEffect(oPC);
        if(GetEffectTag(eEff) == nTag)
            RemoveEffect(oPC, eEff);
        eEff = eNext;
    }
}

void TatuApplyDesignEffects(object oPC, json jDesign, int nSlotIdx)
{
    int nTag = TATU_EFFECT_TAG_BASE + nSlotIdx;

    int nBonAb  = JsonGetInt(JsonObjectGet(jDesign, "bon_ab"));
    int nBonAc  = JsonGetInt(JsonObjectGet(jDesign, "bon_ac"));
    int nBonSk  = JsonGetInt(JsonObjectGet(jDesign, "bon_skill"));
    int nBonSkV = JsonGetInt(JsonObjectGet(jDesign, "bon_skill_v"));
    int nBonSv  = JsonGetInt(JsonObjectGet(jDesign, "bon_save"));
    int nBonSvV = JsonGetInt(JsonObjectGet(jDesign, "bon_save_v"));
    int nBonRs  = JsonGetInt(JsonObjectGet(jDesign, "bon_resist"));
    int bCursed = JsonGetInt(JsonObjectGet(jDesign, "is_cursed"));
    int nCurAb  = JsonGetInt(JsonObjectGet(jDesign, "curse_ab"));
    int nCurSv  = JsonGetInt(JsonObjectGet(jDesign, "curse_saves"));
    int nCurCha = JsonGetInt(JsonObjectGet(jDesign, "curse_cha"));

    if(nBonAb > 0)
        ApplyEffectToObject(DURATION_TYPE_PERMANENT,
            TagEffect(EffectAttackIncrease(nBonAb), nTag), oPC);

    if(nBonAc > 0)
        ApplyEffectToObject(DURATION_TYPE_PERMANENT,
            TagEffect(EffectACIncrease(nBonAc, AC_DODGE_BONUS), nTag), oPC);

    if(nBonSk >= 0 && nBonSkV > 0)
        ApplyEffectToObject(DURATION_TYPE_PERMANENT,
            TagEffect(EffectSkillIncrease(nBonSk, nBonSkV), nTag), oPC);

    if(nBonSv >= 0 && nBonSvV > 0)
        ApplyEffectToObject(DURATION_TYPE_PERMANENT,
            TagEffect(EffectSavingThrowIncrease(nBonSv, nBonSvV), nTag), oPC);

    if(nBonRs > 0)
        ApplyEffectToObject(DURATION_TYPE_PERMANENT,
            TagEffect(EffectDamageResistance(DAMAGE_TYPE_FIRE, nBonRs, 0), nTag), oPC);

    if(bCursed)
    {
        if(nCurAb > 0)
            ApplyEffectToObject(DURATION_TYPE_PERMANENT,
                TagEffect(EffectAttackDecrease(nCurAb), nTag), oPC);

        if(nCurSv > 0)
            ApplyEffectToObject(DURATION_TYPE_PERMANENT,
                TagEffect(EffectSavingThrowDecrease(SAVING_THROW_ALL, nCurSv), nTag), oPC);

        if(nCurCha > 0)
            ApplyEffectToObject(DURATION_TYPE_PERMANENT,
                TagEffect(EffectAbilityDecrease(ABILITY_CHARISMA, nCurCha), nTag), oPC);
    }
}

void TatuApplyEffectsForPC(object oPC)
{
    json jTattoos = TatuGetPCTattoos(oPC);
    int nCount    = JsonGetLength(jTattoos);
    int i;
    for(i = 0; i < nCount; i++)
    {
        json jT     = JsonArrayGet(jTattoos, i);
        int nDesId  = JsonGetInt   (JsonObjectGet(jT, "design_id"));
        string sSlot= JsonGetString(JsonObjectGet(jT, "slot"));
        int nSlotIdx= TatuGetSlotIndex(sSlot);
        if(nSlotIdx < 0) continue;

        json jDesign = TatuGetDesignById(nDesId);
        if(JsonGetType(jDesign) == JSON_TYPE_NULL) continue;

        TatuRemoveEffectsForSlot(oPC, nSlotIdx);
        TatuApplyDesignEffects(oPC, jDesign, nSlotIdx);
    }
}

// ----------------------------------------------------------------
// NUI — slot button helper
// ----------------------------------------------------------------

json TatuMakeSlotButton(object oPC, int nIdx, float fWidth)
{
    float fH  = GetNuiScaleDimension(oPC, TATU_BTN_H);
    float fW  = GetNuiScaleDimension(oPC, fWidth);
    string sId  = TATU_BTN_SLOT + "_" + IntToString(nIdx);
    string sLbl = TATU_BIND_SLOT_LBL + "_" + IntToString(nIdx);
    string sEnc = TATU_BIND_SLOT_ENC + "_" + IntToString(nIdx);

    json jBtn = NuiButton(NuiBind(sLbl));
    jBtn = NuiId(jBtn, sId);
    jBtn = NuiEncouraged(jBtn, NuiBind(sEnc));
    jBtn = NuiWidth(jBtn, fW);
    jBtn = NuiHeight(jBtn, fH);
    return jBtn;
}

// ----------------------------------------------------------------
// NUI — Body map panel
// ----------------------------------------------------------------

json BuildTatuBodyMap(object oPC)
{
    float fH = GetNuiScaleDimension(oPC, TATU_MAP_H);

    // Header
    json jHdr = NuiLabel(JsonString("— Mapa Ciała —"),
        JsonInt(NUI_HALIGN_CENTER), JsonInt(NUI_VALIGN_MIDDLE));
    jHdr = NuiHeight(jHdr, GetNuiScaleDimension(oPC, 22.0));

    // HEAD (centered row)
    json jRowHead = JsonArray();
    jRowHead = JsonArrayInsert(jRowHead, NuiSpacer());
    jRowHead = JsonArrayInsert(jRowHead, TatuMakeSlotButton(oPC, 0, TATU_SLOT_BTN_W));
    jRowHead = JsonArrayInsert(jRowHead, NuiSpacer());

    // NECK (centered row)
    json jRowNeck = JsonArray();
    jRowNeck = JsonArrayInsert(jRowNeck, NuiSpacer());
    jRowNeck = JsonArrayInsert(jRowNeck, TatuMakeSlotButton(oPC, 1, TATU_SLOT_BTN_W));
    jRowNeck = JsonArrayInsert(jRowNeck, NuiSpacer());

    // CHEST (centered row)
    json jRowChest = JsonArray();
    jRowChest = JsonArrayInsert(jRowChest, NuiSpacer());
    jRowChest = JsonArrayInsert(jRowChest, TatuMakeSlotButton(oPC, 2, TATU_SLOT_BTN_W));
    jRowChest = JsonArrayInsert(jRowChest, NuiSpacer());

    // LEFT + RIGHT arms (side by side)
    json jRowArms = JsonArray();
    jRowArms = JsonArrayInsert(jRowArms, TatuMakeSlotButton(oPC, 3, TATU_SLOT_ARM_W));
    jRowArms = JsonArrayInsert(jRowArms, NuiSpacer());
    jRowArms = JsonArrayInsert(jRowArms, TatuMakeSlotButton(oPC, 4, TATU_SLOT_ARM_W));

    json jCol = JsonArray();
    jCol = JsonArrayInsert(jCol, jHdr);
    jCol = JsonArrayInsert(jCol, NuiRow(jRowHead));
    jCol = JsonArrayInsert(jCol, NuiRow(jRowNeck));
    jCol = JsonArrayInsert(jCol, NuiRow(jRowChest));
    jCol = JsonArrayInsert(jCol, NuiRow(jRowArms));

    json jGrp = NuiGroup(NuiCol(jCol), TRUE, NUI_SCROLLBARS_NONE);
    jGrp = NuiHeight(jGrp, fH);
    return jGrp;
}

// ----------------------------------------------------------------
// NUI — Design list panel
// ----------------------------------------------------------------

json BuildTatuDesignList(object oPC)
{
    float fRowH  = GetNuiScaleDimension(oPC, TATU_ROW_H);
    float fSlotW = GetNuiScaleDimension(oPC, 80.0);

    json jNameLbl = NuiLabel(NuiBind(TATU_BIND_LIST_NAME),
        JsonInt(NUI_HALIGN_LEFT), JsonInt(NUI_VALIGN_MIDDLE));
    jNameLbl = NuiStyleForegroundColor(jNameLbl, NuiBind(TATU_BIND_LIST_COLOR));

    json jSlotLbl = NuiLabel(NuiBind(TATU_BIND_LIST_SLOT),
        JsonInt(NUI_HALIGN_RIGHT), JsonInt(NUI_VALIGN_MIDDLE));
    jSlotLbl = NuiStyleForegroundColor(jSlotLbl, NuiBind(TATU_BIND_LIST_COLOR));
    jSlotLbl = NuiWidth(jSlotLbl, fSlotW);

    json jCellRow = JsonArray();
    jCellRow = JsonArrayInsert(jCellRow, jNameLbl);
    jCellRow = JsonArrayInsert(jCellRow, jSlotLbl);

    json jCell = NuiGroup(NuiRow(jCellRow), TRUE, NUI_SCROLLBARS_NONE);
    jCell = NuiId(jCell, TATU_BTN_ROW);
    jCell = NuiEncouraged(jCell, NuiBind(TATU_BIND_LIST_ENC));

    json jTmpl = JsonArrayInsert(JsonArray(),
        NuiListTemplateCell(jCell, 0.0, TRUE));

    json jList = NuiList(jTmpl, NuiBind(TATU_BIND_LIST_COUNT), fRowH);
    return jList;
}

// ----------------------------------------------------------------
// NUI — Detail panel
// ----------------------------------------------------------------

json BuildTatuDetailPanel(object oPC)
{
    float fH      = GetNuiScaleDimension(oPC, TATU_DETAIL_H);
    float fBtnH   = GetNuiScaleDimension(oPC, TATU_BTN_H);
    float fBtnW   = GetNuiScaleDimension(oPC, 160.0);
    float fDescH  = GetNuiScaleDimension(oPC, 60.0);

    json jName = NuiLabel(NuiBind(TATU_BIND_DET_NAME),
        JsonInt(NUI_HALIGN_CENTER), JsonInt(NUI_VALIGN_MIDDLE));
    jName = NuiHeight(jName, GetNuiScaleDimension(oPC, 24.0));

    json jDesc = NuiGroup(NuiText(NuiBind(TATU_BIND_DET_DESC), FALSE),
        FALSE, NUI_SCROLLBARS_NONE);
    jDesc = NuiHeight(jDesc, fDescH);

    json jEffect = NuiLabel(NuiBind(TATU_BIND_DET_EFFECT),
        JsonInt(NUI_HALIGN_LEFT), JsonInt(NUI_VALIGN_MIDDLE));
    jEffect = NuiHeight(jEffect, GetNuiScaleDimension(oPC, 22.0));
    jEffect = NuiStyleForegroundColor(jEffect, NuiColor(160, 220, 160));

    json jReq = NuiLabel(NuiBind(TATU_BIND_DET_REQ),
        JsonInt(NUI_HALIGN_LEFT), JsonInt(NUI_VALIGN_MIDDLE));
    jReq = NuiHeight(jReq, GetNuiScaleDimension(oPC, 22.0));
    jReq = NuiStyleForegroundColor(jReq, NuiColor(220, 200, 120));

    json jCurse = NuiLabel(NuiBind(TATU_BIND_DET_CURSE),
        JsonInt(NUI_HALIGN_LEFT), JsonInt(NUI_VALIGN_MIDDLE));
    jCurse = NuiHeight(jCurse, GetNuiScaleDimension(oPC, 22.0));
    jCurse = NuiStyleForegroundColor(jCurse, NuiColor(220, 100, 100));

    json jApplyBtn = NuiButton(NuiBind(TATU_BIND_APPLY_LBL));
    jApplyBtn = NuiId(jApplyBtn, TATU_BTN_APPLY);
    jApplyBtn = NuiEnabled(jApplyBtn, NuiBind(TATU_BIND_APPLY_ENA));
    jApplyBtn = NuiWidth(jApplyBtn, fBtnW);
    jApplyBtn = NuiHeight(jApplyBtn, fBtnH);

    json jRemoveBtn = NuiButton(JsonString("Wypal Tatuaż"));
    jRemoveBtn = NuiId(jRemoveBtn, TATU_BTN_REMOVE);
    jRemoveBtn = NuiEnabled(jRemoveBtn, NuiBind(TATU_BIND_REMOVE_ENA));
    jRemoveBtn = NuiWidth(jRemoveBtn, fBtnW);
    jRemoveBtn = NuiHeight(jRemoveBtn, fBtnH);

    json jBtnRow = JsonArray();
    jBtnRow = JsonArrayInsert(jBtnRow, NuiSpacer());
    jBtnRow = JsonArrayInsert(jBtnRow, jApplyBtn);
    jBtnRow = JsonArrayInsert(jBtnRow, NuiSpacer());
    jBtnRow = JsonArrayInsert(jBtnRow, jRemoveBtn);
    jBtnRow = JsonArrayInsert(jBtnRow, NuiSpacer());

    json jCol = JsonArray();
    jCol = JsonArrayInsert(jCol, jName);
    jCol = JsonArrayInsert(jCol, jDesc);
    jCol = JsonArrayInsert(jCol, jEffect);
    jCol = JsonArrayInsert(jCol, jReq);
    jCol = JsonArrayInsert(jCol, jCurse);
    jCol = JsonArrayInsert(jCol, NuiSpacer());
    jCol = JsonArrayInsert(jCol, NuiRow(jBtnRow));

    json jGrp = NuiGroup(NuiCol(jCol), TRUE, NUI_SCROLLBARS_NONE);
    jGrp = NuiHeight(jGrp, fH);
    return jGrp;
}

// ----------------------------------------------------------------
// NUI — Window creation
// ----------------------------------------------------------------

void TatuOpenWindow(object oPC)
{
    if(NuiFindWindow(oPC, TATU_WINDOW) != 0)
    {
        TatuRefreshAll(oPC, NuiFindWindow(oPC, TATU_WINDOW));
        return;
    }

    float fCX = (IntToFloat(GetPlayerDeviceProperty(oPC, PLAYER_DEVICE_PROPERTY_GUI_WIDTH))
        - GetNuiScaleDimension(oPC, TATU_W)) / 2.0;
    float fCY = (IntToFloat(GetPlayerDeviceProperty(oPC, PLAYER_DEVICE_PROPERTY_GUI_HEIGHT))
        - GetNuiScaleDimension(oPC, TATU_H)) / 2.0;
    json jGeom = NuiRect(fCX, fCY,
        GetNuiScaleDimension(oPC, TATU_W),
        GetNuiScaleDimension(oPC, TATU_H));

    // Top bar: title label + close button
    float fBtnH = GetNuiScaleDimension(oPC, TATU_BTN_H);

    json jTitleLbl = NuiLabel(JsonString("Pracownia Tatuaży Magicznych"),
        JsonInt(NUI_HALIGN_LEFT), JsonInt(NUI_VALIGN_MIDDLE));
    jTitleLbl = NuiStyleForegroundColor(jTitleLbl, NuiColor(200, 170, 100));

    json jCloseBtn = NuiButton(JsonString("X"));
    jCloseBtn = NuiId(jCloseBtn, TATU_BTN_CLOSE);
    jCloseBtn = NuiWidth(jCloseBtn, GetNuiScaleDimension(oPC, 30.0));
    jCloseBtn = NuiHeight(jCloseBtn, fBtnH);

    json jTopRow = JsonArray();
    jTopRow = JsonArrayInsert(jTopRow, jTitleLbl);
    jTopRow = JsonArrayInsert(jTopRow, NuiSpacer());
    jTopRow = JsonArrayInsert(jTopRow, jCloseBtn);

    // Left column: design list
    float fListW = GetNuiScaleDimension(oPC, TATU_LIST_W);
    json jListHdr = NuiLabel(JsonString("Dostępne Wzory"),
        JsonInt(NUI_HALIGN_CENTER), JsonInt(NUI_VALIGN_MIDDLE));
    jListHdr = NuiHeight(jListHdr, GetNuiScaleDimension(oPC, 22.0));
    jListHdr = NuiStyleForegroundColor(jListHdr, NuiColor(200, 170, 100));

    json jLeftCol = JsonArray();
    jLeftCol = JsonArrayInsert(jLeftCol, jListHdr);
    jLeftCol = JsonArrayInsert(jLeftCol, BuildTatuDesignList(oPC));

    json jLeft = NuiWidth(NuiCol(jLeftCol), fListW);

    // Right column: body map + detail panel
    json jRightCol = JsonArray();
    jRightCol = JsonArrayInsert(jRightCol, BuildTatuBodyMap(oPC));
    jRightCol = JsonArrayInsert(jRightCol, BuildTatuDetailPanel(oPC));

    json jRight = NuiCol(jRightCol);

    // Main content row
    json jContentRow = JsonArray();
    jContentRow = JsonArrayInsert(jContentRow, jLeft);
    jContentRow = JsonArrayInsert(jContentRow, NuiSpacer());
    jContentRow = JsonArrayInsert(jContentRow, jRight);

    // Root
    json jRoot = JsonArray();
    jRoot = JsonArrayInsert(jRoot, NuiRow(jTopRow));
    jRoot = JsonArrayInsert(jRoot, NuiRow(jContentRow));

    json jWin = NuiWindow(NuiCol(jRoot),
        JsonBool(FALSE),
        NuiBind(TATU_WIN_GEOM),
        JsonBool(FALSE),
        JsonBool(FALSE),
        JsonBool(FALSE),
        JsonBool(TRUE),
        JsonBool(FALSE));

    // Initialize selection state
    SetLocalInt(oPC, TATU_LVAR_SEL_DESIGN, 0);
    SetLocalInt(oPC, TATU_LVAR_SEL_SLOT,   -1);

    int nToken = NuiCreate(oPC, jWin, TATU_WINDOW, TATU_EV_SCRIPT);
    NuiSetBind(oPC, nToken, TATU_WIN_GEOM, jGeom);

    json jDesigns = TatuGetAllDesigns();
    json jTattoos = TatuGetPCTattoos(oPC);
    FeedTatuDesignList(oPC, nToken, jDesigns, jTattoos);
    FeedTatuBodyMap(oPC, nToken, jTattoos);
    FeedTatuDetail(oPC, nToken, jDesigns, jTattoos);
}

// ----------------------------------------------------------------
// Feed — Design list
// ----------------------------------------------------------------

void FeedTatuDesignList(object oPC, int nToken, json jDesigns, json jTattoos)
{
    int nCount = JsonGetLength(jDesigns);
    int nSelId = GetLocalInt(oPC, TATU_LVAR_SEL_DESIGN);

    json jNames  = JsonArray();
    json jSlots  = JsonArray();
    json jColors = JsonArray();
    json jEncs   = JsonArray();

    json jWhite   = NuiColor(255, 255, 255);
    json jCursed  = NuiColor(220, 120, 120);  // cursed designs in red tint
    json jApplied = NuiColor(160, 220, 160);  // already applied in green tint

    int i;
    for(i = 0; i < nCount; i++)
    {
        json jD      = JsonArrayGet(jDesigns, i);
        int nId      = JsonGetInt   (JsonObjectGet(jD, "id"));
        string sName = JsonGetString(JsonObjectGet(jD, "name"));
        string sSlot = JsonGetString(JsonObjectGet(jD, "slot"));
        int bCursed  = JsonGetInt   (JsonObjectGet(jD, "is_cursed"));
        int nSlotIdx = TatuGetSlotIndex(sSlot);

        int bApplied = (TatuFindTattooInSlot(jTattoos, sSlot) == nId);

        json jColor = jWhite;
        if(bApplied) jColor = jApplied;
        else if(bCursed) jColor = jCursed;

        string sSlotLbl = TatuGetSlotLabel(nSlotIdx);
        if(bApplied) sSlotLbl = "[noszony]";

        jNames  = JsonArrayInsert(jNames,  JsonString(sName));
        jSlots  = JsonArrayInsert(jSlots,  JsonString(sSlotLbl));
        jColors = JsonArrayInsert(jColors, jColor);
        jEncs   = JsonArrayInsert(jEncs,   JsonBool(nSelId == nId));
    }

    NuiSetBind(oPC, nToken, TATU_BIND_LIST_NAME,  jNames);
    NuiSetBind(oPC, nToken, TATU_BIND_LIST_SLOT,  jSlots);
    NuiSetBind(oPC, nToken, TATU_BIND_LIST_COLOR, jColors);
    NuiSetBind(oPC, nToken, TATU_BIND_LIST_ENC,   jEncs);
    NuiSetBind(oPC, nToken, TATU_BIND_LIST_COUNT, JsonInt(nCount));
}

// ----------------------------------------------------------------
// Feed — Body map
// ----------------------------------------------------------------

void FeedTatuBodyMap(object oPC, int nToken, json jTattoos)
{
    int nSelSlot = GetLocalInt(oPC, TATU_LVAR_SEL_SLOT);
    int i;
    for(i = 0; i < TATU_SLOT_COUNT; i++)
    {
        string sSlot    = TatuGetSlotName(i);
        string sSlotLbl = TatuGetSlotLabel(i);
        int nDesignId   = TatuFindTattooInSlot(jTattoos, sSlot);

        string sLbl;
        if(nDesignId > 0)
        {
            json jD   = TatuGetDesignById(nDesignId);
            string sN = JsonGetString(JsonObjectGet(jD, "name"));
            sLbl = sN;
        }
        else
        {
            sLbl = "— " + sSlotLbl + " —";
        }

        NuiSetBind(oPC, nToken,
            TATU_BIND_SLOT_LBL + "_" + IntToString(i),
            JsonString(sLbl));
        NuiSetBind(oPC, nToken,
            TATU_BIND_SLOT_ENC + "_" + IntToString(i),
            JsonBool(nSelSlot == i));
    }
}

// ----------------------------------------------------------------
// Feed — Detail panel
// ----------------------------------------------------------------

void FeedTatuDetailEmpty(object oPC, int nToken, string sMsg)
{
    NuiSetBind(oPC, nToken, TATU_BIND_DET_NAME,   JsonString(sMsg));
    NuiSetBind(oPC, nToken, TATU_BIND_DET_DESC,   JsonString(""));
    NuiSetBind(oPC, nToken, TATU_BIND_DET_EFFECT, JsonString(""));
    NuiSetBind(oPC, nToken, TATU_BIND_DET_REQ,    JsonString(""));
    NuiSetBind(oPC, nToken, TATU_BIND_DET_CURSE,  JsonString(""));
    NuiSetBind(oPC, nToken, TATU_BIND_APPLY_ENA,  JsonBool(FALSE));
    NuiSetBind(oPC, nToken, TATU_BIND_APPLY_LBL,  JsonString("Natnij"));
    NuiSetBind(oPC, nToken, TATU_BIND_REMOVE_ENA, JsonBool(FALSE));
}

void FeedTatuDetailDesign(object oPC, int nToken, json jDesign, int bSlotMode)
{
    string sName    = JsonGetString(JsonObjectGet(jDesign, "name"));
    string sDesc    = JsonGetString(JsonObjectGet(jDesign, "description"));
    string sSlot    = JsonGetString(JsonObjectGet(jDesign, "slot"));
    int nCostGold   = JsonGetInt   (JsonObjectGet(jDesign, "cost_gold"));
    string sCostItem= JsonGetString(JsonObjectGet(jDesign, "cost_item"));
    int nIsCursed   = JsonGetInt   (JsonObjectGet(jDesign, "is_cursed"));

    string sEffect  = TatuBuildEffectText(jDesign);
    string sCurse   = TatuBuildCurseText(jDesign);

    string sReq = IntToString(nCostGold) + " zł";
    if(sCostItem != "")
        sReq = sReq + " + " + TatuInkName(sCostItem);

    string sCurseLabel = "";
    if(nIsCursed && sCurse != "")
        sCurseLabel = "Przekleństwo: " + sCurse;

    NuiSetBind(oPC, nToken, TATU_BIND_DET_NAME,   JsonString(sName));
    NuiSetBind(oPC, nToken, TATU_BIND_DET_DESC,   JsonString(sDesc));
    NuiSetBind(oPC, nToken, TATU_BIND_DET_EFFECT, JsonString("Efekt: " + sEffect));
    NuiSetBind(oPC, nToken, TATU_BIND_DET_CURSE,  JsonString(sCurseLabel));

    if(bSlotMode)
    {
        // Viewing the applied tattoo from body map slot click → show Remove
        string sRemoveHint = "Usunięcie: " + IntToString(TATU_REMOVE_GOLD)
            + " zł + " + IntToString(TATU_REMOVE_DMG) + " obrażeń";
        NuiSetBind(oPC, nToken, TATU_BIND_DET_REQ,    JsonString(sRemoveHint));
        NuiSetBind(oPC, nToken, TATU_BIND_APPLY_ENA,  JsonBool(FALSE));
        NuiSetBind(oPC, nToken, TATU_BIND_APPLY_LBL,  JsonString("Natnij"));
        NuiSetBind(oPC, nToken, TATU_BIND_REMOVE_ENA, JsonBool(TRUE));
        return;
    }

    // Viewing from design list → check whether we can apply
    NuiSetBind(oPC, nToken, TATU_BIND_DET_REQ, JsonString("Koszt: " + sReq));

    int nCurrentInSlot = TatuGetPCTattooDesignInSlot(oPC, sSlot);
    int bSlotEmpty     = (nCurrentInSlot == 0);
    int bHasGold       = (GetGold(oPC) >= nCostGold);
    int bHasItem       = TRUE;
    if(sCostItem != "")
        bHasItem = GetIsObjectValid(GetItemPossessedBy(oPC, sCostItem));

    int bCanApply = bSlotEmpty && bHasGold && bHasItem;

    string sApplyLbl = "Natnij";
    if(!bSlotEmpty)
        sApplyLbl = "Miejsce zajęte";
    else if(!bHasGold)
        sApplyLbl = "Brak złota";
    else if(!bHasItem)
        sApplyLbl = "Brak atrtamentu";

    NuiSetBind(oPC, nToken, TATU_BIND_APPLY_ENA,  JsonBool(bCanApply));
    NuiSetBind(oPC, nToken, TATU_BIND_APPLY_LBL,  JsonString(sApplyLbl));
    NuiSetBind(oPC, nToken, TATU_BIND_REMOVE_ENA, JsonBool(FALSE));
}

void FeedTatuDetail(object oPC, int nToken, json jDesigns, json jTattoos)
{
    int nSelDesign = GetLocalInt(oPC, TATU_LVAR_SEL_DESIGN);
    int nSelSlot   = GetLocalInt(oPC, TATU_LVAR_SEL_SLOT);

    if(nSelDesign <= 0 && nSelSlot < 0)
    {
        FeedTatuDetailEmpty(oPC, nToken, "Wybierz wzór lub miejsce na ciele.");
        return;
    }

    if(nSelDesign > 0)
    {
        json jD = TatuFindDesignById(jDesigns, nSelDesign);
        if(JsonGetType(jD) == JSON_TYPE_NULL)
        {
            FeedTatuDetailEmpty(oPC, nToken, "Nieznany wzór.");
            return;
        }
        FeedTatuDetailDesign(oPC, nToken, jD, FALSE);
        return;
    }

    // Slot selected from body map
    if(nSelSlot >= 0)
    {
        string sSlot  = TatuGetSlotName(nSelSlot);
        int nDesignId = TatuFindTattooInSlot(jTattoos, sSlot);

        if(nDesignId == 0)
        {
            FeedTatuDetailEmpty(oPC, nToken,
                "— " + TatuGetSlotLabel(nSelSlot) + " —  (puste)");
            return;
        }

        json jD = TatuFindDesignById(jDesigns, nDesignId);
        if(JsonGetType(jD) == JSON_TYPE_NULL)
        {
            FeedTatuDetailEmpty(oPC, nToken, "Błąd danych tatuażu.");
            return;
        }
        FeedTatuDetailDesign(oPC, nToken, jD, TRUE);
    }
}

// ----------------------------------------------------------------
// Refresh helper
// ----------------------------------------------------------------

void TatuRefreshAll(object oPC, int nToken)
{
    json jDesigns = TatuGetAllDesigns();
    json jTattoos = TatuGetPCTattoos(oPC);
    FeedTatuDesignList(oPC, nToken, jDesigns, jTattoos);
    FeedTatuBodyMap(oPC, nToken, jTattoos);
    FeedTatuDetail(oPC, nToken, jDesigns, jTattoos);
}

// ----------------------------------------------------------------
// Apply / Remove logic
// ----------------------------------------------------------------

void TatuDoApply(object oPC, int nToken)
{
    int nSelDesign = GetLocalInt(oPC, TATU_LVAR_SEL_DESIGN);
    if(nSelDesign <= 0) return;

    json jDesigns = TatuGetAllDesigns();
    json jDesign  = TatuFindDesignById(jDesigns, nSelDesign);
    if(JsonGetType(jDesign) == JSON_TYPE_NULL) return;

    string sSlot     = JsonGetString(JsonObjectGet(jDesign, "slot"));
    int nCostGold    = JsonGetInt   (JsonObjectGet(jDesign, "cost_gold"));
    string sCostItem = JsonGetString(JsonObjectGet(jDesign, "cost_item"));
    int nSlotIdx     = TatuGetSlotIndex(sSlot);
    string sName     = JsonGetString(JsonObjectGet(jDesign, "name"));
    int nIsCursed    = JsonGetInt   (JsonObjectGet(jDesign, "is_cursed"));

    if(TatuGetPCTattooDesignInSlot(oPC, sSlot) != 0)
    {
        SendMessageToPC(oPC, "[Tatuaże] To miejsce jest już zajęte innym tatuażem.");
        return;
    }

    if(GetGold(oPC) < nCostGold)
    {
        SendMessageToPC(oPC, "[Tatuaże] Potrzebujesz " + IntToString(nCostGold) + " złota.");
        return;
    }

    object oInk = OBJECT_INVALID;
    if(sCostItem != "")
    {
        oInk = GetItemPossessedBy(oPC, sCostItem);
        if(!GetIsObjectValid(oInk))
        {
            SendMessageToPC(oPC, "[Tatuaże] Brakuje składnika: "
                + TatuInkName(sCostItem) + ".");
            return;
        }
    }

    AssignCommand(oPC, TakeGoldFromCreature(nCostGold, oPC, TRUE));
    if(GetIsObjectValid(oInk))
        DestroyObject(oInk);

    TatuApplyTattoo(oPC, nSelDesign, sSlot);
    TatuRemoveEffectsForSlot(oPC, nSlotIdx);
    TatuApplyDesignEffects(oPC, jDesign, nSlotIdx);

    SetLocalInt(oPC, TATU_LVAR_SEL_DESIGN, 0);

    SendMessageToPC(oPC, "[Tatuaże] Tatuaż \"" + sName
        + "\" wyryty w twoją skórę. Pieczęć pulsuje.");
    if(nIsCursed)
        SendMessageToPC(oPC,
            "[Tatuaże] Poczułeś ciemną moc przekleństwa wnikającą w krew — "
            "lecz moc sama w sobie jest niepodzielna.");

    TatuRefreshAll(oPC, nToken);
}

void TatuDoRemove(object oPC, int nToken)
{
    int nSelSlot = GetLocalInt(oPC, TATU_LVAR_SEL_SLOT);
    if(nSelSlot < 0) return;

    string sSlot  = TatuGetSlotName(nSelSlot);
    int nDesignId = TatuGetPCTattooDesignInSlot(oPC, sSlot);
    if(nDesignId == 0)
    {
        SendMessageToPC(oPC, "[Tatuaże] To miejsce nie ma tatuażu.");
        return;
    }

    if(GetGold(oPC) < TATU_REMOVE_GOLD)
    {
        SendMessageToPC(oPC,
            "[Tatuaże] Wypalenie tatuażu kosztuje "
            + IntToString(TATU_REMOVE_GOLD) + " złota.");
        return;
    }

    AssignCommand(oPC, TakeGoldFromCreature(TATU_REMOVE_GOLD, oPC, TRUE));
    ApplyEffectToObject(DURATION_TYPE_INSTANT,
        EffectDamage(TATU_REMOVE_DMG, DAMAGE_TYPE_MAGICAL), oPC);

    TatuRemoveTattoo(oPC, sSlot);
    TatuRemoveEffectsForSlot(oPC, nSelSlot);

    SetLocalInt(oPC, TATU_LVAR_SEL_SLOT, -1);

    SendMessageToPC(oPC,
        "[Tatuaże] Tatuaż z " + TatuGetSlotLabel(nSelSlot)
        + " boleśnie wypalony rozżarzonym żelazem. "
        + "Smród spalonej skóry unosi się w powietrzu.");

    TatuRefreshAll(oPC, nToken);
}
