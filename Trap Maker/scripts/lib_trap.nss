#include "lib_trap_def"

// ================================================================
// Recipe data — returns JsonArray of recipe objects.
//
// Each recipe:  { type, name, desc, effect_desc, disarm_dc, detect_dc,
//                 comps: [{tag, count}, ...] }
// ================================================================

json TrapGetRecipes()
{
    json jAll = JsonArray();
    json jR;
    json jC;

    // ---- Ostrze Skrytobójcy ----
    jR = JsonObject();
    jR = JsonObjectSet(jR, "type",       JsonString(TRAP_TYPE_BLADE));
    jR = JsonObjectSet(jR, "name",       JsonString("Ostrze Skrytobójcy"));
    jR = JsonObjectSet(jR, "desc",       JsonString("Ukryte w podłodze ostrza wystrzeliwują ku górze, gdy ktoś nadepnie na mechanizm. Sześć żelaznych zębów, jeden los."));
    jR = JsonObjectSet(jR, "effect",     JsonString("2k6+4 obrażeń kłutych"));
    jR = JsonObjectSet(jR, "disarm_dc",  JsonInt(18));
    jR = JsonObjectSet(jR, "detect_dc",  JsonInt(15));
    jC = JsonArray();
    jC = JsonArrayInsert(jC, JsonObjectSet(JsonObjectSet(JsonObject(), "tag", JsonString(TRAP_COMP_BLADE)),  "cnt", JsonInt(2)));
    jC = JsonArrayInsert(jC, JsonObjectSet(JsonObjectSet(JsonObject(), "tag", JsonString(TRAP_COMP_SPRING)), "cnt", JsonInt(1)));
    jR = JsonObjectSet(jR, "comps", jC);
    jAll = JsonArrayInsert(jAll, jR);

    // ---- Zatruta Strzałka ----
    jR = JsonObject();
    jR = JsonObjectSet(jR, "type",       JsonString(TRAP_TYPE_DART));
    jR = JsonObjectSet(jR, "name",       JsonString("Zatruta Strzałka"));
    jR = JsonObjectSet(jR, "desc",       JsonString("Sprężyna katapultuje zatrutą strzałkę prosto w gardło. Trucizna zżera żywotność przez kilka bolesnych minut."));
    jR = JsonObjectSet(jR, "effect",     JsonString("1k4 obrażeń + trucizna (KON -3, 60s)"));
    jR = JsonObjectSet(jR, "disarm_dc",  JsonInt(14));
    jR = JsonObjectSet(jR, "detect_dc",  JsonInt(12));
    jC = JsonArray();
    jC = JsonArrayInsert(jC, JsonObjectSet(JsonObjectSet(JsonObject(), "tag", JsonString(TRAP_COMP_DART)),   "cnt", JsonInt(3)));
    jC = JsonArrayInsert(jC, JsonObjectSet(JsonObjectSet(JsonObject(), "tag", JsonString(TRAP_COMP_POISON)), "cnt", JsonInt(1)));
    jC = JsonArrayInsert(jC, JsonObjectSet(JsonObjectSet(JsonObject(), "tag", JsonString(TRAP_COMP_SPRING)), "cnt", JsonInt(1)));
    jR = JsonObjectSet(jR, "comps", jC);
    jAll = JsonArrayInsert(jAll, jR);

    // ---- Ogniste Więzienie ----
    jR = JsonObject();
    jR = JsonObjectSet(jR, "type",       JsonString(TRAP_TYPE_FLAME));
    jR = JsonObjectSet(jR, "name",       JsonString("Ogniste Więzienie"));
    jR = JsonObjectSet(jR, "desc",       JsonString("Krzemień iskrzy w naprężonej sprężynie, zapalając rozlany olej w ułamku sekundy. Ocalali opowiadają, że czuć to aż za ścianą."));
    jR = JsonObjectSet(jR, "effect",     JsonString("3k6 obrażeń ogniowych"));
    jR = JsonObjectSet(jR, "disarm_dc",  JsonInt(20));
    jR = JsonObjectSet(jR, "detect_dc",  JsonInt(18));
    jC = JsonArray();
    jC = JsonArrayInsert(jC, JsonObjectSet(JsonObjectSet(JsonObject(), "tag", JsonString(TRAP_COMP_OIL)),   "cnt", JsonInt(2)));
    jC = JsonArrayInsert(jC, JsonObjectSet(JsonObjectSet(JsonObject(), "tag", JsonString(TRAP_COMP_FLINT)), "cnt", JsonInt(1)));
    jC = JsonArrayInsert(jC, JsonObjectSet(JsonObjectSet(JsonObject(), "tag", JsonString(TRAP_COMP_SPRING)),"cnt", JsonInt(1)));
    jR = JsonObjectSet(jR, "comps", jC);
    jAll = JsonArrayInsert(jAll, jR);

    // ---- Błyskający Proch ----
    jR = JsonObject();
    jR = JsonObjectSet(jR, "type",       JsonString(TRAP_TYPE_STUN));
    jR = JsonObjectSet(jR, "name",       JsonString("Błyskający Proch"));
    jR = JsonObjectSet(jR, "desc",       JsonString("Fiolka fleszprochu rozbija się i wybucha oślepiającą bielą. Ci, którzy przeżyli, twierdzą, że ich własne imię musiało do nich wracać przez kilka minut."));
    jR = JsonObjectSet(jR, "effect",     JsonString("SIŁ -4, DEX -2 (30s), efekt oślepienia (6s)"));
    jR = JsonObjectSet(jR, "disarm_dc",  JsonInt(16));
    jR = JsonObjectSet(jR, "detect_dc",  JsonInt(14));
    jC = JsonArray();
    jC = JsonArrayInsert(jC, JsonObjectSet(JsonObjectSet(JsonObject(), "tag", JsonString(TRAP_COMP_POWDER)), "cnt", JsonInt(2)));
    jC = JsonArrayInsert(jC, JsonObjectSet(JsonObjectSet(JsonObject(), "tag", JsonString(TRAP_COMP_GLASS)),  "cnt", JsonInt(1)));
    jR = JsonObjectSet(jR, "comps", jC);
    jAll = JsonArrayInsert(jAll, jR);

    // ---- Pułapka Alarmowa ----
    jR = JsonObject();
    jR = JsonObjectSet(jR, "type",       JsonString(TRAP_TYPE_ALARM));
    jR = JsonObjectSet(jR, "name",       JsonString("Pułapka Alarmowa"));
    jR = JsonObjectSet(jR, "desc",       JsonString("Drut naciągowy szarpie dzwonkiem przykutym do ściany. Cichy sam w sobie, lecz strażnicy mają uszy nastawione na ten właśnie dźwięk."));
    jR = JsonObjectSet(jR, "effect",     JsonString("Alert do wszystkich strzeżących w obszarze"));
    jR = JsonObjectSet(jR, "disarm_dc",  JsonInt(12));
    jR = JsonObjectSet(jR, "detect_dc",  JsonInt(10));
    jC = JsonArray();
    jC = JsonArrayInsert(jC, JsonObjectSet(JsonObjectSet(JsonObject(), "tag", JsonString(TRAP_COMP_BELL)),  "cnt", JsonInt(1)));
    jC = JsonArrayInsert(jC, JsonObjectSet(JsonObjectSet(JsonObject(), "tag", JsonString(TRAP_COMP_WIRE)),  "cnt", JsonInt(2)));
    jC = JsonArrayInsert(jC, JsonObjectSet(JsonObjectSet(JsonObject(), "tag", JsonString(TRAP_COMP_SPRING)),"cnt", JsonInt(1)));
    jR = JsonObjectSet(jR, "comps", jC);
    jAll = JsonArrayInsert(jAll, jR);

    // ---- Sidła Łowcy ----
    jR = JsonObject();
    jR = JsonObjectSet(jR, "type",       JsonString(TRAP_TYPE_SNARE));
    jR = JsonObjectSet(jR, "name",       JsonString("Sidła Łowcy"));
    jR = JsonObjectSet(jR, "desc",       JsonString("Stalowe haki zaciskają się na kostce z siłą przeklinającą pościgi. Ofiara pełza, nie biegnie. Idealne do późniejszego odwiedzenia."));
    jR = JsonObjectSet(jR, "effect",     JsonString("Ruch -75% (40s), 1k4 obrażeń przeszywających"));
    jR = JsonObjectSet(jR, "disarm_dc",  JsonInt(15));
    jR = JsonObjectSet(jR, "detect_dc",  JsonInt(13));
    jC = JsonArray();
    jC = JsonArrayInsert(jC, JsonObjectSet(JsonObjectSet(JsonObject(), "tag", JsonString(TRAP_COMP_ROPE)), "cnt", JsonInt(3)));
    jC = JsonArrayInsert(jC, JsonObjectSet(JsonObjectSet(JsonObject(), "tag", JsonString(TRAP_COMP_HOOK)), "cnt", JsonInt(2)));
    jR = JsonObjectSet(jR, "comps", jC);
    jAll = JsonArrayInsert(jAll, jR);

    return jAll;
}

