#include "lib_ln_def"

// ------------------------------------------------------------------
// Text helpers
// ------------------------------------------------------------------

string LnGetTypeName(int nType)
{
    if(nType == LN_TYPE_ARCANE)  return "Arkaniczny";
    if(nType == LN_TYPE_MARTIAL) return "Wojenny";
    if(nType == LN_TYPE_VITAL)   return "Witalny";
    if(nType == LN_TYPE_SHADOW)  return "Cieniowy";
    return "Nieznany";
}

string LnGetTypeGlyph(int nType)
{
    if(nType == LN_TYPE_ARCANE)  return "[A]";
    if(nType == LN_TYPE_MARTIAL) return "[W]";
    if(nType == LN_TYPE_VITAL)   return "[V]";
    if(nType == LN_TYPE_SHADOW)  return "[C]";
    return "[?]";
}

string LnGetBoostDesc(int nType)
{
    if(nType == LN_TYPE_ARCANE)  return "+2 do rzutów obronnych vs czary (10 min)";
    if(nType == LN_TYPE_MARTIAL) return "+2 do rzutów trafienia (10 min)";
    if(nType == LN_TYPE_VITAL)   return "Regeneracja 1 PŻ / 10 s (10 min)";
    if(nType == LN_TYPE_SHADOW)  return "+4 do Ukrywania i Cichego Chodu (10 min)";
    return "";
}

// ------------------------------------------------------------------
// Mechanics
// ------------------------------------------------------------------

// Returns TRUE if oPC is within LN_ATTUNE_RANGE of the named node placeable.
int LnCheckProximity(object oPC, string sTag)
{
    object oNode = GetObjectByTag(sTag);
    if(!GetIsObjectValid(oNode)) return FALSE;
    return GetDistanceBetween(oPC, oNode) <= LN_ATTUNE_RANGE;
}

// Reads LN_TYPE local int from placeable and upserts a row in ln_nodes.
// Safe to call repeatedly (INSERT OR IGNORE).
void LnEnsureNodeRegistered(object oNode)
{
    if(!GetIsObjectValid(oNode)) return;
    string sTag  = GetTag(oNode);
    string sName = GetName(oNode);
    int    nType = GetLocalInt(oNode, "LN_TYPE");
    if(nType < 1 || nType > 4) nType = LN_TYPE_ARCANE;
    LnRegisterNode(sTag, sName, nType);
}

// Applies a timed boost effect and schedules cleanup of the local var.
void LnApplyBoost(object oPC, int nType)
{
    float fDur = IntToFloat(LN_BOOST_DURATION);
    effect eBoost;
    int    nVFX;

    if(nType == LN_TYPE_ARCANE)
    {
        eBoost = EffectSavingThrowIncrease(SAVING_THROW_ALL, 2, SAVING_THROW_TYPE_SPELL);
        nVFX   = VFX_IMP_PULSE_ELECTRICITY;
    }
    else if(nType == LN_TYPE_MARTIAL)
    {
        eBoost = EffectAttackIncrease(2, ATTACK_BONUS_MISC);
        nVFX   = VFX_IMP_PULSE_RED;
    }
    else if(nType == LN_TYPE_VITAL)
    {
        eBoost = EffectRegenerate(1, 10.0);
        nVFX   = VFX_IMP_PULSE_GREEN;
    }
    else if(nType == LN_TYPE_SHADOW)
    {
        effect eH = EffectSkillIncrease(SKILL_HIDE, 4);
        effect eM = EffectSkillIncrease(SKILL_MOVE_SILENTLY, 4);
        eBoost    = EffectLinkEffects(eH, eM);
        nVFX      = VFX_IMP_PULSE_NEGATIVE;
    }
    else return;

    eBoost = SupernaturalEffect(eBoost);
    ApplyEffectToObject(DURATION_TYPE_TEMPORARY, eBoost, oPC, fDur);
    ApplyEffectToObject(DURATION_TYPE_INSTANT,   EffectVisualEffect(nVFX), oPC);

    SetLocalInt(oPC, LN_LVAR_BOOST_TYPE, nType);
    // Clear the local flag when the effect expires so the UI reflects the truth.
    DelayCommand(fDur, DeleteLocalInt(oPC, LN_LVAR_BOOST_TYPE));
}

// ------------------------------------------------------------------
// NUI — list column (left pane)
// ------------------------------------------------------------------

