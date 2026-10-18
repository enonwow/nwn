#include "lib_fcraft_def"
#include "sql_fcraft"

// Searches PC inventory for an item by resref (tags may differ from resrefs)
object FcraftFindComp(object oPC, string sResRef)
{
    object oItem = GetFirstItemInInventory(oPC);
    while(GetIsObjectValid(oItem))
    {
        if(GetResRef(oItem) == sResRef) return oItem;
        oItem = GetNextItemInInventory(oPC);
    }
    return OBJECT_INVALID;
}

void FcraftOpen(object oPC);
void FcraftFeedCatalog(object oPC, int nToken);
void FcraftFeedDetail(object oPC, int nToken, int nIdx);
void FcraftFeedActive(object oPC, int nToken);
void FcraftFeedActiveDetail(object oPC, int nToken, int nIdx);
void FcraftApplyMod(object oPC, string sModId);
void FcraftRemoveMod(object oPC, string sModId);
void FcraftStripEffects(object oPC, string sModId);
void FcraftReapplyAll(object oPC);

// ----------------------------------------------------------------
// NUI window construction
// ----------------------------------------------------------------

json FcraftBuildCatalogTab(object oPC)
{
    float fRowH = GetNuiScaleDimension(oPC, 28.0);
    float fNameW = GetNuiScaleDimension(oPC, 200.0);
    float fCostW = GetNuiScaleDimension(oPC, 80.0);

    json jNameLbl = NuiLabel(NuiBind(FCRAFT_BIND_CAT_NAME),
        JsonInt(NUI_HALIGN_LEFT), JsonInt(NUI_VALIGN_MIDDLE));

    json jCostLbl = NuiLabel(NuiBind(FCRAFT_BIND_CAT_COST),
        JsonInt(NUI_HALIGN_RIGHT), JsonInt(NUI_VALIGN_MIDDLE));
    jCostLbl = NuiWidth(jCostLbl, fCostW);

    json jRow = NuiRow(JsonArrayInsert(JsonArrayInsert(JsonArray(), jNameLbl), jCostLbl));
    jRow = NuiId(jRow, FCRAFT_BTN_CAT_ROW);
    jRow = NuiEncouraged(jRow, NuiBind(FCRAFT_BIND_CAT_ENC));
    jRow = NuiHeight(jRow, fRowH);

    json jList = NuiList(jRow, JsonInt(FCRAFT_MOD_COUNT), fRowH);

    // Detail panel on the right
    float fLblH = GetNuiScaleDimension(oPC, 24.0);
    float fFlvH = GetNuiScaleDimension(oPC, 90.0);
    float fBtnH = GetNuiScaleDimension(oPC, 32.0);
    float fDetW = GetNuiScaleDimension(oPC, 340.0);

    json jTitle = NuiLabel(NuiBind(FCRAFT_BIND_DET_TITLE),
        JsonInt(NUI_HALIGN_LEFT), JsonInt(NUI_VALIGN_MIDDLE));
    jTitle = NuiHeight(jTitle, fLblH);

    json jFlavor = NuiText(NuiBind(FCRAFT_BIND_DET_FLAVOR), FALSE);
    jFlavor = NuiHeight(jFlavor, fFlvH);

    json jEffect = NuiLabel(NuiBind(FCRAFT_BIND_DET_EFFECT),
        JsonInt(NUI_HALIGN_LEFT), JsonInt(NUI_VALIGN_MIDDLE));
    jEffect = NuiHeight(jEffect, fLblH);

    json jCostLbl2 = NuiLabel(NuiBind(FCRAFT_BIND_DET_COST),
        JsonInt(NUI_HALIGN_LEFT), JsonInt(NUI_VALIGN_MIDDLE));
    jCostLbl2 = NuiHeight(jCostLbl2, fLblH);

    json jCompLbl = NuiLabel(NuiBind(FCRAFT_BIND_DET_COMP),
        JsonInt(NUI_HALIGN_LEFT), JsonInt(NUI_VALIGN_MIDDLE));
    jCompLbl = NuiHeight(jCompLbl, fLblH);

    json jImplBtn = NuiButton(NuiBind(FCRAFT_BIND_IMPL_LBL));
    jImplBtn = NuiId(jImplBtn, FCRAFT_BTN_IMPLANT);
    jImplBtn = NuiEnabled(jImplBtn, NuiBind(FCRAFT_BIND_IMPL_ENA));
    jImplBtn = NuiHeight(jImplBtn, fBtnH);

    json jDetailItems = JsonArray();
    jDetailItems = JsonArrayInsert(jDetailItems, jTitle);
    jDetailItems = JsonArrayInsert(jDetailItems, jFlavor);
    jDetailItems = JsonArrayInsert(jDetailItems, jEffect);
    jDetailItems = JsonArrayInsert(jDetailItems, jCostLbl2);
    jDetailItems = JsonArrayInsert(jDetailItems, jCompLbl);
    jDetailItems = JsonArrayInsert(jDetailItems, jImplBtn);

    json jDetail = NuiCol(jDetailItems);
    jDetail = NuiWidth(jDetail, fDetW);

    json jSplit = NuiRow(JsonArrayInsert(JsonArrayInsert(JsonArray(), jList), jDetail));
    return jSplit;
}

