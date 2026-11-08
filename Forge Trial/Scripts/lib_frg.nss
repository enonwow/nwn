// Core library for the Forge Trial module.
// Implements item helpers, property application, NUI construction, and the
// oscillating heat-meter update loop.

#include "lib_frg_def"

// ----------------------------------------------------------------
// Item slot helpers
// ----------------------------------------------------------------

// Returns the item in logical slot 0=main hand, 1=offhand, 2=chest.
object FrgGetSlotItem(object oPC, int nSlot)
{
    if(nSlot == 0) return GetItemInSlot(INVENTORY_SLOT_RIGHTHAND, oPC);
    if(nSlot == 1) return GetItemInSlot(INVENTORY_SLOT_LEFTHAND,  oPC);
    return               GetItemInSlot(INVENTORY_SLOT_CHEST,      oPC);
}

int FrgIsShield(object oItem)
{
    int nType = GetBaseItemType(oItem);
    return (nType == BASE_ITEM_SMALLSHIELD ||
            nType == BASE_ITEM_LARGESHIELD ||
            nType == BASE_ITEM_TOWERSHIELD);
}

int FrgIsArmor(object oItem)
{
    return (GetBaseItemType(oItem) == BASE_ITEM_ARMOR);
}

int FrgIsWeapon(object oItem)
{
    return (!FrgIsShield(oItem) && !FrgIsArmor(oItem));
}

// Returns the forge level for an item from the database.
int FrgGetItemLevel(object oItem)
{
    return FrgDBGetLevel(GetObjectUUID(oItem));
}

// Gold cost for one strike attempt on an item at the given forge level.
int FrgStrikeCost(int nCurrentLevel)
{
    return (nCurrentLevel + 1) * FRG_GOLD_BASE;
}

// ----------------------------------------------------------------
// Item property application
// ----------------------------------------------------------------

// Strip all forge-applied properties (enhancement bonus and bonus damage/saves).
void FrgRemoveForgeProperties(object oItem)
{
    itemproperty ip = GetFirstItemProperty(oItem);
    while(GetIsItemPropertyValid(ip))
    {
        int nType = GetItemPropertyType(ip);
        if(nType == ITEM_PROPERTY_ENHANCEMENT_BONUS     ||
           nType == ITEM_PROPERTY_AC_BONUS              ||
           nType == ITEM_PROPERTY_BONUS_SAVING_THROW    ||
           nType == ITEM_PROPERTY_DAMAGE_BONUS)
        {
            RemoveItemProperty(oItem, ip);
        }
        ip = GetNextItemProperty(oItem);
    }
}

// Apply item properties matching the given forge level (0 = remove all, 1-5 = buff).
void FrgApplyForgeLevel(object oItem, int nLevel)
{
    FrgRemoveForgeProperties(oItem);
    if(nLevel <= 0) return;

    if(FrgIsArmor(oItem) || FrgIsShield(oItem))
    {
        // AC enhancement bonus
        IPSafeAddItemProperty(oItem, ItemPropertyACBonus(nLevel), 0.0, X_ITEMPROP_EXECUTE_NOW);

        // Extra saving throw bonus at higher levels
        if(nLevel >= 4)
            IPSafeAddItemProperty(oItem,
                ItemPropertyBonusSavingThrow(IP_CONST_SAVEVS_ALL, nLevel - 2),
                0.0, X_ITEMPROP_EXECUTE_NOW);
    }
    else
    {
        // Weapon enhancement bonus
        IPSafeAddItemProperty(oItem,
            ItemPropertyEnhancementBonus(nLevel), 0.0, X_ITEMPROP_EXECUTE_NOW);

        // Bonus fire damage at level 3 (1d4) and level 5 (1d6)
        if(nLevel >= 5)
            IPSafeAddItemProperty(oItem,
                ItemPropertyDamageBonus(IP_CONST_DAMAGETYPE_FIRE, IP_CONST_DAMAGEBONUS_1d6),
                0.0, X_ITEMPROP_EXECUTE_NOW);
        else if(nLevel >= 3)
            IPSafeAddItemProperty(oItem,
                ItemPropertyDamageBonus(IP_CONST_DAMAGETYPE_FIRE, IP_CONST_DAMAGEBONUS_1d4),
                0.0, X_ITEMPROP_EXECUTE_NOW);
    }
}

