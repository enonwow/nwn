#include "lib_vamp_def"

// ================================================================
// Tier helpers
// ================================================================

// Returns 0 (worst) to 5 (best).
int VampGetTier(int nBlood)
{
    if(nBlood <= 0)                    return 0;
    if(nBlood < VAMP_TIER_STARVING)    return 1; // frenzy
    if(nBlood < VAMP_TIER_NEUTRAL)     return 2; // starving
    if(nBlood < VAMP_TIER_FED)         return 3; // hungry / neutral
    if(nBlood < VAMP_TIER_SATED)       return 4; // fed
    return 5;                                     // sated
}

string VampTierLabel(int nTier)
{
    switch(nTier)
    {
        case 0: return "Konanie z Głodu";
        case 1: return "Szał Krwi";
        case 2: return "Wygłodzenie";
        case 3: return "Głód";
        case 4: return "Zaspokojenie";
        case 5: return "Sytość";
    }
    return "";
}

json VampTierColor(int nTier)
{
    switch(nTier)
    {
        case 0: return NuiColor( 80,   0,   0);
        case 1: return NuiColor(220,  30,  30);
        case 2: return NuiColor(200,  80,   0);
        case 3: return NuiColor(180, 140,   0);
        case 4: return NuiColor(130, 200,  70);
        case 5: return NuiColor(180, 255, 130);
    }
    return NuiColor(255, 255, 255);
}

string VampTierEffectsLabel(int nTier)
{
    switch(nTier)
    {
        case 0: return "OBЕЗДВИЖONY  •  ciężkie kary do cech";
        case 1: return "-3 SIŁ / ZRE / KON  •  Powolność -50%";
        case 2: return "-1 SIŁ / ZRE / KON";
        case 3: return "Brak modyfikatorów";
        case 4: return "+1 SIŁ / ZRE  •  Regeneracja 1 HP/s";
        case 5: return "+2 SIŁ / ZRE  •  Regeneracja 2 HP/s";
    }
    return "";
}

// ================================================================
// Effect management
// ================================================================

void VampRemoveEffects(object oPC)
{
    effect e = GetFirstEffect(oPC);
    while(GetIsEffectValid(e))
    {
        string sTag = GetEffectTag(e);
        if(sTag == VAMP_TAG_BUFF || sTag == VAMP_TAG_DEBUFF || sTag == VAMP_TAG_HEAVY)
            RemoveEffect(oPC, e);
        e = GetNextEffect(oPC);
    }
}