json FcraftBuildActiveTab(object oPC)
{
    float fRowH = GetNuiScaleDimension(oPC, 28.0);
    float fNameW = GetNuiScaleDimension(oPC, 180.0);

    json jNameLbl = NuiLabel(NuiBind(FCRAFT_BIND_ACT_NAME),
        JsonInt(NUI_HALIGN_LEFT), JsonInt(NUI_VALIGN_MIDDLE));
    jNameLbl = NuiWidth(jNameLbl, fNameW);

    json jEffLbl = NuiLabel(NuiBind(FCRAFT_BIND_ACT_EFF),
        JsonInt(NUI_HALIGN_LEFT), JsonInt(NUI_VALIGN_MIDDLE));

    json jRow = NuiRow(JsonArrayInsert(JsonArrayInsert(JsonArray(), jNameLbl), jEffLbl));
    jRow = NuiId(jRow, FCRAFT_BTN_ACT_ROW);
    jRow = NuiEncouraged(jRow, NuiBind(FCRAFT_BIND_ACT_ENC));
    jRow = NuiHeight(jRow, fRowH);

    json jList = NuiList(jRow, JsonInt(FCRAFT_MAX_MODS), fRowH);

    float fBtnH = GetNuiScaleDimension(oPC, 32.0);
    float fLblH = GetNuiScaleDimension(oPC, 24.0);
    float fDetW = GetNuiScaleDimension(oPC, 300.0);

    json jUseBtn = NuiButton(JsonString("Użyj Zdolności"));
    jUseBtn = NuiId(jUseBtn, FCRAFT_BTN_USE);
    jUseBtn = NuiEnabled(jUseBtn, NuiBind(FCRAFT_BIND_USE_ENA));
    jUseBtn = NuiVisible(jUseBtn, NuiBind(FCRAFT_BIND_USE_VIS));
    jUseBtn = NuiHeight(jUseBtn, fBtnH);

    json jCoolLbl = NuiLabel(NuiBind(FCRAFT_BIND_USE_COOL),
        JsonInt(NUI_HALIGN_LEFT), JsonInt(NUI_VALIGN_MIDDLE));
    jCoolLbl = NuiHeight(jCoolLbl, fLblH);

    json jRemBtn = NuiButton(JsonString("Usuń modyfikację"));
    jRemBtn = NuiId(jRemBtn, FCRAFT_BTN_REMOVE);
    jRemBtn = NuiEnabled(jRemBtn, NuiBind(FCRAFT_BIND_REM_ENA));
    jRemBtn = NuiHeight(jRemBtn, fBtnH);

    json jRemCost = NuiLabel(NuiBind(FCRAFT_BIND_REM_COST),
        JsonInt(NUI_HALIGN_LEFT), JsonInt(NUI_VALIGN_MIDDLE));
    jRemCost = NuiHeight(jRemCost, fLblH);

    json jDetailItems = JsonArray();
    jDetailItems = JsonArrayInsert(jDetailItems, jUseBtn);
    jDetailItems = JsonArrayInsert(jDetailItems, jCoolLbl);
    jDetailItems = JsonArrayInsert(jDetailItems, jRemBtn);
    jDetailItems = JsonArrayInsert(jDetailItems, jRemCost);

    json jDetail = NuiCol(jDetailItems);
    jDetail = NuiWidth(jDetail, fDetW);

    json jSplit = NuiRow(JsonArrayInsert(JsonArrayInsert(JsonArray(), jList), jDetail));
    return jSplit;
}

