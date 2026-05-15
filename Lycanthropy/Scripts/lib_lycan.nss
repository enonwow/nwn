#include "lib_lycan_def"

// Forward declarations
void LycanOpenWindow(object oPC);
void LycanFeedWindow(object oPC, int nToken);
void LycanTransform(object oPC);
void LycanRevert(object oPC);
void LycanApplyStageEffects(object oPC, int nStage);
void LycanRemoveEffects(object oPC);
void LycanCure(object oPC);
void LycanCheckAdvanceStage(object oPC);
void LycanHeartbeat(object oPC);

// -----------------------------------------------------------------------
// Effect helpers
// -----------------------------------------------------------------------

void LycanRemoveTaggedEffects(object oTarget, string sTag)
{
    effect e = GetFirstEffect(oTarget);
    while(GetIsEffectValid(e))
    {
        if(GetEffectTag(e) == sTag)
            RemoveEffect(oTarget, e);
        e = GetNextEffect(oTarget);
    }
}

void LycanRemoveEffects(object oPC)
{
    LycanRemoveTaggedEffects(oPC, LYCAN_EFF_ACTIVE);
    LycanRemoveTaggedEffects(oPC, LYCAN_EFF_FULL);
}

// Applies persistent stat effects appropriate for nStage.
void LycanApplyStageEffects(object oPC, int nStage)
{
    LycanRemoveEffects(oPC);
    if(nStage == LYCAN_STAGE_NONE) return;

    if(nStage == LYCAN_STAGE_ACTIVE)
    {
        // Minor bestial surge: +2 STR, -1 WIS
        effect eStr = TagEffect(EffectAbilityIncrease(ABILITY_STRENGTH, 2),    LYCAN_EFF_ACTIVE);
        effect eWis = TagEffect(EffectAbilityDecrease(ABILITY_WISDOM,   1),    LYCAN_EFF_ACTIVE);
        ApplyEffectToObject(DURATION_TYPE_PERMANENT, EffectLinkEffects(eStr, eWis), oPC);
    }
    else if(nStage == LYCAN_STAGE_FULL)
    {
        // Full curse: +4 STR, +2 CON, -3 WIS, -2 CHA
        effect eStr = TagEffect(EffectAbilityIncrease(ABILITY_STRENGTH,     4), LYCAN_EFF_FULL);
        effect eCon = TagEffect(EffectAbilityIncrease(ABILITY_CONSTITUTION, 2), LYCAN_EFF_FULL);
        effect eWis = TagEffect(EffectAbilityDecrease(ABILITY_WISDOM,       3), LYCAN_EFF_FULL);
        effect eCha = TagEffect(EffectAbilityDecrease(ABILITY_CHARISMA,     2), LYCAN_EFF_FULL);
        effect eAll = EffectLinkEffects(eStr,
                        EffectLinkEffects(eCon,
                          EffectLinkEffects(eWis, eCha)));
        ApplyEffectToObject(DURATION_TYPE_PERMANENT, eAll, oPC);
    }
}

// -----------------------------------------------------------------------
// Stage advancement
// -----------------------------------------------------------------------

void LycanCheckAdvanceStage(object oPC)
{
    int nStage = LycanGetInfectionStage(oPC);
    if(nStage == LYCAN_STAGE_NONE) return;

    int nDays     = LycanGetDaysSinceInfection(oPC);
    int nNewStage = nStage;

    if(nDays >= 7 && nStage < LYCAN_STAGE_FULL)
        nNewStage = LYCAN_STAGE_FULL;
    else if(nDays >= 3 && nStage < LYCAN_STAGE_ACTIVE)
        nNewStage = LYCAN_STAGE_ACTIVE;

    if(nNewStage == nStage) return;

    LycanSetInfection(oPC, nNewStage);
    LycanApplyStageEffects(oPC, nNewStage);

    if(nNewStage == LYCAN_STAGE_ACTIVE)
    {
        string sMsg = "[Wilkołactwo] Gorączka narasta. Zęby bolą, a oczy błyszczą w ciemności...";
        SendMessageToPC(oPC, sMsg);
        FloatingTextStringOnCreature("Klątwa bestii się przebudza!", oPC, FALSE);
    }
    else if(nNewStage == LYCAN_STAGE_FULL)
    {
        string sMsg = "[Wilkołactwo] Klątwa wypełniona. Pełnia księżyca cię przemieni.";
        SendMessageToPC(oPC, sMsg);
        FloatingTextStringOnCreature("Piętno wilka — pełne!", oPC, FALSE);
    }
}