// ================================================================
// Component helpers
// ================================================================

int TrapCountComponent(object oPC, string sCompTag)
{
    int nTotal = 0;
    object oItem = GetFirstItemInInventory(oPC);
    while(GetIsObjectValid(oItem))
    {
        if(GetTag(oItem) == sCompTag)
            nTotal += GetItemStackSize(oItem);
        oItem = GetNextItemInInventory(oPC);
    }
    return nTotal;
}

// Returns TRUE if PC has all components for recipe nIdx
int TrapCanCraft(object oPC, json jRecipes, int nIdx)
{
    if(nIdx < 0 || nIdx >= JsonGetLength(jRecipes)) return FALSE;
    json jR    = JsonArrayGet(jRecipes, nIdx);
    json jComp = JsonObjectGet(jR, "comps");
    int  i;
    for(i = 0; i < JsonGetLength(jComp); i++)
    {
        json   jEntry = JsonArrayGet(jComp, i);
        string sTag   = JsonGetString(JsonObjectGet(jEntry, "tag"));
        int    nNeed  = JsonGetInt   (JsonObjectGet(jEntry, "cnt"));
        if(TrapCountComponent(oPC, sTag) < nNeed) return FALSE;
    }
    return TRUE;
}

void TrapConsumeComponents(object oPC, int nRecipeIdx)
{
    json jRecipes = TrapGetRecipes();
    if(nRecipeIdx < 0 || nRecipeIdx >= JsonGetLength(jRecipes)) return;
    json jR    = JsonArrayGet(jRecipes, nRecipeIdx);
    json jComp = JsonObjectGet(jR, "comps");
    int  i;
    for(i = 0; i < JsonGetLength(jComp); i++)
    {
        json   jEntry  = JsonArrayGet(jComp, i);
        string sTag    = JsonGetString(JsonObjectGet(jEntry, "tag"));
        int    nRemain = JsonGetInt   (JsonObjectGet(jEntry, "cnt"));

        object oItem = GetFirstItemInInventory(oPC);
        while(GetIsObjectValid(oItem) && nRemain > 0)
        {
            if(GetTag(oItem) == sTag)
            {
                int nStack = GetItemStackSize(oItem);
                if(nStack <= nRemain)
                {
                    nRemain -= nStack;
                    DestroyObject(oItem);
                }
                else
                {
                    SetItemStackSize(oItem, nStack - nRemain);
                    nRemain = 0;
                }
            }
            oItem = GetNextItemInInventory(oPC);
        }
    }
}

int TrapCountPlacedByPC(object oPC)
{
    return TrapCountActivePlaced(oPC);
}