void VampApplyEffects(object oPC, int nBlood)
{
    VampRemoveEffects(oPC);
    int nTier = VampGetTier(nBlood);
    SetLocalInt(oPC, VAMP_LVAR_TIER, nTier);

    if(nTier == 0)
    {
        // Incapacitating blood-zero state — severe but not instant death
        effect eStr  = TagEffect(EffectAbilityDecrease(ABILITY_STRENGTH,     6), VAMP_TAG_HEAVY);
        effect eDex  = TagEffect(EffectAbilityDecrease(ABILITY_DEXTERITY,    6), VAMP_TAG_HEAVY);
        effect eCon  = TagEffect(EffectAbilityDecrease(ABILITY_CONSTITUTION, 4), VAMP_TAG_HEAVY);
        effect eSlow = TagEffect(EffectMovementSpeedDecrease(75),                VAMP_TAG_HEAVY);
        effect eLink = EffectLinkEffects(
                           EffectLinkEffects(EffectLinkEffects(eStr, eDex), eCon), eSlow);
        ApplyEffectToObject(DURATION_TYPE_PERMANENT, eLink, oPC);
        ApplyEffectToObject(DURATION_TYPE_INSTANT, EffectVisualEffect(VFX_IMP_HARM), oPC);
        SendMessageToPC(oPC, "[Wampiryzm] Umierasz z pragnienia krwi... Każdy krok to agonia.");
    }
    else if(nTier == 1)
    {
        effect eStr  = TagEffect(EffectAbilityDecrease(ABILITY_STRENGTH,     3), VAMP_TAG_DEBUFF);
        effect eDex  = TagEffect(EffectAbilityDecrease(ABILITY_DEXTERITY,    3), VAMP_TAG_DEBUFF);
        effect eCon  = TagEffect(EffectAbilityDecrease(ABILITY_CONSTITUTION, 3), VAMP_TAG_DEBUFF);
        effect eSlow = TagEffect(EffectMovementSpeedDecrease(50),                VAMP_TAG_DEBUFF);
        effect eLink = EffectLinkEffects(
                           EffectLinkEffects(EffectLinkEffects(eStr, eDex), eCon), eSlow);
        ApplyEffectToObject(DURATION_TYPE_PERMANENT, eLink, oPC);
        ApplyEffectToObject(DURATION_TYPE_INSTANT, EffectVisualEffect(VFX_IMP_HARM), oPC);
    }
    else if(nTier == 2)
    {
        effect eStr = TagEffect(EffectAbilityDecrease(ABILITY_STRENGTH,     1), VAMP_TAG_DEBUFF);
        effect eDex = TagEffect(EffectAbilityDecrease(ABILITY_DEXTERITY,    1), VAMP_TAG_DEBUFF);
        effect eCon = TagEffect(EffectAbilityDecrease(ABILITY_CONSTITUTION, 1), VAMP_TAG_DEBUFF);
        effect eLink= EffectLinkEffects(EffectLinkEffects(eStr, eDex), eCon);
        ApplyEffectToObject(DURATION_TYPE_PERMANENT, eLink, oPC);
    }
    else if(nTier == 3)
    {
        // neutral — no effects applied
    }
    else if(nTier == 4)
    {
        effect eStr  = TagEffect(EffectAbilityIncrease(ABILITY_STRENGTH,  1), VAMP_TAG_BUFF);
        effect eDex  = TagEffect(EffectAbilityIncrease(ABILITY_DEXTERITY, 1), VAMP_TAG_BUFF);
        effect eReg  = TagEffect(EffectRegenerate(1, 6.0),                    VAMP_TAG_BUFF);
        effect eLink = EffectLinkEffects(EffectLinkEffects(eStr, eDex), eReg);
        ApplyEffectToObject(DURATION_TYPE_PERMANENT, eLink, oPC);
    }
    else if(nTier == 5)
    {
        effect eStr  = TagEffect(EffectAbilityIncrease(ABILITY_STRENGTH,  2), VAMP_TAG_BUFF);
        effect eDex  = TagEffect(EffectAbilityIncrease(ABILITY_DEXTERITY, 2), VAMP_TAG_BUFF);
        effect eReg  = TagEffect(EffectRegenerate(2, 6.0),                    VAMP_TAG_BUFF);
        effect eLink = EffectLinkEffects(EffectLinkEffects(eStr, eDex), eReg);
        ApplyEffectToObject(DURATION_TYPE_PERMANENT, eLink, oPC);
        ApplyEffectToObject(DURATION_TYPE_INSTANT, EffectVisualEffect(VFX_IMP_HEALING_M), oPC);
    }
}

// ================================================================
// NUI layout
// ================================================================

