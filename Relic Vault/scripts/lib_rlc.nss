#include "lib_rlc_def"

void RlcShowWindow(object oPC);
void RlcFeedList(object oPC, int nToken);
void RlcFeedDetail(object oPC, int nToken);
void RlcApplyEffects(object oPC);
void RlcRemoveEffects(object oPC);
void RlcCheckCurseTick(object oPC);

// ----------------------------------------------------------------
// Relic data
// ----------------------------------------------------------------

string RlcRelicName(int nId)
{
    switch(nId)
    {
        case RLC_RELIC_EYE:     return "Oko Tyranów";
        case RLC_RELIC_BLADE:   return "Miecz Zdrajcy";
        case RLC_RELIC_CHALICE: return "Kielich Zatracenia";
        case RLC_RELIC_CROWN:   return "Korona Popiołów";
        case RLC_RELIC_SEAL:    return "Pieczęć Nicości";
        case RLC_RELIC_CLAW:    return "Szpon Bestii";
    }
    return "Nieznana Relikwia";
}

string RlcRelicLore(int nId)
{
    switch(nId)
    {
        case RLC_RELIC_EYE:
            return "Skamieniałe oko wyłupione z czoła licza-tyrana. Wciąż patrzy.\n\n"
                   "Mówi się, że posiadacz widzi przez ciemność i czyta kłamstwa jak "
                   "otwartą księgę — lecz każdej nocy oko przegląda mu przez powiekę "
                   "i wysysa mądrość jak sok z mroku. Pieczęć krwi pulsuje słabo...";
        case RLC_RELIC_BLADE:
            return "Obsydianowy sztylet wykuty przez zdrajcę dla własnego pana. "
                   "Pita krwią obu.\n\nSzept ostrza jest słodki: \"Pamiętasz tę ranę? "
                   "Tamten zadał ją pierwszy. Pamiętasz?\" Im dłużej się słucha, "
                   "tym trudniej odróżnić swoje myśli od jego.";
        case RLC_RELIC_CHALICE:
            return "Srebrny kielich, którego dna nikt nie widział. "
                   "Napełnia się sam czarnym winem o smaku miedzi i nadziei.\n\n"
                   "Pijący regeneruje rany, lecz krew gęstnieje z każdym łykiem — "
                   "serce musi pompować coraz mocniej. Po pewnym czasie żyły ciemnieją "
                   "i przebijają przez skórę jak atrament.";
        case RLC_RELIC_CROWN:
            return "Szara korona popiołów. Noszono ją przez jedenaście wojen. "
                   "Nie jeden raz pogardzono nią w trumnie — bo nikt nie mógł jej zdjąć.\n\n"
                   "Ciężar jest symboliczny. Przynajmniej na początku. "
                   "Z czasem korona wydaje się rosnąć, a nogi coraz trudniej unieść.";
        case RLC_RELIC_SEAL:
            return "Obsydianowy dysk ze znakiem Pustki wyrytym szkłem ze spalonego "
                   "Astral-Bastionu. Żadne zaklęcie nie przeniknie bariery noszącego.\n\n"
                   "Niestety — żadne zaklęcie nie wypłynie też na zewnątrz. "
                   "Myśli zaczynają wypełniać ciszę, którą pieczęć tworzy wokół umysłu.";
        case RLC_RELIC_CLAW:
            return "Czarny szpon oderwany od istoty bez nazwy. Kość jest zimna "
                   "i pokryta grzbietami jak grzebień.\n\nNie ma sensu szukać "
                   "zwierzęcia, z którego pochodzi. Uderzenia szarpią i rozrywają. "
                   "Mięśnie ramienia coraz bardziej przypominają te, do których "
                   "szpon pierwotnie należał.";
    }
    return "";
}