// ----------------------------------------------------------------
// Zone logic
// ----------------------------------------------------------------

// Classify a meter position into a zone index:
// 0=ruin, 1=cold, 2=warm, 3=sweet, 4=hot, 5=ruin
int FrgGetZone(int nPos)
{
    if(nPos <= FRG_ZONE_COLD_HI)                              return 1; // too cold
    if(nPos <= FRG_ZONE_WARM_HI)                              return 2; // warm
    if(nPos <= FRG_ZONE_SWEET_HI)                             return 3; // prime heat
    if(nPos <= FRG_ZONE_HOT_HI)                               return 4; // too hot
    return 5;                                                            // ruin
}

string FrgGetZoneLabel(int nPos)
{
    int nZone = FrgGetZone(nPos);
    if(nZone == 1) return "ZBYT ZIMNA";
    if(nZone == 2) return "CIEPŁA";
    if(nZone == 3) return "ŻAR KUŹNI";
    if(nZone == 4) return "ZBYT GORĄCA";
    return                "PŁOMIEŃ ZAGŁADY";
}

json FrgGetZoneColor(int nPos)
{
    int nZone = FrgGetZone(nPos);
    if(nZone == 1) return NuiColor(100, 160, 220);   // cold blue
    if(nZone == 2) return NuiColor(220, 190, 80);    // warm yellow
    if(nZone == 3) return NuiColor(80, 220, 80);     // sweet green
    if(nZone == 4) return NuiColor(220, 130, 50);    // hot orange
    return                NuiColor(220, 60,  60);    // ruin red
}

// Returns the strike outcome for a given meter position and forge level.
// -1 = ruin (degrade), 0 = miss (no effect), 1 = weak (50% +1), 2 = perfect (+1)
int FrgGetStrikeResult(int nPos)
{
    int nZone = FrgGetZone(nPos);
    if(nZone == 3)             return 2;    // prime heat → perfect
    if(nZone == 2 || nZone == 4) return 1; // warm/hot → weak
    if(nZone == 1)             return 0;    // too cold → miss
    return -1;                              // ruin
}

// ----------------------------------------------------------------
// NUI window construction
// ----------------------------------------------------------------

// Builds one slot group widget for slot index nSlot.
json FrgBuildSlotGroup(object oPC, int nSlot)
{
    float fBtnH  = GetNuiScaleDimension(oPC, 70.0);
    float fBtnW  = GetNuiScaleDimension(oPC, 160.0);
    float fIconS = GetNuiScaleDimension(oPC, 36.0);
    float fLblH  = GetNuiScaleDimension(oPC, 18.0);

    string sSuffix = IntToString(nSlot);

    json jIcon = NuiImage(NuiBind(FRG_BIND_SLOT_ICON + sSuffix));
    jIcon = NuiWidth(jIcon,  fIconS);
    jIcon = NuiHeight(jIcon, fIconS);

    json jName = NuiLabel(NuiBind(FRG_BIND_SLOT_NAME + sSuffix),
                          JsonInt(NUI_HALIGN_LEFT), JsonInt(NUI_VALIGN_MIDDLE));
    jName = NuiHeight(jName, fLblH);

    json jLvl  = NuiLabel(NuiBind(FRG_BIND_SLOT_LVL + sSuffix),
                          JsonInt(NUI_HALIGN_LEFT), JsonInt(NUI_VALIGN_MIDDLE));
    jLvl  = NuiHeight(jLvl, fLblH);
    jLvl  = NuiStyleForegroundColor(jLvl, GetNuiColorNwnGold());

    json jTextCol = NuiCol(JsonArrayInsert(JsonArrayInsert(JsonArray(), jName), jLvl));

    json jInnerRow = JsonArray();
    jInnerRow = JsonArrayInsert(jInnerRow, jIcon);
    jInnerRow = JsonArrayInsert(jInnerRow, jTextCol);

    json jGroup = NuiGroup(NuiRow(jInnerRow), TRUE, NUI_SCROLLBARS_NONE);
    jGroup = NuiId(jGroup,          FRG_BTN_SLOT + sSuffix);
    jGroup = NuiEnabled(jGroup,     NuiBind(FRG_BIND_SLOT_ENA + sSuffix));
    jGroup = NuiEncouraged(jGroup,  NuiBind(FRG_BIND_SLOT_ENC + sSuffix));
    jGroup = NuiWidth(jGroup,  fBtnW);
    jGroup = NuiHeight(jGroup, fBtnH);

    return jGroup;
}

