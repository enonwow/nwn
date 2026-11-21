#include "lib_poi_def"

// Forward declarations
void FeedWorkshop(object oPC, int nToken);
void FeedArsenal(object oPC, int nToken);
void SwapToWorkshop(object oPC, int nToken);
void SwapToArsenal(object oPC, int nToken);
void PoiApplyEffect(object oPC, object oWeapon, int nPoisonId);
void PoiOnWeaponTarget(object oPC);

// ----------------------------------------------------------------
// Workshop view builder
// ----------------------------------------------------------------

json BuildWorkshopView(object oPC)
{
    float fBtnH  = GetNuiScaleDimension(oPC, 28.0);
    float fIRowH = GetNuiScaleDimension(oPC, 24.0);
    float fRRowH = GetNuiScaleDimension(oPC, 30.0);

    // --- Ingredient inventory list ---
    json jIngHdr = NuiLabel(JsonString("Składniki w zapasach:"),
        JsonInt(NUI_HALIGN_LEFT), JsonInt(NUI_VALIGN_MIDDLE));
    jIngHdr = NuiHeight(jIngHdr, GetNuiScaleDimension(oPC, 22.0));

    json jIngName = NuiLabel(NuiBind(POI_BIND_ING_NAME),
        JsonInt(NUI_HALIGN_LEFT), JsonInt(NUI_VALIGN_MIDDLE));
    jIngName = NuiStyleForegroundColor(jIngName, NuiBind(POI_BIND_ING_COLOR));

    json jIngCnt = NuiLabel(NuiBind(POI_BIND_ING_COUNT),
        JsonInt(NUI_HALIGN_RIGHT), JsonInt(NUI_VALIGN_MIDDLE));
    jIngCnt = NuiWidth(jIngCnt, GetNuiScaleDimension(oPC, 36.0));
    jIngCnt = NuiStyleForegroundColor(jIngCnt, NuiBind(POI_BIND_ING_COLOR));

    json jIngCols = JsonArray();
    jIngCols = JsonArrayInsert(jIngCols, jIngName);
    jIngCols = JsonArrayInsert(jIngCols, jIngCnt);

    json jIngCell = NuiGroup(NuiRow(jIngCols), FALSE, NUI_SCROLLBARS_NONE);
    json jIngTmpl = JsonArrayInsert(JsonArray(), NuiListTemplateCell(jIngCell, 0.0, TRUE));
    json jIngList = NuiList(jIngTmpl, NuiBind(POI_BIND_ING_LEN), fIRowH);
    jIngList = NuiHeight(jIngList, GetNuiScaleDimension(oPC, 205.0));

    // --- Recipe list ---
    json jRecHdr = NuiLabel(JsonString("Receptury (kliknij 'Warzyj' by sporządzić fiolkę):"),
        JsonInt(NUI_HALIGN_LEFT), JsonInt(NUI_VALIGN_MIDDLE));
    jRecHdr = NuiHeight(jRecHdr, GetNuiScaleDimension(oPC, 22.0));

    float fCraftW = GetNuiScaleDimension(oPC, 70.0);
    float fNameW  = GetNuiScaleDimension(oPC, 145.0);

    json jRecName = NuiLabel(NuiBind(POI_BIND_REC_NAME),
        JsonInt(NUI_HALIGN_LEFT), JsonInt(NUI_VALIGN_MIDDLE));
    jRecName = NuiWidth(jRecName, fNameW);
    jRecName = NuiStyleForegroundColor(jRecName, NuiBind(POI_BIND_REC_COLOR));

    json jRecIngr = NuiLabel(NuiBind(POI_BIND_REC_INGR),
        JsonInt(NUI_HALIGN_LEFT), JsonInt(NUI_VALIGN_MIDDLE));
    jRecIngr = NuiStyleForegroundColor(jRecIngr, NuiBind(POI_BIND_REC_COLOR));

    json jCraftBtn = NuiButton(JsonString("Warzyj"));
    jCraftBtn = NuiId(jCraftBtn, POI_BTN_CRAFT);
    jCraftBtn = NuiEnabled(jCraftBtn, NuiBind(POI_BIND_REC_CRAFT_ENA));
    jCraftBtn = NuiWidth(jCraftBtn, fCraftW);
    jCraftBtn = NuiHeight(jCraftBtn, GetNuiScaleDimension(oPC, 26.0));

    json jRecCols = JsonArray();
    jRecCols = JsonArrayInsert(jRecCols, jRecName);
    jRecCols = JsonArrayInsert(jRecCols, jRecIngr);
    jRecCols = JsonArrayInsert(jRecCols, jCraftBtn);

    json jRecCell = NuiGroup(NuiRow(jRecCols), FALSE, NUI_SCROLLBARS_NONE);
    json jRecTmpl = JsonArrayInsert(JsonArray(), NuiListTemplateCell(jRecCell, 0.0, TRUE));
    json jRecList = NuiList(jRecTmpl, NuiBind(POI_BIND_REC_LEN), fRRowH);
    jRecList = NuiHeight(jRecList, GetNuiScaleDimension(oPC, 200.0));

    // --- Assemble ---
    json jCol = JsonArray();
    jCol = JsonArrayInsert(jCol, jIngHdr);
    jCol = JsonArrayInsert(jCol, jIngList);
    jCol = JsonArrayInsert(jCol, CreateEmptyRow(oPC, 6.0));
    jCol = JsonArrayInsert(jCol, jRecHdr);
    jCol = JsonArrayInsert(jCol, jRecList);

    float fContentW = GetNuiScaleDimension(oPC, 540.0);
    json jSide      = NuiCol(JsonArrayInsert(JsonArray(), NuiSpacer()));
    json jMain      = JsonArray();
    jMain = JsonArrayInsert(jMain, jSide);
    jMain = JsonArrayInsert(jMain, NuiWidth(NuiCol(jCol), fContentW));
    jMain = JsonArrayInsert(jMain, jSide);
    return NuiRow(jMain);
}

