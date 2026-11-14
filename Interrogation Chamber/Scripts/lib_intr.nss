#include "lib_intr_def"

// ----------------------------------------------------------------
// Resistance helpers
// ----------------------------------------------------------------

int IntrCalcStartingResistance(object oPrisoner)
{
    int nWisMod = GetAbilityModifier(ABILITY_WISDOM, oPrisoner);
    int nHD     = GetHitDice(oPrisoner);
    int nRes    = INTR_RES_BASE + nWisMod * 5 + (nHD / 4) * 5;
    if(nRes < INTR_RES_MIN) nRes = INTR_RES_MIN;
    if(nRes > INTR_RES_MAX) nRes = INTR_RES_MAX;
    return nRes;
}

int IntrGetResistance(object oPC, string sPrisonerUUID)
{
    return GetLocalInt(oPC, INTR_LVAR_RESISTANCE + "_" + sPrisonerUUID);
}

void IntrSetResistance(object oPC, string sPrisonerUUID, int nRes)
{
    if(nRes < 0)             nRes = 0;
    if(nRes > INTR_RES_MAX)  nRes = INTR_RES_MAX;
    SetLocalInt(oPC, INTR_LVAR_RESISTANCE + "_" + sPrisonerUUID, nRes);
}

// ----------------------------------------------------------------
// Log management  — keeps last 6 lines
// ----------------------------------------------------------------

void IntrAppendLog(object oPC, int nToken, string sLine)
{
    string sLog  = GetLocalString(oPC, INTR_LVAR_LOG);
    string sNew  = (sLog == "") ? sLine : (sLog + "\n" + sLine);

    // Trim to 6 lines from the front
    int nLines = 1;
    string sTmp = sNew;
    int nPos    = FindSubString(sTmp, "\n");
    while(nPos >= 0)
    {
        nLines++;
        sTmp = GetStringRight(sTmp, GetStringLength(sTmp) - nPos - 1);
        nPos = FindSubString(sTmp, "\n");
    }
    while(nLines > 6)
    {
        int nIdx = FindSubString(sNew, "\n");
        sNew = GetStringRight(sNew, GetStringLength(sNew) - nIdx - 1);
        nLines--;
    }

    SetLocalString(oPC, INTR_LVAR_LOG, sNew);
    NuiSetBind(oPC, nToken, INTR_BIND_LOG, JsonString(sNew));
}

// ----------------------------------------------------------------
// Moral cost
// ----------------------------------------------------------------

void IntrAddMoralCost(object oPC, int nCost)
{
    int nTotal = GetLocalInt(oPC, INTR_LVAR_MORAL_COST) + nCost;
    SetLocalInt(oPC, INTR_LVAR_MORAL_COST, nTotal);
}

void IntrApplyMoralPenalty(object oPC)
{
    int nCost = GetLocalInt(oPC, INTR_LVAR_MORAL_COST);
    if(nCost < INTR_MORAL_THRESHOLD) return;

    int nShifts = nCost / INTR_MORAL_THRESHOLD;
    int i;
    for(i = 0; i < nShifts; i++)
        AdjustAlignment(oPC, ALIGNMENT_EVIL, 5, FALSE);

    SetLocalInt(oPC, INTR_LVAR_MORAL_COST, nCost - nShifts * INTR_MORAL_THRESHOLD);
    SendMessageToPC(oPC, "[Przesluchanie] Twoje czyny pozostawiaja ciemny slad na duszy.");
}

// ----------------------------------------------------------------
// Secret revelation at resistance thresholds
// ----------------------------------------------------------------

