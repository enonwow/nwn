#include "lib_stn_def"

// ----------------------------------------------------------------
// Stance data
// ----------------------------------------------------------------

string StnGetName(int nId)
{
    switch(nId)
    {
        case STN_STANCE_READY:  return "Oczekiwanie";
        case STN_STANCE_FURY:   return "Uderzenie Gwaltowne";
        case STN_STANCE_IRON:   return "Zelazna Obrona";
        case STN_STANCE_BLOOD:  return "Szal Krwi";
        case STN_STANCE_SHADOW: return "Mrok w Oczach";
        case STN_STANCE_DEATH:  return "Pieczen Smierci";
    }
    return "Nieznana";
}

string StnGetDesc(int nId)
{
    switch(nId)
    {
        case STN_STANCE_READY:
            return "Postawa neutralna. Wojownik czeka, obserwuje przeciwnika. "
                   "Zadne premie, zadne kary — czyste skupienie.\n\n"
                   "Efekty: Brak.";
        case STN_STANCE_FURY:
            return "Postawa agresywna. Uderzaj szybko, uderzaj mocno. "
                   "Kazdy atak niesie w sobie odrobine desperacji.\n\n"
                   "Efekty: Trafienie +2, Pancerz -2.";
        case STN_STANCE_IRON:
            return "Postawa obronna. Tarcza staje sie murem, cialo — skala. "
                   "Kazdy cios odpiera sie kosztem wlasnej ofensywy.\n\n"
                   "Efekty: Trafienie -2, Pancerz +3 (unik), Rzuty obronne +1.";
        case STN_STANCE_BLOOD:
            return "Szal berserkera. Bol staje sie paliwem, krew — triumfem. "
                   "Ci, co wkrocza w ten mrok, nie czuja strachu — "
                   "bo sami stali sie czymce gorszym.\n\n"
                   "Efekty: Obrazenia +1k6, Pancerz -5, "
                   "Odpornosc na strach i oczarowanie.\n\n"
                   "Cena odblokowania: " + IntToString(STN_COST_BLOOD) + " sztuk zlota.";
        case STN_STANCE_SHADOW:
            return "Postawa cieniowego lowcy. Krok jest bezglosny, "
                   "cialo niemal przezroczyste. Uderz, zanim zobacza.\n\n"
                   "Efekty: Ukrycie 15%, Cichy krok +4, Chowanie sie +4.\n\n"
                   "Cena odblokowania: " + IntToString(STN_COST_SHADOW) + " sztuk zlota.";
        case STN_STANCE_DEATH:
            return "Pieczen smierci — zawarcie paktu z tym, co nieuniknione. "
                   "Cialo samo sie zszywa powoli, dusza placi cene za kazda "
                   "sekunde spedzona na krawedzi.\n\n"
                   "Efekty: Regeneracja 1 HP/6s, Rzuty vs smierc +2, Charyzma -2.\n\n"
                   "Cena odblokowania: " + IntToString(STN_COST_DEATH) + " sztuk zlota.";
    }
    return "";
}

int StnGetCost(int nId)
{
    switch(nId)
    {
        case STN_STANCE_BLOOD:  return STN_COST_BLOOD;
        case STN_STANCE_SHADOW: return STN_COST_SHADOW;
        case STN_STANCE_DEATH:  return STN_COST_DEATH;
    }
    return 0;
}

// ----------------------------------------------------------------
// Effect removal
// Restarts iterator after each removal to avoid iterator invalidation.
// ----------------------------------------------------------------

void StnRemoveEffects(object oPC)
{
    int bRemovedAny;
    do
    {
        bRemovedAny = FALSE;
        effect eEff = GetFirstEffect(oPC);
        while(GetIsEffectValid(eEff))
        {
            if(GetEffectTag(eEff) == STN_EFFECT_TAG)
            {
                RemoveEffect(oPC, eEff);
                bRemovedAny = TRUE;
                break; // restart outer loop
            }
            eEff = GetNextEffect(oPC);
        }
    } while(bRemovedAny);
}

// ----------------------------------------------------------------
// Effect application
// Each stance applies its effects individually — one Apply call
// per logical effect — each tagged STN_EFFECT_TAG so removal is
// unambiguous without EffectLinkEffects complications.
// ----------------------------------------------------------------

