#include "lib_gwk_def"

// Forward declarations (cross-call order within this file)
json GwkBuildForgeContent(object oPC);
json GwkBuildGolemContent(object oPC);
void GwkDoForge(object oPC, int nToken, int nType);
void GwkDoRepair(object oPC, int nToken);
void GwkDoRecall(object oPC, int nToken);
void GwkDoDestroy(object oPC, int nToken);

// ----------------------------------------------------------------
// Layout builders
// ----------------------------------------------------------------

// Returns a NUI element representing one material requirement row.
json GwkMatRow(object oPC, string sReqBind, string sHaveBind, string sOkBind)
{
    float fH    = GetNuiScaleDimension(oPC, 24.0);
    float fReqW = GetNuiScaleDimension(oPC, 250.0);
    float fHaveW= GetNuiScaleDimension(oPC, 160.0);

    json jReq = NuiLabel(NuiBind(sReqBind), JsonInt(NUI_HALIGN_LEFT), JsonInt(NUI_VALIGN_MIDDLE));
    jReq = NuiHeight(jReq, fH);
    jReq = NuiWidth(jReq, fReqW);

    json jHave = NuiLabel(NuiBind(sHaveBind), JsonInt(NUI_HALIGN_LEFT), JsonInt(NUI_VALIGN_MIDDLE));
    jHave = NuiHeight(jHave, fH);
    jHave = NuiWidth(jHave, fHaveW);
    jHave = NuiStyleForegroundColor(jHave, NuiBind(sOkBind));

    json jArr = JsonArray();
    jArr = JsonArrayInsert(jArr, jReq);
    jArr = JsonArrayInsert(jArr, jHave);
    return NuiRow(jArr);
}

json GwkBuildForgeContent(object oPC)
{
    float fBtnH = GetNuiScaleDimension(oPC, 30.0);
    float fLblH = GetNuiScaleDimension(oPC, 24.0);
    float fDescH= GetNuiScaleDimension(oPC, 85.0);
    float fBigH = GetNuiScaleDimension(oPC, 44.0);
    float fLblW = GetNuiScaleDimension(oPC, 115.0);

    // --- Type selector row ---
    json jTypeLabels = JsonArray();
    jTypeLabels = JsonArrayInsert(jTypeLabels, JsonString("Golem Gliniany"));
    jTypeLabels = JsonArrayInsert(jTypeLabels, JsonString("Golem Żelazny"));
    jTypeLabels = JsonArrayInsert(jTypeLabels, JsonString("Golem Kostny"));

    json jCombo = NuiCombo(jTypeLabels, NuiBind(GWK_BIND_TYPE_SEL));
    jCombo = NuiHeight(jCombo, fBtnH);

    json jTypeLbl = NuiLabel(JsonString("Typ golema:"), JsonInt(NUI_HALIGN_LEFT), JsonInt(NUI_VALIGN_MIDDLE));
    jTypeLbl = NuiHeight(jTypeLbl, fBtnH);
    jTypeLbl = NuiWidth(jTypeLbl, fLblW);

    json jTypeRow = JsonArray();
    jTypeRow = JsonArrayInsert(jTypeRow, jTypeLbl);
    jTypeRow = JsonArrayInsert(jTypeRow, jCombo);

    // --- Material header ---
    json jMatHeader = NuiLabel(JsonString("Wymagane materiały:"), JsonInt(NUI_HALIGN_LEFT), JsonInt(NUI_VALIGN_MIDDLE));
    jMatHeader = NuiHeight(jMatHeader, fLblH);

    // --- Material rows (A, B, C = main mat, secondary, soul) ---
    json jMatA = GwkMatRow(oPC, GWK_BIND_MAT_A_REQ, GWK_BIND_MAT_A_HAVE, GWK_BIND_MAT_A_OK);
    json jMatB = GwkMatRow(oPC, GWK_BIND_MAT_B_REQ, GWK_BIND_MAT_B_HAVE, GWK_BIND_MAT_B_OK);
    json jMatC = GwkMatRow(oPC, GWK_BIND_MAT_C_REQ, GWK_BIND_MAT_C_HAVE, GWK_BIND_MAT_C_OK);

    // --- Description ---
    json jDesc = NuiLabel(NuiBind(GWK_BIND_DESC), JsonInt(NUI_HALIGN_LEFT), JsonInt(NUI_VALIGN_TOP));
    jDesc = NuiHeight(jDesc, fDescH);

    // --- Forge button ---
    json jForgeBtn = NuiButton(JsonString("Wykuj Golema"));
    jForgeBtn = NuiId(jForgeBtn, GWK_BTN_FORGE);
    jForgeBtn = NuiEnabled(jForgeBtn, NuiBind(GWK_BIND_FORGE_ENA));
    jForgeBtn = NuiHeight(jForgeBtn, fBigH);

    // --- Assemble rows ---
    json jRows = JsonArray();
    jRows = JsonArrayInsert(jRows, CreateEmptyRow(oPC, 8.0));
    jRows = JsonArrayInsert(jRows, NuiRow(jTypeRow));
    jRows = JsonArrayInsert(jRows, CreateEmptyRow(oPC, 10.0));
    jRows = JsonArrayInsert(jRows, NuiRow(JsonArrayInsert(JsonArray(), jMatHeader)));
    jRows = JsonArrayInsert(jRows, jMatA);
    jRows = JsonArrayInsert(jRows, jMatB);
    jRows = JsonArrayInsert(jRows, jMatC);
    jRows = JsonArrayInsert(jRows, CreateEmptyRow(oPC, 10.0));
    jRows = JsonArrayInsert(jRows, NuiRow(JsonArrayInsert(JsonArray(), jDesc)));
    jRows = JsonArrayInsert(jRows, CreateEmptyRow(oPC, 10.0));
    jRows = JsonArrayInsert(jRows, NuiRow(JsonArrayInsert(JsonArray(), jForgeBtn)));
    jRows = JsonArrayInsert(jRows, CreateEmptyRow(oPC, 8.0));

    return NuiCol(jRows);
}

