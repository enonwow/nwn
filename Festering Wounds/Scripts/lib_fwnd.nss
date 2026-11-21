#include "lib_fwnd_def"

void FwndOpen(object oPC);
void FwndPCLoop(object oPC);
void FwndFeedList(object oPC, int nToken);
void FwndFeedDetail(object oPC, int nToken, int nWoundId);
void FwndSwapToList(object oPC, int nToken);
void FwndSwapToDetail(object oPC, int nToken, int nWoundId);
void FwndRemoveDebuffs(object oPC);
void FwndApplyWoundEffects(object oPC);

// ----------------------------------------------------------------
// Label helpers
// ----------------------------------------------------------------

string FwndTypeName(int nType)
{
    switch(nType)
    {
        case FWND_TYPE_VAMPIRE:  return "Ukąszenie Wampira";
        case FWND_TYPE_NECROTIC: return "Gnilna Rana";
        case FWND_TYPE_DEMONIC:  return "Szrama Demoniczna";
        case FWND_TYPE_VENOM:    return "Głębokie Zatrucie";
        case FWND_TYPE_CURSED:   return "Przeklęte Cięcie";
    }
    return "Nieznana Rana";
}

string FwndTypeIcon(int nType)
{
    switch(nType)
    {
        case FWND_TYPE_VAMPIRE:  return "[K]";
        case FWND_TYPE_NECROTIC: return "[G]";
        case FWND_TYPE_DEMONIC:  return "[D]";
        case FWND_TYPE_VENOM:    return "[T]";
        case FWND_TYPE_CURSED:   return "[P]";
    }
    return "[?]";
}

string FwndSeverityLabel(int nSev)
{
    switch(nSev)
    {
        case 1: return "I — Swierza";
        case 2: return "II — Narastajaca";
        case 3: return "III — Gleboka";
        case 4: return "IV — Agonizujaca";
        case 5: return "V — Smiertelna";
    }
    return "—";
}

string FwndSeverityStars(int nSev)
{
    if(nSev == 1) return "*....";
    if(nSev == 2) return "**...";
    if(nSev == 3) return "***..";
    if(nSev == 4) return "****.";
    return "*****";
}

json FwndSeverityColor(int nSev)
{
    switch(nSev)
    {
        case 1: return NuiColor(200, 200, 200);
        case 2: return NuiColor(220, 180,  80);
        case 3: return NuiColor(220, 120,  40);
        case 4: return NuiColor(200,  60,  30);
        case 5: return NuiColor(200,  20,  20);
    }
    return NuiColor(255, 255, 255);
}

string FwndTypeDescription(int nType, int nSev)
{
    string sDesc;
    switch(nType)
    {
        case FWND_TYPE_VAMPIRE:
            sDesc = "Wampirze ukąszenie sączy żywotność z ciała. Krew stygnie, siły opuszczają kończyny. Rana szuka drogi do serca.\n\nKara: Konstytucja -" + IntToString(nSev);
            break;
        case FWND_TYPE_NECROTIC:
            sDesc = "Gnilna magia wżera się w mięśnie, pozostawiając tkanki martwe i kruche. Cada z ciężarem ziemi.\n\nKara: Siła -" + IntToString(nSev);
            break;
        case FWND_TYPE_DEMONIC:
            sDesc = "Szrama nosi piętno demonicznej esencji. Umysł oplata fałszywymi wizjami i szeptami z Otchłani.\n\nKara: Mądrość -" + IntToString(nSev);
            break;
        case FWND_TYPE_VENOM:
            sDesc = "Jad wsiąka głęboko, blokując nerwy. Każdy ruch wymaga skupienia, którego już nie ma — trzęsące się dłonie nie słuchają woli.\n\nKara: Zręczność -" + IntToString(nSev);
            break;
        case FWND_TYPE_CURSED:
            sDesc = "Przeklęte ostrze pozostawiło ślad mroku w ranie. Ręka drży, wzrok traci cel — zaklęcie ciągnie broń w bok przy każdym ciosie.\n\nKara: Atak -" + IntToString(nSev);
            break;
        default:
            sDesc = "Nieznana magia. Rana pulsuje słabo, ciągnąc życie powoli.";
            break;
    }
    return sDesc;
}