json LnBuildListPane(object oPC)
{
    float fRowH  = GetNuiScaleDimension(oPC, 30.0);
    float fListH = GetNuiScaleDimension(oPC, LN_H - 80.0);
    float fListW = GetNuiScaleDimension(oPC, LN_LIST_W);

    json jGlyph = NuiLabel(NuiBind(LN_BIND_ROW_TYPE), JsonInt(NUI_HALIGN_CENTER), JsonInt(NUI_VALIGN_MIDDLE));
    jGlyph = NuiWidth(jGlyph, GetNuiScaleDimension(oPC, 38.0));
    jGlyph = NuiStyleForegroundColor(jGlyph, NuiBind(LN_BIND_ROW_COLOR));

    json jName = NuiLabel(NuiBind(LN_BIND_ROW_NAME), JsonInt(NUI_HALIGN_LEFT), JsonInt(NUI_VALIGN_MIDDLE));
    jName = NuiStyleForegroundColor(jName, NuiBind(LN_BIND_ROW_COLOR));

    json jCharge = NuiLabel(NuiBind(LN_BIND_ROW_CHARGE), JsonInt(NUI_HALIGN_RIGHT), JsonInt(NUI_VALIGN_MIDDLE));
    jCharge = NuiWidth(jCharge, GetNuiScaleDimension(oPC, 44.0));
    jCharge = NuiStyleForegroundColor(jCharge, NuiBind(LN_BIND_ROW_COLOR));

    json jCellRow = JsonArray();
    jCellRow = JsonArrayInsert(jCellRow, jGlyph);
    jCellRow = JsonArrayInsert(jCellRow, jName);
    jCellRow = JsonArrayInsert(jCellRow, jCharge);

    json jCell = NuiGroup(NuiRow(jCellRow), TRUE, NUI_SCROLLBARS_NONE);
    jCell = NuiId(jCell, LN_BTN_ROW);
    jCell = NuiEncouraged(jCell, NuiBind(LN_BIND_ROW_ENC));
    jCell = NuiHeight(jCell, fRowH);

    json jTmpl = JsonArrayInsert(JsonArray(), NuiListTemplateCell(jCell, 0.0, TRUE));
    json jList = NuiList(jTmpl, NuiBind(LN_BIND_ROW_COUNT), fRowH);
    jList = NuiHeight(jList, fListH);

    json jHeader = NuiLabel(JsonString("Twoje Węzły"), JsonInt(NUI_HALIGN_CENTER), JsonInt(NUI_VALIGN_MIDDLE));
    jHeader = NuiHeight(jHeader, GetNuiScaleDimension(oPC, 26.0));

    json jCol = JsonArray();
    jCol = JsonArrayInsert(jCol, jHeader);
    jCol = JsonArrayInsert(jCol, jList);
    return NuiWidth(NuiCol(jCol), fListW);
}

// ------------------------------------------------------------------
// NUI — detail pane (right side)
// ------------------------------------------------------------------