void StnApplyEffects(object oPC, int nId)
{
    StnRemoveEffects(oPC);
    if(nId == STN_STANCE_READY) return;

    switch(nId)
    {
        case STN_STANCE_FURY:
            // Aggressive: AB +2, AC -2
            ApplyEffectToObject(DURATION_TYPE_PERMANENT,
                TagEffect(EffectAttackIncrease(2), STN_EFFECT_TAG), oPC);
            ApplyEffectToObject(DURATION_TYPE_PERMANENT,
                TagEffect(EffectACDecrease(2), STN_EFFECT_TAG), oPC);
            break;

        case STN_STANCE_IRON:
            // Defensive: AB -2, AC +3 (dodge), saves +1 all
            ApplyEffectToObject(DURATION_TYPE_PERMANENT,
                TagEffect(EffectAttackDecrease(2), STN_EFFECT_TAG), oPC);
            ApplyEffectToObject(DURATION_TYPE_PERMANENT,
                TagEffect(EffectACIncrease(3, AC_DODGE_BONUS), STN_EFFECT_TAG), oPC);
            ApplyEffectToObject(DURATION_TYPE_PERMANENT,
                TagEffect(EffectSavingThrowIncrease(SAVING_THROW_ALL, 1), STN_EFFECT_TAG), oPC);
            break;

        case STN_STANCE_BLOOD:
            // Berserk: damage +1d6 slashing, AC -5, immune fear+charm
            ApplyEffectToObject(DURATION_TYPE_PERMANENT,
                TagEffect(EffectDamageIncrease(DAMAGE_BONUS_1d6, DAMAGE_TYPE_SLASHING), STN_EFFECT_TAG), oPC);
            ApplyEffectToObject(DURATION_TYPE_PERMANENT,
                TagEffect(EffectACDecrease(5), STN_EFFECT_TAG), oPC);
            ApplyEffectToObject(DURATION_TYPE_PERMANENT,
                TagEffect(EffectImmunity(IMMUNITY_TYPE_FEAR), STN_EFFECT_TAG), oPC);
            ApplyEffectToObject(DURATION_TYPE_PERMANENT,
                TagEffect(EffectImmunity(IMMUNITY_TYPE_CHARM), STN_EFFECT_TAG), oPC);
            break;

        case STN_STANCE_SHADOW:
            // Shadow: 15% concealment, Move Silently +4, Hide +4
            ApplyEffectToObject(DURATION_TYPE_PERMANENT,
                TagEffect(EffectConcealment(15), STN_EFFECT_TAG), oPC);
            ApplyEffectToObject(DURATION_TYPE_PERMANENT,
                TagEffect(EffectSkillIncrease(SKILL_MOVE_SILENTLY, 4), STN_EFFECT_TAG), oPC);
            ApplyEffectToObject(DURATION_TYPE_PERMANENT,
                TagEffect(EffectSkillIncrease(SKILL_HIDE, 4), STN_EFFECT_TAG), oPC);
            break;

        case STN_STANCE_DEATH:
            // Death's Seal: regen 1/6s, +2 saves vs death (fort), -2 CHA
            ApplyEffectToObject(DURATION_TYPE_PERMANENT,
                TagEffect(EffectRegenerate(1, 6.0), STN_EFFECT_TAG), oPC);
            ApplyEffectToObject(DURATION_TYPE_PERMANENT,
                TagEffect(EffectSavingThrowIncrease(SAVING_THROW_FORT, 2, SAVING_THROW_VS_DEATH),
                    STN_EFFECT_TAG), oPC);
            ApplyEffectToObject(DURATION_TYPE_PERMANENT,
                TagEffect(EffectAbilityDecrease(ABILITY_CHARISMA, 2), STN_EFFECT_TAG), oPC);
            break;
    }
}

// ----------------------------------------------------------------
// Adopt and unlock actions
// ----------------------------------------------------------------

