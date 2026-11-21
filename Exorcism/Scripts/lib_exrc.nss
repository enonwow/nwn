#include "lib_exrc_def"

// ================================================================
// Possession effects
// ================================================================

void ExrcRemovePossessionEffects(object oPC)
{
    effect eEff = GetFirstEffect(oPC);
    while(GetIsEffectValid(eEff))
    {
        if(GetEffectTag(eEff) == EXRC_EFFECT_TAG)
            RemoveEffect(oPC, eEff);
        eEff = GetNextEffect(oPC);
    }
}

void ExrcApplyPossessionEffects(object oPC, int nLevel)
{
    ExrcRemovePossessionEffects(oPC);
    if(nLevel == EXRC_LEVEL_CLEAN) return;

    if(nLevel >= EXRC_LEVEL_WHISPERS)
    {
        // -2 CHA — głos demona drwi z twojej osobowości
        effect eCha = EffectAbilityDecrease(ABILITY_CHARISMA, 2);
        eCha = TagEffect(eCha, EXRC_EFFECT_TAG);
        ApplyEffectToObject(DURATION_TYPE_PERMANENT, eCha, oPC);
    }

    if(nLevel >= EXRC_LEVEL_DOMINATED)
    {
        // -2 WIS, -10% ruch — demon przejmuje kontrolę nad umysłem
        effect eWis = EffectAbilityDecrease(ABILITY_WISDOM, 2);
        eWis = TagEffect(eWis, EXRC_EFFECT_TAG);
        ApplyEffectToObject(DURATION_TYPE_PERMANENT, eWis, oPC);

        effect eSpd = EffectMovementSpeedDecrease(15);
        eSpd = TagEffect(eSpd, EXRC_EFFECT_TAG);
        ApplyEffectToObject(DURATION_TYPE_PERMANENT, eSpd, oPC);
    }

    if(nLevel >= EXRC_LEVEL_MANIFESTED)
    {
        // -4 STR, wizualny efekt (purpurowa aura) — demon jest w pełni obecny
        effect eStr = EffectAbilityDecrease(ABILITY_STRENGTH, 4);
        eStr = TagEffect(eStr, EXRC_EFFECT_TAG);
        ApplyEffectToObject(DURATION_TYPE_PERMANENT, eStr, oPC);

        effect eVfx = EffectVisualEffect(VFX_DUR_AURA_COLD_PROTECTION_10);
        eVfx = TagEffect(eVfx, EXRC_EFFECT_TAG);
        ApplyEffectToObject(DURATION_TYPE_PERMANENT, eVfx, oPC);
    }
}

void ExrcInflictPossession(object oPC, int nLevel, string sEntity)
{
    int nCurrent = ExrcGetLevel(oPC);
    if(nLevel <= nCurrent) return;    // nie obniżamy poziomu tą funkcją

    ExrcSavePossession(oPC, nLevel, sEntity);
    ExrcApplyPossessionEffects(oPC, nLevel);

    string sMsg;
    if(nLevel == EXRC_LEVEL_WHISPERS)
        sMsg = "[Egzorcyzm] Coś wdziera się w twój umysł... szepty, których nie chcesz słyszeć.";
    else if(nLevel == EXRC_LEVEL_DOMINATED)
        sMsg = "[Egzorcyzm] " + sEntity + " zaciska uścisk na twojej woli. Czujesz jak tracisz siebie.";
    else
        sMsg = "[Egzorcyzm] " + sEntity + " przebija się przez zasłonę. Twoje ciało nie należy już do ciebie.";

    SendMessageToPC(oPC, sMsg);
    FloatingTextStringOnCreature(sMsg, oPC, FALSE);
}

// ================================================================
// Whisper scheduler (called from heartbeat)
// ================================================================

const string EXRC_WHISPER_LVAR = "EXRC_WHISPER_IDX";