json LnBuildDetailPane(object oPC)
{
    float fBtnH = GetNuiScaleDimension(oPC, 30.0);
    float fLblH = GetNuiScaleDimension(oPC, 24.0);

    json jNameLbl = NuiLabel(NuiBind(LN_BIND_DET_NAME), JsonInt(NUI_HALIGN_CENTER), JsonInt(NUI_VALIGN_MIDDLE));
    jNameLbl = NuiHeight(jNameLbl, GetNuiScaleDimension(oPC, 32.0));

    json jTypeLbl = NuiLabel(NuiBind(LN_BIND_DET_TYPE), JsonInt(NUI_HALIGN_CENTER), JsonInt(NUI_VALIGN_MIDDLE));
    jTypeLbl = NuiHeight(jTypeLbl, fLblH);

    json jPBar = NuiProgressBar(NuiBind(LN_BIND_DET_PBAR));
    jPBar = NuiHeight(jPBar, GetNuiScaleDimension(oPC, 16.0));
    jPBar = NuiTooltip(jPBar, NuiBind(LN_BIND_DET_CHARGE));

    json jChargeLbl = NuiLabel(NuiBind(LN_BIND_DET_CHARGE), JsonInt(NUI_HALIGN_CENTER), JsonInt(NUI_VALIGN_MIDDLE));
    jChargeLbl = NuiHeight(jChargeLbl, fLblH);

    json jStatusLbl = NuiLabel(NuiBind(LN_BIND_DET_STATUS), JsonInt(NUI_HALIGN_CENTER), JsonInt(NUI_VALIGN_MIDDLE));
    jStatusLbl = NuiHeight(jStatusLbl, fLblH);

    json jSiphonBtn = NuiButton(JsonString("Sycyfon Mocy"));
    jSiphonBtn = NuiId(jSiphonBtn, LN_BTN_SIPHON);
    jSiphonBtn = NuiEnabled(jSiphonBtn, NuiBind(LN_BIND_SIPHON_ENA));
    jSiphonBtn = NuiHeight(jSiphonBtn, fBtnH);
    jSiphonBtn = NuiTooltip(jSiphonBtn, JsonString("Wchłoń energię węzła (wymaga bliskości, koszt " + IntToString(LN_DRAW_COST) + " ładunku)"));

    json jReleaseBtn = NuiButton(JsonString("Uwolnij Więź"));
    jReleaseBtn = NuiId(jReleaseBtn, LN_BTN_RELEASE);
    jReleaseBtn = NuiEnabled(jReleaseBtn, NuiBind(LN_BIND_RELEASE_ENA));
    jReleaseBtn = NuiHeight(jReleaseBtn, fBtnH);
    jReleaseBtn = NuiTooltip(jReleaseBtn, JsonString("Zerwij połączenie z tym węzłem (trwałe)"));

    json jAttuneBtn = NuiButton(JsonString("Nastroić (" + IntToString(LN_ATTUNE_COST) + " zł)"));
    jAttuneBtn = NuiId(jAttuneBtn, LN_BTN_ATTUNE);
    jAttuneBtn = NuiEnabled(jAttuneBtn, NuiBind(LN_BIND_ATTUNE_ENA));
    jAttuneBtn = NuiVisible(jAttuneBtn, NuiBind(LN_BIND_ATTUNE_VIS));
    jAttuneBtn = NuiHeight(jAttuneBtn, fBtnH);
    jAttuneBtn = NuiTooltip(jAttuneBtn, JsonString("Nastrojenie trwa wiecznie; kosztuje " + IntToString(LN_ATTUNE_COST) + " złotych i wymaga bliskości"));

    json jActionRow = JsonArray();
    jActionRow = JsonArrayInsert(jActionRow, jSiphonBtn);
    jActionRow = JsonArrayInsert(jActionRow, jReleaseBtn);

    json jCol = JsonArray();
    jCol = JsonArrayInsert(jCol, NuiRow(JsonArrayInsert(JsonArray(), jNameLbl)));
    jCol = JsonArrayInsert(jCol, NuiRow(JsonArrayInsert(JsonArray(), jTypeLbl)));
    jCol = JsonArrayInsert(jCol, CreateEmptyRow(oPC, 6.0));
    jCol = JsonArrayInsert(jCol, NuiRow(JsonArrayInsert(JsonArray(), jPBar)));
    jCol = JsonArrayInsert(jCol, NuiRow(JsonArrayInsert(JsonArray(), jChargeLbl)));
    jCol = JsonArrayInsert(jCol, CreateEmptyRow(oPC, 8.0));
    jCol = JsonArrayInsert(jCol, NuiRow(JsonArrayInsert(JsonArray(), jStatusLbl)));
    jCol = JsonArrayInsert(jCol, CreateEmptyRow(oPC, 16.0));
    jCol = JsonArrayInsert(jCol, NuiRow(jActionRow));
    jCol = JsonArrayInsert(jCol, CreateEmptyRow(oPC, 8.0));
    jCol = JsonArrayInsert(jCol, NuiRow(JsonArrayInsert(JsonArray(), jAttuneBtn)));
    return NuiCol(jCol);
}

// ------------------------------------------------------------------
// NUI — window creation
// ------------------------------------------------------------------