void StnAdoptStance(object oPC, int nId)
{
    if(nId < 0 || nId >= STN_COUNT) return;
    if(!StnIsUnlocked(oPC, nId))
    {
        SendMessageToPC(oPC, "[Postawa] Ta postawa nie jest jeszcze odblokowana.");
        return;
    }

    StnApplyEffects(oPC, nId);
    StnSetActiveStance(oPC, nId);

    string sMsg;
    if(nId == STN_STANCE_READY)
        sMsg = "[Postawa] Powracasz do postawy neutralnej.";
    else
        sMsg = "[Postawa] Przyjmujesz postawe: " + StnGetName(nId) + ".";
    SendMessageToPC(oPC, sMsg);

    int nBook = NuiFindWindow(oPC, STN_WIN_BOOK);
    if(nBook != 0) FeedStanceWindow(oPC, nBook);

    int nWidget = NuiFindWindow(oPC, STN_WIN_WIDGET);
    if(nWidget != 0) FeedStanceWidget(oPC, nWidget);
}

void StnUnlockAtTrainer(object oPC, int nId)
{
    if(nId < STN_FREE_COUNT || nId >= STN_COUNT) return;
    if(StnIsUnlocked(oPC, nId))
    {
        SendMessageToPC(oPC, "[Postawa] Juz opanowal(a)s te postawe.");
        return;
    }

    int nCost = StnGetCost(nId);
    if(GetGold(oPC) < nCost)
    {
        SendMessageToPC(oPC, "[Postawa] Potrzebujesz " + IntToString(nCost)
            + " sztuk zlota, by odblokowac ta postawe.");
        return;
    }

    AssignCommand(oPC, TakeGoldFromCreature(nCost, oPC, TRUE));
    StnUnlockStance(oPC, nId);

    SendMessageToPC(oPC, "[Postawa] Trener przekazuje ci sekret: "
        + StnGetName(nId) + ". Odblokowano za " + IntToString(nCost) + " zl.");

    int nBook = NuiFindWindow(oPC, STN_WIN_BOOK);
    if(nBook != 0) FeedStanceWindow(oPC, nBook);
}

// ----------------------------------------------------------------
// Widget
// ----------------------------------------------------------------

void FeedStanceWidget(object oPC, int nToken)
{
    int nActive = StnGetActiveStance(oPC);
    NuiSetBind(oPC, nToken, STN_BIND_WGT_NAME, JsonString(StnGetName(nActive)));
    json jColor = (nActive == STN_STANCE_READY)
        ? NuiColor(180, 180, 180)
        : NuiColor(200, 220, 160);
    NuiSetBind(oPC, nToken, STN_BIND_WGT_COLOR, jColor);
}

void CreateStanceWidget(object oPC)
{
    if(NuiFindWindow(oPC, STN_WIN_WIDGET) != 0)
    {
        FeedStanceWidget(oPC, NuiFindWindow(oPC, STN_WIN_WIDGET));
        return;
    }

    float fW    = GetNuiScaleDimension(oPC, STN_WGT_W);
    float fH    = GetNuiScaleDimension(oPC, STN_WGT_H);
    float fBtnH = GetNuiScaleDimension(oPC, 28.0);

    float fScreenW = IntToFloat(GetPlayerDeviceProperty(oPC, PLAYER_DEVICE_PROPERTY_GUI_WIDTH));
    float fX       = fScreenW - fW - 12.0;

    json jNameLbl = NuiLabel(NuiBind(STN_BIND_WGT_NAME), JsonInt(NUI_HALIGN_LEFT), JsonInt(NUI_VALIGN_MIDDLE));
    jNameLbl = NuiStyleForegroundColor(jNameLbl, NuiBind(STN_BIND_WGT_COLOR));

    json jOpenBtn = NuiButton(JsonString("..."));
    jOpenBtn = NuiId(jOpenBtn, STN_BTN_WGT_OPEN);
    jOpenBtn = NuiWidth(jOpenBtn, GetNuiScaleDimension(oPC, 28.0));
    jOpenBtn = NuiHeight(jOpenBtn, fBtnH);
    jOpenBtn = NuiTooltip(jOpenBtn, JsonString("Otworz ksiege postaw walki"));

    json jXBtn = NuiButton(JsonString("X"));
    jXBtn = NuiId(jXBtn, STN_BTN_WGT_CLOSE);
    jXBtn = NuiWidth(jXBtn, GetNuiScaleDimension(oPC, 22.0));
    jXBtn = NuiHeight(jXBtn, fBtnH);

    json jRow = JsonArray();
    jRow = JsonArrayInsert(jRow, jNameLbl);
    jRow = JsonArrayInsert(jRow, NuiSpacer());
    jRow = JsonArrayInsert(jRow, jOpenBtn);
    jRow = JsonArrayInsert(jRow, jXBtn);

    json jRoot = NuiCol(JsonArrayInsert(JsonArray(), NuiRow(jRow)));
    json jWin  = NuiWindow(jRoot,
        JsonBool(FALSE),
        NuiBind(STN_BIND_WGT_GEOM),
        JsonBool(FALSE), JsonBool(FALSE), JsonBool(FALSE),
        JsonBool(TRUE),  JsonBool(FALSE));

    int nToken = NuiCreate(oPC, jWin, STN_WIN_WIDGET, STN_EV_SCRIPT);
    NuiSetBind(oPC, nToken, STN_BIND_WGT_GEOM, NuiRect(fX, 80.0, fW, fH));
    FeedStanceWidget(oPC, nToken);
}