json GwkBuildGolemContent(object oPC)
{
    float fLblH = GetNuiScaleDimension(oPC, 28.0);
    float fBarH = GetNuiScaleDimension(oPC, 22.0);
    float fBtnH = GetNuiScaleDimension(oPC, 34.0);

    // --- Golem name ---
    json jName = NuiLabel(NuiBind(GWK_BIND_GOLEM_NAME), JsonInt(NUI_HALIGN_LEFT), JsonInt(NUI_VALIGN_MIDDLE));
    jName = NuiHeight(jName, fLblH);
    jName = NuiStyleForegroundColor(jName, NuiColor(220, 185, 80));

    // --- HP label + bar ---
    json jHpLbl = NuiLabel(NuiBind(GWK_BIND_GOLEM_HP), JsonInt(NUI_HALIGN_LEFT), JsonInt(NUI_VALIGN_MIDDLE));
    jHpLbl = NuiHeight(jHpLbl, fLblH);

    json jHpBar = NuiProgress(NuiBind(GWK_BIND_GOLEM_BAR));
    jHpBar = NuiHeight(jHpBar, fBarH);

    // --- Repair button ---
    json jRepairBtn = NuiButton(NuiBind(GWK_BIND_REPAIR_LBL));
    jRepairBtn = NuiId(jRepairBtn, GWK_BTN_REPAIR);
    jRepairBtn = NuiEnabled(jRepairBtn, NuiBind(GWK_BIND_REPAIR_ENA));
    jRepairBtn = NuiHeight(jRepairBtn, fBtnH);

    // --- Recall/Dismiss button ---
    json jRecallBtn = NuiButton(NuiBind(GWK_BIND_RECALL_LBL));
    jRecallBtn = NuiId(jRecallBtn, GWK_BTN_RECALL);
    jRecallBtn = NuiHeight(jRecallBtn, fBtnH);

    // --- Destroy button ---
    json jDestroyBtn = NuiButton(JsonString("Rozbij Golema"));
    jDestroyBtn = NuiId(jDestroyBtn, GWK_BTN_DESTROY);
    jDestroyBtn = NuiHeight(jDestroyBtn, fBtnH);
    jDestroyBtn = NuiStyleForegroundColor(jDestroyBtn, NuiColor(190, 60, 60));

    // --- No-golem placeholder ---
    json jNoGolemLbl = NuiLabel(
        JsonString("Nie posiadasz golema. Przejdź do zakładki Wykuwanie."),
        JsonInt(NUI_HALIGN_CENTER), JsonInt(NUI_VALIGN_MIDDLE));

    // Both the "no golem" notice and the golem-detail rows are always in the layout.
    // NuiVisible binds ("gwk_no_golem_vis" / "gwk_has_golem_vis") set by
    // GwkFeedGolemSection control which is rendered.
    json jAllRows = JsonArray();
    jAllRows = JsonArrayInsert(jAllRows, CreateEmptyRow(oPC, 10.0));
    // No-golem notice row (visible=bind)
    json jNoticeRow = NuiRow(JsonArrayInsert(JsonArray(),
        NuiHeight(
            NuiVisible(jNoGolemLbl, NuiBind("gwk_no_golem_vis")),
            GetNuiScaleDimension(oPC, 32.0))));
    jAllRows = JsonArrayInsert(jAllRows, jNoticeRow);
    // Golem detail rows (each wrapped in NuiVisible)
    json jNameRow = NuiRow(JsonArrayInsert(JsonArray(), NuiVisible(jName, NuiBind("gwk_has_golem_vis"))));
    json jHpLblRow= NuiRow(JsonArrayInsert(JsonArray(), NuiVisible(jHpLbl, NuiBind("gwk_has_golem_vis"))));
    json jHpBarRow= NuiRow(JsonArrayInsert(JsonArray(), NuiVisible(jHpBar, NuiBind("gwk_has_golem_vis"))));
    json jRepRow  = NuiRow(JsonArrayInsert(JsonArray(), NuiVisible(jRepairBtn, NuiBind("gwk_has_golem_vis"))));
    json jRecRow  = NuiRow(JsonArrayInsert(JsonArray(), NuiVisible(jRecallBtn, NuiBind("gwk_has_golem_vis"))));
    json jDesRow  = NuiRow(JsonArrayInsert(JsonArray(), NuiVisible(jDestroyBtn, NuiBind("gwk_has_golem_vis"))));
    jAllRows = JsonArrayInsert(jAllRows, CreateEmptyRow(oPC, 6.0));
    jAllRows = JsonArrayInsert(jAllRows, jNameRow);
    jAllRows = JsonArrayInsert(jAllRows, CreateEmptyRow(oPC, 4.0));
    jAllRows = JsonArrayInsert(jAllRows, jHpLblRow);
    jAllRows = JsonArrayInsert(jAllRows, jHpBarRow);
    jAllRows = JsonArrayInsert(jAllRows, CreateEmptyRow(oPC, 10.0));
    jAllRows = JsonArrayInsert(jAllRows, jRepRow);
    jAllRows = JsonArrayInsert(jAllRows, CreateEmptyRow(oPC, 5.0));
    jAllRows = JsonArrayInsert(jAllRows, jRecRow);
    jAllRows = JsonArrayInsert(jAllRows, CreateEmptyRow(oPC, 5.0));
    jAllRows = JsonArrayInsert(jAllRows, jDesRow);

    return NuiCol(jAllRows);
}