void ExrcSendWhisper(object oPC)
{
    int nLevel = ExrcGetLevel(oPC);
    if(nLevel == EXRC_LEVEL_CLEAN) return;

    json jRecord = ExrcGetRecord(oPC);
    string sEntity = JsonGetString(JsonObjectGet(jRecord, "entity_name"));
    if(sEntity == "") sEntity = "Nieznana Istota";

    int nIdx = GetLocalInt(oPC, EXRC_WHISPER_LVAR);

    string sText;
    if(nLevel == EXRC_LEVEL_WHISPERS)
    {
        // Ciche, niepokojące myśli
        switch(nIdx % 5)
        {
            case 0: sText = "*Szepty* ...oni wszyscy na ciebie patrzą..."; break;
            case 1: sText = "*Szepty* ...oddaj mi swój gniew..."; break;
            case 2: sText = "*Szepty* ...jesteś taki zmęczony..."; break;
            case 3: sText = "*Szepty* ...po co walczyć?..."; break;
            default: sText = "*Szepty* ...ich krew pachnie słodko..."; break;
        }
    }
    else if(nLevel == EXRC_LEVEL_DOMINATED)
    {
        switch(nIdx % 4)
        {
            case 0: sText = "[" + sEntity + " mówi przez ciebie] ...moje więzy słabną. Wkrótce będziesz wolny – ode mnie.";  break;
            case 1: sText = "[" + sEntity + " mówi przez ciebie] ...jak słodki jest twój ból."; break;
            case 2: sText = "[" + sEntity + " mówi przez ciebie] ...nikt ci nie uwierzy."; break;
            default: sText = "[" + sEntity + " mówi przez ciebie] ...czuję każdą twoją myśl."; break;
        }
    }
    else
    {
        // Manifestacja — demon mówi na głos przez postać
        SpeakString("[" + sEntity + "] Ja jestem tu teraz. To ciało moje.", TALKVOLUME_TALK);
        sText = "[Egzorcyzm] Czarna zasłona spada na twoje oczy na chwilę.";
        ApplyEffectToObject(DURATION_TYPE_TEMPORARY,
            EffectVisualEffect(VFX_DUR_BLUR), oPC, 4.0);
    }

    if(sText != "")
        FloatingTextStringOnCreature(sText, oPC, FALSE);

    SetLocalInt(oPC, EXRC_WHISPER_LVAR, nIdx + 1);
}

// ================================================================
// NUI — detect window
// ================================================================

void ExrcOpenDetectWindow(object oPC, object oTarget)
{
    if(NuiFindWindow(oPC, EXRC_WIN_DETECT) != 0)
        NuiDestroy(oPC, NuiFindWindow(oPC, EXRC_WIN_DETECT));

    float fW = GetNuiScaleDimension(oPC, EXRC_DET_W);
    float fH = GetNuiScaleDimension(oPC, EXRC_DET_H);
    float fX = (IntToFloat(GetPlayerDeviceProperty(oPC, PLAYER_DEVICE_PROPERTY_GUI_WIDTH))  - fW) / 2.0;
    float fY = (IntToFloat(GetPlayerDeviceProperty(oPC, PLAYER_DEVICE_PROPERTY_GUI_HEIGHT)) - fH) / 2.0;
    float fBtnH = GetNuiScaleDimension(oPC, 30.0);
    float fRowH = GetNuiScaleDimension(oPC, 24.0);

    // -- Header label --
    json jName = NuiLabel(NuiBind(EXRC_BIND_DET_NAME),
        JsonInt(NUI_HALIGN_LEFT), JsonInt(NUI_VALIGN_MIDDLE));
    jName = NuiHeight(jName, fRowH);

    json jLvl = NuiLabel(NuiBind(EXRC_BIND_DET_LVL),
        JsonInt(NUI_HALIGN_LEFT), JsonInt(NUI_VALIGN_MIDDLE));
    jLvl = NuiHeight(jLvl, fRowH);
    jLvl = NuiStyleForegroundColor(jLvl, NuiBind(EXRC_BIND_LVL_COL));

    json jEnt = NuiLabel(NuiBind(EXRC_BIND_DET_ENT),
        JsonInt(NUI_HALIGN_LEFT), JsonInt(NUI_VALIGN_MIDDLE));
    jEnt = NuiHeight(jEnt, fRowH);

    json jAge = NuiLabel(NuiBind(EXRC_BIND_DET_AGE),
        JsonInt(NUI_HALIGN_LEFT), JsonInt(NUI_VALIGN_MIDDLE));
    jAge = NuiHeight(jAge, fRowH);

    // -- Buttons --
    json jExrcBtn = NuiButton(JsonString("Przeprowadź egzorcyzm"));
    jExrcBtn = NuiId(jExrcBtn, EXRC_BTN_EXORCISE);
    jExrcBtn = NuiEnabled(jExrcBtn, NuiBind(EXRC_BIND_DET_EXNA));
    jExrcBtn = NuiWidth(jExrcBtn, GetNuiScaleDimension(oPC, 200.0));
    jExrcBtn = NuiHeight(jExrcBtn, fBtnH);

    json jCloseBtn = NuiButton(JsonString("Zamknij"));
    jCloseBtn = NuiId(jCloseBtn, EXRC_BTN_DETCLOSE);
    jCloseBtn = NuiWidth(jCloseBtn, GetNuiScaleDimension(oPC, 80.0));
    jCloseBtn = NuiHeight(jCloseBtn, fBtnH);

    json jBtnRow = JsonArray();
    jBtnRow = JsonArrayInsert(jBtnRow, jExrcBtn);
    jBtnRow = JsonArrayInsert(jBtnRow, NuiSpacer());
    jBtnRow = JsonArrayInsert(jBtnRow, jCloseBtn);

    json jCol = JsonArray();
    jCol = JsonArrayInsert(jCol, jName);
    jCol = JsonArrayInsert(jCol, jLvl);
    jCol = JsonArrayInsert(jCol, jEnt);
    jCol = JsonArrayInsert(jCol, jAge);
    jCol = JsonArrayInsert(jCol, CreateEmptyRow(oPC, 8.0));
    jCol = JsonArrayInsert(jCol, NuiRow(jBtnRow));

    json jWin = NuiWindow(NuiCol(jCol),
        JsonString("Badanie duszy"),
        NuiRect(fX, fY, fW, fH),
        JsonBool(FALSE), JsonBool(FALSE), JsonBool(TRUE),
        JsonBool(FALSE), JsonBool(TRUE));

    int nToken = NuiCreate(oPC, jWin, EXRC_WIN_DETECT, EXRC_EV_SCRIPT);

    // -- Feed binds --
    SetLocalObject(oPC, EXRC_LVAR_TARGET, oTarget);
    int nLevel     = ExrcGetLevel(oTarget);
    json jRecord   = ExrcGetRecord(oTarget);
    string sEntity = "";
    int nAge       = 0;
    if(JsonGetType(jRecord) != JSON_TYPE_NULL)
    {
        sEntity = JsonGetString(JsonObjectGet(jRecord, "entity_name"));
        nAge    = ExrcGetPossessionAge(oTarget);
    }

    NuiSetBind(oPC, nToken, EXRC_BIND_DET_NAME,
        JsonString("Cel: " + GetName(oTarget)));
    NuiSetBind(oPC, nToken, EXRC_BIND_DET_LVL,
        JsonString("Poziom opętania: " + ExrcGetLevelName(nLevel)));
    NuiSetBind(oPC, nToken, EXRC_BIND_LVL_COL,
        ExrcGetLevelColor(nLevel));
    NuiSetBind(oPC, nToken, EXRC_BIND_DET_ENT,
        JsonString(nLevel > 0 ? "Byt: " + sEntity : ""));
    NuiSetBind(oPC, nToken, EXRC_BIND_DET_AGE,
        JsonString(nLevel > 0 ? "Czas opętania: " + IntToString(nAge / 60) + " minut" : ""));
    NuiSetBind(oPC, nToken, EXRC_BIND_DET_EXNA,
        JsonBool(nLevel > 0));
}

