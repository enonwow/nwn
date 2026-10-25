#include "lib_echo_def"

// ----------------------------------------------------------------
// Spell registration
// ----------------------------------------------------------------

// Build the "caster mask" string — visible to other players as partial info
string EchoBuildCasterMask(object oCaster)
{
    string sRace;
    switch(GetRacialType(oCaster))
    {
        case RACIAL_TYPE_HUMAN:      sRace = "Człowiek";    break;
        case RACIAL_TYPE_ELF:        sRace = "Elf";         break;
        case RACIAL_TYPE_HALFELF:    sRace = "Półelf";      break;
        case RACIAL_TYPE_DWARF:      sRace = "Krasnolud";   break;
        case RACIAL_TYPE_GNOME:      sRace = "Gnom";        break;
        case RACIAL_TYPE_HALFLING:   sRace = "Niziołek";    break;
        case RACIAL_TYPE_HALFORC:    sRace = "Półork";      break;
        default:                     sRace = "Istota";      break;
    }

    string sClass;
    int nClass = GetClassByPosition(1, oCaster);
    switch(nClass)
    {
        case CLASS_TYPE_WIZARD:       sClass = "Mag";         break;
        case CLASS_TYPE_SORCERER:     sClass = "Czarodziej";  break;
        case CLASS_TYPE_CLERIC:       sClass = "Kapłan";      break;
        case CLASS_TYPE_DRUID:        sClass = "Druid";       break;
        case CLASS_TYPE_PALADIN:      sClass = "Paladyn";     break;
        case CLASS_TYPE_RANGER:       sClass = "Łowca";       break;
        case CLASS_TYPE_BARD:         sClass = "Bard";        break;
        default:                      sClass = "Nieznany";    break;
    }
    return sRace + " / " + sClass;
}

void EchoOnSpellCast(object oCaster, int nSpellId)
{
    // Only record spells cast by PCs or named NPCs in valid areas
    object oArea = GetArea(oCaster);
    if(!GetIsObjectValid(oArea)) return;
    // Skip invalid or default areas
    string sAreaTag = GetTag(oArea);
    if(sAreaTag == "" || sAreaTag == "STARTAREA") return;

    int nSchool = GetSpellSchool(nSpellId);
    // Don't record cantrips (spell id 0 is placeholder in many modules)
    if(nSpellId <= 0) return;

    string sSpellName  = GetStringByStrRef(GetSpellName(nSpellId));
    int    nCasterLevel = GetCasterLevel(oCaster);
    if(nCasterLevel <= 0) nCasterLevel = GetLevelByClass(CLASS_TYPE_WIZARD, oCaster)
                                       + GetLevelByClass(CLASS_TYPE_SORCERER, oCaster)
                                       + GetLevelByClass(CLASS_TYPE_CLERIC, oCaster)
                                       + GetLevelByClass(CLASS_TYPE_DRUID, oCaster)
                                       + GetLevelByClass(CLASS_TYPE_BARD, oCaster);
    if(nCasterLevel <= 0) nCasterLevel = 1;

    string sCasterUuid = GetIsPC(oCaster) ? GetObjectUUID(oCaster) : "";
    string sCasterMask = EchoBuildCasterMask(oCaster);

    EchoInsertTrace(sAreaTag, sCasterUuid, sCasterMask, nSpellId, nSchool, sSpellName, nCasterLevel);

    // Periodic decay — prune old traces for this area
    EchoDecayArea(sAreaTag, ECHO_DECAY_HOURS);
}

// ----------------------------------------------------------------
// NUI: window construction
// ----------------------------------------------------------------