// ================================================================
// NUI window building
// ================================================================

json TrapBuildRecipeListPanel(object oPC)
{
    float fRowH   = GetNuiScaleDimension(oPC, 30.0);

    json jNameLbl = NuiLabel(NuiBind(TRAP_BIND_REC_NAME),
                             JsonInt(NUI_HALIGN_LEFT), JsonInt(NUI_VALIGN_MIDDLE));
    jNameLbl = NuiStyleForegroundColor(jNameLbl, NuiBind(TRAP_BIND_REC_COLOR));

    json jRowCols = JsonArray();
    jRowCols = JsonArrayInsert(jRowCols, jNameLbl);

    json jRow = NuiGroup(NuiRow(jRowCols), FALSE, NUI_SCROLLBARS_NONE);
    jRow = NuiId(jRow, TRAP_BTN_REC_ROW);
    jRow = NuiEncouraged(jRow, NuiBind(TRAP_BIND_REC_ENC));

    json jList = NuiList(jRow, NuiBind(TRAP_BIND_REC_CNT), fRowH);

    json jHeader = NuiLabel(JsonString("Przepisy"),
                            JsonInt(NUI_HALIGN_CENTER), JsonInt(NUI_VALIGN_MIDDLE));
    jHeader = NuiHeight(jHeader, GetNuiScaleDimension(oPC, 24.0));

    json jCol = JsonArray();
    jCol = JsonArrayInsert(jCol, jHeader);
    jCol = JsonArrayInsert(jCol, jList);

    json jPanel = NuiGroup(NuiCol(jCol), TRUE, NUI_SCROLLBARS_Y);
    jPanel = NuiWidth(jPanel, GetNuiScaleDimension(oPC, 175.0));
    return jPanel;
}

json TrapBuildDetailPanel(object oPC)
{
    float fLblH  = GetNuiScaleDimension(oPC, 24.0);
    float fDescH = GetNuiScaleDimension(oPC, 110.0);
    float fCompH = GetNuiScaleDimension(oPC, 26.0);

    // Recipe title
    json jTitle = NuiLabel(NuiBind(TRAP_BIND_DET_TITLE),
                           JsonInt(NUI_HALIGN_CENTER), JsonInt(NUI_VALIGN_MIDDLE));
    jTitle = NuiHeight(jTitle, fLblH);
    jTitle = NuiStyleForegroundColor(jTitle, NuiColor(220, 160, 60));

    // Flavor description
    json jDesc = NuiText(NuiBind(TRAP_BIND_DET_DESC), FALSE);
    jDesc = NuiHeight(jDesc, fDescH);

    // Effect line
    json jEffectLbl = NuiLabel(JsonString("Efekt:"),
                               JsonInt(NUI_HALIGN_LEFT), JsonInt(NUI_VALIGN_MIDDLE));
    jEffectLbl = NuiWidth(jEffectLbl, GetNuiScaleDimension(oPC, 50.0));
    jEffectLbl = NuiHeight(jEffectLbl, fLblH);

    json jEffect = NuiLabel(NuiBind(TRAP_BIND_DET_EFFECT),
                            JsonInt(NUI_HALIGN_LEFT), JsonInt(NUI_VALIGN_MIDDLE));
    jEffect = NuiHeight(jEffect, fLblH);
    jEffect = NuiStyleForegroundColor(jEffect, NuiColor(200, 90, 90));

    json jEffectRow = JsonArray();
    jEffectRow = JsonArrayInsert(jEffectRow, jEffectLbl);
    jEffectRow = JsonArrayInsert(jEffectRow, jEffect);

    // Components header
    json jCompHdr = NuiLabel(JsonString("Składniki:"),
                             JsonInt(NUI_HALIGN_LEFT), JsonInt(NUI_VALIGN_MIDDLE));
    jCompHdr = NuiHeight(jCompHdr, fLblH);

    // Component requirement list
    json jNeedLbl = NuiLabel(NuiBind(TRAP_BIND_COMP_NEED),
                             JsonInt(NUI_HALIGN_RIGHT), JsonInt(NUI_VALIGN_MIDDLE));
    jNeedLbl = NuiWidth(jNeedLbl, GetNuiScaleDimension(oPC, 30.0));

    json jSlashLbl = NuiLabel(JsonString("/"),
                              JsonInt(NUI_HALIGN_CENTER), JsonInt(NUI_VALIGN_MIDDLE));
    jSlashLbl = NuiWidth(jSlashLbl, GetNuiScaleDimension(oPC, 12.0));

    json jHaveLbl = NuiLabel(NuiBind(TRAP_BIND_COMP_HAVE),
                             JsonInt(NUI_HALIGN_LEFT), JsonInt(NUI_VALIGN_MIDDLE));
    jHaveLbl = NuiWidth(jHaveLbl, GetNuiScaleDimension(oPC, 30.0));
    jHaveLbl = NuiStyleForegroundColor(jHaveLbl, NuiBind(TRAP_BIND_COMP_COLOR));

    json jCompName = NuiLabel(NuiBind(TRAP_BIND_COMP_NAME),
                              JsonInt(NUI_HALIGN_LEFT), JsonInt(NUI_VALIGN_MIDDLE));
    jCompName = NuiStyleForegroundColor(jCompName, NuiBind(TRAP_BIND_COMP_COLOR));

    json jCompRow = JsonArray();
    jCompRow = JsonArrayInsert(jCompRow, jNeedLbl);
    jCompRow = JsonArrayInsert(jCompRow, jSlashLbl);
    jCompRow = JsonArrayInsert(jCompRow, jHaveLbl);
    jCompRow = JsonArrayInsert(jCompRow, jCompName);

    json jCompRowGrp = NuiGroup(NuiRow(jCompRow), FALSE, NUI_SCROLLBARS_NONE);
    json jCompList   = NuiList(jCompRowGrp, NuiBind(TRAP_BIND_COMP_CNT), fCompH);

    json jCol = JsonArray();
    jCol = JsonArrayInsert(jCol, jTitle);
    jCol = JsonArrayInsert(jCol, jDesc);
    jCol = JsonArrayInsert(jCol, NuiRow(jEffectRow));
    jCol = JsonArrayInsert(jCol, jCompHdr);
    jCol = JsonArrayInsert(jCol, jCompList);

    json jPanel = NuiGroup(NuiCol(jCol), TRUE, NUI_SCROLLBARS_NONE);
    return jPanel;
}

