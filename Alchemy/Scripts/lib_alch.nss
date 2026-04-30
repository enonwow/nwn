// lib_alch.nss
// NUI window builder, feed functions and brewing logic for the Alchemy Workshop.
#include "lib_alch_def"

// ----------------------------------------------------------------
// NUI layout helpers (local; mirrors lib_nui.nss conventions)
// ----------------------------------------------------------------

float AlchScale(object oPC, float fDim, float fMax = 1.5)
{
    int nScale = GetPlayerDeviceProperty(oPC, PLAYER_DEVICE_PROPERTY_GUI_SCALE);
    float fS   = IntToFloat(nScale) / 100.0;
    if(fS > fMax) fS = fMax;
    return fDim / fS;
}

json AlchColor(int r, int g, int b)
{
    return NuiColor(r, g, b);
}

json AlchColorGold()  { return NuiColor(185, 150, 100); }
json AlchColorGreen() { return NuiColor( 80, 200,  80); }
json AlchColorRed()   { return NuiColor(220,  60,  60); }
json AlchColorGray()  { return NuiColor(100, 100, 100); }

json AlchSpacer(object oPC, float fH)
{
    json jItems = JsonArray();
    jItems = JsonArrayInsert(jItems, NuiHeight(NuiSpacer(), AlchScale(oPC, fH)));
    return NuiRow(jItems);
}

// ----------------------------------------------------------------
// Recipe list cell template (used by NuiList)
// ----------------------------------------------------------------

json AlchBuildRecipeCell(object oPC)
{
    float fLblH = AlchScale(oPC, 24.0);

    json jName = NuiLabel(
        NuiBind(ALCH_BIND_REC_NAME),
        JsonInt(NUI_HALIGN_LEFT),
        JsonInt(NUI_VALIGN_MIDDLE)
    );
    jName = NuiHeight(jName, fLblH);
    jName = NuiStyleForegroundColor(jName, NuiBind(ALCH_BIND_REC_COLOR));

    json jRow = JsonArray();
    jRow = JsonArrayInsert(jRow, NuiWidth(NuiSpacer(), AlchScale(oPC, 6.0)));
    jRow = JsonArrayInsert(jRow, jName);

    json jCell = NuiGroup(NuiRow(jRow), TRUE, NUI_SCROLLBARS_NONE);
    jCell = NuiId(jCell, ALCH_BTN_ROW);
    jCell = NuiEncouraged(jCell, NuiBind(ALCH_BIND_REC_ENC));

    json jTmpl = JsonArray();
    jTmpl = JsonArrayInsert(jTmpl, NuiListTemplateCell(jCell, 0.0, TRUE));
    return jTmpl;
}

// ----------------------------------------------------------------
// Ingredient row helper (inside detail panel)
// ----------------------------------------------------------------

json AlchBuildIngRow(object oPC, string sNameBind, string sHaveBind, string sColBind)
{
    float fH    = AlchScale(oPC, 20.0);
    float fNameW= AlchScale(oPC, 200.0);
    float fHaveW= AlchScale(oPC, 100.0);

    json jName = NuiLabel(
        NuiBind(sNameBind),
        JsonInt(NUI_HALIGN_LEFT),
        JsonInt(NUI_VALIGN_MIDDLE)
    );
    jName = NuiWidth(jName, fNameW);
    jName = NuiHeight(jName, fH);

    json jHave = NuiLabel(
        NuiBind(sHaveBind),
        JsonInt(NUI_HALIGN_RIGHT),
        JsonInt(NUI_VALIGN_MIDDLE)
    );
    jHave = NuiWidth(jHave, fHaveW);
    jHave = NuiHeight(jHave, fH);
    jHave = NuiStyleForegroundColor(jHave, NuiBind(sColBind));

    json jRow = JsonArray();
    jRow = JsonArrayInsert(jRow, jName);
    jRow = JsonArrayInsert(jRow, NuiSpacer());
    jRow = JsonArrayInsert(jRow, jHave);
    return NuiRow(jRow);
}

// ----------------------------------------------------------------
// Detail panel (right side)
// ----------------------------------------------------------------