// ----------------------------------------------------------------
// Book window — feed
// ----------------------------------------------------------------

json StnRowColor(object oPC, int nStanceId)
{
    if(!StnIsUnlocked(oPC, nStanceId)) return NuiColor(120, 100, 80);
    int nActive = StnGetActiveStance(oPC);
    if(nActive == nStanceId)         return NuiColor(200, 220, 160);
    return NuiColor(220, 200, 160);
}

void FeedStanceWindow(object oPC, int nToken)
{
    int nSel    = GetLocalInt(oPC, STN_LVAR_SEL);
    int nActive = StnGetActiveStance(oPC);

    json jNames    = JsonArray();
    json jStatuses = JsonArray();
    json jEncs     = JsonArray();
    json jColors   = JsonArray();

    int i;
    for(i = 0; i < STN_COUNT; i++)
    {
        int bUnlocked = StnIsUnlocked(oPC, i);
        string sStatus;
        if(i == nActive)    sStatus = "[aktywna]";
        else if(!bUnlocked) sStatus = "[zamknieta]";

        jNames    = JsonArrayInsert(jNames,    JsonString(StnGetName(i)));
        jStatuses = JsonArrayInsert(jStatuses, JsonString(sStatus));
        jEncs     = JsonArrayInsert(jEncs,     JsonBool(i == nSel));
        jColors   = JsonArrayInsert(jColors,   StnRowColor(oPC, i));
    }

    NuiSetBind(oPC, nToken, STN_BIND_ROW_NAME,   jNames);
    NuiSetBind(oPC, nToken, STN_BIND_ROW_STATUS,  jStatuses);
    NuiSetBind(oPC, nToken, STN_BIND_ROW_ENC,     jEncs);
    NuiSetBind(oPC, nToken, STN_BIND_ROW_COLOR,   jColors);
    NuiSetBind(oPC, nToken, STN_BIND_ROW_COUNT,   JsonInt(STN_COUNT));

    string sHeader = "Ksiega Postaw — aktywna: " + StnGetName(nActive);
    NuiSetBind(oPC, nToken, STN_BIND_HEADER, JsonString(sHeader));

    if(nSel < 0 || nSel >= STN_COUNT)
    {
        NuiSetBind(oPC, nToken, STN_BIND_DESC,       JsonString("Wybierz postawe z listy."));
        NuiSetBind(oPC, nToken, STN_BIND_ADOPT_LBL,  JsonString("Przyjmij postawe"));
        NuiSetBind(oPC, nToken, STN_BIND_ADOPT_ENA,  JsonBool(FALSE));
        NuiSetBind(oPC, nToken, STN_BIND_UNLOCK_VIS, JsonBool(FALSE));
        NuiSetBind(oPC, nToken, STN_BIND_UNLOCK_ENA, JsonBool(FALSE));
        NuiSetBind(oPC, nToken, STN_BIND_UNLOCK_LBL, JsonString(""));
        return;
    }

    int bSelUnlocked = StnIsUnlocked(oPC, nSel);
    int bIsActive    = (nSel == nActive);
    int nCost        = StnGetCost(nSel);

    NuiSetBind(oPC, nToken, STN_BIND_DESC, JsonString(StnGetDesc(nSel)));

    NuiSetBind(oPC, nToken, STN_BIND_ADOPT_LBL, JsonString(bIsActive ? "Aktywna postawa" : "Przyjmij postawe"));
    NuiSetBind(oPC, nToken, STN_BIND_ADOPT_ENA, JsonBool(bSelUnlocked && !bIsActive));

    int bShowUnlock = (!bSelUnlocked && nCost > 0);
    NuiSetBind(oPC, nToken, STN_BIND_UNLOCK_VIS, JsonBool(bShowUnlock));
    if(bShowUnlock)
    {
        NuiSetBind(oPC, nToken, STN_BIND_UNLOCK_LBL,
            JsonString("Odblokuj (" + IntToString(nCost) + " zl)"));
        NuiSetBind(oPC, nToken, STN_BIND_UNLOCK_ENA, JsonBool(GetGold(oPC) >= nCost));
    }
    else
    {
        NuiSetBind(oPC, nToken, STN_BIND_UNLOCK_LBL, JsonString(""));
        NuiSetBind(oPC, nToken, STN_BIND_UNLOCK_ENA, JsonBool(FALSE));
    }
}