json TrapBuildBottomBar(object oPC)
{
    float fBtnH = GetNuiScaleDimension(oPC, 32.0);
    float fBtnW = GetNuiScaleDimension(oPC, 170.0);

    json jStatus = NuiLabel(NuiBind(TRAP_BIND_STATUS),
                            JsonInt(NUI_HALIGN_CENTER), JsonInt(NUI_VALIGN_MIDDLE));
    jStatus = NuiStyleForegroundColor(jStatus, NuiBind(TRAP_BIND_STATUS_COLOR));
    jStatus = NuiHeight(jStatus, fBtnH);

    json jPlaced = NuiLabel(NuiBind(TRAP_BIND_PLACED_LBL),
                            JsonInt(NUI_HALIGN_RIGHT), JsonInt(NUI_VALIGN_MIDDLE));
    jPlaced = NuiHeight(jPlaced, fBtnH);
    jPlaced = NuiWidth(jPlaced, GetNuiScaleDimension(oPC, 120.0));

    json jCraftBtn = NuiButton(NuiBind(TRAP_BIND_CRAFT_LBL));
    jCraftBtn = NuiId(jCraftBtn, TRAP_BTN_CRAFT);
    jCraftBtn = NuiEnabled(jCraftBtn, NuiBind(TRAP_BIND_CRAFT_ENA));
    jCraftBtn = NuiWidth(jCraftBtn, fBtnW);
    jCraftBtn = NuiHeight(jCraftBtn, fBtnH);

    json jCloseBtn = NuiButton(JsonString("Zamknij"));
    jCloseBtn = NuiId(jCloseBtn, TRAP_BTN_CLOSE);
    jCloseBtn = NuiWidth(jCloseBtn, GetNuiScaleDimension(oPC, 90.0));
    jCloseBtn = NuiHeight(jCloseBtn, fBtnH);

    json jRow = JsonArray();
    jRow = JsonArrayInsert(jRow, jStatus);
    jRow = JsonArrayInsert(jRow, jPlaced);
    jRow = JsonArrayInsert(jRow, jCraftBtn);
    jRow = JsonArrayInsert(jRow, jCloseBtn);

    return NuiRow(jRow);
}

void TrapOpenCraftWindow(object oPC)
{
    if(NuiFindWindow(oPC, TRAP_WIN_CRAFT) != 0)
    {
        NuiFocus(oPC, NuiFindWindow(oPC, TRAP_WIN_CRAFT));
        return;
    }

    float fW = GetNuiScaleDimension(oPC, TRAP_W);
    float fH = GetNuiScaleDimension(oPC, TRAP_H);

    json jRecipePanel = TrapBuildRecipeListPanel(oPC);
    json jDetailPanel = TrapBuildDetailPanel(oPC);
    json jBottom      = TrapBuildBottomBar(oPC);

    json jMainRow = JsonArray();
    jMainRow = JsonArrayInsert(jMainRow, jRecipePanel);
    jMainRow = JsonArrayInsert(jMainRow, jDetailPanel);

    json jRoot = JsonArray();
    jRoot = JsonArrayInsert(jRoot, NuiRow(jMainRow));
    jRoot = JsonArrayInsert(jRoot, jBottom);

    json jLayout = NuiCol(jRoot);

    json jWin = NuiWindow(jLayout,
                          JsonString("Warsztat Pułapek"),
                          NuiBind(TRAP_WIN_CRAFT + "_geo"),
                          JsonBool(FALSE),
                          JsonBool(FALSE),
                          JsonBool(TRUE),
                          JsonBool(FALSE),
                          JsonBool(TRUE));

    int nToken = NuiCreate(oPC, jWin, TRAP_WIN_CRAFT);

    NuiSetBind(oPC, nToken, TRAP_WIN_CRAFT + "_geo",
               NuiRect(50.0, 50.0, fW, fH));

    SetLocalInt(oPC, TRAP_LVAR_SEL_IDX, -1);

    TrapFeedRecipeList(oPC, nToken);
    TrapFeedRecipeDetail(oPC, nToken, -1);
}

// ================================================================
// Feed functions
// ================================================================

void TrapFeedRecipeList(object oPC, int nToken)
{
    json jRecipes = TrapGetRecipes();
    int  nCount   = JsonGetLength(jRecipes);

    json jNames  = JsonArray();
    json jEncs   = JsonArray();
    json jColors = JsonArray();

    int nSel = GetLocalInt(oPC, TRAP_LVAR_SEL_IDX);

    int i;
    for(i = 0; i < nCount; i++)
    {
        json jR       = JsonArrayGet(jRecipes, i);
        string sName  = JsonGetString(JsonObjectGet(jR, "name"));
        int bCanCraft = TrapCanCraft(oPC, jRecipes, i);

        jNames  = JsonArrayInsert(jNames,  JsonString(sName));
        jEncs   = JsonArrayInsert(jEncs,   JsonBool(i == nSel));
        jColors = JsonArrayInsert(jColors, bCanCraft
                                           ? NuiColor(180, 220, 130)
                                           : NuiColor(150, 120, 100));
    }

    NuiSetBind(oPC, nToken, TRAP_BIND_REC_NAME,  jNames);
    NuiSetBind(oPC, nToken, TRAP_BIND_REC_ENC,   jEncs);
    NuiSetBind(oPC, nToken, TRAP_BIND_REC_COLOR, jColors);
    NuiSetBind(oPC, nToken, TRAP_BIND_REC_CNT,   JsonInt(nCount));
}