json FrgBuildWindow(object oPC)
{
    float fH30  = GetNuiScaleDimension(oPC, 30.0);
    float fH24  = GetNuiScaleDimension(oPC, 24.0);
    float fH20  = GetNuiScaleDimension(oPC, 20.0);
    float fH40  = GetNuiScaleDimension(oPC, 40.0);
    float fH10  = GetNuiScaleDimension(oPC, 10.0);
    float fW80  = GetNuiScaleDimension(oPC, 80.0);
    float fWFull = GetNuiScaleDimension(oPC, FRG_W - 20.0);

    // ---- Slot row ----
    json jSlotRow = JsonArray();
    jSlotRow = JsonArrayInsert(jSlotRow, FrgBuildSlotGroup(oPC, 0));
    jSlotRow = JsonArrayInsert(jSlotRow, FrgBuildSlotGroup(oPC, 1));
    jSlotRow = JsonArrayInsert(jSlotRow, FrgBuildSlotGroup(oPC, 2));
    json jSlots = NuiRow(jSlotRow);

    // ---- Item info area ----
    json jItemName = NuiLabel(NuiBind(FRG_BIND_ITEM_NAME),
                              JsonInt(NUI_HALIGN_CENTER), JsonInt(NUI_VALIGN_MIDDLE));
    jItemName = NuiHeight(jItemName, fH30);

    json jItemInfo = NuiLabel(NuiBind(FRG_BIND_ITEM_INFO),
                              JsonInt(NUI_HALIGN_CENTER), JsonInt(NUI_VALIGN_MIDDLE));
    jItemInfo = NuiHeight(jItemInfo, fH24);
    jItemInfo = NuiStyleForegroundColor(jItemInfo, GetNuiColorNwnGold());

    json jItemCost = NuiLabel(NuiBind(FRG_BIND_ITEM_COST),
                              JsonInt(NUI_HALIGN_CENTER), JsonInt(NUI_VALIGN_MIDDLE));
    jItemCost = NuiHeight(jItemCost, fH20);

    // ---- Heat meter section ----
    json jMeterTitle = NuiLabel(JsonString("WSKAŹNIK ŻARU KUŹNI"),
                                JsonInt(NUI_HALIGN_CENTER), JsonInt(NUI_VALIGN_MIDDLE));
    jMeterTitle = NuiHeight(jMeterTitle, fH24);

    json jMeter = NuiProgressBar(NuiBind(FRG_BIND_METER_VAL));
    jMeter = NuiHeight(jMeter, fH30);

    json jZoneLbl = NuiLabel(NuiBind(FRG_BIND_ZONE_LBL),
                             JsonInt(NUI_HALIGN_CENTER), JsonInt(NUI_VALIGN_MIDDLE));
    jZoneLbl = NuiHeight(jZoneLbl, fH24);
    jZoneLbl = NuiStyleForegroundColor(jZoneLbl, NuiBind(FRG_BIND_ZONE_COLOR));

    // ---- Result area ----
    json jResult = NuiLabel(NuiBind(FRG_BIND_RESULT_TXT),
                            JsonInt(NUI_HALIGN_CENTER), JsonInt(NUI_VALIGN_MIDDLE));
    jResult = NuiHeight(jResult, fH30);
    jResult = NuiStyleForegroundColor(jResult, NuiBind(FRG_BIND_RESULT_COL));

    // ---- Bottom row: strikes label + strike button ----
    json jStrikesLbl = NuiLabel(NuiBind(FRG_BIND_STRIKES),
                                JsonInt(NUI_HALIGN_LEFT), JsonInt(NUI_VALIGN_MIDDLE));
    jStrikesLbl = NuiHeight(jStrikesLbl, fH40);

    json jStrikeBtn = NuiButton(JsonString("UDERZ!"));
    jStrikeBtn = NuiId(jStrikeBtn,      FRG_BTN_STRIKE);
    jStrikeBtn = NuiEnabled(jStrikeBtn, NuiBind(FRG_BIND_STRIKE_ENA));
    jStrikeBtn = NuiWidth(jStrikeBtn,   fW80);
    jStrikeBtn = NuiHeight(jStrikeBtn,  fH40);

    json jBottomRow = JsonArray();
    jBottomRow = JsonArrayInsert(jBottomRow, jStrikesLbl);
    jBottomRow = JsonArrayInsert(jBottomRow, NuiSpacer());
    jBottomRow = JsonArrayInsert(jBottomRow, jStrikeBtn);

    // ---- Assemble root column ----
    json jRoot = JsonArray();
    jRoot = JsonArrayInsert(jRoot, jSlots);
    jRoot = JsonArrayInsert(jRoot, CreateEmptyRow(oPC, fH10));
    jRoot = JsonArrayInsert(jRoot, NuiRow(JsonArrayInsert(JsonArray(), jItemName)));
    jRoot = JsonArrayInsert(jRoot, NuiRow(JsonArrayInsert(JsonArray(), jItemInfo)));
    jRoot = JsonArrayInsert(jRoot, NuiRow(JsonArrayInsert(JsonArray(), jItemCost)));
    jRoot = JsonArrayInsert(jRoot, CreateEmptyRow(oPC, fH10));
    jRoot = JsonArrayInsert(jRoot, NuiRow(JsonArrayInsert(JsonArray(), jMeterTitle)));
    jRoot = JsonArrayInsert(jRoot, NuiRow(JsonArrayInsert(JsonArray(), jMeter)));
    jRoot = JsonArrayInsert(jRoot, NuiRow(JsonArrayInsert(JsonArray(), jZoneLbl)));
    jRoot = JsonArrayInsert(jRoot, CreateEmptyRow(oPC, fH10));
    jRoot = JsonArrayInsert(jRoot, NuiRow(JsonArrayInsert(JsonArray(), jResult)));
    jRoot = JsonArrayInsert(jRoot, NuiRow(jBottomRow));

    json jWin = NuiWindow(
        NuiCol(jRoot),
        JsonString("Próba Kuźni"),
        NuiBind(WINDOW_GEOMETRY),
        JsonBool(FALSE),    // not resizable
        JsonBool(FALSE),    // not collapsible
        JsonBool(TRUE),     // closable
        JsonBool(FALSE),    // not transparent
        JsonBool(TRUE)      // border
    );
    return jWin;
}