string FwndTreatmentText(int nType)
{
    switch(nType)
    {
        case FWND_TYPE_VAMPIRE:  return "Wymagane: Woda Święcona  (fwnd_holy_water)";
        case FWND_TYPE_NECROTIC: return "Wymagane: Żywica Życia   (fwnd_life_salve)";
        case FWND_TYPE_DEMONIC:  return "Wymagane: Ziele Odczynienia (fwnd_ward_herb)";
        case FWND_TYPE_VENOM:    return "Wymagane: Antytoksyna     (fwnd_antitoxin)";
        case FWND_TYPE_CURSED:   return "Wymagane: Olej Egzorcyzmu (fwnd_exorcism)";
    }
    return "";
}

string FwndTreatmentTag(int nType)
{
    switch(nType)
    {
        case FWND_TYPE_VAMPIRE:  return FWND_ITEM_HOLY_WATER;
        case FWND_TYPE_NECROTIC: return FWND_ITEM_LIFE_SALVE;
        case FWND_TYPE_DEMONIC:  return FWND_ITEM_WARD_HERB;
        case FWND_TYPE_VENOM:    return FWND_ITEM_ANTITOXIN;
        case FWND_TYPE_CURSED:   return FWND_ITEM_EXORCISM;
    }
    return "";
}

// ----------------------------------------------------------------
// Effect management
// ----------------------------------------------------------------

void FwndRemoveDebuffs(object oPC)
{
    effect eEff = GetFirstEffect(oPC);
    while(GetIsEffectValid(eEff))
    {
        if(GetEffectTag(eEff) == FWND_EFFECT_TAG)
            RemoveEffect(oPC, eEff);
        eEff = GetNextEffect(oPC);
    }
}

void FwndApplyWoundEffects(object oPC)
{
    FwndRemoveDebuffs(oPC);

    json jWounds = FwndGetWounds(oPC);
    int nCount   = JsonGetLength(jWounds);
    if(nCount == 0) return;

    int i;
    for(i = 0; i < nCount; i++)
    {
        json jW   = JsonArrayGet(jWounds, i);
        int nType = JsonGetInt(JsonObjectGet(jW, "wound_type"));
        int nSev  = JsonGetInt(JsonObjectGet(jW, "severity"));

        effect eDebuff;
        int bValid = TRUE;

        switch(nType)
        {
            case FWND_TYPE_VAMPIRE:
                eDebuff = EffectAbilityDecrease(ABILITY_CONSTITUTION, nSev);
                break;
            case FWND_TYPE_NECROTIC:
                eDebuff = EffectAbilityDecrease(ABILITY_STRENGTH, nSev);
                break;
            case FWND_TYPE_DEMONIC:
                eDebuff = EffectAbilityDecrease(ABILITY_WISDOM, nSev);
                break;
            case FWND_TYPE_VENOM:
                eDebuff = EffectAbilityDecrease(ABILITY_DEXTERITY, nSev);
                break;
            case FWND_TYPE_CURSED:
                eDebuff = EffectAttackDecrease(nSev);
                break;
            default:
                bValid = FALSE;
                break;
        }

        if(bValid)
        {
            eDebuff = TagEffect(eDebuff, FWND_EFFECT_TAG);
            eDebuff = ExtraordinaryEffect(eDebuff);
            ApplyEffectToObject(DURATION_TYPE_PERMANENT, eDebuff, oPC);
        }
    }
}

// ----------------------------------------------------------------
// Wound progression and per-PC loop
// ----------------------------------------------------------------

