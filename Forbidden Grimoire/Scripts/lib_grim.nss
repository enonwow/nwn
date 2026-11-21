#include "lib_grim_def"

// ----------------------------------------------------------------
// Fragment inventory utilities
// ----------------------------------------------------------------

// Aggregates fragment counts from PC inventory.
// Returns JsonArray of {type, tier, total} for every type+tier found (count > 0).
json GrimBuildFragRows(object oPC)
{
    // Accumulate raw counts using a JsonObject keyed "T_R"
    json jMap = JsonObject();
    object oItem = GetFirstItemInInventory(oPC);
    while(GetIsObjectValid(oItem))
    {
        string sTag = GetTag(oItem);
        int nPfxLen = GetStringLength(GRIM_FRAG_PREFIX);
        if(GetStringLeft(sTag, nPfxLen) == GRIM_FRAG_PREFIX)
        {
            string sPart  = GetStringRight(sTag, GetStringLength(sTag) - nPfxLen);
            int    nUnder = FindSubString(sPart, "_");
            if(nUnder >= 0)
            {
                int nType = StringToInt(GetStringLeft(sPart, nUnder));
                int nTier = StringToInt(GetStringRight(sPart, GetStringLength(sPart) - nUnder - 1));
                if(nType >= 0 && nType < GRIM_TYPE_COUNT && nTier >= 1 && nTier <= 3)
                {
                    string sKey = IntToString(nType) + "_" + IntToString(nTier);
                    int nPrev   = JsonGetInt(JsonObjectGet(jMap, sKey));
                    jMap = JsonObjectSet(jMap, sKey, JsonInt(nPrev + GetItemStackSize(oItem)));
                }
            }
        }
        oItem = GetNextItemInInventory(oPC);
    }

    // Build display-order list (type 0..4, tier 1..3), skip zeroes
    json jRows = JsonArray();
    int nType;
    for(nType = 0; nType < GRIM_TYPE_COUNT; nType++)
    {
        int nTier;
        for(nTier = 1; nTier <= 3; nTier++)
        {
            string sKey  = IntToString(nType) + "_" + IntToString(nTier);
            int    nTotal = JsonGetInt(JsonObjectGet(jMap, sKey));
            if(nTotal > 0)
            {
                json jRow = JsonObject();
                jRow = JsonObjectSet(jRow, "type",  JsonInt(nType));
                jRow = JsonObjectSet(jRow, "tier",  JsonInt(nTier));
                jRow = JsonObjectSet(jRow, "total", JsonInt(nTotal));
                jRows = JsonArrayInsert(jRows, jRow);
            }
        }
    }
    return jRows;
}

// How many of {type, tier} are currently in the selected list
int GrimSelectedCount(json jSel, int nType, int nTier)
{
    int nCount = 0;
    int i;
    for(i = 0; i < JsonGetLength(jSel); i++)
    {
        json jS = JsonArrayGet(jSel, i);
        if(JsonGetInt(JsonObjectGet(jS, "type")) == nType &&
           JsonGetInt(JsonObjectGet(jS, "tier")) == nTier)
            nCount++;
    }
    return nCount;
}

// Find and consume one fragment of given type+tier from PC inventory.
// Decrements stack or destroys item.
int GrimConsumeFragment(object oPC, int nType, int nTier)
{
    string sTag  = GrimFragTag(nType, nTier);
    object oItem = GetFirstItemInInventory(oPC);
    while(GetIsObjectValid(oItem))
    {
        if(GetTag(oItem) == sTag)
        {
            int nStack = GetItemStackSize(oItem);
            if(nStack <= 1)
                DestroyObject(oItem);
            else
                SetItemStackSize(oItem, nStack - 1);
            return TRUE;
        }
        oItem = GetNextItemInInventory(oPC);
    }
    return FALSE;
}

// ----------------------------------------------------------------
// Effect application
// ----------------------------------------------------------------