void LnOpenPanel(object oPC)
{
    int nToken = NuiFindWindow(oPC, LN_WINDOW);
    if(nToken != 0)
    {
        LnFeedList(oPC, nToken);
        LnFeedDetail(oPC, nToken, GetLocalString(oPC, LN_LVAR_SEL_TAG));
        return;
    }

    float fCX = (IntToFloat(GetPlayerDeviceProperty(oPC, PLAYER_DEVICE_PROPERTY_GUI_WIDTH))  - GetNuiScaleDimension(oPC, LN_W)) / 2.0;
    float fCY = (IntToFloat(GetPlayerDeviceProperty(oPC, PLAYER_DEVICE_PROPERTY_GUI_HEIGHT)) - GetNuiScaleDimension(oPC, LN_H)) / 2.0;
    json  jGeom = NuiRect(fCX, fCY, GetNuiScaleDimension(oPC, LN_W), GetNuiScaleDimension(oPC, LN_H));

    float fBtnH = GetNuiScaleDimension(oPC, 28.0);
    json jCloseBtn = NuiButton(JsonString("X"));
    jCloseBtn = NuiId(jCloseBtn, LN_BTN_CLOSE);
    jCloseBtn = NuiWidth(jCloseBtn, fBtnH);
    jCloseBtn = NuiHeight(jCloseBtn, fBtnH);

    json jTitleRow = JsonArray();
    jTitleRow = JsonArrayInsert(jTitleRow, NuiLabel(JsonString("Sieć Węzłów Mocy"), JsonInt(NUI_HALIGN_LEFT), JsonInt(NUI_VALIGN_MIDDLE)));
    jTitleRow = JsonArrayInsert(jTitleRow, jCloseBtn);

    json jMainRow = JsonArray();
    jMainRow = JsonArrayInsert(jMainRow, LnBuildListPane(oPC));
    jMainRow = JsonArrayInsert(jMainRow, NuiWidth(NuiSpacer(), GetNuiScaleDimension(oPC, 10.0)));
    jMainRow = JsonArrayInsert(jMainRow, LnBuildDetailPane(oPC));

    json jRoot = JsonArray();
    jRoot = JsonArrayInsert(jRoot, NuiRow(jTitleRow));
    jRoot = JsonArrayInsert(jRoot, CreateEmptyRow(oPC, 4.0));
    jRoot = JsonArrayInsert(jRoot, NuiRow(jMainRow));

    json jWin = NuiWindow(NuiCol(jRoot),
        JsonBool(FALSE),
        NuiBind(LN_WIN_GEOM),
        JsonBool(FALSE),
        JsonBool(FALSE),
        JsonBool(FALSE),
        JsonBool(TRUE),
        JsonBool(FALSE));

    nToken = NuiCreate(oPC, jWin, LN_WINDOW, LN_EV_SCRIPT);
    NuiSetBind(oPC, nToken, LN_WIN_GEOM, jGeom);

    LnFeedList(oPC, nToken);
    LnFeedDetail(oPC, nToken, GetLocalString(oPC, LN_LVAR_SEL_TAG));
}

// ------------------------------------------------------------------
// Feed — populate list pane
// ------------------------------------------------------------------

void LnFeedList(object oPC, int nToken)
{
    json jRows   = LnGetAttunements(oPC);
    int  nCount  = JsonGetLength(jRows);
    string sSelTag = GetLocalString(oPC, LN_LVAR_SEL_TAG);

    json jNames   = JsonArray();
    json jTypes   = JsonArray();
    json jCharges = JsonArray();
    json jColors  = JsonArray();
    json jEncs    = JsonArray();
    json jWhite   = NuiColor(255, 255, 255);

    int i;
    for(i = 0; i < nCount; i++)
    {
        json jRow    = JsonArrayGet(jRows, i);
        string sTag  = JsonGetString(JsonObjectGet(jRow, "tag"));
        string sName = JsonGetString(JsonObjectGet(jRow, "name"));
        int    nType = JsonGetInt   (JsonObjectGet(jRow, "type"));
        int    nCharge = LnGetUpdatedCharge(sTag, LN_CHARGE_REGEN, LN_CHARGE_MAX);

        jNames   = JsonArrayInsert(jNames,   JsonString(sName));
        jTypes   = JsonArrayInsert(jTypes,   JsonString(LnGetTypeGlyph(nType)));
        jCharges = JsonArrayInsert(jCharges, JsonString(IntToString(nCharge)));
        jColors  = JsonArrayInsert(jColors,  jWhite);
        jEncs    = JsonArrayInsert(jEncs,    JsonBool(sTag == sSelTag));
    }

    NuiSetBind(oPC, nToken, LN_BIND_ROW_NAME,   jNames);
    NuiSetBind(oPC, nToken, LN_BIND_ROW_TYPE,   jTypes);
    NuiSetBind(oPC, nToken, LN_BIND_ROW_CHARGE, jCharges);
    NuiSetBind(oPC, nToken, LN_BIND_ROW_COLOR,  jColors);
    NuiSetBind(oPC, nToken, LN_BIND_ROW_ENC,    jEncs);
    NuiSetBind(oPC, nToken, LN_BIND_ROW_COUNT,  JsonInt(nCount));
}