// -----------------------------------------------------------------------
// Transformation
// -----------------------------------------------------------------------

// Store original appearance so we can restore it on revert.
void LycanTransform(object oPC)
{
    if(GetLocalInt(oPC, LYCAN_LVAR_TRANSFORMED)) return;

    // Save human appearance type for restoration
    SetLocalInt(oPC, "LYCAN_ORIG_APPEARANCE", GetAppearanceType(oPC));
    SetCreatureAppearanceType(oPC, LYCAN_WOLF_APPEARANCE);
    SetLocalInt(oPC, LYCAN_LVAR_TRANSFORMED, TRUE);
    LycanRecordTransform(oPC);

    // Brief visual burst
    ApplyEffectToObject(DURATION_TYPE_INSTANT,
        EffectVisualEffect(VFX_FNF_HOWL_WAR_CRY), oPC);

    SendMessageToPC(oPC, "[Wilkołactwo] Ciało pęka i zmienia się. Bestia pochłania człowieka.");
    FloatingTextStringOnCreature("*Przemiana w wilkołaka!*", oPC, FALSE);

    object oOther = GetFirstPC();
    while(GetIsObjectValid(oOther))
    {
        if(oOther != oPC && GetDistanceBetween(oPC, oOther) <= 30.0f)
            SendMessageToPC(oOther,
                "[Wilkołactwo] " + GetName(oPC) + " przemienia się w wilkołaka!");
        oOther = GetNextPC();
    }
}

void LycanRevert(object oPC)
{
    if(!GetLocalInt(oPC, LYCAN_LVAR_TRANSFORMED)) return;

    int nOrig = GetLocalInt(oPC, "LYCAN_ORIG_APPEARANCE");
    if(nOrig > 0) SetCreatureAppearanceType(oPC, nOrig);

    DeleteLocalInt(oPC, LYCAN_LVAR_TRANSFORMED);
    DeleteLocalInt(oPC, "LYCAN_ORIG_APPEARANCE");

    SendMessageToPC(oPC, "[Wilkołactwo] Bestia cofa się. Człowiek wraca — lecz pamięta...");
}

// -----------------------------------------------------------------------
// Silver weakness
// -----------------------------------------------------------------------

// Call from the target's OnPhysicalAttacked (see INTEGRATION.md).
void LycanCheckSilverDamage(object oTarget, object oAttacker)
{
    if(!GetLocalInt(oTarget, LYCAN_LVAR_TRANSFORMED)) return;

    object oWeapon = GetLastWeaponUsed(oAttacker);
    if(!GetIsObjectValid(oWeapon)) return;

    string sTag  = GetStringLowerCase(GetTag(oWeapon));
    string sName = GetStringLowerCase(GetName(oWeapon));

    if(FindSubString(sTag,  LYCAN_SILVER_SUBSTR) == -1 &&
       FindSubString(sName, LYCAN_SILVER_SUBSTR) == -1)
        return;

    // Silver hits the wolf for 2d6 extra magical damage.
    effect eDmg = EffectDamage(d6(2), DAMAGE_TYPE_MAGICAL);
    ApplyEffectToObject(DURATION_TYPE_INSTANT, eDmg, oTarget);
    SendMessageToPC(oTarget, "[Wilkołactwo] Srebro pali ciało wilka jak żar!");
}

// -----------------------------------------------------------------------
// Infection spread
// -----------------------------------------------------------------------

