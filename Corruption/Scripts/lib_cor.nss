// lib_cor.nss  –  Corruption: core logic, effect management, NUI building

#include "lib_cor_def"

// ================================================================
// Effect management
// ================================================================

void CorRemoveEffects(object oPC)
{
    effect eEff = GetFirstEffect(oPC);
    while(GetIsEffectValid(eEff))
    {
        if(GetEffectTag(eEff) == COR_EFFECT_TAG)
            RemoveEffect(oPC, eEff);
        eEff = GetNextEffect(oPC);
    }
}

void CorApplyEffects(object oPC)
{
    CorRemoveEffects(oPC);

    int nCorruption = GetLocalInt(oPC, COR_LVAR_CORRUPTION);
    int nStage      = CorGetStage(nCorruption);

    if(nStage == COR_STAGE_PURE) return;

    effect eCHA, eWIS, eSTR, eAura;

    switch(nStage)
    {
        case COR_STAGE_TAINTED:
            eCHA = TagEffect(EffectAbilityDecrease(ABILITY_CHARISMA, 1), COR_EFFECT_TAG);
            ApplyEffectToObject(DURATION_TYPE_PERMANENT, eCHA, oPC);
            break;

        case COR_STAGE_FALLEN:
            eCHA = TagEffect(EffectAbilityDecrease(ABILITY_CHARISMA, 2), COR_EFFECT_TAG);
            ApplyEffectToObject(DURATION_TYPE_PERMANENT, eCHA, oPC);

            eWIS = TagEffect(EffectAbilityDecrease(ABILITY_WISDOM, 1), COR_EFFECT_TAG);
            ApplyEffectToObject(DURATION_TYPE_PERMANENT, eWIS, oPC);
            break;

        case COR_STAGE_CURSED:
            eCHA = TagEffect(EffectAbilityDecrease(ABILITY_CHARISMA, 4), COR_EFFECT_TAG);
            ApplyEffectToObject(DURATION_TYPE_PERMANENT, eCHA, oPC);

            eWIS = TagEffect(EffectAbilityDecrease(ABILITY_WISDOM, 2), COR_EFFECT_TAG);
            ApplyEffectToObject(DURATION_TYPE_PERMANENT, eWIS, oPC);

            eAura = TagEffect(EffectVisualEffect(VFX_DUR_AURA_PULSE_RED_BLACK), COR_EFFECT_TAG);
            ApplyEffectToObject(DURATION_TYPE_PERMANENT, eAura, oPC);
            break;

        case COR_STAGE_DAMNED:
            eCHA = TagEffect(EffectAbilityDecrease(ABILITY_CHARISMA, 6), COR_EFFECT_TAG);
            ApplyEffectToObject(DURATION_TYPE_PERMANENT, eCHA, oPC);

            eWIS = TagEffect(EffectAbilityDecrease(ABILITY_WISDOM, 4), COR_EFFECT_TAG);
            ApplyEffectToObject(DURATION_TYPE_PERMANENT, eWIS, oPC);

            eSTR = TagEffect(EffectAbilityDecrease(ABILITY_STRENGTH, 2), COR_EFFECT_TAG);
            ApplyEffectToObject(DURATION_TYPE_PERMANENT, eSTR, oPC);

            eAura = TagEffect(EffectVisualEffect(VFX_DUR_AURA_PULSE_RED_BLACK), COR_EFFECT_TAG);
            ApplyEffectToObject(DURATION_TYPE_PERMANENT, eAura, oPC);
            break;
    }
}

// ================================================================
// Corruption modification (public API used by other systems)
// ================================================================

void CorGainCorruption(object oPC, int nAmount, string sFlavor)
{
    int nOld   = GetLocalInt(oPC, COR_LVAR_CORRUPTION);
    int nNew   = nOld + nAmount;
    if(nNew > 100) nNew = 100;
    if(nNew == nOld) return;

    SetLocalInt(oPC, COR_LVAR_CORRUPTION, nNew);
    CorDbSetCorruption(oPC, nNew);

    int nOldStage = CorGetStage(nOld);
    int nNewStage = CorGetStage(nNew);

    CorApplyEffects(oPC);

    if(sFlavor != "")
        SendMessageToPC(oPC, "[Korupcja] " + sFlavor);

    if(nNewStage > nOldStage)
    {
        FloatingTextStringOnCreature(
            "Twoja dusza osuwa się głębiej w mrok... [" + CorStageName(nNewStage) + "]",
            oPC, FALSE);
        SendMessageToPC(oPC,
            "[Korupcja] Nowe stadium: " + CorStageName(nNewStage) + ".");
    }

    int nToken = NuiFindWindow(oPC, COR_WINDOW);
    if(nToken != 0) CorRefreshWindow(oPC);
}

