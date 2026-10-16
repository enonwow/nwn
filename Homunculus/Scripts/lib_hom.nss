// lib_hom.nss — UI construction, game logic, and maintenance for the Homunculus module
#include "lib_hom_def"

// ----------------------------------------------------------------
// VFX presence management
// ----------------------------------------------------------------

void HomApplyPresenceVFX(object oPC)
{
    // Apply a persistent iounstone orbit to signal the companion is active.
    // The effect is re-applied on every module enter so no slot tracking is needed.
    effect eVFX = EffectVisualEffect(HOM_VFX);
    ApplyEffectToObject(DURATION_TYPE_PERMANENT, eVFX, oPC);
}

void HomRemovePresenceVFX(object oPC)
{
    effect eCheck = GetFirstEffect(oPC);
    while(GetIsEffectValid(eCheck))
    {
        if(GetEffectType(eCheck) == EFFECT_TYPE_VISUALEFFECT)
        {
            int nVfxId = GetEffectInteger(eCheck, 0);
            if(nVfxId == HOM_VFX)
            {
                RemoveEffect(oPC, eCheck);
                return;
            }
        }
        eCheck = GetNextEffect(oPC);
    }
}

// ----------------------------------------------------------------
// Maintenance check — called on module enter and heartbeat
// ----------------------------------------------------------------

void HomCheckMaintenance(object oPC)
{
    if(!HomExists(oPC)) return;

    int nSecs = HomSecondsSinceFed(oPC);

    if(nSecs > HOM_STARVE_TIMEOUT)
    {
        // Apply one bond point of decay per login session while starving.
        // This avoids double-penalising if the player logs in and out quickly.
        HomLowerBond(oPC);

        if(!HomExists(oPC))
        {
            HomAddLog(oPC, "Twój homunkulus skonał z głodu. Więź pękła bezpowrotnie.");
            HomRemovePresenceVFX(oPC);
            SendMessageToPC(oPC, "[Homunkulus] Twój homunkulus umarł z głodu. Więź dobiegła końca.");
            FloatingTextStringOnCreature(
                "Homunkulus nie żyje… Pieczęć krwi wygasła.", oPC, FALSE);
            return;
        }

        int nBond = HomGetBondLevel(oPC);
        HomAddLog(oPC, "Homunkulus jest osłabiony z głodu. Więź: " + IntToString(nBond));
        SendMessageToPC(oPC,
            "[Homunkulus] Homunkulus jest głodny od ponad 48 godzin! Więź spada do "
            + IntToString(nBond) + " / 10. Nakarm go!");
    }
}

// ----------------------------------------------------------------
// Ability execution
// ----------------------------------------------------------------

void HomUseAbilityDetect(object oPC)
{
    int nEnemies = 0;
    int nTraps   = 0;
    object oNear = GetNearestCreature(CREATURE_TYPE_IS_ALIVE, TRUE, oPC, 1,
                                      CREATURE_TYPE_REPUTATION, REPUTATION_TYPE_ENEMY);
    while(GetIsObjectValid(oNear) && GetDistanceToObject(oNear) <= 15.0)
    {
        nEnemies++;
        oNear = GetNearestCreature(CREATURE_TYPE_IS_ALIVE, TRUE, oPC, nEnemies + 1,
                                   CREATURE_TYPE_REPUTATION, REPUTATION_TYPE_ENEMY);
    }

    object oTrap = GetNearestTrapToObject(oPC);
    if(GetIsObjectValid(oTrap) && GetDistanceBetween(oTrap, oPC) <= 15.0)
        nTraps = 1;

    string sMsg;
    if(nEnemies == 0 && nTraps == 0)
        sMsg = "Homunkulus mruczy spokojnie — w pobliżu nie wyczuwa żadnego zagrożenia.";
    else
    {
        sMsg = "Homunkulus szepcze ostrzegawczo!";
        if(nEnemies > 0)
            sMsg = sMsg + " Wrogów w zasięgu: " + IntToString(nEnemies) + ".";
        if(nTraps > 0)
            sMsg = sMsg + " Wyczuwa pułapkę w pobliżu!";
    }

    SendMessageToPC(oPC, "[Homunkulus] " + sMsg);
    FloatingTextStringOnCreature(sMsg, oPC, FALSE);
    ApplyEffectToObject(DURATION_TYPE_TEMPORARY,
        EffectVisualEffect(VFX_IMP_BLIND_DEAF_M), oPC, 1.5);
}