json FcraftBuildWindow(object oPC)
{
    float fW    = GetNuiScaleDimension(oPC, FCRAFT_W);
    float fH    = GetNuiScaleDimension(oPC, FCRAFT_H);
    float fBtnH = GetNuiScaleDimension(oPC, 28.0);

    // Tab buttons
    json jTabCat = NuiButton(JsonString("Katalog Operacji"));
    jTabCat = NuiId(jTabCat, FCRAFT_BTN_TAB_CAT);
    jTabCat = NuiHeight(jTabCat, fBtnH);

    json jTabAct = NuiButton(JsonString("Twoje Modyfikacje"));
    jTabAct = NuiId(jTabAct, FCRAFT_BTN_TAB_ACT);
    jTabAct = NuiHeight(jTabAct, fBtnH);

    json jCloseBtn = NuiButton(JsonString("X"));
    jCloseBtn = NuiId(jCloseBtn, FCRAFT_BTN_CLOSE);
    jCloseBtn = NuiWidth(jCloseBtn, GetNuiScaleDimension(oPC, 28.0));
    jCloseBtn = NuiHeight(jCloseBtn, fBtnH);

    json jTopBtns = JsonArray();
    jTopBtns = JsonArrayInsert(jTopBtns, jTabCat);
    jTopBtns = JsonArrayInsert(jTopBtns, jTabAct);
    jTopBtns = JsonArrayInsert(jTopBtns, jCloseBtn);
    json jTopRow = NuiRow(jTopBtns);

    // Content group — two swap children
    json jCatContent  = FcraftBuildCatalogTab(oPC);
    json jActContent  = FcraftBuildActiveTab(oPC);

    json jSwapItems = JsonArray();
    jSwapItems = JsonArrayInsert(jSwapItems, jCatContent);
    jSwapItems = JsonArrayInsert(jSwapItems, jActContent);

    json jSwap = NuiGroup(NuiCol(jSwapItems), FALSE, NUI_SCROLLBARS_NONE);

    json jRoot = JsonArray();
    jRoot = JsonArrayInsert(jRoot, jTopRow);
    jRoot = JsonArrayInsert(jRoot, jSwap);

    json jWin = NuiWindow(
        NuiCol(jRoot),
        JsonString("Kowalnia Ciała — Rzeźbiarz Ciał"),
        NuiBind(FCRAFT_WIN_GEOM),
        JsonBool(TRUE),
        JsonBool(FALSE),
        JsonBool(TRUE),
        JsonBool(FALSE),
        JsonBool(TRUE)
    );
    return jWin;
}

// ----------------------------------------------------------------
// Open window
// ----------------------------------------------------------------

void FcraftOpen(object oPC)
{
    int nToken = NuiFindWindow(oPC, FCRAFT_WIN_MAIN);
    if(nToken != 0)
    {
        NuiSetBind(oPC, nToken, FCRAFT_WIN_GEOM,
            NuiRect(50.0, 50.0,
                GetNuiScaleDimension(oPC, FCRAFT_W),
                GetNuiScaleDimension(oPC, FCRAFT_H)));
        return;
    }

    nToken = NuiCreate(oPC, FcraftBuildWindow(oPC), FCRAFT_WIN_MAIN);
    if(nToken == 0) return;

    NuiSetBind(oPC, nToken, FCRAFT_WIN_GEOM,
        NuiRect(50.0, 50.0,
            GetNuiScaleDimension(oPC, FCRAFT_W),
            GetNuiScaleDimension(oPC, FCRAFT_H)));

    SetLocalInt(oPC, FCRAFT_LVAR_TAB, 0);
    SetLocalInt(oPC, FCRAFT_LVAR_SEL_IDX, -1);
    SetLocalInt(oPC, FCRAFT_LVAR_SEL_ACT, -1);

    FcraftFeedCatalog(oPC, nToken);
    FcraftFeedDetail(oPC, nToken, -1);
    FcraftFeedActive(oPC, nToken);
    FcraftFeedActiveDetail(oPC, nToken, -1);
}