void CorReduceCorruption(object oPC, int nAmount)
{
    int nOld = GetLocalInt(oPC, COR_LVAR_CORRUPTION);
    int nNew = nOld - nAmount;
    if(nNew < 0) nNew = 0;
    if(nNew == nOld) return;

    SetLocalInt(oPC, COR_LVAR_CORRUPTION, nNew);
    CorDbSetCorruption(oPC, nNew);

    int nOldStage = CorGetStage(nOld);
    int nNewStage = CorGetStage(nNew);

    CorApplyEffects(oPC);

    if(nNewStage < nOldStage)
    {
        FloatingTextStringOnCreature(
            "Część ciemności odpłynęła... [" + CorStageName(nNewStage) + "]",
            oPC, FALSE);
    }

    int nToken = NuiFindWindow(oPC, COR_WINDOW);
    if(nToken != 0) CorRefreshWindow(oPC);
}

// ================================================================
// Ritual (NUI-triggered): requires gold, has 24-h cooldown
// ================================================================

void CorPerformRitual(object oPC)
{
    int nNow      = CorDbNow();
    int nLast     = CorDbGetLastRitual(oPC);
    int nCooldown = COR_RITUAL_COOLDOWN - (nNow - nLast);

    if(nCooldown > 0)
    {
        int nHours = nCooldown / 3600;
        int nMins  = (nCooldown % 3600) / 60;
        SendMessageToPC(oPC,
            "[Korupcja] Rytuał wymaga skupienia. Odczekaj jeszcze " +
            IntToString(nHours) + "h " + IntToString(nMins) + "min.");
        return;
    }

    int nGold = GetGold(oPC);
    if(nGold < COR_RITUAL_GOLD_COST)
    {
        SendMessageToPC(oPC,
            "[Korupcja] Rytuał wymaga " +
            IntToString(COR_RITUAL_GOLD_COST) + " sztuk złota jako ofiary.");
        return;
    }

    int nCorruption = GetLocalInt(oPC, COR_LVAR_CORRUPTION);
    if(nCorruption == 0)
    {
        SendMessageToPC(oPC, "[Korupcja] Twoja dusza jest czysta — rytuał nie jest potrzebny.");
        return;
    }

    AssignCommand(oPC, TakeGoldFromCreature(COR_RITUAL_GOLD_COST, oPC, TRUE));
    CorDbSetLastRitual(oPC);

    effect eLight = EffectVisualEffect(VFX_IMP_SUNSTRIKE);
    ApplyEffectToObject(DURATION_TYPE_INSTANT, eLight, oPC);

    SendMessageToPC(oPC,
        "[Korupcja] Wypowiadasz słowa pokuty. Pieczęć mroku słabnie...");

    CorReduceCorruption(oPC, COR_RITUAL_REDUCTION);

    int nToken = NuiFindWindow(oPC, COR_WINDOW);
    if(nToken != 0) CorRefreshWindow(oPC);
}

// ================================================================
// Holy water item use
// ================================================================

void CorUseHolyWater(object oPC, object oItem)
{
    int nCorruption = GetLocalInt(oPC, COR_LVAR_CORRUPTION);
    if(nCorruption == 0)
    {
        SendMessageToPC(oPC,
            "[Korupcja] Święcona woda nic nie robi — twoja dusza jest czysta.");
        return;
    }

    DestroyObject(oItem);

    effect eHoly = EffectVisualEffect(VFX_IMP_HOLY_AID);
    ApplyEffectToObject(DURATION_TYPE_INSTANT, eHoly, oPC);

    SendMessageToPC(oPC,
        "[Korupcja] Święcona woda paruje na twojej skórze. Mrok cofa się odrobinę.");

    CorReduceCorruption(oPC, COR_HWATER_REDUCTION);
}

