#include "lib_fam_def"

// ================================================================
// NUI layout builders
// ================================================================

json FamBuildBondingLayout(object oPC)
{
    float fBtnH = GetNuiScaleDimension(oPC, 32.0);
    float fBtnW = GetNuiScaleDimension(oPC, 76.0);
    float fDescH = GetNuiScaleDimension(oPC, 160.0);

    // Header label
    json jHeader = NuiLabel(JsonString("Wybierz swojego towarzysza:"),
        JsonInt(NUI_HALIGN_LEFT), JsonInt(NUI_VALIGN_MIDDLE));
    jHeader = NuiHeight(jHeader, fBtnH);

    // Five type buttons in a row
    json jTypeBtns = JsonArray();
    int i;
    for(i = 0; i < FAM_TYPE_COUNT; i++)
    {
        json jBtn = NuiButton(JsonString(FamTypeName(i)));
        jBtn = NuiId(jBtn, FAM_BTN_TYPE + IntToString(i));
        jBtn = NuiWidth(jBtn, fBtnW);
        jBtn = NuiHeight(jBtn, fBtnH);
        jTypeBtns = JsonArrayInsert(jTypeBtns, jBtn);
    }

    // Description text area
    json jDesc = NuiGroup(NuiText(NuiBind(FAM_BIND_TYPE_DESC), FALSE),
        TRUE, NUI_SCROLLBARS_Y);
    jDesc = NuiHeight(jDesc, fDescH);

    // Bond button row
    json jBondBtn = NuiButton(JsonString("Zwiąż się z towarzyszem"));
    jBondBtn = NuiId(jBondBtn, FAM_BTN_BOND);
    jBondBtn = NuiEnabled(jBondBtn, NuiBind(FAM_BIND_BOND_ENA));
    jBondBtn = NuiHeight(jBondBtn, fBtnH);

    json jBotRow = JsonArray();
    jBotRow = JsonArrayInsert(jBotRow, NuiSpacer());
    jBotRow = JsonArrayInsert(jBotRow, jBondBtn);
    jBotRow = JsonArrayInsert(jBotRow, NuiSpacer());

    // Assemble column
    json jCol = JsonArray();
    jCol = JsonArrayInsert(jCol, jHeader);
    jCol = JsonArrayInsert(jCol, NuiRow(jTypeBtns));
    jCol = JsonArrayInsert(jCol, jDesc);
    jCol = JsonArrayInsert(jCol, NuiRow(jBotRow));

    float fContentW = GetNuiScaleDimension(oPC, 420.0);
    json jSide = NuiCol(JsonArrayInsert(JsonArray(), NuiSpacer()));
    json jMainRow = JsonArray();
    jMainRow = JsonArrayInsert(jMainRow, jSide);
    jMainRow = JsonArrayInsert(jMainRow, NuiWidth(NuiCol(jCol), fContentW));
    jMainRow = JsonArrayInsert(jMainRow, jSide);
    return NuiRow(jMainRow);
}