json AlchBuildDetailPanel(object oPC)
{
    float fTitleH = AlchScale(oPC, 22.0);
    float fDescH  = AlchScale(oPC, 80.0);
    float fFlavH  = AlchScale(oPC, 44.0);
    float fLblH   = AlchScale(oPC, 20.0);
    float fBtnH   = AlchScale(oPC, 32.0);
    float fBtnW   = AlchScale(oPC, 200.0);
    float fPad    = AlchScale(oPC, 8.0);

    // --- Recipe title ---
    json jTitle = NuiLabel(
        NuiBind(ALCH_BIND_DET_NAME),
        JsonInt(NUI_HALIGN_CENTER),
        JsonInt(NUI_VALIGN_MIDDLE)
    );
    jTitle = NuiHeight(jTitle, fTitleH);
    jTitle = NuiStyleForegroundColor(jTitle, AlchColorGold());

    // --- "Locked" overlay label ---
    json jLocked = NuiLabel(
        NuiBind(ALCH_BIND_LOCKED_LBL),
        JsonInt(NUI_HALIGN_CENTER),
        JsonInt(NUI_VALIGN_MIDDLE)
    );
    jLocked = NuiHeight(jLocked, fLblH);
    jLocked = NuiStyleForegroundColor(jLocked, AlchColorRed());
    jLocked = NuiVisible(jLocked, NuiBind(ALCH_BIND_LOCKED_VIS));

    // --- Effect description ---
    json jDesc = NuiText(NuiBind(ALCH_BIND_DET_DESC), FALSE);
    jDesc = NuiHeight(jDesc, fDescH);

    // --- Flavor text ---
    json jFlav = NuiText(NuiBind(ALCH_BIND_DET_FLAV), FALSE);
    jFlav = NuiHeight(jFlav, fFlavH);
    jFlav = NuiStyleForegroundColor(jFlav, AlchColor(160, 130, 90));

    // --- Ingredient section header ---
    json jIngHdr = NuiLabel(
        JsonString("Składniki:"),
        JsonInt(NUI_HALIGN_LEFT),
        JsonInt(NUI_VALIGN_MIDDLE)
    );
    jIngHdr = NuiHeight(jIngHdr, fLblH);
    jIngHdr = NuiStyleForegroundColor(jIngHdr, AlchColorGold());

    // --- DC and skill labels ---
    json jDc = NuiLabel(
        NuiBind(ALCH_BIND_DC_LBL),
        JsonInt(NUI_HALIGN_LEFT),
        JsonInt(NUI_VALIGN_MIDDLE)
    );
    jDc = NuiHeight(jDc, fLblH);

    json jSkill = NuiLabel(
        NuiBind(ALCH_BIND_SKILL_LBL),
        JsonInt(NUI_HALIGN_LEFT),
        JsonInt(NUI_VALIGN_MIDDLE)
    );
    jSkill = NuiHeight(jSkill, fLblH);

    // --- Brew button ---
    json jBrew = NuiId(NuiButton(JsonString("Destyluj")), ALCH_BTN_BREW);
    jBrew = NuiEnabled(jBrew, NuiBind(ALCH_BIND_BREW_EN));
    jBrew = NuiWidth(jBrew, fBtnW);
    jBrew = NuiHeight(jBrew, fBtnH);

    json jBtnRow = JsonArray();
    jBtnRow = JsonArrayInsert(jBtnRow, NuiSpacer());
    jBtnRow = JsonArrayInsert(jBtnRow, jBrew);
    jBtnRow = JsonArrayInsert(jBtnRow, NuiSpacer());

    // --- Assemble column ---
    json jCol = JsonArray();
    jCol = JsonArrayInsert(jCol, jTitle);
    jCol = JsonArrayInsert(jCol, jLocked);
    jCol = JsonArrayInsert(jCol, AlchSpacer(oPC, 4.0));
    jCol = JsonArrayInsert(jCol, jDesc);
    jCol = JsonArrayInsert(jCol, jFlav);
    jCol = JsonArrayInsert(jCol, AlchSpacer(oPC, 4.0));
    jCol = JsonArrayInsert(jCol, jIngHdr);
    jCol = JsonArrayInsert(jCol, AlchBuildIngRow(oPC, ALCH_BIND_ING1_NAME, ALCH_BIND_ING1_HAVE, ALCH_BIND_ING1_COL));
    jCol = JsonArrayInsert(jCol, AlchBuildIngRow(oPC, ALCH_BIND_ING2_NAME, ALCH_BIND_ING2_HAVE, ALCH_BIND_ING2_COL));
    jCol = JsonArrayInsert(jCol, AlchBuildIngRow(oPC, ALCH_BIND_ING3_NAME, ALCH_BIND_ING3_HAVE, ALCH_BIND_ING3_COL));
    jCol = JsonArrayInsert(jCol, AlchSpacer(oPC, 4.0));
    jCol = JsonArrayInsert(jCol, jDc);
    jCol = JsonArrayInsert(jCol, jSkill);
    jCol = JsonArrayInsert(jCol, NuiSpacer());
    jCol = JsonArrayInsert(jCol, NuiRow(jBtnRow));
    jCol = JsonArrayInsert(jCol, AlchSpacer(oPC, 8.0));

    return NuiGroup(NuiCol(jCol), TRUE, NUI_SCROLLBARS_AUTO);
}

