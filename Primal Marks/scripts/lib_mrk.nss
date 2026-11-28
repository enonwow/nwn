#include "lib_mrk_def"

void MrkOpenWindow(object oPC);
void MrkFeedWindow(object oPC, int nToken);
void MrkActivateTransform(object oPC, int nType);
void MrkEndTransform(object oPC);
void MrkApplyBrand(object oPC, int nType);
void MrkReapplyBrands(object oPC);
void MrkOnCreatureDeath(object oPC, object oVictim);

// ----------------------------------------------------------------
// NUI helpers
// ----------------------------------------------------------------

json MrkBuildEssenceRow(object oPC, int nType)
{
    float fBtnH  = GetNuiScaleDimension(oPC, 28.0);
    float fBarH  = GetNuiScaleDimension(oPC, 18.0);
    float fLblW  = GetNuiScaleDimension(oPC, 110.0);
    float fPctW  = GetNuiScaleDimension(oPC, 70.0);
    float fBtnW  = GetNuiScaleDimension(oPC, 130.0);
    float fStW   = GetNuiScaleDimension(oPC, 80.0);

    string sI = IntToString(nType);

    // Name label
    json jNameLbl = NuiLabel(JsonString(MrkTypeName(nType)),
        JsonInt(NUI_HALIGN_LEFT), JsonInt(NUI_VALIGN_MIDDLE));
    jNameLbl = NuiWidth(jNameLbl, fLblW);

    // Progress bar
    json jBar = NuiProgress(NuiBind(MRK_BIND_BARVAL + sI));
    jBar = NuiHeight(jBar, fBarH);

    // Percentage label
    json jPct = NuiLabel(NuiBind(MRK_BIND_BARPCT + sI),
        JsonInt(NUI_HALIGN_CENTER), JsonInt(NUI_VALIGN_MIDDLE));
    jPct = NuiWidth(jPct, fPctW);

    // Status (Aktywny / CD pozostało)
    json jStatus = NuiLabel(NuiBind(MRK_BIND_STATUS + sI),
        JsonInt(NUI_HALIGN_CENTER), JsonInt(NUI_VALIGN_MIDDLE));
    jStatus = NuiWidth(jStatus, fStW);

    // Transform button
    json jBtn = NuiButton(NuiBind(MRK_BIND_BTN_LBL + sI));
    jBtn = NuiId(jBtn, MRK_BTN_TRANSFORM + sI);
    jBtn = NuiEnabled(jBtn, NuiBind(MRK_BIND_BTN_ENA + sI));
    jBtn = NuiWidth(jBtn, fBtnW);
    jBtn = NuiHeight(jBtn, fBtnH);

    json jRow = JsonArray();
    jRow = JsonArrayInsert(jRow, jNameLbl);
    jRow = JsonArrayInsert(jRow, jBar);
    jRow = JsonArrayInsert(jRow, jPct);
    jRow = JsonArrayInsert(jRow, jStatus);
    jRow = JsonArrayInsert(jRow, jBtn);

    return NuiRow(jRow);
}

json MrkBuildBrandRow(object oPC, int nType)
{
    float fH   = GetNuiScaleDimension(oPC, 20.0);
    string sI  = IntToString(nType);

    json jLbl = NuiLabel(NuiBind(MRK_BIND_BRAND_LBL + sI),
        JsonInt(NUI_HALIGN_LEFT), JsonInt(NUI_VALIGN_MIDDLE));
    jLbl = NuiHeight(jLbl, fH);
    jLbl = NuiVisible(jLbl, NuiBind(MRK_BIND_BRAND_VIS + sI));

    return NuiRow(JsonArrayInsert(JsonArray(), jLbl));
}