json VampBuildLayout(object oPC)
{
    float fBtnH  = GetNuiScaleDimension(oPC, 30.0);
    float fLblH  = GetNuiScaleDimension(oPC, 26.0);
    float fProgH = GetNuiScaleDimension(oPC, 22.0);
    float fCW    = GetNuiScaleDimension(oPC, VAMP_W - 44.0);

    // Title
    json jTitle = NuiLabel(JsonString("— Klątwa Wampira —"),
                           JsonInt(NUI_HALIGN_CENTER), JsonInt(NUI_VALIGN_MIDDLE));
    jTitle = NuiHeight(jTitle, fBtnH);

    // Blood progress bar
    json jProg = NuiProgress(NuiBind(VAMP_BIND_BLOOD_VAL));
    jProg = NuiWidth(jProg, fCW);
    jProg = NuiHeight(jProg, fProgH);
    jProg = NuiTooltip(jProg, NuiBind(VAMP_BIND_BLOOD_LBL));

    // Blood label under bar
    json jBloodLbl = NuiLabel(NuiBind(VAMP_BIND_BLOOD_LBL),
                              JsonInt(NUI_HALIGN_CENTER), JsonInt(NUI_VALIGN_MIDDLE));
    jBloodLbl = NuiHeight(jBloodLbl, fLblH);

    // Status (tier name, coloured)
    json jStatusLbl = NuiLabel(NuiBind(VAMP_BIND_STATUS_LBL),
                               JsonInt(NUI_HALIGN_CENTER), JsonInt(NUI_VALIGN_MIDDLE));
    jStatusLbl = NuiHeight(jStatusLbl, fLblH);
    jStatusLbl = NuiStyleForegroundColor(jStatusLbl, NuiBind(VAMP_BIND_STATUS_COL));

    // Effects line
    json jEffLbl = NuiLabel(NuiBind(VAMP_BIND_EFFECTS_LBL),
                            JsonInt(NUI_HALIGN_CENTER), JsonInt(NUI_VALIGN_MIDDLE));
    jEffLbl = NuiHeight(jEffLbl, fLblH);

    // Sun hazard line
    json jSunLbl = NuiLabel(NuiBind(VAMP_BIND_SUN_LBL),
                            JsonInt(NUI_HALIGN_CENTER), JsonInt(NUI_VALIGN_MIDDLE));
    jSunLbl = NuiHeight(jSunLbl, fLblH);
    jSunLbl = NuiStyleForegroundColor(jSunLbl, NuiBind(VAMP_BIND_SUN_COL));

    // Feed button
    json jFeedBtn = NuiButton(JsonString("Karmi się"));
    jFeedBtn = NuiId(jFeedBtn, VAMP_BTN_FEED);
    jFeedBtn = NuiEnabled(jFeedBtn, NuiBind(VAMP_BIND_FEED_ENA));
    jFeedBtn = NuiWidth(jFeedBtn,  GetNuiScaleDimension(oPC, 140.0));
    jFeedBtn = NuiHeight(jFeedBtn, fBtnH);
    jFeedBtn = NuiTooltip(jFeedBtn, JsonString("Wysysa krew z pobliskiej żywej istoty."));

    // Cure button
    json jCureBtn = NuiButton(NuiBind(VAMP_BIND_CURE_LBL));
    jCureBtn = NuiId(jCureBtn, VAMP_BTN_CURE);
    jCureBtn = NuiEnabled(jCureBtn, NuiBind(VAMP_BIND_CURE_ENA));
    jCureBtn = NuiWidth(jCureBtn,  GetNuiScaleDimension(oPC, 150.0));
    jCureBtn = NuiHeight(jCureBtn, fBtnH);
    jCureBtn = NuiTooltip(jCureBtn, JsonString("Zużyj Krew Świętą, by zdjąć klątwę."));

    json jBtnRow = JsonArray();
    jBtnRow = JsonArrayInsert(jBtnRow, jFeedBtn);
    jBtnRow = JsonArrayInsert(jBtnRow, NuiSpacer());
    jBtnRow = JsonArrayInsert(jBtnRow, jCureBtn);

    // Assemble inner column
    json jCol = JsonArray();
    jCol = JsonArrayInsert(jCol, jTitle);
    jCol = JsonArrayInsert(jCol, jProg);
    jCol = JsonArrayInsert(jCol, jBloodLbl);
    jCol = JsonArrayInsert(jCol, CreateEmptyRow(oPC, 6.0));
    jCol = JsonArrayInsert(jCol, jStatusLbl);
    jCol = JsonArrayInsert(jCol, jEffLbl);
    jCol = JsonArrayInsert(jCol, CreateEmptyRow(oPC, 6.0));
    jCol = JsonArrayInsert(jCol, jSunLbl);
    jCol = JsonArrayInsert(jCol, CreateEmptyRow(oPC, 8.0));
    jCol = JsonArrayInsert(jCol, NuiRow(jBtnRow));

    // Side spacers for centering
    json jSide = NuiCol(JsonArrayInsert(JsonArray(), NuiSpacer()));
    json jMain = JsonArray();
    jMain = JsonArrayInsert(jMain, jSide);
    jMain = JsonArrayInsert(jMain, NuiWidth(NuiCol(jCol), fCW));
    jMain = JsonArrayInsert(jMain, jSide);
    return NuiRow(jMain);
}

