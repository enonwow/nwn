// lib_bur.nss — core logic, NUI layout, and buff management for Burial Rites

#include "lib_bur_def"

// ----------------------------------------------------------------
// Effect helpers
// ----------------------------------------------------------------

// Returns TRUE if oPC has any effect bearing sTag.
int BurHasTaggedEffect(object oPC, string sTag)
{
    effect e = GetFirstEffect(oPC);
    while(GetIsEffectValid(e))
    {
        if(GetEffectTag(e) == sTag) return TRUE;
        e = GetNextEffect(oPC);
    }
    return FALSE;
}

// Returns 1/2/3 for active pauper/proper/sacred buff, 0 if none.
int BurGetActiveBuff(object oPC)
{
    effect e = GetFirstEffect(oPC);
    while(GetIsEffectValid(e))
    {
        string sTag = GetEffectTag(e);
        if(sTag == BUR_BUFF_TAG_1) return 1;
        if(sTag == BUR_BUFF_TAG_2) return 2;
        if(sTag == BUR_BUFF_TAG_3) return 3;
        e = GetNextEffect(oPC);
    }
    return 0;
}

// Removes all temporary burial buffs from oPC.
void BurRemoveBuff(object oPC)
{
    effect e = GetFirstEffect(oPC);
    while(GetIsEffectValid(e))
    {
        string sTag = GetEffectTag(e);
        if(sTag == BUR_BUFF_TAG_1 || sTag == BUR_BUFF_TAG_2 || sTag == BUR_BUFF_TAG_3)
            RemoveEffect(oPC, e);
        e = GetNextEffect(oPC);
    }
}

// ----------------------------------------------------------------
// Buff application
// ----------------------------------------------------------------

void BurApplyBuff(object oPC, int nRiteType)
{
    BurRemoveBuff(oPC);

    string sTag;
    float  fDur;
    string sMsg;

    if(nRiteType == BUR_RITE_PAUPER)
    {
        sTag = BUR_BUFF_TAG_1;
        fDur = BUR_DUR_PAUPER;
        sMsg = "Sk\305\202adasz proste modlitwy za poleg\305\202ych. Spok\303\263j n\304\231dzarzy niech ci\304\231 os\305\202ania.";

        effect eSave = TagEffect(EffectSavingThrowIncrease(SAVING_THROW_ALL, 1, SAVING_THROW_TYPE_DEATH), sTag);
        ApplyEffectToObject(DURATION_TYPE_TEMPORARY, eSave, oPC, fDur);
    }
    else if(nRiteType == BUR_RITE_PROPER)
    {
        sTag = BUR_BUFF_TAG_2;
        fDur = BUR_DUR_PROPER;
        sMsg = "Zapalone \305\233wiece o\305\233wietlaj\304\205 drog\304\231 umar\305\202ym. Pok\303\263j Zmar\305\202ych ogania ci\304\231 niczym p\305\202aszcz.";

        effect eAC    = TagEffect(EffectACIncrease(1, AC_DODGE_BONUS), sTag);
        effect eSave  = TagEffect(EffectSavingThrowIncrease(SAVING_THROW_ALL, 1), sTag);
        effect eRegen = TagEffect(EffectRegenerate(1, 6.0), sTag);
        effect eVFX   = TagEffect(EffectVisualEffect(VFX_DUR_CESSATE_POSITIVE), sTag);
        ApplyEffectToObject(DURATION_TYPE_TEMPORARY, eAC,    oPC, fDur);
        ApplyEffectToObject(DURATION_TYPE_TEMPORARY, eSave,  oPC, fDur);
        ApplyEffectToObject(DURATION_TYPE_TEMPORARY, eRegen, oPC, fDur);
        ApplyEffectToObject(DURATION_TYPE_TEMPORARY, eVFX,   oPC, fDur);
    }
    else // SACRED
    {
        sTag = BUR_BUFF_TAG_3;
        fDur = BUR_DUR_SACRED;
        sMsg = "Wypowiadasz staro\305\274ytne s\305\202owa przej\305\233cia. B\305\202ogos\305\202awie\305\204stwo Zawi\305\233cia sp\305\202ywa na ciebie.";

        effect eAC    = TagEffect(EffectACIncrease(2, AC_DODGE_BONUS), sTag);
        effect eSave  = TagEffect(EffectSavingThrowIncrease(SAVING_THROW_ALL, 2), sTag);
        effect eRegen = TagEffect(EffectRegenerate(2, 6.0), sTag);
        effect eMove  = TagEffect(EffectMovementSpeedIncrease(10), sTag);
        effect eVFX   = TagEffect(EffectVisualEffect(VFX_DUR_AURA_PULSE_YELLOW_WHITE), sTag);
        ApplyEffectToObject(DURATION_TYPE_TEMPORARY, eAC,    oPC, fDur);
        ApplyEffectToObject(DURATION_TYPE_TEMPORARY, eSave,  oPC, fDur);
        ApplyEffectToObject(DURATION_TYPE_TEMPORARY, eRegen, oPC, fDur);
        ApplyEffectToObject(DURATION_TYPE_TEMPORARY, eMove,  oPC, fDur);
        ApplyEffectToObject(DURATION_TYPE_TEMPORARY, eVFX,   oPC, fDur);
    }

    // Impact VFX on rite completion
    ApplyEffectToObject(DURATION_TYPE_INSTANT, EffectVisualEffect(VFX_IMP_HOLY_AID), oPC);
    SendMessageToPC(oPC, "[Pogrzebnik] " + sMsg);
}