json MrkBuildLayout(object oPC)
{
    float fBtnH = GetNuiScaleDimension(oPC, 30.0);
    float fSep  = GetNuiScaleDimension(oPC, 6.0);

    // Header
    json jHeader = NuiLabel(
        JsonString("Piętna Prymalne — esencja zabitych istot"),
        JsonInt(NUI_HALIGN_CENTER), JsonInt(NUI_VALIGN_MIDDLE));
    jHeader = NuiHeight(jHeader, fBtnH);

    // Info label (active transform description)
    json jInfo = NuiLabel(NuiBind(MRK_BIND_INFO),
        JsonInt(NUI_HALIGN_LEFT), JsonInt(NUI_VALIGN_MIDDLE));
    jInfo = NuiHeight(jInfo, GetNuiScaleDimension(oPC, 36.0));

    // Essence rows
    json jCol = JsonArray();
    jCol = JsonArrayInsert(jCol, NuiRow(JsonArrayInsert(JsonArray(), jHeader)));
    jCol = JsonArrayInsert(jCol, NuiRow(JsonArrayInsert(JsonArray(), jInfo)));
    jCol = JsonArrayInsert(jCol, CreateEmptyRow(oPC, 4.0));

    // Column header
    float fLblW = GetNuiScaleDimension(oPC, 110.0);
    float fPctW = GetNuiScaleDimension(oPC, 70.0);
    float fStW  = GetNuiScaleDimension(oPC, 80.0);
    float fBtnW = GetNuiScaleDimension(oPC, 130.0);
    json jHdr = JsonArray();
    json jH1 = NuiLabel(JsonString("Typ"), JsonInt(NUI_HALIGN_LEFT), JsonInt(NUI_VALIGN_MIDDLE));
    jH1 = NuiWidth(jH1, fLblW);
    json jH2 = NuiLabel(JsonString("Esencja"), JsonInt(NUI_HALIGN_CENTER), JsonInt(NUI_VALIGN_MIDDLE));
    json jH3 = NuiLabel(JsonString("Ilość"), JsonInt(NUI_HALIGN_CENTER), JsonInt(NUI_VALIGN_MIDDLE));
    jH3 = NuiWidth(jH3, fPctW);
    json jH4 = NuiLabel(JsonString("Stan"), JsonInt(NUI_HALIGN_CENTER), JsonInt(NUI_VALIGN_MIDDLE));
    jH4 = NuiWidth(jH4, fStW);
    json jH5 = NuiLabel(JsonString("Akcja"), JsonInt(NUI_HALIGN_CENTER), JsonInt(NUI_VALIGN_MIDDLE));
    jH5 = NuiWidth(jH5, fBtnW);
    jHdr = JsonArrayInsert(jHdr, jH1);
    jHdr = JsonArrayInsert(jHdr, jH2);
    jHdr = JsonArrayInsert(jHdr, jH3);
    jHdr = JsonArrayInsert(jHdr, jH4);
    jHdr = JsonArrayInsert(jHdr, jH5);
    jCol = JsonArrayInsert(jCol, NuiRow(jHdr));

    int i;
    for(i = 0; i < MRK_TYPE_COUNT; i++)
    {
        jCol = JsonArrayInsert(jCol, MrkBuildEssenceRow(oPC, i));
    }

    // Brands section
    jCol = JsonArrayInsert(jCol, CreateEmptyRow(oPC, 8.0));
    json jBrandHdr = NuiLabel(JsonString("— Trwałe Piętna —"),
        JsonInt(NUI_HALIGN_CENTER), JsonInt(NUI_VALIGN_MIDDLE));
    jBrandHdr = NuiHeight(jBrandHdr, GetNuiScaleDimension(oPC, 22.0));
    jCol = JsonArrayInsert(jCol, NuiRow(JsonArrayInsert(JsonArray(), jBrandHdr)));

    for(i = 0; i < MRK_TYPE_COUNT; i++)
    {
        jCol = JsonArrayInsert(jCol, MrkBuildBrandRow(oPC, i));
    }

    // Close button
    jCol = JsonArrayInsert(jCol, CreateEmptyRow(oPC, 8.0));
    json jClose = NuiButton(JsonString("Zamknij"));
    jClose = NuiId(jClose, MRK_BTN_CLOSE);
    jClose = NuiWidth(jClose, GetNuiScaleDimension(oPC, 120.0));
    jClose = NuiHeight(jClose, GetNuiScaleDimension(oPC, 30.0));
    json jCloseRow = JsonArray();
    jCloseRow = JsonArrayInsert(jCloseRow, NuiSpacer());
    jCloseRow = JsonArrayInsert(jCloseRow, jClose);
    jCloseRow = JsonArrayInsert(jCloseRow, NuiSpacer());
    jCol = JsonArrayInsert(jCol, NuiRow(jCloseRow));

    return NuiCol(jCol);
}