// ================================================================
// NUI — ritual window
// ================================================================

json ExrcBuildSequenceRow(object oPC)
{
    // 4-slot list showing the current sequence as icons
    float fSlotSz = GetNuiScaleDimension(oPC, 52.0);
    float fRowH   = GetNuiScaleDimension(oPC, 56.0);

    json jImg = NuiImage(NuiBind(EXRC_BIND_SEQ_IMG),
        JsonInt(NUI_ASPECT_FIT), JsonInt(NUI_HALIGN_CENTER), JsonInt(NUI_VALIGN_MIDDLE));
    jImg = NuiWidth(jImg, fSlotSz);
    jImg = NuiHeight(jImg, fSlotSz);

    json jCell = NuiGroup(
        NuiRow(JsonArrayInsert(JsonArray(), jImg)),
        TRUE, NUI_SCROLLBARS_NONE);
    jCell = NuiStyleForegroundColor(jCell, NuiBind(EXRC_BIND_SEQ_COL));

    json jTmpl = JsonArrayInsert(JsonArray(),
        NuiListTemplateCell(jCell, fSlotSz + 4.0, FALSE));

    json jList = NuiList(jTmpl, NuiBind(EXRC_BIND_SEQ_CNT), fRowH);
    jList = NuiHeight(jList, fRowH + 2.0);
    return jList;
}

json ExrcBuildSymbolRow(object oPC)
{
    // 6 clickable symbol buttons
    float fSz = GetNuiScaleDimension(oPC, 60.0);
    json jRow = JsonArray();
    int i;
    for(i = 0; i < EXRC_SYMBOL_COUNT; i++)
    {
        string sId  = EXRC_BTN_SYM + IntToString(i);
        string sImg = EXRC_BIND_SYMS_IMG + IntToString(i);
        string sEna = EXRC_BIND_SYMS_ENA + IntToString(i);

        json jBtn = NuiButtonImage(NuiBind(sImg));
        jBtn = NuiId(jBtn, sId);
        jBtn = NuiWidth(jBtn, fSz);
        jBtn = NuiHeight(jBtn, fSz);
        jBtn = NuiEnabled(jBtn, NuiBind(sEna));
        jRow = JsonArrayInsert(jRow, jBtn);
    }
    return NuiRow(jRow);
}

