#include "lib_scar_def"

const float SCAR_W = 640.0;
const float SCAR_H = 530.0;

// ── NUI construction ──────────────────────────────────────────────

json BuildScarListRow(object oPC)
{
    float fLocW = GetNuiScaleDimension(oPC, 115.0);
    float fTypW = GetNuiScaleDimension(oPC, 115.0);
    float fStaW = GetNuiScaleDimension(oPC, 90.0);
    float fEffW = GetNuiScaleDimension(oPC, 150.0);

    json jLoc = NuiLabel(NuiBind(SCAR_BIND_ROW_LOC), JsonInt(NUI_HALIGN_LEFT), JsonInt(NUI_VALIGN_MIDDLE));
    jLoc = NuiWidth(jLoc, fLocW);
    jLoc = NuiStyleForegroundColor(jLoc, NuiBind(SCAR_BIND_ROW_COLOR));

    json jTyp = NuiLabel(NuiBind(SCAR_BIND_ROW_TYPE), JsonInt(NUI_HALIGN_LEFT), JsonInt(NUI_VALIGN_MIDDLE));
    jTyp = NuiWidth(jTyp, fTypW);
    jTyp = NuiStyleForegroundColor(jTyp, NuiBind(SCAR_BIND_ROW_COLOR));

    json jSta = NuiLabel(NuiBind(SCAR_BIND_ROW_STATUS), JsonInt(NUI_HALIGN_CENTER), JsonInt(NUI_VALIGN_MIDDLE));
    jSta = NuiWidth(jSta, fStaW);
    jSta = NuiStyleForegroundColor(jSta, NuiBind(SCAR_BIND_ROW_COLOR));

    json jEff = NuiLabel(NuiBind(SCAR_BIND_ROW_EFF), JsonInt(NUI_HALIGN_LEFT), JsonInt(NUI_VALIGN_MIDDLE));
    jEff = NuiWidth(jEff, fEffW);
    jEff = NuiStyleForegroundColor(jEff, NuiBind(SCAR_BIND_ROW_COLOR));

    json jInner = JsonArray();
    jInner = JsonArrayInsert(jInner, jLoc);
    jInner = JsonArrayInsert(jInner, jTyp);
    jInner = JsonArrayInsert(jInner, jSta);
    jInner = JsonArrayInsert(jInner, jEff);

    json jCell = NuiGroup(NuiRow(jInner), TRUE, NUI_SCROLLBARS_NONE);
    jCell = NuiId(jCell, SCAR_BTN_ROW);
    jCell = NuiEncouraged(jCell, NuiBind(SCAR_BIND_ROW_ENC));
    return jCell;
}