string RlcPowerDesc(int nId, int bAmp)
{
    switch(nId)
    {
        case RLC_RELIC_EYE:     return bAmp ? "+4 do wszystkich rzutów obronnych (wzmocnione)" : "+2 do wszystkich rzutów obronnych";
        case RLC_RELIC_BLADE:   return bAmp ? "+4 do trafienia i obrażeń (wzmocnione)"         : "+2 do trafienia i obrażeń";
        case RLC_RELIC_CHALICE: return bAmp ? "Regeneracja 2 PW / 6 sekund (wzmocnione)"       : "Regeneracja 1 PW / 6 sekund";
        case RLC_RELIC_CROWN:   return bAmp ? "+6 do KP — ugięcie (wzmocnione)"                 : "+3 do KP — ugięcie";
        case RLC_RELIC_SEAL:    return bAmp ? "Odporność na zaklęcia 22 (wzmocnione)"           : "Odporność na zaklęcia 15";
        case RLC_RELIC_CLAW:    return bAmp ? "+2k6 obrażeń magicznych (wzmocnione)"            : "+1k6 obrażeń magicznych";
    }
    return "";
}

string RlcCurseDesc(int nId, int nLevel)
{
    if(nLevel <= 0) return "brak";
    switch(nId)
    {
        case RLC_RELIC_EYE:     return "Mądrość -"        + IntToString(nLevel);
        case RLC_RELIC_BLADE:   return "Charyzma -"        + IntToString(nLevel);
        case RLC_RELIC_CHALICE: return "Kondycja -"        + IntToString(nLevel);
        case RLC_RELIC_CROWN:   return "Zręczność -"       + IntToString(nLevel);
        case RLC_RELIC_SEAL:    return "Inteligencja -"    + IntToString(nLevel);
        case RLC_RELIC_CLAW:    return "Siła -"            + IntToString(nLevel);
    }
    return "";
}

// ----------------------------------------------------------------
// Effect application / removal
// ----------------------------------------------------------------

void RlcRemoveEffects(object oPC)
{
    effect eFX = GetFirstEffect(oPC);
    while(GetIsEffectValid(eFX))
    {
        string sTag = GetEffectTag(eFX);
        effect eNext = GetNextEffect(oPC);
        if(sTag == RLC_TAG_POWER || sTag == RLC_TAG_CURSE)
            RemoveEffect(oPC, eFX);
        eFX = eNext;
    }
}