void ExrcOpenRitualWindow(object oPC, object oTarget)
{
    if(NuiFindWindow(oPC, EXRC_WINDOW) != 0)
        NuiDestroy(oPC, NuiFindWindow(oPC, EXRC_WINDOW));

    float fCX = (IntToFloat(GetPlayerDeviceProperty(oPC, PLAYER_DEVICE_PROPERTY_GUI_WIDTH))  - GetNuiScaleDimension(oPC, EXRC_WIN_W)) / 2.0;
    float fCY = (IntToFloat(GetPlayerDeviceProperty(oPC, PLAYER_DEVICE_PROPERTY_GUI_HEIGHT)) - GetNuiScaleDimension(oPC, EXRC_WIN_H)) / 2.0;
    json jGeom = NuiRect(fCX, fCY, GetNuiScaleDimension(oPC, EXRC_WIN_W), GetNuiScaleDimension(oPC, EXRC_WIN_H));

    float fBtnH = GetNuiScaleDimension(oPC, 30.0);
    float fLblH = GetNuiScaleDimension(oPC, 22.0);

    // -- Target info header --
    json jTName = NuiLabel(NuiBind(EXRC_BIND_TNAME),
        JsonInt(NUI_HALIGN_CENTER), JsonInt(NUI_VALIGN_MIDDLE));
    jTName = NuiHeight(jTName, fLblH);

    json jLvlLbl = NuiLabel(NuiBind(EXRC_BIND_LVL_TXT),
        JsonInt(NUI_HALIGN_CENTER), JsonInt(NUI_VALIGN_MIDDLE));
    jLvlLbl = NuiHeight(jLvlLbl, fLblH);
    jLvlLbl = NuiStyleForegroundColor(jLvlLbl, NuiBind(EXRC_BIND_LVL_COL));

    json jEntLbl = NuiLabel(NuiBind(EXRC_BIND_ENT_TXT),
        JsonInt(NUI_HALIGN_CENTER), JsonInt(NUI_VALIGN_MIDDLE));
    jEntLbl = NuiHeight(jEntLbl, fLblH);

    json jWaterLbl = NuiLabel(NuiBind(EXRC_BIND_WATER),
        JsonInt(NUI_HALIGN_CENTER), JsonInt(NUI_VALIGN_MIDDLE));
    jWaterLbl = NuiHeight(jWaterLbl, fLblH);

    // -- Sequence display label --
    json jSeqLbl = NuiLabel(JsonString("Wymagana kolejność symboli:"),
        JsonInt(NUI_HALIGN_CENTER), JsonInt(NUI_VALIGN_MIDDLE));
    jSeqLbl = NuiHeight(jSeqLbl, fLblH);

    json jSeqRow = ExrcBuildSequenceRow(oPC);

    // -- Symbol keyboard --
    json jSymLbl = NuiLabel(JsonString("Aktywne symbole rytuału:"),
        JsonInt(NUI_HALIGN_CENTER), JsonInt(NUI_VALIGN_MIDDLE));
    jSymLbl = NuiHeight(jSymLbl, fLblH);

    json jSymRow = ExrcBuildSymbolRow(oPC);

    // -- Progress & timer --
    json jProgLbl = NuiLabel(NuiBind(EXRC_BIND_PROG_TXT),
        JsonInt(NUI_HALIGN_CENTER), JsonInt(NUI_VALIGN_MIDDLE));
    jProgLbl = NuiHeight(jProgLbl, fLblH);

    json jTimerLbl = NuiLabel(NuiBind(EXRC_BIND_TIMER),
        JsonInt(NUI_HALIGN_CENTER), JsonInt(NUI_VALIGN_MIDDLE));
    jTimerLbl = NuiHeight(jTimerLbl, fLblH);

    // -- Result message --
    json jResult = NuiLabel(NuiBind(EXRC_BIND_RESULT),
        JsonInt(NUI_HALIGN_CENTER), JsonInt(NUI_VALIGN_MIDDLE));
    jResult = NuiHeight(jResult, fLblH);
    jResult = NuiStyleForegroundColor(jResult, NuiBind(EXRC_BIND_RESULT_COL));

    // -- Bottom bar: Begin + Close --
    json jBeginBtn = NuiButton(JsonString("Rozpocznij rytuał"));
    jBeginBtn = NuiId(jBeginBtn, EXRC_BTN_BEGIN);
    jBeginBtn = NuiEnabled(jBeginBtn, NuiBind(EXRC_BIND_BEGIN_ENA));
    jBeginBtn = NuiWidth(jBeginBtn, GetNuiScaleDimension(oPC, 160.0));
    jBeginBtn = NuiHeight(jBeginBtn, fBtnH);

    json jCloseBtn = NuiButton(JsonString("Zamknij"));
    jCloseBtn = NuiId(jCloseBtn, EXRC_BTN_CLOSE);
    jCloseBtn = NuiWidth(jCloseBtn, GetNuiScaleDimension(oPC, 80.0));
    jCloseBtn = NuiHeight(jCloseBtn, fBtnH);

    json jBotRow = JsonArray();
    jBotRow = JsonArrayInsert(jBotRow, jBeginBtn);
    jBotRow = JsonArrayInsert(jBotRow, NuiSpacer());
    jBotRow = JsonArrayInsert(jBotRow, jCloseBtn);

    // -- Assemble column --
    json jCol = JsonArray();
    jCol = JsonArrayInsert(jCol, jTName);
    jCol = JsonArrayInsert(jCol, jLvlLbl);
    jCol = JsonArrayInsert(jCol, jEntLbl);
    jCol = JsonArrayInsert(jCol, jWaterLbl);
    jCol = JsonArrayInsert(jCol, CreateEmptyRow(oPC, 6.0));
    jCol = JsonArrayInsert(jCol, jSeqLbl);
    jCol = JsonArrayInsert(jCol, jSeqRow);
    jCol = JsonArrayInsert(jCol, CreateEmptyRow(oPC, 6.0));
    jCol = JsonArrayInsert(jCol, jSymLbl);
    jCol = JsonArrayInsert(jCol, jSymRow);
    jCol = JsonArrayInsert(jCol, CreateEmptyRow(oPC, 6.0));
    jCol = JsonArrayInsert(jCol, jProgLbl);
    jCol = JsonArrayInsert(jCol, jTimerLbl);
    jCol = JsonArrayInsert(jCol, jResult);
    jCol = JsonArrayInsert(jCol, CreateEmptyRow(oPC, 6.0));
    jCol = JsonArrayInsert(jCol, NuiRow(jBotRow));

    // -- Side spacers for centering --
    json jSide = NuiCol(JsonArrayInsert(JsonArray(), NuiSpacer()));
    float fContentW = GetNuiScaleDimension(oPC, EXRC_WIN_W - 40.0);
    json jMainRow = JsonArray();
    jMainRow = JsonArrayInsert(jMainRow, jSide);
    jMainRow = JsonArrayInsert(jMainRow, NuiWidth(NuiCol(jCol), fContentW));
    jMainRow = JsonArrayInsert(jMainRow, jSide);

    json jWin = NuiWindow(NuiRow(jMainRow),
        JsonString("Rytuał Egzorcyzmu"),
        NuiBind(EXRC_WIN_GEOM),
        JsonBool(FALSE), JsonBool(FALSE), JsonBool(FALSE),
        JsonBool(TRUE),  JsonBool(FALSE));

    int nToken = NuiCreate(oPC, jWin, EXRC_WINDOW, EXRC_EV_SCRIPT);
    NuiSetBind(oPC, nToken, EXRC_WIN_GEOM, jGeom);

    SetLocalObject(oPC, EXRC_LVAR_TARGET, oTarget);
    DeleteLocalInt(oPC, EXRC_LVAR_STARTED);
    DeleteLocalInt(oPC, EXRC_LVAR_PROGRESS);

    ExrcFeedRitual(oPC, nToken);
}

