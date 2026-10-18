#include "lib_astr_def"

// ----------------------------------------------------------------
// NUI — layout helpers
// ----------------------------------------------------------------

json AstrBuildContent(object oPC)
{
    float fBtnH   = GetNuiScaleDimension(oPC, 30.0);
    float fLblH   = GetNuiScaleDimension(oPC, 20.0);
    float fTimerH = GetNuiScaleDimension(oPC, 44.0);
    float fProgH  = GetNuiScaleDimension(oPC, 14.0);
    float fStatH  = GetNuiScaleDimension(oPC, 18.0);

    // Large countdown label
    json jTimer = NuiLabel(NuiBind(ASTR_BIND_TIMER), JsonInt(NUI_HALIGN_CENTER), JsonInt(NUI_VALIGN_MIDDLE));
    jTimer = NuiHeight(jTimer, fTimerH);

    // Time-remaining progress bar (0.0–1.0)
    json jProgress = NuiProgressBar(NuiBind(ASTR_BIND_PROGRESS));
    jProgress = NuiHeight(jProgress, fProgH);

    // Flavor / status label (wraps)
    json jStatus = NuiLabel(NuiBind(ASTR_BIND_STATUS), JsonInt(NUI_HALIGN_CENTER), JsonInt(NUI_VALIGN_MIDDLE));
    jStatus = NuiHeight(jStatus, fLblH * 2.0);

    // Persistent stats from SQL
    json jStats = NuiLabel(NuiBind(ASTR_BIND_STATS), JsonInt(NUI_HALIGN_CENTER), JsonInt(NUI_VALIGN_MIDDLE));
    jStats = NuiHeight(jStats, fStatH);

    // Perceive Hidden button
    json jPerc = NuiButton(NuiBind(ASTR_BIND_PERCEIVE_LBL));
    jPerc = NuiId(jPerc, ASTR_BTN_PERCEIVE);
    jPerc = NuiEnabled(jPerc, NuiBind(ASTR_BIND_PERCEIVE_ENA));
    jPerc = NuiHeight(jPerc, fBtnH);
    jPerc = NuiTooltip(jPerc, JsonString("Przeskanuj otoczenie zmysłami ducha — ujawnia ukryte obiekty i wrogów."));

    // Return to body button
    json jReturn = NuiButton(JsonString("Wróć do ciała"));
    jReturn = NuiId(jReturn, ASTR_BTN_RETURN);
    jReturn = NuiHeight(jReturn, fBtnH);
    jReturn = NuiTooltip(jReturn, JsonString("Przywoła ducha z powrotem. Wyczerpanie rośnie im dłużej przebywasz poza ciałem."));

    json jCol = JsonArray();
    jCol = JsonArrayInsert(jCol, jTimer);
    jCol = JsonArrayInsert(jCol, jProgress);
    jCol = JsonArrayInsert(jCol, CreateEmptyRow(oPC, 4.0));
    jCol = JsonArrayInsert(jCol, jStatus);
    jCol = JsonArrayInsert(jCol, jStats);
    jCol = JsonArrayInsert(jCol, CreateEmptyRow(oPC, 6.0));
    jCol = JsonArrayInsert(jCol, jPerc);
    jCol = JsonArrayInsert(jCol, CreateEmptyRow(oPC, 4.0));
    jCol = JsonArrayInsert(jCol, jReturn);

    return NuiCol(jCol);
}

void AstrOpenWindow(object oPC)
{
    if(NuiFindWindow(oPC, ASTR_WINDOW) != 0) return;

    float fW = GetNuiScaleDimension(oPC, ASTR_W);
    float fH = GetNuiScaleDimension(oPC, ASTR_H);
    // Anchor top-right, small margin
    float fX = IntToFloat(GetPlayerDeviceProperty(oPC, PLAYER_DEVICE_PROPERTY_GUI_WIDTH)) - fW - 14.0;
    float fY = 34.0;
    json  jGeom = NuiRect(fX, fY, fW, fH);

    // Closable = TRUE: closing via X also triggers voluntary return via event handler
    json jWin = NuiWindow(
        AstrBuildContent(oPC),
        JsonString("Projekcja Astralna"),
        NuiBind(ASTR_WIN_GEOM),
        JsonBool(FALSE),  // resizable
        JsonBool(FALSE),  // collapsed
        JsonBool(TRUE),   // closable (X = voluntary return)
        JsonBool(FALSE),  // transparent
        JsonBool(TRUE));  // border

    int nToken = NuiCreate(oPC, jWin, ASTR_WINDOW, ASTR_EV_SCRIPT);
    NuiSetBind(oPC, nToken, ASTR_WIN_GEOM, jGeom);
}

