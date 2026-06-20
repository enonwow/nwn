// lib_oath.nss — NUI layout, effect logic and violation checking for Sacred Oaths

#include "lib_oath_def"

// ================================================================
// Text helpers
// ================================================================

string OathGetName(int nId)
{
    switch(nId)
    {
        case OATH_POVERTY:   return "Przysięga Ubóstwa";
        case OATH_IRON:      return "Przysięga Żelaza";
        case OATH_VENGEANCE: return "Przysięga Zemsty";
        case OATH_BLOOD:     return "Przysięga Krwi";
        case OATH_SILENCE:   return "Przysięga Milczenia";
    }
    return "Nieznana Przysięga";
}

string OathGetBonusText(int nId)
{
    switch(nId)
    {
        case OATH_POVERTY:
            return "+2 Mądrości, +2 Charyzmy, +1 do wszystkich rzutów obronnych";
        case OATH_IRON:
            return "+4 do naturalnej klasy pancerza, +2 Kondycji";
        case OATH_VENGEANCE:
            return "+4 do testów ataku, +2k6 obrażeń magicznych przy każdym trafieniu";
        case OATH_BLOOD:
            return "Odporność na Strach i efekty mentalne, +3 Siły";
        case OATH_SILENCE:
            return "+5 do Ukrywania się, +5 do Cichego poruszania, +2 Zręczności";
    }
    return "";
}

string OathGetRestrText(int nId)
{
    switch(nId)
    {
        case OATH_POVERTY:
            return "Nie możesz posiadać więcej niż " + IntToString(OATH_POVERTY_CAP)
                 + " sz.z. — nadmiar zostanie wykryty i policzy się jako naruszenie.";
        case OATH_IRON:
            return "Nie możesz nosić zbroi (bazowa KP > 0). "
                 + "Każde wykrycie zbroi liczy się jako naruszenie.";
        case OATH_VENGEANCE:
            return "Nie możesz uciekać z walki z wrogiem, gdy masz więcej niż 25% HP. "
                 + "Kodeks honorowy — system nie egzekwuje automatycznie.";
        case OATH_BLOOD:
            return "Co ~60 sekund tracisz " + IntToString(OATH_BLOOD_DRAIN_PCT)
                 + "% maksymalnych PŻ. Krew jest ceną potęgi.";
        case OATH_SILENCE:
            return "Nie możesz rzucać zaklęć werbalnych ani używać głosu w walce. "
                 + "Kodeks honorowy — system nie egzekwuje automatycznie.";
    }
    return "";
}

string OathGetLoreText(int nId)
{
    switch(nId)
    {
        case OATH_POVERTY:
            return "„Bogactwo jest łańcuchem duszy. Kto wyrzeka się złota, "
                 + "otwiera serce na moc wyższą niż metal i ziemia."";
        case OATH_IRON:
            return "„Twoje ciało jest tarczą. Każda blizna to lekcja przeżyta. "
                 + "Stal na plecach to słabość umysłu — prawdziwy wojownik jej nie potrzebuje."";
        case OATH_VENGEANCE:
            return "„Krew za krew. Śmierć za śmierć. Kto raz obrał cel, "
                 + "nie spocznie, nie ucieknie, nie wyrzeknie się — aż wyrок zostanie spełniony."";
        case OATH_BLOOD:
            return "„Potęga drzemie w każdej kropli. Przelej swoją — "
                 + "a staniesz się niezłomny. Lub zgniły. Bogowie nie rozróżniają."";
        case OATH_SILENCE:
            return "„Słowa są bronią głupców i modlitwą tchórzy. "
                 + "Prawdziwa siła milczy, obserwuje i uderza raz — nieomylnie."";
    }
    return "";
}

int OathGetCost(int nId)
{
    switch(nId)
    {
        case OATH_POVERTY:   return OATH_COST_POVERTY;
        case OATH_IRON:      return OATH_COST_IRON;
        case OATH_VENGEANCE: return OATH_COST_VENGEANCE;
        case OATH_BLOOD:     return OATH_COST_BLOOD;
        case OATH_SILENCE:   return OATH_COST_SILENCE;
    }
    return 0;
}

// ================================================================
// Effect management
// ================================================================

effect OathTag(effect e)
{
    return TagEffect(e, OATH_EFFECT_TAG);
}