void RlcApplyEffects(object oPC)
{
    RlcRemoveEffects(oPC);

    int nRelicId = RlcGetAttuned(oPC);
    if(nRelicId == 0) return;

    int nCurse = RlcGetCurseLevel(oPC);
    int bAmp   = (nCurse >= RLC_CURSE_MAX);

    // Power effect
    switch(nRelicId)
    {
        case RLC_RELIC_EYE:
        {
            int nB = bAmp ? 4 : 2;
            ApplyEffectToObject(DURATION_TYPE_PERMANENT,
                TagEffect(EffectSavingThrowIncrease(SAVING_THROW_ALL, nB), RLC_TAG_POWER), oPC);
            break;
        }
        case RLC_RELIC_BLADE:
        {
            int nB = bAmp ? 4 : 2;
            ApplyEffectToObject(DURATION_TYPE_PERMANENT,
                TagEffect(EffectAttackIncrease(nB, ATTACK_BONUS_MISC), RLC_TAG_POWER), oPC);
            ApplyEffectToObject(DURATION_TYPE_PERMANENT,
                TagEffect(EffectDamageBonus(nB, DAMAGE_TYPE_MAGICAL), RLC_TAG_POWER), oPC);
            break;
        }
        case RLC_RELIC_CHALICE:
        {
            int nRegen = bAmp ? 2 : 1;
            ApplyEffectToObject(DURATION_TYPE_PERMANENT,
                TagEffect(EffectRegenerate(nRegen, 6.0), RLC_TAG_POWER), oPC);
            break;
        }
        case RLC_RELIC_CROWN:
        {
            int nAC = bAmp ? 6 : 3;
            ApplyEffectToObject(DURATION_TYPE_PERMANENT,
                TagEffect(EffectACIncrease(nAC, AC_DEFLECTION_BONUS), RLC_TAG_POWER), oPC);
            break;
        }
        case RLC_RELIC_SEAL:
        {
            int nSR = bAmp ? 22 : 15;
            ApplyEffectToObject(DURATION_TYPE_PERMANENT,
                TagEffect(EffectSpellResistanceIncrease(nSR), RLC_TAG_POWER), oPC);
            break;
        }
        case RLC_RELIC_CLAW:
        {
            int nDmg = bAmp ? DAMAGE_BONUS_2d6 : DAMAGE_BONUS_1d6;
            ApplyEffectToObject(DURATION_TYPE_PERMANENT,
                TagEffect(EffectDamageBonus(nDmg, DAMAGE_TYPE_MAGICAL), RLC_TAG_POWER), oPC);
            break;
        }
    }

    // Curse effect (penalty grows each tick)
    if(nCurse <= 0) return;

    int nAbility = ABILITY_WISDOM;
    switch(nRelicId)
    {
        case RLC_RELIC_EYE:     nAbility = ABILITY_WISDOM;       break;
        case RLC_RELIC_BLADE:   nAbility = ABILITY_CHARISMA;     break;
        case RLC_RELIC_CHALICE: nAbility = ABILITY_CONSTITUTION; break;
        case RLC_RELIC_CROWN:   nAbility = ABILITY_DEXTERITY;    break;
        case RLC_RELIC_SEAL:    nAbility = ABILITY_INTELLIGENCE; break;
        case RLC_RELIC_CLAW:    nAbility = ABILITY_STRENGTH;     break;
    }
    ApplyEffectToObject(DURATION_TYPE_PERMANENT,
        TagEffect(EffectAbilityDecrease(nAbility, nCurse), RLC_TAG_CURSE), oPC);
}

// ----------------------------------------------------------------
// Curse tick (call from heartbeat and on-enter)
// ----------------------------------------------------------------

void RlcCheckCurseTick(object oPC)
{
    if(RlcGetAttuned(oPC) == 0) return;
    if(!RlcNeedsCurseTick(oPC)) return;

    int nNew = RlcTickCurse(oPC);
    if(nNew < 0) return;

    string sMsg;
    if(nNew >= RLC_CURSE_MAX)
        sMsg = "[Relikwia] Klątwa osiągnęła szczyt. Moc relikwii rozkwita — i zatruwa.";
    else
        sMsg = "[Relikwia] Klątwa się wzmacnia — poziom " + IntToString(nNew) + "/" + IntToString(RLC_CURSE_MAX) + ".";
    SendMessageToPC(oPC, sMsg);

    RlcApplyEffects(oPC);

    int nToken = NuiFindWindow(oPC, RLC_WINDOW);
    if(nToken != 0)
    {
        RlcFeedList(oPC, nToken);
        RlcFeedDetail(oPC, nToken);
    }
}

// ----------------------------------------------------------------
// NUI layout builders
// ----------------------------------------------------------------

json RlcBuildListPanel(object oPC)
{
    float fRowH = GetNuiScaleDimension(oPC, 52.0);
    float fPanW = GetNuiScaleDimension(oPC, 210.0);

    json jNameLbl = NuiLabel(NuiBind(RLC_BIND_ROW_NAME),
        JsonInt(NUI_HALIGN_LEFT), JsonInt(NUI_VALIGN_MIDDLE));
    jNameLbl = NuiStyleForegroundColor(jNameLbl, NuiBind(RLC_BIND_ROW_COLOR));

    json jStatusLbl = NuiLabel(NuiBind(RLC_BIND_ROW_STATUS),
        JsonInt(NUI_HALIGN_LEFT), JsonInt(NUI_VALIGN_MIDDLE));
    jStatusLbl = NuiHeight(jStatusLbl, GetNuiScaleDimension(oPC, 18.0));

    json jCellCol = JsonArray();
    jCellCol = JsonArrayInsert(jCellCol, jNameLbl);
    jCellCol = JsonArrayInsert(jCellCol, jStatusLbl);

    json jCell = NuiGroup(NuiCol(jCellCol), TRUE, NUI_SCROLLBARS_NONE);
    jCell = NuiId(jCell, RLC_BTN_ROW);
    jCell = NuiEncouraged(jCell, NuiBind(RLC_BIND_ROW_ENC));

    json jTmpl = JsonArrayInsert(JsonArray(), NuiListTemplateCell(jCell, 0.0, TRUE));
    json jList = NuiList(jTmpl, JsonInt(RLC_RELIC_COUNT), fRowH);

    return NuiWidth(NuiCol(JsonArrayInsert(JsonArray(), jList)), fPanW);
}