// ----------------------------------------------------------------
// NUI — bind updates
// ----------------------------------------------------------------

string AstrGetStatusFlavor(int nSecsLeft)
{
    float fRatio = IntToFloat(nSecsLeft) / IntToFloat(ASTR_MAX_DURATION);
    if(fRatio > 0.66f) return "Duch dryfuje swobodnie przez astralne prądy...";
    if(fRatio > 0.33f) return "Więź z ciałem słabnie, pociągając ku powrotowi...";
    return "Pieczęć krwi pulsuje słabo — czas ucieka!";
}

void AstrUpdateNui(object oPC, int nToken)
{
    int    nSecsLeft = GetLocalInt(oPC, ASTR_LVAR_TIMER_SECS);
    int    nMins     = nSecsLeft / 60;
    int    nSecs     = nSecsLeft % 60;
    string sTimer    = IntToString(nMins) + ":" + (nSecs < 10 ? "0" : "") + IntToString(nSecs);
    float  fProgress = IntToFloat(nSecsLeft) / IntToFloat(ASTR_MAX_DURATION);

    NuiSetBind(oPC, nToken, ASTR_BIND_TIMER,    JsonString(sTimer));
    NuiSetBind(oPC, nToken, ASTR_BIND_PROGRESS, JsonFloat(fProgress));
    NuiSetBind(oPC, nToken, ASTR_BIND_STATUS,   JsonString(AstrGetStatusFlavor(nSecsLeft)));
}

void AstrUpdateStats(object oPC, int nToken)
{
    json jStats    = AstrGetStats(oPC);
    int  nSessions = JsonGetInt(JsonObjectGet(jStats, "total_sessions"));
    int  nMaxSecs  = JsonGetInt(JsonObjectGet(jStats, "max_secs"));
    int  nMaxMins  = nMaxSecs / 60;
    int  nMaxS     = nMaxSecs % 60;
    string sStats  = "Sesje: " + IntToString(nSessions)
        + "  |  Rekord: " + IntToString(nMaxMins) + ":"
        + (nMaxS < 10 ? "0" : "") + IntToString(nMaxS);
    NuiSetBind(oPC, nToken, ASTR_BIND_STATS, JsonString(sStats));
}

// ----------------------------------------------------------------
// Effects
// ----------------------------------------------------------------

void AstrApplyGhostEffects(object oPC)
{
    // VFX_DUR_BLUR (105) gives the translucent ghostly shimmer
    effect eVfx   = EffectVisualEffect(VFX_DUR_BLUR);
    effect eConc  = EffectConcealment(75, MISS_CHANCE_TYPE_NORMAL);
    effect eSpeed = EffectMovementSpeedIncrease(50);
    effect eImmB  = EffectDamageImmunityIncrease(DAMAGE_TYPE_BLUDGEONING, 100);
    effect eImmP  = EffectDamageImmunityIncrease(DAMAGE_TYPE_PIERCING,    100);
    effect eImmS  = EffectDamageImmunityIncrease(DAMAGE_TYPE_SLASHING,    100);
    effect eImmN  = EffectImmunity(IMMUNITY_TYPE_MIND_SPELLS);

    eVfx   = TagEffect(eVfx,   ASTR_EFFECT_TAG);
    eConc  = TagEffect(eConc,  ASTR_EFFECT_TAG);
    eSpeed = TagEffect(eSpeed, ASTR_EFFECT_TAG);
    eImmB  = TagEffect(eImmB,  ASTR_EFFECT_TAG);
    eImmP  = TagEffect(eImmP,  ASTR_EFFECT_TAG);
    eImmS  = TagEffect(eImmS,  ASTR_EFFECT_TAG);
    eImmN  = TagEffect(eImmN,  ASTR_EFFECT_TAG);

    ApplyEffectToObject(DURATION_TYPE_PERMANENT, eVfx,   oPC);
    ApplyEffectToObject(DURATION_TYPE_PERMANENT, eConc,  oPC);
    ApplyEffectToObject(DURATION_TYPE_PERMANENT, eSpeed, oPC);
    ApplyEffectToObject(DURATION_TYPE_PERMANENT, eImmB,  oPC);
    ApplyEffectToObject(DURATION_TYPE_PERMANENT, eImmP,  oPC);
    ApplyEffectToObject(DURATION_TYPE_PERMANENT, eImmS,  oPC);
    ApplyEffectToObject(DURATION_TYPE_PERMANENT, eImmN,  oPC);
}