// ----------------------------------------------------------------
// Window open / data feed
// ----------------------------------------------------------------

void FrgOpenWindow(object oPC)
{
    if(NuiFindWindow(oPC, FRG_WINDOW) != 0)
        return;

    json jGeom = NuiRect(-1.0, -1.0,
                         GetNuiScaleDimension(oPC, FRG_W),
                         GetNuiScaleDimension(oPC, FRG_H));
    int nToken = NuiCreate(oPC, FrgBuildWindow(oPC), FRG_WINDOW);
    if(nToken == 0) return;

    NuiSetBind(oPC, nToken, WINDOW_GEOMETRY,    jGeom);
    NuiSetBindWatch(oPC, nToken, WINDOW_GEOMETRY, TRUE);

    NuiSetGroupScript(oPC, nToken, FRG_EV_SCRIPT);

    // Default selection: first valid slot
    int nSel = -1;
    int i;
    for(i = 0; i < FRG_SLOT_COUNT && nSel == -1; i++)
    {
        if(GetIsObjectValid(FrgGetSlotItem(oPC, i)))
            nSel = i;
    }
    SetLocalInt(oPC, FRG_LVAR_SEL_SLOT, nSel);
    SetLocalInt(oPC, FRG_LVAR_STRIKES,  FRG_STRIKES_MAX);

    FrgFeedSlots(oPC, nToken);
    FrgFeedSelectedItem(oPC, nToken);

    // Initialise result / zone text
    NuiSetBind(oPC, nToken, FRG_BIND_RESULT_TXT, JsonString("Wybierz przedmiot i uderz we właściwym momencie."));
    NuiSetBind(oPC, nToken, FRG_BIND_RESULT_COL, NuiColor(200, 200, 200));
    NuiSetBind(oPC, nToken, FRG_BIND_METER_VAL,  JsonFloat(0.0));
    NuiSetBind(oPC, nToken, FRG_BIND_ZONE_LBL,   JsonString("—"));
    NuiSetBind(oPC, nToken, FRG_BIND_ZONE_COLOR, NuiColor(160, 160, 160));

    if(nSel >= 0)
        FrgStartMeter(oPC, nToken);
}