// ----------------------------------------------------------------
// Feed functions
// ----------------------------------------------------------------

void FcraftFeedCatalog(object oPC, int nToken)
{
    json jNames  = JsonArray();
    json jCosts  = JsonArray();
    json jEncs   = JsonArray();
    json jAvails = JsonArray();

    int i;
    for(i = 0; i < FCRAFT_MOD_COUNT; i++)
    {
        string sId   = FcraftModId(i);
        string sName = FcraftModName(sId);
        int nCost    = FcraftModCost(sId);
        int bOwned   = FcraftHasMod(oPC, sId);

        jNames  = JsonArrayInsert(jNames,  JsonString(bOwned ? ("[WSZCZEPIONA] " + sName) : sName));
        jCosts  = JsonArrayInsert(jCosts,  JsonString(IntToString(nCost) + " zł"));
        jEncs   = JsonArrayInsert(jEncs,   JsonBool(FALSE));
        jAvails = JsonArrayInsert(jAvails, JsonBool(!bOwned));
    }

    NuiSetBind(oPC, nToken, FCRAFT_BIND_CAT_NAME,  jNames);
    NuiSetBind(oPC, nToken, FCRAFT_BIND_CAT_COST,  jCosts);
    NuiSetBind(oPC, nToken, FCRAFT_BIND_CAT_ENC,   jEncs);
    NuiSetBind(oPC, nToken, FCRAFT_BIND_CAT_AVAIL, jAvails);
}

void FcraftFeedDetail(object oPC, int nToken, int nIdx)
{
    if(nIdx < 0)
    {
        NuiSetBind(oPC, nToken, FCRAFT_BIND_DET_TITLE,  JsonString("— wybierz operację —"));
        NuiSetBind(oPC, nToken, FCRAFT_BIND_DET_FLAVOR, JsonString(""));
        NuiSetBind(oPC, nToken, FCRAFT_BIND_DET_EFFECT, JsonString(""));
        NuiSetBind(oPC, nToken, FCRAFT_BIND_DET_COST,   JsonString(""));
        NuiSetBind(oPC, nToken, FCRAFT_BIND_DET_COMP,   JsonString(""));
        NuiSetBind(oPC, nToken, FCRAFT_BIND_IMPL_ENA,   JsonBool(FALSE));
        NuiSetBind(oPC, nToken, FCRAFT_BIND_IMPL_LBL,   JsonString("Wszczep"));
        return;
    }

    string sId       = FcraftModId(nIdx);
    int bOwned       = FcraftHasMod(oPC, sId);
    int nCount       = FcraftGetModCount(oPC);
    string sExcl     = FcraftModExcludes(sId);
    int bExcluded    = (sExcl != "" && FcraftHasMod(oPC, sExcl));
    int nCost        = FcraftModCost(sId);
    int bCanAfford   = (GetGold(oPC) >= nCost);
    string sCompRef  = FcraftModComp(sId);
    object oComp     = FcraftFindComp(oPC, sCompRef);
    int bHasComp     = GetIsObjectValid(oComp);
    int bCanImplant  = (!bOwned && !bExcluded && nCount < FCRAFT_MAX_MODS && bCanAfford && bHasComp);

    string sImplLbl = "Wszczep (" + IntToString(nCost) + " zł + składnik)";
    if(bOwned)       sImplLbl = "Już wszczepiona";
    else if(bExcluded) sImplLbl = "Wykluczona przez inną modyfikację";
    else if(nCount >= FCRAFT_MAX_MODS) sImplLbl = "Ciało osiągnęło limit (5)";
    else if(!bCanAfford) sImplLbl = "Za mało złota";
    else if(!bHasComp)   sImplLbl = "Brakuje składnika organicznego";

    string sCompStatus = bHasComp ? "Składnik: POSIADASZ" : "Składnik: BRAKUJE (" + sCompRef + ")";

    NuiSetBind(oPC, nToken, FCRAFT_BIND_DET_TITLE,  JsonString(FcraftModName(sId)));
    NuiSetBind(oPC, nToken, FCRAFT_BIND_DET_FLAVOR, JsonString(FcraftModFlavor(sId)));
    NuiSetBind(oPC, nToken, FCRAFT_BIND_DET_EFFECT, JsonString("Efekty: " + FcraftModEffectDesc(sId)));
    NuiSetBind(oPC, nToken, FCRAFT_BIND_DET_COST,   JsonString("Koszt: " + IntToString(nCost) + " zł"));
    NuiSetBind(oPC, nToken, FCRAFT_BIND_DET_COMP,   JsonString(sCompStatus));
    NuiSetBind(oPC, nToken, FCRAFT_BIND_IMPL_ENA,   JsonBool(bCanImplant));
    NuiSetBind(oPC, nToken, FCRAFT_BIND_IMPL_LBL,   JsonString(sImplLbl));
}