void IntrRevealSecret(object oPC, int nToken, object oPrisoner, int nThreshold)
{
    string sResRef = GetResRef(oPrisoner);

    // Custom LVAR on creature takes precedence
    string sSecret = GetLocalString(oPrisoner, "INTR_SECRET_" + IntToString(nThreshold));
    if(sSecret == "")
        sSecret = IntrGetConfession(sResRef, nThreshold);
    if(sSecret == "")
        sSecret = IntrGetGenericSecret(GetRacialType(oPrisoner), nThreshold);

    string sHeader;
    if(nThreshold == 75)      sHeader = "> Wiezien zdradza drobne informacje...";
    else if(nThreshold == 50) sHeader = "> Wiezien przyznaje istotne fakty...";
    else if(nThreshold == 25) sHeader = "> Zlaman, wiezien wyznaje prawde...";
    else                      sHeader = "> Wiezien calkowicie sie poddal.";

    IntrAppendLog(oPC, nToken, sHeader);

    if(sSecret != "")
    {
        IntrAppendLog(oPC, nToken, "  \"" + sSecret + "\"");
        SendMessageToPC(oPC, "[Przesluchanie] " + sSecret);
    }

    IntrLogConfession(GetObjectUUID(oPC), GetObjectUUID(oPrisoner),
                      GetName(oPrisoner), nThreshold, sSecret);
}

void IntrCheckThresholds(object oPC, int nToken, object oPrisoner, int nOldRes, int nNewRes)
{
    string sUUID = GetObjectUUID(oPrisoner);

    if(nOldRes > 75 && nNewRes <= 75
       && !GetLocalInt(oPC, INTR_LVAR_THRESHOLD_75 + sUUID))
    {
        SetLocalInt(oPC, INTR_LVAR_THRESHOLD_75 + sUUID, 1);
        IntrRevealSecret(oPC, nToken, oPrisoner, 75);
    }
    if(nOldRes > 50 && nNewRes <= 50
       && !GetLocalInt(oPC, INTR_LVAR_THRESHOLD_50 + sUUID))
    {
        SetLocalInt(oPC, INTR_LVAR_THRESHOLD_50 + sUUID, 1);
        IntrRevealSecret(oPC, nToken, oPrisoner, 50);
    }
    if(nOldRes > 25 && nNewRes <= 25
       && !GetLocalInt(oPC, INTR_LVAR_THRESHOLD_25 + sUUID))
    {
        SetLocalInt(oPC, INTR_LVAR_THRESHOLD_25 + sUUID, 1);
        IntrRevealSecret(oPC, nToken, oPrisoner, 25);
    }
    if(nOldRes > 0 && nNewRes <= 0
       && !GetLocalInt(oPC, INTR_LVAR_THRESHOLD_0 + sUUID))
    {
        SetLocalInt(oPC, INTR_LVAR_THRESHOLD_0 + sUUID, 1);
        SetLocalInt(oPC, INTR_LVAR_BROKEN + sUUID, 1);
        IntrRevealSecret(oPC, nToken, oPrisoner, 0);

        // Broken prisoner gains permanent Frightened
        effect eFear = EffectFrightened();
        effect eVis  = EffectVisualEffect(VFX_DUR_MIND_AFFECTING_FEAR);
        ApplyEffectToObject(DURATION_TYPE_PERMANENT,
                            EffectLinkEffects(eFear, eVis), oPrisoner);
    }
}

// ----------------------------------------------------------------
// Find prisoner object by stored UUID (searches area)
// ----------------------------------------------------------------

object IntrFindPrisoner(object oPC, string sPrisonerUUID)
{
    object oArea = GetArea(oPC);
    object oObj  = GetFirstObjectInArea(oArea);
    while(GetIsObjectValid(oObj))
    {
        if(GetObjectUUID(oObj) == sPrisonerUUID)
            return oObj;
        oObj = GetNextObjectInArea(oArea);
    }
    return OBJECT_INVALID;
}

// ----------------------------------------------------------------
// Method resolution — called from event handler
// ----------------------------------------------------------------