// ----------------------------------------------------------------
// Window open / feed
// ----------------------------------------------------------------

void MrkOpenWindow(object oPC)
{
    int nToken = NuiFindWindow(oPC, MRK_WINDOW);
    if(nToken != 0)
    {
        MrkFeedWindow(oPC, nToken);
        return;
    }

    float fCX = (IntToFloat(GetPlayerDeviceProperty(oPC, PLAYER_DEVICE_PROPERTY_GUI_WIDTH))
                 - GetNuiScaleDimension(oPC, MRK_W)) / 2.0;
    float fCY = (IntToFloat(GetPlayerDeviceProperty(oPC, PLAYER_DEVICE_PROPERTY_GUI_HEIGHT))
                 - GetNuiScaleDimension(oPC, MRK_H)) / 2.0;
    json jGeom = NuiRect(fCX, fCY,
        GetNuiScaleDimension(oPC, MRK_W),
        GetNuiScaleDimension(oPC, MRK_H));

    json jWin = NuiWindow(
        MrkBuildLayout(oPC),
        JsonString("Piętna Prymalne"),
        NuiBind(MRK_WIN_GEOM),
        JsonBool(FALSE),
        JsonBool(FALSE),
        JsonBool(TRUE),
        JsonBool(TRUE),
        JsonBool(FALSE));

    nToken = NuiCreate(oPC, jWin, MRK_WINDOW, MRK_EV_SCRIPT);
    NuiSetBind(oPC, nToken, MRK_WIN_GEOM, jGeom);
    MrkFeedWindow(oPC, nToken);
}