// ================================================================
// NUI – populate binds after window creation / refresh
// ================================================================

void CorRefreshWindow(object oPC)
{
    int nToken = NuiFindWindow(oPC, COR_WINDOW);
    if(nToken == 0) return;

    int nCorruption = GetLocalInt(oPC, COR_LVAR_CORRUPTION);
    int nStage      = CorGetStage(nCorruption);

    NuiSetBind(oPC, nToken, COR_BIND_STAGE_LBL,
        JsonString(CorStageName(nStage) + "  (" + IntToString(nCorruption) + "/100)"));

    NuiSetBind(oPC, nToken, COR_BIND_VALUE_LBL,
        JsonString(IntToString(nCorruption) + " / 100"));

    NuiSetBind(oPC, nToken, COR_BIND_BAR_VAL,
        JsonFloat(IntToFloat(nCorruption) / 100.0));

    NuiSetBind(oPC, nToken, COR_BIND_FLAVOR_LBL,
        JsonString(CorStageFlavor(nStage)));

    NuiSetBind(oPC, nToken, COR_BIND_PENALTY_LBL,
        JsonString(CorStagePenalties(nStage)));

    // Ritual button state
    int nNow     = CorDbNow();
    int nLast    = CorDbGetLastRitual(oPC);
    int nCooldownSec = COR_RITUAL_COOLDOWN - (nNow - nLast);
    int bCanRitual   = (nCooldownSec <= 0 && nCorruption > 0);

    NuiSetBind(oPC, nToken, COR_BIND_RITUAL_ENA, JsonBool(bCanRitual));

    if(bCanRitual)
        NuiSetBind(oPC, nToken, COR_BIND_RITUAL_LBL,
            JsonString("Odpokutuj (" + IntToString(COR_RITUAL_GOLD_COST) + " zł)"));
    else if(nCorruption == 0)
        NuiSetBind(oPC, nToken, COR_BIND_RITUAL_LBL,
            JsonString("Dusza czysta"));
    else
    {
        int nH = nCooldownSec / 3600;
        int nM = (nCooldownSec % 3600) / 60;
        NuiSetBind(oPC, nToken, COR_BIND_RITUAL_LBL,
            JsonString("Cooldown: " + IntToString(nH) + "h " + IntToString(nM) + "m"));
    }
}

// ================================================================
// NUI – build layout
// ================================================================