void GrimApplyEffect(object oPC, int nEffectId)
{
    object oEnemy = GetNearestCreature(CREATURE_TYPE_REPUTATION, REPUTATION_TYPE_ENEMY,
                                       oPC, 1, CREATURE_TYPE_PERCEPTION, PERCEPTION_SEEN);
    int bHasEnemy = GetIsObjectValid(oEnemy);

    switch(nEffectId)
    {
        case 1: // Kula Ognia — fire burst on nearest visible enemy
            if(bHasEnemy)
            {
                ApplyEffectToObject(DURATION_TYPE_INSTANT,
                    EffectDamage(d6(6), DAMAGE_TYPE_FIRE), oEnemy);
                ApplyEffectToObject(DURATION_TYPE_TEMPORARY,
                    EffectVisualEffect(VFX_IMP_FLAME_M), oEnemy, 0.5);
            }
            else
                ApplyEffectAtLocation(DURATION_TYPE_TEMPORARY,
                    EffectVisualEffect(VFX_IMP_FLAME_M), GetLocation(oPC), 0.0);
            FloatingTextStringOnCreature("Kula Ognia!", oPC, FALSE);
            break;

        case 2: // Lodowy Uścisk — slow + cold damage
            if(bHasEnemy)
            {
                ApplyEffectToObject(DURATION_TYPE_INSTANT,
                    EffectDamage(d6(4), DAMAGE_TYPE_COLD), oEnemy);
                ApplyEffectToObject(DURATION_TYPE_TEMPORARY,
                    EffectSlow(), oEnemy, 30.0);
                ApplyEffectToObject(DURATION_TYPE_TEMPORARY,
                    EffectVisualEffect(VFX_DUR_FREEZE_ANIMATION), oEnemy, 6.0);
            }
            FloatingTextStringOnCreature("Lodowy Uścisk!", oPC, FALSE);
            break;

        case 3: // Zasłona Mroku — blind + daze
            if(bHasEnemy)
            {
                effect eLink = EffectLinkEffects(EffectBlindness(), EffectDazed());
                ApplyEffectToObject(DURATION_TYPE_TEMPORARY, eLink, oEnemy, 12.0);
            }
            FloatingTextStringOnCreature("Zasłona Mroku!", oPC, FALSE);
            break;

        case 4: // Pustka Rozdarcia — heavy magic damage
            if(bHasEnemy)
                ApplyEffectToObject(DURATION_TYPE_INSTANT,
                    EffectDamage(d6(8), DAMAGE_TYPE_MAGICAL), oEnemy);
            FloatingTextStringOnCreature("Pustka Rozdarcia!", oPC, FALSE);
            break;

        case 5: // Tchnięcie Życia — self heal
            ApplyEffectToObject(DURATION_TYPE_INSTANT,
                EffectHeal(d6(6)), oPC);
            ApplyEffectAtLocation(DURATION_TYPE_TEMPORARY,
                EffectVisualEffect(VFX_IMP_HEALING_L), GetLocation(oPC), 0.0);
            FloatingTextStringOnCreature("Tchnięcie Życia!", oPC, FALSE);
            break;

        case 6: // Żar Krwi — fire damage buff on self
        {
            effect eFire = EffectDamageBonus(DAMAGE_BONUS_2d6, DAMAGE_TYPE_FIRE);
            effect eVfx  = EffectVisualEffect(VFX_DUR_FIRE_WEIRD_SM);
            ApplyEffectToObject(DURATION_TYPE_TEMPORARY,
                EffectLinkEffects(eFire, eVfx), oPC, 60.0);
            FloatingTextStringOnCreature("Żar Krwi!", oPC, FALSE);
            break;
        }

        case 7: // Widmo Zimy — fear + slow on enemy
            if(bHasEnemy)
            {
                effect eFear = EffectLinkEffects(EffectFrightened(), EffectSlow());
                ApplyEffectToObject(DURATION_TYPE_TEMPORARY, eFear, oEnemy, 15.0);
            }
            FloatingTextStringOnCreature("Widmo Zimy!", oPC, FALSE);
            break;

        case 8: // Rozdarcie Duszy — negative energy AoE, 10m
        {
            object oTarget = GetFirstObjectInShape(SHAPE_SPHERE, 10.0,
                GetLocation(oPC), TRUE, OBJECT_TYPE_CREATURE);
            while(GetIsObjectValid(oTarget))
            {
                if(GetIsEnemy(oTarget, oPC))
                {
                    ApplyEffectToObject(DURATION_TYPE_INSTANT,
                        EffectDamage(d6(10), DAMAGE_TYPE_NEGATIVE), oTarget);
                    ApplyEffectToObject(DURATION_TYPE_TEMPORARY,
                        EffectVisualEffect(VFX_IMP_DEATH), oTarget, 0.5);
                }
                oTarget = GetNextObjectInShape(SHAPE_SPHERE, 10.0,
                    GetLocation(oPC), TRUE, OBJECT_TYPE_CREATURE);
            }
            FloatingTextStringOnCreature("Rozdarcie Duszy!", oPC, FALSE);
            break;
        }
    }
}