void TrapFeedRecipeDetail(object oPC, int nToken, int nIdx)
{
    json jRecipes = TrapGetRecipes();

    if(nIdx < 0 || nIdx >= JsonGetLength(jRecipes))
    {
        NuiSetBind(oPC, nToken, TRAP_BIND_DET_TITLE,  JsonString("Wybierz przepis"));
        NuiSetBind(oPC, nToken, TRAP_BIND_DET_DESC,   JsonString("Kliknij nazwę pułapki po lewej, aby zobaczyć szczegóły i potrzebne składniki."));
        NuiSetBind(oPC, nToken, TRAP_BIND_DET_EFFECT, JsonString("—"));
        NuiSetBind(oPC, nToken, TRAP_BIND_COMP_NAME,  JsonArray());
        NuiSetBind(oPC, nToken, TRAP_BIND_COMP_NEED,  JsonArray());
        NuiSetBind(oPC, nToken, TRAP_BIND_COMP_HAVE,  JsonArray());
        NuiSetBind(oPC, nToken, TRAP_BIND_COMP_COLOR, JsonArray());
        NuiSetBind(oPC, nToken, TRAP_BIND_COMP_CNT,   JsonInt(0));
        NuiSetBind(oPC, nToken, TRAP_BIND_CRAFT_ENA,  JsonBool(FALSE));
        NuiSetBind(oPC, nToken, TRAP_BIND_CRAFT_LBL,  JsonString("Skuć pułapkę"));
        NuiSetBind(oPC, nToken, TRAP_BIND_STATUS,     JsonString(""));
        NuiSetBind(oPC, nToken, TRAP_BIND_STATUS_COLOR, NuiColor(200, 200, 200));
        int nPlaced = TrapCountPlacedByPC(oPC);
        NuiSetBind(oPC, nToken, TRAP_BIND_PLACED_LBL,
                   JsonString("Aktywne: " + IntToString(nPlaced) + "/" + IntToString(TRAP_MAX_ACTIVE)));
        return;
    }

    json jR      = JsonArrayGet(jRecipes, nIdx);
    string sName = JsonGetString(JsonObjectGet(jR, "name"));
    string sDesc = JsonGetString(JsonObjectGet(jR, "desc"));
    string sEff  = JsonGetString(JsonObjectGet(jR, "effect"));
    json   jComp = JsonObjectGet(jR, "comps");
    int    nComp = JsonGetLength(jComp);

    NuiSetBind(oPC, nToken, TRAP_BIND_DET_TITLE,  JsonString(sName));
    NuiSetBind(oPC, nToken, TRAP_BIND_DET_DESC,   JsonString(sDesc));
    NuiSetBind(oPC, nToken, TRAP_BIND_DET_EFFECT, JsonString(sEff));

    json jCNames  = JsonArray();
    json jCNeeds  = JsonArray();
    json jCHaves  = JsonArray();
    json jCColors = JsonArray();

    int bAllHave = TRUE;
    int j;
    for(j = 0; j < nComp; j++)
    {
        json   jEntry = JsonArrayGet(jComp, j);
        string sTag   = JsonGetString(JsonObjectGet(jEntry, "tag"));
        int    nNeed  = JsonGetInt   (JsonObjectGet(jEntry, "cnt"));
        int    nHave  = TrapCountComponent(oPC, sTag);
        int    bOk    = (nHave >= nNeed);
        if(!bOk) bAllHave = FALSE;

        // User-friendly component name from tag
        string sDispName = sTag;
        if(sTag == TRAP_COMP_BLADE)  sDispName = "Ostrze";
        if(sTag == TRAP_COMP_SPRING) sDispName = "Sprężyna";
        if(sTag == TRAP_COMP_DART)   sDispName = "Strzałka";
        if(sTag == TRAP_COMP_POISON) sDispName = "Fiolka trucizny";
        if(sTag == TRAP_COMP_OIL)    sDispName = "Kolba olejku";
        if(sTag == TRAP_COMP_FLINT)  sDispName = "Krzesiwo";
        if(sTag == TRAP_COMP_POWDER) sDispName = "Fleszkiproch";
        if(sTag == TRAP_COMP_GLASS)  sDispName = "Fiolka szklana";
        if(sTag == TRAP_COMP_BELL)   sDispName = "Dzwoneczek";
        if(sTag == TRAP_COMP_WIRE)   sDispName = "Drut";
        if(sTag == TRAP_COMP_ROPE)   sDispName = "Linka";
        if(sTag == TRAP_COMP_HOOK)   sDispName = "Hak";

        jCNames  = JsonArrayInsert(jCNames,  JsonString(sDispName));
        jCNeeds  = JsonArrayInsert(jCNeeds,  JsonString("x" + IntToString(nNeed)));
        jCHaves  = JsonArrayInsert(jCHaves,  JsonString(IntToString(nHave)));
        jCColors = JsonArrayInsert(jCColors, bOk ? NuiColor(150, 220, 100) : NuiColor(220, 80, 80));
    }

    NuiSetBind(oPC, nToken, TRAP_BIND_COMP_NAME,  jCNames);
    NuiSetBind(oPC, nToken, TRAP_BIND_COMP_NEED,  jCNeeds);
    NuiSetBind(oPC, nToken, TRAP_BIND_COMP_HAVE,  jCHaves);
    NuiSetBind(oPC, nToken, TRAP_BIND_COMP_COLOR, jCColors);
    NuiSetBind(oPC, nToken, TRAP_BIND_COMP_CNT,   JsonInt(nComp));

    int nPlaced = TrapCountPlacedByPC(oPC);
    int bAtLimit = (nPlaced >= TRAP_MAX_ACTIVE);

    NuiSetBind(oPC, nToken, TRAP_BIND_CRAFT_ENA,
               JsonBool(bAllHave && !bAtLimit));
    NuiSetBind(oPC, nToken, TRAP_BIND_CRAFT_LBL,
               JsonString("Skuć pułapkę: " + sName));

    if(bAtLimit)
        NuiSetBind(oPC, nToken, TRAP_BIND_STATUS,
                   JsonString("Osiągnięto limit aktywnych pułapek!"));
    else if(!bAllHave)
        NuiSetBind(oPC, nToken, TRAP_BIND_STATUS,
                   JsonString("Brakuje składników."));
    else
        NuiSetBind(oPC, nToken, TRAP_BIND_STATUS,
                   JsonString("Możesz skuć tę pułapkę."));

    NuiSetBind(oPC, nToken, TRAP_BIND_STATUS_COLOR,
               bAllHave && !bAtLimit ? NuiColor(150, 220, 100) : NuiColor(220, 140, 60));

    NuiSetBind(oPC, nToken, TRAP_BIND_PLACED_LBL,
               JsonString("Aktywne: " + IntToString(nPlaced) + "/" + IntToString(TRAP_MAX_ACTIVE)));
}