void IntrApplyMethod(object oPC, int nMethod)
{
    int    nToken        = NuiFindWindow(oPC, INTR_WINDOW);
    if(nToken == 0) return;

    string sPrisonerUUID = GetLocalString(oPC, INTR_LVAR_PRISONER_UUID);
    object oPrisoner     = IntrFindPrisoner(oPC, sPrisonerUUID);

    if(!GetIsObjectValid(oPrisoner) || GetIsDead(oPrisoner))
    {
        IntrAppendLog(oPC, nToken, "> Wiezien jest poza zasiegiem lub nie zyje.");
        NuiSetBind(oPC, nToken, INTR_BIND_BTN_Q_ENA, JsonBool(FALSE));
        NuiSetBind(oPC, nToken, INTR_BIND_BTN_I_ENA, JsonBool(FALSE));
        NuiSetBind(oPC, nToken, INTR_BIND_BTN_T_ENA, JsonBool(FALSE));
        NuiSetBind(oPC, nToken, INTR_BIND_BTN_D_ENA, JsonBool(FALSE));
        return;
    }

    int nRes    = IntrGetResistance(oPC, sPrisonerUUID);
    int nOldRes = nRes;
    int nMoral  = 0;
    string sMsg = "";
    int bDied   = FALSE;

    if(nRes <= 0)
    {
        IntrAppendLog(oPC, nToken, "> Wiezien jest juz calkowicie zlaman.");
        return;
    }

    switch(nMethod)
    {
        case INTR_METHOD_QUESTION:
        {
            int nCheck = d20() + GetSkillRank(SKILL_LORE, oPC, TRUE);
            int nDC    = 12 + GetAbilityModifier(ABILITY_WISDOM, oPrisoner);
            if(nCheck >= nDC)
            {
                nRes -= 20;
                sMsg  = "> Pytania trafiaja w czuly punkt. Wiezien sie potyka. (-20 oporu)";
            }
            else
            {
                nRes -= 5;
                sMsg  = "> Wiezien zaciska usta. Niewiele zdradza. (-5 oporu)";
            }
            nMoral = 0;
            break;
        }

        case INTR_METHOD_INTIMIDATE:
        {
            int nCheck = d20() + GetSkillRank(SKILL_INTIMIDATE, oPC, TRUE);
            int nDC    = 10 + GetAbilityModifier(ABILITY_STRENGTH, oPrisoner) * 2;
            if(nCheck >= nDC)
            {
                nRes -= 25;
                sMsg  = "> Wiezien drzy pod spojrzeniem. Zaczyna mowic. (-25 oporu)";
                // Brief shake effect on prisoner
                ApplyEffectToObject(DURATION_TYPE_TEMPORARY,
                    EffectVisualEffect(VFX_DUR_MIND_AFFECTING_FEAR), oPrisoner, 3.0f);
            }
            else
            {
                nRes -= 10;
                sMsg  = "> Wiezien wytrzymuje grozby. Lecz i tak placi cene. (-10 oporu)";
            }
            nMoral = 1;
            break;
        }

        case INTR_METHOD_TORTURE:
        {
            nRes  -= 30;
            nMoral = 3;
            sMsg   = "> Tortury lamia kazde cialo i ducha. (-30 oporu)";

            // Risk of premature death when prisoner is already weak
            if(nOldRes <= 25 && d100() <= INTR_TORTURE_DEATH_ROLL)
            {
                IntrAppendLog(oPC, nToken, "> Wiezien nie przezywa sesji.");
                SendMessageToPC(oPC, "[Przesluchanie] Wiezien zmarl, zanim ujawnil wszystkie sekrety.");
                ApplyEffectToObject(DURATION_TYPE_INSTANT,
                    EffectDeath(TRUE, FALSE), oPrisoner);
                bDied  = TRUE;
                nRes   = 0;
            }
            break;
        }

        case INTR_METHOD_DECEIVE:
        {
            int nCheck = d20() + GetSkillRank(SKILL_BLUFF, oPC, TRUE);
            int nDC    = 11 + GetAbilityModifier(ABILITY_WISDOM, oPrisoner) * 2;
            if(nCheck >= nDC)
            {
                nRes -= 35;
                sMsg  = "> Podstep zadzialal — wiezien daje sie nabrec i mowi. (-35 oporu)";
            }
            else
            {
                nRes += 10;
                if(nRes > INTR_RES_MAX) nRes = INTR_RES_MAX;
                sMsg  = "> Wiezien przejrzal klamstwo. Staje sie bardziej nieufny. (+10 oporu)";
            }
            nMoral = 1;
            break;
        }
    }

    IntrSetResistance(oPC, sPrisonerUUID, nRes);
    IntrAddMoralCost(oPC, nMoral);
    IntrAppendLog(oPC, nToken, sMsg);

    if(!bDied)
        IntrCheckThresholds(oPC, nToken, oPrisoner, nOldRes, nRes);

    IntrFeedStatus(oPC, nToken);
}