// ----------------------------------------------------------------
// Milestone effects (re-applied on login)
// ----------------------------------------------------------------

void BurRestorePermanentEffects(object oPC)
{
    json jRecord = BurGetRecord(oPC);
    if(JsonGetType(jRecord) == JSON_TYPE_NULL) return;

    int nSacred = JsonGetInt(JsonObjectGet(jRecord, "total_sacred"));
    int nTotal  = JsonGetInt(JsonObjectGet(jRecord, "total_pauper"))
                + JsonGetInt(JsonObjectGet(jRecord, "total_proper"))
                + nSacred;

    if(nSacred >= BUR_MILESTONE_MARKED && !BurHasTaggedEffect(oPC, BUR_PERM_TAG_MARKED))
    {
        effect eGlow = TagEffect(EffectVisualEffect(VFX_DUR_GLOW_WHITE), BUR_PERM_TAG_MARKED);
        ApplyEffectToObject(DURATION_TYPE_PERMANENT, eGlow, oPC);
        SetLocalInt(oPC, BUR_LVAR_MARKED, 1);
    }

    if(nTotal >= BUR_MILESTONE_BLESSED && !BurHasTaggedEffect(oPC, BUR_PERM_TAG_BLESSED))
    {
        effect eSave = TagEffect(
            EffectSavingThrowIncrease(SAVING_THROW_ALL, 1, SAVING_THROW_TYPE_DEATH),
            BUR_PERM_TAG_BLESSED);
        ApplyEffectToObject(DURATION_TYPE_PERMANENT, eSave, oPC);
        SetLocalInt(oPC, BUR_LVAR_BLESSED, 1);
    }
}

// ----------------------------------------------------------------
// Milestone check and notification (called after each rite)
// ----------------------------------------------------------------