// ================================================================
// Crafting
// ================================================================

void TrapHandleCraft(object oPC, int nToken)
{
    int  nIdx     = GetLocalInt(oPC, TRAP_LVAR_SEL_IDX);
    json jRecipes = TrapGetRecipes();

    if(nIdx < 0 || nIdx >= JsonGetLength(jRecipes)) return;

    if(TrapCountPlacedByPC(oPC) >= TRAP_MAX_ACTIVE)
    {
        SendMessageToPC(oPC, "[Pułapki] Osiągnąłeś limit " +
                             IntToString(TRAP_MAX_ACTIVE) + " aktywnych pułapek.");
        return;
    }

    if(!TrapCanCraft(oPC, jRecipes, nIdx))
    {
        SendMessageToPC(oPC, "[Pułapki] Brakuje składników.");
        TrapFeedRecipeDetail(oPC, nToken, nIdx);
        return;
    }

    json   jR    = JsonArrayGet(jRecipes, nIdx);
    string sType = JsonGetString(JsonObjectGet(jR, "type"));
    string sName = JsonGetString(JsonObjectGet(jR, "name"));
    int    nDDC  = JsonGetInt   (JsonObjectGet(jR, "disarm_dc"));
    int    nDetDC= JsonGetInt   (JsonObjectGet(jR, "detect_dc"));

    TrapConsumeComponents(oPC, nIdx);

    // Create trap item in PC inventory (misc. item — needs resref in HAK)
    // We store type + DCs as local vars on the created item.
    object oItem = CreateItemOnObject("nw_it_msmlmisc05", oPC, 1,
                                      TRAP_ITEM_PREFIX + sType);
    if(GetIsObjectValid(oItem))
    {
        SetName(oItem, "Pułapka: " + sName);
        SetDescription(oItem, "Rożnie tą pułapkę na ziemi. Użyj jej, aby aktywować tryb celowania.");
        SetLocalString(oItem, TRAP_LVAR_TYPE,      sType);
        SetLocalInt   (oItem, TRAP_LVAR_DISARM_DC, nDDC);
        SetLocalInt   (oItem, TRAP_LVAR_DETECT_DC, nDetDC);
    }

    TrapStatIncCrafted(oPC);

    SendMessageToPC(oPC, "[Pułapki] Skuta pułapka \"" + sName + "\" trafia do twojego ekwipunku.");
    TrapFeedRecipeList  (oPC, nToken);
    TrapFeedRecipeDetail(oPC, nToken, nIdx);
}

// ================================================================
// Deploy mode — enter cursor targeting so player picks a floor location
// ================================================================

void TrapEnterDeployMode(object oPC, int nToken)
{
    int nIdx = GetLocalInt(oPC, TRAP_LVAR_SEL_IDX);
    if(nIdx < 0) return;

    // Find the trap item in inventory
    json jRecipes = TrapGetRecipes();
    if(nIdx >= JsonGetLength(jRecipes)) return;

    json   jR    = JsonArrayGet(jRecipes, nIdx);
    string sType = JsonGetString(JsonObjectGet(jR, "type"));

    object oItem = GetItemPossessedBy(oPC, TRAP_ITEM_PREFIX + sType);
    if(!GetIsObjectValid(oItem))
    {
        SendMessageToPC(oPC, "[Pułapki] Nie masz tej pułapki w ekwipunku.");
        return;
    }

    if(TrapCountPlacedByPC(oPC) >= TRAP_MAX_ACTIVE)
    {
        SendMessageToPC(oPC, "[Pułapki] Osiągnięto limit aktywnych pułapek.");
        return;
    }

    int nDDC  = GetLocalInt(oItem, TRAP_LVAR_DISARM_DC);
    int nDetDC= GetLocalInt(oItem, TRAP_LVAR_DETECT_DC);

    SetLocalInt   (oPC, TRAP_LVAR_DEPLOYING,    1);
    SetLocalString(oPC, TRAP_LVAR_DEPLOY_TYPE,  sType);
    SetLocalInt   (oPC, TRAP_LVAR_DEPLOY_DARM,  nDDC);
    SetLocalInt   (oPC, TRAP_LVAR_DETECT_DC,    nDetDC);

    NuiDestroy(oPC, nToken);
    EnterTargetingMode(oPC, OBJECT_TYPE_PLACEABLE | OBJECT_TYPE_TILE);
    SendMessageToPC(oPC, "[Pułapki] Kliknij miejsce na podłodze, aby umieścić pułapkę.");
}

// ================================================================
// Placement — called from sys_on_target.nss
// ================================================================