// Outer window frame: tab buttons + content group (layout set dynamically)
json GwkBuildOuterLayout(object oPC)
{
    float fTabH = GetNuiScaleDimension(oPC, 36.0);

    json jTabForge = NuiButton(JsonString("Wykuwanie"));
    jTabForge = NuiId(jTabForge, GWK_BTN_TAB_FORGE);
    jTabForge = NuiHeight(jTabForge, fTabH);

    json jTabGolem = NuiButton(JsonString("Mój Golem"));
    jTabGolem = NuiId(jTabGolem, GWK_BTN_TAB_GOLEM);
    jTabGolem = NuiHeight(jTabGolem, fTabH);

    json jTabArr = JsonArray();
    jTabArr = JsonArrayInsert(jTabArr, jTabForge);
    jTabArr = JsonArrayInsert(jTabArr, jTabGolem);
    json jTabRow = NuiRow(jTabArr);

    // Content group — populated dynamically via NuiSetGroupLayout
    json jContentGrp = NuiGroup(NuiSpacer(), NUI_SCROLLBARS_NONE, NUI_SCROLLBARS_NONE);
    jContentGrp = NuiId(jContentGrp, GWK_GRP_CONTENT);

    json jMainRows = JsonArray();
    jMainRows = JsonArrayInsert(jMainRows, jTabRow);
    jMainRows = JsonArrayInsert(jMainRows, jContentGrp);

    return NuiWindow(
        NuiCol(jMainRows),
        JsonString("Warsztat Golemisty"),
        NuiRect(-1.0, -1.0, GetNuiScaleDimension(oPC, GWK_W), GetNuiScaleDimension(oPC, GWK_H)),
        JsonBool(FALSE),
        JsonBool(FALSE),
        JsonBool(TRUE),
        JsonBool(FALSE),
        JsonBool(TRUE)
    );
}