void FwndProgressWounds(object oPC)
{
    json jDue  = FwndGetWoundsToProgress(oPC);
    int nCount = JsonGetLength(jDue);
    if(nCount == 0) return;

    int i;
    for(i = 0; i < nCount; i++)
    {
        json jW   = JsonArrayGet(jDue, i);
        int nId   = JsonGetInt(JsonObjectGet(jW, "id"));
        int nSev  = JsonGetInt(JsonObjectGet(jW, "severity"));
        int nType = JsonGetInt(JsonObjectGet(jW, "wound_type"));

        int nNewSev = nSev + 1;
        FwndSetSeverity(nId, nNewSev);

        string sWName = FwndTypeName(nType);
        SendMessageToPC(oPC, "[Rany] " + sWName + " się pogłębia... (" + FwndSeverityLabel(nNewSev) + ")");

        if(nNewSev >= 5)
            FloatingTextStringOnCreature("Rana osiągnęła poziom ŚMIERTELNY!", oPC, FALSE);
    }

    int nToken = NuiFindWindow(oPC, FWND_WINDOW);
    if(nToken != 0)
        FwndFeedList(oPC, nToken);
}

void FwndPCLoop(object oPC)
{
    if(!GetIsObjectValid(oPC)) return;
    if(!GetIsPC(oPC))          return;
    if(!GetLocalInt(oPC, FWND_LVAR_LOOP_RUN)) return;

    FwndProgressWounds(oPC);
    FwndApplyWoundEffects(oPC);

    DelayCommand(FWND_LOOP_DELAY, FwndPCLoop(oPC));
}

// ----------------------------------------------------------------
// Treatment
// ----------------------------------------------------------------

int FwndHasTreatmentItem(object oPC, int nType)
{
    string sTag = FwndTreatmentTag(nType);
    if(sTag != "" && GetIsObjectValid(GetItemPossessedBy(oPC, sTag))) return TRUE;
    if(GetIsObjectValid(GetItemPossessedBy(oPC, FWND_ITEM_LIFE_LEAF))) return TRUE;
    return FALSE;
}

void FwndApplyTreatment(object oPC, int nWoundId)
{
    json jW = FwndGetWound(nWoundId);
    if(JsonGetType(jW) == JSON_TYPE_NULL) return;

    int nType = JsonGetInt(JsonObjectGet(jW, "wound_type"));
    int nSev  = JsonGetInt(JsonObjectGet(jW, "severity"));

    string sSpecTag  = FwndTreatmentTag(nType);
    object oItem     = OBJECT_INVALID;
    int    bUniversal = FALSE;

    if(sSpecTag != "")
        oItem = GetItemPossessedBy(oPC, sSpecTag);

    if(!GetIsObjectValid(oItem))
    {
        oItem = GetItemPossessedBy(oPC, FWND_ITEM_LIFE_LEAF);
        if(!GetIsObjectValid(oItem))
        {
            SendMessageToPC(oPC, "[Rany] Nie posiadasz odpowiedniego leku.");
            return;
        }
        bUniversal = TRUE;
    }

    int nStack = GetItemStackSize(oItem);
    if(nStack > 1)
        SetItemStackSize(oItem, nStack - 1);
    else
        DestroyObject(oItem);

    int nNewSev = nSev - 1;
    FwndSetSeverity(nWoundId, nNewSev);

    string sWName = FwndTypeName(nType);
    if(nNewSev <= 0)
    {
        SendMessageToPC(oPC, "[Rany] " + sWName + " — uleczona. Rana zamknęła się.");
        FloatingTextStringOnCreature("Rana zagojona!", oPC, FALSE);
    }
    else
    {
        SendMessageToPC(oPC, "[Rany] " + sWName + " — złagodzona do: " + FwndSeverityLabel(nNewSev));
    }

    FwndApplyWoundEffects(oPC);
}

// ----------------------------------------------------------------
// NUI layout builders
// ----------------------------------------------------------------