// ----------------------------------------------------------------
// Arsenal view builder
// ----------------------------------------------------------------

json BuildArsenalView(object oPC)
{
    float fRowH   = GetNuiScaleDimension(oPC, 32.0);
    float fApplyW = GetNuiScaleDimension(oPC, 130.0);
    float fCntW   = GetNuiScaleDimension(oPC, 32.0);
    float fEfxW   = GetNuiScaleDimension(oPC, 140.0);

    json jActiveLbl = NuiLabel(NuiBind(POI_BIND_ARS_ACTIVE),
        JsonInt(NUI_HALIGN_LEFT), JsonInt(NUI_VALIGN_MIDDLE));
    jActiveLbl = NuiHeight(jActiveLbl, GetNuiScaleDimension(oPC, 28.0));

    // List columns: name | effect | count | [apply btn]
    json jPoisName = NuiLabel(NuiBind(POI_BIND_ARS_NAME),
        JsonInt(NUI_HALIGN_LEFT), JsonInt(NUI_VALIGN_MIDDLE));
    jPoisName = NuiStyleForegroundColor(jPoisName, NuiBind(POI_BIND_ARS_COLOR));
    jPoisName = NuiWidth(jPoisName, GetNuiScaleDimension(oPC, 145.0));

    json jPoisCnt = NuiLabel(NuiBind(POI_BIND_ARS_COUNT),
        JsonInt(NUI_HALIGN_CENTER), JsonInt(NUI_VALIGN_MIDDLE));
    jPoisCnt = NuiWidth(jPoisCnt, fCntW);
    jPoisCnt = NuiStyleForegroundColor(jPoisCnt, NuiBind(POI_BIND_ARS_COLOR));

    json jApplyBtn = NuiButton(JsonString("Nałóż na broń"));
    jApplyBtn = NuiId(jApplyBtn, POI_BTN_APPLY);
    jApplyBtn = NuiEnabled(jApplyBtn, NuiBind(POI_BIND_ARS_APPLY_ENA));
    jApplyBtn = NuiWidth(jApplyBtn, fApplyW);
    jApplyBtn = NuiHeight(jApplyBtn, GetNuiScaleDimension(oPC, 28.0));

    json jPoisCols = JsonArray();
    jPoisCols = JsonArrayInsert(jPoisCols, jPoisName);
    jPoisCols = JsonArrayInsert(jPoisCols, jPoisCnt);
    jPoisCols = JsonArrayInsert(jPoisCols, jApplyBtn);

    json jPoisCell = NuiGroup(NuiRow(jPoisCols), FALSE, NUI_SCROLLBARS_NONE);
    json jPoisTmpl = JsonArrayInsert(JsonArray(), NuiListTemplateCell(jPoisCell, 0.0, TRUE));
    json jPoisList = NuiList(jPoisTmpl, NuiBind(POI_BIND_ARS_LEN), fRowH);
    jPoisList = NuiHeight(jPoisList, GetNuiScaleDimension(oPC, 230.0));

    json jHint = NuiLabel(
        JsonString("Kliknij 'Nałóż na broń', następnie wskaż broń z ekwipunku lub dzierżoną w dłoni."),
        JsonInt(NUI_HALIGN_LEFT), JsonInt(NUI_VALIGN_MIDDLE));
    jHint = NuiHeight(jHint, GetNuiScaleDimension(oPC, 42.0));

    json jCol = JsonArray();
    jCol = JsonArrayInsert(jCol, jActiveLbl);
    jCol = JsonArrayInsert(jCol, CreateEmptyRow(oPC, 4.0));
    jCol = JsonArrayInsert(jCol, jPoisList);
    jCol = JsonArrayInsert(jCol, CreateEmptyRow(oPC, 8.0));
    jCol = JsonArrayInsert(jCol, jHint);

    float fContentW = GetNuiScaleDimension(oPC, 540.0);
    json jSide      = NuiCol(JsonArrayInsert(JsonArray(), NuiSpacer()));
    json jMain      = JsonArray();
    jMain = JsonArrayInsert(jMain, jSide);
    jMain = JsonArrayInsert(jMain, NuiWidth(NuiCol(jCol), fContentW));
    jMain = JsonArrayInsert(jMain, jSide);
    return NuiRow(jMain);
}