void OathRemoveEffects(object oPC)
{
    effect e = GetFirstEffect(oPC);
    while(GetIsEffectValid(e))
    {
        effect eNext = GetNextEffect(oPC);
        if(GetEffectTag(e) == OATH_EFFECT_TAG)
            RemoveEffect(oPC, e);
        e = eNext;
    }
}

void OathRemoveCurse(object oPC)
{
    effect e = GetFirstEffect(oPC);
    while(GetIsEffectValid(e))
    {
        effect eNext = GetNextEffect(oPC);
        if(GetEffectTag(e) == OATH_CURSE_TAG)
            RemoveEffect(oPC, e);
        e = eNext;
    }
}

void OathApplyCurse(object oPC)
{
    // -2 to all six ability scores; skill penalties follow automatically via ability mods
    effect eCurse = TagEffect(EffectCurse(2, 2, 2, 2, 2, 2), OATH_CURSE_TAG);
    ApplyEffectToObject(DURATION_TYPE_PERMANENT, eCurse, oPC);
}

void OathApplyEffects(object oPC, int nOathId)
{
    OathRemoveEffects(oPC);
    if(nOathId <= 0) return;

    switch(nOathId)
    {
        case OATH_POVERTY:
            ApplyEffectToObject(DURATION_TYPE_PERMANENT,
                OathTag(EffectAbilityIncrease(ABILITY_WISDOM, 2)), oPC);
            ApplyEffectToObject(DURATION_TYPE_PERMANENT,
                OathTag(EffectAbilityIncrease(ABILITY_CHARISMA, 2)), oPC);
            ApplyEffectToObject(DURATION_TYPE_PERMANENT,
                OathTag(EffectSavingThrowIncrease(SAVING_THROW_ALL, 1, SAVING_THROW_TYPE_ALL)), oPC);
            break;

        case OATH_IRON:
            ApplyEffectToObject(DURATION_TYPE_PERMANENT,
                OathTag(EffectACIncrease(4, AC_NATURAL_BONUS)), oPC);
            ApplyEffectToObject(DURATION_TYPE_PERMANENT,
                OathTag(EffectAbilityIncrease(ABILITY_CONSTITUTION, 2)), oPC);
            break;

        case OATH_VENGEANCE:
            ApplyEffectToObject(DURATION_TYPE_PERMANENT,
                OathTag(EffectAttackIncrease(4)), oPC);
            ApplyEffectToObject(DURATION_TYPE_PERMANENT,
                OathTag(EffectDamageIncrease(DAMAGE_BONUS_2d6, DAMAGE_TYPE_MAGICAL)), oPC);
            break;

        case OATH_BLOOD:
            ApplyEffectToObject(DURATION_TYPE_PERMANENT,
                OathTag(EffectImmunity(IMMUNITY_TYPE_FEAR)), oPC);
            ApplyEffectToObject(DURATION_TYPE_PERMANENT,
                OathTag(EffectImmunity(IMMUNITY_TYPE_MIND_SPELLS)), oPC);
            ApplyEffectToObject(DURATION_TYPE_PERMANENT,
                OathTag(EffectAbilityIncrease(ABILITY_STRENGTH, 3)), oPC);
            break;

        case OATH_SILENCE:
            ApplyEffectToObject(DURATION_TYPE_PERMANENT,
                OathTag(EffectSkillIncrease(SKILL_HIDE, 5)), oPC);
            ApplyEffectToObject(DURATION_TYPE_PERMANENT,
                OathTag(EffectSkillIncrease(SKILL_MOVE_SILENTLY, 5)), oPC);
            ApplyEffectToObject(DURATION_TYPE_PERMANENT,
                OathTag(EffectAbilityIncrease(ABILITY_DEXTERITY, 2)), oPC);
            break;
    }
}

// ================================================================
// Oath break
// ================================================================