// ----------------------------------------------------------------
// Book window — create
// ----------------------------------------------------------------

void CreateStanceWindow(object oPC)
{
    if(NuiFindWindow(oPC, STN_WIN_BOOK) != 0)
    {
        FeedStanceWindow(oPC, NuiFindWindow(oPC, STN_WIN_BOOK));
        return;
    }

    float fW    = GetNuiScaleDimension(oPC, STN_W);
    float fH    = GetNuiScaleDimension(oPC, STN_H);
    float fBtnH = GetNuiScaleDimension(oPC, 30.0);
    float fRowH = GetNuiScaleDimension(oPC, 30.0);

    float fCX = (IntToFloat(GetPlayerDeviceProperty(oPC, PLAYER_DEVICE_PROPERTY_GUI_WIDTH))  - fW) / 2.0;
    float fCY = (IntToFloat(GetPlayerDeviceProperty(oPC, PLAYER_DEVICE_PROPERTY_GUI_HEIGHT)) - fH) / 2.0;

    // ---- Top bar ----
    json jHeader = NuiLabel(NuiBind(STN_BIND_HEADER), JsonInt(NUI_HALIGN_LEFT), JsonInt(NUI_VALIGN_MIDDLE));
    jHeader = NuiHeight(jHeader, fBtnH);

    json jCloseBtn = NuiButton(JsonString("X"));
    jCloseBtn = NuiId(jCloseBtn, STN_BTN_CLOSE);
    jCloseBtn = NuiWidth(jCloseBtn, GetNuiScaleDimension(oPC, 30.0));
    jCloseBtn = NuiHeight(jCloseBtn, fBtnH);

    json jTopRow = JsonArray();
    jTopRow = JsonArrayInsert(jTopRow, jHeader);
    jTopRow = JsonArrayInsert(jTopRow, NuiSpacer());
    jTopRow = JsonArrayInsert(jTopRow, jCloseBtn);

    // ---- List (left panel) ----
    float fListW   = GetNuiScaleDimension(oPC, 260.0);
    float fStatusW = GetNuiScaleDimension(oPC, 90.0);
    float fListH   = GetNuiScaleDimension(oPC, 360.0);

    json jNameLbl = NuiLabel(NuiBind(STN_BIND_ROW_NAME), JsonInt(NUI_HALIGN_LEFT), JsonInt(NUI_VALIGN_MIDDLE));
    jNameLbl = NuiStyleForegroundColor(jNameLbl, NuiBind(STN_BIND_ROW_COLOR));

    json jStatusLbl = NuiLabel(NuiBind(STN_BIND_ROW_STATUS), JsonInt(NUI_HALIGN_RIGHT), JsonInt(NUI_VALIGN_MIDDLE));
    jStatusLbl = NuiWidth(jStatusLbl, fStatusW);
    jStatusLbl = NuiStyleForegroundColor(jStatusLbl, NuiBind(STN_BIND_ROW_COLOR));

    json jCellRow = JsonArray();
    jCellRow = JsonArrayInsert(jCellRow, jNameLbl);
    jCellRow = JsonArrayInsert(jCellRow, jStatusLbl);

    json jCell = NuiGroup(NuiRow(jCellRow), TRUE, NUI_SCROLLBARS_NONE);
    jCell = NuiId(jCell, STN_BTN_ROW);
    jCell = NuiEncouraged(jCell, NuiBind(STN_BIND_ROW_ENC));

    json jTmpl = JsonArrayInsert(JsonArray(), NuiListTemplateCell(jCell, 0.0, TRUE));
    json jList = NuiList(jTmpl, NuiBind(STN_BIND_ROW_COUNT), fRowH);
    jList = NuiHeight(jList, fListH);
    jList = NuiWidth(jList, fListW);

    // ---- Right panel ----
    float fDescH = GetNuiScaleDimension(oPC, 280.0);
    json jDesc   = NuiGroup(NuiText(NuiBind(STN_BIND_DESC), FALSE), TRUE, NUI_SCROLLBARS_NONE);
    jDesc = NuiHeight(jDesc, fDescH);

    json jAdoptBtn = NuiButton(NuiBind(STN_BIND_ADOPT_LBL));
    jAdoptBtn = NuiId(jAdoptBtn, STN_BTN_ADOPT);
    jAdoptBtn = NuiEnabled(jAdoptBtn, NuiBind(STN_BIND_ADOPT_ENA));
    jAdoptBtn = NuiHeight(jAdoptBtn, fBtnH);

    json jUnlockBtn = NuiButton(NuiBind(STN_BIND_UNLOCK_LBL));
    jUnlockBtn = NuiId(jUnlockBtn, STN_BTN_UNLOCK);
    jUnlockBtn = NuiEnabled(jUnlockBtn, NuiBind(STN_BIND_UNLOCK_ENA));
    jUnlockBtn = NuiVisible(jUnlockBtn, NuiBind(STN_BIND_UNLOCK_VIS));
    jUnlockBtn = NuiHeight(jUnlockBtn, fBtnH);

    json jBtnRow = JsonArray();
    jBtnRow = JsonArrayInsert(jBtnRow, jAdoptBtn);
    jBtnRow = JsonArrayInsert(jBtnRow, NuiSpacer());
    jBtnRow = JsonArrayInsert(jBtnRow, jUnlockBtn);

    json jRightCol = JsonArray();
    jRightCol = JsonArrayInsert(jRightCol, jDesc);
    jRightCol = JsonArrayInsert(jRightCol, CreateEmptyRow(oPC, 8.0));
    jRightCol = JsonArrayInsert(jRightCol, NuiRow(jBtnRow));

    // ---- Main layout ----
    json jGap     = NuiWidth(NuiCol(JsonArrayInsert(JsonArray(), NuiSpacer())), GetNuiScaleDimension(oPC, 16.0));
    json jSplitRow = JsonArray();
    jSplitRow = JsonArrayInsert(jSplitRow, NuiWidth(NuiCol(JsonArrayInsert(JsonArray(), jList)), fListW));
    jSplitRow = JsonArrayInsert(jSplitRow, jGap);
    jSplitRow = JsonArrayInsert(jSplitRow, NuiCol(jRightCol));

    json jRootCol = JsonArray();
    jRootCol = JsonArrayInsert(jRootCol, NuiRow(jTopRow));
    jRootCol = JsonArrayInsert(jRootCol, CreateEmptyRow(oPC, 6.0));
    jRootCol = JsonArrayInsert(jRootCol, NuiRow(jSplitRow));

    json jWin = NuiWindow(NuiCol(jRootCol),
        JsonBool(FALSE),
        NuiBind(STN_BIND_WIN_GEOM),
        JsonBool(FALSE), JsonBool(FALSE), JsonBool(TRUE),
        JsonBool(TRUE),  JsonBool(FALSE));

    int nToken = NuiCreate(oPC, jWin, STN_WIN_BOOK, STN_EV_SCRIPT);
    NuiSetBind(oPC, nToken, STN_BIND_WIN_GEOM, NuiRect(fCX, fCY, fW, fH));

    SetLocalInt(oPC, STN_LVAR_SEL, StnGetActiveStance(oPC));
    FeedStanceWindow(oPC, nToken);
}