// ------------------------------------------------------------------
// Feed — populate detail pane for a single node tag
// ------------------------------------------------------------------

void LnFeedDetail(object oPC, int nToken, string sTag)
{
    if(sTag == "")
    {
        NuiSetBind(oPC, nToken, LN_BIND_DET_NAME,    JsonString("— wybierz węzeł —"));
        NuiSetBind(oPC, nToken, LN_BIND_DET_TYPE,    JsonString(""));
        NuiSetBind(oPC, nToken, LN_BIND_DET_CHARGE,  JsonString(""));
        NuiSetBind(oPC, nToken, LN_BIND_DET_PBAR,    JsonFloat(0.0));
        NuiSetBind(oPC, nToken, LN_BIND_DET_STATUS,  JsonString("Użyj placeable węzła, by go zidentyfikować."));
        NuiSetBind(oPC, nToken, LN_BIND_SIPHON_ENA,  JsonBool(FALSE));
        NuiSetBind(oPC, nToken, LN_BIND_RELEASE_ENA, JsonBool(FALSE));
        NuiSetBind(oPC, nToken, LN_BIND_ATTUNE_ENA,  JsonBool(FALSE));
        NuiSetBind(oPC, nToken, LN_BIND_ATTUNE_VIS,  JsonBool(FALSE));
        return;
    }

    string sName    = LnGetNodeName(sTag);
    int    nType    = LnGetNodeType(sTag);
    int    nCharge  = LnGetUpdatedCharge(sTag, LN_CHARGE_REGEN, LN_CHARGE_MAX);
    int    bAttuned = LnIsAttuned(oPC, sTag);
    int    bNear    = LnCheckProximity(oPC, sTag);
    int    nBoost   = GetLocalInt(oPC, LN_LVAR_BOOST_TYPE);
    int    bBoosted = (nBoost != 0);

    string sStatus;
    if(bBoosted)
        sStatus = "Aktywna moc: " + LnGetTypeName(nBoost) + " — odczekaj, aż wygaśnie.";
    else if(!bAttuned && !bNear)
        sStatus = "Zbliż się, by nastroić.";
    else if(!bAttuned && bNear)
        sStatus = "Jesteś przy węźle. Możesz się nastroić.";
    else if(bAttuned && !bNear)
        sStatus = "Zbliż się do węzła, by sycyfonować.";
    else if(bAttuned && bNear && nCharge < LN_DRAW_COST)
        sStatus = "Węzeł się ładuje... (" + IntToString(nCharge) + "/" + IntToString(LN_DRAW_COST) + ")";
    else if(bAttuned && bNear)
        sStatus = "Gotowy do sycyfonowania.";

    float fPbar = IntToFloat(nCharge) / IntToFloat(LN_CHARGE_MAX);

    NuiSetBind(oPC, nToken, LN_BIND_DET_NAME,    JsonString(sName));
    NuiSetBind(oPC, nToken, LN_BIND_DET_TYPE,    JsonString(LnGetTypeName(nType) + " — " + LnGetBoostDesc(nType)));
    NuiSetBind(oPC, nToken, LN_BIND_DET_CHARGE,  JsonString("Ładunek: " + IntToString(nCharge) + " / " + IntToString(LN_CHARGE_MAX)));
    NuiSetBind(oPC, nToken, LN_BIND_DET_PBAR,    JsonFloat(fPbar));
    NuiSetBind(oPC, nToken, LN_BIND_DET_STATUS,  JsonString(sStatus));
    NuiSetBind(oPC, nToken, LN_BIND_SIPHON_ENA,
        JsonBool(bAttuned && bNear && nCharge >= LN_DRAW_COST && !bBoosted));
    NuiSetBind(oPC, nToken, LN_BIND_RELEASE_ENA, JsonBool(bAttuned));
    NuiSetBind(oPC, nToken, LN_BIND_ATTUNE_ENA,
        JsonBool(!bAttuned && bNear
                 && GetGold(oPC) >= LN_ATTUNE_COST
                 && LnGetAttunementCount(oPC) < LN_MAX_ATTUNEMENTS));
    NuiSetBind(oPC, nToken, LN_BIND_ATTUNE_VIS,  JsonBool(!bAttuned));
}

// ------------------------------------------------------------------
// Actions — called from lib_ln_ev.nss
// ------------------------------------------------------------------