void OathBreak(object oPC, string sReason)
{
    int nOathId = OathGetActive(oPC);
    if(nOathId <= 0) return;

    OathRemoveEffects(oPC);
    OathDbMarkBroken(oPC);

    OathApplyCurse(oPC);
    ApplyEffectToObject(DURATION_TYPE_INSTANT,
        EffectVisualEffect(VFX_IMP_DOOM), oPC);

    FloatingTextStringOnCreature(
        "Pieczęć pęka — " + OathGetName(nOathId) + " zerwana! " + sReason
        + " Bogowie odwracają oblicza.", oPC, FALSE);

    SendMessageToPC(oPC, "[Przysięgi] Przysięga zerwana. Nosisz piętno krzywoprzysięzcy "
        "(-2 do wszystkich atrybutów). Odkup się za "
        + IntToString(OATH_COST_ATONE) + " sz.z. w Kaplicy.");

    int nToken = NuiFindWindow(oPC, OATH_WINDOW);
    if(nToken != 0)
    {
        FeedOathStatus(oPC, nToken);
        FeedOathDetail(oPC, nToken, GetLocalInt(oPC, OATH_LVAR_SEL));
    }
}

// ================================================================
// Violation checking (called from module heartbeat)
// ================================================================

void OathCheckViolations(object oPC)
{
    int nOathId = OathGetActive(oPC);
    if(nOathId <= 0) return;

    int bViolated = FALSE;
    string sReason = "";

    switch(nOathId)
    {
        case OATH_POVERTY:
        {
            int nGold = GetGold(oPC);
            if(nGold > OATH_POVERTY_CAP)
            {
                bViolated = TRUE;
                sReason = "Posiadasz " + IntToString(nGold) + " sz.z. (limit: "
                        + IntToString(OATH_POVERTY_CAP) + ").";
            }
            break;
        }
        case OATH_IRON:
        {
            object oChest = GetItemInSlot(INVENTORY_SLOT_CHEST, oPC);
            if(GetIsObjectValid(oChest) && GetBaseAC(oChest) > 0)
            {
                bViolated = TRUE;
                sReason = "Nosisz zbroję — ciało powinno być jedyną tarczą.";
            }
            break;
        }
        case OATH_BLOOD:
        {
            int nMaxHP  = GetMaxHitPoints(oPC);
            int nDrain  = max(1, nMaxHP * OATH_BLOOD_DRAIN_PCT / 100);
            if(GetCurrentHitPoints(oPC) > nDrain + 5)
            {
                ApplyEffectToObject(DURATION_TYPE_INSTANT,
                    EffectDamage(nDrain, DAMAGE_TYPE_MAGICAL, DAMAGE_POWER_NORMAL), oPC);
                ApplyEffectToObject(DURATION_TYPE_TEMPORARY,
                    EffectVisualEffect(VFX_DUR_BLUR), oPC, 1.5);
            }
            // Blood drain is a cost, not a violation — oath never breaks from it
            return;
        }
        // OATH_VENGEANCE and OATH_SILENCE are honour-system only
    }

    if(bViolated)
    {
        OathDbViolation(oPC);
        int nViol = OathGetViolations(oPC);

        if(nViol >= OATH_MAX_VIOLATIONS)
        {
            OathBreak(oPC, sReason);
        }
        else
        {
            FloatingTextStringOnCreature(
                "Ostrzeżenie przysięgi: " + sReason
                + " [Naruszenia: " + IntToString(nViol) + "/"
                + IntToString(OATH_MAX_VIOLATIONS) + "]", oPC, FALSE);
        }
    }
}

// ================================================================
// Login restore
// ================================================================

void OathRestoreOnLogin(object oPC)
{
    int nOathId = OathGetActive(oPC);
    if(nOathId > 0)
    {
        OathApplyEffects(oPC, nOathId);
        SendMessageToPC(oPC, "[Przysięgi] Aktywna przysięga: " + OathGetName(nOathId)
            + ". Niechaj bogowie będą świadkami.");
        return;
    }
    if(OathIsBroken(oPC))
    {
        OathApplyCurse(oPC);
        SendMessageToPC(oPC, "[Przysięgi] Nosisz piętno krzywoprzysięzcy. "
            "Odkup się za " + IntToString(OATH_COST_ATONE) + " sz.z. u kapłana.");
    }
}

// ================================================================
// NUI: feed functions
// ================================================================