json CorBuildLayout(object oPC)
{
    float fBtnH  = GetNuiScaleDimension(oPC, 30.0);
    float fBarH  = GetNuiScaleDimension(oPC, 18.0);
    float fLblH  = GetNuiScaleDimension(oPC, 24.0);
    float fTextH = GetNuiScaleDimension(oPC, 66.0);
    float fPenH  = GetNuiScaleDimension(oPC, 88.0);
    float fContentW = GetNuiScaleDimension(oPC, 380.0);

    // Stage label (large, centered)
    json jStageLbl = NuiHeight(
        NuiLabel(NuiBind(COR_BIND_STAGE_LBL),
            JsonInt(NUI_HALIGN_CENTER), JsonInt(NUI_VALIGN_MIDDLE)),
        GetNuiScaleDimension(oPC, 32.0));

    // Progress bar
    json jBar = NuiHeight(NuiProgress(NuiBind(COR_BIND_BAR_VAL)), fBarH);

    // Flavor text (multi-line)
    json jFlavor = NuiHeight(
        NuiText(NuiBind(COR_BIND_FLAVOR_LBL), FALSE),
        fTextH);

    // Separator label
    json jPenHdr = NuiHeight(
        NuiLabel(JsonString("Aktywne kary:"),
            JsonInt(NUI_HALIGN_LEFT), JsonInt(NUI_VALIGN_MIDDLE)),
        fLblH);

    // Penalties (multi-line text, read-only)
    json jPen = NuiHeight(
        NuiText(NuiBind(COR_BIND_PENALTY_LBL), FALSE),
        fPenH);

    // Ritual button
    json jRitualBtn = NuiButton(NuiBind(COR_BIND_RITUAL_LBL));
    jRitualBtn = NuiId(jRitualBtn, COR_BTN_RITUAL);
    jRitualBtn = NuiEnabled(jRitualBtn, NuiBind(COR_BIND_RITUAL_ENA));
    jRitualBtn = NuiWidth(jRitualBtn, GetNuiScaleDimension(oPC, 220.0));
    jRitualBtn = NuiHeight(jRitualBtn, fBtnH);
    jRitualBtn = NuiTooltip(jRitualBtn,
        JsonString("Wykonaj rytuał pokuty — usuwa " +
            IntToString(COR_RITUAL_REDUCTION) + " pkt korupcji. Odnawia się co 24h."));

    // Close button
    json jClose = NuiButton(JsonString("Zamknij"));
    jClose = NuiId(jClose, COR_BTN_CLOSE);
    jClose = NuiWidth(jClose, GetNuiScaleDimension(oPC, 100.0));
    jClose = NuiHeight(jClose, fBtnH);

    // Bottom row
    json jBotRow = JsonArray();
    jBotRow = JsonArrayInsert(jBotRow, jRitualBtn);
    jBotRow = JsonArrayInsert(jBotRow, NuiSpacer());
    jBotRow = JsonArrayInsert(jBotRow, jClose);

    // Assemble column
    json jCol = JsonArray();
    jCol = JsonArrayInsert(jCol, jStageLbl);
    jCol = JsonArrayInsert(jCol, CreateEmptyRow(oPC, 4.0));
    jCol = JsonArrayInsert(jCol, jBar);
    jCol = JsonArrayInsert(jCol, CreateEmptyRow(oPC, 8.0));
    jCol = JsonArrayInsert(jCol, jFlavor);
    jCol = JsonArrayInsert(jCol, CreateEmptyRow(oPC, 4.0));
    jCol = JsonArrayInsert(jCol, jPenHdr);
    jCol = JsonArrayInsert(jCol, jPen);
    jCol = JsonArrayInsert(jCol, CreateEmptyRow(oPC, 6.0));
    jCol = JsonArrayInsert(jCol, NuiRow(jBotRow));

    // Wrap in centering side columns (Mailbox/LFG pattern)
    json jSide    = NuiCol(JsonArrayInsert(JsonArray(), NuiSpacer()));
    json jMainRow = JsonArray();
    jMainRow = JsonArrayInsert(jMainRow, jSide);
    jMainRow = JsonArrayInsert(jMainRow, NuiWidth(NuiCol(jCol), fContentW));
    jMainRow = JsonArrayInsert(jMainRow, jSide);
    return NuiRow(jMainRow);
}

// ================================================================
// Window open / reopen
// ================================================================

void CorOpenWindow(object oPC)
{
    int nExisting = NuiFindWindow(oPC, COR_WINDOW);
    if(nExisting != 0)
    {
        CorRefreshWindow(oPC);
        return;
    }

    float fCX = (IntToFloat(GetPlayerDeviceProperty(oPC, PLAYER_DEVICE_PROPERTY_GUI_WIDTH))
                 - GetNuiScaleDimension(oPC, COR_W)) / 2.0;
    float fCY = (IntToFloat(GetPlayerDeviceProperty(oPC, PLAYER_DEVICE_PROPERTY_GUI_HEIGHT))
                 - GetNuiScaleDimension(oPC, COR_H)) / 2.0;
    json jGeom = NuiRect(fCX, fCY,
                         GetNuiScaleDimension(oPC, COR_W),
                         GetNuiScaleDimension(oPC, COR_H));

    json jRoot = CorBuildLayout(oPC);

    json jWin = NuiWindow(
        jRoot,
        JsonString("Korupcja Duszy"),
        NuiBind(COR_WIN_GEOM),
        JsonBool(FALSE),   // resizable
        JsonBool(FALSE),   // collapsed
        JsonBool(TRUE),    // closable
        JsonBool(TRUE),    // transparent
        JsonBool(FALSE));  // border

    int nToken = NuiCreate(oPC, jWin, COR_WINDOW, COR_EV);
    NuiSetBind(oPC, nToken, COR_WIN_GEOM, jGeom);

    CorRefreshWindow(oPC);
}