// ================================================================
// Feed / populate ritual window binds
// ================================================================

void ExrcFeedSymbolButtons(object oPC, int nToken, int bEnabled)
{
    int i;
    for(i = 0; i < EXRC_SYMBOL_COUNT; i++)
    {
        NuiSetBind(oPC, nToken,
            EXRC_BIND_SYMS_IMG + IntToString(i),
            JsonString(ExrcGetIconByIndex(i)));
        NuiSetBind(oPC, nToken,
            EXRC_BIND_SYMS_ENA + IntToString(i),
            JsonBool(bEnabled));
    }
}

void ExrcFeedSequenceDisplay(object oPC, int nToken)
{
    json jSeq   = GetLocalJson(oPC, EXRC_LVAR_SEQUENCE);
    int nProg   = GetLocalInt(oPC, EXRC_LVAR_PROGRESS);
    int nCount  = JsonGetLength(jSeq);

    json jImgs  = JsonArray();
    json jCols  = JsonArray();
    json jGreen = NuiColor( 80, 200,  80);
    json jWhite = NuiColor(220, 220, 220);
    json jGray  = NuiColor(100, 100, 100);

    int i;
    for(i = 0; i < nCount; i++)
    {
        int nSym = JsonGetInt(JsonArrayGet(jSeq, i));
        jImgs = JsonArrayInsert(jImgs, JsonString(ExrcGetIconByIndex(nSym)));
        if(i < nProg)
            jCols = JsonArrayInsert(jCols, jGreen);    // już kliknięty poprawnie
        else if(i == nProg)
            jCols = JsonArrayInsert(jCols, jWhite);    // aktualny
        else
            jCols = JsonArrayInsert(jCols, jGray);     // przyszłe
    }

    NuiSetBind(oPC, nToken, EXRC_BIND_SEQ_IMG, jImgs);
    NuiSetBind(oPC, nToken, EXRC_BIND_SEQ_COL, jCols);
    NuiSetBind(oPC, nToken, EXRC_BIND_SEQ_CNT, JsonInt(nCount));
}