void CreateVampWindow(object oPC)
{
    int nExisting = NuiFindWindow(oPC, VAMP_WINDOW);
    if(nExisting != 0)
    {
        VampUpdateUI(oPC, nExisting);
        return;
    }

    float fCX = (IntToFloat(GetPlayerDeviceProperty(oPC, PLAYER_DEVICE_PROPERTY_GUI_WIDTH))
                 - GetNuiScaleDimension(oPC, VAMP_W)) / 2.0;
    float fCY = (IntToFloat(GetPlayerDeviceProperty(oPC, PLAYER_DEVICE_PROPERTY_GUI_HEIGHT))
                 - GetNuiScaleDimension(oPC, VAMP_H)) / 2.0;
    json jGeom = NuiRect(fCX, fCY,
                         GetNuiScaleDimension(oPC, VAMP_W),
                         GetNuiScaleDimension(oPC, VAMP_H));

    // Top-bar close button (manual, since we hide the title bar)
    float fBtnH = GetNuiScaleDimension(oPC, 30.0);
    json jClose = NuiButton(JsonString("X"));
    jClose = NuiId(jClose, VAMP_BTN_CLOSE);
    jClose = NuiWidth(jClose,  GetNuiScaleDimension(oPC, 30.0));
    jClose = NuiHeight(jClose, fBtnH);
    json jTopBar = JsonArray();
    jTopBar = JsonArrayInsert(jTopBar, NuiSpacer());
    jTopBar = JsonArrayInsert(jTopBar, jClose);

    json jRootChildren = JsonArray();
    jRootChildren = JsonArrayInsert(jRootChildren, NuiRow(jTopBar));
    jRootChildren = JsonArrayInsert(jRootChildren, VampBuildLayout(oPC));
    json jRoot = NuiCol(jRootChildren);

    json jWin = NuiWindow(
        jRoot,
        JsonBool(FALSE),          // no title-bar title
        NuiBind(VAMP_WIN_GEOM),
        JsonBool(FALSE),          // not resizable
        JsonBool(FALSE),          // not collapsed
        JsonBool(FALSE),          // not closable via X
        JsonBool(TRUE),           // border
        JsonBool(FALSE));         // not transparent

    int nToken = NuiCreate(oPC, jWin, VAMP_WINDOW, VAMP_EV_SCRIPT);
    NuiSetBind(oPC, nToken, VAMP_WIN_GEOM, jGeom);
    VampUpdateUI(oPC, nToken);
}

// ================================================================
// UI data feed
// ================================================================

void VampUpdateUI(object oPC, int nToken)
{
    int nBlood = VampGetBlood(oPC);
    if(nBlood < 0) nBlood = 0;
    int nTier = VampGetTier(nBlood);

    NuiSetBind(oPC, nToken, VAMP_BIND_BLOOD_VAL,
               JsonFloat(IntToFloat(nBlood) / 100.0));
    NuiSetBind(oPC, nToken, VAMP_BIND_BLOOD_LBL,
               JsonString("Krew: " + IntToString(nBlood) + " / 100"));
    NuiSetBind(oPC, nToken, VAMP_BIND_STATUS_LBL,
               JsonString("Stan: " + VampTierLabel(nTier)));
    NuiSetBind(oPC, nToken, VAMP_BIND_STATUS_COL, VampTierColor(nTier));
    NuiSetBind(oPC, nToken, VAMP_BIND_EFFECTS_LBL,
               JsonString(VampTierEffectsLabel(nTier)));

    // Daylight / area hazard
    int bDay     = !GetIsNight();
    int bOutdoor = GetIsAreaExterior(GetArea(oPC));
    string sSun;
    json   jSunCol;
    if(bDay && bOutdoor)
    {
        sSun    = "Słońce: NIEBEZPIECZEŃSTWO — jesteś na zewnątrz!";
        jSunCol = NuiColor(255, 80, 30);
    }
    else if(bDay)
    {
        sSun    = "Słońce: Bezpieczny (wewnątrz)";
        jSunCol = NuiColor(180, 160, 80);
    }
    else
    {
        sSun    = "Słońce: Bezpieczny (noc)";
        jSunCol = NuiColor(100, 150, 220);
    }
    NuiSetBind(oPC, nToken, VAMP_BIND_SUN_LBL, JsonString(sSun));
    NuiSetBind(oPC, nToken, VAMP_BIND_SUN_COL, jSunCol);

    // Feed enabled: not currently targeting, not full, not incapacitated (tier>0)
    int bFeedEna = !GetLocalInt(oPC, VAMP_LVAR_IS_FEEDING)
                   && nTier > 0
                   && nBlood < 100;
    NuiSetBind(oPC, nToken, VAMP_BIND_FEED_ENA, JsonBool(bFeedEna));

    // Cure enabled: player carries the holy blood item
    int bHasCure = GetIsObjectValid(GetItemPossessedBy(oPC, VAMP_CURE_ITEM_TAG));
    NuiSetBind(oPC, nToken, VAMP_BIND_CURE_ENA, JsonBool(bHasCure));
    NuiSetBind(oPC, nToken, VAMP_BIND_CURE_LBL,
               JsonString(bHasCure ? "Oczyść Klątwę" : "Brak Krwi Świętej"));
}