// ----------------------------------------------------------------
// Full window layout
// ----------------------------------------------------------------

json AlchBuildWindow(object oPC)
{
    float fRowH  = AlchScale(oPC, 28.0);
    float fListH = AlchScale(oPC, ALCH_WIN_H - 80.0);
    float fListW = AlchScale(oPC, 210.0);
    float fPad   = AlchScale(oPC, 10.0);
    float fBtnH  = AlchScale(oPC, 24.0);
    float fBtnW  = AlchScale(oPC, 80.0);

    // --- Left: recipe list ---
    json jList = NuiList(AlchBuildRecipeCell(oPC), NuiBind(ALCH_BIND_REC_COUNT), fRowH);
    jList = NuiHeight(jList, fListH);
    jList = NuiWidth(jList, fListW);

    // --- Right: detail panel ---
    json jDetail = AlchBuildDetailPanel(oPC);
    jDetail = NuiHeight(jDetail, fListH);

    // --- Close button row ---
    json jClose = NuiId(NuiButton(JsonString("Zamknij")), ALCH_BTN_CLOSE);
    jClose = NuiWidth(jClose, fBtnW);
    jClose = NuiHeight(jClose, fBtnH);

    json jCloseRow = JsonArray();
    jCloseRow = JsonArrayInsert(jCloseRow, NuiSpacer());
    jCloseRow = JsonArrayInsert(jCloseRow, jClose);

    // --- Content row (list + detail) ---
    json jContent = JsonArray();
    jContent = JsonArrayInsert(jContent, jList);
    jContent = JsonArrayInsert(jContent, NuiWidth(NuiSpacer(), fPad));
    jContent = JsonArrayInsert(jContent, jDetail);

    // --- Outer column ---
    json jOuter = JsonArray();
    jOuter = JsonArrayInsert(jOuter, AlchSpacer(oPC, 4.0));
    jOuter = JsonArrayInsert(jOuter, NuiRow(jContent));
    jOuter = JsonArrayInsert(jOuter, NuiRow(jCloseRow));
    jOuter = JsonArrayInsert(jOuter, AlchSpacer(oPC, 4.0));

    json jRoot = NuiCol(jOuter);

    float fW = AlchScale(oPC, ALCH_WIN_W);
    float fH = AlchScale(oPC, ALCH_WIN_H);

    return NuiWindow(
        jRoot,
        JsonString("Pracownia Alchemiczna"),
        NuiBind(ALCH_WINDOW + "_geom"),
        JsonBool(FALSE),
        JsonBool(FALSE),
        JsonBool(TRUE),
        JsonBool(FALSE),
        JsonBool(TRUE)
    );
}

// ----------------------------------------------------------------
// Feed recipe list
// ----------------------------------------------------------------