// ----------------------------------------------------------------
// Backlash on failed research
// ----------------------------------------------------------------

void GrimApplyBacklash(object oPC)
{
    ApplyEffectToObject(DURATION_TYPE_TEMPORARY,
        EffectVisualEffect(VFX_DUR_MAGIC_RESISTANCE), oPC, 1.0);
    switch(d4())
    {
        case 1:
            ApplyEffectToObject(DURATION_TYPE_INSTANT,
                EffectDamage(d6(3), DAMAGE_TYPE_MAGICAL), oPC);
            FloatingTextStringOnCreature("Odrzut archaicznej energii!", oPC, FALSE);
            break;
        case 2:
            ApplyEffectToObject(DURATION_TYPE_TEMPORARY,
                EffectConfused(), oPC, 8.0);
            FloatingTextStringOnCreature("Umysł w zamęcie!", oPC, FALSE);
            break;
        case 3:
            ApplyEffectToObject(DURATION_TYPE_TEMPORARY,
                EffectStunned(), oPC, 4.0);
            FloatingTextStringOnCreature("Ogłuszenie magiczne!", oPC, FALSE);
            break;
        case 4:
            ApplyEffectToObject(DURATION_TYPE_TEMPORARY,
                EffectAbilityDecrease(ABILITY_INTELLIGENCE, 2), oPC, 120.0);
            FloatingTextStringOnCreature("Umysł spalony przez chaos!", oPC, FALSE);
            break;
    }
}

// ----------------------------------------------------------------
// Research logic
// ----------------------------------------------------------------

void GrimDoResearch(object oPC, int nToken)
{
    json jSel = GetLocalJson(oPC, GRIM_LVAR_SEL);
    if(JsonGetType(jSel) != JSON_TYPE_ARRAY || JsonGetLength(jSel) < GRIM_SLOT_COUNT)
    {
        SendMessageToPC(oPC, "[Grimuar] Wybierz " + IntToString(GRIM_SLOT_COUNT) + " fragmenty.");
        return;
    }

    json jF0 = JsonArrayGet(jSel, 0);
    json jF1 = JsonArrayGet(jSel, 1);
    int  nT0  = JsonGetInt(JsonObjectGet(jF0, "type"));
    int  nR0  = JsonGetInt(JsonObjectGet(jF0, "tier"));
    int  nT1  = JsonGetInt(JsonObjectGet(jF1, "type"));
    int  nR1  = JsonGetInt(JsonObjectGet(jF1, "tier"));

    // Consume fragments first (prevents double-submit exploit)
    int bOk0 = GrimConsumeFragment(oPC, nT0, nR0);
    int bOk1 = GrimConsumeFragment(oPC, nT1, nR1);
    if(!bOk0 || !bOk1)
    {
        GrimFeedResult(oPC, nToken, "Fragmenty zniknęły z sakiewki — ktoś wziął je wcześniej.");
        DeleteLocalJson(oPC, GRIM_LVAR_SEL);
        GrimFeedFragmentList(oPC, nToken);
        GrimFeedSlots(oPC, nToken);
        return;
    }

    DeleteLocalJson(oPC, GRIM_LVAR_SEL);
    DeleteLocalJson(oPC, GRIM_LVAR_FRAG_ROWS);

    int nRecipeId = GrimMatchRecipe(nT0, nR0, nT1, nR1);
    int nChance   = GrimResearchChance(oPC);
    int nRoll     = d100();

    if(nRecipeId < 0)
    {
        // Unknown combination — always fails; 30% chance of backlash
        string sResult = "Fragmenty nie rezonują ze sobą.\nWiedza rozpada się w ciemnościach.";
        if(d100() <= 30)
        {
            GrimApplyBacklash(oPC);
            sResult = sResult + "\n\nOdrzut archaicznej energii przewraca zmysły!";
        }
        GrimFeedResult(oPC, nToken, sResult);
        GrimFeedFragmentList(oPC, nToken);
        GrimFeedSlots(oPC, nToken);
        return;
    }

    struct GrimRecipe r = GrimGetRecipe(nRecipeId);

    if(nRoll > nChance)
    {
        // Failure
        string sResult = "Rytuał się nie powiódł (rzut: " + IntToString(nRoll) +
                         " vs " + IntToString(nChance) + ").\nFragmenty rozpadają się w pył.";
        if(d100() <= 25)
        {
            GrimApplyBacklash(oPC);
            sResult = sResult + "\n\nOdrzut energii!";
        }
        GrimFeedResult(oPC, nToken, sResult);
    }
    else
    {
        // Success
        int nUses = GrimRecordDiscovery(oPC, nRecipeId, GRIM_MASTERY_USES);
        GrimApplyEffect(oPC, r.nEffectId);

        string sResult = "\"" + r.sName + "\"\n" + r.sDesc;
        sResult = sResult + "\n\nFormuła odkryta! (" +
                  IntToString(nUses) + "/" + IntToString(GRIM_MASTERY_USES) + " do mistrzostwa)";
        if(nUses >= GRIM_MASTERY_USES)
            sResult = sResult +
                      "\n\nMistrzowskie opanowanie!\nMożesz przywołać tę moc bez fragmentów raz na dobę.";

        GrimFeedResult(oPC, nToken, sResult);
    }

    GrimFeedFragmentList(oPC, nToken);
    GrimFeedSlots(oPC, nToken);
}