json FamBuildMainLayout(object oPC)
{
    float fBtnH = GetNuiScaleDimension(oPC, 30.0);
    float fBtnW = GetNuiScaleDimension(oPC, 130.0);
    float fLblH = GetNuiScaleDimension(oPC, 22.0);

    // ---- Status block ----
    json jTitle = NuiLabel(NuiBind(FAM_BIND_TITLE),
        JsonInt(NUI_HALIGN_CENTER), JsonInt(NUI_VALIGN_MIDDLE));
    jTitle = NuiHeight(jTitle, fBtnH);

    json jBondRow = JsonArray();
    json jBondLbl = NuiLabel(NuiBind(FAM_BIND_BOND_LVL),
        JsonInt(NUI_HALIGN_LEFT), JsonInt(NUI_VALIGN_MIDDLE));
    jBondLbl = NuiHeight(jBondLbl, fLblH);
    json jHpLbl = NuiLabel(NuiBind(FAM_BIND_HP_TXT),
        JsonInt(NUI_HALIGN_RIGHT), JsonInt(NUI_VALIGN_MIDDLE));
    jHpLbl = NuiHeight(jHpLbl, fLblH);
    jBondRow = JsonArrayInsert(jBondRow, jBondLbl);
    jBondRow = JsonArrayInsert(jBondRow, NuiSpacer());
    jBondRow = JsonArrayInsert(jBondRow, jHpLbl);

    json jStatusLbl = NuiLabel(NuiBind(FAM_BIND_STATUS),
        JsonInt(NUI_HALIGN_LEFT), JsonInt(NUI_VALIGN_MIDDLE));
    jStatusLbl = NuiHeight(jStatusLbl, fLblH);

    json jCarryLbl = NuiLabel(NuiBind(FAM_BIND_CARRY_TXT),
        JsonInt(NUI_HALIGN_LEFT), JsonInt(NUI_VALIGN_MIDDLE));
    jCarryLbl = NuiHeight(jCarryLbl, fLblH);

    // ---- Command buttons (2 columns × 3 rows) ----
    json jScoutBtn = NuiButton(NuiBind(FAM_BIND_SCOUT_LBL));
    jScoutBtn = NuiId(jScoutBtn, FAM_BTN_SCOUT);
    jScoutBtn = NuiEnabled(jScoutBtn, NuiBind(FAM_BIND_SCOUT_ENA));
    jScoutBtn = NuiWidth(jScoutBtn, fBtnW);
    jScoutBtn = NuiHeight(jScoutBtn, fBtnH);

    json jForageBtn = NuiButton(NuiBind(FAM_BIND_FORAGE_LBL));
    jForageBtn = NuiId(jForageBtn, FAM_BTN_FORAGE);
    jForageBtn = NuiEnabled(jForageBtn, NuiBind(FAM_BIND_FORAGE_ENA));
    jForageBtn = NuiWidth(jForageBtn, fBtnW);
    jForageBtn = NuiHeight(jForageBtn, fBtnH);

    json jVigilBtn = NuiButton(NuiBind(FAM_BIND_VIGIL_LBL));
    jVigilBtn = NuiId(jVigilBtn, FAM_BTN_VIGIL);
    jVigilBtn = NuiEnabled(jVigilBtn, NuiBind(FAM_BIND_VIGIL_ENA));
    jVigilBtn = NuiWidth(jVigilBtn, fBtnW);
    jVigilBtn = NuiHeight(jVigilBtn, fBtnH);

    json jCarryBtn = NuiButton(NuiBind(FAM_BIND_CARRY_LBL));
    jCarryBtn = NuiId(jCarryBtn, FAM_BTN_CARRY);
    jCarryBtn = NuiEnabled(jCarryBtn, NuiBind(FAM_BIND_CARRY_ENA));
    jCarryBtn = NuiWidth(jCarryBtn, fBtnW);
    jCarryBtn = NuiHeight(jCarryBtn, fBtnH);

    json jDismissBtn = NuiButton(NuiBind(FAM_BIND_DISMISS_LBL));
    jDismissBtn = NuiId(jDismissBtn, FAM_BTN_DISMISS);
    jDismissBtn = NuiEnabled(jDismissBtn, NuiBind(FAM_BIND_DISMISS_ENA));
    jDismissBtn = NuiWidth(jDismissBtn, fBtnW);
    jDismissBtn = NuiHeight(jDismissBtn, fBtnH);

    json jRetrvBtn = NuiButton(NuiBind(FAM_BIND_RETRV_LBL));
    jRetrvBtn = NuiId(jRetrvBtn, FAM_BTN_RETRIEVE);
    jRetrvBtn = NuiEnabled(jRetrvBtn, NuiBind(FAM_BIND_RETRV_ENA));
    jRetrvBtn = NuiWidth(jRetrvBtn, fBtnW);
    jRetrvBtn = NuiHeight(jRetrvBtn, fBtnH);

    // Row 1: Scout | Forage
    json jRow1 = JsonArray();
    jRow1 = JsonArrayInsert(jRow1, jScoutBtn);
    jRow1 = JsonArrayInsert(jRow1, NuiSpacer());
    jRow1 = JsonArrayInsert(jRow1, jForageBtn);

    // Row 2: Vigil | Carry
    json jRow2 = JsonArray();
    jRow2 = JsonArrayInsert(jRow2, jVigilBtn);
    jRow2 = JsonArrayInsert(jRow2, NuiSpacer());
    jRow2 = JsonArrayInsert(jRow2, jCarryBtn);

    // Row 3: Dismiss | Retrieve
    json jRow3 = JsonArray();
    jRow3 = JsonArrayInsert(jRow3, jDismissBtn);
    jRow3 = JsonArrayInsert(jRow3, NuiSpacer());
    jRow3 = JsonArrayInsert(jRow3, jRetrvBtn);

    // Release button (destructive — full width, bottom)
    json jReleaseBtn = NuiButton(JsonString("Uwolnij towarzysza (nieodwracalne)"));
    jReleaseBtn = NuiId(jReleaseBtn, FAM_BTN_RELEASE);
    jReleaseBtn = NuiHeight(jReleaseBtn, fBtnH);

    // Assemble
    json jCol = JsonArray();
    jCol = JsonArrayInsert(jCol, jTitle);
    jCol = JsonArrayInsert(jCol, NuiRow(jBondRow));
    jCol = JsonArrayInsert(jCol, jStatusLbl);
    jCol = JsonArrayInsert(jCol, jCarryLbl);
    jCol = JsonArrayInsert(jCol, NuiRow(jRow1));
    jCol = JsonArrayInsert(jCol, NuiRow(jRow2));
    jCol = JsonArrayInsert(jCol, NuiRow(jRow3));
    jCol = JsonArrayInsert(jCol, jReleaseBtn);

    float fContentW = GetNuiScaleDimension(oPC, 420.0);
    json jSide = NuiCol(JsonArrayInsert(JsonArray(), NuiSpacer()));
    json jMainRow = JsonArray();
    jMainRow = JsonArrayInsert(jMainRow, jSide);
    jMainRow = JsonArrayInsert(jMainRow, NuiWidth(NuiCol(jCol), fContentW));
    jMainRow = JsonArrayInsert(jMainRow, jSide);
    return NuiRow(jMainRow);
}

