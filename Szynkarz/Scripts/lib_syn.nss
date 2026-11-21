// lib_syn.nss — Szynkarz: NUI layout, game logic, effect application

#include "lib_syn_def"

// ----------------------------------------------------------------
// Layout constants (scaled from base dimensions)
// ----------------------------------------------------------------

const float SYN_WIN_W   = 620.0;
const float SYN_WIN_H   = 430.0;
const float SYN_ROW_H   = 26.0;
const float SYN_LIST_H  = 280.0;

// ----------------------------------------------------------------
// Ingredient list text helper
// ----------------------------------------------------------------

string SynIngListText(int nRecipeId)
{
    json jIngs  = SynGetRecipeIngredients(nRecipeId);
    int  nCount = JsonGetLength(jIngs);
    string sOut = "";
    int i;
    for(i = 0; i < nCount; i++)
    {
        json jIng   = JsonArrayGet(jIngs, i);
        string sN   = JsonGetString(JsonObjectGet(jIng, "name"));
        int    nQ   = JsonGetInt   (JsonObjectGet(jIng, "qty"));
        if(sOut != "") sOut += "\n";
        sOut += "  " + sN + " x" + IntToString(nQ);
    }
    return sOut;
}

// ----------------------------------------------------------------
// Layout builders — each returns the content for the swappable group
// ----------------------------------------------------------------

json SynBuildRecipesLayout(object oPC)
{
    float fRowH = GetNuiScaleDimension(oPC, SYN_ROW_H);
    float fListW = GetNuiScaleDimension(oPC, 175.0);

    // Left column: scrollable recipe list
    // Group wraps the label; enc is on the group so the full row background highlights.
    json jRecRow = JsonArray();
    jRecRow = JsonArrayInsert(jRecRow,
        NuiLabel(NuiBind(SYN_BIND_REC_NAMES), JsonInt(NUI_HALIGN_LEFT), JsonInt(NUI_VALIGN_MIDDLE)));

    json jRowGrp = NuiGroup(NuiRow(jRecRow), FALSE, NUI_SCROLLBARS_NONE);
    jRowGrp = NuiId(jRowGrp, SYN_BTN_REC_ROW);
    jRowGrp = NuiEncouraged(jRowGrp, NuiBind(SYN_BIND_REC_ENC));

    json jTmpl = JsonArrayInsert(JsonArray(), NuiListTemplateCell(jRowGrp, 0.0, TRUE));

    json jList = NuiList(jTmpl, NuiBind("syn_rec_count"), fRowH);
    jList = NuiHeight(jList, GetNuiScaleDimension(oPC, SYN_LIST_H));

    json jLeftItems = JsonArray();
    jLeftItems = JsonArrayInsert(jLeftItems,
        NuiLabel(JsonString("Receptury"), JsonInt(NUI_HALIGN_CENTER), JsonInt(NUI_VALIGN_MIDDLE)));
    jLeftItems = JsonArrayInsert(jLeftItems, jList);
    json jLeft = NuiWidth(NuiCol(jLeftItems), fListW);

    // Right column: recipe detail
    json jRightItems = JsonArray();
    jRightItems = JsonArrayInsert(jRightItems,
        NuiLabel(NuiBind(SYN_BIND_DET_NAME),
                 JsonInt(NUI_HALIGN_LEFT), JsonInt(NUI_VALIGN_MIDDLE)));
    jRightItems = JsonArrayInsert(jRightItems, NuiSpacer());
    jRightItems = JsonArrayInsert(jRightItems,
        NuiText(NuiBind(SYN_BIND_DET_FLAV), FALSE));
    jRightItems = JsonArrayInsert(jRightItems, NuiSpacer());
    jRightItems = JsonArrayInsert(jRightItems,
        NuiLabel(JsonString("Składniki:"), JsonInt(NUI_HALIGN_LEFT), JsonInt(NUI_VALIGN_MIDDLE)));
    jRightItems = JsonArrayInsert(jRightItems,
        NuiLabel(NuiBind(SYN_BIND_DET_INGS), JsonInt(NUI_HALIGN_LEFT), JsonInt(NUI_VALIGN_TOP)));
    jRightItems = JsonArrayInsert(jRightItems, NuiSpacer());
    jRightItems = JsonArrayInsert(jRightItems,
        NuiLabel(JsonString("Efekty:"), JsonInt(NUI_HALIGN_LEFT), JsonInt(NUI_VALIGN_MIDDLE)));
    jRightItems = JsonArrayInsert(jRightItems,
        NuiLabel(NuiBind(SYN_BIND_DET_EFFS), JsonInt(NUI_HALIGN_LEFT), JsonInt(NUI_VALIGN_TOP)));
    jRightItems = JsonArrayInsert(jRightItems, NuiSpacer());
    jRightItems = JsonArrayInsert(jRightItems,
        NuiLabel(NuiBind(SYN_BIND_DET_INTOX), JsonInt(NUI_HALIGN_LEFT), JsonInt(NUI_VALIGN_MIDDLE)));

    json jRight = NuiCol(jRightItems);

    json jMainRow = JsonArray();
    jMainRow = JsonArrayInsert(jMainRow, jLeft);
    jMainRow = JsonArrayInsert(jMainRow, jRight);

    return NuiCol(JsonArrayInsert(JsonArray(), NuiRow(jMainRow)));
}