// ----------------------------------------------------------------
// Window creation
// ----------------------------------------------------------------

void CreatePoisonWindow(object oPC)
{
    if(NuiFindWindow(oPC, POI_WINDOW) != 0)
    {
        SwapToWorkshop(oPC, NuiFindWindow(oPC, POI_WINDOW));
        return;
    }

    float fCX = (IntToFloat(GetPlayerDeviceProperty(oPC, PLAYER_DEVICE_PROPERTY_GUI_WIDTH))
                 - GetNuiScaleDimension(oPC, POI_W)) / 2.0;
    float fCY = (IntToFloat(GetPlayerDeviceProperty(oPC, PLAYER_DEVICE_PROPERTY_GUI_HEIGHT))
                 - GetNuiScaleDimension(oPC, POI_H)) / 2.0;
    json jGeom = NuiRect(fCX, fCY,
                         GetNuiScaleDimension(oPC, POI_W),
                         GetNuiScaleDimension(oPC, POI_H));

    float fBtnH = GetNuiScaleDimension(oPC, 28.0);

    json jWorkTab = NuiButton(JsonString("Receptury"));
    jWorkTab = NuiId(jWorkTab, POI_BTN_TAB_WORKSHOP);
    jWorkTab = NuiWidth(jWorkTab, GetNuiScaleDimension(oPC, 110.0));
    jWorkTab = NuiHeight(jWorkTab, fBtnH);
    jWorkTab = NuiEncouraged(jWorkTab, NuiBind(POI_BIND_TAB_WORK_ENC));

    json jArsTab = NuiButton(JsonString("Arsenał"));
    jArsTab = NuiId(jArsTab, POI_BTN_TAB_ARSENAL);
    jArsTab = NuiWidth(jArsTab, GetNuiScaleDimension(oPC, 110.0));
    jArsTab = NuiHeight(jArsTab, fBtnH);
    jArsTab = NuiEncouraged(jArsTab, NuiBind(POI_BIND_TAB_ARS_ENC));

    json jCloseBtn = NuiButton(JsonString("X"));
    jCloseBtn = NuiId(jCloseBtn, POI_BTN_CLOSE);
    jCloseBtn = NuiWidth(jCloseBtn, GetNuiScaleDimension(oPC, 30.0));
    jCloseBtn = NuiHeight(jCloseBtn, fBtnH);

    json jTabRow = JsonArray();
    jTabRow = JsonArrayInsert(jTabRow, jWorkTab);
    jTabRow = JsonArrayInsert(jTabRow, jArsTab);
    jTabRow = JsonArrayInsert(jTabRow, NuiSpacer());
    jTabRow = JsonArrayInsert(jTabRow, jCloseBtn);

    json jSwapGrp = NuiGroup(BuildWorkshopView(oPC), FALSE, NUI_SCROLLBARS_NONE);
    jSwapGrp = NuiId(jSwapGrp, POI_GRP_SWAP);

    json jRootCols = JsonArray();
    jRootCols = JsonArrayInsert(jRootCols, NuiRow(jTabRow));
    jRootCols = JsonArrayInsert(jRootCols, jSwapGrp);
    json jRoot = NuiCol(jRootCols);

    json jWin = NuiWindow(jRoot,
        JsonString("Wytwórnia Trucizn"),
        NuiBind(POI_WIN_GEOM),
        JsonBool(FALSE),
        JsonBool(FALSE),
        JsonBool(FALSE),
        JsonBool(TRUE),
        JsonBool(FALSE));

    int nToken = NuiCreate(oPC, jWin, POI_WINDOW, POI_EV_SCRIPT);
    NuiSetBind(oPC, nToken, POI_WIN_GEOM, jGeom);
    SwapToWorkshop(oPC, nToken);
}