// ----------------------------------------------------------------
// Feed: update all dynamic binds from current state
// ----------------------------------------------------------------

void IntrFeedStatus(object oPC, int nToken)
{
    string sUUID = GetLocalString(oPC, INTR_LVAR_PRISONER_UUID);
    int nRes     = IntrGetResistance(oPC, sUUID);
    int nMoral   = GetLocalInt(oPC, INTR_LVAR_MORAL_COST);
    int nBroken  = GetLocalInt(oPC, INTR_LVAR_BROKEN + sUUID);

    float fRes = IntToFloat(nRes) / IntToFloat(INTR_RES_MAX);
    NuiSetBind(oPC, nToken, INTR_BIND_RESISTANCE, JsonFloat(fRes));
    NuiSetBind(oPC, nToken, INTR_BIND_RES_LABEL,
               JsonString("Opor: " + IntToString(nRes) + " / " + IntToString(INTR_RES_MAX)));

    json jResColor;
    if(nRes > 60)      jResColor = NuiColor(60, 180, 60);
    else if(nRes > 30) jResColor = NuiColor(200, 160, 30);
    else               jResColor = NuiColor(200, 50, 50);
    NuiSetBind(oPC, nToken, INTR_BIND_RES_COLOR, jResColor);

    string sMoral = "Skaza moralna: " + IntToString(nMoral);
    if(nMoral >= INTR_MORAL_THRESHOLD)
        sMoral = sMoral + "  (kara przy zamknieciu)";
    NuiSetBind(oPC, nToken, INTR_BIND_MORAL_LABEL, JsonString(sMoral));

    int bActive = (nRes > 0 && !nBroken);
    NuiSetBind(oPC, nToken, INTR_BIND_BTN_Q_ENA, JsonBool(bActive));
    NuiSetBind(oPC, nToken, INTR_BIND_BTN_I_ENA, JsonBool(bActive));
    NuiSetBind(oPC, nToken, INTR_BIND_BTN_T_ENA, JsonBool(bActive));
    NuiSetBind(oPC, nToken, INTR_BIND_BTN_D_ENA, JsonBool(bActive));

    string sStatus;
    json   jStatusColor;
    if(nBroken || nRes <= 0)
    {
        sStatus      = "ZLAMAN";
        jStatusColor = NuiColor(200, 50, 50);
    }
    else if(nRes < 30)
    {
        sStatus      = "BLISKI ZLAMANIA";
        jStatusColor = NuiColor(200, 100, 30);
    }
    else if(nRes < 60)
    {
        sStatus      = "OSLABIONY";
        jStatusColor = NuiColor(200, 160, 30);
    }
    else
    {
        sStatus      = "OPIERA SIE";
        jStatusColor = NuiColor(60, 180, 60);
    }
    NuiSetBind(oPC, nToken, INTR_BIND_STATUS,       JsonString(sStatus));
    NuiSetBind(oPC, nToken, INTR_BIND_STATUS_COLOR,  jStatusColor);
}

// ----------------------------------------------------------------
// Window construction
// ----------------------------------------------------------------