// ----------------------------------------------------------------
// Open / tab switching
// ----------------------------------------------------------------

void GwkOpenWorkshop(object oPC)
{
    int nToken = NuiFindWindow(oPC, GWK_WINDOW);
    if(nToken != 0)
    {
        // Already open; refresh current tab
        int nTab = GetLocalInt(oPC, GWK_LVAR_TAB);
        if(nTab == 0) GwkFeedForgeSection(oPC, nToken);
        else          GwkFeedGolemSection(oPC, nToken);
        return;
    }

    json jWindow = GwkBuildOuterLayout(oPC);
    nToken = NuiCreate(oPC, jWindow, GWK_WINDOW, GWK_EV_SCRIPT);
    if(nToken == 0) return;

    SetLocalInt(oPC, GWK_LVAR_TAB, 0);
    GwkSwitchTab(oPC, nToken, 0);
}

void GwkSwitchTab(object oPC, int nToken, int nTab)
{
    SetLocalInt(oPC, GWK_LVAR_TAB, nTab);

    if(nTab == 0)
    {
        NuiSetGroupLayout(oPC, nToken, GWK_GRP_CONTENT, GwkBuildForgeContent(oPC));
        // Initialize combo labels (static — same each time)
        NuiSetBind(oPC, nToken, GWK_BIND_TYPE_SEL, JsonInt(GetLocalInt(oPC, "GWK_LAST_TYPE_SEL")));
        GwkFeedForgeSection(oPC, nToken);
    }
    else
    {
        NuiSetGroupLayout(oPC, nToken, GWK_GRP_CONTENT, GwkBuildGolemContent(oPC));
        GwkFeedGolemSection(oPC, nToken);
    }
}

// ----------------------------------------------------------------
// Bind population
// ----------------------------------------------------------------