void FeedRecipeList(object oPC, int nToken)
{
    int nSel = GetLocalInt(oPC, ALCH_LVAR_SEL_IDX);

    json jNames  = JsonArray();
    json jEncs   = JsonArray();
    json jColors = JsonArray();

    int i;
    for(i = 0; i < ALCH_RECIPE_COUNT; i++)
    {
        int bKnown = AlchHasRecipe(oPC, i);
        string sName = bKnown ? AlchGetRecipeName(i) : "??? Nieznany Przepis ???";

        jNames  = JsonArrayInsert(jNames,  JsonString(sName));
        jEncs   = JsonArrayInsert(jEncs,   JsonBool(i == nSel));
        jColors = JsonArrayInsert(jColors, bKnown ? AlchColorGold() : AlchColorGray());
    }

    NuiSetBind(oPC, nToken, ALCH_BIND_REC_NAME,  jNames);
    NuiSetBind(oPC, nToken, ALCH_BIND_REC_ENC,   jEncs);
    NuiSetBind(oPC, nToken, ALCH_BIND_REC_COLOR, jColors);
    NuiSetBind(oPC, nToken, ALCH_BIND_REC_COUNT, JsonInt(ALCH_RECIPE_COUNT));
}

// ----------------------------------------------------------------
// Feed detail panel for selected recipe
// ----------------------------------------------------------------