void BurCheckMilestones(object oPC)
{
    json jRecord = BurGetRecord(oPC);
    if(JsonGetType(jRecord) == JSON_TYPE_NULL) return;

    int nSacred = JsonGetInt(JsonObjectGet(jRecord, "total_sacred"));
    int nTotal  = JsonGetInt(JsonObjectGet(jRecord, "total_pauper"))
                + JsonGetInt(JsonObjectGet(jRecord, "total_proper"))
                + nSacred;

    if(nSacred == BUR_MILESTONE_MARKED && !GetLocalInt(oPC, BUR_LVAR_MARKED))
    {
        SetLocalInt(oPC, BUR_LVAR_MARKED, 1);
        effect eGlow = TagEffect(EffectVisualEffect(VFX_DUR_GLOW_WHITE), BUR_PERM_TAG_MARKED);
        ApplyEffectToObject(DURATION_TYPE_PERMANENT, eGlow, oPC);
        SendMessageToPC(oPC,
            "[Pogrzebnik] Pi\304\231tno Grabarza sp\305\202yn\304\231\305\202o na ciebie. Duch twego po\305\233wi\304\231cenia trwa wiecznie.");
        FloatingTextStringOnCreature(
            "Pi\304\231tno Grabarza — trwa\305\202e pi\304\231tno!",
            oPC, FALSE);
    }

    if(nTotal == BUR_MILESTONE_BLESSED && !GetLocalInt(oPC, BUR_LVAR_BLESSED))
    {
        SetLocalInt(oPC, BUR_LVAR_BLESSED, 1);
        effect eSave = TagEffect(
            EffectSavingThrowIncrease(SAVING_THROW_ALL, 1, SAVING_THROW_TYPE_DEATH),
            BUR_PERM_TAG_BLESSED);
        ApplyEffectToObject(DURATION_TYPE_PERMANENT, eSave, oPC);
        SendMessageToPC(oPC,
            "[Pogrzebnik] B\305\202ogos\305\202awie\305\204stwo Spokoju — wieczny spok\303\263j pochowanych chroni twoj\304\205 dusz\304\231. (+1 obrony vs. \305\233mier\304\207, trwa\305\202e)");
        FloatingTextStringOnCreature(
            "B\305\202ogos\305\202awie\305\224stwo Spokoju — trwa\305\202e!",
            oPC, FALSE);
    }
}

// ----------------------------------------------------------------
// Rite execution
// ----------------------------------------------------------------

void BurApplyRite(object oPC, int nRiteType)
{
    BurEnsureRecord(oPC);

    if(nRiteType == BUR_RITE_PAUPER)
    {
        int nLeft = BurPauperCooldownLeft(oPC);
        if(nLeft > 0)
        {
            int nMin = (nLeft + 59) / 60;
            SendMessageToPC(oPC,
                "[Pogrzebnik] Ubogi Poch\303\263wek jest jeszcze na odnowieniu ("
                + IntToString(nMin) + " min).");
            return;
        }
        BurApplyBuff(oPC, BUR_RITE_PAUPER);
        BurRecordPauper(oPC);
    }
    else if(nRiteType == BUR_RITE_PROPER)
    {
        if(GetGold(oPC) < BUR_COST_PROPER_GOLD)
        {
            SendMessageToPC(oPC, "[Pogrzebnik] Potrzebujesz co najmniej "
                + IntToString(BUR_COST_PROPER_GOLD) + " sztuk z\305\202ota.");
            return;
        }
        object oCandle = GetItemPossessedBy(oPC, BUR_TAG_CANDLE);
        if(!GetIsObjectValid(oCandle))
        {
            SendMessageToPC(oPC, "[Pogrzebnik] Potrzebujesz \305\232wiecy Pogrzebowej (tag: "
                + BUR_TAG_CANDLE + ").");
            return;
        }
        AssignCommand(oPC, TakeGoldFromCreature(BUR_COST_PROPER_GOLD, oPC, TRUE));
        DestroyObject(oCandle);
        BurApplyBuff(oPC, BUR_RITE_PROPER);
        BurRecordProper(oPC);
    }
    else // SACRED
    {
        if(GetGold(oPC) < BUR_COST_SACRED_GOLD)
        {
            SendMessageToPC(oPC, "[Pogrzebnik] Potrzebujesz co najmniej "
                + IntToString(BUR_COST_SACRED_GOLD) + " sztuk z\305\202ota.");
            return;
        }
        object oOil    = GetItemPossessedBy(oPC, BUR_TAG_OIL);
        object oScroll = GetItemPossessedBy(oPC, BUR_TAG_SCROLL);
        if(!GetIsObjectValid(oOil))
        {
            SendMessageToPC(oPC, "[Pogrzebnik] Potrzebujesz Olejku Ostatniego (tag: "
                + BUR_TAG_OIL + ").");
            return;
        }
        if(!GetIsObjectValid(oScroll))
        {
            SendMessageToPC(oPC, "[Pogrzebnik] Potrzebujesz Pergaminu Imion (tag: "
                + BUR_TAG_SCROLL + ").");
            return;
        }
        AssignCommand(oPC, TakeGoldFromCreature(BUR_COST_SACRED_GOLD, oPC, TRUE));
        DestroyObject(oOil);
        DestroyObject(oScroll);
        BurApplyBuff(oPC, BUR_RITE_SACRED);
        BurRecordSacred(oPC);
    }

    BurCheckMilestones(oPC);

    int nToken = NuiFindWindow(oPC, BUR_WINDOW);
    if(nToken != 0)
        BurFeedWindow(oPC, nToken);
}