json BuildScarWindow(object oPC)
{
    float fBtnH  = GetNuiScaleDimension(oPC, 30.0);
    float fRowH  = GetNuiScaleDimension(oPC, 28.0);
    float fListH = GetNuiScaleDimension(oPC, 200.0);
    float fFlvH  = GetNuiScaleDimension(oPC, 115.0);

    // Column header row (static labels, not bound)
    float fLocW = GetNuiScaleDimension(oPC, 115.0);
    float fTypW = GetNuiScaleDimension(oPC, 115.0);
    float fStaW = GetNuiScaleDimension(oPC, 90.0);

    json jHLoc = NuiWidth(NuiLabel(JsonString("Lokalizacja"), JsonInt(NUI_HALIGN_LEFT), JsonInt(NUI_VALIGN_MIDDLE)), fLocW);
    json jHTyp = NuiWidth(NuiLabel(JsonString("Rodzaj"),       JsonInt(NUI_HALIGN_LEFT), JsonInt(NUI_VALIGN_MIDDLE)), fTypW);
    json jHSta = NuiWidth(NuiLabel(JsonString("Stan"),         JsonInt(NUI_HALIGN_CENTER), JsonInt(NUI_VALIGN_MIDDLE)), fStaW);
    json jHEff = NuiLabel(JsonString("Efekt"), JsonInt(NUI_HALIGN_LEFT), JsonInt(NUI_VALIGN_MIDDLE));

    json jHdrRow = JsonArray();
    jHdrRow = JsonArrayInsert(jHdrRow, jHLoc);
    jHdrRow = JsonArrayInsert(jHdrRow, jHTyp);
    jHdrRow = JsonArrayInsert(jHdrRow, jHSta);
    jHdrRow = JsonArrayInsert(jHdrRow, jHEff);

    // List
    json jTmpl = JsonArrayInsert(JsonArray(), NuiListTemplateCell(BuildScarListRow(oPC), 0.0, TRUE));
    json jList = NuiList(jTmpl, NuiBind(SCAR_BIND_ROW_COUNT), fRowH);
    jList = NuiHeight(jList, fListH);

    // Detail panel
    json jDetHdr = NuiLabel(NuiBind(SCAR_BIND_DET_HEADER), JsonInt(NUI_HALIGN_LEFT), JsonInt(NUI_VALIGN_MIDDLE));
    jDetHdr = NuiHeight(jDetHdr, fBtnH);

    json jDetFlv = NuiGroup(NuiText(NuiBind(SCAR_BIND_DET_FLAVOR), FALSE), TRUE, NUI_SCROLLBARS_NONE);
    jDetFlv = NuiHeight(jDetFlv, fFlvH);

    // Treatment button
    json jTreatBtn = NuiButton(NuiBind(SCAR_BIND_TREAT_LBL));
    jTreatBtn = NuiId(jTreatBtn, SCAR_BTN_TREAT);
    jTreatBtn = NuiEnabled(jTreatBtn, NuiBind(SCAR_BIND_TREAT_ENA));
    jTreatBtn = NuiWidth(jTreatBtn, GetNuiScaleDimension(oPC, 240.0));
    jTreatBtn = NuiHeight(jTreatBtn, fBtnH);

    json jBotRow = JsonArray();
    jBotRow = JsonArrayInsert(jBotRow, NuiSpacer());
    jBotRow = JsonArrayInsert(jBotRow, jTreatBtn);

    // Close button in top-right corner
    json jClose = NuiButton(JsonString("X"));
    jClose = NuiId(jClose, SCAR_BTN_CLOSE);
    jClose = NuiWidth(jClose, GetNuiScaleDimension(oPC, 30.0));
    jClose = NuiHeight(jClose, fBtnH);

    json jTopBar = JsonArray();
    jTopBar = JsonArrayInsert(jTopBar, NuiSpacer());
    jTopBar = JsonArrayInsert(jTopBar, jClose);

    // Assemble column
    json jCol = JsonArray();
    jCol = JsonArrayInsert(jCol, NuiRow(jTopBar));
    jCol = JsonArrayInsert(jCol, NuiRow(jHdrRow));
    jCol = JsonArrayInsert(jCol, jList);
    jCol = JsonArrayInsert(jCol, CreateEmptyRow(oPC, 4.0));
    jCol = JsonArrayInsert(jCol, jDetHdr);
    jCol = JsonArrayInsert(jCol, jDetFlv);
    jCol = JsonArrayInsert(jCol, NuiRow(jBotRow));

    json jSide = NuiCol(JsonArrayInsert(JsonArray(), NuiSpacer()));
    float fCW  = GetNuiScaleDimension(oPC, SCAR_W - 40.0);

    json jMain = JsonArray();
    jMain = JsonArrayInsert(jMain, jSide);
    jMain = JsonArrayInsert(jMain, NuiWidth(NuiCol(jCol), fCW));
    jMain = JsonArrayInsert(jMain, jSide);
    return NuiRow(jMain);
}

// ── Window management ─────────────────────────────────────────────