// Mastery free cast — called from Codex popup
void GrimDoMasteryCast(object oPC, int nRecipeId)
{
    if(!GrimGetRecipeMastered(oPC, nRecipeId))
    {
        SendMessageToPC(oPC, "[Grimuar] Nie opanowałeś tej formuły.");
        return;
    }
    int nNow  = GrimGetCurrentTime();
    int nLast = GrimGetLastFreeCast(oPC, nRecipeId);
    if(nNow - nLast < GRIM_FREE_CAST_CD)
    {
        int nRemain = GRIM_FREE_CAST_CD - (nNow - nLast);
        SendMessageToPC(oPC, "[Grimuar] Moc nie jest gotowa. Pozostało: " +
                        IntToString(nRemain / 3600) + "h " +
                        IntToString((nRemain % 3600) / 60) + "min.");
        return;
    }
    struct GrimRecipe r = GrimGetRecipe(nRecipeId);
    GrimSetLastFreeCast(oPC, nRecipeId);
    GrimApplyEffect(oPC, r.nEffectId);
    SendMessageToPC(oPC, "[Grimuar] Mistrzowska formuła: \"" + r.sName + "\" przywołana.");

    // Refresh codex so button becomes disabled until CD expires
    GrimOpenCodexWindow(oPC);
}

// ----------------------------------------------------------------
// NUI layout builders
// ----------------------------------------------------------------

json GrimBuildFragList(object oPC)
{
    float fRowH = GetNuiScaleDimension(oPC, 26.0);

    json jNameLbl = NuiLabel(NuiBind(GRIM_BIND_FRAG_NAME),
        JsonInt(NUI_HALIGN_LEFT), JsonInt(NUI_VALIGN_MIDDLE));

    json jTypeLbl = NuiLabel(NuiBind(GRIM_BIND_FRAG_TYPE),
        JsonInt(NUI_HALIGN_CENTER), JsonInt(NUI_VALIGN_MIDDLE));
    jTypeLbl = NuiWidth(jTypeLbl, GetNuiScaleDimension(oPC, 66.0));

    json jAvailLbl = NuiLabel(NuiBind(GRIM_BIND_FRAG_AVAIL),
        JsonInt(NUI_HALIGN_CENTER), JsonInt(NUI_VALIGN_MIDDLE));
    jAvailLbl = NuiWidth(jAvailLbl, GetNuiScaleDimension(oPC, 42.0));

    json jCellRow = JsonArray();
    jCellRow = JsonArrayInsert(jCellRow, jNameLbl);
    jCellRow = JsonArrayInsert(jCellRow, jTypeLbl);
    jCellRow = JsonArrayInsert(jCellRow, jAvailLbl);

    json jCell = NuiGroup(NuiRow(jCellRow), TRUE, NUI_SCROLLBARS_NONE);
    jCell = NuiId(jCell, GRIM_BTN_FRAG_ROW);
    jCell = NuiEncouraged(jCell, NuiBind(GRIM_BIND_FRAG_ENC));

    json jTmpl = JsonArrayInsert(JsonArray(), NuiListTemplateCell(jCell, 0.0, TRUE));
    json jList = NuiList(jTmpl, NuiBind(GRIM_BIND_FRAG_ROWCNT), fRowH);
    jList = NuiHeight(jList, GetNuiScaleDimension(oPC, 295.0));

    return jList;
}