void FeedOathStatus(object oPC, int nToken)
{
    int nActive = OathGetActive(oPC);
    int nBroken = OathIsBroken(oPC);
    string sText;
    json jColor;

    if(nBroken)
    {
        sText  = "PIĘTNO KRZYWOPRZYSIĘZCY — odkup się za " + IntToString(OATH_COST_ATONE) + " sz.z.";
        jColor = NuiColor(210, 50, 50);
    }
    else if(nActive > 0)
    {
        int nViol  = OathGetViolations(oPC);
        int nSworn = OathGetSwornAt(oPC);
        sText = OathGetName(nActive) + "  ·  przysięga od: " + OathDaysSince(nSworn) + " dni";
        if(nViol > 0)
            sText = sText + "  ·  naruszenia: " + IntToString(nViol) + "/" + IntToString(OATH_MAX_VIOLATIONS);
        jColor = NuiColor(110, 210, 90);
    }
    else
    {
        sText  = "Brak aktywnej przysięgi";
        jColor = NuiColor(155, 155, 155);
    }

    NuiSetBind(oPC, nToken, OATH_BIND_ACTIVE_LBL, JsonString(sText));
    NuiSetBind(oPC, nToken, OATH_BIND_ACTIVE_COL, jColor);
}

void FeedOathDetail(object oPC, int nToken, int nOathId)
{
    if(nOathId <= 0)
    {
        NuiSetBind(oPC, nToken, OATH_BIND_DET_NAME,  JsonString(""));
        NuiSetBind(oPC, nToken, OATH_BIND_DET_BONUS,  JsonString(""));
        NuiSetBind(oPC, nToken, OATH_BIND_DET_RESTR,  JsonString(""));
        NuiSetBind(oPC, nToken, OATH_BIND_DET_LORE,
            JsonString("Wybierz przysięgę z listy, aby poznać jej moc i cenę."));
        NuiSetBind(oPC, nToken, OATH_BIND_DET_COST,  JsonString(""));
        NuiSetBind(oPC, nToken, OATH_BIND_SWEAR_ENA, JsonBool(FALSE));
        NuiSetBind(oPC, nToken, OATH_BIND_SWEAR_LBL, JsonString("Złóż Przysięgę"));
        NuiSetBind(oPC, nToken, OATH_BIND_REN_ENA,   JsonBool(FALSE));
        return;
    }

    int nActive  = OathGetActive(oPC);
    int nBroken  = OathIsBroken(oPC);
    int nCost    = OathGetCost(nOathId);
    int bIsActive = (nActive == nOathId);

    NuiSetBind(oPC, nToken, OATH_BIND_DET_NAME,  JsonString(OathGetName(nOathId)));
    NuiSetBind(oPC, nToken, OATH_BIND_DET_BONUS,  JsonString("Premie:  " + OathGetBonusText(nOathId)));
    NuiSetBind(oPC, nToken, OATH_BIND_DET_RESTR,  JsonString("Ograniczenie:  " + OathGetRestrText(nOathId)));
    NuiSetBind(oPC, nToken, OATH_BIND_DET_LORE,   JsonString(OathGetLoreText(nOathId)));

    string sCostLine = (nCost > 0)
        ? "Koszt złożenia: " + IntToString(nCost) + " sz.z."
        : "Koszt złożenia: brak złota — tylko krew.";
    NuiSetBind(oPC, nToken, OATH_BIND_DET_COST, JsonString(sCostLine));

    int bCanSwear = (nActive == 0) && !nBroken && (GetGold(oPC) >= nCost);

    NuiSetBind(oPC, nToken, OATH_BIND_SWEAR_ENA, JsonBool(bCanSwear));
    NuiSetBind(oPC, nToken, OATH_BIND_SWEAR_LBL,
        JsonString(bIsActive ? "▶  Aktywna przysięga" : "Złóż Przysięgę"));
    NuiSetBind(oPC, nToken, OATH_BIND_REN_ENA, JsonBool(bIsActive));
}

void FeedOathRows(object oPC, int nToken, int nSelectedId)
{
    int i;
    for(i = 1; i <= OATH_COUNT; i++)
        NuiSetBind(oPC, nToken, OATH_BIND_ROW_ENC + IntToString(i), JsonBool(i == nSelectedId));
}

// ================================================================
// NUI: layout builders
// ================================================================

