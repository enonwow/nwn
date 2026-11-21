// lib_vic.nss — Core logic for the Vices (Nałogi) system.
// Covers: effect management, NUI window builder, FeedViceWindow,
//         VicConsumeDose, VicAttemptDetox, VicTick, VicRestoreEffects.
#include "lib_vic_def"

// ============================================================
// State derivation
// ============================================================

// Derives the current runtime state from SQL data + current time.
int VicGetCurrentState(int nLevel, int nLastDose, int nNow)
{
    if(nLevel <= 0) return VICE_STATE_SOBER;
    int nElapsed = nNow - nLastDose;
    if(nElapsed < VicCravingOnset(nLevel))    return VICE_STATE_SATISFIED;
    if(nElapsed < VicWithdrawalOnset(nLevel)) return VICE_STATE_CRAVING;
    return VICE_STATE_WITHDRAWAL;
}

// ============================================================
// Effect management
// ============================================================

void VicRemoveEffects(object oPC, int nSubstance)
{
    string sBuffTag  = VIC_ETAG_BUFF   + IntToString(nSubstance);
    string sWithTag  = VIC_ETAG_WITHDR + IntToString(nSubstance);
    effect eEff = GetFirstEffect(oPC);
    while(GetIsEffectValid(eEff))
    {
        string sTag = GetEffectTag(eEff);
        if(sTag == sBuffTag || sTag == sWithTag)
            RemoveEffect(oPC, eEff);
        eEff = GetNextEffect(oPC);
    }
}