void HomUseAbilityScavenge(object oPC)
{
    string sResRef = HomRandomIngredientResref();
    object oItem   = CreateItemOnObject(sResRef, oPC);
    if(GetIsObjectValid(oItem))
    {
        string sMsg = "Homunkulus wraca z małą zdobyczą: " + GetName(oItem) + "!";
        SendMessageToPC(oPC, "[Homunkulus] " + sMsg);
        FloatingTextStringOnCreature("Homunkulus coś przyniósł!", oPC, FALSE);
    }
    else
    {
        SendMessageToPC(oPC, "[Homunkulus] Homunkulus wraca z pustymi rękami tym razem.");
    }
    ApplyEffectToObject(DURATION_TYPE_TEMPORARY,
        EffectVisualEffect(VFX_IMP_MAGIC_PROTECTION), oPC, 1.5);
}

void HomUseAbilityShield(object oPC)
{
    effect eTHP = EffectTemporaryHitpoints(10);
    effect eAC  = EffectACIncrease(2, AC_DODGE_BONUS);
    effect eVFX = EffectVisualEffect(VFX_IMP_MAGIC_PROTECTION);

    float fDur = 3600.0; // 1 hour
    ApplyEffectToObject(DURATION_TYPE_TEMPORARY, eTHP, oPC, fDur);
    ApplyEffectToObject(DURATION_TYPE_TEMPORARY, eAC,  oPC, fDur);
    ApplyEffectToObject(DURATION_TYPE_TEMPORARY, eVFX, oPC, 2.0);

    SendMessageToPC(oPC,
        "[Homunkulus] Alchemiczna substancja oplata twoje ciało. +10 HP, +2 AC przez godzinę.");
    FloatingTextStringOnCreature(
        "Pieczęć alchemiczna aktywna!", oPC, FALSE);
}

void HomUseAbilitySurge(object oPC)
{
    float fDur   = 1800.0; // 30 minutes
    effect eSave = EffectSavingThrowIncrease(SAVING_THROW_ALL, 4, SAVING_THROW_TYPE_ALL);
    effect eVFX  = EffectVisualEffect(VFX_IMP_PULSE_WIND);

    ApplyEffectToObject(DURATION_TYPE_TEMPORARY, eSave, oPC, fDur);
    ApplyEffectToObject(DURATION_TYPE_TEMPORARY, eVFX,  oPC, 2.0);

    SendMessageToPC(oPC,
        "[Homunkulus] Esencja przepływa przez ciebie. +4 do wszystkich rzutów obronnych przez 30 minut.");
    FloatingTextStringOnCreature(
        "Wzmocnienie Duszy aktywne!", oPC, FALSE);
}

void HomUseAbility(object oPC)
{
    if(!HomExists(oPC))
    {
        SendMessageToPC(oPC, "[Homunkulus] Nie posiadasz żywego homunkulus.");
        return;
    }
    if(HomAbilityOnCooldown(oPC))
    {
        SendMessageToPC(oPC, "[Homunkulus] Homunkulus jest wyczerpany. Wróć jutro.");
        return;
    }

    int nBond = HomGetBondLevel(oPC);
    HomMarkAbilityUsed(oPC);

    if(nBond <= 2)
    {
        HomAddLog(oPC, "Percepcja Zagrożeń — homunkulus skontrolował otoczenie.");
        HomUseAbilityDetect(oPC);
    }
    else if(nBond <= 5)
    {
        HomAddLog(oPC, "Zbieraczka Składników — homunkulus przyniósł reagent.");
        HomUseAbilityScavenge(oPC);
    }
    else if(nBond <= 8)
    {
        HomAddLog(oPC, "Tarcza Alchemiczna — aktywowano osłonę.");
        HomUseAbilityShield(oPC);
    }
    else
    {
        HomAddLog(oPC, "Wzmocnienie Duszy — esencja wzmocniła ciało.");
        HomUseAbilitySurge(oPC);
    }
}

// ----------------------------------------------------------------
// Feed logic
// ----------------------------------------------------------------

int HomCountFeedItems(object oPC)
{
    int nCount = 0;
    object oItem = GetFirstItemInInventory(oPC);
    while(GetIsObjectValid(oItem))
    {
        if(GetTag(oItem) == HOM_FEED_ITEM_TAG)
            nCount++;
        oItem = GetNextItemInInventory(oPC);
    }
    return nCount;
}