json IntrBuildLayout(object oPC, object oPrisoner)
{
    float fBtnH  = GetNuiScaleDimension(oPC, 32.0);
    float fLblH  = GetNuiScaleDimension(oPC, 22.0);
    float fBarH  = GetNuiScaleDimension(oPC, 20.0);

    // ---- Title row ----
    json jTitleLbl = NuiLabel(JsonString("IZBA PRZESLUCHAN"),
        JsonInt(NUI_HALIGN_LEFT), JsonInt(NUI_VALIGN_MIDDLE));
    jTitleLbl = NuiHeight(jTitleLbl, fBtnH);

    json jClose = NuiButton(JsonString("x"));
    jClose = NuiId(jClose, INTR_BTN_CLOSE);
    jClose = NuiWidth(jClose,  GetNuiScaleDimension(oPC, 30.0));
    jClose = NuiHeight(jClose, fBtnH);

    json jTitleRow = JsonArray();
    jTitleRow = JsonArrayInsert(jTitleRow, jTitleLbl);
    jTitleRow = JsonArrayInsert(jTitleRow, jClose);

    // ---- Prisoner name ----
    json jNameLbl = NuiLabel(NuiBind(INTR_BIND_PRISONER_NAME),
        JsonInt(NUI_HALIGN_CENTER), JsonInt(NUI_VALIGN_MIDDLE));
    jNameLbl = NuiHeight(jNameLbl, fLblH);

    // ---- Prisoner type / race ----
    json jTypeLbl = NuiLabel(NuiBind(INTR_BIND_PRISONER_TYPE),
        JsonInt(NUI_HALIGN_CENTER), JsonInt(NUI_VALIGN_MIDDLE));
    jTypeLbl = NuiHeight(jTypeLbl, fLblH);
    jTypeLbl = NuiStyleForegroundColor(jTypeLbl, NuiColor(160, 130, 100));

    // ---- HD label ----
    json jHdLbl = NuiLabel(NuiBind(INTR_BIND_HD_LABEL),
        JsonInt(NUI_HALIGN_CENTER), JsonInt(NUI_VALIGN_MIDDLE));
    jHdLbl = NuiHeight(jHdLbl, fLblH);
    jHdLbl = NuiStyleForegroundColor(jHdLbl, NuiColor(120, 110, 90));

    // ---- Resistance bar ----
    json jResBar = NuiProgressBar(NuiBind(INTR_BIND_RESISTANCE));
    jResBar = NuiHeight(jResBar, fBarH);
    jResBar = NuiStyleForegroundColor(jResBar, NuiBind(INTR_BIND_RES_COLOR));

    json jResLbl = NuiLabel(NuiBind(INTR_BIND_RES_LABEL),
        JsonInt(NUI_HALIGN_CENTER), JsonInt(NUI_VALIGN_MIDDLE));
    jResLbl = NuiHeight(jResLbl, fLblH);

    // ---- Status ----
    json jStatus = NuiLabel(NuiBind(INTR_BIND_STATUS),
        JsonInt(NUI_HALIGN_CENTER), JsonInt(NUI_VALIGN_MIDDLE));
    jStatus = NuiHeight(jStatus, fLblH);
    jStatus = NuiStyleForegroundColor(jStatus, NuiBind(INTR_BIND_STATUS_COLOR));

    // ---- Method buttons ----
    json jBtnQ = NuiButton(JsonString("Przesluchanie  (INT / Wiedza)"));
    jBtnQ = NuiId(jBtnQ, INTR_BTN_QUESTION);
    jBtnQ = NuiEnabled(jBtnQ, NuiBind(INTR_BIND_BTN_Q_ENA));
    jBtnQ = NuiHeight(jBtnQ, fBtnH);
    jBtnQ = NuiTooltip(jBtnQ, JsonString(
        "Spokojne pytania — bez kosztu moralnego. Test: INT + Wiedza."));

    json jBtnI = NuiButton(JsonString("Zastraszenie  (SIL / Zastraszanie)"));
    jBtnI = NuiId(jBtnI, INTR_BTN_INTIMIDATE);
    jBtnI = NuiEnabled(jBtnI, NuiBind(INTR_BIND_BTN_I_ENA));
    jBtnI = NuiHeight(jBtnI, fBtnH);
    jBtnI = NuiTooltip(jBtnI, JsonString(
        "Grozby i przemoc psychiczna. Koszt moralny: 1. Test: SIL + Zastraszanie."));

    json jBtnT = NuiButton(JsonString("Tortury  (pewne — ryzyko smierci)"));
    jBtnT = NuiId(jBtnT, INTR_BTN_TORTURE);
    jBtnT = NuiEnabled(jBtnT, NuiBind(INTR_BIND_BTN_T_ENA));
    jBtnT = NuiHeight(jBtnT, fBtnH);
    jBtnT = NuiStyleForegroundColor(jBtnT, NuiColor(190, 60, 60));
    jBtnT = NuiTooltip(jBtnT, JsonString(
        "Pewne -30 oporu, brak testu. Koszt moralny: 3. "
        "Przy niskim oporze: 8% szansa smierci wieznia."));

    json jBtnD = NuiButton(JsonString("Podstep  (CHA / Blef)"));
    jBtnD = NuiId(jBtnD, INTR_BTN_DECEIVE);
    jBtnD = NuiEnabled(jBtnD, NuiBind(INTR_BIND_BTN_D_ENA));
    jBtnD = NuiHeight(jBtnD, fBtnH);
    jBtnD = NuiTooltip(jBtnD, JsonString(
        "Sukces: -35 oporu. Porazka: wiezien zyskuje +10 oporu. "
        "Koszt moralny: 1. Test: CHA + Blef."));

    // ---- Moral cost label ----
    json jMoralLbl = NuiLabel(NuiBind(INTR_BIND_MORAL_LABEL),
        JsonInt(NUI_HALIGN_CENTER), JsonInt(NUI_VALIGN_MIDDLE));
    jMoralLbl = NuiHeight(jMoralLbl, fLblH);
    jMoralLbl = NuiStyleForegroundColor(jMoralLbl, NuiColor(160, 80, 80));

    // ---- Log area ----
    json jLogText = NuiText(NuiBind(INTR_BIND_LOG), FALSE);
    json jLogGrp  = NuiGroup(jLogText, TRUE, NUI_SCROLLBARS_Y);
    jLogGrp = NuiHeight(jLogGrp, GetNuiScaleDimension(oPC, 100.0));

    // ---- Assemble column ----
    json jCol = JsonArray();
    jCol = JsonArrayInsert(jCol, NuiRow(jTitleRow));
    jCol = JsonArrayInsert(jCol, CreateEmptyRow(oPC, 4.0));

    json jNameCol = JsonArrayInsert(JsonArray(), jNameLbl);
    jCol = JsonArrayInsert(jCol, NuiRow(jNameCol));

    json jTypeCol = JsonArrayInsert(JsonArray(), jTypeLbl);
    jCol = JsonArrayInsert(jCol, NuiRow(jTypeCol));

    json jHdCol = JsonArrayInsert(JsonArray(), jHdLbl);
    jCol = JsonArrayInsert(jCol, NuiRow(jHdCol));

    jCol = JsonArrayInsert(jCol, CreateEmptyRow(oPC, 6.0));

    json jBarCol = JsonArrayInsert(JsonArray(), jResBar);
    jCol = JsonArrayInsert(jCol, NuiRow(jBarCol));

    json jResLblCol = JsonArrayInsert(JsonArray(), jResLbl);
    jCol = JsonArrayInsert(jCol, NuiRow(jResLblCol));

    json jStatusCol = JsonArrayInsert(JsonArray(), jStatus);
    jCol = JsonArrayInsert(jCol, NuiRow(jStatusCol));

    jCol = JsonArrayInsert(jCol, CreateEmptyRow(oPC, 6.0));

    json jQCol = JsonArrayInsert(JsonArray(), jBtnQ);
    jCol = JsonArrayInsert(jCol, NuiRow(jQCol));

    json jICol = JsonArrayInsert(JsonArray(), jBtnI);
    jCol = JsonArrayInsert(jCol, NuiRow(jICol));

    json jTCol = JsonArrayInsert(JsonArray(), jBtnT);
    jCol = JsonArrayInsert(jCol, NuiRow(jTCol));

    json jDCol = JsonArrayInsert(JsonArray(), jBtnD);
    jCol = JsonArrayInsert(jCol, NuiRow(jDCol));

    jCol = JsonArrayInsert(jCol, CreateEmptyRow(oPC, 4.0));

    json jMoralCol = JsonArrayInsert(JsonArray(), jMoralLbl);
    jCol = JsonArrayInsert(jCol, NuiRow(jMoralCol));

    jCol = JsonArrayInsert(jCol, jLogGrp);

    return NuiCol(jCol);
}