void VicApplyEffects(object oPC, int nSubstance, int nState, int nLevel)
{
    VicRemoveEffects(oPC, nSubstance);
    if(nState == VICE_STATE_SOBER) return;

    int bBuff   = (nState == VICE_STATE_SATISFIED);
    string sTag = bBuff ? (VIC_ETAG_BUFF + IntToString(nSubstance))
                        : (VIC_ETAG_WITHDR + IntToString(nSubstance));
    int nMag    = VicBuffMagnitude(nLevel);   // 1, 2 or 3
    int nWMag   = nLevel;                     // withdrawal scales harder

    effect eLink;

    switch(nSubstance)
    {
        case VICE_MOONFIRE:
            if(bBuff)
            {
                eLink = TagEffect(EffectAbilityIncrease(ABILITY_STRENGTH, nMag), sTag);
                eLink = EffectLinkEffects(eLink,
                    TagEffect(EffectAbilityIncrease(ABILITY_CONSTITUTION, 1), sTag));
                eLink = EffectLinkEffects(eLink,
                    TagEffect(EffectAbilityDecrease(ABILITY_INTELLIGENCE, 1), sTag));
            }
            else
            {
                eLink = TagEffect(EffectAbilityDecrease(ABILITY_STRENGTH, nWMag), sTag);
                eLink = EffectLinkEffects(eLink,
                    TagEffect(EffectAbilityDecrease(ABILITY_DEXTERITY, 1), sTag));
                if(nLevel >= 4)
                    eLink = EffectLinkEffects(eLink,
                        TagEffect(EffectVisualEffect(VFX_DUR_BLUR), sTag));
            }
            break;

        case VICE_DREAMDUST:
            if(bBuff)
            {
                eLink = TagEffect(EffectAbilityIncrease(ABILITY_WISDOM, nMag), sTag);
                eLink = EffectLinkEffects(eLink,
                    TagEffect(EffectAbilityIncrease(ABILITY_CHARISMA, 1), sTag));
                eLink = EffectLinkEffects(eLink,
                    TagEffect(EffectAbilityDecrease(ABILITY_DEXTERITY, 1), sTag));
            }
            else
            {
                eLink = TagEffect(EffectAbilityDecrease(ABILITY_WISDOM, nWMag), sTag);
                eLink = EffectLinkEffects(eLink,
                    TagEffect(EffectAbilityDecrease(ABILITY_CHARISMA, 1), sTag));
                if(nLevel >= 3)
                    eLink = EffectLinkEffects(eLink,
                        TagEffect(EffectVisualEffect(VFX_DUR_MIND_AFFECTING_NEGATIVE), sTag));
            }
            break;

        case VICE_DEMON_BLOOD:
            if(bBuff)
            {
                eLink = TagEffect(EffectAbilityIncrease(ABILITY_STRENGTH, nMag + 1), sTag);
                eLink = EffectLinkEffects(eLink,
                    TagEffect(EffectAttackIncrease(1), sTag));
                eLink = EffectLinkEffects(eLink,
                    TagEffect(EffectAbilityDecrease(ABILITY_CHARISMA, nMag), sTag));
                eLink = EffectLinkEffects(eLink,
                    TagEffect(EffectVisualEffect(VFX_DUR_AURA_RED), sTag));
            }
            else
            {
                eLink = TagEffect(EffectAbilityDecrease(ABILITY_STRENGTH, nWMag + 1), sTag);
                eLink = EffectLinkEffects(eLink,
                    TagEffect(EffectAbilityDecrease(ABILITY_CONSTITUTION, 1), sTag));
                if(nLevel >= 3)
                    eLink = EffectLinkEffects(eLink,
                        TagEffect(EffectVisualEffect(VFX_DUR_AURA_PULSE_RED), sTag));
            }
            break;

        case VICE_BLACKROOT:
            if(bBuff)
            {
                eLink = TagEffect(EffectAbilityIncrease(ABILITY_CONSTITUTION, nMag), sTag);
                eLink = EffectLinkEffects(eLink,
                    TagEffect(EffectImmunity(IMMUNITY_TYPE_FEAR), sTag));
                eLink = EffectLinkEffects(eLink,
                    TagEffect(EffectAbilityDecrease(ABILITY_WISDOM, 1), sTag));
            }
            else
            {
                eLink = TagEffect(EffectAbilityDecrease(ABILITY_CONSTITUTION, nWMag), sTag);
                eLink = EffectLinkEffects(eLink,
                    TagEffect(EffectAbilityDecrease(ABILITY_WISDOM, 1), sTag));
                if(nLevel >= 2)
                    eLink = EffectLinkEffects(eLink,
                        TagEffect(EffectVisualEffect(VFX_DUR_MIND_AFFECTING_FEAR), sTag));
            }
            break;

        case VICE_WITCH_MILK:
            if(bBuff)
            {
                eLink = TagEffect(EffectAbilityIncrease(ABILITY_CHARISMA, nMag), sTag);
                eLink = EffectLinkEffects(eLink,
                    TagEffect(EffectSkillIncrease(SKILL_PERSUADE, nMag), sTag));
                eLink = EffectLinkEffects(eLink,
                    TagEffect(EffectAbilityDecrease(ABILITY_CONSTITUTION, 1), sTag));
            }
            else
            {
                eLink = TagEffect(EffectAbilityDecrease(ABILITY_CHARISMA, nWMag), sTag);
                eLink = EffectLinkEffects(eLink,
                    TagEffect(EffectSkillDecrease(SKILL_PERSUADE, nWMag), sTag));
            }
            break;

        case VICE_SHADOW_PASTE:
            if(bBuff)
            {
                eLink = TagEffect(EffectSkillIncrease(SKILL_HIDE, nMag * 2), sTag);
                eLink = EffectLinkEffects(eLink,
                    TagEffect(EffectSkillIncrease(SKILL_MOVE_SILENTLY, nMag), sTag));
                eLink = EffectLinkEffects(eLink,
                    TagEffect(EffectUltravision(), sTag));
                eLink = EffectLinkEffects(eLink,
                    TagEffect(EffectSkillDecrease(SKILL_SPOT, 1), sTag));
            }
            else
            {
                eLink = TagEffect(EffectSkillDecrease(SKILL_HIDE, nWMag * 2), sTag);
                eLink = EffectLinkEffects(eLink,
                    TagEffect(EffectSkillDecrease(SKILL_MOVE_SILENTLY, nWMag), sTag));
                if(nLevel >= 3)
                    eLink = EffectLinkEffects(eLink,
                        TagEffect(EffectAbilityDecrease(ABILITY_DEXTERITY, 1), sTag));
            }
            break;

        default: return;
    }

    ApplyEffectToObject(DURATION_TYPE_PERMANENT, eLink, oPC);
}