void ScarOpenWindow(object oPC)
{
    int nToken = NuiFindWindow(oPC, SCAR_WINDOW);
    if(nToken != 0)
    {
        FeedScarList(oPC, nToken);
        return;
    }

    float fX = (IntToFloat(GetPlayerDeviceProperty(oPC, PLAYER_DEVICE_PROPERTY_GUI_WIDTH))
                - GetNuiScaleDimension(oPC, SCAR_W)) / 2.0;
    float fY = (IntToFloat(GetPlayerDeviceProperty(oPC, PLAYER_DEVICE_PROPERTY_GUI_HEIGHT))
                - GetNuiScaleDimension(oPC, SCAR_H)) / 2.0;
    json jGeom = NuiRect(fX, fY, GetNuiScaleDimension(oPC, SCAR_W), GetNuiScaleDimension(oPC, SCAR_H));

    json jWin = NuiWindow(BuildScarWindow(oPC),
        JsonString("Rany i Blizny"),
        NuiBind(SCAR_WIN_GEOM),
        JsonBool(FALSE),
        JsonBool(FALSE),
        JsonBool(TRUE),
        JsonBool(TRUE),
        JsonBool(FALSE));

    nToken = NuiCreate(oPC, jWin, SCAR_WINDOW, SCAR_EV_SCRIPT);
    NuiSetBind(oPC, nToken, SCAR_WIN_GEOM, jGeom);
    FeedScarList(oPC, nToken);
}

// ── Feed functions ────────────────────────────────────────────────

void FeedScarDetail(object oPC, int nToken, int nWoundId)
{
    json jWounds = ScarDbGetWounds(oPC);
    int  nCount  = JsonGetLength(jWounds);
    json jTarget = JsonNull();
    int  i;
    for(i = 0; i < nCount; i++)
    {
        json jRow = JsonArrayGet(jWounds, i);
        if(JsonGetInt(JsonObjectGet(jRow, "id")) == nWoundId)
        {
            jTarget = jRow;
            break;
        }
    }

    if(JsonGetType(jTarget) == JSON_TYPE_NULL)
    {
        SetLocalInt(oPC, SCAR_LVAR_SEL_ID, 0);
        return;
    }

    int    nType  = JsonGetInt(JsonObjectGet(jTarget, "wound_type"));
    int    nLoc   = JsonGetInt(JsonObjectGet(jTarget, "location"));
    int    nStat  = JsonGetInt(JsonObjectGet(jTarget, "status"));
    string sFlavor = (nStat == SCAR_STATUS_SCARRED)
                   ? ScarFlavorScar(nType, nLoc)
                   : ScarFlavorOpen(nType, nLoc);
    string sHeader = ScarLocName(nLoc) + " — " + ScarTypeName(nType) + " [" + ScarStatusName(nStat) + "]";

    int bCanTreat = (nStat == SCAR_STATUS_OPEN);
    string sTreatLbl;
    if(bCanTreat)
        sTreatLbl = "Lecz ranę (" + IntToString(SCAR_TREAT_COST) + " sz.)";
    else if(nStat == SCAR_STATUS_HEALING)
        sTreatLbl = "Gojenie w toku... (powróć za " + IntToString(SCAR_HEAL_HOURS) + "h)";
    else
        sTreatLbl = "Blizna — trwały ślad bitwy";

    NuiSetBind(oPC, nToken, SCAR_BIND_DET_HEADER, JsonString(sHeader));
    NuiSetBind(oPC, nToken, SCAR_BIND_DET_FLAVOR, JsonString(sFlavor));
    NuiSetBind(oPC, nToken, SCAR_BIND_TREAT_ENA,  JsonBool(bCanTreat));
    NuiSetBind(oPC, nToken, SCAR_BIND_TREAT_LBL,  JsonString(sTreatLbl));
}