json SynBuildBrewLayout(object oPC)
{
    json jRows = JsonArray();

    jRows = JsonArrayInsert(jRows, NuiHeight(
        NuiLabel(NuiBind(SYN_BIND_BREW_NAME), JsonInt(NUI_HALIGN_CENTER), JsonInt(NUI_VALIGN_MIDDLE)),
        GetNuiScaleDimension(oPC, 28.0)));

    jRows = JsonArrayInsert(jRows,
        NuiLabel(JsonString("Składniki:"), JsonInt(NUI_HALIGN_LEFT), JsonInt(NUI_VALIGN_MIDDLE)));

    jRows = JsonArrayInsert(jRows,
        NuiText(NuiBind(SYN_BIND_BREW_LINES), FALSE));

    jRows = JsonArrayInsert(jRows, NuiSpacer());

    json jBrewBtn = NuiButton(JsonString("Warzyj Trunek"));
    jBrewBtn = NuiId(jBrewBtn, SYN_BTN_BREW);
    jBrewBtn = NuiEnabled(jBrewBtn, NuiBind(SYN_BIND_BREW_ENA));
    jBrewBtn = NuiWidth(jBrewBtn, GetNuiScaleDimension(oPC, 160.0));

    json jBtnRow = JsonArray();
    jBtnRow = JsonArrayInsert(jBtnRow, NuiSpacer());
    jBtnRow = JsonArrayInsert(jBtnRow, jBrewBtn);
    jBtnRow = JsonArrayInsert(jBtnRow, NuiSpacer());
    jRows = JsonArrayInsert(jRows, NuiRow(jBtnRow));

    return NuiCol(jRows);
}

json SynBuildCellarLayout(object oPC)
{
    float fRowH = GetNuiScaleDimension(oPC, SYN_ROW_H);
    float fQtyW = GetNuiScaleDimension(oPC, 50.0);

    // Row content: name (elastic) + qty (fixed width)
    json jNameLbl = NuiLabel(NuiBind(SYN_BIND_CEL_NAMES),
                             JsonInt(NUI_HALIGN_LEFT), JsonInt(NUI_VALIGN_MIDDLE));
    json jQtyLbl  = NuiWidth(
        NuiLabel(NuiBind(SYN_BIND_CEL_QTYS), JsonInt(NUI_HALIGN_CENTER), JsonInt(NUI_VALIGN_MIDDLE)),
        fQtyW);

    json jCellRow = JsonArray();
    jCellRow = JsonArrayInsert(jCellRow, jNameLbl);
    jCellRow = JsonArrayInsert(jCellRow, jQtyLbl);

    // Wrap in a group so the whole row is a single clickable element
    json jRowGrp = NuiGroup(NuiRow(jCellRow), FALSE, NUI_SCROLLBARS_NONE);
    jRowGrp = NuiId(jRowGrp, SYN_BTN_CEL_ROW);
    jRowGrp = NuiEncouraged(jRowGrp, NuiBind(SYN_BIND_CEL_ENC));

    json jTmpl = JsonArrayInsert(JsonArray(), NuiListTemplateCell(jRowGrp, 0.0, TRUE));

    json jCelList = NuiList(jTmpl, NuiBind("syn_cel_count"), fRowH);
    jCelList = NuiHeight(jCelList, GetNuiScaleDimension(oPC, SYN_LIST_H));

    json jDrinkBtn = NuiButton(JsonString("Wypij Zaznaczony"));
    jDrinkBtn = NuiId(jDrinkBtn, SYN_BTN_DRINK);
    jDrinkBtn = NuiEnabled(jDrinkBtn, NuiBind(SYN_BIND_DRINK_ENA));
    jDrinkBtn = NuiWidth(jDrinkBtn, GetNuiScaleDimension(oPC, 180.0));

    json jBtnRow = JsonArray();
    jBtnRow = JsonArrayInsert(jBtnRow, NuiSpacer());
    jBtnRow = JsonArrayInsert(jBtnRow, jDrinkBtn);
    jBtnRow = JsonArrayInsert(jBtnRow, NuiSpacer());

    json jRows = JsonArray();
    jRows = JsonArrayInsert(jRows,
        NuiLabel(JsonString("Spiżarnia:"), JsonInt(NUI_HALIGN_LEFT), JsonInt(NUI_VALIGN_MIDDLE)));
    jRows = JsonArrayInsert(jRows, jCelList);
    jRows = JsonArrayInsert(jRows, NuiSpacer());
    jRows = JsonArrayInsert(jRows, NuiRow(jBtnRow));

    return NuiCol(jRows);
}