void SwapToWorkshop(object oPC, int nToken)
{
    NuiSetGroupLayout(oPC, nToken, POI_GRP_SWAP, BuildWorkshopView(oPC));
    NuiSetBind(oPC, nToken, POI_BIND_TAB_WORK_ENC, JsonBool(TRUE));
    NuiSetBind(oPC, nToken, POI_BIND_TAB_ARS_ENC,  JsonBool(FALSE));
    FeedWorkshop(oPC, nToken);
}

void SwapToArsenal(object oPC, int nToken)
{
    NuiSetGroupLayout(oPC, nToken, POI_GRP_SWAP, BuildArsenalView(oPC));
    NuiSetBind(oPC, nToken, POI_BIND_TAB_WORK_ENC, JsonBool(FALSE));
    NuiSetBind(oPC, nToken, POI_BIND_TAB_ARS_ENC,  JsonBool(TRUE));
    FeedArsenal(oPC, nToken);
}

// ----------------------------------------------------------------
// Data feed — Workshop
// ----------------------------------------------------------------

void FeedWorkshop(object oPC, int nToken)
{
    json jGray  = NuiColor(120, 120, 120);
    json jWhite = NuiColor(210, 210, 210);

    // ingredient rows
    json jIngNames  = JsonArray();
    json jIngCounts = JsonArray();
    json jIngColors = JsonArray();
    int i;
    for(i = 0; i < POI_ING_COUNT; i++)
    {
        int nCnt = PoiGetStock(oPC, i);
        jIngNames  = JsonArrayInsert(jIngNames,  JsonString(PoiIngredientName(i)));
        jIngCounts = JsonArrayInsert(jIngCounts, JsonString("x" + IntToString(nCnt)));
        jIngColors = JsonArrayInsert(jIngColors, nCnt > 0 ? jWhite : jGray);
    }
    NuiSetBind(oPC, nToken, POI_BIND_ING_NAME,  jIngNames);
    NuiSetBind(oPC, nToken, POI_BIND_ING_COUNT, jIngCounts);
    NuiSetBind(oPC, nToken, POI_BIND_ING_COLOR, jIngColors);
    NuiSetBind(oPC, nToken, POI_BIND_ING_LEN,   JsonInt(POI_ING_COUNT));

    // recipe rows
    json jRecNames  = JsonArray();
    json jRecIngrs  = JsonArray();
    json jRecEnas   = JsonArray();
    json jRecColors = JsonArray();
    for(i = 0; i < POI_VIAL_COUNT; i++)
    {
        int i0, i1, i2;
        PoiGetRecipe(i, i0, i1, i2);

        int bCan = TRUE;
        if(i0 >= 0 && PoiGetStock(oPC, i0) < 1) bCan = FALSE;
        if(i1 >= 0 && PoiGetStock(oPC, i1) < 1) bCan = FALSE;
        if(i2 >= 0 && PoiGetStock(oPC, i2) < 1) bCan = FALSE;

        jRecNames  = JsonArrayInsert(jRecNames,  JsonString(PoiPoisonName(i)));
        jRecIngrs  = JsonArrayInsert(jRecIngrs,  JsonString(PoiRecipeString(i)));
        jRecEnas   = JsonArrayInsert(jRecEnas,   JsonBool(bCan));
        jRecColors = JsonArrayInsert(jRecColors, bCan ? PoiPoisonColor(i) : jGray);
    }
    NuiSetBind(oPC, nToken, POI_BIND_REC_NAME,      jRecNames);
    NuiSetBind(oPC, nToken, POI_BIND_REC_INGR,      jRecIngrs);
    NuiSetBind(oPC, nToken, POI_BIND_REC_CRAFT_ENA, jRecEnas);
    NuiSetBind(oPC, nToken, POI_BIND_REC_COLOR,     jRecColors);
    NuiSetBind(oPC, nToken, POI_BIND_REC_LEN,       JsonInt(POI_VIAL_COUNT));
}