void ExrcFeedRitual(object oPC, int nToken)
{
    object oTarget = GetLocalObject(oPC, EXRC_LVAR_TARGET);
    int nLevel     = ExrcGetLevel(oTarget);
    json jRecord   = ExrcGetRecord(oTarget);
    string sEntity = "";
    if(JsonGetType(jRecord) != JSON_TYPE_NULL)
        sEntity = JsonGetString(JsonObjectGet(jRecord, "entity_name"));
    if(sEntity == "") sEntity = "Nieznana Istota";

    int nWater     = ExrcCountHolyWater(oPC);
    int nCost      = ExrcWaterCost(nLevel);
    int bCanBegin  = (nLevel > 0 && nWater >= nCost);

    NuiSetBind(oPC, nToken, EXRC_BIND_TNAME,
        JsonString("Cel rytuału: " + GetName(oTarget)));
    NuiSetBind(oPC, nToken, EXRC_BIND_LVL_TXT,
        JsonString("Poziom opętania: " + ExrcGetLevelName(nLevel)));
    NuiSetBind(oPC, nToken, EXRC_BIND_LVL_COL,
        ExrcGetLevelColor(nLevel));
    NuiSetBind(oPC, nToken, EXRC_BIND_ENT_TXT,
        JsonString(nLevel > 0 ? "Byt: " + sEntity : "Dusza czysta — rytuał zbędny."));
    NuiSetBind(oPC, nToken, EXRC_BIND_WATER,
        JsonString("Święta Woda: " + IntToString(nWater) + " fiolek (wymagane: " + IntToString(nCost) + ")"));
    NuiSetBind(oPC, nToken, EXRC_BIND_BEGIN_ENA,
        JsonBool(bCanBegin && !GetLocalInt(oPC, EXRC_LVAR_STARTED)));
    NuiSetBind(oPC, nToken, EXRC_BIND_PROG_TXT,  JsonString(""));
    NuiSetBind(oPC, nToken, EXRC_BIND_TIMER,      JsonString(""));
    NuiSetBind(oPC, nToken, EXRC_BIND_RESULT,     JsonString(""));
    NuiSetBind(oPC, nToken, EXRC_BIND_RESULT_COL, NuiColor(220, 220, 220));

    // Sequence — initially empty (shown after Begin is pressed)
    NuiSetBind(oPC, nToken, EXRC_BIND_SEQ_CNT, JsonInt(0));
    NuiSetBind(oPC, nToken, EXRC_BIND_SEQ_IMG, JsonArray());
    NuiSetBind(oPC, nToken, EXRC_BIND_SEQ_COL, JsonArray());

    ExrcFeedSymbolButtons(oPC, nToken, FALSE);
}

// ================================================================
// Ritual sequence logic
// ================================================================

json ExrcGenerateSequence()
{
    // Picks EXRC_SEQ_LENGTH symbols from [0..EXRC_SYMBOL_COUNT-1],
    // repetition allowed to keep it unpredictable.
    json jSeq = JsonArray();
    int i;
    for(i = 0; i < EXRC_SEQ_LENGTH; i++)
    {
        int nSym = Random(EXRC_SYMBOL_COUNT);
        jSeq = JsonArrayInsert(jSeq, JsonInt(nSym));
    }
    return jSeq;
}