// Called each heartbeat for each transformed PC.
// Any non-infected PC within 2 m has a 5 % chance of being bitten.
void LycanCheckSpread(object oWolf)
{
    if(!GetLocalInt(oWolf, LYCAN_LVAR_TRANSFORMED)) return;

    object oTarget = GetFirstPC();
    while(GetIsObjectValid(oTarget))
    {
        if(oTarget != oWolf && GetDistanceBetween(oWolf, oTarget) <= 2.0f)
        {
            if(LycanGetInfectionStage(oTarget) == LYCAN_STAGE_NONE && d100() <= 5)
            {
                LycanSetInfection(oTarget, LYCAN_STAGE_LATENT);
                SendMessageToPC(oTarget,
                    "[Wilkołactwo] Czujesz pieczenie — wilk cię dosięgnął. "
                    + "Coś złego kiełkuje w krwi...");
                SendMessageToPC(oWolf,
                    "[Wilkołactwo] Bestia dosięgnęła pobliskiej duszy.");
            }
        }
        oTarget = GetNextPC();
    }
}

// -----------------------------------------------------------------------
// Cure
// -----------------------------------------------------------------------

void LycanCure(object oPC)
{
    LycanSetInfection(oPC, LYCAN_STAGE_NONE);
    LycanRemoveEffects(oPC);
    LycanRevert(oPC);

    ApplyEffectToObject(DURATION_TYPE_INSTANT,
        EffectVisualEffect(VFX_FNF_DISPEL_DISJUNCTION), oPC);

    SendMessageToPC(oPC, "[Wilkołactwo] Klątwa bestii odpędzona. Jesteś wolny.");
    FloatingTextStringOnCreature("*Klątwa wilkołaka złamana!*", oPC, FALSE);
}

// Attempts to cure; consumes lycan_cure_kit if found.
// Returns TRUE on success.
int LycanTryCure(object oPC)
{
    if(GetLocalInt(oPC, LYCAN_LVAR_TRANSFORMED))
    {
        SendMessageToPC(oPC,
            "[Wilkołactwo] Nie możesz wykonać rytuału oczyszczenia w formie bestii. "
            + "Poczekaj do świtu.");
        return FALSE;
    }

    object oKit = GetItemPossessedBy(oPC, LYCAN_CURE_KIT_TAG);
    if(!GetIsObjectValid(oKit))
    {
        SendMessageToPC(oPC,
            "[Wilkołactwo] Potrzebujesz Zestawu Odpędnika Wilkołaka. "
            + "Poszukaj go u kapłana lub alchemika.");
        return FALSE;
    }

    DestroyObject(oKit);
    LycanCure(oPC);
    return TRUE;
}

// -----------------------------------------------------------------------
// Per-PC heartbeat (self-perpetuating, started in sys_on_enter.nss)
// -----------------------------------------------------------------------

void LycanHeartbeat(object oPC)
{
    if(!GetIsObjectValid(oPC) || !GetIsPC(oPC)) return;

    int nStage = LycanGetInfectionStage(oPC);
    if(nStage > 0)
    {
        LycanCheckAdvanceStage(oPC);
        // Re-read: stage may have advanced above.
        nStage = LycanGetInfectionStage(oPC);

        int bFull  = LycanIsFullMoon();
        int bTrans = GetLocalInt(oPC, LYCAN_LVAR_TRANSFORMED);

        // Auto-transform at full moon for stage-3 PCs.
        if(bFull && nStage == LYCAN_STAGE_FULL && !bTrans)
            LycanTransform(oPC);

        // Revert when full moon ends.
        if(!bFull && bTrans && nStage == LYCAN_STAGE_FULL)
            LycanRevert(oPC);

        // Spread infection to nearby PCs.
        if(bTrans)
            LycanCheckSpread(oPC);
    }

    // Refresh open window each tick so moon bar stays live.
    int nToken = NuiFindWindow(oPC, LYCAN_WIN_STATUS);
    if(nToken != 0)
        LycanFeedWindow(oPC, nToken);

    DelayCommand(6.0f, LycanHeartbeat(oPC));
}