json RlcBuildDetailPanel(object oPC)
{
    float fBtnH  = GetNuiScaleDimension(oPC, 30.0);
    float fLoreH = GetNuiScaleDimension(oPC, 160.0);

    json jRelicName = NuiLabel(NuiBind(RLC_BIND_DET_NAME),
        JsonInt(NUI_HALIGN_LEFT), JsonInt(NUI_VALIGN_MIDDLE));
    jRelicName = NuiHeight(jRelicName, GetNuiScaleDimension(oPC, 32.0));

    json jLore = NuiGroup(NuiText(NuiBind(RLC_BIND_DET_LORE), FALSE), TRUE, NUI_SCROLLBARS_AUTO);
    jLore = NuiHeight(jLore, fLoreH);

    // Power row
    json jPwrLbl = NuiLabel(JsonString("Moc:"),
        JsonInt(NUI_HALIGN_LEFT), JsonInt(NUI_VALIGN_MIDDLE));
    jPwrLbl = NuiWidth(jPwrLbl, GetNuiScaleDimension(oPC, 46.0));
    json jPwrVal = NuiLabel(NuiBind(RLC_BIND_DET_POWER),
        JsonInt(NUI_HALIGN_LEFT), JsonInt(NUI_VALIGN_MIDDLE));
    json jPwrRow = JsonArray();
    jPwrRow = JsonArrayInsert(jPwrRow, jPwrLbl);
    jPwrRow = JsonArrayInsert(jPwrRow, jPwrVal);

    // Curse label
    json jCurseLbl = NuiLabel(NuiBind(RLC_BIND_CURSE_LBL),
        JsonInt(NUI_HALIGN_LEFT), JsonInt(NUI_VALIGN_MIDDLE));
    jCurseLbl = NuiHeight(jCurseLbl, GetNuiScaleDimension(oPC, 22.0));

    // Curse progress bar
    json jBar = NuiProgressBar(NuiBind(RLC_BIND_CURSE_PROG));
    jBar = NuiHeight(jBar, GetNuiScaleDimension(oPC, 16.0));
    jBar = NuiTooltip(jBar, JsonString("Poziom klątwy — 0 (uśpiona) do 5 (obudzona)"));

    // Active curse description
    json jCurseVal = NuiLabel(NuiBind(RLC_BIND_DET_CURSE),
        JsonInt(NUI_HALIGN_LEFT), JsonInt(NUI_VALIGN_MIDDLE));
    jCurseVal = NuiHeight(jCurseVal, GetNuiScaleDimension(oPC, 22.0));

    // Holder info
    json jHolderLbl = NuiLabel(NuiBind(RLC_BIND_HOLDER_LBL),
        JsonInt(NUI_HALIGN_LEFT), JsonInt(NUI_VALIGN_MIDDLE));
    jHolderLbl = NuiHeight(jHolderLbl, GetNuiScaleDimension(oPC, 22.0));

    // Action buttons
    string sAttuneLabel  = "Atunuj ("  + IntToString(RLC_GOLD_ATTUNE)  + " sz)";
    string sReleaseLabel = "Uwolnij (" + IntToString(RLC_GOLD_RELEASE) + " sz)";
    string sPurifyLabel  = "Oczyść ("  + IntToString(RLC_GOLD_PURIFY)  + " sz, " + IntToString(RLC_PURIFY_CHANCE) + "%)";

    json jAttuneBtn = NuiButton(JsonString(sAttuneLabel));
    jAttuneBtn = NuiId(jAttuneBtn, RLC_BTN_ATTUNE);
    jAttuneBtn = NuiEnabled(jAttuneBtn, NuiBind(RLC_BIND_ATTUNE_ENA));
    jAttuneBtn = NuiWidth(jAttuneBtn, GetNuiScaleDimension(oPC, 160.0));
    jAttuneBtn = NuiHeight(jAttuneBtn, fBtnH);
    jAttuneBtn = NuiTooltip(jAttuneBtn, JsonString("Zwiąż swoją wolę z relikwią. Możesz dzierżyć tylko jedną naraz."));

    json jRelBtn = NuiButton(JsonString(sReleaseLabel));
    jRelBtn = NuiId(jRelBtn, RLC_BTN_RELEASE);
    jRelBtn = NuiEnabled(jRelBtn, NuiBind(RLC_BIND_RELEAS_ENA));
    jRelBtn = NuiWidth(jRelBtn, GetNuiScaleDimension(oPC, 160.0));
    jRelBtn = NuiHeight(jRelBtn, fBtnH);
    jRelBtn = NuiTooltip(jRelBtn, JsonString("Zerwij więź siłą woli. Klątwa i moc ustępują — cena to rytuał oczyszczenia."));

    json jPurBtn = NuiButton(JsonString(sPurifyLabel));
    jPurBtn = NuiId(jPurBtn, RLC_BTN_PURIFY);
    jPurBtn = NuiEnabled(jPurBtn, NuiBind(RLC_BIND_PURIFY_ENA));
    jPurBtn = NuiWidth(jPurBtn, GetNuiScaleDimension(oPC, 260.0));
    jPurBtn = NuiHeight(jPurBtn, fBtnH);
    jPurBtn = NuiTooltip(jPurBtn, JsonString("Rytuał oczyszczenia — " + IntToString(RLC_PURIFY_CHANCE) + "% szansy na redukcję klątwy o 1."));

    json jBtnRow = JsonArray();
    jBtnRow = JsonArrayInsert(jBtnRow, jAttuneBtn);
    jBtnRow = JsonArrayInsert(jBtnRow, jRelBtn);
    jBtnRow = JsonArrayInsert(jBtnRow, NuiSpacer());
    jBtnRow = JsonArrayInsert(jBtnRow, jPurBtn);

    json jCol = JsonArray();
    jCol = JsonArrayInsert(jCol, jRelicName);
    jCol = JsonArrayInsert(jCol, jLore);
    jCol = JsonArrayInsert(jCol, CreateEmptyRow(oPC, 8.0));
    jCol = JsonArrayInsert(jCol, NuiRow(jPwrRow));
    jCol = JsonArrayInsert(jCol, CreateEmptyRow(oPC, 4.0));
    jCol = JsonArrayInsert(jCol, jCurseLbl);
    jCol = JsonArrayInsert(jCol, jBar);
    jCol = JsonArrayInsert(jCol, jCurseVal);
    jCol = JsonArrayInsert(jCol, jHolderLbl);
    jCol = JsonArrayInsert(jCol, CreateEmptyRow(oPC, 10.0));
    jCol = JsonArrayInsert(jCol, NuiRow(jBtnRow));

    return NuiCol(jCol);
}