json GrimBuildResearchPanel(object oPC)
{
    float fBtnH    = GetNuiScaleDimension(oPC, 28.0);
    float fLblH    = GetNuiScaleDimension(oPC, 22.0);
    float fResultH = GetNuiScaleDimension(oPC, 150.0);

    json jHdr = NuiLabel(JsonString("Wybrane fragmenty:"),
        JsonInt(NUI_HALIGN_LEFT), JsonInt(NUI_VALIGN_MIDDLE));
    jHdr = NuiHeight(jHdr, fLblH);

    json jSlotCol = JsonArray();
    jSlotCol = JsonArrayInsert(jSlotCol, jHdr);

    int i;
    for(i = 0; i < GRIM_SLOT_COUNT; i++)
    {
        string sSfx = IntToString(i);

        json jSlotLbl = NuiLabel(NuiBind(GRIM_BIND_SLOT_LBL + sSfx),
            JsonInt(NUI_HALIGN_LEFT), JsonInt(NUI_VALIGN_MIDDLE));

        json jClearBtn = NuiButton(JsonString("X"));
        jClearBtn = NuiId(jClearBtn, GRIM_BTN_CLEAR_SLOT + sSfx);
        jClearBtn = NuiEnabled(jClearBtn, NuiBind(GRIM_BIND_SLOT_ENA + sSfx));
        jClearBtn = NuiWidth(jClearBtn, GetNuiScaleDimension(oPC, 26.0));
        jClearBtn = NuiHeight(jClearBtn, fBtnH);

        json jRow = JsonArray();
        jRow = JsonArrayInsert(jRow, jSlotLbl);
        jRow = JsonArrayInsert(jRow, jClearBtn);
        jSlotCol = JsonArrayInsert(jSlotCol, NuiRow(jRow));
    }

    json jResBtn = NuiButton(JsonString("Badaj"));
    jResBtn = NuiId(jResBtn, GRIM_BTN_RESEARCH);
    jResBtn = NuiEnabled(jResBtn, NuiBind(GRIM_BIND_RESEARCH_ENA));
    jResBtn = NuiHeight(jResBtn, fBtnH);

    json jResultTxt = NuiGroup(NuiText(NuiBind(GRIM_BIND_RESULT), FALSE),
        TRUE, NUI_SCROLLBARS_NONE);
    jResultTxt = NuiHeight(jResultTxt, fResultH);

    jSlotCol = JsonArrayInsert(jSlotCol, NuiSpacer());
    jSlotCol = JsonArrayInsert(jSlotCol, jResBtn);
    jSlotCol = JsonArrayInsert(jSlotCol, jResultTxt);

    return NuiCol(jSlotCol);
}

// ----------------------------------------------------------------
// Window create / open
// ----------------------------------------------------------------