void TrapPlaceAtLocation(object oPC, location lTarget)
{
    if(!GetLocalInt(oPC, TRAP_LVAR_DEPLOYING)) return;

    string sType  = GetLocalString(oPC, TRAP_LVAR_DEPLOY_TYPE);
    int    nDDC   = GetLocalInt   (oPC, TRAP_LVAR_DEPLOY_DARM);
    int    nDetDC = GetLocalInt   (oPC, TRAP_LVAR_DETECT_DC);

    DeleteLocalInt   (oPC, TRAP_LVAR_DEPLOYING);
    DeleteLocalString(oPC, TRAP_LVAR_DEPLOY_TYPE);
    DeleteLocalInt   (oPC, TRAP_LVAR_DEPLOY_DARM);
    DeleteLocalInt   (oPC, TRAP_LVAR_DETECT_DC);

    if(sType == "") return;

    // Consume trap item from inventory
    object oItem = GetItemPossessedBy(oPC, TRAP_ITEM_PREFIX + sType);
    if(!GetIsObjectValid(oItem))
    {
        SendMessageToPC(oPC, "[Pułapki] Pułapka zniknęła z ekwipunku.");
        return;
    }
    DestroyObject(oItem);

    object oTrap = CreateObject(OBJECT_TYPE_PLACEABLE, TRAP_PLACEA_RESREF,
                                lTarget, FALSE,
                                TRAP_PLACED_PREFIX + sType);

    if(!GetIsObjectValid(oTrap))
    {
        SendMessageToPC(oPC, "[Pułapki] Nie można umieścić pułapki tutaj.");
        // Recreate item (refund)
        CreateItemOnObject("nw_it_msmlmisc05", oPC, 1, TRAP_ITEM_PREFIX + sType);
        return;
    }

    SetLocalString(oTrap, TRAP_LVAR_TYPE,        sType);
    SetLocalString(oTrap, TRAP_LVAR_SETTER_UUID,  GetObjectUUID(oPC));
    SetLocalString(oTrap, TRAP_LVAR_SETTER_NAME,  GetName(oPC));
    SetLocalInt   (oTrap, TRAP_LVAR_DISARM_DC,    nDDC);
    SetLocalInt   (oTrap, TRAP_LVAR_DETECT_DC,    nDetDC);
    SetLocalInt   (oTrap, TRAP_LVAR_ARMED,         1);

    SetEventScript(oTrap, EVENT_SCRIPT_PLACEABLE_ON_HEARTBEAT, TRAP_SCRIPT_HB);
    SetEventScript(oTrap, EVENT_SCRIPT_PLACEABLE_ON_USED,      TRAP_SCRIPT_DEF);

    TrapRegisterPlaced(oTrap, sType, oPC);

    SendMessageToPC(oPC, "[Pułapki] Pułapka rozstawiona. Niech czeka.");
}

// ================================================================
// Trap effect — fires once, then destroys the placeable
// ================================================================

void TrapFireEffect(object oTrap, object oTarget)
{
    string sType = GetLocalString(oTrap, TRAP_LVAR_TYPE);

    // Setter gets stat credit
    string sSetterUUID = GetLocalString(oTrap, TRAP_LVAR_SETTER_UUID);
    object oSetter     = OBJECT_INVALID;
    object oCheck      = GetFirstPC();
    while(GetIsObjectValid(oCheck))
    {
        if(GetObjectUUID(oCheck) == sSetterUUID)
        {
            oSetter = oCheck;
            break;
        }
        oCheck = GetNextPC();
    }
    if(GetIsObjectValid(oSetter))
        TrapStatIncTriggered(oSetter);

    // Visual / sound
    ApplyEffectAtLocation(DURATION_TYPE_INSTANT,
                          EffectVisualEffect(VFX_COM_BLOOD_SPARK_LARGE),
                          GetLocation(oTrap));

    if(sType == TRAP_TYPE_BLADE)
    {
        int nDmg = d6(2) + 4;
        effect eDmg = EffectDamage(nDmg, DAMAGE_TYPE_PIERCING);
        ApplyEffectToObject(DURATION_TYPE_INSTANT, eDmg, oTarget);
        ApplyEffectToObject(DURATION_TYPE_INSTANT, EffectVisualEffect(VFX_COM_BLOOD_REG), oTarget);
        FloatingTextStringOnCreature("Ostrze Skrytobójcy! (" + IntToString(nDmg) + " dmg)", oTarget, FALSE);
    }
    else if(sType == TRAP_TYPE_DART)
    {
        int nDmg = d4(1);
        effect eDmg  = EffectDamage(nDmg, DAMAGE_TYPE_PIERCING);
        effect ePoison = EffectAbilityDecrease(ABILITY_CONSTITUTION, 3);
        ApplyEffectToObject(DURATION_TYPE_INSTANT,   eDmg,    oTarget);
        ApplyEffectToObject(DURATION_TYPE_TEMPORARY, ePoison, oTarget, 60.0);
        ApplyEffectToObject(DURATION_TYPE_INSTANT, EffectVisualEffect(VFX_IMP_POISON_S), oTarget);
        FloatingTextStringOnCreature("Zatruta Strzałka! Trucizna pulsuje w żyłach.", oTarget, FALSE);
    }
    else if(sType == TRAP_TYPE_FLAME)
    {
        int nDmg = d6(3);
        effect eFire = EffectDamage(nDmg, DAMAGE_TYPE_FIRE);
        ApplyEffectToObject(DURATION_TYPE_INSTANT, eFire, oTarget);
        ApplyEffectAtLocation(DURATION_TYPE_INSTANT,
                              EffectVisualEffect(VFX_FNF_FIREBALL),
                              GetLocation(oTrap));
        FloatingTextStringOnCreature("Ogniste Więzienie! (" + IntToString(nDmg) + " dmg ogniowych)", oTarget, FALSE);
    }
    else if(sType == TRAP_TYPE_STUN)
    {
        effect eStr = EffectAbilityDecrease(ABILITY_STRENGTH,  4);
        effect eDex = EffectAbilityDecrease(ABILITY_DEXTERITY, 2);
        effect eBlind = EffectBlindness();
        ApplyEffectToObject(DURATION_TYPE_TEMPORARY, eStr,  oTarget, 30.0);
        ApplyEffectToObject(DURATION_TYPE_TEMPORARY, eDex,  oTarget, 30.0);
        ApplyEffectToObject(DURATION_TYPE_TEMPORARY, eBlind,oTarget,  6.0);
        ApplyEffectAtLocation(DURATION_TYPE_INSTANT,
                              EffectVisualEffect(VFX_FNF_GAS_EXPLOSION_FIRE),
                              GetLocation(oTrap));
        FloatingTextStringOnCreature("Błyskający Proch! Świat tonie w bieli.", oTarget, FALSE);
    }
    else if(sType == TRAP_TYPE_ALARM)
    {
        // Loud alarm: notify all DMs and nearby PCs
        string sMsg = "[ALARM] Pułapka alarmowa wyzwolona w: " + GetName(GetArea(oTrap));
        SendMessageToAllDMs(sMsg);
        object oPCIter = GetFirstPC();
        while(GetIsObjectValid(oPCIter))
        {
            if(GetArea(oPCIter) == GetArea(oTrap))
                SendMessageToPC(oPCIter, "Rozlega się przenikliwy džwięk alarmu!");
            oPCIter = GetNextPC();
        }
        ApplyEffectAtLocation(DURATION_TYPE_INSTANT,
                              EffectVisualEffect(VFX_FNF_LOS_NORMAL_10),
                              GetLocation(oTrap));
    }
    else if(sType == TRAP_TYPE_SNARE)
    {
        int nDmg = d4(1);
        effect eDmg  = EffectDamage(nDmg, DAMAGE_TYPE_PIERCING);
        effect eSlow = EffectMovementSpeedDecrease(75);
        ApplyEffectToObject(DURATION_TYPE_INSTANT,   eDmg,  oTarget);
        ApplyEffectToObject(DURATION_TYPE_TEMPORARY, eSlow, oTarget, 40.0);
        ApplyEffectToObject(DURATION_TYPE_INSTANT, EffectVisualEffect(VFX_IMP_REDUCE_ABILITY_SCORE), oTarget);
        FloatingTextStringOnCreature("Sidła Łowcy! Nogi uwięzione.", oTarget, FALSE);
    }

    TrapUnregisterPlaced(oTrap);
    SetLocalInt(oTrap, TRAP_LVAR_ARMED, 0);
    DestroyObject(oTrap, 0.5);
}