// -----------------------------------------------------------------------
// NUI — window construction
// -----------------------------------------------------------------------

json BuildLycanWindow(object oPC)
{
    float fBtnH   = GetNuiScaleDimension(oPC, 30.0f);
    float fLblH   = GetNuiScaleDimension(oPC, 22.0f);
    float fDescH  = GetNuiScaleDimension(oPC, 100.0f);
    float fBtnW1  = GetNuiScaleDimension(oPC, 190.0f);
    float fBtnW2  = GetNuiScaleDimension(oPC, 150.0f);
    float fBtnW3  = GetNuiScaleDimension(oPC, 80.0f);

    // -- Moon section --
    json jMoonLabelLbl = NuiLabel(JsonString("Faza Księżyca:"),
        JsonInt(NUI_HALIGN_LEFT), JsonInt(NUI_VALIGN_MIDDLE));
    jMoonLabelLbl = NuiHeight(jMoonLabelLbl, fLblH);

    json jMoonName = NuiLabel(NuiBind(LYCAN_BIND_MOON_LABEL),
        JsonInt(NUI_HALIGN_LEFT), JsonInt(NUI_VALIGN_MIDDLE));
    jMoonName = NuiHeight(jMoonName, fLblH);
    jMoonName = NuiStyleForegroundColor(jMoonName, NuiColor(220, 210, 255));

    json jMoonBarLbl = NuiLabel(NuiBind(LYCAN_BIND_MOON_BAR),
        JsonInt(NUI_HALIGN_LEFT), JsonInt(NUI_VALIGN_MIDDLE));
    jMoonBarLbl = NuiHeight(jMoonBarLbl, fLblH);
    jMoonBarLbl = NuiStyleForegroundColor(jMoonBarLbl, NuiColor(180, 180, 200));

    // -- Infection section --
    json jInfHeaderLbl = NuiLabel(JsonString("Stan Klątwy:"),
        JsonInt(NUI_HALIGN_LEFT), JsonInt(NUI_VALIGN_MIDDLE));
    jInfHeaderLbl = NuiHeight(jInfHeaderLbl, fLblH);

    json jStageLbl = NuiLabel(NuiBind(LYCAN_BIND_STAGE_LBL),
        JsonInt(NUI_HALIGN_LEFT), JsonInt(NUI_VALIGN_MIDDLE));
    jStageLbl = NuiHeight(jStageLbl, fLblH);
    jStageLbl = NuiStyleForegroundColor(jStageLbl, NuiBind(LYCAN_BIND_STAGE_COLOR));

    json jDaysLbl = NuiLabel(NuiBind(LYCAN_BIND_DAYS_LBL),
        JsonInt(NUI_HALIGN_LEFT), JsonInt(NUI_VALIGN_MIDDLE));
    jDaysLbl = NuiHeight(jDaysLbl, fLblH);

    json jFormLbl = NuiLabel(NuiBind(LYCAN_BIND_FORM_LBL),
        JsonInt(NUI_HALIGN_LEFT), JsonInt(NUI_VALIGN_MIDDLE));
    jFormLbl = NuiHeight(jFormLbl, fLblH);
    jFormLbl = NuiStyleForegroundColor(jFormLbl, NuiBind(LYCAN_BIND_FORM_COLOR));

    // -- Description text --
    json jDescTxt = NuiGroup(
        NuiText(NuiBind(LYCAN_BIND_DESC_TXT), FALSE),
        TRUE, NUI_SCROLLBARS_NONE);
    jDescTxt = NuiHeight(jDescTxt, fDescH);

    // -- Buttons --
    json jCureBtn = NuiButton(NuiBind(LYCAN_BIND_CURE_LBL));
    jCureBtn = NuiId(jCureBtn, LYCAN_BTN_CURE);
    jCureBtn = NuiEnabled(jCureBtn, NuiBind(LYCAN_BIND_CURE_ENA));
    jCureBtn = NuiWidth(jCureBtn, fBtnW1);
    jCureBtn = NuiHeight(jCureBtn, fBtnH);

    json jXformBtn = NuiButton(NuiBind(LYCAN_BIND_XFORM_LBL));
    jXformBtn = NuiId(jXformBtn, LYCAN_BTN_TRANSFORM);
    jXformBtn = NuiEnabled(jXformBtn, NuiBind(LYCAN_BIND_XFORM_ENA));
    jXformBtn = NuiWidth(jXformBtn, fBtnW2);
    jXformBtn = NuiHeight(jXformBtn, fBtnH);

    json jCloseBtn = NuiButton(JsonString("Zamknij"));
    jCloseBtn = NuiId(jCloseBtn, LYCAN_BTN_CLOSE);
    jCloseBtn = NuiWidth(jCloseBtn, fBtnW3);
    jCloseBtn = NuiHeight(jCloseBtn, fBtnH);

    json jBtnRow = JsonArray();
    jBtnRow = JsonArrayInsert(jBtnRow, jCureBtn);
    jBtnRow = JsonArrayInsert(jBtnRow, NuiSpacer());
    jBtnRow = JsonArrayInsert(jBtnRow, jXformBtn);
    jBtnRow = JsonArrayInsert(jBtnRow, jCloseBtn);

    // -- Assemble column --
    json jCol = JsonArray();
    jCol = JsonArrayInsert(jCol, jMoonLabelLbl);
    jCol = JsonArrayInsert(jCol, jMoonName);
    jCol = JsonArrayInsert(jCol, jMoonBarLbl);
    jCol = JsonArrayInsert(jCol, CreateEmptyRow(oPC, 6.0f));
    jCol = JsonArrayInsert(jCol, jInfHeaderLbl);
    jCol = JsonArrayInsert(jCol, jStageLbl);
    jCol = JsonArrayInsert(jCol, jDaysLbl);
    jCol = JsonArrayInsert(jCol, jFormLbl);
    jCol = JsonArrayInsert(jCol, CreateEmptyRow(oPC, 6.0f));
    jCol = JsonArrayInsert(jCol, jDescTxt);
    jCol = JsonArrayInsert(jCol, NuiSpacer());
    jCol = JsonArrayInsert(jCol, NuiRow(jBtnRow));

    // Centre-pad with side spacers (same LFG/Mail pattern)
    float fContentW = GetNuiScaleDimension(oPC, LYCAN_WIN_W - 30.0f);
    json jSide = NuiCol(JsonArrayInsert(JsonArray(), NuiSpacer()));
    json jMainRow = JsonArray();
    jMainRow = JsonArrayInsert(jMainRow, jSide);
    jMainRow = JsonArrayInsert(jMainRow, NuiWidth(NuiCol(jCol), fContentW));
    jMainRow = JsonArrayInsert(jMainRow, jSide);

    json jWin = NuiWindow(
        NuiRow(jMainRow),
        JsonString("Klątwa Wilkołaka"),
        NuiBind(LYCAN_BIND_WIN_GEOM),
        JsonBool(FALSE),
        JsonBool(FALSE),
        JsonBool(TRUE),
        JsonBool(TRUE),
        JsonBool(FALSE));

    return jWin;
}