// ----------------------------------------------------------------
// Window construction
// ----------------------------------------------------------------

void SynOpenWindow(object oPC)
{
    int nToken = NuiFindWindow(oPC, SYN_WINDOW);
    if(nToken != 0)
    {
        NuiSetWindowCollapsed(oPC, nToken, FALSE);
        return;
    }

    // Tab strip + close button (always visible at top)
    json jTabRec  = NuiId(NuiButton(JsonString("Receptury")),  SYN_BTN_TAB_REC);
    json jTabBrew = NuiId(NuiButton(JsonString("Warzelnia")),  SYN_BTN_TAB_BREW);
    json jTabCel  = NuiId(NuiButton(JsonString("Spiżarnia")),  SYN_BTN_TAB_CEL);
    json jClose   = NuiId(NuiButton(JsonString("X")),          SYN_BTN_CLOSE);

    float fTabW = GetNuiScaleDimension(oPC, 90.0);
    json jTabRow = JsonArray();
    jTabRow = JsonArrayInsert(jTabRow, NuiWidth(jTabRec,  fTabW));
    jTabRow = JsonArrayInsert(jTabRow, NuiWidth(jTabBrew, fTabW));
    jTabRow = JsonArrayInsert(jTabRow, NuiWidth(jTabCel,  fTabW));
    jTabRow = JsonArrayInsert(jTabRow, NuiSpacer());
    jTabRow = JsonArrayInsert(jTabRow, NuiWidth(jClose, GetNuiScaleDimension(oPC, 30.0)));

    // Swappable content group (placeholder; set via NuiSetGroupLayout after open)
    json jPlaceholder = NuiSpacer();
    json jContentGrp = NuiGroup(jPlaceholder, FALSE, NUI_SCROLLBARS_NONE);
    jContentGrp = NuiId(jContentGrp, SYN_CONTENT_GROUP);

    // Intox bar (always visible at bottom)
    json jIntoxLbl = NuiLabel(NuiBind(SYN_BIND_INTOX_LBL),
                              JsonInt(NUI_HALIGN_LEFT), JsonInt(NUI_VALIGN_MIDDLE));
    jIntoxLbl = NuiWidth(jIntoxLbl, GetNuiScaleDimension(oPC, 180.0));

    json jBar = NuiProgressBar(NuiBind(SYN_BIND_INTOX_VAL));
    jBar = NuiStyleForegroundColor(jBar, NuiBind(SYN_BIND_INTOX_COL));

    json jBarRow = JsonArray();
    jBarRow = JsonArrayInsert(jBarRow,
        NuiWidth(NuiLabel(JsonString("Upojenie:"), JsonInt(NUI_HALIGN_LEFT), JsonInt(NUI_VALIGN_MIDDLE)),
                 GetNuiScaleDimension(oPC, 70.0)));
    jBarRow = JsonArrayInsert(jBarRow, jIntoxLbl);
    jBarRow = JsonArrayInsert(jBarRow, jBar);

    // Root layout
    json jRoot = JsonArray();
    jRoot = JsonArrayInsert(jRoot, NuiHeight(NuiRow(jTabRow),    GetNuiScaleDimension(oPC, 32.0)));
    jRoot = JsonArrayInsert(jRoot, NuiRow(JsonArrayInsert(JsonArray(), jContentGrp)));
    jRoot = JsonArrayInsert(jRoot, NuiHeight(NuiRow(jBarRow),   GetNuiScaleDimension(oPC, 30.0)));

    json jGeom = NuiRect(
        GetNuiScaleDimension(oPC, 80.0),
        GetNuiScaleDimension(oPC, 80.0),
        GetNuiScaleDimension(oPC, SYN_WIN_W),
        GetNuiScaleDimension(oPC, SYN_WIN_H));

    nToken = NuiCreate(oPC, NuiCol(jRoot), JsonString("Warzelnia"), SYN_WIN_GEOM, TRUE, SYN_EV_SCRIPT);
    if(nToken == 0) return;

    NuiSetBind(oPC, nToken, SYN_WIN_GEOM, jGeom);

    SetLocalInt(oPC, SYN_LVAR_SEL_REC,    -1);
    SetLocalInt(oPC, SYN_LVAR_SEL_CEL_ID,  0);
    SetLocalInt(oPC, SYN_LVAR_ACTIVE_TAB,  0);

    // Populate intox bar immediately
    int nLevel = GetLocalInt(oPC, "SYN_INTOX_CACHE");
    SynUpdateIntoxBar(oPC, nToken, nLevel);

    // Show recipes tab by default
    SynFeedRecipesGroup(oPC, nToken);
}