// ============================================================
// NUI — window layout
// ============================================================

json VicBuildSubstanceRow(object oPC, int nSub)
{
    float fH    = GetNuiScaleDimension(oPC, 36.0);
    float fNameW = GetNuiScaleDimension(oPC, 160.0);
    float fStW   = GetNuiScaleDimension(oPC, 90.0);
    float fLvW   = GetNuiScaleDimension(oPC, 80.0);
    float fBtnW  = GetNuiScaleDimension(oPC, 90.0);

    string sS = IntToString(nSub);

    json jName = NuiLabel(NuiBind(VIC_BIND_NAME + sS),
        JsonInt(NUI_HALIGN_LEFT), JsonInt(NUI_VALIGN_MIDDLE));
    jName = NuiWidth(jName, fNameW);
    jName = NuiStyleForegroundColor(jName, NuiBind(VIC_BIND_COLOR + sS));

    json jState = NuiLabel(NuiBind(VIC_BIND_STATE + sS),
        JsonInt(NUI_HALIGN_CENTER), JsonInt(NUI_VALIGN_MIDDLE));
    jState = NuiWidth(jState, fStW);
    jState = NuiStyleForegroundColor(jState, NuiBind(VIC_BIND_COLOR + sS));

    json jLevel = NuiLabel(NuiBind(VIC_BIND_LEVEL + sS),
        JsonInt(NUI_HALIGN_CENTER), JsonInt(NUI_VALIGN_MIDDLE));
    jLevel = NuiWidth(jLevel, fLvW);

    json jConsume = NuiButton(JsonString("Spożyj"));
    jConsume = NuiId(jConsume, VIC_BTN_CONSUME + sS);
    jConsume = NuiEnabled(jConsume, NuiBind(VIC_BIND_BTENA + sS));
    jConsume = NuiWidth(jConsume, fBtnW);
    jConsume = NuiHeight(jConsume, fH);

    json jBreak = NuiButton(JsonString("Odwyk"));
    jBreak = NuiId(jBreak, VIC_BTN_BREAK + sS);
    jBreak = NuiEnabled(jBreak, NuiBind(VIC_BIND_CLEAN + sS));
    jBreak = NuiWidth(jBreak, fBtnW);
    jBreak = NuiHeight(jBreak, fH);

    json jCells = JsonArray();
    jCells = JsonArrayInsert(jCells, jName);
    jCells = JsonArrayInsert(jCells, jState);
    jCells = JsonArrayInsert(jCells, jLevel);
    jCells = JsonArrayInsert(jCells, jConsume);
    jCells = JsonArrayInsert(jCells, jBreak);

    json jRow = NuiRow(jCells);
    return NuiHeight(jRow, fH);
}