json EchoBuildListView(object oPC)
{
    float fBtnH  = GetNuiScaleDimension(oPC, 30.0);
    float fRowH  = GetNuiScaleDimension(oPC, 26.0);
    float fListH = GetNuiScaleDimension(oPC, 320.0);

    // -- Column header --
    json jHdrSchool = NuiLabel(JsonString("Szkoła"), JsonInt(NUI_HALIGN_LEFT), JsonInt(NUI_VALIGN_MIDDLE));
    jHdrSchool = NuiWidth(jHdrSchool, GetNuiScaleDimension(oPC, 120.0));
    json jHdrSpell  = NuiLabel(JsonString("Czar"), JsonInt(NUI_HALIGN_LEFT), JsonInt(NUI_VALIGN_MIDDLE));
    json jHdrAge    = NuiLabel(JsonString("Wiek"), JsonInt(NUI_HALIGN_CENTER), JsonInt(NUI_VALIGN_MIDDLE));
    jHdrAge = NuiWidth(jHdrAge, GetNuiScaleDimension(oPC, 70.0));
    json jHdrPower  = NuiLabel(JsonString("Siła"), JsonInt(NUI_HALIGN_CENTER), JsonInt(NUI_VALIGN_MIDDLE));
    jHdrPower = NuiWidth(jHdrPower, GetNuiScaleDimension(oPC, 60.0));

    json jHdrRow = JsonArray();
    jHdrRow = JsonArrayInsert(jHdrRow, jHdrSchool);
    jHdrRow = JsonArrayInsert(jHdrRow, jHdrSpell);
    jHdrRow = JsonArrayInsert(jHdrRow, jHdrAge);
    jHdrRow = JsonArrayInsert(jHdrRow, jHdrPower);

    // -- Row template --
    float fSchoolW = GetNuiScaleDimension(oPC, 120.0);
    float fAgeW    = GetNuiScaleDimension(oPC, 70.0);
    float fPowerW  = GetNuiScaleDimension(oPC, 60.0);

    json jSchoolLbl = NuiLabel(NuiBind(ECHO_BIND_SCHOOL_LBL), JsonInt(NUI_HALIGN_LEFT), JsonInt(NUI_VALIGN_MIDDLE));
    jSchoolLbl = NuiWidth(jSchoolLbl, fSchoolW);
    jSchoolLbl = NuiStyleForegroundColor(jSchoolLbl, NuiBind(ECHO_BIND_ROW_COLOR));

    json jSpellLbl = NuiLabel(NuiBind(ECHO_BIND_SPELL_LBL), JsonInt(NUI_HALIGN_LEFT), JsonInt(NUI_VALIGN_MIDDLE));
    jSpellLbl = NuiStyleForegroundColor(jSpellLbl, NuiBind(ECHO_BIND_ROW_COLOR));

    json jAgeLbl = NuiLabel(NuiBind(ECHO_BIND_AGE_LBL), JsonInt(NUI_HALIGN_CENTER), JsonInt(NUI_VALIGN_MIDDLE));
    jAgeLbl = NuiWidth(jAgeLbl, fAgeW);
    jAgeLbl = NuiStyleForegroundColor(jAgeLbl, NuiBind(ECHO_BIND_ROW_COLOR));

    json jPowerLbl = NuiLabel(NuiBind(ECHO_BIND_INTENSITY), JsonInt(NUI_HALIGN_CENTER), JsonInt(NUI_VALIGN_MIDDLE));
    jPowerLbl = NuiWidth(jPowerLbl, fPowerW);
    jPowerLbl = NuiStyleForegroundColor(jPowerLbl, NuiBind(ECHO_BIND_ROW_COLOR));

    json jCellRow = JsonArray();
    jCellRow = JsonArrayInsert(jCellRow, jSchoolLbl);
    jCellRow = JsonArrayInsert(jCellRow, jSpellLbl);
    jCellRow = JsonArrayInsert(jCellRow, jAgeLbl);
    jCellRow = JsonArrayInsert(jCellRow, jPowerLbl);

    json jCell = NuiGroup(NuiRow(jCellRow), TRUE, NUI_SCROLLBARS_NONE);
    jCell = NuiId(jCell, ECHO_BTN_ROW);
    jCell = NuiEncouraged(jCell, NuiBind(ECHO_BIND_ROW_ENC));

    json jTmpl = JsonArrayInsert(JsonArray(), NuiListTemplateCell(jCell, 0.0, TRUE));
    json jList = NuiList(jTmpl, NuiBind("echo_rowcount"), fRowH);
    jList = NuiHeight(jList, fListH);

    // -- Bottom bar: Refresh --
    json jRefreshBtn = NuiButton(JsonString("Odśwież"));
    jRefreshBtn = NuiId(jRefreshBtn, ECHO_BTN_REFRESH);
    jRefreshBtn = NuiWidth(jRefreshBtn, GetNuiScaleDimension(oPC, 90.0));
    jRefreshBtn = NuiHeight(jRefreshBtn, fBtnH);

    json jBotRow = JsonArray();
    jBotRow = JsonArrayInsert(jBotRow, NuiSpacer());
    jBotRow = JsonArrayInsert(jBotRow, jRefreshBtn);

    json jCol = JsonArray();
    jCol = JsonArrayInsert(jCol, NuiRow(jHdrRow));
    jCol = JsonArrayInsert(jCol, jList);
    jCol = JsonArrayInsert(jCol, NuiRow(jBotRow));

    return NuiCol(jCol);
}