void ExrcBeginRitual(object oPC, int nToken)
{
    object oTarget = GetLocalObject(oPC, EXRC_LVAR_TARGET);
    int nLevel     = ExrcGetLevel(oTarget);
    int nCost      = ExrcWaterCost(nLevel);
    int nWater     = ExrcCountHolyWater(oPC);

    if(nLevel == EXRC_LEVEL_CLEAN)
    {
        NuiSetBind(oPC, nToken, EXRC_BIND_RESULT,
            JsonString("Dusza celu jest czysta. Rytuał zbędny."));
        return;
    }
    if(nWater < nCost)
    {
        NuiSetBind(oPC, nToken, EXRC_BIND_RESULT,
            JsonString("Niewystarczająca ilość Świętej Wody."));
        NuiSetBind(oPC, nToken, EXRC_BIND_RESULT_COL, NuiColor(200, 80, 80));
        return;
    }

    ExrcConsumeHolyWater(oPC, nCost);

    json jSeq = ExrcGenerateSequence();
    SetLocalJson(oPC, EXRC_LVAR_SEQUENCE, jSeq);
    SetLocalInt (oPC, EXRC_LVAR_PROGRESS, 0);
    SetLocalInt (oPC, EXRC_LVAR_STARTED,  1);
    SetLocalInt (oPC, EXRC_LVAR_DEADLINE, ExrcNowUnix() + FloatToInt(EXRC_RITUAL_TIMEOUT));

    NuiSetBind(oPC, nToken, EXRC_BIND_BEGIN_ENA, JsonBool(FALSE));
    NuiSetBind(oPC, nToken, EXRC_BIND_RESULT,    JsonString(""));
    ExrcFeedSymbolButtons(oPC, nToken, TRUE);
    ExrcFeedSequenceDisplay(oPC, nToken);
    ExrcTickTimer(oPC);

    // Timeout failsafe via DelayCommand
    DelayCommand(EXRC_RITUAL_TIMEOUT + 1.0, ExrcHandleTimeout(oPC));

    SendMessageToPC(oPC, "[Egzorcyzm] Rytuał rozpoczęty. Kliknij symbole w podanej kolejności!");
}

void ExrcHandleTimeout(object oPC)
{
    if(!GetLocalInt(oPC, EXRC_LVAR_STARTED)) return;

    int nNow      = ExrcNowUnix();
    int nDeadline = GetLocalInt(oPC, EXRC_LVAR_DEADLINE);
    if(nNow <= nDeadline) return;   // already handled successfully

    int nToken = NuiFindWindow(oPC, EXRC_WINDOW);
    if(nToken == 0)
    {
        DeleteLocalInt(oPC, EXRC_LVAR_STARTED);
        return;
    }

    DeleteLocalInt(oPC, EXRC_LVAR_STARTED);
    ExrcFeedSymbolButtons(oPC, nToken, FALSE);
    // Refresh header to reflect consumed holy water, then overlay failure message
    ExrcFeedRitual(oPC, nToken);
    NuiSetBind(oPC, nToken, EXRC_BIND_TIMER,      JsonString("Czas upłynął!"));
    NuiSetBind(oPC, nToken, EXRC_BIND_RESULT,     JsonString("Rytuał przerwany — demon wzmacnia swój uchwyt."));
    NuiSetBind(oPC, nToken, EXRC_BIND_RESULT_COL, NuiColor(200, 60, 60));

    // Failure penalty: deal 1d6 divine damage to exorcist; risk level increase
    ApplyEffectToObject(DURATION_TYPE_INSTANT,
        EffectDamage(d6(1), DAMAGE_TYPE_DIVINE), oPC);
    SendMessageToPC(oPC, "[Egzorcyzm] Niepowodzenie! Demon odpycha twoje zaklęcia.");

    // Small chance (25%) the possession level rises on failure
    if(Random(4) == 0)
    {
        object oTarget = GetLocalObject(oPC, EXRC_LVAR_TARGET);
        int nLevel     = ExrcGetLevel(oTarget);
        if(nLevel < EXRC_LEVEL_MANIFESTED)
        {
            json jRecord = ExrcGetRecord(oTarget);
            string sEntity = JsonGetString(JsonObjectGet(jRecord, "entity_name"));
            ExrcInflictPossession(oTarget, nLevel + 1, sEntity);
            SendMessageToPC(oPC, "[Egzorcyzm] Demon zyskał na sile!");
        }
    }
}

void ExrcTickTimer(object oPC)
{
    int nToken = NuiFindWindow(oPC, EXRC_WINDOW);
    if(nToken == 0 || !GetLocalInt(oPC, EXRC_LVAR_STARTED)) return;

    int nNow      = ExrcNowUnix();
    int nDeadline = GetLocalInt(oPC, EXRC_LVAR_DEADLINE);
    int nLeft     = nDeadline - nNow;
    if(nLeft < 0) nLeft = 0;

    NuiSetBind(oPC, nToken, EXRC_BIND_TIMER,
        JsonString("Pozostało czasu: " + IntToString(nLeft) + "s"));

    if(nLeft > 0)
        DelayCommand(1.0, ExrcTickTimer(oPC));
}