// ================================================================
// Window open / swap
// ================================================================

void FamSwapToBonding(object oPC, int nToken)
{
    NuiSetGroupLayout(oPC, nToken, FAM_GRP_SWAP, FamBuildBondingLayout(oPC));
    FeedBondingView(oPC, nToken);
}

void FamSwapToMain(object oPC, int nToken, json jFam)
{
    NuiSetGroupLayout(oPC, nToken, FAM_GRP_SWAP, FamBuildMainLayout(oPC));
    FeedMainView(oPC, nToken, jFam);
}

void FamOpenWindow(object oPC)
{
    int nToken = NuiFindWindow(oPC, FAM_WINDOW);
    if(nToken != 0)
    {
        json jFam = FamGet(oPC);
        if(JsonGetType(jFam) != JSON_TYPE_NULL)
            FamSwapToMain(oPC, nToken, jFam);
        else
            FamSwapToBonding(oPC, nToken);
        return;
    }

    float fCX = (IntToFloat(GetPlayerDeviceProperty(oPC, PLAYER_DEVICE_PROPERTY_GUI_WIDTH))
                 - GetNuiScaleDimension(oPC, FAM_W)) / 2.0;
    float fCY = (IntToFloat(GetPlayerDeviceProperty(oPC, PLAYER_DEVICE_PROPERTY_GUI_HEIGHT))
                 - GetNuiScaleDimension(oPC, FAM_H)) / 2.0;
    json jGeom = NuiRect(fCX, fCY,
        GetNuiScaleDimension(oPC, FAM_W),
        GetNuiScaleDimension(oPC, FAM_H));

    float fBtnH = GetNuiScaleDimension(oPC, 30.0);
    json jCloseBtn = NuiButton(JsonString("X"));
    jCloseBtn = NuiId(jCloseBtn, FAM_BTN_CLOSE);
    jCloseBtn = NuiWidth(jCloseBtn, GetNuiScaleDimension(oPC, 30.0));
    jCloseBtn = NuiHeight(jCloseBtn, fBtnH);

    json jTitleLbl = NuiLabel(JsonString("Znamię Wiedźmy"),
        JsonInt(NUI_HALIGN_LEFT), JsonInt(NUI_VALIGN_MIDDLE));
    jTitleLbl = NuiHeight(jTitleLbl, fBtnH);

    json jTopRow = JsonArray();
    jTopRow = JsonArrayInsert(jTopRow, jTitleLbl);
    jTopRow = JsonArrayInsert(jTopRow, NuiSpacer());
    jTopRow = JsonArrayInsert(jTopRow, jCloseBtn);

    json jFam = FamGet(oPC);
    json jInitLayout = (JsonGetType(jFam) != JSON_TYPE_NULL)
        ? FamBuildMainLayout(oPC)
        : FamBuildBondingLayout(oPC);

    json jSwapGrp = NuiGroup(jInitLayout, FALSE, NUI_SCROLLBARS_NONE);
    jSwapGrp = NuiId(jSwapGrp, FAM_GRP_SWAP);

    json jRootChildren = JsonArray();
    jRootChildren = JsonArrayInsert(jRootChildren, NuiRow(jTopRow));
    jRootChildren = JsonArrayInsert(jRootChildren, jSwapGrp);
    json jRoot = NuiCol(jRootChildren);

    json jWin = NuiWindow(jRoot,
        JsonBool(FALSE),
        NuiBind(FAM_WIN_GEOM),
        JsonBool(FALSE),
        JsonBool(FALSE),
        JsonBool(FALSE),
        JsonBool(TRUE),
        JsonBool(FALSE));

    nToken = NuiCreate(oPC, jWin, FAM_WINDOW, FAM_EV_SCRIPT);
    NuiSetBind(oPC, nToken, FAM_WIN_GEOM, jGeom);

    if(JsonGetType(jFam) != JSON_TYPE_NULL)
        FeedMainView(oPC, nToken, jFam);
    else
        FeedBondingView(oPC, nToken);
}