void HomConsumeOneFeedItem(object oPC)
{
    object oItem = GetFirstItemInInventory(oPC);
    while(GetIsObjectValid(oItem))
    {
        if(GetTag(oItem) == HOM_FEED_ITEM_TAG)
        {
            int nStack = GetItemStackSize(oItem);
            if(nStack > 1)
                SetItemStackSize(oItem, nStack - 1);
            else
                DestroyObject(oItem);
            return;
        }
        oItem = GetNextItemInInventory(oPC);
    }
}

void HomFeedCompanion(object oPC)
{
    if(!HomExists(oPC))
    {
        SendMessageToPC(oPC, "[Homunkulus] Nie posiadasz żywego homunkulus.");
        return;
    }
    if(HomCountFeedItems(oPC) < 1)
    {
        SendMessageToPC(oPC, "[Homunkulus] Potrzebujesz reagentu karmienia (tag: " + HOM_FEED_ITEM_TAG + ").");
        return;
    }

    int nSecsFed = HomSecondsSinceFed(oPC);
    HomConsumeOneFeedItem(oPC);
    HomFeed(oPC);

    // Bond grows if fed on time (within the normal window)
    if(nSecsFed >= HOM_FEED_INTERVAL)
    {
        HomRaiseBond(oPC);
        int nBond = HomGetBondLevel(oPC);
        HomAddLog(oPC, "Nakarmiony — więź wzrosła do " + IntToString(nBond) + ".");
        SendMessageToPC(oPC,
            "[Homunkulus] Homunkulus zjada porcję z apetytem. Więź wzrasta do "
            + IntToString(nBond) + " / 10.");
        FloatingTextStringOnCreature("Więź się wzmocniła!", oPC, FALSE);
    }
    else
    {
        HomAddLog(oPC, "Nakarmiony — więź stabilna.");
        SendMessageToPC(oPC, "[Homunkulus] Homunkulus przyjmuje pożywienie. Więź stabilna.");
    }
}

// ----------------------------------------------------------------
// Sacrifice
// ----------------------------------------------------------------

void HomSacrifice(object oPC)
{
    if(!HomExists(oPC))
    {
        SendMessageToPC(oPC, "[Homunkulus] Nie posiadasz homunkulus, który można poświęcić.");
        return;
    }
    if(HomGetBondLevel(oPC) < 10)
    {
        SendMessageToPC(oPC, "[Homunkulus] Więź musi osiągnąć poziom 10, aby móc dokonać poświęcenia.");
        return;
    }

    HomAddLog(oPC, "POŚWIĘCENIE — homunkulus złożony w ofierze.");
    HomKill(oPC);
    HomRemovePresenceVFX(oPC);

    // Powerful one-time boon: full HP restore + powerful regen for 10 minutes
    effect eHP  = EffectHeal(GetMaxHitPoints(oPC));
    effect eReg = EffectRegenerate(5, 6.0); // 5 HP every 6 seconds
    effect eVFX = EffectVisualEffect(VFX_IMP_PULSE_HOLY);

    ApplyEffectToObject(DURATION_TYPE_INSTANT,   eHP,  oPC);
    ApplyEffectToObject(DURATION_TYPE_TEMPORARY, eReg, oPC, 600.0);
    ApplyEffectToObject(DURATION_TYPE_TEMPORARY, eVFX, oPC, 3.0);

    SendMessageToPC(oPC,
        "[Homunkulus] Homunkulus roztopił się w potoku gorącej esencji, wypełniając twoje ciało życiem."
        " Pełne HP przywrócone. Regeneracja 5 HP/6s przez 10 minut.");
    FloatingTextStringOnCreature(
        "Homunkulus poświęcony… jego siła stała się twoją.", oPC, FALSE);
}

// ----------------------------------------------------------------
// Crafting
// ----------------------------------------------------------------

int HomCountReagents(object oPC)
{
    int nCount = 0;
    object oItem = GetFirstItemInInventory(oPC);
    while(GetIsObjectValid(oItem))
    {
        if(GetTag(oItem) == HOM_REAGENT_TAG)
            nCount += GetItemStackSize(oItem);
        oItem = GetNextItemInInventory(oPC);
    }
    return nCount;
}