void FeedDetailPanel(object oPC, int nToken, int nIdx)
{
    if(nIdx < 0 || nIdx >= ALCH_RECIPE_COUNT)
    {
        NuiSetBind(oPC, nToken, ALCH_BIND_DET_NAME,  JsonString("— Wybierz przepis —"));
        NuiSetBind(oPC, nToken, ALCH_BIND_DET_DESC,  JsonString(""));
        NuiSetBind(oPC, nToken, ALCH_BIND_DET_FLAV,  JsonString(""));
        NuiSetBind(oPC, nToken, ALCH_BIND_ING1_NAME, JsonString(""));
        NuiSetBind(oPC, nToken, ALCH_BIND_ING2_NAME, JsonString(""));
        NuiSetBind(oPC, nToken, ALCH_BIND_ING3_NAME, JsonString(""));
        NuiSetBind(oPC, nToken, ALCH_BIND_ING1_HAVE, JsonString(""));
        NuiSetBind(oPC, nToken, ALCH_BIND_ING2_HAVE, JsonString(""));
        NuiSetBind(oPC, nToken, ALCH_BIND_ING3_HAVE, JsonString(""));
        NuiSetBind(oPC, nToken, ALCH_BIND_ING1_COL,  AlchColorGray());
        NuiSetBind(oPC, nToken, ALCH_BIND_ING2_COL,  AlchColorGray());
        NuiSetBind(oPC, nToken, ALCH_BIND_ING3_COL,  AlchColorGray());
        NuiSetBind(oPC, nToken, ALCH_BIND_DC_LBL,    JsonString(""));
        NuiSetBind(oPC, nToken, ALCH_BIND_SKILL_LBL, JsonString(""));
        NuiSetBind(oPC, nToken, ALCH_BIND_BREW_EN,   JsonBool(FALSE));
        NuiSetBind(oPC, nToken, ALCH_BIND_LOCKED_LBL,JsonString(""));
        NuiSetBind(oPC, nToken, ALCH_BIND_LOCKED_VIS,JsonBool(FALSE));
        return;
    }

    int bKnown = AlchHasRecipe(oPC, nIdx);

    NuiSetBind(oPC, nToken, ALCH_BIND_DET_NAME, JsonString(AlchGetRecipeName(nIdx)));
    NuiSetBind(oPC, nToken, ALCH_BIND_LOCKED_LBL,
        JsonString(bKnown ? "" : "[ Przepis Zablokowany — Szukaj Zwoju Receptury ]"));
    NuiSetBind(oPC, nToken, ALCH_BIND_LOCKED_VIS, JsonBool(!bKnown));

    if(!bKnown)
    {
        NuiSetBind(oPC, nToken, ALCH_BIND_DET_DESC,  JsonString("Ten przepis jest ci nieznany."));
        NuiSetBind(oPC, nToken, ALCH_BIND_DET_FLAV,  JsonString(""));
        NuiSetBind(oPC, nToken, ALCH_BIND_ING1_NAME, JsonString("???"));
        NuiSetBind(oPC, nToken, ALCH_BIND_ING2_NAME, JsonString("???"));
        NuiSetBind(oPC, nToken, ALCH_BIND_ING3_NAME, JsonString("???"));
        NuiSetBind(oPC, nToken, ALCH_BIND_ING1_HAVE, JsonString(""));
        NuiSetBind(oPC, nToken, ALCH_BIND_ING2_HAVE, JsonString(""));
        NuiSetBind(oPC, nToken, ALCH_BIND_ING3_HAVE, JsonString(""));
        NuiSetBind(oPC, nToken, ALCH_BIND_ING1_COL,  AlchColorGray());
        NuiSetBind(oPC, nToken, ALCH_BIND_ING2_COL,  AlchColorGray());
        NuiSetBind(oPC, nToken, ALCH_BIND_ING3_COL,  AlchColorGray());
        NuiSetBind(oPC, nToken, ALCH_BIND_DC_LBL,    JsonString(""));
        NuiSetBind(oPC, nToken, ALCH_BIND_SKILL_LBL, JsonString(""));
        NuiSetBind(oPC, nToken, ALCH_BIND_BREW_EN,   JsonBool(FALSE));
        return;
    }

    string sIng1 = AlchGetRecipeIng1(nIdx);
    string sIng2 = AlchGetRecipeIng2(nIdx);
    string sIng3 = AlchGetRecipeIng3(nIdx);

    int nHave1 = AlchCountIngredient(oPC, sIng1);
    int nHave2 = AlchCountIngredient(oPC, sIng2);
    int nHave3 = AlchCountIngredient(oPC, sIng3);

    int bHaveAll = (nHave1 >= 1) && (nHave2 >= 1) && (nHave3 >= 1);

    NuiSetBind(oPC, nToken, ALCH_BIND_DET_DESC, JsonString(AlchGetRecipeDesc(nIdx)));
    NuiSetBind(oPC, nToken, ALCH_BIND_DET_FLAV, JsonString(AlchGetRecipeFlavor(nIdx)));

    NuiSetBind(oPC, nToken, ALCH_BIND_ING1_NAME, JsonString(AlchGetIngredientName(sIng1)));
    NuiSetBind(oPC, nToken, ALCH_BIND_ING2_NAME, JsonString(AlchGetIngredientName(sIng2)));
    NuiSetBind(oPC, nToken, ALCH_BIND_ING3_NAME, JsonString(AlchGetIngredientName(sIng3)));

    NuiSetBind(oPC, nToken, ALCH_BIND_ING1_HAVE, JsonString("masz: " + IntToString(nHave1)));
    NuiSetBind(oPC, nToken, ALCH_BIND_ING2_HAVE, JsonString("masz: " + IntToString(nHave2)));
    NuiSetBind(oPC, nToken, ALCH_BIND_ING3_HAVE, JsonString("masz: " + IntToString(nHave3)));

    NuiSetBind(oPC, nToken, ALCH_BIND_ING1_COL, nHave1 >= 1 ? AlchColorGreen() : AlchColorRed());
    NuiSetBind(oPC, nToken, ALCH_BIND_ING2_COL, nHave2 >= 1 ? AlchColorGreen() : AlchColorRed());
    NuiSetBind(oPC, nToken, ALCH_BIND_ING3_COL, nHave3 >= 1 ? AlchColorGreen() : AlchColorRed());

    int nDC     = AlchGetRecipeDC(nIdx);
    int nBonus  = AlchGetCraftBonus(oPC);
    NuiSetBind(oPC, nToken, ALCH_BIND_DC_LBL,    JsonString("Trudność: DC " + IntToString(nDC)));
    NuiSetBind(oPC, nToken, ALCH_BIND_SKILL_LBL,
        JsonString("Twój bonus: +" + IntToString(nBonus) + " (Wiedza Magiczna + INT)"));

    NuiSetBind(oPC, nToken, ALCH_BIND_BREW_EN, JsonBool(bHaveAll));
}

// ----------------------------------------------------------------
// Open window
// ----------------------------------------------------------------