// ================================================================
// Feed functions
// ================================================================

void FeedBondingView(object oPC, int nToken)
{
    SetLocalInt(oPC, FAM_LVAR_SEL_TYPE, -1);
    NuiSetBind(oPC, nToken, FAM_BIND_TYPE_DESC,
        JsonString("Wybierz jednego z towarzyszy, aby poznać jego zdolności."));
    NuiSetBind(oPC, nToken, FAM_BIND_BOND_ENA, JsonBool(FALSE));
}

void FeedMainView(object oPC, int nToken, json jFam)
{
    int nNow     = FamNowUnix();
    int nType    = JsonGetInt(JsonObjectGet(jFam, "fam_type"));
    int nBondXp  = JsonGetInt(JsonObjectGet(jFam, "bond_xp"));
    int nHp      = JsonGetInt(JsonObjectGet(jFam, "hp"));
    int nMaxHp   = JsonGetInt(JsonObjectGet(jFam, "max_hp"));
    int nTask    = JsonGetInt(JsonObjectGet(jFam, "task"));
    int nTaskSt  = JsonGetInt(JsonObjectGet(jFam, "task_started"));
    int nVigilUntil = JsonGetInt(JsonObjectGet(jFam, "vigil_until"));
    int nMournUntil = JsonGetInt(JsonObjectGet(jFam, "mourning_until"));
    int bDismissed  = JsonGetInt(JsonObjectGet(jFam, "dismissed"));
    string sCarry   = JsonGetString(JsonObjectGet(jFam, "carry_json"));

    // Regen HP on each UI open (simulates time passing)
    if(nHp < nMaxHp && nMournUntil == 0)
    {
        nHp = nHp + FAM_HP_REGEN_ON_CHECK;
        if(nHp > nMaxHp) nHp = nMaxHp;
        FamSetHp(oPC, nHp);
    }

    // Check mourning expiry
    if(nMournUntil > 0 && nNow >= nMournUntil)
    {
        FamEndMourning(oPC);
        nMournUntil = 0;
        nHp = nMaxHp;
        SendMessageToPC(oPC, "[Znamię] Żałoba minęła. Możesz nawiązać nową więź.");
        FamSwapToBonding(oPC, nToken);
        return;
    }

    // Add bond XP on each view (1 point per open — roughly per session)
    FamAddBondXp(oPC, 1);
    nBondXp++;
    int nBondLvl = FamBondLevel(nBondXp);

    NuiSetBind(oPC, nToken, FAM_BIND_TITLE,
        JsonString(FamTypeName(nType)));
    NuiSetBind(oPC, nToken, FAM_BIND_BOND_LVL,
        JsonString(FamBondStars(nBondLvl) + "  " + FamBondName(nBondLvl)));
    NuiSetBind(oPC, nToken, FAM_BIND_HP_TXT,
        JsonString("Żywotność: " + IntToString(nHp) + "/" + IntToString(nMaxHp)));

    // Status text
    string sStatus = "";
    if(nMournUntil > 0)
    {
        sStatus = "W żałobie — odpoczynek konieczny.";
    }
    else if(bDismissed)
    {
        sStatus = "Odprawiony. Czeka na przywołanie.";
    }
    else if(nTask == FAM_TASK_FORAGE)
    {
        int nElapsed = nNow - nTaskSt;
        int nLeft    = FAM_FORAGE_DURATION - nElapsed;
        if(nLeft > 0)
            sStatus = "Zbiera składniki... (jeszcze " + IntToString(nLeft / 60) + " min)";
        else
            sStatus = "Wrócił! Gotowy do odbioru składników.";
    }
    else if(nVigilUntil > 0 && nNow < nVigilUntil)
    {
        int nLeft = nVigilUntil - nNow;
        sStatus = "Czuwa w pobliżu. (" + IntToString(nLeft / 60) + " min)";
    }
    else
    {
        sStatus = "Bezczynny — czeka na polecenie.";
    }
    NuiSetBind(oPC, nToken, FAM_BIND_STATUS, JsonString(sStatus));

    // Carry — carry_json holds a wrapper: {"name":"...", "item":<serialized>}
    string sCarryDisplay = "Nie niesie niczego.";
    if(sCarry != "")
    {
        json jCarryWrapper = JsonParse(sCarry);
        string sCarryName = JsonGetString(JsonObjectGet(jCarryWrapper, "name"));
        sCarryDisplay = "Niesie: " + sCarryName;
    }
    NuiSetBind(oPC, nToken, FAM_BIND_CARRY_TXT, JsonString(sCarryDisplay));

    // Command availability
    int bExhausted = (nHp <= 0 || nMournUntil > 0);
    int bBusy      = (nTask == FAM_TASK_FORAGE &&
                     (nNow - nTaskSt) < FAM_FORAGE_DURATION);
    int bVigilActive = (nVigilUntil > 0 && nNow < nVigilUntil);

    // Scout: available when not exhausted, not busy foraging, hp >= cost
    int bScoutOk = (!bExhausted && !bDismissed && nHp >= FAM_HP_COST_SCOUT && !bBusy);
    NuiSetBind(oPC, nToken, FAM_BIND_SCOUT_ENA, JsonBool(bScoutOk));
    NuiSetBind(oPC, nToken, FAM_BIND_SCOUT_LBL, JsonString("Zwiad"));

    // Forage
    int bForageOk = (!bExhausted && !bDismissed && nHp >= FAM_HP_COST_FORAGE && !bBusy);
    NuiSetBind(oPC, nToken, FAM_BIND_FORAGE_ENA, JsonBool(bForageOk));
    NuiSetBind(oPC, nToken, FAM_BIND_FORAGE_LBL, JsonString("Zbieranie"));

    // Vigil
    int bVigilOk = (!bExhausted && !bDismissed && nHp >= FAM_HP_COST_VIGIL && !bVigilActive && !bBusy);
    NuiSetBind(oPC, nToken, FAM_BIND_VIGIL_ENA, JsonBool(bVigilOk));
    NuiSetBind(oPC, nToken, FAM_BIND_VIGIL_LBL,
        JsonString(bVigilActive ? "Czuwanie (aktywne)" : "Czuwanie"));

    // Carry button: "Zanieś" when empty, "Odbierz" when holding something
    int bCarryOk = !bExhausted && !bDismissed &&
                   (sCarry == "" ? nHp >= FAM_HP_COST_CARRY : TRUE);
    NuiSetBind(oPC, nToken, FAM_BIND_CARRY_ENA, JsonBool(bCarryOk));
    NuiSetBind(oPC, nToken, FAM_BIND_CARRY_LBL,
        JsonString(sCarry != "" ? "Odbierz przedmiot" : "Zanieś przedmiot"));

    // Dismiss / Recall
    NuiSetBind(oPC, nToken, FAM_BIND_DISMISS_ENA,
        JsonBool(!bExhausted && !bBusy));
    NuiSetBind(oPC, nToken, FAM_BIND_DISMISS_LBL,
        JsonString(bDismissed ? "Przywołaj" : "Odpraw"));

    // Retrieve (collect forage when ready)
    int bForageReady = (nTask == FAM_TASK_FORAGE && (nNow - nTaskSt) >= FAM_FORAGE_DURATION);
    NuiSetBind(oPC, nToken, FAM_BIND_RETRV_ENA, JsonBool(bForageReady));
    NuiSetBind(oPC, nToken, FAM_BIND_RETRV_LBL, JsonString("Odbierz"));
}