void HomConsumeReagents(object oPC, int nNeeded)
{
    int nLeft = nNeeded;
    object oItem = GetFirstItemInInventory(oPC);
    while(GetIsObjectValid(oItem) && nLeft > 0)
    {
        if(GetTag(oItem) == HOM_REAGENT_TAG)
        {
            int nStack = GetItemStackSize(oItem);
            if(nStack <= nLeft)
            {
                nLeft -= nStack;
                DestroyObject(oItem);
            }
            else
            {
                SetItemStackSize(oItem, nStack - nLeft);
                nLeft = 0;
            }
        }
        oItem = GetNextItemInInventory(oPC);
    }
}

void HomCraft(object oPC)
{
    if(HomExists(oPC))
    {
        SendMessageToPC(oPC, "[Homunkulus] Posiadasz już żywego homunkulus. Nie możesz stworzyć drugiego.");
        return;
    }
    if(HomCountReagents(oPC) < HOM_REAGENT_NEEDED)
    {
        SendMessageToPC(oPC,
            "[Homunkulus] Potrzebujesz " + IntToString(HOM_REAGENT_NEEDED)
            + " reagentów alchemicznych (tag: " + HOM_REAGENT_TAG + ").");
        return;
    }

    HomConsumeReagents(oPC, HOM_REAGENT_NEEDED);
    HomCreate(oPC, "Bezimienny");
    HomAddLog(oPC, "Homunkulus stworzony.");
    HomApplyPresenceVFX(oPC);

    SendMessageToPC(oPC,
        "[Homunkulus] Mieszanina bulgocze, krzepnie i otwiera oczy. Homunkulus żyje!"
        " Użyj panelu, by nadać mu imię.");
    FloatingTextStringOnCreature(
        "Homunkulus przebudził się!", oPC, FALSE);
}

// ----------------------------------------------------------------
// NUI — swap group content builders
// ----------------------------------------------------------------