void FcraftFeedActive(object oPC, int nToken)
{
    json jMods   = FcraftGetMods(oPC);
    int nCount   = JsonGetLength(jMods);
    json jNames  = JsonArray();
    json jEffs   = JsonArray();
    json jEncs   = JsonArray();

    int i;
    for(i = 0; i < nCount; i++)
    {
        string sId = JsonGetString(JsonArrayGet(jMods, i));
        jNames = JsonArrayInsert(jNames, JsonString(FcraftModName(sId)));
        jEffs  = JsonArrayInsert(jEffs,  JsonString(FcraftModEffectDesc(sId)));
        jEncs  = JsonArrayInsert(jEncs,  JsonBool(FALSE));
    }

    // Pad to FCRAFT_MAX_MODS rows so list doesn't collapse
    while(JsonGetLength(jNames) < FCRAFT_MAX_MODS)
    {
        jNames = JsonArrayInsert(jNames, JsonString("—"));
        jEffs  = JsonArrayInsert(jEffs,  JsonString(""));
        jEncs  = JsonArrayInsert(jEncs,  JsonBool(FALSE));
    }

    NuiSetBind(oPC, nToken, FCRAFT_BIND_ACT_NAME, jNames);
    NuiSetBind(oPC, nToken, FCRAFT_BIND_ACT_EFF,  jEffs);
    NuiSetBind(oPC, nToken, FCRAFT_BIND_ACT_ENC,  jEncs);
}

void FcraftFeedActiveDetail(object oPC, int nToken, int nActIdx)
{
    if(nActIdx < 0)
    {
        NuiSetBind(oPC, nToken, FCRAFT_BIND_USE_VIS,  JsonBool(FALSE));
        NuiSetBind(oPC, nToken, FCRAFT_BIND_USE_ENA,  JsonBool(FALSE));
        NuiSetBind(oPC, nToken, FCRAFT_BIND_USE_COOL, JsonString(""));
        NuiSetBind(oPC, nToken, FCRAFT_BIND_REM_ENA,  JsonBool(FALSE));
        NuiSetBind(oPC, nToken, FCRAFT_BIND_REM_COST, JsonString("— wybierz modyfikację —"));
        return;
    }

    json jMods = FcraftGetMods(oPC);
    if(nActIdx >= JsonGetLength(jMods))
    {
        FcraftFeedActiveDetail(oPC, nToken, -1);
        return;
    }

    string sId      = JsonGetString(JsonArrayGet(jMods, nActIdx));
    int bHasAbil    = FcraftModHasAbility(sId);
    string sCoolTag = FcraftModCooldownTag(sId);
    int bOnCool     = (sCoolTag != "" && GetLocalInt(oPC, sCoolTag) == 1);
    int nRemCost    = FcraftModCost(sId) * FCRAFT_REMOVE_MULT;
    int bCanRemove  = (GetGold(oPC) >= nRemCost);

    string sCoolLbl = "";
    if(bHasAbil)
        sCoolLbl = bOnCool ? "Zdolność: na odnowieniu" : "Zdolność: gotowa do użycia";

    NuiSetBind(oPC, nToken, FCRAFT_BIND_USE_VIS,  JsonBool(bHasAbil));
    NuiSetBind(oPC, nToken, FCRAFT_BIND_USE_ENA,  JsonBool(bHasAbil && !bOnCool));
    NuiSetBind(oPC, nToken, FCRAFT_BIND_USE_COOL, JsonString(sCoolLbl));
    NuiSetBind(oPC, nToken, FCRAFT_BIND_REM_ENA,  JsonBool(bCanRemove));
    NuiSetBind(oPC, nToken, FCRAFT_BIND_REM_COST,
        JsonString("Usunięcie: " + IntToString(nRemCost) + " zł (bolesny zabieg)"));
}