// -----------------------------------------------------------------------
// NUI — feed binds from current game state
// -----------------------------------------------------------------------

void LycanFeedWindow(object oPC, int nToken)
{
    int    nStage  = LycanGetInfectionStage(oPC);
    int    nDays   = LycanGetDaysSinceInfection(oPC);
    int    bTrans  = GetLocalInt(oPC, LYCAN_LVAR_TRANSFORMED);
    int    bFull   = LycanIsFullMoon();
    string sMoon   = LycanGetMoonPhaseName();
    string sBar    = LycanGetMoonBar();

    NuiSetBind(oPC, nToken, LYCAN_BIND_MOON_LABEL, JsonString(sMoon));
    NuiSetBind(oPC, nToken, LYCAN_BIND_MOON_BAR,   JsonString(sBar));

    // Stage colour: none=grey, latent=yellow, active=orange, full=red
    json jStageColor;
    switch(nStage)
    {
        case LYCAN_STAGE_NONE:   jStageColor = NuiColor(160, 160, 160); break;
        case LYCAN_STAGE_LATENT: jStageColor = NuiColor(230, 220,  80); break;
        case LYCAN_STAGE_ACTIVE: jStageColor = NuiColor(230, 130,  30); break;
        default:                 jStageColor = NuiColor(220,  50,  50); break;
    }
    NuiSetBind(oPC, nToken, LYCAN_BIND_STAGE_LBL,   JsonString(LycanGetStageLabel(nStage)));
    NuiSetBind(oPC, nToken, LYCAN_BIND_STAGE_COLOR,  jStageColor);

    string sDays = (nStage > 0)
        ? "Dni od zarażenia: " + IntToString(nDays)
        : "";
    NuiSetBind(oPC, nToken, LYCAN_BIND_DAYS_LBL, JsonString(sDays));

    string sForm = bTrans ? "Forma: Wilk [AKTYWNA]" : "Forma: Człowiek";
    json   jFormColor = bTrans ? NuiColor(220, 50, 50) : NuiColor(200, 200, 200);
    NuiSetBind(oPC, nToken, LYCAN_BIND_FORM_LBL,   JsonString(sForm));
    NuiSetBind(oPC, nToken, LYCAN_BIND_FORM_COLOR,  jFormColor);

    NuiSetBind(oPC, nToken, LYCAN_BIND_DESC_TXT, JsonString(LycanGetStageDesc(nStage)));

    // Cure button: enabled only if infected and not transformed
    int bCanCure = (nStage > 0 && !bTrans);
    NuiSetBind(oPC, nToken, LYCAN_BIND_CURE_ENA, JsonBool(bCanCure));
    NuiSetBind(oPC, nToken, LYCAN_BIND_CURE_LBL,
        JsonString(bCanCure ? "Odpedz Klatwe (kit)" : "Brak Klątwy / Forma Wilka"));

    // Transform button: stage FULL only; label changes based on current state
    int bCanXform = (nStage == LYCAN_STAGE_FULL);
    NuiSetBind(oPC, nToken, LYCAN_BIND_XFORM_ENA, JsonBool(bCanXform));
    NuiSetBind(oPC, nToken, LYCAN_BIND_XFORM_LBL,
        JsonString(bTrans ? "Przywroc Postac Ludzka" : "Wywolaj Przemiane"));
}