void RlcShowWindow(object oPC)
{
    if(NuiFindWindow(oPC, RLC_WINDOW) != 0)
    {
        int nToken = NuiFindWindow(oPC, RLC_WINDOW);
        RlcFeedList(oPC, nToken);
        RlcFeedDetail(oPC, nToken);
        return;
    }

    float fCX = (IntToFloat(GetPlayerDeviceProperty(oPC, PLAYER_DEVICE_PROPERTY_GUI_WIDTH))
                - GetNuiScaleDimension(oPC, RLC_W)) / 2.0;
    float fCY = (IntToFloat(GetPlayerDeviceProperty(oPC, PLAYER_DEVICE_PROPERTY_GUI_HEIGHT))
                - GetNuiScaleDimension(oPC, RLC_H)) / 2.0;
    json jGeom = NuiRect(fCX, fCY, GetNuiScaleDimension(oPC, RLC_W), GetNuiScaleDimension(oPC, RLC_H));

    json jClose = NuiButton(JsonString("X"));
    jClose = NuiId(jClose, RLC_BTN_CLOSE);
    jClose = NuiWidth(jClose, GetNuiScaleDimension(oPC, 28.0));
    jClose = NuiHeight(jClose, GetNuiScaleDimension(oPC, 28.0));

    json jTitleLbl = NuiLabel(JsonString("Skarbiec Relikwii"),
        JsonInt(NUI_HALIGN_LEFT), JsonInt(NUI_VALIGN_MIDDLE));

    json jTitleRow = JsonArray();
    jTitleRow = JsonArrayInsert(jTitleRow, jTitleLbl);
    jTitleRow = JsonArrayInsert(jTitleRow, NuiSpacer());
    jTitleRow = JsonArrayInsert(jTitleRow, jClose);

    // Split view: fixed-width list on the left, elastic detail on the right
    json jContentRow = JsonArray();
    jContentRow = JsonArrayInsert(jContentRow, RlcBuildListPanel(oPC));
    jContentRow = JsonArrayInsert(jContentRow, NuiSpacer());
    jContentRow = JsonArrayInsert(jContentRow, RlcBuildDetailPanel(oPC));

    json jRoot = JsonArray();
    jRoot = JsonArrayInsert(jRoot, NuiRow(jTitleRow));
    jRoot = JsonArrayInsert(jRoot, NuiRow(jContentRow));

    json jWin = NuiWindow(NuiCol(jRoot),
        JsonBool(FALSE),
        NuiBind(RLC_WIN_GEOM),
        JsonBool(FALSE),
        JsonBool(FALSE),
        JsonBool(FALSE),
        JsonBool(TRUE),
        JsonBool(FALSE));

    int nToken = NuiCreate(oPC, jWin, RLC_WINDOW, RLC_EV_SCRIPT);
    NuiSetBind(oPC, nToken, RLC_WIN_GEOM, jGeom);

    // Default selection = first relic
    if(GetLocalInt(oPC, RLC_LVAR_SEL) < 1)
        SetLocalInt(oPC, RLC_LVAR_SEL, 1);

    RlcFeedList(oPC, nToken);
    RlcFeedDetail(oPC, nToken);
}