void FrgFeedSlots(object oPC, int nToken)
{
    int nSel = GetLocalInt(oPC, FRG_LVAR_SEL_SLOT);
    int i;
    for(i = 0; i < FRG_SLOT_COUNT; i++)
    {
        string sSuffix = IntToString(i);
        object oItem   = FrgGetSlotItem(oPC, i);
        int    bValid  = GetIsObjectValid(oItem);

        string sIcon  = "";
        string sName  = "(pusty slot)";
        string sLevel = "";

        if(bValid)
        {
            sIcon  = Get2DAString("baseitems", "DefaultIcon", GetBaseItemType(oItem));
            sName  = GetName(oItem);
            if(GetStringLength(sName) > 18)
                sName = GetStringLeft(sName, 16) + "..";
            int nLvl = FrgGetItemLevel(oItem);
            if(nLvl > 0)
                sLevel = "Kuźnia: " + IntToString(nLvl) + "/" + IntToString(FRG_MAX_LEVEL);
        }

        NuiSetBind(oPC, nToken, FRG_BIND_SLOT_ICON + sSuffix, JsonString(sIcon));
        NuiSetBind(oPC, nToken, FRG_BIND_SLOT_NAME + sSuffix, JsonString(sName));
        NuiSetBind(oPC, nToken, FRG_BIND_SLOT_LVL  + sSuffix, JsonString(sLevel));
        NuiSetBind(oPC, nToken, FRG_BIND_SLOT_ENA  + sSuffix, JsonBool(bValid));
        NuiSetBind(oPC, nToken, FRG_BIND_SLOT_ENC  + sSuffix, JsonBool(i == nSel));
    }
}

// Descriptive text for the next forge level.
string FrgNextLevelDesc(object oItem, int nLevel)
{
    if(nLevel >= FRG_MAX_LEVEL) return "Przedmiot osiągnął kres kuźni.";

    int nNext = nLevel + 1;
    if(FrgIsArmor(oItem) || FrgIsShield(oItem))
    {
        if(nNext <= 3) return "+" + IntToString(nNext) + " Pancerz (Wzmocnienie)";
        if(nNext == 4) return "+" + IntToString(nNext) + " Pancerz + +2 Ochrona przed zgubą";
        return               "+" + IntToString(nNext) + " Pancerz + +3 Ochrona przed zgubą";
    }
    else
    {
        if(nNext <= 2) return "+" + IntToString(nNext) + " Broń (Wzmocnienie)";
        if(nNext == 3) return "+" + IntToString(nNext) + " Broń + 1k4 Ogień";
        if(nNext == 4) return "+" + IntToString(nNext) + " Broń + 1k4 Ogień";
        return               "+" + IntToString(nNext) + " Broń + 1k6 Ogień";
    }
}