void GrimOpenWindow(object oPC)
{
    int nExisting = NuiFindWindow(oPC, GRIM_WINDOW);
    if(nExisting != 0)
    {
        GrimFeedFragmentList(oPC, nExisting);
        return;
    }

    float fCX = (IntToFloat(GetPlayerDeviceProperty(oPC, PLAYER_DEVICE_PROPERTY_GUI_WIDTH)) -
                 GetNuiScaleDimension(oPC, GRIM_W)) / 2.0;
    float fCY = (IntToFloat(GetPlayerDeviceProperty(oPC, PLAYER_DEVICE_PROPERTY_GUI_HEIGHT)) -
                 GetNuiScaleDimension(oPC, GRIM_H)) / 2.0;
    json jGeom = NuiRect(fCX, fCY,
                         GetNuiScaleDimension(oPC, GRIM_W),
                         GetNuiScaleDimension(oPC, GRIM_H));

    float fBtnH = GetNuiScaleDimension(oPC, 28.0);

    // Top bar
    json jTitleLbl = NuiLabel(JsonString("Grimuar Zakazanej Wiedzy"),
        JsonInt(NUI_HALIGN_LEFT), JsonInt(NUI_VALIGN_MIDDLE));
    jTitleLbl = NuiHeight(jTitleLbl, fBtnH);

    json jCodexBtn = NuiButton(JsonString("Kodeks"));
    jCodexBtn = NuiId(jCodexBtn, GRIM_BTN_CODEX);
    jCodexBtn = NuiWidth(jCodexBtn, GetNuiScaleDimension(oPC, 80.0));
    jCodexBtn = NuiHeight(jCodexBtn, fBtnH);

    json jCloseBtn = NuiButton(JsonString("X"));
    jCloseBtn = NuiId(jCloseBtn, GRIM_BTN_CLOSE);
    jCloseBtn = NuiWidth(jCloseBtn, GetNuiScaleDimension(oPC, 30.0));
    jCloseBtn = NuiHeight(jCloseBtn, fBtnH);

    json jTopRow = JsonArray();
    jTopRow = JsonArrayInsert(jTopRow, jTitleLbl);
    jTopRow = JsonArrayInsert(jTopRow, NuiSpacer());
    jTopRow = JsonArrayInsert(jTopRow, jCodexBtn);
    jTopRow = JsonArrayInsert(jTopRow, jCloseBtn);

    // Main content: left list | right research panel
    float fListW = GetNuiScaleDimension(oPC, 320.0);
    json jLeft = NuiWidth(
        NuiCol(JsonArrayInsert(JsonArray(), GrimBuildFragList(oPC))),
        fListW);

    json jContent = JsonArray();
    jContent = JsonArrayInsert(jContent, jLeft);
    jContent = JsonArrayInsert(jContent, GrimBuildResearchPanel(oPC));

    json jRoot = JsonArray();
    jRoot = JsonArrayInsert(jRoot, NuiRow(jTopRow));
    jRoot = JsonArrayInsert(jRoot, NuiRow(jContent));

    json jWin = NuiWindow(NuiCol(jRoot),
        JsonBool(FALSE),
        NuiBind(GRIM_BIND_WIN_GEOM),
        JsonBool(FALSE),
        JsonBool(FALSE),
        JsonBool(FALSE),
        JsonBool(TRUE),
        JsonBool(FALSE));

    int nToken = NuiCreate(oPC, jWin, GRIM_WINDOW, GRIM_EV_SCRIPT);
    NuiSetBind(oPC, nToken, GRIM_BIND_WIN_GEOM, jGeom);

    DeleteLocalJson(oPC, GRIM_LVAR_SEL);
    DeleteLocalJson(oPC, GRIM_LVAR_FRAG_ROWS);

    GrimFeedFragmentList(oPC, nToken);
    GrimFeedSlots(oPC, nToken);
    GrimFeedResult(oPC, nToken, "Umieść dwa fragmenty w gniazdach i naciśnij Badaj.\nFragmenty zostaną skonsumowane niezależnie od wyniku.");
}

// ----------------------------------------------------------------
// Feed functions
// ----------------------------------------------------------------

void GrimFeedFragmentList(object oPC, int nToken)
{
    json jRows = GrimBuildFragRows(oPC);
    SetLocalJson(oPC, GRIM_LVAR_FRAG_ROWS, jRows);
    int nCount = JsonGetLength(jRows);

    json jSel = GetLocalJson(oPC, GRIM_LVAR_SEL);
    if(JsonGetType(jSel) != JSON_TYPE_ARRAY) jSel = JsonArray();

    json jNames  = JsonArray();
    json jTypes  = JsonArray();
    json jAvails = JsonArray();
    json jEncs   = JsonArray();

    int i;
    for(i = 0; i < nCount; i++)
    {
        json jRow  = JsonArrayGet(jRows, i);
        int  nType = JsonGetInt(JsonObjectGet(jRow, "type"));
        int  nTier = JsonGetInt(JsonObjectGet(jRow, "tier"));
        int  nTot  = JsonGetInt(JsonObjectGet(jRow, "total"));
        int  nSelC = GrimSelectedCount(jSel, nType, nTier);
        int  nAvail = nTot - nSelC;

        jNames  = JsonArrayInsert(jNames,  JsonString(GrimFragName(nType, nTier)));
        jTypes  = JsonArrayInsert(jTypes,  JsonString(GrimTypeName(nType)));
        jAvails = JsonArrayInsert(jAvails, JsonString(IntToString(nAvail) + " szt."));
        jEncs   = JsonArrayInsert(jEncs,   JsonBool(nSelC > 0));
    }

    NuiSetBind(oPC, nToken, GRIM_BIND_FRAG_NAME,   jNames);
    NuiSetBind(oPC, nToken, GRIM_BIND_FRAG_TYPE,   jTypes);
    NuiSetBind(oPC, nToken, GRIM_BIND_FRAG_AVAIL,  jAvails);
    NuiSetBind(oPC, nToken, GRIM_BIND_FRAG_ENC,    jEncs);
    NuiSetBind(oPC, nToken, GRIM_BIND_FRAG_ROWCNT, JsonInt(nCount));
}