// ----------------------------------------------------------------
// Feed functions
// ----------------------------------------------------------------

void RlcFeedList(object oPC, int nToken)
{
    int nMyRelic = RlcGetAttuned(oPC);
    int nSel     = GetLocalInt(oPC, RLC_LVAR_SEL);

    json jNames    = JsonArray();
    json jStatuses = JsonArray();
    json jColors   = JsonArray();
    json jEncs     = JsonArray();

    int i;
    for(i = 1; i <= RLC_RELIC_COUNT; i++)
    {
        string sHolder = RlcGetHolder(i);
        string sStatus;
        json jColor;

        if(i == nMyRelic)
        {
            int nCurse = RlcGetCurseLevel(oPC);
            sStatus = "Twoja — klątwa: " + IntToString(nCurse) + "/" + IntToString(RLC_CURSE_MAX);
            jColor  = NuiColor(200, 170, 60); // gold
        }
        else if(sHolder == "")
        {
            sStatus = "Wolna";
            jColor  = NuiColor(210, 210, 210); // light
        }
        else
        {
            sStatus = sHolder;
            jColor  = NuiColor(120, 120, 120); // dimmed
        }

        jNames    = JsonArrayInsert(jNames,    JsonString(RlcRelicName(i)));
        jStatuses = JsonArrayInsert(jStatuses, JsonString(sStatus));
        jColors   = JsonArrayInsert(jColors,   jColor);
        jEncs     = JsonArrayInsert(jEncs,     JsonBool(i == nSel));
    }

    NuiSetBind(oPC, nToken, RLC_BIND_ROW_NAME,   jNames);
    NuiSetBind(oPC, nToken, RLC_BIND_ROW_STATUS, jStatuses);
    NuiSetBind(oPC, nToken, RLC_BIND_ROW_COLOR,  jColors);
    NuiSetBind(oPC, nToken, RLC_BIND_ROW_ENC,    jEncs);
}