void VicOpenWindow(object oPC)
{
    int nExisting = NuiFindWindow(oPC, VIC_WINDOW);
    if(nExisting != 0)
    {
        FeedViceWindow(oPC, nExisting);
        return;
    }

    float fW = 540.0;
    float fH = 460.0;

    float fNameW = GetNuiScaleDimension(oPC, 160.0);
    float fStW   = GetNuiScaleDimension(oPC, 90.0);
    float fLvW   = GetNuiScaleDimension(oPC, 80.0);
    float fBtnW  = GetNuiScaleDimension(oPC, 90.0);
    float fHdrH  = GetNuiScaleDimension(oPC, 22.0);

    // Header row
    json jHName  = NuiWidth(NuiLabel(JsonString("Substancja"),
        JsonInt(NUI_HALIGN_LEFT), JsonInt(NUI_VALIGN_MIDDLE)), fNameW);
    json jHState = NuiWidth(NuiLabel(JsonString("Stan"),
        JsonInt(NUI_HALIGN_CENTER), JsonInt(NUI_VALIGN_MIDDLE)), fStW);
    json jHLevel = NuiWidth(NuiLabel(JsonString("Uzależnienie"),
        JsonInt(NUI_HALIGN_CENTER), JsonInt(NUI_VALIGN_MIDDLE)), fLvW);
    json jHCons  = NuiWidth(NuiLabel(JsonString(""),
        JsonInt(NUI_HALIGN_CENTER), JsonInt(NUI_VALIGN_MIDDLE)), fBtnW);
    json jHBreak = NuiWidth(NuiLabel(JsonString(""),
        JsonInt(NUI_HALIGN_CENTER), JsonInt(NUI_VALIGN_MIDDLE)), fBtnW);

    json jHdrCells = JsonArray();
    jHdrCells = JsonArrayInsert(jHdrCells, jHName);
    jHdrCells = JsonArrayInsert(jHdrCells, jHState);
    jHdrCells = JsonArrayInsert(jHdrCells, jHLevel);
    jHdrCells = JsonArrayInsert(jHdrCells, jHCons);
    jHdrCells = JsonArrayInsert(jHdrCells, jHBreak);
    json jHdrRow = NuiHeight(NuiRow(jHdrCells), fHdrH);

    // Separator
    json jSep = NuiHeight(NuiSpacer(), GetNuiScaleDimension(oPC, 2.0));

    // Substance rows
    json jSubRows = JsonArray();
    int i;
    for(i = 0; i < VICE_COUNT; i++)
        jSubRows = JsonArrayInsert(jSubRows, VicBuildSubstanceRow(oPC, i));

    // Flavor text area
    json jFlavor = NuiLabel(NuiBind(VIC_BIND_FLAVOR),
        JsonInt(NUI_HALIGN_LEFT), JsonInt(NUI_VALIGN_MIDDLE));
    jFlavor = NuiHeight(jFlavor, GetNuiScaleDimension(oPC, 52.0));

    // Warning line
    json jWarning = NuiLabel(NuiBind(VIC_BIND_WARNING),
        JsonInt(NUI_HALIGN_LEFT), JsonInt(NUI_VALIGN_MIDDLE));
    jWarning = NuiStyleForegroundColor(jWarning, NuiColor(220, 50, 50, 255));
    jWarning = NuiHeight(jWarning, GetNuiScaleDimension(oPC, 24.0));

    // Build root column
    json jCols = JsonArray();
    jCols = JsonArrayInsert(jCols, jHdrRow);
    jCols = JsonArrayInsert(jCols, jSep);
    for(i = 0; i < VICE_COUNT; i++)
        jCols = JsonArrayInsert(jCols, JsonArrayGet(jSubRows, i));
    jCols = JsonArrayInsert(jCols, NuiSpacer());
    jCols = JsonArrayInsert(jCols, jFlavor);
    jCols = JsonArrayInsert(jCols, jWarning);

    json jRoot = NuiCol(jCols);

    json jWin = NuiWindow(jRoot,
        JsonString("Nałogi"),
        NuiBind(VIC_WIN_GEOM),
        JsonBool(FALSE),    // not resizable
        JsonBool(FALSE),    // not collapsed
        JsonBool(TRUE),     // closable
        JsonBool(FALSE),    // not transparent
        JsonBool(TRUE));    // border

    int nToken = NuiCreate(oPC, jWin, VIC_WINDOW, VIC_EV_SCRIPT);
    if(nToken == 0) return;

    float fCX = (IntToFloat(GetPlayerDeviceProperty(oPC, PLAYER_DEVICE_PROPERTY_GUI_WIDTH))
                 - GetNuiScaleDimension(oPC, fW)) / 2.0;
    float fCY = (IntToFloat(GetPlayerDeviceProperty(oPC, PLAYER_DEVICE_PROPERTY_GUI_HEIGHT))
                 - GetNuiScaleDimension(oPC, fH)) / 2.0;
    NuiSetBind(oPC, nToken, VIC_WIN_GEOM,
        NuiRect(fCX, fCY, GetNuiScaleDimension(oPC, fW), GetNuiScaleDimension(oPC, fH)));

    FeedViceWindow(oPC, nToken);
}