// -----------------------------------------------------------------------
// NUI — open / focus window
// -----------------------------------------------------------------------

void LycanOpenWindow(object oPC)
{
    int nToken = NuiFindWindow(oPC, LYCAN_WIN_STATUS);
    if(nToken != 0)
    {
        LycanFeedWindow(oPC, nToken);
        return;
    }

    float fGuiW = IntToFloat(GetPlayerDeviceProperty(oPC, PLAYER_DEVICE_PROPERTY_GUI_WIDTH));
    float fGuiH = IntToFloat(GetPlayerDeviceProperty(oPC, PLAYER_DEVICE_PROPERTY_GUI_HEIGHT));
    float fWinW = GetNuiScaleDimension(oPC, LYCAN_WIN_W);
    float fWinH = GetNuiScaleDimension(oPC, LYCAN_WIN_H);
    json  jGeom = NuiRect((fGuiW - fWinW) / 2.0f, (fGuiH - fWinH) / 2.0f, fWinW, fWinH);

    nToken = NuiCreate(oPC, BuildLycanWindow(oPC), LYCAN_WIN_STATUS, LYCAN_EV_SCRIPT);
    NuiSetBind(oPC, nToken, LYCAN_BIND_WIN_GEOM, jGeom);
    LycanFeedWindow(oPC, nToken);
}