// ----------------------------------------------------------------
// Apply / Remove effects
// ----------------------------------------------------------------

void FcraftApplyEffectsForMod(object oPC, string sId)
{
    effect eFx = EffectLinkEffects(EffectVisualEffect(VFX_DUR_IOUNSTONE_BLUE), EffectVisualEffect(VFX_DUR_IOUNSTONE_BLUE));
    // Linking to a dummy VFX; real chain built below per mod
    int bApply = FALSE;

    if(sId == FCRAFT_MOD_CHITIN)
    {
        eFx = EffectLinkEffects(EffectACIncrease(3, AC_DEFLECTION_BONUS),
              EffectLinkEffects(EffectAbilityDecrease(ABILITY_DEXTERITY, 1),
                                EffectSkillDecrease(SKILL_PERSUADE, 2)));
        bApply = TRUE;
    }
    else if(sId == FCRAFT_MOD_DEMONSEYE)
    {
        eFx = EffectLinkEffects(EffectSkillIncrease(SKILL_SPOT, 5),
              EffectLinkEffects(EffectSkillIncrease(SKILL_LISTEN, 5),
                                EffectSkillDecrease(SKILL_PERSUADE, 2)));
        bApply = TRUE;
    }
    else if(sId == FCRAFT_MOD_SINEWARM)
    {
        eFx = EffectLinkEffects(EffectAbilityIncrease(ABILITY_STRENGTH, 2),
                                EffectAbilityDecrease(ABILITY_DEXTERITY, 1));
        bApply = TRUE;
    }
    else if(sId == FCRAFT_MOD_BONEFIST)
    {
        eFx = EffectLinkEffects(EffectAttackIncrease(1, ATTACK_BONUS_MISC),
                                EffectAbilityIncrease(ABILITY_STRENGTH, 1));
        bApply = TRUE;
    }
    else if(sId == FCRAFT_MOD_SPIDERGLAND)
    {
        eFx = EffectLinkEffects(EffectAbilityIncrease(ABILITY_DEXTERITY, 1),
                                EffectImmunity(IMMUNITY_TYPE_ENTANGLE));
        bApply = TRUE;
    }
    else if(sId == FCRAFT_MOD_IRONHIDE)
    {
        eFx = EffectLinkEffects(EffectACIncrease(2, AC_NATURAL_BONUS),
                                EffectAbilityDecrease(ABILITY_DEXTERITY, 1));
        bApply = TRUE;
    }
    else if(sId == FCRAFT_MOD_VENOMFANG)
    {
        eFx = EffectLinkEffects(EffectAbilityIncrease(ABILITY_CONSTITUTION, 1),
                                EffectImmunity(IMMUNITY_TYPE_POISON));
        bApply = TRUE;
    }
    else if(sId == FCRAFT_MOD_HEARTVAULT)
    {
        eFx = EffectLinkEffects(EffectAbilityIncrease(ABILITY_CONSTITUTION, 2),
                                EffectSavingThrowIncrease(SAVING_THROW_FORT, 2));
        bApply = TRUE;
    }
    else if(sId == FCRAFT_MOD_STONEEYE)
    {
        eFx = EffectLinkEffects(EffectAbilityIncrease(ABILITY_WISDOM, 2),
              EffectLinkEffects(EffectSkillIncrease(SKILL_SPOT, 5),
                                EffectImmunity(IMMUNITY_TYPE_BLINDNESS)));
        bApply = TRUE;
    }
    else if(sId == FCRAFT_MOD_SHADOWLIMB)
    {
        eFx = EffectLinkEffects(EffectAbilityIncrease(ABILITY_DEXTERITY, 2),
                                EffectAbilityDecrease(ABILITY_STRENGTH, 1));
        bApply = TRUE;
    }

    if(!bApply) return;

    eFx = SupernaturalEffect(eFx);
    eFx = TagEffect(eFx, "FCRAFT_" + sId);
    ApplyEffectToObject(DURATION_TYPE_PERMANENT, eFx, oPC);
}