void GrimFeedSlots(object oPC, int nToken)
{
    json jSel  = GetLocalJson(oPC, GRIM_LVAR_SEL);
    if(JsonGetType(jSel) != JSON_TYPE_ARRAY) jSel = JsonArray();
    int  nSel  = JsonGetLength(jSel);

    int i;
    for(i = 0; i < GRIM_SLOT_COUNT; i++)
    {
        string sSfx = IntToString(i);
        string sLbl;
        int    bFull = (i < nSel);
        if(bFull)
        {
            json jF  = JsonArrayGet(jSel, i);
            int  nTy = JsonGetInt(JsonObjectGet(jF, "type"));
            int  nTr = JsonGetInt(JsonObjectGet(jF, "tier"));
            sLbl = IntToString(i + 1) + ". " + GrimFragName(nTy, nTr);
        }
        else
        {
            sLbl = IntToString(i + 1) + ". — puste —";
        }
        NuiSetBind(oPC, nToken, GRIM_BIND_SLOT_LBL + sSfx, JsonString(sLbl));
        NuiSetBind(oPC, nToken, GRIM_BIND_SLOT_ENA + sSfx, JsonBool(bFull));
    }

    NuiSetBind(oPC, nToken, GRIM_BIND_RESEARCH_ENA, JsonBool(nSel >= GRIM_SLOT_COUNT));
}

void GrimFeedResult(object oPC, int nToken, string sText)
{
    NuiSetBind(oPC, nToken, GRIM_BIND_RESULT, JsonString(sText));
}

// ----------------------------------------------------------------
// Codex popup
// ----------------------------------------------------------------