// ================================================================
// Heartbeat — proximity scan, fires on first hostile in range
// ================================================================

void TrapHeartbeat(object oTrap)
{
    if(!GetLocalInt(oTrap, TRAP_LVAR_ARMED)) return;

    string sSetterUUID = GetLocalString(oTrap, TRAP_LVAR_SETTER_UUID);

    object oNear = GetFirstObjectInShape(SHAPE_SPHERE, TRAP_TRIGGER_RADIUS,
                                         GetLocation(oTrap), TRUE,
                                         OBJECT_TYPE_CREATURE);
    while(GetIsObjectValid(oNear))
    {
        if(!GetIsDead(oNear))
        {
            // Don't trigger on the setter themselves (they set it, they know where it is)
            if(GetObjectUUID(oNear) != sSetterUUID)
            {
                TrapFireEffect(oTrap, oNear);
                return;
            }
        }
        oNear = GetNextObjectInShape(SHAPE_SPHERE, TRAP_TRIGGER_RADIUS,
                                      GetLocation(oTrap), TRUE,
                                      OBJECT_TYPE_CREATURE);
    }
}

// ================================================================
// Defuse — PC uses the placeable, attempts Disable Trap / Open Lock
// ================================================================

void TrapTryDefuse(object oTrap)
{
    object oPC = GetLastUsedBy();
    if(!GetIsPC(oPC)) return;

    int nDC   = GetLocalInt(oTrap, TRAP_LVAR_DISARM_DC);
    int nSkill= GetSkillRank(SKILL_DISABLE_TRAP, oPC);
    int nRoll = d20() + nSkill;

    string sSetterName = GetLocalString(oTrap, TRAP_LVAR_SETTER_NAME);

    if(nRoll >= nDC)
    {
        SendMessageToPC(oPC, "[Pułapki] Rozbroiłeś pułapkę (wynik: " +
                             IntToString(nRoll) + " vs DC " + IntToString(nDC) + ").");

        // Find setter and give them the disarmed notification
        string sSetterUUID = GetLocalString(oTrap, TRAP_LVAR_SETTER_UUID);
        object oSetter = GetFirstPC();
        while(GetIsObjectValid(oSetter))
        {
            if(GetObjectUUID(oSetter) == sSetterUUID)
            {
                SendMessageToPC(oSetter, "[Pułapki] Twoja pułapka została rozbrojona przez " + GetName(oPC) + "!");
                TrapStatIncDisarmed(oSetter);
                break;
            }
            oSetter = GetNextPC();
        }

        TrapUnregisterPlaced(oTrap);
        SetLocalInt(oTrap, TRAP_LVAR_ARMED, 0);
        DestroyObject(oTrap, 0.3);
    }
    else
    {
        SendMessageToPC(oPC, "[Pułapki] Nie udało się rozbroić (wynik: " +
                             IntToString(nRoll) + " vs DC " + IntToString(nDC) + ").");
        // Fumble: trap fires on the disarmer!
        if(nRoll <= (nDC - 10))
        {
            SendMessageToPC(oPC, "[Pułapki] Nieudana próba... pułapka się uruchomiła!");
            TrapFireEffect(oTrap, oPC);
        }
    }
}