json BuildOathLeftPanel(object oPC)
{
    float fRowH  = GetNuiScaleDimension(oPC, 42.0);
    float fPanW  = GetNuiScaleDimension(oPC, 220.0);
    float fHdrH  = GetNuiScaleDimension(oPC, 26.0);

    json jCol = JsonArray();

    json jHdr = NuiLabel(JsonString("Dostępne przysięgi"),
        JsonInt(NUI_HALIGN_CENTER), JsonInt(NUI_VALIGN_MIDDLE));
    jHdr = NuiHeight(jHdr, fHdrH);
    jHdr = NuiStyleForegroundColor(jHdr, GetNuiColorNwnGold());
    jCol = JsonArrayInsert(jCol, NuiRow(JsonArrayInsert(JsonArray(), jHdr)));

    int i;
    for(i = 1; i <= OATH_COUNT; i++)
    {
        json jLbl = NuiLabel(JsonString(OathGetName(i)),
            JsonInt(NUI_HALIGN_LEFT), JsonInt(NUI_VALIGN_MIDDLE));

        json jCells = JsonArray();
        jCells = JsonArrayInsert(jCells, NuiSpacer());
        jCells = JsonArrayInsert(jCells, jLbl);

        json jGroup = NuiGroup(NuiRow(jCells), FALSE, NUI_SCROLLBARS_NONE);
        jGroup = NuiId(jGroup, OATH_BTN_ROW + IntToString(i));
        jGroup = NuiHeight(jGroup, fRowH);
        jGroup = NuiEncouraged(jGroup, NuiBind(OATH_BIND_ROW_ENC + IntToString(i)));

        jCol = JsonArrayInsert(jCol, jGroup);
    }

    json jPanel = NuiGroup(NuiCol(jCol), TRUE, NUI_SCROLLBARS_NONE);
    jPanel = NuiWidth(jPanel, fPanW);
    return jPanel;
}

json BuildOathRightPanel(object oPC)
{
    float fBtnH  = GetNuiScaleDimension(oPC, 30.0);
    float fNameH = GetNuiScaleDimension(oPC, 30.0);
    float fLoreH = GetNuiScaleDimension(oPC, 64.0);
    float fBonH  = GetNuiScaleDimension(oPC, 52.0);
    float fResH  = GetNuiScaleDimension(oPC, 60.0);
    float fCostH = GetNuiScaleDimension(oPC, 24.0);

    json jCol = JsonArray();

    // Oath name
    json jName = NuiLabel(NuiBind(OATH_BIND_DET_NAME),
        JsonInt(NUI_HALIGN_LEFT), JsonInt(NUI_VALIGN_MIDDLE));
    jName = NuiHeight(jName, fNameH);
    jName = NuiStyleForegroundColor(jName, GetNuiColorNwnGold());
    jCol = JsonArrayInsert(jCol, NuiRow(JsonArrayInsert(JsonArray(), jName)));

    jCol = JsonArrayInsert(jCol, CreateEmptyRow(oPC, 4.0));

    // Lore quote
    json jLore = NuiLabel(NuiBind(OATH_BIND_DET_LORE),
        JsonInt(NUI_HALIGN_LEFT), JsonInt(NUI_VALIGN_TOP));
    jLore = NuiHeight(jLore, fLoreH);
    jLore = NuiStyleForegroundColor(jLore, NuiColor(190, 180, 155));
    jCol = JsonArrayInsert(jCol, NuiRow(JsonArrayInsert(JsonArray(), jLore)));

    jCol = JsonArrayInsert(jCol, CreateEmptyRow(oPC, 6.0));

    // Bonus description
    json jBonus = NuiLabel(NuiBind(OATH_BIND_DET_BONUS),
        JsonInt(NUI_HALIGN_LEFT), JsonInt(NUI_VALIGN_TOP));
    jBonus = NuiHeight(jBonus, fBonH);
    jBonus = NuiStyleForegroundColor(jBonus, NuiColor(90, 215, 90));
    jCol = JsonArrayInsert(jCol, NuiRow(JsonArrayInsert(JsonArray(), jBonus)));

    jCol = JsonArrayInsert(jCol, CreateEmptyRow(oPC, 4.0));

    // Restriction description
    json jRestr = NuiLabel(NuiBind(OATH_BIND_DET_RESTR),
        JsonInt(NUI_HALIGN_LEFT), JsonInt(NUI_VALIGN_TOP));
    jRestr = NuiHeight(jRestr, fResH);
    jRestr = NuiStyleForegroundColor(jRestr, NuiColor(215, 90, 90));
    jCol = JsonArrayInsert(jCol, NuiRow(JsonArrayInsert(JsonArray(), jRestr)));

    jCol = JsonArrayInsert(jCol, CreateEmptyRow(oPC, 4.0));

    // Cost line
    json jCost = NuiLabel(NuiBind(OATH_BIND_DET_COST),
        JsonInt(NUI_HALIGN_LEFT), JsonInt(NUI_VALIGN_MIDDLE));
    jCost = NuiHeight(jCost, fCostH);
    jCost = NuiStyleForegroundColor(jCost, NuiColor(200, 165, 75));
    jCol = JsonArrayInsert(jCol, NuiRow(JsonArrayInsert(JsonArray(), jCost)));

    jCol = JsonArrayInsert(jCol, CreateEmptyRow(oPC, 10.0));

    // Button row: [Złóż Przysięgę]  spacer  [Wyrzeknij się]
    json jSwear = NuiButton(NuiBind(OATH_BIND_SWEAR_LBL));
    jSwear = NuiId(jSwear, OATH_BTN_SWEAR);
    jSwear = NuiEnabled(jSwear, NuiBind(OATH_BIND_SWEAR_ENA));
    jSwear = NuiHeight(jSwear, fBtnH);

    json jRenounce = NuiButton(JsonString("Wyrzeknij się"));
    jRenounce = NuiId(jRenounce, OATH_BTN_RENOUNCE);
    jRenounce = NuiEnabled(jRenounce, NuiBind(OATH_BIND_REN_ENA));
    jRenounce = NuiHeight(jRenounce, fBtnH);
    jRenounce = NuiWidth(jRenounce, GetNuiScaleDimension(oPC, 130.0));

    json jBtnRow = JsonArray();
    jBtnRow = JsonArrayInsert(jBtnRow, jSwear);
    jBtnRow = JsonArrayInsert(jBtnRow, NuiSpacer());
    jBtnRow = JsonArrayInsert(jBtnRow, jRenounce);
    jCol = JsonArrayInsert(jCol, NuiRow(jBtnRow));

    return NuiGroup(NuiCol(jCol), FALSE, NUI_SCROLLBARS_NONE);
}