// ----------------------------------------------------------------
// Feed functions — repopulate binds for each tab
// ----------------------------------------------------------------

void SynFeedRecipesGroup(object oPC, int nToken)
{
    NuiSetGroupLayout(oPC, nToken, SYN_CONTENT_GROUP, SynBuildRecipesLayout(oPC));

    // Static count (always SYN_REC_COUNT rows)
    NuiSetBind(oPC, nToken, "syn_rec_count", JsonInt(SYN_REC_COUNT));

    // Recipe name array
    int  nSel   = GetLocalInt(oPC, SYN_LVAR_SEL_REC);
    json jNames = JsonArray();
    json jEnc   = JsonArray();
    int i;
    for(i = 0; i < SYN_REC_COUNT; i++)
    {
        jNames = JsonArrayInsert(jNames, JsonString(SynRecipeName(i)));
        jEnc   = JsonArrayInsert(jEnc,   JsonBool(i == nSel));
    }
    NuiSetBind(oPC, nToken, SYN_BIND_REC_NAMES, jNames);
    NuiSetBind(oPC, nToken, SYN_BIND_REC_ENC,   jEnc);

    // Detail panel
    if(nSel >= 0 && nSel < SYN_REC_COUNT)
    {
        NuiSetBind(oPC, nToken, SYN_BIND_DET_NAME,
            JsonString(SynRecipeName(nSel)));
        NuiSetBind(oPC, nToken, SYN_BIND_DET_FLAV,
            JsonString(SynRecipeFlavor(nSel)));
        NuiSetBind(oPC, nToken, SYN_BIND_DET_INGS,
            JsonString(SynIngListText(nSel)));
        NuiSetBind(oPC, nToken, SYN_BIND_DET_EFFS,
            JsonString(SynRecipeEffects(nSel)));
        NuiSetBind(oPC, nToken, SYN_BIND_DET_INTOX,
            JsonString("Upojenie: +" + IntToString(SynRecipeIntox(nSel)) + " pkt"));
    }
    else
    {
        NuiSetBind(oPC, nToken, SYN_BIND_DET_NAME,  JsonString(""));
        NuiSetBind(oPC, nToken, SYN_BIND_DET_FLAV,
            JsonString("Wybierz recepturę z listy po lewej."));
        NuiSetBind(oPC, nToken, SYN_BIND_DET_INGS,  JsonString(""));
        NuiSetBind(oPC, nToken, SYN_BIND_DET_EFFS,  JsonString(""));
        NuiSetBind(oPC, nToken, SYN_BIND_DET_INTOX, JsonString(""));
    }
}

void SynFeedBrewGroup(object oPC, int nToken)
{
    NuiSetGroupLayout(oPC, nToken, SYN_CONTENT_GROUP, SynBuildBrewLayout(oPC));

    int nSel = GetLocalInt(oPC, SYN_LVAR_SEL_REC);
    if(nSel < 0 || nSel >= SYN_REC_COUNT)
    {
        NuiSetBind(oPC, nToken, SYN_BIND_BREW_NAME,
            JsonString("Brak wybranej receptury"));
        NuiSetBind(oPC, nToken, SYN_BIND_BREW_LINES,
            JsonString("Wybierz recepturę w zakładce Receptury."));
        NuiSetBind(oPC, nToken, SYN_BIND_BREW_ENA, JsonBool(FALSE));
        return;
    }

    NuiSetBind(oPC, nToken, SYN_BIND_BREW_NAME, JsonString(SynRecipeName(nSel)));

    json jIngs  = SynGetRecipeIngredients(nSel);
    int  nCount = JsonGetLength(jIngs);
    string sLines  = "";
    int bCanBrew = TRUE;
    int i;
    for(i = 0; i < nCount; i++)
    {
        json jIng   = JsonArrayGet(jIngs, i);
        string sN   = JsonGetString(JsonObjectGet(jIng, "name"));
        int    nReq = JsonGetInt   (JsonObjectGet(jIng, "qty"));
        int    nHas = SynCountInInventory(oPC, JsonGetString(JsonObjectGet(jIng, "tag")));
        if(sLines != "") sLines += "\n";
        string sMark = (nHas >= nReq) ? "[OK] " : "[--] ";
        sLines += sMark + sN + " — " + IntToString(nHas) + "/" + IntToString(nReq);
        if(nHas < nReq) bCanBrew = FALSE;
    }
    NuiSetBind(oPC, nToken, SYN_BIND_BREW_LINES, JsonString(sLines));
    NuiSetBind(oPC, nToken, SYN_BIND_BREW_ENA,   JsonBool(bCanBrew));
}