json HomBuildStatusView(object oPC)
{
    float fBtnH  = GetNuiScaleDimension(oPC, 30.0);
    float fDescH = GetNuiScaleDimension(oPC, 80.0);
    float fLogH  = GetNuiScaleDimension(oPC, 22.0);

    // Bond progress bar (NuiProgress expects a float bind 0.0–1.0)
    json jBondLbl = NuiLabel(NuiBind(HOM_BIND_BOND_LBL),
                             JsonInt(NUI_HALIGN_LEFT), JsonInt(NUI_VALIGN_MIDDLE));
    jBondLbl = NuiHeight(jBondLbl, fBtnH);

    json jBar = NuiProgress(NuiBind(HOM_BIND_BOND_PROG));
    jBar = NuiHeight(jBar, GetNuiScaleDimension(oPC, 14.0));

    // Status line (hunger/health)
    json jStatus = NuiLabel(NuiBind(HOM_BIND_STATUS),
                            JsonInt(NUI_HALIGN_LEFT), JsonInt(NUI_VALIGN_MIDDLE));
    jStatus = NuiStyleForegroundColor(jStatus, NuiBind(HOM_BIND_STATUS_CLR));
    jStatus = NuiHeight(jStatus, fBtnH);

    // Ability section
    json jANameLbl = NuiLabel(NuiBind(HOM_BIND_ANAME),
                              JsonInt(NUI_HALIGN_LEFT), JsonInt(NUI_VALIGN_MIDDLE));
    jANameLbl = NuiHeight(jANameLbl, fBtnH);

    json jADesc = NuiGroup(NuiText(NuiBind(HOM_BIND_ADESC), FALSE), TRUE, NUI_SCROLLBARS_NONE);
    jADesc = NuiHeight(jADesc, fDescH);

    json jUseBtn = NuiButton(NuiBind(HOM_BIND_ABTN_LBL));
    jUseBtn = NuiId(jUseBtn, HOM_BTN_USE);
    jUseBtn = NuiEnabled(jUseBtn, NuiBind(HOM_BIND_AENA));
    jUseBtn = NuiHeight(jUseBtn, fBtnH);

    // Feed / Rename / Sacrifice row
    json jFeedBtn = NuiButton(JsonString("Nakarm"));
    jFeedBtn = NuiId(jFeedBtn, HOM_BTN_FEED);
    jFeedBtn = NuiEnabled(jFeedBtn, NuiBind(HOM_BIND_FEED_ENA));
    jFeedBtn = NuiWidth(jFeedBtn, GetNuiScaleDimension(oPC, 120.0));
    jFeedBtn = NuiHeight(jFeedBtn, fBtnH);
    jFeedBtn = NuiTooltip(jFeedBtn, JsonString("Zużywa 1 item (tag: hom_feed)."));

    json jRenBtn = NuiButton(JsonString("Zmień imię"));
    jRenBtn = NuiId(jRenBtn, HOM_BTN_RENAME);
    jRenBtn = NuiWidth(jRenBtn, GetNuiScaleDimension(oPC, 110.0));
    jRenBtn = NuiHeight(jRenBtn, fBtnH);

    json jSacBtn = NuiButton(JsonString("Poświęć"));
    jSacBtn = NuiId(jSacBtn, HOM_BTN_SACRIFICE);
    jSacBtn = NuiEnabled(jSacBtn, NuiBind(HOM_BIND_SAC_ENA));
    jSacBtn = NuiWidth(jSacBtn, GetNuiScaleDimension(oPC, 100.0));
    jSacBtn = NuiHeight(jSacBtn, fBtnH);
    jSacBtn = NuiTooltip(jSacBtn,
        JsonString("Poświęca homunkulus w zamian za potężny jednorazowy efekt.\n"
                   "Wymaga więzi poziomu 10. Nie do odwrócenia!"));

    json jActRow = JsonArray();
    jActRow = JsonArrayInsert(jActRow, jFeedBtn);
    jActRow = JsonArrayInsert(jActRow, NuiSpacer());
    jActRow = JsonArrayInsert(jActRow, jRenBtn);
    jActRow = JsonArrayInsert(jActRow, jSacBtn);

    // Log section (last 3 entries)
    json jLog0 = NuiLabel(NuiBind(HOM_BIND_LOG0), JsonInt(NUI_HALIGN_LEFT), JsonInt(NUI_VALIGN_MIDDLE));
    jLog0 = NuiStyleForegroundColor(jLog0, NuiColor(160, 160, 160));
    jLog0 = NuiHeight(jLog0, fLogH);

    json jLog1 = NuiLabel(NuiBind(HOM_BIND_LOG1), JsonInt(NUI_HALIGN_LEFT), JsonInt(NUI_VALIGN_MIDDLE));
    jLog1 = NuiStyleForegroundColor(jLog1, NuiColor(130, 130, 130));
    jLog1 = NuiHeight(jLog1, fLogH);

    json jLog2 = NuiLabel(NuiBind(HOM_BIND_LOG2), JsonInt(NUI_HALIGN_LEFT), JsonInt(NUI_VALIGN_MIDDLE));
    jLog2 = NuiStyleForegroundColor(jLog2, NuiColor(100, 100, 100));
    jLog2 = NuiHeight(jLog2, fLogH);

    // Assemble column
    json jCol = JsonArray();
    jCol = JsonArrayInsert(jCol, jBondLbl);
    jCol = JsonArrayInsert(jCol, jBar);
    jCol = JsonArrayInsert(jCol, CreateEmptyRow(oPC, 6.0));
    jCol = JsonArrayInsert(jCol, jStatus);
    jCol = JsonArrayInsert(jCol, CreateEmptyRow(oPC, 8.0));
    jCol = JsonArrayInsert(jCol, jANameLbl);
    jCol = JsonArrayInsert(jCol, jADesc);
    jCol = JsonArrayInsert(jCol, jUseBtn);
    jCol = JsonArrayInsert(jCol, CreateEmptyRow(oPC, 8.0));
    jCol = JsonArrayInsert(jCol, NuiRow(jActRow));
    jCol = JsonArrayInsert(jCol, CreateEmptyRow(oPC, 10.0));
    jCol = JsonArrayInsert(jCol, jLog0);
    jCol = JsonArrayInsert(jCol, jLog1);
    jCol = JsonArrayInsert(jCol, jLog2);

    // Center with side spacers
    json jSide = NuiCol(JsonArrayInsert(JsonArray(), NuiSpacer()));
    float fContentW = GetNuiScaleDimension(oPC, 560.0);
    json jMain = JsonArray();
    jMain = JsonArrayInsert(jMain, jSide);
    jMain = JsonArrayInsert(jMain, NuiWidth(NuiCol(jCol), fContentW));
    jMain = JsonArrayInsert(jMain, jSide);
    return NuiRow(jMain);
}