void GrimOpenCodexWindow(object oPC)
{
    if(NuiFindWindow(oPC, GRIM_WIN_CODEX) != 0)
        NuiDestroy(oPC, NuiFindWindow(oPC, GRIM_WIN_CODEX));

    float fW    = GetNuiScaleDimension(oPC, 560.0);
    float fH    = GetNuiScaleDimension(oPC, 400.0);
    float fRowH = GetNuiScaleDimension(oPC, 32.0);
    float fX    = (IntToFloat(GetPlayerDeviceProperty(oPC, PLAYER_DEVICE_PROPERTY_GUI_WIDTH))  - fW) / 2.0;
    float fY    = (IntToFloat(GetPlayerDeviceProperty(oPC, PLAYER_DEVICE_PROPERTY_GUI_HEIGHT)) - fH) / 2.0;

    // List template: name | requirements | uses/mastery | [cast] button
    json jNameLbl = NuiLabel(NuiBind(GRIM_BIND_COD_NAME),
        JsonInt(NUI_HALIGN_LEFT), JsonInt(NUI_VALIGN_MIDDLE));

    json jReqLbl = NuiLabel(NuiBind(GRIM_BIND_COD_REQ),
        JsonInt(NUI_HALIGN_LEFT), JsonInt(NUI_VALIGN_MIDDLE));
    jReqLbl = NuiWidth(jReqLbl, GetNuiScaleDimension(oPC, 170.0));

    json jUsesLbl = NuiLabel(NuiBind(GRIM_BIND_COD_USES),
        JsonInt(NUI_HALIGN_CENTER), JsonInt(NUI_VALIGN_MIDDLE));
    jUsesLbl = NuiWidth(jUsesLbl, GetNuiScaleDimension(oPC, 60.0));

    json jMastLbl = NuiLabel(NuiBind(GRIM_BIND_COD_MASTER),
        JsonInt(NUI_HALIGN_CENTER), JsonInt(NUI_VALIGN_MIDDLE));
    jMastLbl = NuiWidth(jMastLbl, GetNuiScaleDimension(oPC, 55.0));

    json jCastBtn = NuiButton(JsonString("Przywołaj"));
    jCastBtn = NuiId(jCastBtn, GRIM_BTN_COD_CAST);
    jCastBtn = NuiEnabled(jCastBtn, NuiBind(GRIM_BIND_COD_CAST_ENA));
    jCastBtn = NuiWidth(jCastBtn, GetNuiScaleDimension(oPC, 80.0));
    jCastBtn = NuiHeight(jCastBtn, GetNuiScaleDimension(oPC, 26.0));

    json jRow = JsonArray();
    jRow = JsonArrayInsert(jRow, jNameLbl);
    jRow = JsonArrayInsert(jRow, jReqLbl);
    jRow = JsonArrayInsert(jRow, jUsesLbl);
    jRow = JsonArrayInsert(jRow, jMastLbl);
    jRow = JsonArrayInsert(jRow, jCastBtn);

    json jCell = NuiGroup(NuiRow(jRow), TRUE, NUI_SCROLLBARS_NONE);
    json jTmpl = JsonArrayInsert(JsonArray(), NuiListTemplateCell(jCell, 0.0, TRUE));
    json jList = NuiList(jTmpl, NuiBind(GRIM_BIND_COD_ROWCNT), fRowH);

    json jWin = NuiWindow(NuiCol(JsonArrayInsert(JsonArray(), jList)),
        JsonString("Kodeks Zakazanej Wiedzy"),
        NuiRect(fX, fY, fW, fH),
        JsonBool(FALSE), JsonBool(FALSE), JsonBool(TRUE),
        JsonBool(FALSE), JsonBool(TRUE));

    int nCodToken = NuiCreate(oPC, jWin, GRIM_WIN_CODEX, GRIM_EV_SCRIPT);

    int nNow = GrimGetCurrentTime();

    json jNames    = JsonArray();
    json jReqs     = JsonArray();
    json jUses     = JsonArray();
    json jMasters  = JsonArray();
    json jCastEnas = JsonArray();

    int i;
    for(i = 1; i <= GRIM_RECIPE_COUNT; i++)
    {
        struct GrimRecipe r = GrimGetRecipe(i);
        int  nUses      = GrimGetRecipeUses(oPC, i);
        int  bMastered  = GrimGetRecipeMastered(oPC, i);
        int  nLastFree  = GrimGetLastFreeCast(oPC, i);
        int  bCanCast   = bMastered && (nNow - nLastFree >= GRIM_FREE_CAST_CD);

        jNames    = JsonArrayInsert(jNames,    JsonString(r.sName));
        jReqs     = JsonArrayInsert(jReqs,     JsonString(
            GrimTierName(r.nTier0) + " " + GrimTypeName(r.nType0) +
            " + " +
            GrimTierName(r.nTier1) + " " + GrimTypeName(r.nType1)));
        jUses     = JsonArrayInsert(jUses,     JsonString(
            IntToString(nUses) + "/" + IntToString(GRIM_MASTERY_USES)));
        jMasters  = JsonArrayInsert(jMasters,  JsonString(bMastered ? "Mistrz" : ""));
        jCastEnas = JsonArrayInsert(jCastEnas, JsonBool(bCanCast));
    }

    NuiSetBind(oPC, nCodToken, GRIM_BIND_COD_NAME,    jNames);
    NuiSetBind(oPC, nCodToken, GRIM_BIND_COD_REQ,     jReqs);
    NuiSetBind(oPC, nCodToken, GRIM_BIND_COD_USES,    jUses);
    NuiSetBind(oPC, nCodToken, GRIM_BIND_COD_MASTER,  jMasters);
    NuiSetBind(oPC, nCodToken, GRIM_BIND_COD_CAST_ENA, jCastEnas);
    NuiSetBind(oPC, nCodToken, GRIM_BIND_COD_ROWCNT,  JsonInt(GRIM_RECIPE_COUNT));
}