void FeedViceWindow(object oPC, int nToken)
{
    int nNow          = VicGetNow();
    string sFlavor    = "";
    int nInWithdrawal = 0;
    int i;

    for(i = 0; i < VICE_COUNT; i++)
    {
        string sS    = IntToString(i);
        json jRec    = VicGetAddict(oPC, i);
        int nLevel   = 0;
        int nLastDose = 0;
        if(JsonGetType(jRec) != JSON_TYPE_NULL)
        {
            nLevel    = JsonGetInt(JsonObjectGet(jRec, "level"));
            nLastDose = JsonGetInt(JsonObjectGet(jRec, "last_dose"));
        }

        int nState = VicGetCurrentState(nLevel, nLastDose, nNow);

        NuiSetBind(oPC, nToken, VIC_BIND_NAME  + sS, JsonString(VicSubstanceName(i)));
        NuiSetBind(oPC, nToken, VIC_BIND_STATE + sS, JsonString(VicStateName(nState)));
        NuiSetBind(oPC, nToken, VIC_BIND_COLOR + sS, VicStateColor(nState));

        string sLvl = (nLevel > 0) ? ("Stopień " + IntToString(nLevel)) : "Brak";
        NuiSetBind(oPC, nToken, VIC_BIND_LEVEL + sS, JsonString(sLvl));

        NuiSetBind(oPC, nToken, VIC_BIND_BTENA + sS, JsonBool(TRUE));
        NuiSetBind(oPC, nToken, VIC_BIND_CLEAN + sS, JsonBool(nLevel > 0));

        if(nState == VICE_STATE_WITHDRAWAL) nInWithdrawal++;

        // Most severe active substance gets the flavor text slot.
        if(nState == VICE_STATE_WITHDRAWAL && sFlavor == "")
            sFlavor = VicFlavorText(i, nState, nLevel);
        else if(nState == VICE_STATE_CRAVING && sFlavor == "")
            sFlavor = VicFlavorText(i, nState, nLevel);
        else if(nState == VICE_STATE_SATISFIED && sFlavor == "")
            sFlavor = VicFlavorText(i, nState, nLevel);
    }

    if(sFlavor == "")
        sFlavor = "Czysty jak woda ze strumienia... na razie.";
    NuiSetBind(oPC, nToken, VIC_BIND_FLAVOR, JsonString(sFlavor));

    string sWarn = "";
    if(nInWithdrawal == 1)
        sWarn = "UWAGA: Odstawienie aktywne. Szukaj dawki lub wytrzymaj.";
    else if(nInWithdrawal > 1)
        sWarn = "UWAGA: Odstawienie aktywne (" + IntToString(nInWithdrawal) + " substancje). Pilnie szukaj dawek.";
    NuiSetBind(oPC, nToken, VIC_BIND_WARNING, JsonString(sWarn));
}

// ============================================================
// Consume dose
// ============================================================

void VicConsumeDose(object oPC, int nSubstance)
{
    if(nSubstance < 0 || nSubstance >= VICE_COUNT) return;

    json jRec  = VicGetAddict(oPC, nSubstance);
    int nLevel = 0;
    if(JsonGetType(jRec) != JSON_TYPE_NULL)
        nLevel = JsonGetInt(JsonObjectGet(jRec, "level"));

    int nNow      = VicGetNow();
    int nNewLevel = nLevel;

    if(nLevel == 0)
    {
        // First exposure — creates level 1 addiction.
        nNewLevel = 1;
        string sMsg = "Coś się zmieniło po " + VicSubstanceName(nSubstance) + ". Ciało to zapamięta.";
        SendMessageToPC(oPC, "[Nałogi] " + sMsg);
        FloatingTextStringOnCreature(sMsg, oPC, FALSE);
    }
    else if(nLevel < 5 && d100(1) <= 20)
    {
        // 20% chance to escalate per dose when already addicted.
        nNewLevel = nLevel + 1;
        string sMsg = "Uzależnienie od " + VicSubstanceName(nSubstance)
                    + " wzrosło do stopnia " + IntToString(nNewLevel) + ".";
        SendMessageToPC(oPC, "[Nałogi] " + sMsg);
        FloatingTextStringOnCreature(sMsg, oPC, FALSE);
    }

    VicUpsertDose(oPC, nSubstance, nNewLevel, nNow);
    SetLocalInt(oPC, VIC_LVAR_STATE_PFX + IntToString(nSubstance), VICE_STATE_SATISFIED);
    VicApplyEffects(oPC, nSubstance, VICE_STATE_SATISFIED, nNewLevel);

    string sFlavor = VicFlavorText(nSubstance, VICE_STATE_SATISFIED, nNewLevel);
    FloatingTextStringOnCreature(sFlavor, oPC, FALSE);
    SendMessageToPC(oPC, "[Nałogi] " + sFlavor);

    int nToken = NuiFindWindow(oPC, VIC_WINDOW);
    if(nToken != 0) FeedViceWindow(oPC, nToken);
}