json FwndBuildListView(object oPC)
{
    float fBtnH  = GetNuiScaleDimension(oPC, 30.0);
    float fRowH  = GetNuiScaleDimension(oPC, 30.0);
    float fIconW = GetNuiScaleDimension(oPC, 44.0);
    float fSevW  = GetNuiScaleDimension(oPC, 84.0);

    json jHeaderLbl = NuiLabel(NuiBind(FWND_BIND_HEADER),
        JsonInt(NUI_HALIGN_LEFT), JsonInt(NUI_VALIGN_MIDDLE));
    jHeaderLbl = NuiHeight(jHeaderLbl, fBtnH);

    json jIconLbl = NuiLabel(NuiBind(FWND_BIND_LIST_ICON),
        JsonInt(NUI_HALIGN_CENTER), JsonInt(NUI_VALIGN_MIDDLE));
    jIconLbl = NuiWidth(jIconLbl, fIconW);
    jIconLbl = NuiStyleForegroundColor(jIconLbl, NuiBind(FWND_BIND_LIST_COL));

    json jNameLbl = NuiLabel(NuiBind(FWND_BIND_LIST_NAME),
        JsonInt(NUI_HALIGN_LEFT), JsonInt(NUI_VALIGN_MIDDLE));
    jNameLbl = NuiStyleForegroundColor(jNameLbl, NuiBind(FWND_BIND_LIST_COL));

    json jSevLbl = NuiLabel(NuiBind(FWND_BIND_LIST_SEV),
        JsonInt(NUI_HALIGN_RIGHT), JsonInt(NUI_VALIGN_MIDDLE));
    jSevLbl = NuiWidth(jSevLbl, fSevW);
    jSevLbl = NuiStyleForegroundColor(jSevLbl, NuiBind(FWND_BIND_LIST_COL));

    json jCellInner = JsonArray();
    jCellInner = JsonArrayInsert(jCellInner, jIconLbl);
    jCellInner = JsonArrayInsert(jCellInner, jNameLbl);
    jCellInner = JsonArrayInsert(jCellInner, jSevLbl);

    json jCell = NuiGroup(NuiRow(jCellInner), TRUE, NUI_SCROLLBARS_NONE);
    jCell = NuiId(jCell, FWND_BTN_ROW);
    jCell = NuiEncouraged(jCell, NuiBind(FWND_BIND_LIST_ENC));

    json jTmpl = JsonArrayInsert(JsonArray(), NuiListTemplateCell(jCell, 0.0, TRUE));

    float fListH = GetNuiScaleDimension(oPC, 295.0);
    json  jList  = NuiList(jTmpl, NuiBind(FWND_BIND_ROWCOUNT), fRowH);
    jList = NuiHeight(jList, fListH);

    json jCloseBtn = NuiButton(JsonString("Zamknij"));
    jCloseBtn = NuiId(jCloseBtn, FWND_BTN_CLOSE);
    jCloseBtn = NuiWidth(jCloseBtn, GetNuiScaleDimension(oPC, 100.0));
    jCloseBtn = NuiHeight(jCloseBtn, fBtnH);

    json jBotRow = JsonArray();
    jBotRow = JsonArrayInsert(jBotRow, NuiSpacer());
    jBotRow = JsonArrayInsert(jBotRow, jCloseBtn);

    json jCol = JsonArray();
    jCol = JsonArrayInsert(jCol, NuiRow(JsonArrayInsert(JsonArray(), jHeaderLbl)));
    jCol = JsonArrayInsert(jCol, jList);
    jCol = JsonArrayInsert(jCol, NuiRow(jBotRow));

    json jSide    = NuiCol(JsonArrayInsert(JsonArray(), NuiSpacer()));
    float fContW  = GetNuiScaleDimension(oPC, 520.0);
    json jMainRow = JsonArray();
    jMainRow = JsonArrayInsert(jMainRow, jSide);
    jMainRow = JsonArrayInsert(jMainRow, NuiWidth(NuiCol(jCol), fContW));
    jMainRow = JsonArrayInsert(jMainRow, jSide);
    return NuiRow(jMainRow);
}