// ----------------------------------------------------------------
// NUI — layout
// ----------------------------------------------------------------

json BurBuildRiteBlock(object oPC,
                       string sBtnId,
                       string sBtnLabel,
                       string sBindEna,
                       string sBindReqLbl,
                       string sBindReqCol,
                       string sEffectText)
{
    float fBtnH = GetNuiScaleDimension(oPC, 30.0);
    float fSmH  = GetNuiScaleDimension(oPC, 22.0);

    json jBtn = NuiButton(JsonString(sBtnLabel));
    jBtn = NuiId(jBtn, sBtnId);
    jBtn = NuiEnabled(jBtn, NuiBind(sBindEna));
    jBtn = NuiHeight(jBtn, fBtnH);

    json jReqLbl = NuiLabel(NuiBind(sBindReqLbl),
        JsonInt(NUI_HALIGN_LEFT), JsonInt(NUI_VALIGN_MIDDLE));
    jReqLbl = NuiStyleForegroundColor(jReqLbl, NuiBind(sBindReqCol));
    jReqLbl = NuiHeight(jReqLbl, fSmH);

    json jEffLbl = NuiLabel(JsonString(sEffectText),
        JsonInt(NUI_HALIGN_LEFT), JsonInt(NUI_VALIGN_MIDDLE));
    jEffLbl = NuiStyleForegroundColor(jEffLbl, NuiColor(180, 180, 180));
    jEffLbl = NuiHeight(jEffLbl, fSmH);

    json jCol = JsonArray();
    jCol = JsonArrayInsert(jCol, NuiRow(JsonArrayInsert(JsonArray(), jBtn)));
    jCol = JsonArrayInsert(jCol, NuiRow(JsonArrayInsert(JsonArray(), jReqLbl)));
    jCol = JsonArrayInsert(jCol, NuiRow(JsonArrayInsert(JsonArray(), jEffLbl)));

    json jGrp = NuiGroup(NuiCol(jCol), TRUE, NUI_SCROLLBARS_NONE);
    jGrp = NuiHeight(jGrp, GetNuiScaleDimension(oPC, 92.0));
    return jGrp;
}