void FeedScarList(object oPC, int nToken)
{
    ScarRefreshHealed(oPC);

    json jWounds = ScarDbGetWounds(oPC);
    int  nCount  = JsonGetLength(jWounds);
    int  nSelId  = GetLocalInt(oPC, SCAR_LVAR_SEL_ID);

    json jLocs    = JsonArray();
    json jTypes   = JsonArray();
    json jStats   = JsonArray();
    json jEffects = JsonArray();
    json jColors  = JsonArray();
    json jEncs    = JsonArray();

    json jColOpen  = NuiColor(220, 70, 70);
    json jColHeal  = NuiColor(220, 200, 60);
    json jColScar  = NuiColor(150, 150, 150);

    int i;
    for(i = 0; i < nCount; i++)
    {
        json jRow  = JsonArrayGet(jWounds, i);
        int  nId   = JsonGetInt(JsonObjectGet(jRow, "id"));
        int  nType = JsonGetInt(JsonObjectGet(jRow, "wound_type"));
        int  nLoc  = JsonGetInt(JsonObjectGet(jRow, "location"));
        int  nStat = JsonGetInt(JsonObjectGet(jRow, "status"));

        json jColor;
        switch(nStat)
        {
            case SCAR_STATUS_OPEN:    jColor = jColOpen;  break;
            case SCAR_STATUS_HEALING: jColor = jColHeal;  break;
            default:                  jColor = jColScar;  break;
        }

        jLocs    = JsonArrayInsert(jLocs,    JsonString(ScarLocName(nLoc)));
        jTypes   = JsonArrayInsert(jTypes,   JsonString(ScarTypeName(nType)));
        jStats   = JsonArrayInsert(jStats,   JsonString(ScarStatusName(nStat)));
        jEffects = JsonArrayInsert(jEffects, JsonString(ScarEffectLabel(nType, nStat)));
        jColors  = JsonArrayInsert(jColors,  jColor);
        jEncs    = JsonArrayInsert(jEncs,    JsonBool(nSelId > 0 && nId == nSelId));
    }

    NuiSetBind(oPC, nToken, SCAR_BIND_ROW_LOC,    jLocs);
    NuiSetBind(oPC, nToken, SCAR_BIND_ROW_TYPE,   jTypes);
    NuiSetBind(oPC, nToken, SCAR_BIND_ROW_STATUS, jStats);
    NuiSetBind(oPC, nToken, SCAR_BIND_ROW_EFF,    jEffects);
    NuiSetBind(oPC, nToken, SCAR_BIND_ROW_COLOR,  jColors);
    NuiSetBind(oPC, nToken, SCAR_BIND_ROW_ENC,    jEncs);
    NuiSetBind(oPC, nToken, SCAR_BIND_ROW_COUNT,  JsonInt(nCount));

    if(nSelId > 0)
        FeedScarDetail(oPC, nToken, nSelId);
    else
    {
        NuiSetBind(oPC, nToken, SCAR_BIND_DET_HEADER, JsonString("Kliknij ranę, aby zobaczyć szczegóły."));
        NuiSetBind(oPC, nToken, SCAR_BIND_DET_FLAVOR, JsonString(""));
        NuiSetBind(oPC, nToken, SCAR_BIND_TREAT_ENA,  JsonBool(FALSE));
        NuiSetBind(oPC, nToken, SCAR_BIND_TREAT_LBL,  JsonString("Lecz ranę"));
    }
}

// ── Effect management ─────────────────────────────────────────────

void ScarRemoveEffects(object oPC)
{
    effect eEff = GetFirstEffect(oPC);
    while(GetIsEffectValid(eEff))
    {
        if(GetEffectTag(eEff) == SCAR_EFFECT_TAG)
            RemoveEffect(oPC, eEff);
        eEff = GetNextEffect(oPC);
    }
}