json FwndBuildDetailView(object oPC)
{
    float fBtnH  = GetNuiScaleDimension(oPC, 30.0);
    float fDescH = GetNuiScaleDimension(oPC, 175.0);

    json jNameLbl = NuiLabel(NuiBind(FWND_BIND_DET_WNAME),
        JsonInt(NUI_HALIGN_LEFT), JsonInt(NUI_VALIGN_MIDDLE));
    jNameLbl = NuiHeight(jNameLbl, GetNuiScaleDimension(oPC, 26.0));

    json jTypeLbl = NuiLabel(NuiBind(FWND_BIND_DET_TYPE),
        JsonInt(NUI_HALIGN_LEFT), JsonInt(NUI_VALIGN_MIDDLE));
    jTypeLbl = NuiHeight(jTypeLbl, GetNuiScaleDimension(oPC, 22.0));

    json jSevLbl = NuiLabel(NuiBind(FWND_BIND_DET_SEV),
        JsonInt(NUI_HALIGN_LEFT), JsonInt(NUI_VALIGN_MIDDLE));
    jSevLbl = NuiHeight(jSevLbl, GetNuiScaleDimension(oPC, 22.0));

    json jDescBox = NuiGroup(NuiText(NuiBind(FWND_BIND_DET_DESC), FALSE), TRUE, NUI_SCROLLBARS_NONE);
    jDescBox = NuiHeight(jDescBox, fDescH);

    json jTreatLbl = NuiLabel(NuiBind(FWND_BIND_DET_TREAT),
        JsonInt(NUI_HALIGN_LEFT), JsonInt(NUI_VALIGN_MIDDLE));
    jTreatLbl = NuiHeight(jTreatLbl, GetNuiScaleDimension(oPC, 24.0));

    json jTreatBtn = NuiButton(JsonString("Zastosuj Lekarstwo"));
    jTreatBtn = NuiId(jTreatBtn, FWND_BTN_TREAT);
    jTreatBtn = NuiEnabled(jTreatBtn, NuiBind(FWND_BIND_TREAT_ENA));
    jTreatBtn = NuiWidth(jTreatBtn, GetNuiScaleDimension(oPC, 200.0));
    jTreatBtn = NuiHeight(jTreatBtn, fBtnH);

    json jBackBtn = NuiButton(JsonString("Powrot"));
    jBackBtn = NuiId(jBackBtn, FWND_BTN_BACK);
    jBackBtn = NuiWidth(jBackBtn, GetNuiScaleDimension(oPC, 80.0));
    jBackBtn = NuiHeight(jBackBtn, fBtnH);

    json jBotRow = JsonArray();
    jBotRow = JsonArrayInsert(jBotRow, jBackBtn);
    jBotRow = JsonArrayInsert(jBotRow, NuiSpacer());
    jBotRow = JsonArrayInsert(jBotRow, jTreatBtn);

    json jCol = JsonArray();
    jCol = JsonArrayInsert(jCol, NuiRow(JsonArrayInsert(JsonArray(), jNameLbl)));
    jCol = JsonArrayInsert(jCol, NuiRow(JsonArrayInsert(JsonArray(), jTypeLbl)));
    jCol = JsonArrayInsert(jCol, NuiRow(JsonArrayInsert(JsonArray(), jSevLbl)));
    jCol = JsonArrayInsert(jCol, jDescBox);
    jCol = JsonArrayInsert(jCol, NuiRow(JsonArrayInsert(JsonArray(), jTreatLbl)));
    jCol = JsonArrayInsert(jCol, NuiRow(jBotRow));

    json jSide    = NuiCol(JsonArrayInsert(JsonArray(), NuiSpacer()));
    float fContW  = GetNuiScaleDimension(oPC, 520.0);
    json jMainRow = JsonArray();
    jMainRow = JsonArrayInsert(jMainRow, jSide);
    jMainRow = JsonArrayInsert(jMainRow, NuiWidth(NuiCol(jCol), fContW));
    jMainRow = JsonArrayInsert(jMainRow, jSide);
    return NuiRow(jMainRow);
}