// ----------------------------------------------------------------
// Data feed — Arsenal
// ----------------------------------------------------------------

void FeedArsenal(object oPC, int nToken)
{
    int nActiveId = GetLocalInt(oPC, POI_LVAR_POISON_ID) - 1;
    string sActive = nActiveId >= 0
        ? "Na broni: " + PoiPoisonName(nActiveId) + "  [aktywna przez " + IntToString(FloatToInt(POI_WEAPON_DURATION)) + "s od naniesienia]"
        : "Broń bez trucizny. Pieczęć krwi pulsuje słabo…";
    NuiSetBind(oPC, nToken, POI_BIND_ARS_ACTIVE, JsonString(sActive));

    json jGray = NuiColor(100, 100, 100);
    json jPoisNames  = JsonArray();
    json jPoisCounts = JsonArray();
    json jPoisEnas   = JsonArray();
    json jPoisColors = JsonArray();
    int i;
    for(i = 0; i < POI_VIAL_COUNT; i++)
    {
        int nCnt = PoiGetStock(oPC, POI_POISON_OFFSET + i);
        jPoisNames  = JsonArrayInsert(jPoisNames,  JsonString(PoiPoisonName(i) + "  [" + PoiPoisonEffect(i) + "]"));
        jPoisCounts = JsonArrayInsert(jPoisCounts, JsonString("x" + IntToString(nCnt)));
        jPoisEnas   = JsonArrayInsert(jPoisEnas,   JsonBool(nCnt > 0));
        jPoisColors = JsonArrayInsert(jPoisColors, nCnt > 0 ? PoiPoisonColor(i) : jGray);
    }
    NuiSetBind(oPC, nToken, POI_BIND_ARS_NAME,      jPoisNames);
    NuiSetBind(oPC, nToken, POI_BIND_ARS_COUNT,     jPoisCounts);
    NuiSetBind(oPC, nToken, POI_BIND_ARS_APPLY_ENA, jPoisEnas);
    NuiSetBind(oPC, nToken, POI_BIND_ARS_COLOR,     jPoisColors);
    NuiSetBind(oPC, nToken, POI_BIND_ARS_LEN,       JsonInt(POI_VIAL_COUNT));
}

// ----------------------------------------------------------------
// Craft a poison vial
// ----------------------------------------------------------------