json EchoBuildDetailView(object oPC)
{
    float fBtnH = GetNuiScaleDimension(oPC, 30.0);
    float fLblH = GetNuiScaleDimension(oPC, 24.0);

    // School row
    json jDetSchool = NuiLabel(NuiBind(ECHO_BIND_DETAIL_SCHOOL), JsonInt(NUI_HALIGN_LEFT), JsonInt(NUI_VALIGN_MIDDLE));
    jDetSchool = NuiHeight(jDetSchool, fLblH);

    // Spell row
    json jDetSpell = NuiLabel(NuiBind(ECHO_BIND_DETAIL_SPELL), JsonInt(NUI_HALIGN_LEFT), JsonInt(NUI_VALIGN_MIDDLE));
    jDetSpell = NuiHeight(jDetSpell, fLblH);

    // Age row
    json jDetAge = NuiLabel(NuiBind(ECHO_BIND_DETAIL_AGE), JsonInt(NUI_HALIGN_LEFT), JsonInt(NUI_VALIGN_MIDDLE));
    jDetAge = NuiHeight(jDetAge, fLblH);

    // Power row
    json jDetPower = NuiLabel(NuiBind(ECHO_BIND_DETAIL_POWER), JsonInt(NUI_HALIGN_LEFT), JsonInt(NUI_VALIGN_MIDDLE));
    jDetPower = NuiHeight(jDetPower, fLblH);

    // Caster mask row
    json jDetCaster = NuiLabel(NuiBind(ECHO_BIND_DETAIL_CASTER), JsonInt(NUI_HALIGN_LEFT), JsonInt(NUI_VALIGN_MIDDLE));
    jDetCaster = NuiHeight(jDetCaster, fLblH);

    // Erase button (only enabled for own traces)
    json jEraseBtn = NuiButton(NuiBind(ECHO_BIND_ERASE_LBL));
    jEraseBtn = NuiId(jEraseBtn, ECHO_BTN_ERASE);
    jEraseBtn = NuiEnabled(jEraseBtn, NuiBind(ECHO_BIND_ERASE_ENA));
    jEraseBtn = NuiHeight(jEraseBtn, fBtnH);

    json jSep = NuiLabel(JsonString("────────────────────────────────────"),
        JsonInt(NUI_HALIGN_LEFT), JsonInt(NUI_VALIGN_MIDDLE));
    jSep = NuiStyleForegroundColor(jSep, NuiColor(100, 100, 100));

    json jCol = JsonArray();
    jCol = JsonArrayInsert(jCol, jSep);
    jCol = JsonArrayInsert(jCol, jDetSchool);
    jCol = JsonArrayInsert(jCol, jDetSpell);
    jCol = JsonArrayInsert(jCol, jDetAge);
    jCol = JsonArrayInsert(jCol, jDetPower);
    jCol = JsonArrayInsert(jCol, jDetCaster);
    jCol = JsonArrayInsert(jCol, NuiSpacer());
    jCol = JsonArrayInsert(jCol, jEraseBtn);

    return NuiCol(jCol);
}

// ----------------------------------------------------------------
// Window create
// ----------------------------------------------------------------