void GwkFeedForgeSection(object oPC, int nToken)
{
    int nType = JsonGetInt(NuiGetBind(oPC, nToken, GWK_BIND_TYPE_SEL));
    SetLocalInt(oPC, "GWK_LAST_TYPE_SEL", nType);

    int nNeedClay = GwkGetMatClay(nType);
    int nNeedIron = GwkGetMatIron(nType);
    int nNeedBone = GwkGetMatBone(nType);

    int nHaveClay = GwkCountItem(oPC, GWK_ITEM_CLAY);
    int nHaveIron = GwkCountItem(oPC, GWK_ITEM_IRON);
    int nHaveBone = GwkCountItem(oPC, GWK_ITEM_BONE);
    int nHaveSoul = GwkCountItem(oPC, GWK_ITEM_SOUL);

    int bOkAll = TRUE;

    // Row A — primary material
    string sNameA;
    int nNeedA, nHaveA;
    if(nType == GWK_TYPE_BONE) { sNameA = "Fragment kości"; nNeedA = nNeedBone; nHaveA = nHaveBone; }
    else                        { sNameA = "Bryła gliny";    nNeedA = nNeedClay; nHaveA = nHaveClay; }
    NuiSetBind(oPC, nToken, GWK_BIND_MAT_A_REQ,  JsonString(sNameA + " (" + IntToString(nNeedA) + "x)"));
    NuiSetBind(oPC, nToken, GWK_BIND_MAT_A_HAVE, JsonString("Posiadasz: " + IntToString(nHaveA)));
    int bOkA = (nHaveA >= nNeedA);
    NuiSetBind(oPC, nToken, GWK_BIND_MAT_A_OK, bOkA ? NuiColor(110, 200, 90) : NuiColor(210, 70, 70));
    if(!bOkA) bOkAll = FALSE;

    // Row B — secondary material (iron only, else empty)
    if(nNeedIron > 0)
    {
        NuiSetBind(oPC, nToken, GWK_BIND_MAT_B_REQ,  JsonString("Odłamek żelaza (" + IntToString(nNeedIron) + "x)"));
        NuiSetBind(oPC, nToken, GWK_BIND_MAT_B_HAVE, JsonString("Posiadasz: " + IntToString(nHaveIron)));
        int bOkB = (nHaveIron >= nNeedIron);
        NuiSetBind(oPC, nToken, GWK_BIND_MAT_B_OK, bOkB ? NuiColor(110, 200, 90) : NuiColor(210, 70, 70));
        if(!bOkB) bOkAll = FALSE;
    }
    else
    {
        NuiSetBind(oPC, nToken, GWK_BIND_MAT_B_REQ,  JsonString(""));
        NuiSetBind(oPC, nToken, GWK_BIND_MAT_B_HAVE, JsonString(""));
        NuiSetBind(oPC, nToken, GWK_BIND_MAT_B_OK,   NuiColor(100, 100, 100));
    }

    // Row C — soul fragment (always required)
    NuiSetBind(oPC, nToken, GWK_BIND_MAT_C_REQ,  JsonString("Fragment duszy (1x)"));
    NuiSetBind(oPC, nToken, GWK_BIND_MAT_C_HAVE, JsonString("Posiadasz: " + IntToString(nHaveSoul)));
    int bOkC = (nHaveSoul >= 1);
    NuiSetBind(oPC, nToken, GWK_BIND_MAT_C_OK, bOkC ? NuiColor(110, 200, 90) : NuiColor(210, 70, 70));
    if(!bOkC) bOkAll = FALSE;

    NuiSetBind(oPC, nToken, GWK_BIND_DESC, JsonString(GwkGetTypeDesc(nType)));
    NuiSetBind(oPC, nToken, GWK_BIND_FORGE_ENA, JsonBool(bOkAll && !GwkHasGolem(oPC)));
}

void GwkFeedGolemSection(object oPC, int nToken)
{
    json jData   = GwkLoadGolem(oPC);
    int bHasGolem = JsonGetType(jData) != JSON_TYPE_NULL;

    NuiSetBind(oPC, nToken, "gwk_no_golem_vis",  JsonBool(!bHasGolem));
    NuiSetBind(oPC, nToken, "gwk_has_golem_vis", JsonBool(bHasGolem));

    if(!bHasGolem) return;

    int nType   = JsonGetInt(JsonObjectGet(jData, "type"));
    int nCurHp  = JsonGetInt(JsonObjectGet(jData, "current_hp"));
    int nMaxHp  = JsonGetInt(JsonObjectGet(jData, "max_hp"));

    // If golem is live, read its actual HP
    object oGolem = GwkFindGolem(oPC);
    if(GetIsObjectValid(oGolem))
    {
        nCurHp = GetCurrentHitPoints(oGolem);
        nMaxHp = GetMaxHitPoints(oGolem);
    }

    NuiSetBind(oPC, nToken, GWK_BIND_GOLEM_NAME, JsonString(GwkGetTypeName(nType)));
    NuiSetBind(oPC, nToken, GWK_BIND_GOLEM_HP,
        JsonString("Żywotność: " + IntToString(nCurHp) + " / " + IntToString(nMaxHp)));

    float fBar = nMaxHp > 0 ? IntToFloat(nCurHp) / IntToFloat(nMaxHp) : 0.0;
    NuiSetBind(oPC, nToken, GWK_BIND_GOLEM_BAR, JsonFloat(fBar));

    // Repair label
    int nRClay = GwkGetRepairClay(nType);
    int nRIron = GwkGetRepairIron(nType);
    int nRBone = GwkGetRepairBone(nType);
    string sRepairLbl = "Napraw — ";
    if(nRClay > 0) sRepairLbl += IntToString(nRClay) + "x glina, ";
    if(nRIron > 0) sRepairLbl += IntToString(nRIron) + "x żelazo, ";
    if(nRBone > 0) sRepairLbl += IntToString(nRBone) + "x kość, ";
    sRepairLbl += "1x dusza";
    NuiSetBind(oPC, nToken, GWK_BIND_REPAIR_LBL, JsonString(sRepairLbl));

    int bNeedRepair = (nCurHp < nMaxHp);
    int bHasMats    = TRUE;
    if(nRClay > 0 && GwkCountItem(oPC, GWK_ITEM_CLAY) < nRClay) bHasMats = FALSE;
    if(nRIron > 0 && GwkCountItem(oPC, GWK_ITEM_IRON) < nRIron) bHasMats = FALSE;
    if(nRBone > 0 && GwkCountItem(oPC, GWK_ITEM_BONE) < nRBone) bHasMats = FALSE;
    if(GwkCountItem(oPC, GWK_ITEM_SOUL) < 1)                    bHasMats = FALSE;
    NuiSetBind(oPC, nToken, GWK_BIND_REPAIR_ENA, JsonBool(bNeedRepair && bHasMats));

    // Recall/dismiss label
    string sRecall = GetIsObjectValid(oGolem) ? "Odpędź Golema" : "Wezwij Golema";
    NuiSetBind(oPC, nToken, GWK_BIND_RECALL_LBL, JsonString(sRecall));
}