// ============================================================
// Detox attempt
// ============================================================

void VicAttemptDetox(object oPC, int nSubstance)
{
    if(nSubstance < 0 || nSubstance >= VICE_COUNT) return;

    json jRec = VicGetAddict(oPC, nSubstance);
    if(JsonGetType(jRec) == JSON_TYPE_NULL) return;
    int nLevel    = JsonGetInt(JsonObjectGet(jRec, "level"));
    int nLastDose = JsonGetInt(JsonObjectGet(jRec, "last_dose"));
    if(nLevel <= 0) return;

    int nNow = VicGetNow();
    if(nNow - nLastDose < VIC_DETOX_MIN_WAIT)
    {
        SendMessageToPC(oPC, "[Nałogi] Nie minęło wystarczająco dużo czasu od ostatniej dawki.");
        return;
    }

    // Success chance: 80% at level 1, drops 15% per level (floor 10%).
    int nChance = 80 - (nLevel - 1) * 15;
    if(nChance < 10) nChance = 10;

    if(d100(1) <= nChance)
    {
        int nNew = nLevel - 1;
        VicSetLevel(oPC, nSubstance, nNew);
        if(nNew == 0)
        {
            SetLocalInt(oPC, VIC_LVAR_STATE_PFX + IntToString(nSubstance), VICE_STATE_SOBER);
            VicRemoveEffects(oPC, nSubstance);
            string sMsg = "Pokonałeś nałóg: " + VicSubstanceName(nSubstance) + ". Ciało krzyczy, ale rozum wygrywa.";
            SendMessageToPC(oPC, "[Nałogi] " + sMsg);
            FloatingTextStringOnCreature(sMsg, oPC, FALSE);
        }
        else
        {
            string sMsg = "Uzależnienie od " + VicSubstanceName(nSubstance)
                        + " zmniejszyło się do stopnia " + IntToString(nNew) + ".";
            SendMessageToPC(oPC, "[Nałogi] " + sMsg);
        }
    }
    else
    {
        SendMessageToPC(oPC, "[Nałogi] Ciało odmówiło. Odwyk się nie powiódł.");
        FloatingTextStringOnCreature("Ciało odmówiło posłuszeństwa!", oPC, FALSE);
        // Failed detox at high addiction may worsen it.
        if(nLevel >= 3 && d100(1) <= 30)
        {
            VicSetLevel(oPC, nSubstance, nLevel + 1 <= 5 ? nLevel + 1 : 5);
            SendMessageToPC(oPC, "[Nałogi] Przy próbie odwyku uzależnienie wzrosło — ciało odrzuciło wysiłek.");
        }
    }

    int nToken = NuiFindWindow(oPC, VIC_WINDOW);
    if(nToken != 0) FeedViceWindow(oPC, nToken);
}

// ============================================================
// Tick — runs every VIC_TICK_INTERVAL seconds per logged-in PC.
// Checks for state transitions and applies/removes effects accordingly.
// Also handles natural recovery: 24h clean lowers level by 1.
// ============================================================