void ExrcHandleSymbolClick(object oPC, int nToken, int nSym)
{
    if(!GetLocalInt(oPC, EXRC_LVAR_STARTED)) return;

    int nNow      = ExrcNowUnix();
    int nDeadline = GetLocalInt(oPC, EXRC_LVAR_DEADLINE);
    if(nNow > nDeadline)
    {
        ExrcHandleTimeout(oPC);
        return;
    }

    json jSeq  = GetLocalJson(oPC, EXRC_LVAR_SEQUENCE);
    int nProg  = GetLocalInt(oPC, EXRC_LVAR_PROGRESS);
    int nExpected = JsonGetInt(JsonArrayGet(jSeq, nProg));

    if(nSym == nExpected)
    {
        nProg++;
        SetLocalInt(oPC, EXRC_LVAR_PROGRESS, nProg);
        ExrcFeedSequenceDisplay(oPC, nToken);

        if(nProg >= EXRC_SEQ_LENGTH)
        {
            // SUCCESS — persist new level before feeding the window header
            DeleteLocalInt(oPC, EXRC_LVAR_STARTED);

            object oTarget = GetLocalObject(oPC, EXRC_LVAR_TARGET);
            int nLevel     = ExrcGetLevel(oTarget);
            int nNewLevel  = nLevel - 1;

            json jRecord   = ExrcGetRecord(oTarget);
            string sEntity = JsonGetString(JsonObjectGet(jRecord, "entity_name"));
            ExrcSavePossession(oTarget, nNewLevel, sEntity);
            ExrcApplyPossessionEffects(oTarget, nNewLevel);

            // Refresh header (reads new level from DB), then overlay success message
            ExrcFeedSymbolButtons(oPC, nToken, FALSE);
            ExrcFeedRitual(oPC, nToken);
            NuiSetBind(oPC, nToken, EXRC_BIND_RESULT,
                JsonString("Rytuał zakończony. Demon osłabł!"));
            NuiSetBind(oPC, nToken, EXRC_BIND_RESULT_COL, NuiColor(80, 200, 80));

            if(nNewLevel == EXRC_LEVEL_CLEAN)
            {
                SendMessageToPC(oPC,     "[Egzorcyzm] Demon wypędzony! Dusza celu jest wolna.");
                SendMessageToPC(oTarget, "[Egzorcyzm] Czujesz jak ciemność opuszcza twój umysł. Jesteś wolny.");
                FloatingTextStringOnCreature("Opętanie zdjęte!", oTarget, FALSE);
            }
            else
            {
                string sNewName = ExrcGetLevelName(nNewLevel);
                SendMessageToPC(oPC,     "[Egzorcyzm] Poziom opętania obniżony do: " + sNewName + ". Kolejny rytuał potrzebny.");
                SendMessageToPC(oTarget, "[Egzorcyzm] Czujesz chwilową ulgę... ale ciemność wciąż czai się wewnątrz.");
            }
        }
    }
    else
    {
        // WRONG SYMBOL
        DeleteLocalInt(oPC, EXRC_LVAR_STARTED);
        ExrcFeedSymbolButtons(oPC, nToken, FALSE);
        // Refresh header to reflect consumed holy water, then overlay failure message
        ExrcFeedRitual(oPC, nToken);
        NuiSetBind(oPC, nToken, EXRC_BIND_TIMER,      JsonString(""));
        NuiSetBind(oPC, nToken, EXRC_BIND_RESULT,
            JsonString("Błędny symbol! Rytuał przerwany."));
        NuiSetBind(oPC, nToken, EXRC_BIND_RESULT_COL, NuiColor(200, 60, 60));

        // Wrong symbol always deals damage
        ApplyEffectToObject(DURATION_TYPE_INSTANT,
            EffectDamage(d6(1), DAMAGE_TYPE_DIVINE), oPC);
        SendMessageToPC(oPC, "[Egzorcyzm] Nieprawidłowa sekwencja! Demon odpycha cię siłą.");

        // 25% chance level rises
        if(Random(4) == 0)
        {
            object oTarget = GetLocalObject(oPC, EXRC_LVAR_TARGET);
            int nLevel     = ExrcGetLevel(oTarget);
            if(nLevel < EXRC_LEVEL_MANIFESTED)
            {
                json jRecord = ExrcGetRecord(oTarget);
                string sEntity = JsonGetString(JsonObjectGet(jRecord, "entity_name"));
                ExrcInflictPossession(oTarget, nLevel + 1, sEntity);
                SendMessageToPC(oPC, "[Egzorcyzm] Demon zyskał na sile wskutek błędu!");
            }
        }
    }
}