// ----------------------------------------------------------------
// Actions
// ----------------------------------------------------------------

void GwkDoForge(object oPC, int nToken, int nType)
{
    if(GwkHasGolem(oPC))
    {
        SendMessageToPC(oPC, "[Warsztat] Możesz posiadać tylko jednego golema naraz.");
        return;
    }

    int nNeedClay = GwkGetMatClay(nType);
    int nNeedIron = GwkGetMatIron(nType);
    int nNeedBone = GwkGetMatBone(nType);

    if(nNeedClay > 0 && GwkCountItem(oPC, GWK_ITEM_CLAY) < nNeedClay)
    { SendMessageToPC(oPC, "[Warsztat] Brakuje brył gliny."); GwkFeedForgeSection(oPC, nToken); return; }
    if(nNeedIron > 0 && GwkCountItem(oPC, GWK_ITEM_IRON) < nNeedIron)
    { SendMessageToPC(oPC, "[Warsztat] Brakuje odłamków żelaza."); GwkFeedForgeSection(oPC, nToken); return; }
    if(nNeedBone > 0 && GwkCountItem(oPC, GWK_ITEM_BONE) < nNeedBone)
    { SendMessageToPC(oPC, "[Warsztat] Brakuje fragmentów kości."); GwkFeedForgeSection(oPC, nToken); return; }
    if(GwkCountItem(oPC, GWK_ITEM_SOUL) < 1)
    { SendMessageToPC(oPC, "[Warsztat] Brakuje fragmentu duszy."); GwkFeedForgeSection(oPC, nToken); return; }

    GwkTakeItem(oPC, GWK_ITEM_CLAY, nNeedClay);
    GwkTakeItem(oPC, GWK_ITEM_IRON, nNeedIron);
    GwkTakeItem(oPC, GWK_ITEM_BONE, nNeedBone);
    GwkTakeItem(oPC, GWK_ITEM_SOUL, 1);

    object oGolem = CreateObject(OBJECT_TYPE_CREATURE, GwkGetResRef(nType), GetLocation(oPC), FALSE);
    if(!GetIsObjectValid(oGolem))
    {
        SendMessageToPC(oPC, "[Warsztat] Duch odrzucił materiały. Składniki przepadły w próżni.");
        return;
    }

    SetLocalInt(oGolem, GWK_GOLEM_FLAG,     1);
    SetLocalInt(oGolem, GWK_GOLEM_TYPE_VAR, nType);

    // Heal to full so we start from a clean baseline
    ApplyEffectToObject(DURATION_TYPE_INSTANT, EffectHeal(GetMaxHitPoints(oGolem)), oGolem);

    int nActualMax = GetMaxHitPoints(oGolem);
    AddHenchman(oPC, oGolem);
    GwkSaveGolem(oPC, nType, nActualMax, nActualMax, TRUE);

    FloatingTextStringOnCreature("Pieczęć duszy wypełnia formę mroczną energią...", oPC, FALSE);
    SendMessageToPC(oPC, "[Warsztat] " + GwkGetTypeName(nType) + " gotowy do służby.");

    // Switch to My Golem tab
    GwkSwitchTab(oPC, nToken, 1);
}