json HomBuildCraftView(object oPC)
{
    float fBtnH = GetNuiScaleDimension(oPC, 30.0);

    json jMsg = NuiText(NuiBind(HOM_BIND_CRAFT_MSG), FALSE);
    jMsg = NuiHeight(jMsg, GetNuiScaleDimension(oPC, 160.0));

    json jBtn = NuiButton(JsonString("Stwórz Homunkulus"));
    jBtn = NuiId(jBtn, HOM_BTN_CRAFT);
    jBtn = NuiHeight(jBtn, fBtnH);
    jBtn = NuiWidth(jBtn, GetNuiScaleDimension(oPC, 220.0));

    json jBtnRow = JsonArray();
    jBtnRow = JsonArrayInsert(jBtnRow, NuiSpacer());
    jBtnRow = JsonArrayInsert(jBtnRow, jBtn);
    jBtnRow = JsonArrayInsert(jBtnRow, NuiSpacer());

    json jCol = JsonArray();
    jCol = JsonArrayInsert(jCol, jMsg);
    jCol = JsonArrayInsert(jCol, CreateEmptyRow(oPC, 10.0));
    jCol = JsonArrayInsert(jCol, NuiRow(jBtnRow));

    json jSide = NuiCol(JsonArrayInsert(JsonArray(), NuiSpacer()));
    float fW   = GetNuiScaleDimension(oPC, 560.0);
    json jMain = JsonArray();
    jMain = JsonArrayInsert(jMain, jSide);
    jMain = JsonArrayInsert(jMain, NuiWidth(NuiCol(jCol), fW));
    jMain = JsonArrayInsert(jMain, jSide);
    return NuiRow(jMain);
}

json HomBuildRenameView(object oPC)
{
    float fBtnH = GetNuiScaleDimension(oPC, 30.0);

    json jLbl = NuiLabel(JsonString("Nowe imię homunkulus:"),
                         JsonInt(NUI_HALIGN_LEFT), JsonInt(NUI_VALIGN_MIDDLE));
    jLbl = NuiHeight(jLbl, fBtnH);

    json jField = NuiTextEdit(JsonString(""), NuiBind(HOM_BIND_NAME_TXT), HOM_MAX_NAME, FALSE);
    jField = NuiHeight(jField, fBtnH);

    json jOk = NuiButton(JsonString("Potwierdź"));
    jOk = NuiId(jOk, HOM_BTN_RENAME_OK);
    jOk = NuiWidth(jOk, GetNuiScaleDimension(oPC, 110.0));
    jOk = NuiHeight(jOk, fBtnH);

    json jCc = NuiButton(JsonString("Anuluj"));
    jCc = NuiId(jCc, HOM_BTN_RENAME_CC);
    jCc = NuiWidth(jCc, GetNuiScaleDimension(oPC, 90.0));
    jCc = NuiHeight(jCc, fBtnH);

    json jBtnRow = JsonArray();
    jBtnRow = JsonArrayInsert(jBtnRow, NuiSpacer());
    jBtnRow = JsonArrayInsert(jBtnRow, jOk);
    jBtnRow = JsonArrayInsert(jBtnRow, jCc);

    json jCol = JsonArray();
    jCol = JsonArrayInsert(jCol, CreateEmptyRow(oPC, 40.0));
    jCol = JsonArrayInsert(jCol, jLbl);
    jCol = JsonArrayInsert(jCol, jField);
    jCol = JsonArrayInsert(jCol, CreateEmptyRow(oPC, 10.0));
    jCol = JsonArrayInsert(jCol, NuiRow(jBtnRow));

    json jSide = NuiCol(JsonArrayInsert(JsonArray(), NuiSpacer()));
    float fW   = GetNuiScaleDimension(oPC, 400.0);
    json jMain = JsonArray();
    jMain = JsonArrayInsert(jMain, jSide);
    jMain = JsonArrayInsert(jMain, NuiWidth(NuiCol(jCol), fW));
    jMain = JsonArrayInsert(jMain, jSide);
    return NuiRow(jMain);
}

// ----------------------------------------------------------------
// Feed functions — push data into existing binds
// ----------------------------------------------------------------