json BurBuildLayout(object oPC)
{
    float fBtnH = GetNuiScaleDimension(oPC, 30.0);
    float fSmH  = GetNuiScaleDimension(oPC, 22.0);

    // Top bar: title + close button
    json jTitle = NuiLabel(JsonString("Obrz\304\231dy Pogrzebowe"),
        JsonInt(NUI_HALIGN_LEFT), JsonInt(NUI_VALIGN_MIDDLE));
    json jClose = NuiButton(JsonString("X"));
    jClose = NuiId(jClose, BUR_BTN_CLOSE);
    jClose = NuiWidth(jClose, GetNuiScaleDimension(oPC, 30.0));
    jClose = NuiHeight(jClose, fBtnH);
    json jTopRow = JsonArray();
    jTopRow = JsonArrayInsert(jTopRow, jTitle);
    jTopRow = JsonArrayInsert(jTopRow, NuiSpacer());
    jTopRow = JsonArrayInsert(jTopRow, jClose);

    // Three rite blocks
    json jP0 = BurBuildRiteBlock(oPC,
        BUR_BTN_PAUPER, "Ubogi Poch\303\263wek",
        BUR_BIND_P0_ENA, BUR_BIND_P0_REQ_LBL, BUR_BIND_P0_REQ_COL,
        "Efekt: Odpocznienie N\304\231dzarzy (+1 obrona vs. \305\233mier\304\207, 1h)");

    json jP1 = BurBuildRiteBlock(oPC,
        BUR_BTN_PROPER, "Przyzwoity Poch\303\263wek",
        BUR_BIND_P1_ENA, BUR_BIND_P1_REQ_LBL, BUR_BIND_P1_REQ_COL,
        "Efekt: Pok\303\263j Zmar\305\202ych (AC+1, obrony+1, regen HP, 4h)");

    json jP2 = BurBuildRiteBlock(oPC,
        BUR_BTN_SACRED, "\305\232wi\304\231ty Ryt Przej\305\233cia",
        BUR_BIND_P2_ENA, BUR_BIND_P2_REQ_LBL, BUR_BIND_P2_REQ_COL,
        "Efekt: B\305\202ogos\305\202awie\305\204stwo Zawi\305\233cia (AC+2, obrony+2, regen, +ruch, 8h)");

    // Progress + status rows
    json jProgressLbl = NuiLabel(NuiBind(BUR_BIND_PROGRESS_LBL),
        JsonInt(NUI_HALIGN_LEFT), JsonInt(NUI_VALIGN_MIDDLE));
    jProgressLbl = NuiHeight(jProgressLbl, fSmH);

    json jMilestoneLbl = NuiLabel(NuiBind(BUR_BIND_MILESTONE_LBL),
        JsonInt(NUI_HALIGN_LEFT), JsonInt(NUI_VALIGN_MIDDLE));
    jMilestoneLbl = NuiStyleForegroundColor(jMilestoneLbl, GetNuiColorNwnGold());
    jMilestoneLbl = NuiHeight(jMilestoneLbl, fSmH);

    json jStatusLbl = NuiLabel(NuiBind(BUR_BIND_STATUS_LBL),
        JsonInt(NUI_HALIGN_LEFT), JsonInt(NUI_VALIGN_MIDDLE));
    jStatusLbl = NuiStyleForegroundColor(jStatusLbl, NuiColor(160, 200, 255));
    jStatusLbl = NuiHeight(jStatusLbl, fSmH);

    // Main column
    json jCol = JsonArray();
    jCol = JsonArrayInsert(jCol, NuiRow(jTopRow));
    jCol = JsonArrayInsert(jCol, CreateEmptyRow(oPC, 6.0));
    jCol = JsonArrayInsert(jCol, jP0);
    jCol = JsonArrayInsert(jCol, CreateEmptyRow(oPC, 4.0));
    jCol = JsonArrayInsert(jCol, jP1);
    jCol = JsonArrayInsert(jCol, CreateEmptyRow(oPC, 4.0));
    jCol = JsonArrayInsert(jCol, jP2);
    jCol = JsonArrayInsert(jCol, CreateEmptyRow(oPC, 8.0));
    jCol = JsonArrayInsert(jCol, NuiRow(JsonArrayInsert(JsonArray(), jProgressLbl)));
    jCol = JsonArrayInsert(jCol, NuiRow(JsonArrayInsert(JsonArray(), jMilestoneLbl)));
    jCol = JsonArrayInsert(jCol, NuiRow(JsonArrayInsert(JsonArray(), jStatusLbl)));

    // Centred with side spacers (Mailbox pattern)
    json jSide = NuiCol(JsonArrayInsert(JsonArray(), NuiSpacer()));
    float fContentW = GetNuiScaleDimension(oPC, 460.0);
    json jMainRow = JsonArray();
    jMainRow = JsonArrayInsert(jMainRow, jSide);
    jMainRow = JsonArrayInsert(jMainRow, NuiWidth(NuiCol(jCol), fContentW));
    jMainRow = JsonArrayInsert(jMainRow, jSide);
    return NuiRow(jMainRow);
}