void GwkDoRepair(object oPC, int nToken)
{
    json jData = GwkLoadGolem(oPC);
    if(JsonGetType(jData) == JSON_TYPE_NULL) return;

    int nType  = JsonGetInt(JsonObjectGet(jData, "type"));
    int nMaxHp = JsonGetInt(JsonObjectGet(jData, "max_hp"));

    object oGolem = GwkFindGolem(oPC);
    int nCurHp = GetIsObjectValid(oGolem) ? GetCurrentHitPoints(oGolem) : JsonGetInt(JsonObjectGet(jData, "current_hp"));

    if(nCurHp >= nMaxHp) { SendMessageToPC(oPC, "[Warsztat] Golem jest w pełni sił."); return; }

    int nRClay = GwkGetRepairClay(nType);
    int nRIron = GwkGetRepairIron(nType);
    int nRBone = GwkGetRepairBone(nType);

    if(nRClay > 0 && GwkCountItem(oPC, GWK_ITEM_CLAY) < nRClay) { SendMessageToPC(oPC, "[Warsztat] Brakuje gliny."); return; }
    if(nRIron > 0 && GwkCountItem(oPC, GWK_ITEM_IRON) < nRIron) { SendMessageToPC(oPC, "[Warsztat] Brakuje żelaza."); return; }
    if(nRBone > 0 && GwkCountItem(oPC, GWK_ITEM_BONE) < nRBone) { SendMessageToPC(oPC, "[Warsztat] Brakuje kości."); return; }
    if(GwkCountItem(oPC, GWK_ITEM_SOUL) < 1) { SendMessageToPC(oPC, "[Warsztat] Brakuje fragmentu duszy."); return; }

    GwkTakeItem(oPC, GWK_ITEM_CLAY, nRClay);
    GwkTakeItem(oPC, GWK_ITEM_IRON, nRIron);
    GwkTakeItem(oPC, GWK_ITEM_BONE, nRBone);
    GwkTakeItem(oPC, GWK_ITEM_SOUL, 1);

    if(GetIsObjectValid(oGolem))
    {
        int nHeal = nMaxHp - GetCurrentHitPoints(oGolem);
        if(nHeal > 0) ApplyEffectToObject(DURATION_TYPE_INSTANT, EffectHeal(nHeal), oGolem);
    }
    GwkUpdateHp(oPC, nMaxHp);

    FloatingTextStringOnCreature("Rysy i pęknięcia wypełniają się na twoich oczach...", oPC, FALSE);
    SendMessageToPC(oPC, "[Warsztat] Golem naprawiony. Pieczęć duszy rozbłysła.");
    GwkFeedGolemSection(oPC, nToken);
}

void GwkDoRecall(object oPC, int nToken)
{
    json jData = GwkLoadGolem(oPC);
    if(JsonGetType(jData) == JSON_TYPE_NULL) return;

    object oGolem = GwkFindGolem(oPC);

    if(GetIsObjectValid(oGolem))
    {
        // Dismiss
        int nCurHp = GetCurrentHitPoints(oGolem);
        GwkUpdateHp(oPC, nCurHp);
        GwkSetActive(oPC, FALSE);
        RemoveHenchman(oPC, oGolem);
        DestroyObject(oGolem);
        FloatingTextStringOnCreature("Posłusznik odpada bezwładnie, czekając na wezwanie...", oPC, FALSE);
        SendMessageToPC(oPC, "[Warsztat] Golem uśpiony. Jego rany zostały zapamiętane.");
    }
    else
    {
        // Recall
        int nType  = JsonGetInt(JsonObjectGet(jData, "type"));
        int nCurHp = JsonGetInt(JsonObjectGet(jData, "current_hp"));
        int nMaxHp = JsonGetInt(JsonObjectGet(jData, "max_hp"));

        object oNew = CreateObject(OBJECT_TYPE_CREATURE, GwkGetResRef(nType), GetLocation(oPC), FALSE);
        if(!GetIsObjectValid(oNew)) { SendMessageToPC(oPC, "[Warsztat] Nie udało się przywołać golema."); return; }

        SetLocalInt(oNew, GWK_GOLEM_FLAG,     1);
        SetLocalInt(oNew, GWK_GOLEM_TYPE_VAR, nType);

        // Restore to stored HP
        ApplyEffectToObject(DURATION_TYPE_INSTANT, EffectHeal(9999), oNew);
        int nActMax = GetMaxHitPoints(oNew);
        if(nCurHp < nActMax)
        {
            int nDmg = nActMax - nCurHp;
            ApplyEffectToObject(DURATION_TYPE_INSTANT, EffectDamage(nDmg, DAMAGE_TYPE_MAGICAL), oNew);
        }

        AddHenchman(oPC, oNew);
        GwkSetActive(oPC, TRUE);
        FloatingTextStringOnCreature("Ciemna esencja ożywia uśpioną formę...", oPC, FALSE);
        SendMessageToPC(oPC, "[Warsztat] " + GwkGetTypeName(nType) + " wznowił służbę.");
    }

    GwkFeedGolemSection(oPC, nToken);
}