void PoiCraft(object oPC, int nToken, int nPoisonId)
{
    int i0, i1, i2;
    PoiGetRecipe(nPoisonId, i0, i1, i2);

    // Validate stock
    if(i0 >= 0 && PoiGetStock(oPC, i0) < 1)
    {
        SendMessageToPC(oPC, "[Trucizny] Brak składnika: " + PoiIngredientName(i0) + ".");
        return;
    }
    if(i1 >= 0 && PoiGetStock(oPC, i1) < 1)
    {
        SendMessageToPC(oPC, "[Trucizny] Brak składnika: " + PoiIngredientName(i1) + ".");
        return;
    }
    if(i2 >= 0 && PoiGetStock(oPC, i2) < 1)
    {
        SendMessageToPC(oPC, "[Trucizny] Brak składnika: " + PoiIngredientName(i2) + ".");
        return;
    }

    // Consume
    if(i0 >= 0) PoiModifyStock(oPC, i0, -1);
    if(i1 >= 0) PoiModifyStock(oPC, i1, -1);
    if(i2 >= 0) PoiModifyStock(oPC, i2, -1);

    PoiModifyStock(oPC, POI_POISON_OFFSET + nPoisonId, 1);

    string sFlavor;
    switch(nPoisonId)
    {
        case POI_VIAL_SLOW:
            sFlavor = "Bąbelki cieczy snują się leniwie, niczym śmierć powolna.";
            break;
        case POI_VIAL_PARALYZE:
            sFlavor = "Woń pająka unosi się nad czarną pianą.";
            break;
        case POI_VIAL_BLIND:
            sFlavor = "Mgła zamknięta w fiolce — mroku mądrość.";
            break;
        case POI_VIAL_WEAKEN:
            sFlavor = "Pyłek kwiatu pochodzi z ziemi, co nie zna słońca.";
            break;
        case POI_VIAL_LETHAL:
            sFlavor = "Ciemność w płynie. Czujesz, jak pali w palcach.";
            break;
        default:
            sFlavor = "Grzyb i żółć rozżarzają się razem bladym ogniem.";
            break;
    }

    SendMessageToPC(oPC, "[Trucizny] Sporządzono: " + PoiPoisonName(nPoisonId) + ". " + sFlavor);
    FloatingTextStringOnCreature("*warzy truciznę*", oPC, FALSE);
    ApplyEffectToObject(DURATION_TYPE_INSTANT, EffectVisualEffect(VFX_IMP_ACID_S), oPC);

    FeedWorkshop(oPC, nToken);
}

// ----------------------------------------------------------------
// Begin apply-to-weapon flow (targeting mode)
// ----------------------------------------------------------------

void PoiApplyToWeapon(object oPC, int nPoisonId)
{
    if(PoiGetStock(oPC, POI_POISON_OFFSET + nPoisonId) < 1)
    {
        SendMessageToPC(oPC, "[Trucizny] Nie masz tej trucizny.");
        return;
    }
    SetLocalInt(oPC, POI_LVAR_PENDING, nPoisonId + 1);
    SendMessageToPC(oPC, "[Trucizny] Wskaż broń, na którą nanieść "
                    + PoiPoisonName(nPoisonId) + ".");
    EnterTargetingMode(oPC, OBJECT_TYPE_ITEM);
}

// ----------------------------------------------------------------
// Apply the actual item property to the weapon
// ----------------------------------------------------------------