void AlchOpenWindow(object oPC)
{
    int nToken = NuiFindWindow(oPC, ALCH_WINDOW);
    if(nToken != 0)
    {
        // Refresh data and bring to front
        FeedRecipeList(oPC, nToken);
        int nSel = GetLocalInt(oPC, ALCH_LVAR_SEL_IDX);
        FeedDetailPanel(oPC, nToken, nSel);
        return;
    }

    SetLocalInt(oPC, ALCH_LVAR_SEL_IDX, -1);

    nToken = NuiCreate(oPC, AlchBuildWindow(oPC), ALCH_WINDOW);
    if(nToken == 0) return;

    float fW = AlchScale(oPC, ALCH_WIN_W);
    float fH = AlchScale(oPC, ALCH_WIN_H);
    NuiSetBind(oPC, nToken, ALCH_WINDOW + "_geom",
        NuiRect(50.0, 100.0, fW, fH));

    FeedRecipeList(oPC, nToken);
    FeedDetailPanel(oPC, nToken, -1);

    SetEventScript(oPC, EVENT_SCRIPT_MODULE_ON_NUI_EVENT, ALCH_EV_SCRIPT);
}

// ----------------------------------------------------------------
// Brew — apply effect and consume ingredients
// ----------------------------------------------------------------

void AlchApplyEffect(object oPC, int nRecipeId)
{
    float fMin5  = 300.0;
    float fMin3  = 180.0;
    float fMin2  = 120.0;
    float fRound = 6.0;

    switch(nRecipeId)
    {
        case 0:
            // Nalewka Gojąca — instant heal 15 HP
            ApplyEffectToObject(DURATION_TYPE_INSTANT, EffectHeal(15), oPC);
            SendMessageToPC(oPC, "[Alchemia] Rana zastyga. Ciepło zalewa pierś.");
            break;

        case 1:
            // Odwar Mrocznego Wzroku — Ultravision + Spot +10 for 3min
            ApplyEffectToObject(DURATION_TYPE_TEMPORARY, EffectUltravision(),                      oPC, fMin3);
            ApplyEffectToObject(DURATION_TYPE_TEMPORARY, EffectSkillIncrease(SKILL_SPOT, 10),      oPC, fMin3);
            ApplyEffectToObject(DURATION_TYPE_TEMPORARY, EffectSkillIncrease(SKILL_LISTEN, 5),     oPC, fMin3);
            SendMessageToPC(oPC, "[Alchemia] Ciemność ustępuje. Widzisz każdy cień przez 3 minuty.");
            break;

        case 2:
            // Wywar Pancerza Krwi — AC +4 enchantment for 5min
            ApplyEffectToObject(DURATION_TYPE_TEMPORARY,
                EffectACIncrease(4, AC_ARMOUR_ENCHANTMENT_BONUS), oPC, fMin5);
            SendMessageToPC(oPC, "[Alchemia] Skóra twardnieje niczym żelazo. +4 do KP przez 5 minut.");
            break;

        case 3:
            // Eliksir Siły Ogra — STR +4 for 5min
            ApplyEffectToObject(DURATION_TYPE_TEMPORARY,
                EffectAbilityIncrease(ABILITY_STRENGTH, 4), oPC, fMin5);
            SendMessageToPC(oPC, "[Alchemia] Mięśnie nabrzmiewają. Siła +4 przez 5 minut.");
            break;

        case 4:
            // Wywar Cieni — Concealment 20% for 3min
            ApplyEffectToObject(DURATION_TYPE_TEMPORARY,
                EffectConcealment(20, MISS_CHANCE_TYPE_NORMAL), oPC, fMin3);
            SendMessageToPC(oPC, "[Alchemia] Kontury ciała rozmywają się w cieniu. 20%% zasłony przez 3 minuty.");
            break;

        case 5:
            // Odwar Odporności — all saves +2 for 5min
            ApplyEffectToObject(DURATION_TYPE_TEMPORARY,
                EffectSavingThrowIncrease(SAVING_THROW_ALL, 2, SAVING_THROW_TYPE_ALL), oPC, fMin5);
            SendMessageToPC(oPC, "[Alchemia] Wewnętrzna tarcza wzniesiona. Rzuty obronne +2 przez 5 minut.");
            break;

        case 6:
            // Eliksir Szybkości — Haste for 3 rounds (18s)
            ApplyEffectToObject(DURATION_TYPE_TEMPORARY, EffectHaste(), oPC, fRound * 3.0);
            SendMessageToPC(oPC, "[Alchemia] Rtęć śpiewa w żyłach. Haste przez 3 rundy.");
            break;

        case 7:
            // Wywar Ostrza — attack bonus +3 for 5min
            ApplyEffectToObject(DURATION_TYPE_TEMPORARY,
                EffectAttackIncrease(3, ATTACK_BONUS_MISC), oPC, fMin5);
            SendMessageToPC(oPC, "[Alchemia] Ręka prowadzi broń pewniej. Premia do ataku +3 przez 5 minut.");
            break;

        case 8:
            // Nalewka Czarnego Serca — Regenerate 2HP/6s for 5min
            ApplyEffectToObject(DURATION_TYPE_TEMPORARY, EffectRegenerate(2, 6.0), oPC, fMin5);
            SendMessageToPC(oPC, "[Alchemia] Ciemne ciepło pełznie przez żyły. Regeneracja 2 PŻ / rundę przez 5 minut.");
            break;

        default: break;
    }
}