void SynFeedCellarGroup(object oPC, int nToken)
{
    NuiSetGroupLayout(oPC, nToken, SYN_CONTENT_GROUP, SynBuildCellarLayout(oPC));

    json jCellar = SynGetCellar(oPC);
    int  nCount  = JsonGetLength(jCellar);
    int  nSelId  = GetLocalInt(oPC, SYN_LVAR_SEL_CEL_ID);

    json jNames = JsonArray();
    json jQtys  = JsonArray();
    json jEnc   = JsonArray();
    int i;
    for(i = 0; i < nCount; i++)
    {
        json jRow = JsonArrayGet(jCellar, i);
        int  nId  = JsonGetInt(JsonObjectGet(jRow, "id"));
        int  nRec = JsonGetInt(JsonObjectGet(jRow, "recipe_id"));
        int  nQty = JsonGetInt(JsonObjectGet(jRow, "qty"));

        jNames = JsonArrayInsert(jNames, JsonString(SynRecipeName(nRec)));
        jQtys  = JsonArrayInsert(jQtys,  JsonString("x" + IntToString(nQty)));
        jEnc   = JsonArrayInsert(jEnc,   JsonBool(nId == nSelId));
    }

    NuiSetBind(oPC, nToken, SYN_BIND_CEL_NAMES, jNames);
    NuiSetBind(oPC, nToken, SYN_BIND_CEL_QTYS,  jQtys);
    NuiSetBind(oPC, nToken, SYN_BIND_CEL_ENC,   jEnc);
    NuiSetBind(oPC, nToken, "syn_cel_count",     JsonInt(nCount));
    NuiSetBind(oPC, nToken, SYN_BIND_DRINK_ENA,  JsonBool(nSelId != 0 && nCount > 0));
}

// ----------------------------------------------------------------
// Intox bar (refreshed after any intox change and on tab switch)
// ----------------------------------------------------------------

void SynUpdateIntoxBar(object oPC, int nToken, int nLevel)
{
    string sLbl = SynIntoxLabel(nLevel) + " (" + IntToString(nLevel) + "/100)";
    NuiSetBind(oPC, nToken, SYN_BIND_INTOX_LBL, JsonString(sLbl));
    NuiSetBind(oPC, nToken, SYN_BIND_INTOX_VAL, JsonFloat(IntToFloat(nLevel) / 100.0));
    NuiSetBind(oPC, nToken, SYN_BIND_INTOX_COL, SynIntoxColor(nLevel));
}

// ----------------------------------------------------------------
// Brewing action
// ----------------------------------------------------------------

void SynBrew(object oPC, int nToken)
{
    int nSel = GetLocalInt(oPC, SYN_LVAR_SEL_REC);
    if(nSel < 0 || nSel >= SYN_REC_COUNT)
    {
        SendMessageToPC(oPC, "[Warzelnia] Brak wybranej receptury.");
        return;
    }
    if(!SynCanBrew(oPC, nSel))
    {
        SendMessageToPC(oPC, "[Warzelnia] Brakuje składników.");
        NuiSetBind(oPC, nToken, SYN_BIND_BREW_ENA, JsonBool(FALSE));
        return;
    }

    SynConsumeIngredients(oPC, nSel);
    SynAddCellarDrink(oPC, nSel);

    PlaySound("al_cv_stirpot2");
    SendMessageToPC(oPC, "[Warzelnia] Uwarzono: " + SynRecipeName(nSel)
                       + ". Trunek trafił do spiżarni.");

    // Refresh ingredient availability for next brew
    SynFeedBrewGroup(oPC, nToken);
}

// ----------------------------------------------------------------
// Drink-specific effects
// ----------------------------------------------------------------