void EchoOpenDetector(object oPC)
{
    int nToken = NuiFindWindow(oPC, ECHO_WINDOW);
    if(nToken != 0)
    {
        EchoFeedTraceList(oPC, nToken);
        return;
    }

    float fCX = (IntToFloat(GetPlayerDeviceProperty(oPC, PLAYER_DEVICE_PROPERTY_GUI_WIDTH))  - GetNuiScaleDimension(oPC, ECHO_W)) / 2.0;
    float fCY = (IntToFloat(GetPlayerDeviceProperty(oPC, PLAYER_DEVICE_PROPERTY_GUI_HEIGHT)) - GetNuiScaleDimension(oPC, ECHO_H)) / 2.0;
    json jGeom = NuiRect(fCX, fCY, GetNuiScaleDimension(oPC, ECHO_W), GetNuiScaleDimension(oPC, ECHO_H));

    // Close button in title bar
    float fBtnH = GetNuiScaleDimension(oPC, 30.0);
    json jCloseBtn = NuiButton(JsonString("X"));
    jCloseBtn = NuiId(jCloseBtn, ECHO_BTN_CLOSE);
    jCloseBtn = NuiWidth(jCloseBtn, GetNuiScaleDimension(oPC, 30.0));
    jCloseBtn = NuiHeight(jCloseBtn, fBtnH);
    json jTopBar = JsonArray();
    jTopBar = JsonArrayInsert(jTopBar, NuiSpacer());
    jTopBar = JsonArrayInsert(jTopBar, jCloseBtn);

    // Left panel: trace list (wider)
    float fListColW   = GetNuiScaleDimension(oPC, 410.0);
    float fDetailColW = GetNuiScaleDimension(oPC, 220.0);

    json jListGrp   = NuiGroup(EchoBuildListView(oPC),   FALSE, NUI_SCROLLBARS_NONE);
    jListGrp = NuiWidth(jListGrp, fListColW);

    // Right panel: detail pane (static — group layout swapped on selection)
    json jDetailGrp = NuiGroup(EchoBuildDetailView(oPC), FALSE, NUI_SCROLLBARS_NONE);
    jDetailGrp = NuiId(jDetailGrp, ECHO_GRP_DETAIL);
    jDetailGrp = NuiWidth(jDetailGrp, fDetailColW);

    json jBodyRow = JsonArray();
    jBodyRow = JsonArrayInsert(jBodyRow, jListGrp);
    jBodyRow = JsonArrayInsert(jBodyRow, jDetailGrp);

    json jRootCol = JsonArray();
    jRootCol = JsonArrayInsert(jRootCol, NuiRow(jTopBar));
    jRootCol = JsonArrayInsert(jRootCol, NuiRow(jBodyRow));
    json jRoot = NuiCol(jRootCol);

    json jWin = NuiWindow(jRoot,
        JsonString("Echo Arkanów"),
        NuiBind(ECHO_WIN_GEOM),
        JsonBool(FALSE),
        JsonBool(FALSE),
        JsonBool(FALSE),
        JsonBool(TRUE),
        JsonBool(FALSE));

    nToken = NuiCreate(oPC, jWin, ECHO_WINDOW, ECHO_EV_SCRIPT);
    NuiSetBind(oPC, nToken, ECHO_WIN_GEOM, jGeom);

    SetLocalInt(oPC, ECHO_LVAR_SEL_ID, 0);
    EchoFeedTraceList(oPC, nToken);
    EchoFeedDetailEmpty(oPC, nToken);
}

// ----------------------------------------------------------------
// Feed functions
// ----------------------------------------------------------------

void EchoFeedDetailEmpty(object oPC, int nToken)
{
    NuiSetBind(oPC, nToken, ECHO_BIND_DETAIL_SCHOOL,  JsonString("Wybierz ślad z listy…"));
    NuiSetBind(oPC, nToken, ECHO_BIND_DETAIL_SPELL,   JsonString(""));
    NuiSetBind(oPC, nToken, ECHO_BIND_DETAIL_AGE,     JsonString(""));
    NuiSetBind(oPC, nToken, ECHO_BIND_DETAIL_POWER,   JsonString(""));
    NuiSetBind(oPC, nToken, ECHO_BIND_DETAIL_CASTER,  JsonString(""));
    NuiSetBind(oPC, nToken, ECHO_BIND_ERASE_ENA,      JsonBool(FALSE));
    NuiSetBind(oPC, nToken, ECHO_BIND_ERASE_LBL,      JsonString("Zatarcie śladów"));
}