void AlchBrew(object oPC, int nToken, int nRecipeId)
{
    if(!AlchHasRecipe(oPC, nRecipeId))
    {
        SendMessageToPC(oPC, "[Alchemia] Nie znasz tego przepisu.");
        return;
    }

    string sIng1 = AlchGetRecipeIng1(nRecipeId);
    string sIng2 = AlchGetRecipeIng2(nRecipeId);
    string sIng3 = AlchGetRecipeIng3(nRecipeId);

    if(AlchCountIngredient(oPC, sIng1) < 1 ||
       AlchCountIngredient(oPC, sIng2) < 1 ||
       AlchCountIngredient(oPC, sIng3) < 1)
    {
        SendMessageToPC(oPC, "[Alchemia] Brakuje składników.");
        FeedDetailPanel(oPC, nToken, nRecipeId);
        return;
    }

    int nDC    = AlchGetRecipeDC(nRecipeId);
    int nBonus = AlchGetCraftBonus(oPC);
    int nRoll  = d20(1);
    int nTotal = nRoll + nBonus;

    // Always consume ingredients
    AlchTakeIngredient(oPC, sIng1);
    AlchTakeIngredient(oPC, sIng2);
    AlchTakeIngredient(oPC, sIng3);

    if(nRoll == 1 || (nTotal < nDC && nRoll != 20))
    {
        // Failure — ingredients wasted
        string sMsg = "[Alchemia] Destylacja nieudana (rzut: "
            + IntToString(nRoll) + "+" + IntToString(nBonus)
            + "=" + IntToString(nTotal) + " vs DC " + IntToString(nDC)
            + "). Składniki zmarnowane.";
        SendMessageToPC(oPC, sMsg);

        // Critical fumble on natural 1: HP penalty from fume inhalation
        if(nRoll == 1)
        {
            int nFumeDmg = d6(1) + 2;
            ApplyEffectToObject(DURATION_TYPE_INSTANT, EffectDamage(nFumeDmg, DAMAGE_TYPE_ACID), oPC);
            SendMessageToPC(oPC, "[Alchemia] Opary alchemiczne atakują gardło! Obrażenia: "
                + IntToString(nFumeDmg) + ".");
        }
    }
    else
    {
        // Success
        int bCritSuccess = (nTotal >= nDC + 10 || nRoll == 20);

        string sMsg = "[Alchemia] Destylacja udana (rzut: "
            + IntToString(nRoll) + "+" + IntToString(nBonus)
            + "=" + IntToString(nTotal) + " vs DC " + IntToString(nDC) + ").";
        if(bCritSuccess) sMsg += " Mistrzostwo!";
        SendMessageToPC(oPC, sMsg);

        AlchApplyEffect(oPC, nRecipeId);

        // Critical success: apply effect a second time (double potency)
        if(bCritSuccess)
        {
            AlchApplyEffect(oPC, nRecipeId);
            SendMessageToPC(oPC, "[Alchemia] Podwójne działanie mikstury!");
        }
    }

    FeedDetailPanel(oPC, nToken, nRecipeId);
    FeedRecipeList(oPC, nToken);
}