void FrgFeedSelectedItem(object oPC, int nToken)
{
    int nSel  = GetLocalInt(oPC, FRG_LVAR_SEL_SLOT);
    int nLeft = GetLocalInt(oPC, FRG_LVAR_STRIKES);

    NuiSetBind(oPC, nToken, FRG_BIND_STRIKES,
               JsonString("Pozostałe uderzenia: " + IntToString(nLeft)));

    if(nSel < 0)
    {
        NuiSetBind(oPC, nToken, FRG_BIND_ITEM_NAME, JsonString("Brak wyposażenia w szczelinach kuźni."));
        NuiSetBind(oPC, nToken, FRG_BIND_ITEM_INFO, JsonString("Załóż broń lub zbroję, by móc wykuć."));
        NuiSetBind(oPC, nToken, FRG_BIND_ITEM_COST, JsonString(""));
        NuiSetBind(oPC, nToken, FRG_BIND_STRIKE_ENA, JsonBool(FALSE));
        return;
    }

    object oItem = FrgGetSlotItem(oPC, nSel);
    if(!GetIsObjectValid(oItem))
    {
        NuiSetBind(oPC, nToken, FRG_BIND_ITEM_NAME, JsonString("Slot jest pusty."));
        NuiSetBind(oPC, nToken, FRG_BIND_ITEM_INFO, JsonString(""));
        NuiSetBind(oPC, nToken, FRG_BIND_ITEM_COST, JsonString(""));
        NuiSetBind(oPC, nToken, FRG_BIND_STRIKE_ENA, JsonBool(FALSE));
        return;
    }

    int nLevel = FrgGetItemLevel(oItem);

    if(nLevel >= FRG_MAX_LEVEL)
    {
        NuiSetBind(oPC, nToken, FRG_BIND_ITEM_NAME, JsonString(GetName(oItem)));
        NuiSetBind(oPC, nToken, FRG_BIND_ITEM_INFO, JsonString("Przedmiot osiągnął szczyt doskonałości kuźni."));
        NuiSetBind(oPC, nToken, FRG_BIND_ITEM_COST, JsonString(""));
        NuiSetBind(oPC, nToken, FRG_BIND_STRIKE_ENA, JsonBool(FALSE));
        return;
    }

    int nCooldown = FrgDBCooldownRemaining(GetObjectUUID(oItem));
    if(nCooldown > 0)
    {
        int nMin = nCooldown / 60;
        int nSec = nCooldown % 60;
        NuiSetBind(oPC, nToken, FRG_BIND_ITEM_NAME, JsonString(GetName(oItem)));
        NuiSetBind(oPC, nToken, FRG_BIND_ITEM_INFO,
            JsonString("Kuźnia musi ostygnąć. Przerwa: " + IntToString(nMin) + "m " + IntToString(nSec) + "s."));
        NuiSetBind(oPC, nToken, FRG_BIND_ITEM_COST, JsonString(""));
        NuiSetBind(oPC, nToken, FRG_BIND_STRIKE_ENA, JsonBool(FALSE));
        return;
    }

    int nCost = FrgStrikeCost(nLevel);
    int bCanStrike = (nLeft > 0 && GetGold(oPC) >= nCost);

    NuiSetBind(oPC, nToken, FRG_BIND_ITEM_NAME,
               JsonString(GetName(oItem) + "   [Poz. " + IntToString(nLevel) + "/" + IntToString(FRG_MAX_LEVEL) + "]"));
    NuiSetBind(oPC, nToken, FRG_BIND_ITEM_INFO,
               JsonString(FrgNextLevelDesc(oItem, nLevel)));
    NuiSetBind(oPC, nToken, FRG_BIND_ITEM_COST,
               JsonString("Koszt uderzenia: " + IntToString(nCost) + " złota"));
    NuiSetBind(oPC, nToken, FRG_BIND_STRIKE_ENA, JsonBool(bCanStrike));
}