void PoiApplyEffect(object oPC, object oWeapon, int nPoisonId)
{
    // Strip any existing temporary properties from this module first
    // (DURATION_TYPE_TEMPORARY covers all temp props, so we only remove
    //  the ones we know about to avoid removing legitimate enchants)
    itemproperty ip = GetFirstItemProperty(oWeapon);
    while(GetIsItemPropertyValid(ip))
    {
        itemproperty ipNext = GetNextItemProperty(oWeapon);
        if(GetItemPropertyDurationType(ip) == DURATION_TYPE_TEMPORARY)
            RemoveItemProperty(oWeapon, ip);
        ip = ipNext;
    }

    float fDur = POI_WEAPON_DURATION;
    switch(nPoisonId)
    {
        case POI_VIAL_SLOW:
            AddItemProperty(DURATION_TYPE_TEMPORARY,
                ItemPropertyOnHitCastSpell(IP_CONST_ONHIT_CASTSPELL_SLOW, 5),
                oWeapon, fDur);
            break;
        case POI_VIAL_PARALYZE:
            AddItemProperty(DURATION_TYPE_TEMPORARY,
                ItemPropertyOnHitCastSpell(IP_CONST_ONHIT_CASTSPELL_HOLD_MONSTER, 5),
                oWeapon, fDur);
            break;
        case POI_VIAL_BLIND:
            AddItemProperty(DURATION_TYPE_TEMPORARY,
                ItemPropertyOnHitCastSpell(IP_CONST_ONHIT_CASTSPELL_BLINDNESS_AND_DEAFNESS, 5),
                oWeapon, fDur);
            break;
        case POI_VIAL_WEAKEN:
            AddItemProperty(DURATION_TYPE_TEMPORARY,
                ItemPropertyOnHitCastSpell(IP_CONST_ONHIT_CASTSPELL_BESTOW_CURSE, 5),
                oWeapon, fDur);
            break;
        case POI_VIAL_LETHAL:
            AddItemProperty(DURATION_TYPE_TEMPORARY,
                ItemPropertyDamageBonus(IP_CONST_DAMAGETYPE_ACID, IP_CONST_DAMAGEBONUS_2d6),
                oWeapon, fDur);
            break;
        case POI_VIAL_WITCHBANE:
            AddItemProperty(DURATION_TYPE_TEMPORARY,
                ItemPropertyOnHitCastSpell(IP_CONST_ONHIT_CASTSPELL_DISPEL_MAGIC, 5),
                oWeapon, fDur);
            break;
    }

    SetLocalInt(oPC, POI_LVAR_POISON_ID, nPoisonId + 1);

    // Schedule UI cleanup — item property auto-expires, we just clear tracking
    DelayCommand(fDur, PoiClearWeaponPoison(oPC));
}

// ----------------------------------------------------------------
// OnPlayerTarget handler — resolve weapon selection
// ----------------------------------------------------------------

void PoiOnWeaponTarget(object oPC)
{
    int nPending = GetLocalInt(oPC, POI_LVAR_PENDING) - 1;
    DeleteLocalInt(oPC, POI_LVAR_PENDING);

    if(nPending < 0) return;

    object oItem = GetTargetingModeSelectedObject();
    if(!GetIsObjectValid(oItem))
    {
        SendMessageToPC(oPC, "[Trucizny] Anulowano.");
        return;
    }

    if(GetItemPossessor(oItem) != oPC)
    {
        SendMessageToPC(oPC, "[Trucizny] Możesz nanosić truciznę tylko na własną broń.");
        return;
    }

    // Must have at least one stock (double-check race condition)
    if(PoiGetStock(oPC, POI_POISON_OFFSET + nPending) < 1)
    {
        SendMessageToPC(oPC, "[Trucizny] Fiolka opróżniła się.");
        return;
    }

    PoiModifyStock(oPC, POI_POISON_OFFSET + nPending, -1);
    PoiApplyEffect(oPC, oItem, nPending);

    string sFlavor;
    switch(nPending)
    {
        case POI_VIAL_SLOW:
            sFlavor = "Ostrze pokrywa się mazią zimną niczym bagno.";
            break;
        case POI_VIAL_PARALYZE:
            sFlavor = "Klinga drżąco wchłania jad pająka.";
            break;
        case POI_VIAL_BLIND:
            sFlavor = "Mgła osiadła na ostrzu; wyczuwasz stęchliznę.";
            break;
        case POI_VIAL_WEAKEN:
            sFlavor = "Pyłek osadza się w rowkach ostrza bez dźwięku.";
            break;
        case POI_VIAL_LETHAL:
            sFlavor = "Czarna ciecz sączy się wzdłuż ostrza jak krew.";
            break;
        default:
            sFlavor = "Runa na głowni rozbłyska bladym ogniem i gaśnie.";
            break;
    }

    SendMessageToPC(oPC, "[Trucizny] " + PoiPoisonName(nPending)
                    + " naniesiona na " + GetName(oItem) + ". " + sFlavor);
    FloatingTextStringOnCreature("*nanosi truciznę*", oPC, FALSE);
    ApplyEffectToObject(DURATION_TYPE_INSTANT,
        EffectVisualEffect(VFX_IMP_POISON_S), oPC);

    int nToken = NuiFindWindow(oPC, POI_WINDOW);
    if(nToken != 0)
        FeedArsenal(oPC, nToken);
}