void AstrRemoveGhostEffects(object oPC)
{
    effect eEff = GetFirstEffect(oPC);
    while(GetIsEffectValid(eEff))
    {
        if(GetEffectTag(eEff) == ASTR_EFFECT_TAG)
            RemoveEffect(oPC, eEff);
        eEff = GetNextEffect(oPC);
    }
}

void AstrApplyExhaustion(object oPC, int nSecsSpent)
{
    int nTier = nSecsSpent / ASTR_EXHAUSTION_DIV;
    if(nTier < 1) nTier = 1;
    if(nTier > 5) nTier = 5;

    float fDur  = IntToFloat(nTier * 60);
    effect eStr = EffectAbilityDecrease(ABILITY_STRENGTH,     nTier);
    effect eDex = EffectAbilityDecrease(ABILITY_DEXTERITY,    nTier);
    effect eCon = EffectAbilityDecrease(ABILITY_CONSTITUTION, nTier);
    eStr = TagEffect(eStr, ASTR_EXHAUSTION_TAG);
    eDex = TagEffect(eDex, ASTR_EXHAUSTION_TAG);
    eCon = TagEffect(eCon, ASTR_EXHAUSTION_TAG);
    ApplyEffectToObject(DURATION_TYPE_TEMPORARY, eStr, oPC, fDur);
    ApplyEffectToObject(DURATION_TYPE_TEMPORARY, eDex, oPC, fDur);
    ApplyEffectToObject(DURATION_TYPE_TEMPORARY, eCon, oPC, fDur);

    SendMessageToPC(oPC, "[Projekcja] Wyczerpanie astralne — poziom " + IntToString(nTier)
        + " (STR/DEX/CON -" + IntToString(nTier) + " przez " + IntToString(nTier) + " min.).");
}

// ----------------------------------------------------------------
// Entry
// ----------------------------------------------------------------

void AstrEnterProjection(object oPC)
{
    if(!GetIsObjectValid(oPC) || !GetIsPC(oPC)) return;
    if(GetLocalInt(oPC, ASTR_LVAR_ACTIVE))
    {
        SendMessageToPC(oPC, "[Projekcja] Twój duch jest już poza ciałem!");
        return;
    }

    SetLocalInt(oPC, ASTR_LVAR_ACTIVE,     TRUE);
    SetLocalInt(oPC, ASTR_LVAR_TIMER_SECS, ASTR_MAX_DURATION);

    AstrApplyGhostEffects(oPC);
    AstrOpenWindow(oPC);

    int nToken = NuiFindWindow(oPC, ASTR_WINDOW);
    if(nToken)
    {
        AstrUpdateNui(oPC, nToken);
        AstrUpdateStats(oPC, nToken);
        NuiSetBind(oPC, nToken, ASTR_BIND_PERCEIVE_ENA, JsonBool(TRUE));
        NuiSetBind(oPC, nToken, ASTR_BIND_PERCEIVE_LBL, JsonString("Postrzeż ukryte"));
    }

    FloatingTextStringOnCreature("Duch opuszcza ciało...", oPC, FALSE);
    SendMessageToPC(oPC, "[Projekcja] Twoja dusza odrywa się od ciała."
        + " Wróć dobrowolnie lub zaczekaj — im dłużej zwlekasz, tym większe wyczerpanie.");
    ApplyEffectAtLocation(DURATION_TYPE_INSTANT,
        EffectVisualEffect(VFX_FNF_DISPEL_GREATER), GetLocation(oPC));

    // Countdown runs on module so it persists regardless of which script called us
    AssignCommand(GetModule(), DelayCommand(1.0f, AstrTickDown(oPC)));
}