void MrkFeedWindow(object oPC, int nToken)
{
    json jData = MrkEnsureData(oPC);

    // Active state is tracked via local int: 0=none, 1..5 = type+1
    // CD is tracked as a boolean local int cleared by DelayCommand.
    int nActiveBit = GetLocalInt(oPC, MRK_LVAR_ACTIVE);

    int nBrands = JsonGetInt(JsonObjectGet(jData, "brands"));

    string sInfoTxt = "Zbierasz esencję zabitych istot.\nPróg transformacji: " + IntToString(MRK_THRESHOLD) + " pkt. Czas trwania: 3 min.";
    if(nActiveBit > 0)
    {
        int nActType = nActiveBit - 1;
        sInfoTxt = "Aktywna transformacja: " + MrkTypeName(nActType) + "\n" + MrkTypeDesc(nActType);
    }
    NuiSetBind(oPC, nToken, MRK_BIND_INFO, JsonString(sInfoTxt));

    int i;
    for(i = 0; i < MRK_TYPE_COUNT; i++)
    {
        string sI   = IntToString(i);
        int nEss    = MrkGetEssenceFromData(jData, i);
        int nTotal  = MrkGetTotalFromData(jData, i);
        int bOnCD   = GetLocalInt(oPC, MRK_LVAR_CD + sI);
        int bActive = (nActiveBit == i + 1);

        float fBarVal = IntToFloat(nEss) / IntToFloat(MRK_THRESHOLD);
        if(fBarVal > 1.0) fBarVal = 1.0;

        string sPct  = IntToString(nEss) + " / " + IntToString(MRK_THRESHOLD);
        string sStatus;
        string sBtnLbl;
        int bBtnEna;

        if(bActive)
        {
            sStatus  = "Aktywny";
            sBtnLbl  = "Zakończ";
            bBtnEna  = TRUE;
        }
        else if(bOnCD)
        {
            sStatus  = "Odnawia się";
            sBtnLbl  = "Niedostępna";
            bBtnEna  = FALSE;
        }
        else if(nActiveBit > 0)
        {
            // Another transform active
            sStatus  = "-";
            sBtnLbl  = "Inna aktywna";
            bBtnEna  = FALSE;
        }
        else if(nEss >= MRK_THRESHOLD)
        {
            sStatus  = "Gotowe";
            sBtnLbl  = "Transformuj";
            bBtnEna  = TRUE;
        }
        else
        {
            sStatus  = "-";
            sBtnLbl  = "Zbyt mało";
            bBtnEna  = FALSE;
        }

        NuiSetBind(oPC, nToken, MRK_BIND_BARVAL  + sI, JsonFloat(fBarVal));
        NuiSetBind(oPC, nToken, MRK_BIND_BARPCT  + sI, JsonString(sPct));
        NuiSetBind(oPC, nToken, MRK_BIND_STATUS  + sI, JsonString(sStatus));
        NuiSetBind(oPC, nToken, MRK_BIND_BTN_LBL + sI, JsonString(sBtnLbl));
        NuiSetBind(oPC, nToken, MRK_BIND_BTN_ENA + sI, JsonBool(bBtnEna));

        int bHasBrand = (nBrands & (1 << i)) != 0;
        NuiSetBind(oPC, nToken, MRK_BIND_BRAND_LBL + sI, JsonString(MrkBrandFlavor(i)));
        NuiSetBind(oPC, nToken, MRK_BIND_BRAND_VIS + sI, JsonBool(bHasBrand));
    }
}

// ----------------------------------------------------------------
// Transform application / removal
// ----------------------------------------------------------------