void SynApplyDrinkEffect(object oPC, int nRecipeId)
{
    float fDur5  = RoundsToSeconds(10);
    float fDur10 = RoundsToSeconds(20);
    float fDur15 = RoundsToSeconds(30);
    float fDur30 = RoundsToSeconds(60);
    string sTag  = "SYN_DRINK_" + IntToString(nRecipeId);

    switch(nRecipeId)
    {
        case SYN_REC_ALE:
            ApplyEffectToObject(DURATION_TYPE_TEMPORARY,
                TagEffect(EffectAbilityIncrease(ABILITY_STRENGTH,  1), sTag), oPC, fDur10);
            ApplyEffectToObject(DURATION_TYPE_TEMPORARY,
                TagEffect(EffectAbilityDecrease(ABILITY_DEXTERITY, 1), sTag), oPC, fDur10);
            ApplyEffectToObject(DURATION_TYPE_TEMPORARY,
                TagEffect(EffectAbilityIncrease(ABILITY_CHARISMA,  1), sTag), oPC, fDur10);
            ApplyEffectToObject(DURATION_TYPE_TEMPORARY,
                TagEffect(EffectTemporaryHitpoints(5), sTag), oPC, fDur10);
            break;

        case SYN_REC_GRAVEDIGGER:
            ApplyEffectToObject(DURATION_TYPE_TEMPORARY,
                TagEffect(EffectAbilityIncrease(ABILITY_STRENGTH,  2), sTag), oPC, fDur10);
            ApplyEffectToObject(DURATION_TYPE_TEMPORARY,
                TagEffect(EffectAbilityDecrease(ABILITY_DEXTERITY, 2), sTag), oPC, fDur10);
            ApplyEffectToObject(DURATION_TYPE_TEMPORARY,
                TagEffect(EffectDamageResistance(DAMAGE_TYPE_COLD, 5, 0), sTag), oPC, fDur10);
            break;

        case SYN_REC_GRAVE_MEAD:
            ApplyEffectToObject(DURATION_TYPE_TEMPORARY,
                TagEffect(EffectImmunity(IMMUNITY_TYPE_FRIGHTENED), sTag), oPC, fDur15);
            ApplyEffectToObject(DURATION_TYPE_TEMPORARY,
                TagEffect(EffectSavingThrowIncrease(SAVING_THROW_ALL, 3, SAVING_THROW_TYPE_DEATH),
                          sTag), oPC, fDur15);
            break;

        case SYN_REC_BLOOD_WINE:
            ApplyEffectToObject(DURATION_TYPE_TEMPORARY,
                TagEffect(EffectAttackIncrease(1, ATTACK_BONUS_MISC), sTag), oPC, fDur5);
            SetLocalInt(oPC, "SYN_BLOOD_WINE", 1);
            DelayCommand(fDur5, DeleteLocalInt(oPC, "SYN_BLOOD_WINE"));
            break;

        case SYN_REC_WRAITHWATER:
            ApplyEffectToObject(DURATION_TYPE_TEMPORARY,
                TagEffect(EffectConcealment(25, MISS_CHANCE_TYPE_NORMAL), sTag), oPC, fDur5);
            ApplyEffectToObject(DURATION_TYPE_TEMPORARY,
                TagEffect(EffectAbilityDecrease(ABILITY_WISDOM, 4), sTag), oPC, fDur5);
            break;

        case SYN_REC_IRON_BREW:
            ApplyEffectToObject(DURATION_TYPE_TEMPORARY,
                TagEffect(EffectAbilityIncrease(ABILITY_CONSTITUTION, 2), sTag), oPC, fDur10);
            ApplyEffectToObject(DURATION_TYPE_TEMPORARY,
                TagEffect(EffectDamageResistance(DAMAGE_TYPE_SLASHING, 5, 0), sTag), oPC, fDur10);
            ApplyEffectToObject(DURATION_TYPE_TEMPORARY,
                TagEffect(EffectAbilityDecrease(ABILITY_INTELLIGENCE, 1), sTag), oPC, fDur10);
            break;

        case SYN_REC_SPIDER_GIN:
            ApplyEffectToObject(DURATION_TYPE_TEMPORARY,
                TagEffect(EffectImmunity(IMMUNITY_TYPE_POISON), sTag), oPC, fDur30);
            ApplyEffectToObject(DURATION_TYPE_TEMPORARY,
                TagEffect(EffectAbilityIncrease(ABILITY_DEXTERITY, 2), sTag), oPC, fDur30);
            break;

        case SYN_REC_WARLOCK_VOD:
            // +1 caster level is best approximated by a bonus spell; use visual + AC here
            ApplyEffectToObject(DURATION_TYPE_TEMPORARY,
                TagEffect(EffectSpellLevelAbsorption(9, 0, SPELL_SCHOOL_GENERAL), sTag), oPC, fDur5);
            int nVFX;
            switch(d4(1))
            {
                case 1: nVFX = VFX_IMP_LIGHTNING_S;       break;
                case 2: nVFX = VFX_IMP_EVIL_HELP;         break;
                case 3: nVFX = VFX_IMP_MAGIC_PROTECTION;  break;
                default: nVFX = VFX_IMP_HOLY_AID;         break;
            }
            ApplyEffectToObject(DURATION_TYPE_INSTANT, EffectVisualEffect(nVFX), oPC);
            break;
    }

    // Flavor floating text
    string sFlavor;
    switch(nRecipeId)
    {
        case SYN_REC_ALE:
            sFlavor = "Piwo ścieka po gardle — ciepłe i złe. Mięśnie się rozluźniają."; break;
        case SYN_REC_GRAVEDIGGER:
            sFlavor = "Pali jak ogień. Zęby szczękają mimo woli — ze strachu czy z zimna?"; break;
        case SYN_REC_GRAVE_MEAD:
            sFlavor = "Słodki proch na języku. Strach odpływa jak mgła nad mogiłą."; break;
        case SYN_REC_BLOOD_WINE:
            sFlavor = "Ciepłe i ciężkie. Wzrok wyostrza się na bijące serca wokół."; break;
        case SYN_REC_WRAITHWATER:
            sFlavor = "Chłód wchodzi w kości — i pozostaje. Twój cień się nie porusza razem z tobą."; break;
        case SYN_REC_IRON_BREW:
            sFlavor = "Zęby cię boli. Żołądek protestuje. Skóra twardnieje jak kuta blacha."; break;
        case SYN_REC_SPIDER_GIN:
            sFlavor = "Mroźny ukłucie w gardle. Trucizna jak antidotum — albo odwrotnie."; break;
        case SYN_REC_WARLOCK_VOD:
            sFlavor = "Iskry za oczami. Możesz przysiąc, że widzisz nitki magii w powietrzu."; break;
        default:
            sFlavor = "Trunek smakuje jak przeznaczenie."; break;
    }
    FloatingTextStringOnCreature(sFlavor, oPC, FALSE);
}