// ================================================================
// Command handlers
// ================================================================

void FamExecuteScout(object oPC, int nToken, json jFam)
{
    int nType = JsonGetInt(JsonObjectGet(jFam, "fam_type"));
    int nHp   = JsonGetInt(JsonObjectGet(jFam, "hp"));
    FamSetHp(oPC, nHp - FAM_HP_COST_SCOUT);

    // Scan nearby creatures and report
    int nFound = 0;
    string sReport = "";
    int i;
    for(i = 1; i <= 10; i++)
    {
        object oTarget = GetNearestCreature(CREATURE_TYPE_IS_ALIVE, TRUE,
            oPC, i, CREATURE_TYPE_REPUTATION, REPUTATION_TYPE_ENEMY);
        if(!GetIsObjectValid(oTarget)) break;
        nFound++;
        if(nFound <= 3)
            sReport = sReport + "\n  — " + GetName(oTarget);
    }

    string sMsg = "";
    switch(nType)
    {
        case FAM_TYPE_RAVEN:
            sMsg = "Kruk kracze alarmująco.";
            break;
        case FAM_TYPE_CAT:
            sMsg = "Czarny Kot jeży grzbiet i warczy.";
            break;
        case FAM_TYPE_TOAD:
            sMsg = "Ropucha rechoce ostrzegawczo.";
            break;
        case FAM_TYPE_SPIDER:
            sMsg = "Pająk zatrzęsał siecią.";
            break;
        case FAM_TYPE_OWL:
            sMsg = "Puchacz piszczy niepokojąco.";
            break;
    }

    if(nFound == 0)
        SendMessageToPC(oPC, "[Znamię] " + sMsg + " W pobliżu nie wyczuwa wrogów.");
    else
    {
        SendMessageToPC(oPC, "[Znamię] " + sMsg + " Wykryto " + IntToString(nFound)
            + " wrogów:" + sReport);
    }

    FamLogEvent(oPC, "scout", IntToString(nFound));
    json jUpdated = FamGet(oPC);
    FeedMainView(oPC, nToken, jUpdated);
}