void MrkApplyTransformEffects(object oPC, int nType)
{
    effect eVFX = EffectVisualEffect(MrkTransformVFX(nType));
    eVFX = ExtraordinaryEffect(eVFX);

    switch(nType)
    {
        case MRK_TYPE_BEAST:
        {
            effect eAtk  = ExtraordinaryEffect(EffectAttackIncrease(2, ATTACK_BONUS_ONHAND));
            effect eSkS  = ExtraordinaryEffect(EffectSkillIncrease(SKILL_SEARCH, 5));
            effect eSkSp = ExtraordinaryEffect(EffectSkillIncrease(SKILL_SPOT, 5));
            effect eReg  = ExtraordinaryEffect(EffectRegenerate(1, 6.0));
            ApplyEffectToObject(DURATION_TYPE_TEMPORARY, eAtk,  oPC, MRK_TRANSFORM_DUR);
            ApplyEffectToObject(DURATION_TYPE_TEMPORARY, eSkS,  oPC, MRK_TRANSFORM_DUR);
            ApplyEffectToObject(DURATION_TYPE_TEMPORARY, eSkSp, oPC, MRK_TRANSFORM_DUR);
            ApplyEffectToObject(DURATION_TYPE_TEMPORARY, eReg,  oPC, MRK_TRANSFORM_DUR);
            break;
        }
        case MRK_TYPE_UNDEAD:
        {
            effect eAC   = ExtraordinaryEffect(EffectACIncrease(2, AC_NATURAL_BONUS));
            effect eAura = ExtraordinaryEffect(EffectAreaOfEffect(AOE_MOB_FEAR, "", "", ""));
            effect eFear = ExtraordinaryEffect(EffectImmunity(IMMUNITY_TYPE_FEAR));
            ApplyEffectToObject(DURATION_TYPE_TEMPORARY, eAC,   oPC, MRK_TRANSFORM_DUR);
            ApplyEffectToObject(DURATION_TYPE_TEMPORARY, eAura, oPC, MRK_TRANSFORM_DUR);
            ApplyEffectToObject(DURATION_TYPE_TEMPORARY, eFear, oPC, MRK_TRANSFORM_DUR);
            break;
        }
        case MRK_TYPE_ELEMENTAL:
        {
            effect eFire = ExtraordinaryEffect(EffectDamageResistance(DAMAGE_TYPE_FIRE,       10, 0));
            effect eCold = ExtraordinaryEffect(EffectDamageResistance(DAMAGE_TYPE_COLD,       10, 0));
            effect eElec = ExtraordinaryEffect(EffectDamageResistance(DAMAGE_TYPE_ELECTRICAL, 10, 0));
            effect eCL   = ExtraordinaryEffect(EffectIncreasedCasterLevel(1));
            ApplyEffectToObject(DURATION_TYPE_TEMPORARY, eFire, oPC, MRK_TRANSFORM_DUR);
            ApplyEffectToObject(DURATION_TYPE_TEMPORARY, eCold, oPC, MRK_TRANSFORM_DUR);
            ApplyEffectToObject(DURATION_TYPE_TEMPORARY, eElec, oPC, MRK_TRANSFORM_DUR);
            ApplyEffectToObject(DURATION_TYPE_TEMPORARY, eCL,   oPC, MRK_TRANSFORM_DUR);
            break;
        }
        case MRK_TYPE_INFERNAL:
        {
            effect eStr  = ExtraordinaryEffect(EffectAbilityIncrease(ABILITY_STRENGTH, 2));
            effect eDmg  = ExtraordinaryEffect(EffectDamageBonus(DAMAGE_BONUS_1d6, DAMAGE_TYPE_FIRE));
            effect eIntm = ExtraordinaryEffect(EffectSkillIncrease(SKILL_INTIMIDATE, 4));
            ApplyEffectToObject(DURATION_TYPE_TEMPORARY, eStr,  oPC, MRK_TRANSFORM_DUR);
            ApplyEffectToObject(DURATION_TYPE_TEMPORARY, eDmg,  oPC, MRK_TRANSFORM_DUR);
            ApplyEffectToObject(DURATION_TYPE_TEMPORARY, eIntm, oPC, MRK_TRANSFORM_DUR);
            break;
        }
        case MRK_TYPE_FEY:
        {
            effect eDex  = ExtraordinaryEffect(EffectAbilityIncrease(ABILITY_DEXTERITY, 4));
            effect eConc = ExtraordinaryEffect(EffectConcealment(20, MISS_CHANCE_TYPE_NORMAL));
            effect eSR   = ExtraordinaryEffect(EffectSpellResistanceIncrease(2));
            ApplyEffectToObject(DURATION_TYPE_TEMPORARY, eDex,  oPC, MRK_TRANSFORM_DUR);
            ApplyEffectToObject(DURATION_TYPE_TEMPORARY, eConc, oPC, MRK_TRANSFORM_DUR);
            ApplyEffectToObject(DURATION_TYPE_TEMPORARY, eSR,   oPC, MRK_TRANSFORM_DUR);
            break;
        }
    }

    ApplyEffectToObject(DURATION_TYPE_TEMPORARY, eVFX, oPC, MRK_TRANSFORM_DUR);
    ApplyEffectToObject(DURATION_TYPE_INSTANT,
        EffectVisualEffect(VFX_FNF_LOS_NORMAL_10), oPC);
}

void MrkEndTransformCallback(object oPC, int nType)
{
    if(GetLocalInt(oPC, MRK_LVAR_ACTIVE) != nType + 1) return;
    MrkEndTransform(oPC);
}

void MrkCooldownExpired(object oPC, int nType)
{
    SetLocalInt(oPC, MRK_LVAR_CD + IntToString(nType), 0);
    int nToken = NuiFindWindow(oPC, MRK_WINDOW);
    if(nToken != 0)
        MrkFeedWindow(oPC, nToken);
}