// ----------------------------------------------------------------
// Intox threshold passive effects
// ----------------------------------------------------------------

// Removes all effects tagged with the given threshold tag
void SynRemoveIntoxThresholdFX(object oPC, int nThr)
{
    string sTag = "SYN_INTOX_" + IntToString(nThr);
    effect eChk = GetFirstEffect(oPC);
    while(GetIsEffectValid(eChk))
    {
        if(GetEffectTag(eChk) == sTag)
            RemoveEffect(oPC, eChk);
        eChk = GetNextEffect(oPC);
    }
}

void SynApplyIntoxEffects(object oPC, int nOldThr, int nNewThr)
{
    if(nOldThr == nNewThr) return;

    SynRemoveIntoxThresholdFX(oPC, nOldThr);

    if(nNewThr <= 0) // sober
    {
        if(nOldThr > 0)
            SendMessageToPC(oPC, "[Warzelnia] Upojenie minęło. Powrót do trzeźwości.");
        return;
    }

    string sTag  = "SYN_INTOX_" + IntToString(nNewThr);
    float  fPerm = HoursToSeconds(24); // stays until removed by decay

    switch(nNewThr)
    {
        case 1: // tipsy
            ApplyEffectToObject(DURATION_TYPE_TEMPORARY,
                TagEffect(EffectAbilityIncrease(ABILITY_CHARISMA, 1), sTag), oPC, fPerm);
            SendMessageToPC(oPC, "[Warzelnia] Lekko w głowie. Świat wygląda przyjemniej.");
            break;

        case 2: // drunk
            ApplyEffectToObject(DURATION_TYPE_TEMPORARY,
                TagEffect(EffectAbilityIncrease(ABILITY_STRENGTH,     2), sTag), oPC, fPerm);
            ApplyEffectToObject(DURATION_TYPE_TEMPORARY,
                TagEffect(EffectAbilityDecrease(ABILITY_DEXTERITY,    2), sTag), oPC, fPerm);
            ApplyEffectToObject(DURATION_TYPE_TEMPORARY,
                TagEffect(EffectAbilityDecrease(ABILITY_INTELLIGENCE, 2), sTag), oPC, fPerm);
            ApplyEffectToObject(DURATION_TYPE_TEMPORARY,
                TagEffect(EffectAbilityIncrease(ABILITY_CHARISMA,     2), sTag), oPC, fPerm);
            SendMessageToPC(oPC, "[Warzelnia] Pijany. Nogi trochę nie słuchają, ale w rękach czuć moc.");
            break;

        case 3: // heavy
            ApplyEffectToObject(DURATION_TYPE_TEMPORARY,
                TagEffect(EffectAbilityIncrease(ABILITY_STRENGTH,     3), sTag), oPC, fPerm);
            ApplyEffectToObject(DURATION_TYPE_TEMPORARY,
                TagEffect(EffectAbilityDecrease(ABILITY_DEXTERITY,    4), sTag), oPC, fPerm);
            ApplyEffectToObject(DURATION_TYPE_TEMPORARY,
                TagEffect(EffectAbilityDecrease(ABILITY_INTELLIGENCE, 4), sTag), oPC, fPerm);
            ApplyEffectToObject(DURATION_TYPE_TEMPORARY,
                TagEffect(EffectAbilityIncrease(ABILITY_CHARISMA,     2), sTag), oPC, fPerm);
            SendMessageToPC(oPC, "[Warzelnia] Mocno pijany. Rzeczywistość faluje jak woda w beczce.");
            break;

        case 4: // severe
            ApplyEffectToObject(DURATION_TYPE_TEMPORARY,
                TagEffect(EffectAbilityDecrease(ABILITY_DEXTERITY,    5), sTag), oPC, fPerm);
            ApplyEffectToObject(DURATION_TYPE_TEMPORARY,
                TagEffect(EffectAbilityDecrease(ABILITY_INTELLIGENCE, 6), sTag), oPC, fPerm);
            ApplyEffectToObject(DURATION_TYPE_TEMPORARY,
                TagEffect(EffectAbilityDecrease(ABILITY_WISDOM,       4), sTag), oPC, fPerm);
            SendMessageToPC(oPC, "[Warzelnia] Totalnie pijany. Ziemia się kręci. Czas się położyć.");
            break;

        case 5: // blackout
            SendMessageToPC(oPC, "[Warzelnia] Zbyt dużo... Oczy się zamykają same.");
            ApplyEffectToObject(DURATION_TYPE_TEMPORARY,
                TagEffect(EffectSleep(), "SYN_INTOX_5"), oPC, 30.0);
            break;
    }
}