void FrgFeedMeterZone(object oPC, int nToken, int nPos)
{
    NuiSetBind(oPC, nToken, FRG_BIND_ZONE_LBL,   JsonString(FrgGetZoneLabel(nPos)));
    NuiSetBind(oPC, nToken, FRG_BIND_ZONE_COLOR,  FrgGetZoneColor(nPos));
}

// ----------------------------------------------------------------
// Oscillating heat meter
// ----------------------------------------------------------------

void FrgTickMeter(object oPC, int nToken)
{
    if(!GetLocalInt(oPC, FRG_LVAR_METER_RUN)) return;
    if(NuiFindWindow(oPC, FRG_WINDOW) != nToken) return;

    int nPos = GetLocalInt(oPC, FRG_LVAR_METER_POS);
    int nDir = GetLocalInt(oPC, FRG_LVAR_METER_DIR);
    if(nDir == 0) nDir = 1;

    // Speed scales with the current forge level of the selected item
    int nSpeed = FRG_SPEED_BASE;
    int nSel   = GetLocalInt(oPC, FRG_LVAR_SEL_SLOT);
    if(nSel >= 0)
    {
        object oItem = FrgGetSlotItem(oPC, nSel);
        if(GetIsObjectValid(oItem))
            nSpeed = FRG_SPEED_BASE + FrgGetItemLevel(oItem) * 2;
    }

    nPos += nDir * nSpeed;
    if(nPos >= 100) { nPos = 100; nDir = -1; }
    if(nPos <= 0)   { nPos = 0;   nDir =  1; }

    SetLocalInt(oPC, FRG_LVAR_METER_POS, nPos);
    SetLocalInt(oPC, FRG_LVAR_METER_DIR, nDir);

    NuiSetBind(oPC, nToken, FRG_BIND_METER_VAL, JsonFloat(IntToFloat(nPos) / 100.0));
    FrgFeedMeterZone(oPC, nToken, nPos);

    DelayCommand(FRG_METER_TICK, FrgTickMeter(oPC, nToken));
}

void FrgStartMeter(object oPC, int nToken)
{
    FrgStopMeter(oPC);
    SetLocalInt(oPC, FRG_LVAR_METER_POS, 0);
    SetLocalInt(oPC, FRG_LVAR_METER_DIR, 1);
    SetLocalInt(oPC, FRG_LVAR_METER_RUN, 1);
    DelayCommand(FRG_METER_TICK, FrgTickMeter(oPC, nToken));
}

void FrgStopMeter(object oPC)
{
    SetLocalInt(oPC, FRG_LVAR_METER_RUN, 0);
}

// ----------------------------------------------------------------
// Strike execution
// ----------------------------------------------------------------