// ----------------------------------------------------------------
// Feed functions
// ----------------------------------------------------------------

void FwndFeedList(object oPC, int nToken)
{
    json jWounds = FwndGetWounds(oPC);
    int  nCount  = JsonGetLength(jWounds);

    string sHeader;
    if(nCount == 0)
        sHeader = "Rany Gnijące — brak aktywnych ran";
    else if(nCount == 1)
        sHeader = "Rany Gnijące — 1 aktywna rana";
    else
        sHeader = "Rany Gnijące — " + IntToString(nCount) + " aktywnych ran";

    NuiSetBind(oPC, nToken, FWND_BIND_HEADER,   JsonString(sHeader));
    NuiSetBind(oPC, nToken, FWND_BIND_ROWCOUNT, JsonInt(nCount));

    json jIcons  = JsonArray();
    json jNames  = JsonArray();
    json jSevs   = JsonArray();
    json jColors = JsonArray();
    json jEncs   = JsonArray();

    int nSelId = GetLocalInt(oPC, FWND_LVAR_SEL_ID);

    int i;
    for(i = 0; i < nCount; i++)
    {
        json jW   = JsonArrayGet(jWounds, i);
        int nType = JsonGetInt(JsonObjectGet(jW, "wound_type"));
        int nSev  = JsonGetInt(JsonObjectGet(jW, "severity"));
        int nId   = JsonGetInt(JsonObjectGet(jW, "id"));

        jIcons  = JsonArrayInsert(jIcons,  JsonString(FwndTypeIcon(nType)));
        jNames  = JsonArrayInsert(jNames,  JsonString(FwndTypeName(nType)));
        jSevs   = JsonArrayInsert(jSevs,   JsonString(FwndSeverityStars(nSev)));
        jColors = JsonArrayInsert(jColors, FwndSeverityColor(nSev));
        jEncs   = JsonArrayInsert(jEncs,   JsonBool(nSelId > 0 && nId == nSelId));
    }

    NuiSetBind(oPC, nToken, FWND_BIND_LIST_ICON, jIcons);
    NuiSetBind(oPC, nToken, FWND_BIND_LIST_NAME, jNames);
    NuiSetBind(oPC, nToken, FWND_BIND_LIST_SEV,  jSevs);
    NuiSetBind(oPC, nToken, FWND_BIND_LIST_COL,  jColors);
    NuiSetBind(oPC, nToken, FWND_BIND_LIST_ENC,  jEncs);
}

void FwndFeedDetail(object oPC, int nToken, int nWoundId)
{
    json jW = FwndGetWound(nWoundId);
    if(JsonGetType(jW) == JSON_TYPE_NULL)
    {
        // Wound no longer exists — return to list
        FwndSwapToList(oPC, nToken);
        return;
    }

    int    nType = JsonGetInt   (JsonObjectGet(jW, "wound_type"));
    int    nSev  = JsonGetInt   (JsonObjectGet(jW, "severity"));
    string sSrc  = JsonGetString(JsonObjectGet(jW, "source_name"));

    string sDesc = FwndTypeDescription(nType, nSev);
    if(sSrc != "")
        sDesc += "\n\nZadana przez: " + sSrc;

    string sTreat = FwndTreatmentText(nType)
                  + "\n" + "Lisc Zywotnika: dziala na kazda rane (-1 sila).";

    int bHasItem = FwndHasTreatmentItem(oPC, nType);

    SetLocalInt(oPC, FWND_LVAR_SEL_ID, nWoundId);

    NuiSetBind(oPC, nToken, FWND_BIND_DET_WNAME, JsonString(FwndTypeName(nType)));
    NuiSetBind(oPC, nToken, FWND_BIND_DET_TYPE,  JsonString("Typ: " + FwndTypeIcon(nType) + "  " + FwndTypeName(nType)));
    NuiSetBind(oPC, nToken, FWND_BIND_DET_SEV,
        JsonString("Sila rany: " + FwndSeverityLabel(nSev) + "  " + FwndSeverityStars(nSev)));
    NuiSetBind(oPC, nToken, FWND_BIND_DET_DESC,  JsonString(sDesc));
    NuiSetBind(oPC, nToken, FWND_BIND_DET_TREAT, JsonString(sTreat));
    NuiSetBind(oPC, nToken, FWND_BIND_TREAT_ENA, JsonBool(bHasItem));
}