// ----------------------------------------------------------------
// Drinking action
// ----------------------------------------------------------------

void SynDrink(object oPC, int nToken, int nRowId, int nRecipeId)
{
    if(nRowId == 0) return;

    SynRemoveCellarDrink(oPC, nRowId);
    SetLocalInt(oPC, SYN_LVAR_SEL_CEL_ID, 0);

    SynApplyDrinkEffect(oPC, nRecipeId);

    int nOldLevel = GetLocalInt(oPC, "SYN_INTOX_CACHE");
    int nOldThr   = SynIntoxThreshold(nOldLevel);
    SynAddIntox(oPC, SynRecipeIntox(nRecipeId));
    int nNewLevel = GetLocalInt(oPC, "SYN_INTOX_CACHE");
    int nNewThr   = SynIntoxThreshold(nNewLevel);

    SynApplyIntoxEffects(oPC, nOldThr, nNewThr);
    SetLocalInt(oPC, SYN_LVAR_INTOX_THR, nNewThr);

    SynUpdateIntoxBar(oPC, nToken, nNewLevel);
    SynFeedCellarGroup(oPC, nToken);
}

// ----------------------------------------------------------------
// Login / heartbeat hooks
// ----------------------------------------------------------------

void SynOnClientEnter(object oPC)
{
    int nLevel = SynGetIntox(oPC);
    SetLocalInt(oPC, "SYN_INTOX_CACHE", nLevel);
    int nThr = SynIntoxThreshold(nLevel);
    SetLocalInt(oPC, SYN_LVAR_INTOX_THR, nThr);
    // Re-apply passive effects for persisted intox (no old threshold to remove)
    if(nThr > 0)
        SynApplyIntoxEffects(oPC, 0, nThr);
}

void SynOnHeartbeat(object oPC)
{
    int nTick = GetLocalInt(oPC, SYN_LVAR_HB_TICK) + 1;
    if(nTick < SYN_HB_DECAY_EVERY)
    {
        SetLocalInt(oPC, SYN_LVAR_HB_TICK, nTick);
        return;
    }
    SetLocalInt(oPC, SYN_LVAR_HB_TICK, 0);

    int nOldLevel = GetLocalInt(oPC, "SYN_INTOX_CACHE");
    if(nOldLevel <= 0) return;

    SynDecayIntox(oPC);
    int nNewLevel = GetLocalInt(oPC, "SYN_INTOX_CACHE");
    int nOldThr   = SynIntoxThreshold(nOldLevel);
    int nNewThr   = SynIntoxThreshold(nNewLevel);

    if(nOldThr != nNewThr)
    {
        SynApplyIntoxEffects(oPC, nOldThr, nNewThr);
        SetLocalInt(oPC, SYN_LVAR_INTOX_THR, nNewThr);
    }

    // Live-update the open window's intox bar
    int nToken = NuiFindWindow(oPC, SYN_WINDOW);
    if(nToken != 0)
        SynUpdateIntoxBar(oPC, nToken, nNewLevel);
}