// ----------------------------------------------------------------
// Exit
// ----------------------------------------------------------------

void AstrExitProjection(object oPC, int bTimeout)
{
    if(!GetIsObjectValid(oPC)) return;
    if(!GetLocalInt(oPC, ASTR_LVAR_ACTIVE)) return;

    int nSecsSpent = ASTR_MAX_DURATION - GetLocalInt(oPC, ASTR_LVAR_TIMER_SECS);
    if(nSecsSpent < 1) nSecsSpent = 1;

    DeleteLocalInt(oPC, ASTR_LVAR_ACTIVE);
    DeleteLocalInt(oPC, ASTR_LVAR_TIMER_SECS);
    DeleteLocalInt(oPC, ASTR_LVAR_PERCEIVE_CD);

    AstrRemoveGhostEffects(oPC);

    int nToken = NuiFindWindow(oPC, ASTR_WINDOW);
    if(nToken) NuiDestroy(oPC, nToken);

    AstrApplyExhaustion(oPC, nSecsSpent);

    if(bTimeout)
    {
        FloatingTextStringOnCreature("Więź zerwana! Duch wraca gwałtownie.", oPC, FALSE);
        SendMessageToPC(oPC, "[Projekcja] Czas minął — duch powrócił gwałtownie. Szok astralny zadaje obrażenia!");
        // Spiritual shock: 2d6 negative energy
        ApplyEffectToObject(DURATION_TYPE_INSTANT,
            EffectDamage(d6(2), DAMAGE_TYPE_NEGATIVE, DAMAGE_POWER_ENERGY), oPC);
    }
    else
    {
        FloatingTextStringOnCreature("Duch powraca do ciała.", oPC, FALSE);
    }

    ApplyEffectAtLocation(DURATION_TYPE_INSTANT,
        EffectVisualEffect(VFX_FNF_DISPEL_GREATER), GetLocation(oPC));

    AstrRecordSession(oPC, nSecsSpent);
}

// ----------------------------------------------------------------
// Countdown tick — always dispatched on module to stay alive
// ----------------------------------------------------------------

void AstrTickDown(object oPC)
{
    if(!GetIsObjectValid(oPC)) return;
    if(!GetLocalInt(oPC, ASTR_LVAR_ACTIVE)) return;

    int nSecsLeft = GetLocalInt(oPC, ASTR_LVAR_TIMER_SECS) - 1;
    if(nSecsLeft < 0) nSecsLeft = 0;
    SetLocalInt(oPC, ASTR_LVAR_TIMER_SECS, nSecsLeft);

    int nToken = NuiFindWindow(oPC, ASTR_WINDOW);
    if(nToken) AstrUpdateNui(oPC, nToken);

    if(nSecsLeft <= 0)
    {
        AstrExitProjection(oPC, TRUE);
        return;
    }

    if(nSecsLeft == 30)
        SendMessageToPC(oPC, "[Projekcja] Uwaga! Pozostało 30 sekund!");

    if(nSecsLeft == 10)
    {
        SendMessageToPC(oPC, "[Projekcja] Ostatnie chwile — duch słabnie!");
        ApplyEffectAtLocation(DURATION_TYPE_INSTANT,
            EffectVisualEffect(VFX_FNF_DISPEL_GREATER), GetLocation(oPC));
    }

    AssignCommand(GetModule(), DelayCommand(1.0f, AstrTickDown(oPC)));
}

// ----------------------------------------------------------------
// Perceive Hidden ability
// ----------------------------------------------------------------