void VicTick(object oPC)
{
    if(!GetIsObjectValid(oPC) || !GetIsPC(oPC)) return;
    if(!GetLocalInt(oPC, VIC_LVAR_TICK)) return;

    int nNow = VicGetNow();
    int i;
    for(i = 0; i < VICE_COUNT; i++)
    {
        json jRec = VicGetAddict(oPC, i);
        if(JsonGetType(jRec) == JSON_TYPE_NULL) continue;
        int nLevel    = JsonGetInt(JsonObjectGet(jRec, "level"));
        int nLastDose = JsonGetInt(JsonObjectGet(jRec, "last_dose"));
        if(nLevel <= 0) continue;

        int nState     = VicGetCurrentState(nLevel, nLastDose, nNow);
        string sKey    = VIC_LVAR_STATE_PFX + IntToString(i);
        int nLastState = GetLocalInt(oPC, sKey);

        if(nState != nLastState)
        {
            SetLocalInt(oPC, sKey, nState);
            VicApplyEffects(oPC, i, nState, nLevel);

            if(nState == VICE_STATE_CRAVING)
            {
                string sMsg = "Pragnienie " + VicSubstanceName(i) + " narasta powoli…";
                FloatingTextStringOnCreature(sMsg, oPC, FALSE);
                SendMessageToPC(oPC, "[Nałogi] " + sMsg);
            }
            else if(nState == VICE_STATE_WITHDRAWAL)
            {
                string sMsg = VicFlavorText(i, VICE_STATE_WITHDRAWAL, nLevel);
                FloatingTextStringOnCreature(sMsg, oPC, FALSE);
                SendMessageToPC(oPC, "[Nałogi] " + sMsg);
            }
        }

        // Natural recovery: 24h completely clean drops level by 1.
        if(nState == VICE_STATE_WITHDRAWAL && (nNow - nLastDose) >= 86400)
        {
            int nNew = nLevel - 1;
            if(nNew < 0) nNew = 0;
            VicSetLevel(oPC, i, nNew);
            if(nNew == 0)
            {
                SetLocalInt(oPC, sKey, VICE_STATE_SOBER);
                VicRemoveEffects(oPC, i);
                string sMsg = "Ciało przeszło przez piekło i wyszło czyste z nałogu: "
                            + VicSubstanceName(i) + ".";
                FloatingTextStringOnCreature(sMsg, oPC, FALSE);
                SendMessageToPC(oPC, "[Nałogi] " + sMsg);
            }
        }
    }

    int nToken = NuiFindWindow(oPC, VIC_WINDOW);
    if(nToken != 0) FeedViceWindow(oPC, nToken);

    DelayCommand(VIC_TICK_INTERVAL, VicTick(oPC));
}

void VicStartTick(object oPC)
{
    if(GetLocalInt(oPC, VIC_LVAR_TICK)) return;
    SetLocalInt(oPC, VIC_LVAR_TICK, 1);
    DelayCommand(VIC_TICK_INTERVAL, VicTick(oPC));
}

void VicStopTick(object oPC)
{
    DeleteLocalInt(oPC, VIC_LVAR_TICK);
}

// Reapplies persisted effects after login.
void VicRestoreEffects(object oPC)
{
    int nNow = VicGetNow();
    int i;
    for(i = 0; i < VICE_COUNT; i++)
    {
        json jRec = VicGetAddict(oPC, i);
        if(JsonGetType(jRec) == JSON_TYPE_NULL) continue;
        int nLevel    = JsonGetInt(JsonObjectGet(jRec, "level"));
        int nLastDose = JsonGetInt(JsonObjectGet(jRec, "last_dose"));
        if(nLevel <= 0) continue;

        int nState = VicGetCurrentState(nLevel, nLastDose, nNow);
        SetLocalInt(oPC, VIC_LVAR_STATE_PFX + IntToString(i), nState);
        VicApplyEffects(oPC, i, nState, nLevel);

        if(nState == VICE_STATE_WITHDRAWAL)
        {
            string sMsg = "[Nałogi] Odstawienie aktywne: " + VicSubstanceName(i) + ".";
            SendMessageToPC(oPC, sMsg);
        }
    }
}