void IntrOpenWindow(object oPC, object oPrisoner)
{
    if(!GetLocalInt(oPrisoner, "INTR_IS_PRISONER"))
    {
        SendMessageToPC(oPC,
            "[Przesluchanie] Ta istota nie jest wieziem. "
            "Ustaw INTR_IS_PRISONER = 1 na stworzeniu.");
        return;
    }

    if(!GetIsObjectValid(oPrisoner) || GetIsDead(oPrisoner))
    {
        SendMessageToPC(oPC, "[Przesluchanie] Wiezien nie zyje lub jest poza zasiegiem.");
        return;
    }

    int nExisting = NuiFindWindow(oPC, INTR_WINDOW);
    if(nExisting != 0)
        NuiDestroy(oPC, nExisting);

    string sUUID = GetObjectUUID(oPrisoner);
    SetLocalString(oPC, INTR_LVAR_PRISONER_UUID, sUUID);

    // Initialise resistance once per unique prisoner
    if(IntrGetResistance(oPC, sUUID) == 0
       && !GetLocalInt(oPC, INTR_LVAR_THRESHOLD_0 + sUUID))
        IntrSetResistance(oPC, sUUID, IntrCalcStartingResistance(oPrisoner));

    // Centre the window
    float fCX = (IntToFloat(GetPlayerDeviceProperty(oPC, PLAYER_DEVICE_PROPERTY_GUI_WIDTH))
                 - GetNuiScaleDimension(oPC, INTR_W)) / 2.0;
    float fCY = (IntToFloat(GetPlayerDeviceProperty(oPC, PLAYER_DEVICE_PROPERTY_GUI_HEIGHT))
                 - GetNuiScaleDimension(oPC, INTR_H)) / 2.0;
    json jGeom = NuiRect(fCX, fCY,
                         GetNuiScaleDimension(oPC, INTR_W),
                         GetNuiScaleDimension(oPC, INTR_H));

    json jRoot = IntrBuildLayout(oPC, oPrisoner);
    json jWin  = NuiWindow(jRoot,
        JsonBool(FALSE),
        NuiBind(INTR_WIN_GEOM),
        JsonBool(FALSE),
        JsonBool(FALSE),
        JsonBool(FALSE),
        JsonBool(TRUE),
        JsonBool(FALSE));

    int nToken = NuiCreate(oPC, jWin, INTR_WINDOW, INTR_EV_SCRIPT);
    NuiSetBind(oPC, nToken, INTR_WIN_GEOM, jGeom);

    // Static prisoner info
    NuiSetBind(oPC, nToken, INTR_BIND_PRISONER_NAME,
               JsonString(GetName(oPrisoner)));

    string sRaceName = GetStringByStrRef(StringToInt(
        Get2DAString("racialtypes", "Name", GetRacialType(oPrisoner))));
    NuiSetBind(oPC, nToken, INTR_BIND_PRISONER_TYPE, JsonString(sRaceName));

    NuiSetBind(oPC, nToken, INTR_BIND_HD_LABEL,
               JsonString("HD " + IntToString(GetHitDice(oPrisoner))));

    // Intro log line
    string sIntro = "Wiezien siedzi naprzeciw ciebie. W jego oczach widac strach.";
    SetLocalString(oPC, INTR_LVAR_LOG, sIntro);
    NuiSetBind(oPC, nToken, INTR_BIND_LOG, JsonString(sIntro));

    IntrFeedStatus(oPC, nToken);
}