void FamExecuteForage(object oPC, int nToken, json jFam)
{
    int nHp = JsonGetInt(JsonObjectGet(jFam, "hp"));
    FamSetHp(oPC, nHp - FAM_HP_COST_FORAGE);
    FamSetTask(oPC, FAM_TASK_FORAGE);

    int nType = JsonGetInt(JsonObjectGet(jFam, "fam_type"));
    string sMsg = "";
    switch(nType)
    {
        case FAM_TYPE_RAVEN:  sMsg = "Kruk odleciał w poszukiwaniu błyskotek."; break;
        case FAM_TYPE_CAT:    sMsg = "Czarny Kot zniknął w cieniu by zbierać zioła."; break;
        case FAM_TYPE_TOAD:   sMsg = "Ropucha zeskoczyła do bagna na poszukiwania."; break;
        case FAM_TYPE_SPIDER: sMsg = "Pająk pobiegł snuć sieci i zbierać składniki."; break;
        case FAM_TYPE_OWL:    sMsg = "Puchacz wzbił się w noc na poszukiwanie rarytasów."; break;
    }
    SendMessageToPC(oPC, "[Znamię] " + sMsg + " Wróci za kilka minut.");

    json jUpdated = FamGet(oPC);
    FeedMainView(oPC, nToken, jUpdated);
}

void FamProcessForageReturn(object oPC, int nToken, json jFam)
{
    FamFinishTask(oPC);

    int nType     = JsonGetInt(JsonObjectGet(jFam, "fam_type"));
    int nBondLvl  = FamBondLevel(JsonGetInt(JsonObjectGet(jFam, "bond_xp")));
    int nGold     = 5 + Random(16) + nBondLvl * 2;
    GiveGoldToCreature(oPC, nGold);

    string sResRef = "";
    string sMsg = "";
    switch(nType)
    {
        case FAM_TYPE_RAVEN:
            sResRef = FAM_ITEM_RAVEN;
            sMsg = "Kruk przyniósł kilka błyskotek."; break;
        case FAM_TYPE_CAT:
            sResRef = FAM_ITEM_CAT;
            sMsg = "Czarny Kot złożył wiązankę ziół."; break;
        case FAM_TYPE_TOAD:
            sResRef = FAM_ITEM_TOAD;
            sMsg = "Ropucha powróciła z jadowitymi jagodami."; break;
        case FAM_TYPE_SPIDER:
            sResRef = FAM_ITEM_SPIDER;
            sMsg = "Pająk przyniósł kokon i odrobinę jadowitej żywicy."; break;
        case FAM_TYPE_OWL:
            sResRef = FAM_ITEM_OWL;
            sMsg = "Puchacz powrócił z magicznym piórem."; break;
    }

    SendMessageToPC(oPC, "[Znamię] " + sMsg
        + " Znalazł też " + IntToString(nGold) + " sztuk złota.");

    // Attempt custom item (see INTEGRATION.md for HAK resrefs)
    CreateItemOnObject(sResRef, oPC, 1);

    FamLogEvent(oPC, "forage_return", IntToString(nGold) + "g");
    json jUpdated = FamGet(oPC);
    FeedMainView(oPC, nToken, jUpdated);
}

void FamExecuteVigil(object oPC, int nToken, json jFam)
{
    int nHp  = JsonGetInt(JsonObjectGet(jFam, "hp"));
    FamSetHp(oPC, nHp - FAM_HP_COST_VIGIL);

    int nUntil = FamNowUnix() + FAM_VIGIL_DURATION;
    FamSetVigil(oPC, nUntil);

    // Apply a minor Alertness effect for the duration
    effect eAlert = ExtraordinaryEffect(EffectSkillIncrease(SKILL_LISTEN, 4));
    eAlert = EffectLinkEffects(eAlert, ExtraordinaryEffect(EffectSkillIncrease(SKILL_SPOT, 4)));
    ApplyEffectToObject(DURATION_TYPE_TEMPORARY, eAlert, oPC,
        IntToFloat(FAM_VIGIL_DURATION));

    int nType = JsonGetInt(JsonObjectGet(jFam, "fam_type"));
    string sMsg = "";
    switch(nType)
    {
        case FAM_TYPE_RAVEN:  sMsg = "Kruk siada na ramieniu i patrzy w dal."; break;
        case FAM_TYPE_CAT:    sMsg = "Czarny Kot siada przy stopach i mruży oczy."; break;
        case FAM_TYPE_TOAD:   sMsg = "Ropucha rechoce subtelnie, ostrzegając cię o ruchach."; break;
        case FAM_TYPE_SPIDER: sMsg = "Pająk rozciąga niewidzialną sieć wokół ciebie."; break;
        case FAM_TYPE_OWL:    sMsg = "Puchacz krąży nad tobą w milczeniu."; break;
    }
    SendMessageToPC(oPC, "[Znamię] " + sMsg
        + " Czujesz wyostrzone zmysły. (+4 Słuch, +4 Spostrzegawczość)");

    FamLogEvent(oPC, "vigil", IntToString(nUntil));
    json jUpdated = FamGet(oPC);
    FeedMainView(oPC, nToken, jUpdated);
}