// ----------------------------------------------------------------
// View switching
// ----------------------------------------------------------------

void FwndSwapToList(object oPC, int nToken)
{
    NuiSetGroupLayout(oPC, nToken, FWND_GRP_SWAP, FwndBuildListView(oPC));
    SetLocalInt(oPC, FWND_LVAR_SEL_ID, 0);
    FwndFeedList(oPC, nToken);
}

void FwndSwapToDetail(object oPC, int nToken, int nWoundId)
{
    NuiSetGroupLayout(oPC, nToken, FWND_GRP_SWAP, FwndBuildDetailView(oPC));
    FwndFeedDetail(oPC, nToken, nWoundId);
}

// ----------------------------------------------------------------
// Window creation
// ----------------------------------------------------------------

void FwndOpen(object oPC)
{
    int nToken = NuiFindWindow(oPC, FWND_WINDOW);
    if(nToken != 0)
    {
        FwndSwapToList(oPC, nToken);
        return;
    }

    float fCX = (IntToFloat(GetPlayerDeviceProperty(oPC, PLAYER_DEVICE_PROPERTY_GUI_WIDTH))
                 - GetNuiScaleDimension(oPC, FWND_W)) / 2.0;
    float fCY = (IntToFloat(GetPlayerDeviceProperty(oPC, PLAYER_DEVICE_PROPERTY_GUI_HEIGHT))
                 - GetNuiScaleDimension(oPC, FWND_H)) / 2.0;
    json jGeom = NuiRect(fCX, fCY,
                         GetNuiScaleDimension(oPC, FWND_W),
                         GetNuiScaleDimension(oPC, FWND_H));

    json jSwapGrp = NuiGroup(FwndBuildListView(oPC), FALSE, NUI_SCROLLBARS_NONE);
    jSwapGrp = NuiId(jSwapGrp, FWND_GRP_SWAP);

    float fBtnH    = GetNuiScaleDimension(oPC, 30.0);
    json  jCloseX  = NuiButton(JsonString("X"));
    jCloseX = NuiId(jCloseX, FWND_BTN_CLOSE);
    jCloseX = NuiWidth(jCloseX, GetNuiScaleDimension(oPC, 30.0));
    jCloseX = NuiHeight(jCloseX, fBtnH);

    json jTopBar = JsonArray();
    jTopBar = JsonArrayInsert(jTopBar, NuiSpacer());
    jTopBar = JsonArrayInsert(jTopBar, jCloseX);

    json jRootCol = JsonArray();
    jRootCol = JsonArrayInsert(jRootCol, NuiRow(jTopBar));
    jRootCol = JsonArrayInsert(jRootCol, jSwapGrp);

    json jWin = NuiWindow(NuiCol(jRootCol),
        JsonBool(FALSE),
        NuiBind(FWND_WIN_GEOM),
        JsonBool(FALSE),
        JsonBool(FALSE),
        JsonBool(FALSE),
        JsonBool(TRUE),
        JsonBool(FALSE));

    nToken = NuiCreate(oPC, jWin, FWND_WINDOW, FWND_EV_SCRIPT);
    NuiSetBind(oPC, nToken, FWND_WIN_GEOM, jGeom);

    FwndSwapToList(oPC, nToken);
}