// ================================================================
// NUI: open window
// ================================================================

void OathOpenWindow(object oPC)
{
    int nExist = NuiFindWindow(oPC, OATH_WINDOW);
    if(nExist != 0)
    {
        NuiDestroy(oPC, nExist);
    }

    float fGuiW = IntToFloat(GetPlayerDeviceProperty(oPC, PLAYER_DEVICE_PROPERTY_GUI_WIDTH));
    float fGuiH = IntToFloat(GetPlayerDeviceProperty(oPC, PLAYER_DEVICE_PROPERTY_GUI_HEIGHT));
    float fW    = GetNuiScaleDimension(oPC, OATH_W);
    float fH    = GetNuiScaleDimension(oPC, OATH_H);
    float fCX   = (fGuiW - fW) / 2.0;
    float fCY   = (fGuiH - fH) / 2.0;

    // ---- Status bar row ----
    json jStatusLbl = NuiLabel(NuiBind(OATH_BIND_ACTIVE_LBL),
        JsonInt(NUI_HALIGN_LEFT), JsonInt(NUI_VALIGN_MIDDLE));
    jStatusLbl = NuiStyleForegroundColor(jStatusLbl, NuiBind(OATH_BIND_ACTIVE_COL));
    jStatusLbl = NuiHeight(jStatusLbl, GetNuiScaleDimension(oPC, 24.0));

    json jAtone = NuiButton(JsonString("Odkup się"));
    jAtone = NuiId(jAtone, OATH_BTN_ATONE);
    jAtone = NuiWidth(jAtone, GetNuiScaleDimension(oPC, 110.0));
    jAtone = NuiHeight(jAtone, GetNuiScaleDimension(oPC, 24.0));

    json jClose = NuiButton(JsonString("✕"));
    jClose = NuiId(jClose, OATH_BTN_CLOSE);
    jClose = NuiWidth(jClose, GetNuiScaleDimension(oPC, 28.0));
    jClose = NuiHeight(jClose, GetNuiScaleDimension(oPC, 24.0));

    json jTopRow = JsonArray();
    jTopRow = JsonArrayInsert(jTopRow, jStatusLbl);
    jTopRow = JsonArrayInsert(jTopRow, jAtone);
    jTopRow = JsonArrayInsert(jTopRow, jClose);

    // ---- Main content ----
    json jContent = JsonArray();
    jContent = JsonArrayInsert(jContent, BuildOathLeftPanel(oPC));
    jContent = JsonArrayInsert(jContent, BuildOathRightPanel(oPC));

    // ---- Root layout ----
    json jRoot = JsonArray();
    jRoot = JsonArrayInsert(jRoot, NuiRow(jTopRow));
    jRoot = JsonArrayInsert(jRoot, CreateEmptyRow(oPC, 4.0));
    jRoot = JsonArrayInsert(jRoot, NuiRow(jContent));

    json jWin = NuiWindow(
        NuiCol(jRoot),
        JsonString("Kaplica Przysiąg"),
        NuiRect(fCX, fCY, fW, fH),
        JsonBool(FALSE),
        JsonBool(FALSE),
        JsonBool(TRUE),
        JsonBool(FALSE),
        JsonBool(TRUE));

    int nToken = NuiCreate(oPC, jWin, OATH_WINDOW, OATH_EV_SCRIPT);
    if(nToken == 0) return;

    SetLocalInt(oPC, OATH_LVAR_SEL, 0);
    FeedOathStatus(oPC, nToken);
    FeedOathRows(oPC, nToken, 0);
    FeedOathDetail(oPC, nToken, 0);
}