void RlcFeedDetail(object oPC, int nToken)
{
    int nSel     = GetLocalInt(oPC, RLC_LVAR_SEL);
    int nMyRelic = RlcGetAttuned(oPC);
    int nMyCurse = RlcGetCurseLevel(oPC);

    if(nSel < 1 || nSel > RLC_RELIC_COUNT)
        nSel = 1;

    string sHolder = RlcGetHolder(nSel);
    int bIsMine    = (nSel == nMyRelic);
    int bFree      = (sHolder == "");
    int bIHaveOne  = (nMyRelic != 0);

    int   nDispCurse = bIsMine ? nMyCurse : 0;
    float fProgress  = bIsMine
        ? IntToFloat(nMyCurse) / IntToFloat(RLC_CURSE_MAX)
        : 0.0;
    int bAmp = bIsMine && (nMyCurse >= RLC_CURSE_MAX);

    string sCurseLbl;
    if(bIsMine)
        sCurseLbl = "Klątwa: " + IntToString(nMyCurse) + " / " + IntToString(RLC_CURSE_MAX)
                  + (bAmp ? "  [OBUDZONA]" : "");
    else if(!bFree)
        sCurseLbl = "Klątwa: nieznana (relikwia dzierżona)";
    else
        sCurseLbl = "Klątwa: 0 — relikwia jest wolna";

    string sCurseDesc = "Przekleństwo: " + RlcCurseDesc(nSel, nDispCurse);

    string sHolderLbl;
    if(bIsMine)
        sHolderLbl = "To twoja relikwia.";
    else if(!bFree)
        sHolderLbl = "Dzierżona przez: " + sHolder;
    else
        sHolderLbl = "Relikwia jest wolna.";

    NuiSetBind(oPC, nToken, RLC_BIND_DET_NAME,   JsonString(RlcRelicName(nSel)));
    NuiSetBind(oPC, nToken, RLC_BIND_DET_LORE,   JsonString(RlcRelicLore(nSel)));
    NuiSetBind(oPC, nToken, RLC_BIND_DET_POWER,  JsonString(RlcPowerDesc(nSel, bAmp)));
    NuiSetBind(oPC, nToken, RLC_BIND_CURSE_LBL,  JsonString(sCurseLbl));
    NuiSetBind(oPC, nToken, RLC_BIND_CURSE_PROG, JsonFloat(fProgress));
    NuiSetBind(oPC, nToken, RLC_BIND_DET_CURSE,  JsonString(sCurseDesc));
    NuiSetBind(oPC, nToken, RLC_BIND_HOLDER_LBL, JsonString(sHolderLbl));

    NuiSetBind(oPC, nToken, RLC_BIND_ATTUNE_ENA, JsonBool(bFree && !bIHaveOne));
    NuiSetBind(oPC, nToken, RLC_BIND_RELEAS_ENA, JsonBool(bIsMine));
    NuiSetBind(oPC, nToken, RLC_BIND_PURIFY_ENA, JsonBool(bIsMine && nMyCurse > 0));
}