void EchoFeedTraceList(object oPC, int nToken)
{
    object oArea    = GetArea(oPC);
    string sAreaTag = GetTag(oArea);

    EchoDecayArea(sAreaTag, ECHO_DECAY_HOURS);

    json jTraces = EchoGetAreaTraces(sAreaTag, ECHO_MAX_LIST);
    int nCount   = JsonGetLength(jTraces);

    int nSelId = GetLocalInt(oPC, ECHO_LVAR_SEL_ID);

    json jSchools  = JsonArray();
    json jSpells   = JsonArray();
    json jAges     = JsonArray();
    json jPowers   = JsonArray();
    json jColors   = JsonArray();
    json jEncs     = JsonArray();

    int i;
    for(i = 0; i < nCount; i++)
    {
        json jRow        = JsonArrayGet(jTraces, i);
        int  nId         = JsonGetInt   (JsonObjectGet(jRow, "id"));
        int  nSchool     = JsonGetInt   (JsonObjectGet(jRow, "spell_school"));
        string sSpell    = JsonGetString(JsonObjectGet(jRow, "spell_name"));
        int  nCasterLvl  = JsonGetInt   (JsonObjectGet(jRow, "caster_level"));
        int  nSecondsOld = JsonGetInt   (JsonObjectGet(jRow, "seconds_old"));

        jSchools = JsonArrayInsert(jSchools, JsonString(EchoSchoolLabel(nSchool)));
        jSpells  = JsonArrayInsert(jSpells,  JsonString(sSpell));
        jAges    = JsonArrayInsert(jAges,    JsonString(EchoAgeLabel(nSecondsOld)));
        jPowers  = JsonArrayInsert(jPowers,  JsonString(EchoPowerLabel(nCasterLvl)));
        jColors  = JsonArrayInsert(jColors,  EchoSchoolColor(nSchool));
        jEncs    = JsonArrayInsert(jEncs,    JsonBool(nSelId > 0 && nId == nSelId));
    }

    NuiSetBind(oPC, nToken, ECHO_BIND_SCHOOL_LBL, jSchools);
    NuiSetBind(oPC, nToken, ECHO_BIND_SPELL_LBL,  jSpells);
    NuiSetBind(oPC, nToken, ECHO_BIND_AGE_LBL,    jAges);
    NuiSetBind(oPC, nToken, ECHO_BIND_INTENSITY,  jPowers);
    NuiSetBind(oPC, nToken, ECHO_BIND_ROW_COLOR,  jColors);
    NuiSetBind(oPC, nToken, ECHO_BIND_ROW_ENC,    jEncs);
    NuiSetBind(oPC, nToken, "echo_rowcount",      JsonInt(nCount));

    if(nCount == 0)
        SendMessageToPC(oPC, "[Echo Arkanów] Brak śladów magicznych w tej lokacji.");
}

void EchoFeedDetail(object oPC, int nToken, int nTraceId)
{
    json jTrace = EchoGetTrace(nTraceId);
    if(JsonGetType(jTrace) == JSON_TYPE_NULL)
    {
        EchoFeedDetailEmpty(oPC, nToken);
        return;
    }

    int    nSchool      = JsonGetInt   (JsonObjectGet(jTrace, "spell_school"));
    string sSpellName   = JsonGetString(JsonObjectGet(jTrace, "spell_name"));
    int    nCasterLevel = JsonGetInt   (JsonObjectGet(jTrace, "caster_level"));
    int    nSecondsOld  = JsonGetInt   (JsonObjectGet(jTrace, "seconds_old"));
    string sCasterUuid  = JsonGetString(JsonObjectGet(jTrace, "caster_uuid"));
    string sCasterMask  = JsonGetString(JsonObjectGet(jTrace, "caster_mask"));

    int bIsOwn = (sCasterUuid != "" && GetObjectUUID(oPC) == sCasterUuid);

    SetLocalInt(oPC, ECHO_LVAR_SEL_ID, nTraceId);
    SetLocalInt(oPC, ECHO_LVAR_IS_OWN, bIsOwn);

    string sCasterDisplay = EchoCasterMask(sCasterUuid, sCasterMask, oPC);

    // Erase cost depends on how many of your own traces remain
    int nEraseCost = 0;
    if(bIsOwn)
    {
        int nCount = EchoCasterTraceCount(GetTag(GetArea(oPC)), sCasterUuid);
        nEraseCost = nCount * ECHO_ERASE_GOLD_COST;
    }

    NuiSetBind(oPC, nToken, ECHO_BIND_DETAIL_SCHOOL,
        JsonString("Szkoła: " + EchoSchoolLabel(nSchool)));
    NuiSetBind(oPC, nToken, ECHO_BIND_DETAIL_SPELL,
        JsonString("Czar: " + sSpellName));
    NuiSetBind(oPC, nToken, ECHO_BIND_DETAIL_AGE,
        JsonString("Wiek: " + EchoAgeLabel(nSecondsOld)));
    NuiSetBind(oPC, nToken, ECHO_BIND_DETAIL_POWER,
        JsonString("Moc: " + EchoPowerLabel(nCasterLevel) + " (poz. " + IntToString(nCasterLevel) + ")"));
    NuiSetBind(oPC, nToken, ECHO_BIND_DETAIL_CASTER,
        JsonString("Rzucający: " + sCasterDisplay));
    NuiSetBind(oPC, nToken, ECHO_BIND_ERASE_ENA,
        JsonBool(bIsOwn));
    NuiSetBind(oPC, nToken, ECHO_BIND_ERASE_LBL,
        JsonString(bIsOwn
            ? "Zatarcie śladów (" + IntToString(nEraseCost) + " sz.)"
            : "Zatarcie śladów"));
}