// ================================================================
// NUI: confirm popup
// ================================================================

void OathCreateConfirmPopup(object oPC, int nOathId, string sType)
{
    int nExist = NuiFindWindow(oPC, OATH_WIN_CONFIRM);
    if(nExist != 0) NuiDestroy(oPC, nExist);

    SetLocalString(oPC, OATH_LVAR_CONFIRM, sType);

    string sMsg;
    if(sType == "swear")
    {
        int nCost = OathGetCost(nOathId);
        sMsg = "Złożyć " + OathGetName(nOathId) + "?\n"
             + (nCost > 0 ? "Koszt: " + IntToString(nCost) + " sz.z.\n" : "Koszt: krew.\n")
             + "Bogowie będą świadkami. Nie ma odwrotu bez piętna.";
    }
    else if(sType == "renounce")
    {
        sMsg = "Wyrzec się " + OathGetName(nOathId) + "?\n"
             + "Złamanie przysięgi sprowadzi klątwę i piętno krzywoprzysięzcy.\n"
             + "Jesteś pewien?";
    }
    else
    {
        sMsg = "Odkupić winę krzywoprzysięzcy za " + IntToString(OATH_COST_ATONE) + " sz.z.?\n"
             + "Piętno zostanie zdjęte i będziesz mógł złożyć nową przysięgę.";
    }

    float fPW = GetNuiScaleDimension(oPC, 370.0);
    float fPH = GetNuiScaleDimension(oPC, 180.0);
    float fBH = GetNuiScaleDimension(oPC, 32.0);

    json jMsg = NuiLabel(NuiBind(OATH_BIND_CONF_MSG),
        JsonInt(NUI_HALIGN_CENTER), JsonInt(NUI_VALIGN_MIDDLE));
    jMsg = NuiHeight(jMsg, GetNuiScaleDimension(oPC, 90.0));

    json jYes = NuiButton(JsonString("Tak, potwierdzam"));
    jYes = NuiId(jYes, OATH_BTN_YES);
    jYes = NuiHeight(jYes, fBH);

    json jNo = NuiButton(JsonString("Nie, rezygnuję"));
    jNo = NuiId(jNo, OATH_BTN_NO);
    jNo = NuiHeight(jNo, fBH);

    json jBtns = JsonArray();
    jBtns = JsonArrayInsert(jBtns, jYes);
    jBtns = JsonArrayInsert(jBtns, jNo);

    json jLayout = JsonArray();
    jLayout = JsonArrayInsert(jLayout, NuiRow(JsonArrayInsert(JsonArray(), jMsg)));
    jLayout = JsonArrayInsert(jLayout, NuiRow(jBtns));

    float fGuiW = IntToFloat(GetPlayerDeviceProperty(oPC, PLAYER_DEVICE_PROPERTY_GUI_WIDTH));
    float fGuiH = IntToFloat(GetPlayerDeviceProperty(oPC, PLAYER_DEVICE_PROPERTY_GUI_HEIGHT));

    json jWin = NuiWindow(
        NuiCol(jLayout),
        JsonString("Potwierdzenie"),
        NuiRect((fGuiW - fPW) / 2.0, (fGuiH - fPH) / 2.0, fPW, fPH),
        JsonBool(FALSE),
        JsonBool(FALSE),
        JsonBool(FALSE),
        JsonBool(FALSE),
        JsonBool(TRUE));

    int nToken = NuiCreate(oPC, jWin, OATH_WIN_CONFIRM, OATH_EV_SCRIPT);
    if(nToken != 0)
        NuiSetBind(oPC, nToken, OATH_BIND_CONF_MSG, JsonString(sMsg));
}