void AstrClearPerceiveCD(object oPC)
{
    DeleteLocalInt(oPC, ASTR_LVAR_PERCEIVE_CD);
    int nToken = NuiFindWindow(oPC, ASTR_WINDOW);
    if(!nToken) return;
    NuiSetBind(oPC, nToken, ASTR_BIND_PERCEIVE_ENA, JsonBool(TRUE));
    NuiSetBind(oPC, nToken, ASTR_BIND_PERCEIVE_LBL, JsonString("Postrzeż ukryte"));
}

void AstrPerceiveHidden(object oPC)
{
    if(!GetLocalInt(oPC, ASTR_LVAR_ACTIVE)) return;
    if(GetLocalInt(oPC, ASTR_LVAR_PERCEIVE_CD))
    {
        SendMessageToPC(oPC, "[Projekcja] Zmysły ducha potrzebują chwili odpoczynku.");
        return;
    }

    SetLocalInt(oPC, ASTR_LVAR_PERCEIVE_CD, TRUE);
    int nToken = NuiFindWindow(oPC, ASTR_WINDOW);
    if(nToken)
    {
        NuiSetBind(oPC, nToken, ASTR_BIND_PERCEIVE_ENA, JsonBool(FALSE));
        NuiSetBind(oPC, nToken, ASTR_BIND_PERCEIVE_LBL,
            JsonString("Postrzeż ukryte (" + IntToString(ASTR_PERCEIVE_CD_SECS) + "s)"));
    }

    location lPC   = GetLocation(oPC);
    int      nFound = 0;

    // Scan placeables: traps and containers
    object oPlc = GetFirstObjectInShape(SHAPE_SPHERE, ASTR_PERCEIVE_RADIUS, lPC, FALSE, OBJECT_TYPE_PLACEABLE);
    while(GetIsObjectValid(oPlc))
    {
        if(GetIsTrapped(oPlc))
        {
            SendMessageToPC(oPC, "[Projekcja] Pułapka: " + GetName(oPlc));
            nFound++;
        }
        else if(GetHasInventory(oPlc) && !GetIsOpen(oPlc))
        {
            SendMessageToPC(oPC, "[Projekcja] Schowek: " + GetName(oPlc));
            nFound++;
        }
        oPlc = GetNextObjectInShape(SHAPE_SPHERE, ASTR_PERCEIVE_RADIUS, lPC, FALSE, OBJECT_TYPE_PLACEABLE);
    }

    // Sense hostile and undead creatures
    object oCre = GetFirstObjectInShape(SHAPE_SPHERE, ASTR_SENSE_RADIUS, lPC, FALSE, OBJECT_TYPE_CREATURE);
    while(GetIsObjectValid(oCre))
    {
        if(oCre != oPC)
        {
            string sTag = "";
            if(GetRacialType(oCre) == RACIAL_TYPE_UNDEAD)
                sTag = "[Nieumarły]";
            else if(GetIsEnemy(oCre, oPC))
                sTag = "[Wróg]";

            if(sTag != "")
            {
                int nDist = FloatToInt(GetDistanceBetween(oPC, oCre));
                SendMessageToPC(oPC, "[Projekcja] " + sTag + " " + GetName(oCre)
                    + " — " + IntToString(nDist) + "m");
                nFound++;
            }
        }
        oCre = GetNextObjectInShape(SHAPE_SPHERE, ASTR_SENSE_RADIUS, lPC, FALSE, OBJECT_TYPE_CREATURE);
    }

    if(nFound == 0)
        SendMessageToPC(oPC, "[Projekcja] Okolica jest spokojna... lub doskonale ukryta.");
    else
        SendMessageToPC(oPC, "[Projekcja] Wykryto " + IntToString(nFound) + " punkt(ów) zainteresowania.");

    ApplyEffectToObject(DURATION_TYPE_INSTANT,
        EffectVisualEffect(VFX_FNF_DISPEL_DISJUNCTION), oPC);

    AssignCommand(GetModule(), DelayCommand(IntToFloat(ASTR_PERCEIVE_CD_SECS), AstrClearPerceiveCD(oPC)));
}