// ----------------------------------------------------------------
// NUI — feed (populate binds with live data)
// ----------------------------------------------------------------

void BurFeedWindow(object oPC, int nToken)
{
    json jRecord = BurGetRecord(oPC);
    if(JsonGetType(jRecord) == JSON_TYPE_NULL)
        jRecord = JsonObject(); // fallback with zeros

    int nTotalPauper = JsonGetInt(JsonObjectGet(jRecord, "total_pauper"));
    int nTotalProper = JsonGetInt(JsonObjectGet(jRecord, "total_proper"));
    int nTotalSacred = JsonGetInt(JsonObjectGet(jRecord, "total_sacred"));
    int nTotal       = nTotalPauper + nTotalProper + nTotalSacred;

    int nGold      = GetGold(oPC);
    int bHasCandle = GetIsObjectValid(GetItemPossessedBy(oPC, BUR_TAG_CANDLE));
    int bHasOil    = GetIsObjectValid(GetItemPossessedBy(oPC, BUR_TAG_OIL));
    int bHasScroll = GetIsObjectValid(GetItemPossessedBy(oPC, BUR_TAG_SCROLL));

    json jGreen = NuiColor(100, 220, 100);
    json jRed   = NuiColor(220, 80,  80);

    // Rite 0 — Pauper
    int nCooldown  = BurPauperCooldownLeft(oPC);
    int bP0Enabled = (nCooldown == 0);
    string sP0Req;
    if(bP0Enabled)
        sP0Req = "Gotowe — bez koszt\303\263w";
    else
        sP0Req = "Odnowienie: " + IntToString((nCooldown + 59) / 60) + " min";

    // Rite 1 — Proper
    int bP1Enabled = (nGold >= BUR_COST_PROPER_GOLD && bHasCandle);
    string sP1Req;
    if(bP1Enabled)
        sP1Req = IntToString(BUR_COST_PROPER_GOLD) + "gp + \305\232wieca \342\234\223";
    else if(nGold < BUR_COST_PROPER_GOLD)
        sP1Req = "Brakuje z\305\202ota (" + IntToString(BUR_COST_PROPER_GOLD) + "gp)";
    else
        sP1Req = "Brak \305\232wiecy Pogrzebowej";

    // Rite 2 — Sacred
    int bP2Enabled = (nGold >= BUR_COST_SACRED_GOLD && bHasOil && bHasScroll);
    string sP2Req;
    if(bP2Enabled)
        sP2Req = IntToString(BUR_COST_SACRED_GOLD) + "gp + Olejek + Pergamin \342\234\223";
    else if(nGold < BUR_COST_SACRED_GOLD)
        sP2Req = "Brakuje z\305\202ota (" + IntToString(BUR_COST_SACRED_GOLD) + "gp)";
    else if(!bHasOil)
        sP2Req = "Brak Olejku Ostatniego";
    else
        sP2Req = "Brak Pergaminu Imion";

    // Progress line
    string sProgress = "Poch\303\263wki: " + IntToString(nTotal)
        + " \342\200\224 proste: " + IntToString(nTotalPauper)
        + ", przyzwoite: " + IntToString(nTotalProper)
        + ", \305\233wi\304\231te: " + IntToString(nTotalSacred);

    // Milestone line
    string sMile1, sMile2;
    if(nTotalSacred < BUR_MILESTONE_MARKED)
        sMile1 = "Pi\304\231tno Grabarza: " + IntToString(nTotalSacred)
                 + "/" + IntToString(BUR_MILESTONE_MARKED);
    else
        sMile1 = "Pi\304\231tno Grabarza: ZDOBYTE";

    if(nTotal < BUR_MILESTONE_BLESSED)
        sMile2 = "  |  B\305\202ogos\305\202.: " + IntToString(nTotal)
                 + "/" + IntToString(BUR_MILESTONE_BLESSED);
    else
        sMile2 = "  |  B\305\202ogos\305\202.: ZDOBYTE";

    // Active buff line
    int nActiveBuff = BurGetActiveBuff(oPC);
    string sStatus;
    if(nActiveBuff == 1)      sStatus = "Aktywny buff: Odpocznienie N\304\231dzarzy (1h)";
    else if(nActiveBuff == 2) sStatus = "Aktywny buff: Pok\303\263j Zmar\305\202ych (4h)";
    else if(nActiveBuff == 3) sStatus = "Aktywny buff: B\305\202ogos\305\202awie\305\204stwo Zawi\305\233cia (8h)";
    else                      sStatus = "Brak aktywnego b\305\202ogos\305\202awie\305\204stwa";

    NuiSetBind(oPC, nToken, BUR_BIND_P0_ENA,       JsonBool(bP0Enabled));
    NuiSetBind(oPC, nToken, BUR_BIND_P0_REQ_LBL,   JsonString(sP0Req));
    NuiSetBind(oPC, nToken, BUR_BIND_P0_REQ_COL,   bP0Enabled ? jGreen : jRed);
    NuiSetBind(oPC, nToken, BUR_BIND_P1_ENA,       JsonBool(bP1Enabled));
    NuiSetBind(oPC, nToken, BUR_BIND_P1_REQ_LBL,   JsonString(sP1Req));
    NuiSetBind(oPC, nToken, BUR_BIND_P1_REQ_COL,   bP1Enabled ? jGreen : jRed);
    NuiSetBind(oPC, nToken, BUR_BIND_P2_ENA,       JsonBool(bP2Enabled));
    NuiSetBind(oPC, nToken, BUR_BIND_P2_REQ_LBL,   JsonString(sP2Req));
    NuiSetBind(oPC, nToken, BUR_BIND_P2_REQ_COL,   bP2Enabled ? jGreen : jRed);
    NuiSetBind(oPC, nToken, BUR_BIND_PROGRESS_LBL,  JsonString(sProgress));
    NuiSetBind(oPC, nToken, BUR_BIND_MILESTONE_LBL, JsonString(sMile1 + sMile2));
    NuiSetBind(oPC, nToken, BUR_BIND_STATUS_LBL,    JsonString(sStatus));
}