void MrkActivateTransform(object oPC, int nType)
{
    if(GetLocalInt(oPC, MRK_LVAR_ACTIVE) != 0)
    {
        SendMessageToPC(oPC, "[Piętna] Transformacja już aktywna.");
        return;
    }
    if(GetLocalInt(oPC, MRK_LVAR_CD + IntToString(nType)))
    {
        SendMessageToPC(oPC, "[Piętna] Ten aspekt jeszcze się odnawia.");
        return;
    }

    json jData = MrkEnsureData(oPC);
    int nEss   = MrkGetEssenceFromData(jData, nType);
    if(nEss < MRK_THRESHOLD)
    {
        SendMessageToPC(oPC, "[Piętna] Niewystarczająca esencja.");
        return;
    }

    int nTotal  = MrkGetTotalFromData(jData, nType);
    int nBrands = JsonGetInt(JsonObjectGet(jData, "brands"));

    // Spend essence
    int nNewEss = nEss - MRK_TRANSFORM_COST;
    if(nNewEss < 0) nNewEss = 0;
    MrkSaveEssence(oPC, nType, nNewEss, nTotal, nBrands);

    SetLocalInt(oPC, MRK_LVAR_ACTIVE, nType + 1);

    MrkApplyTransformEffects(oPC, nType);

    string sName = MrkTypeName(nType);
    SendMessageToPC(oPC, "[Piętna] Aspekt " + sName + " obudził się w tobie na " + IntToString(FloatToInt(MRK_TRANSFORM_DUR)) + " sekund.");
    FloatingTextStringOnCreature("Aspekt " + sName + " — aktywny!", oPC, FALSE);

    // Schedule end
    DelayCommand(MRK_TRANSFORM_DUR, MrkEndTransformCallback(oPC, nType));

    int nToken = NuiFindWindow(oPC, MRK_WINDOW);
    if(nToken != 0)
        MrkFeedWindow(oPC, nToken);
}

void MrkEndTransform(object oPC)
{
    int nActiveBit = GetLocalInt(oPC, MRK_LVAR_ACTIVE);
    if(nActiveBit == 0) return;

    int nType = nActiveBit - 1;
    SetLocalInt(oPC, MRK_LVAR_ACTIVE, 0);

    // Remove all extraordinary effects from the PC
    effect eEff = GetFirstEffect(oPC);
    while(GetIsEffectValid(eEff))
    {
        if(GetEffectSubType(eEff) == SUBTYPE_EXTRAORDINARY &&
           GetEffectDurationType(eEff) == DURATION_TYPE_TEMPORARY)
        {
            RemoveEffect(oPC, eEff);
        }
        eEff = GetNextEffect(oPC);
    }

    // Start cooldown
    SetLocalInt(oPC, MRK_LVAR_CD + IntToString(nType), 1);
    DelayCommand(MRK_COOLDOWN, MrkCooldownExpired(oPC, nType));

    string sName = MrkTypeName(nType);
    SendMessageToPC(oPC, "[Piętna] Aspekt " + sName + " wygasł. Odnowienie za " + IntToString(FloatToInt(MRK_COOLDOWN)) + " s.");

    int nToken = NuiFindWindow(oPC, MRK_WINDOW);
    if(nToken != 0)
        MrkFeedWindow(oPC, nToken);
}

// ----------------------------------------------------------------
// Brand (permanent mark) application
// ----------------------------------------------------------------