void FamExecuteCarry(object oPC, int nToken)
{
    SetLocalInt(oPC, FAM_LVAR_TARGETING, 1);
    NuiDestroy(oPC, nToken);
    EnterTargetingMode(oPC, OBJECT_TYPE_ITEM);
    SendMessageToPC(oPC, "[Znamię] Kliknij przedmiot w ekwipunku, który chcesz powierzyć towarzyszowi.");
}

void FamOnCarryTarget(object oPC)
{
    DeleteLocalInt(oPC, FAM_LVAR_TARGETING);

    object oItem = GetTargetingModeSelectedObject();
    if(!GetIsObjectValid(oItem) || GetItemPossessor(oItem) != oPC)
    {
        SendMessageToPC(oPC, "[Znamię] Możesz powierzyć tylko przedmiot ze swojego ekwipunku.");
        return;
    }

    json jFam = FamGet(oPC);
    if(JsonGetType(jFam) == JSON_TYPE_NULL) return;

    string sCarry = JsonGetString(JsonObjectGet(jFam, "carry_json"));
    if(sCarry != "")
    {
        SendMessageToPC(oPC, "[Znamię] Twój towarzysz już coś niesie. Najpierw odbierz przedmiot.");
        return;
    }

    int nHp = JsonGetInt(JsonObjectGet(jFam, "hp"));
    FamSetHp(oPC, nHp - FAM_HP_COST_CARRY);

    string sName = GetName(oItem);
    // Wrap item serialization + display name together for SQL persistence
    json jWrapper = JsonObject();
    jWrapper = JsonObjectSet(jWrapper, "name", JsonString(sName));
    jWrapper = JsonObjectSet(jWrapper, "item", ObjectToJson(oItem, TRUE));
    FamSetCarry(oPC, JsonDump(jWrapper));
    DestroyObject(oItem);

    SendMessageToPC(oPC, "[Znamię] Twój towarzysz wziął: " + sName + ".");
    FamLogEvent(oPC, "carry", sName);
}

void FamRetrieveCarry(object oPC, int nToken, json jFam)
{
    string sCarryRaw = JsonGetString(JsonObjectGet(jFam, "carry_json"));
    if(sCarryRaw == "") return;

    json jWrapper = JsonParse(sCarryRaw);
    string sCarryName = JsonGetString(JsonObjectGet(jWrapper, "name"));
    json jItemSerial  = JsonObjectGet(jWrapper, "item");

    if(JsonGetType(jItemSerial) != JSON_TYPE_NULL)
        JsonToObject(jItemSerial, GetLocation(oPC), oPC, TRUE);

    FamSetCarry(oPC, "");
    SendMessageToPC(oPC, "[Znamię] Odebrałeś od towarzysza: " + sCarryName + ".");
    FamLogEvent(oPC, "retrieve_carry", sCarryName);

    json jUpdated = FamGet(oPC);
    FeedMainView(oPC, nToken, jUpdated);
}

void FamExecuteDismiss(object oPC, int nToken, json jFam)
{
    int bDismissed = JsonGetInt(JsonObjectGet(jFam, "dismissed"));

    if(bDismissed)
    {
        FamSetDismissed(oPC, FALSE);
        int nType = JsonGetInt(JsonObjectGet(jFam, "fam_type"));
        SendMessageToPC(oPC, "[Znamię] " + FamTypeName(nType) + " powrócił na twoje wezwanie.");
        FamLogEvent(oPC, "recall", "");
    }
    else
    {
        FamSetDismissed(oPC, TRUE);
        int nType = JsonGetInt(JsonObjectGet(jFam, "fam_type"));
        SendMessageToPC(oPC, "[Znamię] " + FamTypeName(nType) + " oddala się, lecz poczujesz go gdy zawołasz.");
        FamLogEvent(oPC, "dismiss", "");
    }

    json jUpdated = FamGet(oPC);
    FeedMainView(oPC, nToken, jUpdated);
}