// ----------------------------------------------------------------
// NUI — window create / refresh
// ----------------------------------------------------------------

void BurShowWindow(object oPC)
{
    BurEnsureRecord(oPC);

    int nToken = NuiFindWindow(oPC, BUR_WINDOW);
    if(nToken != 0)
    {
        BurFeedWindow(oPC, nToken);
        return;
    }

    float fCX = (IntToFloat(GetPlayerDeviceProperty(oPC, PLAYER_DEVICE_PROPERTY_GUI_WIDTH))
                 - GetNuiScaleDimension(oPC, BUR_W)) / 2.0;
    float fCY = (IntToFloat(GetPlayerDeviceProperty(oPC, PLAYER_DEVICE_PROPERTY_GUI_HEIGHT))
                 - GetNuiScaleDimension(oPC, BUR_H)) / 2.0;
    json jGeom = NuiRect(fCX, fCY,
        GetNuiScaleDimension(oPC, BUR_W),
        GetNuiScaleDimension(oPC, BUR_H));

    json jWin = NuiWindow(
        BurBuildLayout(oPC),
        JsonBool(FALSE),
        NuiBind(BUR_WIN_GEOM),
        JsonBool(FALSE),
        JsonBool(FALSE),
        JsonBool(FALSE),
        JsonBool(TRUE),
        JsonBool(FALSE));

    nToken = NuiCreate(oPC, jWin, BUR_WINDOW, BUR_EV_SCRIPT);
    NuiSetBind(oPC, nToken, BUR_WIN_GEOM, jGeom);
    BurFeedWindow(oPC, nToken);
}