void ScarApplyEffects(object oPC)
{
    ScarRemoveEffects(oPC);

    json jWounds = ScarDbGetWounds(oPC);
    int  nCount  = JsonGetLength(jWounds);
    int  i;
    for(i = 0; i < nCount; i++)
    {
        json jRow  = JsonArrayGet(jWounds, i);
        int  nType = JsonGetInt(JsonObjectGet(jRow, "wound_type"));
        int  nStat = JsonGetInt(JsonObjectGet(jRow, "status"));

        effect eEff;
        int bValid = TRUE;

        if(nStat == SCAR_STATUS_OPEN)
        {
            switch(nType)
            {
                case SCAR_TYPE_CUT:    eEff = EffectAbilityDecrease(ABILITY_DEXTERITY,    1); break;
                case SCAR_TYPE_BURN:   eEff = EffectAbilityDecrease(ABILITY_CHARISMA,     1); break;
                case SCAR_TYPE_PIERCE: eEff = EffectAbilityDecrease(ABILITY_CONSTITUTION, 1); break;
                case SCAR_TYPE_BREAK:  eEff = EffectAbilityDecrease(ABILITY_STRENGTH,     1); break;
                case SCAR_TYPE_NERVE:  eEff = EffectAbilityDecrease(ABILITY_INTELLIGENCE, 1); break;
                default: bValid = FALSE; break;
            }
        }
        else if(nStat == SCAR_STATUS_SCARRED)
        {
            switch(nType)
            {
                case SCAR_TYPE_CUT:
                    eEff = EffectSkillIncrease(SKILL_INTIMIDATE, 1);
                    break;
                case SCAR_TYPE_BURN:
                    eEff = EffectDamageResistance(DAMAGE_TYPE_FIRE, 5, 0);
                    break;
                case SCAR_TYPE_PIERCE:
                    eEff = EffectSavingThrowIncrease(SAVING_THROW_FORT, 1, SAVING_THROW_TYPE_ALL);
                    break;
                case SCAR_TYPE_BREAK:
                    eEff = EffectSavingThrowIncrease(SAVING_THROW_FORT, 1, SAVING_THROW_TYPE_ALL);
                    break;
                case SCAR_TYPE_NERVE:
                    // Chronic pain from nerve damage: slower thought, heightened hearing
                    eEff = EffectLinkEffects(
                        EffectSkillDecrease(SKILL_CONCENTRATION, 1),
                        EffectSkillIncrease(SKILL_LISTEN, 1));
                    break;
                default: bValid = FALSE; break;
            }
        }
        else
        {
            bValid = FALSE; // HEALING status: no active effect
        }

        if(bValid)
        {
            eEff = TagEffect(eEff, SCAR_EFFECT_TAG);
            ApplyEffectToObject(DURATION_TYPE_PERMANENT, eEff, oPC);
        }
    }
}

// ── Wound lifecycle ───────────────────────────────────────────────

void ScarRefreshHealed(object oPC)
{
    ScarDbFinalizeHealed(oPC, SCAR_HEAL_HOURS * 3600);
}

void ScarGainWound(object oPC)
{
    if(ScarDbCountAll(oPC) >= SCAR_MAX_WOUNDS) return;

    int nType = Random(5);
    int nLoc  = Random(6);

    ScarDbAddWound(oPC, nType, nLoc);
    ScarApplyEffects(oPC);

    string sMsg = "[Rana] Doznałeś poważnych obrażeń: "
                + ScarTypeName(nType) + " — " + ScarLocName(nLoc) + ". "
                + "Znajdź chirurga i lecz ranę, zanim się pogorszy.";
    SendMessageToPC(oPC, sMsg);
    FloatingTextStringOnCreature(
        "Nowa rana: " + ScarTypeName(nType) + " (" + ScarLocName(nLoc) + ")!",
        oPC, FALSE);
}

void ScarTreatWound(object oPC, int nWoundId, int nToken)
{
    if(GetGold(oPC) < SCAR_TREAT_COST)
    {
        SendMessageToPC(oPC, "[Rana] Brak złota. Opatrunek kosztuje "
            + IntToString(SCAR_TREAT_COST) + " sz.");
        return;
    }

    // Confirm wound belongs to this PC and is open (guard against stale UI state)
    json jWounds = ScarDbGetWounds(oPC);
    int  nCount  = JsonGetLength(jWounds);
    int  bFound  = FALSE;
    int  i;
    for(i = 0; i < nCount; i++)
    {
        json jRow  = JsonArrayGet(jWounds, i);
        if(JsonGetInt(JsonObjectGet(jRow, "id"))     == nWoundId &&
           JsonGetInt(JsonObjectGet(jRow, "status")) == SCAR_STATUS_OPEN)
        {
            bFound = TRUE;
            break;
        }
    }

    if(!bFound)
    {
        SendMessageToPC(oPC, "[Rana] Nie można leczyć tej rany.");
        return;
    }

    AssignCommand(oPC, TakeGoldFromCreature(SCAR_TREAT_COST, oPC, TRUE));
    ScarDbTreatWound(nWoundId);
    ScarApplyEffects(oPC);

    // Clear selection so the list refreshes cleanly
    SetLocalInt(oPC, SCAR_LVAR_SEL_ID, 0);
    FeedScarList(oPC, nToken);

    SendMessageToPC(oPC, "[Rana] Rana została opatrzona. Za "
        + IntToString(SCAR_HEAL_HOURS) + " godzin przemieni się w bliznę.");
}