void MrkApplyBrand(object oPC, int nType)
{
    switch(nType)
    {
        case MRK_TYPE_BEAST:
            ApplyEffectToObject(DURATION_TYPE_PERMANENT,
                ExtraordinaryEffect(EffectAbilityIncrease(ABILITY_STRENGTH, 1)), oPC);
            break;
        case MRK_TYPE_UNDEAD:
            ApplyEffectToObject(DURATION_TYPE_PERMANENT,
                ExtraordinaryEffect(EffectAbilityIncrease(ABILITY_CONSTITUTION, 1)), oPC);
            break;
        case MRK_TYPE_ELEMENTAL:
            ApplyEffectToObject(DURATION_TYPE_PERMANENT,
                ExtraordinaryEffect(EffectDamageResistance(DAMAGE_TYPE_FIRE, 5, 0)), oPC);
            break;
        case MRK_TYPE_INFERNAL:
            ApplyEffectToObject(DURATION_TYPE_PERMANENT,
                ExtraordinaryEffect(EffectAbilityIncrease(ABILITY_CHARISMA, 1)), oPC);
            break;
        case MRK_TYPE_FEY:
            ApplyEffectToObject(DURATION_TYPE_PERMANENT,
                ExtraordinaryEffect(EffectAbilityIncrease(ABILITY_DEXTERITY, 1)), oPC);
            break;
    }
}

void MrkReapplyBrands(object oPC)
{
    json jData = MrkLoadData(oPC);
    if(JsonGetType(jData) == JSON_TYPE_NULL) return;

    int nBrands = JsonGetInt(JsonObjectGet(jData, "brands"));
    int i;
    for(i = 0; i < MRK_TYPE_COUNT; i++)
    {
        if(nBrands & (1 << i))
            MrkApplyBrand(oPC, i);
    }
}

// ----------------------------------------------------------------
// Essence harvesting on creature death
// ----------------------------------------------------------------

void MrkOnCreatureDeath(object oPC, object oVictim)
{
    if(!GetIsPC(oPC)) return;
    if(!GetIsObjectValid(oVictim)) return;
    if(GetIsPC(oVictim)) return;

    int nType = MrkGetEssenceType(oVictim);
    if(nType < 0) return;

    int nGain  = MrkEssenceFromKill(oVictim);
    json jData = MrkEnsureData(oPC);

    int nEss   = MrkGetEssenceFromData(jData, nType);
    int nTotal = MrkGetTotalFromData(jData, nType);
    int nBrands= JsonGetInt(JsonObjectGet(jData, "brands"));

    int nNewEss   = nEss + nGain;
    int nNewTotal = nTotal + nGain;

    // Cap essence at 3x threshold to prevent waste
    if(nNewEss > MRK_THRESHOLD * 3) nNewEss = MRK_THRESHOLD * 3;

    // Check if brand threshold crossed for the first time
    int bNewBrand = FALSE;
    if(!(nBrands & (1 << nType)) && nNewTotal >= MRK_BRAND_TOTAL)
    {
        nBrands = nBrands | (1 << nType);
        bNewBrand = TRUE;
        MrkSaveEssence(oPC, nType, nNewEss, nNewTotal, nBrands);
        MrkSaveBrands(oPC, nBrands);
        MrkApplyBrand(oPC, nType);
        string sFlavor = MrkBrandFlavor(nType);
        SendMessageToPC(oPC, "[Piętna] PIĘTNO TRWAŁE: " + sFlavor);
        FloatingTextStringOnCreature("Nowe Piętno: " + MrkTypeName(nType) + "!", oPC, FALSE);
        ApplyEffectToObject(DURATION_TYPE_INSTANT,
            EffectVisualEffect(VFX_FNF_SUMMON_UNDEAD), oPC);
    }
    else
    {
        MrkSaveEssence(oPC, nType, nNewEss, nNewTotal, nBrands);
    }

    // Notify only when crossing multiples of 25 (reduce spam)
    if((nEss / 25) != (nNewEss / 25) || nNewEss >= MRK_THRESHOLD)
    {
        string sMsg = "[Piętna] " + MrkTypeName(nType) + ": "
                    + IntToString(nNewEss) + "/" + IntToString(MRK_THRESHOLD) + " esencji";
        if(nNewEss >= MRK_THRESHOLD) sMsg = sMsg + " — GOTOWE do transformacji!";
        SendMessageToPC(oPC, sMsg);
    }

    // Refresh open window
    int nToken = NuiFindWindow(oPC, MRK_WINDOW);
    if(nToken != 0)
        MrkFeedWindow(oPC, nToken);
}