void FcraftStripEffects(object oPC, string sId)
{
    string sTag = "FCRAFT_" + sId;
    effect eFx  = GetFirstEffect(oPC);
    while(GetIsEffectValid(eFx))
    {
        if(GetEffectTag(eFx) == sTag)
            RemoveEffect(oPC, eFx);
        eFx = GetNextEffect(oPC);
    }
}

void FcraftApplyMod(object oPC, string sModId)
{
    if(FcraftHasMod(oPC, sModId)) return;
    if(FcraftGetModCount(oPC) >= FCRAFT_MAX_MODS) return;

    string sExcl = FcraftModExcludes(sModId);
    if(sExcl != "" && FcraftHasMod(oPC, sExcl)) return;

    int nCost       = FcraftModCost(sModId);
    string sCompRef = FcraftModComp(sModId);
    object oComp    = FcraftFindComp(oPC, sCompRef);

    if(GetGold(oPC) < nCost || !GetIsObjectValid(oComp)) return;

    AssignCommand(oPC, TakeGoldFromCreature(nCost, oPC, TRUE));
    DestroyObject(oComp);

    FcraftAddMod(oPC, sModId);
    FcraftApplyEffectsForMod(oPC, sModId);

    string sMsg = "[Kowalnia] Modyfikacja wszczepiona: " + FcraftModName(sModId) + ".";
    FloatingTextStringOnCreature(sMsg, oPC, FALSE);
    SendMessageToPC(oPC, sMsg);
    ApplyEffectToObject(DURATION_TYPE_TEMPORARY,
        EffectVisualEffect(VFX_COM_BLOOD_CRT_RED), oPC, 2.0);
}

void FcraftRemoveMod(object oPC, string sModId)
{
    if(!FcraftHasMod(oPC, sModId)) return;

    int nRemCost = FcraftModCost(sModId) * FCRAFT_REMOVE_MULT;
    if(GetGold(oPC) < nRemCost) return;

    AssignCommand(oPC, TakeGoldFromCreature(nRemCost, oPC, TRUE));
    FcraftStripEffects(oPC, sModId);
    FcraftDeleteMod(oPC, sModId);
    DeleteLocalInt(oPC, FcraftModCooldownTag(sModId));

    string sMsg = "[Kowalnia] Modyfikacja usunięta: " + FcraftModName(sModId) + ". Blizna pozostanie.";
    FloatingTextStringOnCreature(sMsg, oPC, FALSE);
    SendMessageToPC(oPC, sMsg);
}

void FcraftReapplyAll(object oPC)
{
    json jMods  = FcraftGetMods(oPC);
    int nCount  = JsonGetLength(jMods);
    int i;
    for(i = 0; i < nCount; i++)
    {
        string sId = JsonGetString(JsonArrayGet(jMods, i));
        FcraftStripEffects(oPC, sId); // clear stale effects from previous session
        FcraftApplyEffectsForMod(oPC, sId);
    }
    if(nCount > 0)
    {
        string sMsg = "[Kowalnia] " + IntToString(nCount) + " modyfikacja/-e ciała aktywne.";
        SendMessageToPC(oPC, sMsg);
    }
}