// ================================================================
// Feeding mechanic
// ================================================================

void VampFeedOnTarget(object oPC, object oTarget)
{
    SetLocalInt(oPC, VAMP_LVAR_IS_FEEDING, 0);

    int nToken = NuiFindWindow(oPC, VAMP_WINDOW);

    if(!GetIsObjectValid(oTarget) || oTarget == oPC)
    {
        SendMessageToPC(oPC, "[Wampiryzm] Nie wybrano odpowiedniego celu.");
        if(nToken != 0) VampUpdateUI(oPC, nToken);
        return;
    }

    // Cannot feed on beings without living blood
    int nRace = GetRacialType(oTarget);
    if(nRace == RACIAL_TYPE_UNDEAD     ||
       nRace == RACIAL_TYPE_CONSTRUCT  ||
       nRace == RACIAL_TYPE_ELEMENTAL)
    {
        SendMessageToPC(oPC, "[Wampiryzm] Ta istota nie ma żywej krwi do wysysania.");
        if(nToken != 0) VampUpdateUI(oPC, nToken);
        return;
    }

    if(GetDistanceBetween(oPC, oTarget) > VAMP_FEED_RANGE)
    {
        SendMessageToPC(oPC, "[Wampiryzm] Cel jest zbyt daleko. Zbliż się.");
        if(nToken != 0) VampUpdateUI(oPC, nToken);
        return;
    }

    // Clamp drain to leave the target at 1 HP minimum
    int nHP    = GetCurrentHitPoints(oTarget);
    int nDrain = VAMP_FEED_HP_DRAIN;
    if(nHP <= nDrain) nDrain = nHP - 1;
    if(nDrain <= 0)
    {
        SendMessageToPC(oPC, "[Wampiryzm] Cel jest zbyt osłabiony — nie możesz wyssać więcej krwi.");
        if(nToken != 0) VampUpdateUI(oPC, nToken);
        return;
    }

    // Damage to target
    effect eDmg = EffectDamage(nDrain, DAMAGE_TYPE_NEGATIVE);
    effect eVFX = EffectVisualEffect(VFX_IMP_NEGATIVE_ENERGY);
    ApplyEffectToObject(DURATION_TYPE_INSTANT, EffectLinkEffects(eDmg, eVFX), oTarget);

    // Healing flash on self
    ApplyEffectToObject(DURATION_TYPE_INSTANT, EffectVisualEffect(VFX_IMP_HEALING_S), oPC);

    // Gain blood
    int nOld   = VampGetBlood(oPC);
    int nNew   = nOld + VAMP_FEED_BLOOD_GAIN;
    VampSetBlood(oPC, nNew);
    if(nNew > 100) nNew = 100;

    // Re-apply effects if tier changed
    if(VampGetTier(nNew) != VampGetTier(nOld))
        VampApplyEffects(oPC, nNew);

    SendMessageToPC(oPC,
        "[Wampiryzm] Wysysasz krew z " + GetName(oTarget) + "."
        + " Krew: " + IntToString(nNew) + "/100.");

    if(GetIsPC(oTarget))
        SendMessageToPC(oTarget,
            "[Wampiryzm] " + GetName(oPC) + " wysysa twoją krew! ("
            + IntToString(nDrain) + " HP)");

    // NPC counter-attacks
    if(!GetIsPC(oTarget) && !GetIsDead(oTarget))
        AssignCommand(oTarget, ActionAttack(oPC));

    if(nToken != 0) VampUpdateUI(oPC, nToken);
}