void HomShowMain(object oPC, int nToken)
{
    NuiSetGroupLayout(oPC, nToken, HOM_GRP_SWAP,
        HomExists(oPC) ? HomBuildStatusView(oPC) : HomBuildCraftView(oPC));
    SetLocalInt(oPC, HOM_LVAR_VIEW, 0);

    if(!HomExists(oPC))
    {
        string sCraftMsg =
            "Nie posiadasz homunkulus.\n\n"
            "Aby stworzyć towarzysza, zbierz " + IntToString(HOM_REAGENT_NEEDED)
            + " reagenty alchemiczne (tag: " + HOM_REAGENT_TAG + ")\n"
            "i naciśnij przycisk poniżej.\n\n"
            "Więź z homunkulus rośnie z każdym karmieniem. Wraz z jej wzrostem\n"
            "dostępne stają się nowe zdolności:\n"
            "  • Więź 1-2  :  Percepcja Zagrożeń\n"
            "  • Więź 3-5  :  Zbieraczka Składników\n"
            "  • Więź 6-8  :  Tarcza Alchemiczna\n"
            "  • Więź 9-10 :  Wzmocnienie Duszy\n"
            "  • Więź 10   :  Opcja Poświęcenia";
        NuiSetBind(oPC, nToken, HOM_BIND_CRAFT_MSG, JsonString(sCraftMsg));
        return;
    }

    json jData  = HomGetData(oPC);
    int  nBond  = JsonGetInt(JsonObjectGet(jData, "bond_level"));
    string sName = JsonGetString(JsonObjectGet(jData, "name"));
    int  nFedSecs = HomSecondsSinceFed(oPC);
    int  bOnCD   = HomAbilityOnCooldown(oPC);

    // Title line
    NuiSetBind(oPC, nToken, HOM_BIND_TITLE, JsonString(sName));

    // Bond label and progress bar
    string sBondLbl = "Więź: " + IntToString(nBond) + " / 10  •  " + HomTierName(nBond);
    NuiSetBind(oPC, nToken, HOM_BIND_BOND_LBL,  JsonString(sBondLbl));
    NuiSetBind(oPC, nToken, HOM_BIND_BOND_PROG,  JsonFloat(IntToFloat(nBond) / 10.0));

    // Maintenance status
    string sStatus;
    json   jStatusClr;
    if(nFedSecs < HOM_FEED_INTERVAL)
    {
        sStatus    = "Najedzony — kolejne karmienie za "
                   + IntToString((HOM_FEED_INTERVAL - nFedSecs) / 3600)
                   + " godz.";
        jStatusClr = NuiColor(120, 200, 100);
    }
    else if(nFedSecs < HOM_STARVE_TIMEOUT)
    {
        sStatus    = "Głodny! Nakarm homunkulus, by więź nie osłabła.";
        jStatusClr = NuiColor(240, 180, 40);
    }
    else
    {
        sStatus    = "Zagłodzony! Więź opada. Nakarm natychmiast!";
        jStatusClr = NuiColor(220, 60, 60);
    }
    NuiSetBind(oPC, nToken, HOM_BIND_STATUS,     JsonString(sStatus));
    NuiSetBind(oPC, nToken, HOM_BIND_STATUS_CLR, jStatusClr);

    // Ability info
    NuiSetBind(oPC, nToken, HOM_BIND_ANAME, JsonString(HomAbilityName(nBond)));
    NuiSetBind(oPC, nToken, HOM_BIND_ADESC, JsonString(HomAbilityDesc(nBond)));

    string sAbtnLbl = bOnCD ? "Wyczerpany (odnawia się jutro)" : "Użyj zdolności";
    NuiSetBind(oPC, nToken, HOM_BIND_ABTN_LBL, JsonString(sAbtnLbl));
    NuiSetBind(oPC, nToken, HOM_BIND_AENA,     JsonBool(!bOnCD));
    NuiSetBind(oPC, nToken, HOM_BIND_FEED_ENA, JsonBool(TRUE));
    NuiSetBind(oPC, nToken, HOM_BIND_SAC_ENA,  JsonBool(nBond >= 10));

    // Log
    json jLog = HomGetLog(oPC, 3);
    int nLogCount = JsonGetLength(jLog);
    NuiSetBind(oPC, nToken, HOM_BIND_LOG0,
        JsonString(nLogCount > 0 ? JsonGetString(JsonArrayGet(jLog, 0)) : ""));
    NuiSetBind(oPC, nToken, HOM_BIND_LOG1,
        JsonString(nLogCount > 1 ? JsonGetString(JsonArrayGet(jLog, 1)) : ""));
    NuiSetBind(oPC, nToken, HOM_BIND_LOG2,
        JsonString(nLogCount > 2 ? JsonGetString(JsonArrayGet(jLog, 2)) : ""));
}