void GwkDoDestroy(object oPC, int nToken)
{
    json jData = GwkLoadGolem(oPC);
    if(JsonGetType(jData) == JSON_TYPE_NULL) return;

    int nType = JsonGetInt(JsonObjectGet(jData, "type"));

    // Return half forge materials to PC
    int nRClay = GwkGetMatClay(nType) / 2;
    int nRIron = GwkGetMatIron(nType) / 2;
    int nRBone = GwkGetMatBone(nType) / 2;
    if(nRClay > 0) CreateItemOnObject(GWK_ITEM_CLAY, oPC, nRClay);
    if(nRIron > 0) CreateItemOnObject(GWK_ITEM_IRON, oPC, nRIron);
    if(nRBone > 0) CreateItemOnObject(GWK_ITEM_BONE, oPC, nRBone);

    object oGolem = GwkFindGolem(oPC);
    if(GetIsObjectValid(oGolem))
    {
        RemoveHenchman(oPC, oGolem);
        DestroyObject(oGolem);
    }

    GwkDeleteGolem(oPC);
    FloatingTextStringOnCreature("Konstrukt rozsypuje się w proch i milczenie...", oPC, FALSE);
    SendMessageToPC(oPC, "[Warsztat] Golem rozbity. Część materiałów odzyskana.");

    GwkSwitchTab(oPC, nToken, 1);
}

// ----------------------------------------------------------------
// Auto-recall on server enter
// ----------------------------------------------------------------

void GwkAutoRecall(object oPC)
{
    if(!GetIsObjectValid(oPC)) return;

    json jData = GwkLoadGolem(oPC);
    if(JsonGetType(jData) == JSON_TYPE_NULL) return;
    if(!JsonGetInt(JsonObjectGet(jData, "is_active"))) return;

    int nType  = JsonGetInt(JsonObjectGet(jData, "type"));
    int nCurHp = JsonGetInt(JsonObjectGet(jData, "current_hp"));
    int nMaxHp = JsonGetInt(JsonObjectGet(jData, "max_hp"));

    object oNew = CreateObject(OBJECT_TYPE_CREATURE, GwkGetResRef(nType), GetLocation(oPC), FALSE);
    if(!GetIsObjectValid(oNew)) { GwkSetActive(oPC, FALSE); return; }

    SetLocalInt(oNew, GWK_GOLEM_FLAG,     1);
    SetLocalInt(oNew, GWK_GOLEM_TYPE_VAR, nType);

    ApplyEffectToObject(DURATION_TYPE_INSTANT, EffectHeal(9999), oNew);
    int nActMax = GetMaxHitPoints(oNew);
    if(nCurHp < nActMax)
    {
        int nDmg = nActMax - nCurHp;
        ApplyEffectToObject(DURATION_TYPE_INSTANT, EffectDamage(nDmg, DAMAGE_TYPE_MAGICAL), oNew);
    }

    AddHenchman(oPC, oNew);
    SendMessageToPC(oPC, "[Warsztat] Twój golem odnajduje cię po powrocie.");
}