// ================================================================
// Infection / Cure
// ================================================================

void VampInfectPC(object oPC)
{
    if(VampIsVampire(oPC)) return;

    VampInfect(oPC);
    VampApplyEffects(oPC, 75);

    SendMessageToPC(oPC,
        "[Wampiryzm] Zimno przeszywa twoje żyły niczym ostrze lodu."
        " Klątwa krwi osiadła na tobie.");
    FloatingTextStringOnCreature("Zarażony Klątwą Wampira!", oPC, FALSE);
    ApplyEffectToObject(DURATION_TYPE_INSTANT, EffectVisualEffect(VFX_IMP_NEGATIVE_ENERGY), oPC);

    DelayCommand(1.0, CreateVampWindow(oPC));
}

void VampCurePC(object oPC)
{
    if(!VampIsVampire(oPC)) return;

    VampRemoveEffects(oPC);
    VampCure(oPC);

    int nToken = NuiFindWindow(oPC, VAMP_WINDOW);
    if(nToken != 0) NuiDestroy(oPC, nToken);

    SendMessageToPC(oPC,
        "[Wampiryzm] Klątwa krwi zostaje zerwana. Ciepło powraca do twojego ciała.");
    FloatingTextStringOnCreature("Klątwa Zdjęta!", oPC, FALSE);
    ApplyEffectToObject(DURATION_TYPE_INSTANT, EffectVisualEffect(VFX_IMP_HOLY_AID), oPC);
}

// ================================================================
// Heartbeat processing (called every ~6 s per vampire PC)
// ================================================================

void VampCheckSunDamage(object oPC, int nBlood)
{
    if(nBlood <= 0)                         return; // already incapacitated
    if(GetIsNight())                        return;
    if(!GetIsObjectValid(GetArea(oPC)))     return;
    if(!GetIsAreaExterior(GetArea(oPC)))    return;

    int nDmg = d6(1);
    effect eDmg = EffectDamage(nDmg, DAMAGE_TYPE_DIVINE);
    effect eVFX = EffectVisualEffect(VFX_IMP_HARM);
    ApplyEffectToObject(DURATION_TYPE_INSTANT, EffectLinkEffects(eDmg, eVFX), oPC);
    SendMessageToPC(oPC,
        "[Wampiryzm] Słońce pali twoją wampirzą skórę... ("
        + IntToString(nDmg) + " obrażeń świętych)");
}

void VampOnHeartbeat(object oPC)
{
    if(!GetIsPC(oPC))  return;
    if(GetIsDead(oPC)) return;

    int nOld = VampGetBlood(oPC);
    if(nOld < 0) return; // row vanished (e.g. GM purge)

    int nNew = nOld - VAMP_HB_DRAIN;
    if(nNew < 0) nNew = 0;

    VampSetBlood(oPC, nNew);

    // Tier change → re-apply effect set
    if(VampGetTier(nNew) != VampGetTier(nOld))
        VampApplyEffects(oPC, nNew);

    VampCheckSunDamage(oPC, nNew);

    // Update open window
    int nToken = NuiFindWindow(oPC, VAMP_WINDOW);
    if(nToken != 0) VampUpdateUI(oPC, nToken);

    // Threshold warnings to guide the player
    if(nNew == VAMP_TIER_SATED - 1)
        SendMessageToPC(oPC, "[Wampiryzm] Pieczęć krwi pulsuje słabo... Wkrótce poczujesz głód.");
    else if(nNew == VAMP_TIER_STARVING - 1)
        SendMessageToPC(oPC, "[Wampiryzm] Głód staje się nie do zniesienia. Musisz się nakarmić!");
    else if(nNew == 0)
        SendMessageToPC(oPC, "[Wampiryzm] Krew wyschła całkowicie. Mdlejesz z pragnienia...");
}