void HomShowRename(object oPC, int nToken)
{
    NuiSetGroupLayout(oPC, nToken, HOM_GRP_SWAP, HomBuildRenameView(oPC));
    SetLocalInt(oPC, HOM_LVAR_VIEW, 1);

    json jData = HomGetData(oPC);
    string sName = JsonGetString(JsonObjectGet(jData, "name"));
    NuiSetBind(oPC, nToken, HOM_BIND_NAME_TXT, JsonString(sName));
}

// ----------------------------------------------------------------
// Window creation
// ----------------------------------------------------------------

void HomCreateWindow(object oPC)
{
    if(NuiFindWindow(oPC, HOM_WINDOW) != 0)
    {
        int nToken = NuiFindWindow(oPC, HOM_WINDOW);
        HomShowMain(oPC, nToken);
        return;
    }

    float fGuiW = IntToFloat(GetPlayerDeviceProperty(oPC, PLAYER_DEVICE_PROPERTY_GUI_WIDTH));
    float fGuiH = IntToFloat(GetPlayerDeviceProperty(oPC, PLAYER_DEVICE_PROPERTY_GUI_HEIGHT));
    float fW    = GetNuiScaleDimension(oPC, HOM_W);
    float fH    = GetNuiScaleDimension(oPC, HOM_H);
    float fCX   = (fGuiW - fW) / 2.0;
    float fCY   = (fGuiH - fH) / 2.0;
    json  jGeom = NuiRect(fCX, fCY, fW, fH);

    float fBtnH = GetNuiScaleDimension(oPC, 30.0);

    // Title bar: companion name + close button
    json jTitleLbl = NuiLabel(NuiBind(HOM_BIND_TITLE),
                              JsonInt(NUI_HALIGN_LEFT), JsonInt(NUI_VALIGN_MIDDLE));
    jTitleLbl = NuiHeight(jTitleLbl, fBtnH);

    json jCloseBtn = NuiButton(JsonString("X"));
    jCloseBtn = NuiId(jCloseBtn, HOM_BTN_CLOSE);
    jCloseBtn = NuiWidth(jCloseBtn, GetNuiScaleDimension(oPC, 30.0));
    jCloseBtn = NuiHeight(jCloseBtn, fBtnH);

    json jTitleRow = JsonArray();
    jTitleRow = JsonArrayInsert(jTitleRow, jTitleLbl);
    jTitleRow = JsonArrayInsert(jTitleRow, jCloseBtn);

    // Swap group — holds either the status view or the craft/rename view
    json jSwapGrp = NuiGroup(
        HomExists(oPC) ? HomBuildStatusView(oPC) : HomBuildCraftView(oPC),
        FALSE, NUI_SCROLLBARS_NONE);
    jSwapGrp = NuiId(jSwapGrp, HOM_GRP_SWAP);

    json jRoot = NuiCol(JsonArray());
    json jChildren = JsonArray();
    jChildren = JsonArrayInsert(jChildren, NuiRow(jTitleRow));
    jChildren = JsonArrayInsert(jChildren, jSwapGrp);
    jRoot = NuiCol(jChildren);

    json jWin = NuiWindow(jRoot,
        JsonBool(FALSE),
        NuiBind(HOM_WIN_GEOM),
        JsonBool(FALSE),
        JsonBool(FALSE),
        JsonBool(FALSE),
        JsonBool(TRUE),
        JsonBool(FALSE));

    int nToken = NuiCreate(oPC, jWin, HOM_WINDOW, HOM_EV_SCRIPT);
    NuiSetBind(oPC, nToken, HOM_WIN_GEOM, jGeom);

    // Initial title for the title bar bind (used in both views)
    json jData = HomGetData(oPC);
    string sTitle = HomExists(oPC)
        ? JsonGetString(JsonObjectGet(jData, "name"))
        : "Laboratorium Alchemiczne";
    NuiSetBind(oPC, nToken, HOM_BIND_TITLE, JsonString(sTitle));

    HomShowMain(oPC, nToken);
}