void FrgExecuteStrike(object oPC, int nToken)
{
    int nSel = GetLocalInt(oPC, FRG_LVAR_SEL_SLOT);
    if(nSel < 0) return;

    object oItem = FrgGetSlotItem(oPC, nSel);
    if(!GetIsObjectValid(oItem)) return;

    string sItemUuid  = GetObjectUUID(oItem);
    string sOwnerUuid = GetObjectUUID(oPC);

    int nLevel    = FrgGetItemLevel(oItem);
    int nCost     = FrgStrikeCost(nLevel);
    int nLeft     = GetLocalInt(oPC, FRG_LVAR_STRIKES);

    if(nLeft <= 0) return;
    if(!FrgDBCanForge(sItemUuid))
    {
        SendMessageToPC(oPC, "[Kuźnia] Przedmiot musi ostygnąć — za wcześnie na kolejną próbę.");
        return;
    }
    if(GetGold(oPC) < nCost)
    {
        SendMessageToPC(oPC, "[Kuźnia] Niewystarczająco złota na kolejne uderzenie.");
        return;
    }
    if(nLevel >= FRG_MAX_LEVEL)
    {
        SendMessageToPC(oPC, "[Kuźnia] Ten przedmiot nie może już być wzmocniony.");
        return;
    }

    // Deduct gold
    AssignCommand(oPC, TakeGoldFromCreature(nCost, oPC, TRUE));

    int nPos    = GetLocalInt(oPC, FRG_LVAR_METER_POS);
    int nResult = FrgGetStrikeResult(nPos);

    string sResultMsg;
    json   jResultCol;
    int    nNewLevel = nLevel;

    switch(nResult)
    {
        case -1:
            nNewLevel = (nLevel > 0) ? nLevel - 1 : 0;
            sResultMsg = "Płomień zniszczył metal! Jakość obniżona.";
            jResultCol = NuiColor(220, 60, 60);
            break;
        case 0:
            sResultMsg = "Zbyt zimna kuźnia — cios nic nie dał.";
            jResultCol = NuiColor(100, 160, 220);
            break;
        case 1:
            // Warm or Too Hot zone: 50% chance of success
            if(d6() >= 4)
            {
                nNewLevel  = nLevel + 1;
                if(nNewLevel >= FRG_MAX_LEVEL)
                    sResultMsg = "KUNSZT MISTRZOWSKI! Broń osiągnęła szczyt doskonałości!";
                else
                    sResultMsg = "Dobre uderzenie! Przedmiot wzmocniony na poziom " + IntToString(nNewLevel) + ".";
                jResultCol = NuiColor(140, 220, 100);
            }
            else
            {
                sResultMsg = "Niezłe trafienie, lecz nie dość precyzyjne — bez efektu.";
                jResultCol = NuiColor(200, 180, 80);
            }
            break;
        case 2:
            nNewLevel = nLevel + 1;
            if(nNewLevel >= FRG_MAX_LEVEL)
                sResultMsg = "KUNSZT MISTRZOWSKI! Broń osiągnęła szczyt doskonałości!";
            else
                sResultMsg = "Mistrowski cios! Przedmiot wzmocniony na poziom " + IntToString(nNewLevel) + ".";
            jResultCol = NuiColor(80, 220, 80);
            break;
        default:
            sResultMsg = "Kuźnia milczy.";
            jResultCol = NuiColor(200, 200, 200);
            break;
    }

    // Apply changes
    if(nNewLevel != nLevel)
        FrgApplyForgeLevel(oItem, nNewLevel);

    FrgDBUpsertItem(sItemUuid, sOwnerUuid, nNewLevel, 1);

    // Update strikes remaining
    nLeft--;
    SetLocalInt(oPC, FRG_LVAR_STRIKES, nLeft);

    NuiSetBind(oPC, nToken, FRG_BIND_RESULT_TXT, JsonString(sResultMsg));
    NuiSetBind(oPC, nToken, FRG_BIND_RESULT_COL, jResultCol);

    FrgFeedSlots(oPC, nToken);
    FrgFeedSelectedItem(oPC, nToken);

    if(nLeft <= 0)
    {
        FrgStopMeter(oPC);
        NuiSetBind(oPC, nToken, FRG_BIND_METER_VAL,  JsonFloat(0.0));
        NuiSetBind(oPC, nToken, FRG_BIND_ZONE_LBL,   JsonString("Kuźnia musi ostygnąć."));
        NuiSetBind(oPC, nToken, FRG_BIND_ZONE_COLOR, NuiColor(160, 160, 160));
    }
}

// ----------------------------------------------------------------
// Cleanup on close
// ----------------------------------------------------------------

void FrgCleanup(object oPC)
{
    FrgStopMeter(oPC);
    DeleteLocalInt(oPC, FRG_LVAR_SEL_SLOT);
    DeleteLocalInt(oPC, FRG_LVAR_METER_POS);
    DeleteLocalInt(oPC, FRG_LVAR_METER_DIR);
    DeleteLocalInt(oPC, FRG_LVAR_METER_RUN);
    DeleteLocalInt(oPC, FRG_LVAR_STRIKES);
}