// ================================================================
// Swear / Renounce / Atone
// ================================================================

void OathDoSwear(object oPC, int nOathId)
{
    int nCost = OathGetCost(nOathId);

    if(GetGold(oPC) < nCost)
    {
        SendMessageToPC(oPC, "[Przysięgi] Potrzebujesz " + IntToString(nCost)
            + " sz.z., by złożyć tę przysięgę.");
        return;
    }
    if(OathGetActive(oPC) > 0)
    {
        SendMessageToPC(oPC, "[Przysięgi] Możesz złożyć tylko jedną przysięgę naraz.");
        return;
    }
    if(OathIsBroken(oPC))
    {
        SendMessageToPC(oPC, "[Przysięgi] Piętno krzywoprzysięzcy blokuje nowe przysięgi. Najpierw się odkup.");
        return;
    }

    if(nCost > 0)
        AssignCommand(oPC, TakeGoldFromCreature(nCost, oPC, TRUE));

    OathDbSwear(oPC, nOathId);
    OathApplyEffects(oPC, nOathId);

    ApplyEffectToObject(DURATION_TYPE_INSTANT,
        EffectVisualEffect(VFX_FNF_HOLY_BURST), oPC);

    FloatingTextStringOnCreature(
        OathGetName(nOathId) + " złożona. Bogowie przyjmują świadectwo.", oPC, FALSE);

    SendMessageToPC(oPC, "[Przysięgi] Złożono " + OathGetName(nOathId) + ". Moc jest twoja.");

    int nToken = NuiFindWindow(oPC, OATH_WINDOW);
    if(nToken != 0)
    {
        SetLocalInt(oPC, OATH_LVAR_SEL, nOathId);
        FeedOathStatus(oPC, nToken);
        FeedOathDetail(oPC, nToken, nOathId);
        FeedOathRows(oPC, nToken, nOathId);
    }
}

void OathDoRenounce(object oPC)
{
    OathBreak(oPC, "Dobrowolne wyrzeczenie się przysięgi.");
}

void OathDoAtone(object oPC)
{
    if(!OathIsBroken(oPC))
    {
        SendMessageToPC(oPC, "[Przysięgi] Nie nosisz piętna krzywoprzysięzcy.");
        return;
    }
    if(GetGold(oPC) < OATH_COST_ATONE)
    {
        SendMessageToPC(oPC, "[Przysięgi] Odkupienie kosztuje " + IntToString(OATH_COST_ATONE)
            + " sz.z. Nie masz wystarczająco złota.");
        return;
    }

    AssignCommand(oPC, TakeGoldFromCreature(OATH_COST_ATONE, oPC, TRUE));
    OathRemoveCurse(oPC);
    OathDbClear(oPC);

    ApplyEffectToObject(DURATION_TYPE_INSTANT,
        EffectVisualEffect(VFX_IMP_HOLY_AID), oPC);

    FloatingTextStringOnCreature(
        "Bogowie przyjmują ofiarę. Piętno opada jak popiół.", oPC, FALSE);

    SendMessageToPC(oPC, "[Przysięgi] Piętno krzywoprzysięzcy zdjęte. Możesz złożyć nową przysięgę.");

    int nToken = NuiFindWindow(oPC, OATH_WINDOW);
    if(nToken != 0)
    {
        FeedOathStatus(oPC, nToken);
        FeedOathDetail(oPC, nToken, GetLocalInt(oPC, OATH_LVAR_SEL));
    }
}