void FamExecuteRelease(object oPC, int nToken, json jFam)
{
    int nType = JsonGetInt(JsonObjectGet(jFam, "fam_type"));
    string sName = FamTypeName(nType);

    FamStartMourning(oPC);

    // Apply a mourning debuff: -2 Wisdom for the duration
    effect eMourn = ExtraordinaryEffect(EffectAbilityDecrease(ABILITY_WISDOM, 2));
    eMourn = EffectLinkEffects(eMourn,
        ExtraordinaryEffect(EffectAbilityDecrease(ABILITY_CHARISMA, 1)));
    ApplyEffectToObject(DURATION_TYPE_TEMPORARY, eMourn, oPC,
        IntToFloat(FAM_MOURN_DURATION));

    FloatingTextStringOnCreature(
        "Więź z " + sName + " pęka. Żałoba trwa...", oPC, FALSE);
    SendMessageToPC(oPC, "[Znamię] Zerwałeś więź z " + sName
        + ". Duch towarzysza odchodzi. Żałoba potrwa 24 godziny."
        + " (-2 Mądrość, -1 Charyzma)");
    FamLogEvent(oPC, "release", sName);

    FamSwapToBonding(oPC, nToken);
}

// ================================================================
// Bond — called from bonding view on confirm
// ================================================================

void FamBond(object oPC, int nToken)
{
    int nType = GetLocalInt(oPC, FAM_LVAR_SEL_TYPE);
    if(nType < 0 || nType >= FAM_TYPE_COUNT)
    {
        SendMessageToPC(oPC, "[Znamię] Wybierz najpierw towarzysza.");
        return;
    }

    FamCreate(oPC, nType);
    FamLogEvent(oPC, "bond", IntToString(nType));

    FloatingTextStringOnCreature(
        "Więź nawiązana — " + FamTypeName(nType) + " jest teraz twoim towarzyszem.",
        oPC, FALSE);
    SendMessageToPC(oPC, "[Znamię] Pieczęć krwi pulsuje słabo…"
        + " Poczułeś obecność " + FamTypeName(nType) + " w swoim cieniu.");

    json jFam = FamGet(oPC);
    FamSwapToMain(oPC, nToken, jFam);
}

// ================================================================
// Mourning debuff restore on login
// ================================================================

void FamRestoreEffects(object oPC)
{
    if(!FamExists(oPC)) return;
    json jFam = FamGet(oPC);

    int nMournUntil = JsonGetInt(JsonObjectGet(jFam, "mourning_until"));
    if(nMournUntil == 0) return;

    int nNow = FamNowUnix();
    if(nNow >= nMournUntil)
    {
        FamEndMourning(oPC);
        return;
    }

    int nLeft = nMournUntil - nNow;
    effect eMourn = ExtraordinaryEffect(EffectAbilityDecrease(ABILITY_WISDOM, 2));
    eMourn = EffectLinkEffects(eMourn,
        ExtraordinaryEffect(EffectAbilityDecrease(ABILITY_CHARISMA, 1)));
    ApplyEffectToObject(DURATION_TYPE_TEMPORARY, eMourn, oPC, IntToFloat(nLeft));
}

// ================================================================
// Vigil check — called from heartbeat or periodic check
// ================================================================

void FamCheckVigil(object oPC)
{
    if(!FamExists(oPC)) return;
    json jFam = FamGet(oPC);

    int nMournUntil = JsonGetInt(JsonObjectGet(jFam, "mourning_until"));
    if(nMournUntil > 0) return;

    int bDismissed = JsonGetInt(JsonObjectGet(jFam, "dismissed"));
    if(bDismissed) return;

    int nVigilUntil = JsonGetInt(JsonObjectGet(jFam, "vigil_until"));
    if(nVigilUntil == 0) return;
    if(FamNowUnix() >= nVigilUntil) return;

    // Check for nearby enemies and warn
    object oEnemy = GetNearestCreature(CREATURE_TYPE_IS_ALIVE, TRUE,
        oPC, 1, CREATURE_TYPE_REPUTATION, REPUTATION_TYPE_ENEMY);
    if(!GetIsObjectValid(oEnemy)) return;

    int nType = JsonGetInt(JsonObjectGet(jFam, "fam_type"));
    string sWarn = "";
    switch(nType)
    {
        case FAM_TYPE_RAVEN:  sWarn = "Kruk krzyczy alarmująco!"; break;
        case FAM_TYPE_CAT:    sWarn = "Czarny Kot syczy ostrzegawczo!"; break;
        case FAM_TYPE_TOAD:   sWarn = "Ropucha rechoce gwałtownie!"; break;
        case FAM_TYPE_SPIDER: sWarn = "Pająk zaciska wszystkie nogi!"; break;
        case FAM_TYPE_OWL:    sWarn = "Puchacz wrzeszczy z góry!"; break;
    }
    FloatingTextStringOnCreature("[Znamię] " + sWarn + " "
        + GetName(oEnemy) + " jest w pobliżu!", oPC, FALSE);
}