void LnSiphonPower(object oPC, int nToken)
{
    string sTag = GetLocalString(oPC, LN_LVAR_SEL_TAG);
    if(sTag == "")
    {
        SendMessageToPC(oPC, "[Węzły] Nie wybrano węzła.");
        return;
    }
    if(!LnIsAttuned(oPC, sTag))
    {
        SendMessageToPC(oPC, "[Węzły] Nie jesteś nastrojony do tego węzła. Nastrojenie wymagane.");
        return;
    }
    if(!LnCheckProximity(oPC, sTag))
    {
        SendMessageToPC(oPC, "[Węzły] Zbliż się do węzła, by wchłonąć jego moc.");
        return;
    }
    int nCharge = LnGetUpdatedCharge(sTag, LN_CHARGE_REGEN, LN_CHARGE_MAX);
    if(nCharge < LN_DRAW_COST)
    {
        SendMessageToPC(oPC, "[Węzły] Węzeł jest zbyt słaby (" + IntToString(nCharge) + "/" + IntToString(LN_DRAW_COST) + "). Poczekaj na regenerację.");
        return;
    }
    if(GetLocalInt(oPC, LN_LVAR_BOOST_TYPE) != 0)
    {
        SendMessageToPC(oPC, "[Węzły] Masz już aktywną moc węzła. Poczekaj, aż wygaśnie.");
        return;
    }

    int nType = LnGetNodeType(sTag);
    LnDrainCharge(sTag, LN_DRAW_COST);
    LnApplyBoost(oPC, nType);

    string sMsg = "Energia węzła przepływa przez ciebie... " + LnGetBoostDesc(nType) + ".";
    FloatingTextStringOnCreature(sMsg, oPC, FALSE);
    SendMessageToPC(oPC, "[Węzły] " + sMsg);

    LnFeedList(oPC, nToken);
    LnFeedDetail(oPC, nToken, sTag);
}

void LnAttuneSelected(object oPC, int nToken)
{
    string sTag = GetLocalString(oPC, LN_LVAR_SEL_TAG);
    if(sTag == "")
    {
        SendMessageToPC(oPC, "[Węzły] Najpierw użyj placeable węzła, by go zidentyfikować.");
        return;
    }
    if(LnIsAttuned(oPC, sTag))
    {
        SendMessageToPC(oPC, "[Węzły] Jesteś już nastrojony do tego węzła.");
        return;
    }
    if(LnGetAttunementCount(oPC) >= LN_MAX_ATTUNEMENTS)
    {
        SendMessageToPC(oPC, "[Węzły] Możesz być nastrojony do maksymalnie " + IntToString(LN_MAX_ATTUNEMENTS) + " węzłów. Uwolnij jeden, by dodać nowy.");
        return;
    }
    if(!LnCheckProximity(oPC, sTag))
    {
        SendMessageToPC(oPC, "[Węzły] Zbliż się do węzła, by przeprowadzić rytuał nastrojenia.");
        return;
    }
    if(GetGold(oPC) < LN_ATTUNE_COST)
    {
        SendMessageToPC(oPC, "[Węzły] Potrzebujesz " + IntToString(LN_ATTUNE_COST) + " złotych na rytuał nastrojenia.");
        return;
    }

    AssignCommand(oPC, TakeGoldFromCreature(LN_ATTUNE_COST, oPC, TRUE));
    LnAddAttunement(oPC, sTag);

    string sNodeName = LnGetNodeName(sTag);
    string sMsg = "Pieczęć żyłki wiąże się z twoją duszą — węzeł \"" + sNodeName + "\" jest teraz twój.";
    FloatingTextStringOnCreature(sMsg, oPC, FALSE);
    SendMessageToPC(oPC, "[Węzły] " + sMsg);

    LnFeedList(oPC, nToken);
    LnFeedDetail(oPC, nToken, sTag);
}

void LnReleaseAttunement(object oPC, int nToken)
{
    string sTag = GetLocalString(oPC, LN_LVAR_SEL_TAG);
    if(sTag == "") return;
    if(!LnIsAttuned(oPC, sTag))
    {
        SendMessageToPC(oPC, "[Węzły] Nie jesteś nastrojony do tego węzła.");
        return;
    }

    LnRemoveAttunement(oPC, sTag);
    string sNodeName = LnGetNodeName(sTag);
    SendMessageToPC(oPC, "[Węzły] Więź z węzłem \"" + sNodeName + "\" zerwana. Złoto rytuału przepadło.");

    DeleteLocalString(oPC, LN_LVAR_SEL_TAG);
    LnFeedList(oPC, nToken);
    LnFeedDetail(oPC, nToken, "");
}
