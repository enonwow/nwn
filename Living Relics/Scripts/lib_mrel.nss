#include "lib_mrel_def"

// ----------------------------------------------------------------
// NUI window builder
// ----------------------------------------------------------------

json MrelBuildSlotListRow(object oPC)
{
    float fBtnH  = GetNuiScaleDimension(oPC, 36.0);
    float fHungW = GetNuiScaleDimension(oPC, 100.0);
    float fProgW = GetNuiScaleDimension(oPC, 90.0);
    float fMemW  = GetNuiScaleDimension(oPC, 55.0);

    json jNameLbl = NuiLabel(NuiBind(MREL_BIND_SLOT_NAME),
        JsonInt(NUI_HALIGN_LEFT), JsonInt(NUI_VALIGN_MIDDLE));

    json jHungLbl = NuiLabel(NuiBind(MREL_BIND_SLOT_HUNG),
        JsonInt(NUI_HALIGN_CENTER), JsonInt(NUI_VALIGN_MIDDLE));
    jHungLbl = NuiWidth(jHungLbl, fHungW);

    json jProg = NuiProgressBar(NuiBind(MREL_BIND_SLOT_MPROG));
    jProg = NuiWidth(jProg, fProgW);
    jProg = NuiTooltip(jProg, NuiBind(MREL_BIND_SLOT_MEM));

    json jMemLbl = NuiLabel(NuiBind(MREL_BIND_SLOT_MEM),
        JsonInt(NUI_HALIGN_CENTER), JsonInt(NUI_VALIGN_MIDDLE));
    jMemLbl = NuiWidth(jMemLbl, fMemW);

    json jCellRow = JsonArray();
    jCellRow = JsonArrayInsert(jCellRow, jNameLbl);
    jCellRow = JsonArrayInsert(jCellRow, jHungLbl);
    jCellRow = JsonArrayInsert(jCellRow, jProg);
    jCellRow = JsonArrayInsert(jCellRow, jMemLbl);

    json jCell = NuiGroup(NuiRow(jCellRow), FALSE, NUI_SCROLLBARS_NONE);
    jCell = NuiId(jCell, MREL_BTN_ROW);
    jCell = NuiHeight(jCell, fBtnH);
    jCell = NuiEncouraged(jCell, NuiBind(MREL_BIND_SLOT_ENC));

    return NuiListTemplateCell(jCell, 0.0, TRUE);
}

void MrelCreateWindow(object oPC)
{
    if(NuiFindWindow(oPC, MREL_WINDOW) != 0) return;

    float fBtnH   = GetNuiScaleDimension(oPC, 32.0);
    float fRowH   = GetNuiScaleDimension(oPC, 36.0);
    float fListH  = GetNuiScaleDimension(oPC, 120.0);
    float fVisionH= GetNuiScaleDimension(oPC, 80.0);
    float fBtnW   = GetNuiScaleDimension(oPC, 130.0);
    float fBtnWS  = GetNuiScaleDimension(oPC, 120.0);

    // ---- Header row ----
    json jTitle = NuiLabel(JsonString("Żywe Relikwie"),
        JsonInt(NUI_HALIGN_LEFT), JsonInt(NUI_VALIGN_MIDDLE));
    jTitle = NuiHeight(jTitle, fBtnH);

    json jClose = NuiButton(JsonString("X"));
    jClose = NuiId(jClose, MREL_BTN_CLOSE);
    jClose = NuiWidth(jClose, fBtnH);
    jClose = NuiHeight(jClose, fBtnH);

    json jHeaderRow = JsonArray();
    jHeaderRow = JsonArrayInsert(jHeaderRow, jTitle);
    jHeaderRow = JsonArrayInsert(jHeaderRow, jClose);
    json jHeader = NuiRow(jHeaderRow);

    // ---- Column labels ----
    float fHungW  = GetNuiScaleDimension(oPC, 100.0);
    float fProgW  = GetNuiScaleDimension(oPC, 90.0);
    float fMemW   = GetNuiScaleDimension(oPC, 55.0);

    json jLblPrz   = NuiLabel(JsonString("Przedmiot"),
        JsonInt(NUI_HALIGN_LEFT), JsonInt(NUI_VALIGN_MIDDLE));
    json jLblGlod  = NuiLabel(JsonString("Głód"),
        JsonInt(NUI_HALIGN_CENTER), JsonInt(NUI_VALIGN_MIDDLE));
    jLblGlod = NuiWidth(jLblGlod, fHungW);
    json jLblPamSp = NuiLabel(JsonString("Pamięć"),
        JsonInt(NUI_HALIGN_CENTER), JsonInt(NUI_VALIGN_MIDDLE));
    jLblPamSp = NuiWidth(jLblPamSp, fProgW);
    json jLblPamN  = NuiLabel(JsonString(""),
        JsonInt(NUI_HALIGN_CENTER), JsonInt(NUI_VALIGN_MIDDLE));
    jLblPamN = NuiWidth(jLblPamN, fMemW);

    json jColLblRow = JsonArray();
    jColLblRow = JsonArrayInsert(jColLblRow, jLblPrz);
    jColLblRow = JsonArrayInsert(jColLblRow, jLblGlod);
    jColLblRow = JsonArrayInsert(jColLblRow, jLblPamSp);
    jColLblRow = JsonArrayInsert(jColLblRow, jLblPamN);
    json jColLabels = NuiRow(jColLblRow);
    jColLabels = NuiHeight(jColLabels, GetNuiScaleDimension(oPC, 20.0));

    // ---- Slot list ----
    json jTmpl = JsonArrayInsert(JsonArray(), MrelBuildSlotListRow(oPC));
    json jList = NuiList(jTmpl, JsonInt(MREL_SLOT_COUNT), fRowH);
    jList = NuiHeight(jList, fListH);

    // ---- Vision panel (last whisper) ----
    json jVisionHdr = NuiLabel(JsonString("Ostatni szept:"),
        JsonInt(NUI_HALIGN_LEFT), JsonInt(NUI_VALIGN_MIDDLE));
    jVisionHdr = NuiHeight(jVisionHdr, GetNuiScaleDimension(oPC, 20.0));

    json jVisionTxt = NuiGroup(
        NuiText(NuiBind(MREL_BIND_VISION), FALSE),
        TRUE, NUI_SCROLLBARS_Y);
    jVisionTxt = NuiHeight(jVisionTxt, fVisionH);

    // ---- Action buttons ----
    json jBtnAttune = NuiButton(JsonString("Poświęć"));
    jBtnAttune = NuiId(jBtnAttune, MREL_BTN_ATTUNE);
    jBtnAttune = NuiEnabled(jBtnAttune, NuiBind(MREL_BIND_ATTUNE_ENA));
    jBtnAttune = NuiWidth(jBtnAttune, fBtnW);
    jBtnAttune = NuiHeight(jBtnAttune, fBtnH);
    jBtnAttune = NuiTooltip(jBtnAttune, JsonString("Wybierz przedmiot z ekwipunku do atunementu."));

    json jBtnRemove = NuiButton(JsonString("Usuń"));
    jBtnRemove = NuiId(jBtnRemove, MREL_BTN_REMOVE);
    jBtnRemove = NuiEnabled(jBtnRemove, NuiBind(MREL_BIND_REMOVE_ENA));
    jBtnRemove = NuiWidth(jBtnRemove, fBtnW);
    jBtnRemove = NuiHeight(jBtnRemove, fBtnH);
    jBtnRemove = NuiTooltip(jBtnRemove, JsonString("Usuń wybraną relikwię — traci wszystkie wspomnienia."));

    json jBtnBlood = NuiButton(NuiBind(MREL_BIND_BLOOD_LBL));
    jBtnBlood = NuiId(jBtnBlood, MREL_BTN_BLOOD);
    jBtnBlood = NuiEnabled(jBtnBlood, NuiBind(MREL_BIND_BLOOD_ENA));
    jBtnBlood = NuiWidth(jBtnBlood, fBtnWS);
    jBtnBlood = NuiHeight(jBtnBlood, fBtnH);
    jBtnBlood = NuiTooltip(jBtnBlood, JsonString("Ofiara -5 PŻ — relikwia pochłania twoją krew, zyskując pamięć."));

    json jBtnWake = NuiButton(JsonString("Obudź"));
    jBtnWake = NuiId(jBtnWake, MREL_BTN_WAKE);
    jBtnWake = NuiEnabled(jBtnWake, NuiBind(MREL_BIND_WAKE_ENA));
    jBtnWake = NuiWidth(jBtnWake, fBtnW);
    jBtnWake = NuiHeight(jBtnWake, fBtnH);
    jBtnWake = NuiTooltip(jBtnWake, JsonString("Wymuś przebudzenie relikwii (tylko gdy pamięć jest pełna)."));

    json jBtnRow1 = JsonArray();
    jBtnRow1 = JsonArrayInsert(jBtnRow1, jBtnAttune);
    jBtnRow1 = JsonArrayInsert(jBtnRow1, jBtnRemove);
    jBtnRow1 = JsonArrayInsert(jBtnRow1, NuiSpacer());

    json jBtnRow2 = JsonArray();
    jBtnRow2 = JsonArrayInsert(jBtnRow2, jBtnBlood);
    jBtnRow2 = JsonArrayInsert(jBtnRow2, jBtnWake);
    jBtnRow2 = JsonArrayInsert(jBtnRow2, NuiSpacer());

    // ---- Assemble layout ----
    json jChildren = JsonArray();
    jChildren = JsonArrayInsert(jChildren, jHeader);
    jChildren = JsonArrayInsert(jChildren, jColLabels);
    jChildren = JsonArrayInsert(jChildren, jList);
    jChildren = JsonArrayInsert(jChildren, jVisionHdr);
    jChildren = JsonArrayInsert(jChildren, jVisionTxt);
    jChildren = JsonArrayInsert(jChildren, NuiRow(jBtnRow1));
    jChildren = JsonArrayInsert(jChildren, NuiRow(jBtnRow2));

    json jLayout = NuiCol(jChildren);
    json jRoot   = NuiWindow(jLayout,
        JsonString("Żywe Relikwie"),
        NuiBind(MREL_WIN_GEOM),
        JsonBool(FALSE), JsonBool(FALSE),
        JsonBool(TRUE),  JsonBool(FALSE), JsonBool(TRUE));

    int nToken = NuiCreate(oPC, jRoot, MREL_EV_SCRIPT, MREL_WINDOW);
    NuiSetBind(oPC, nToken, MREL_WIN_GEOM,
        NuiRect(80.0, 50.0, MREL_W, MREL_H));

    MrelFeedRelicList(oPC, nToken);
    MrelFeedDetail(oPC, nToken);
}

// ----------------------------------------------------------------
// Data feed
// ----------------------------------------------------------------

void MrelFeedRelicList(object oPC, int nToken)
{
    string sUuid = GetObjectUUID(oPC);
    json jAll    = MrelDbGetAllRelics(sUuid);

    json jNames  = JsonArray();
    json jHungs  = JsonArray();
    json jProgs  = JsonArray();
    json jMems   = JsonArray();
    json jEncs   = JsonArray();

    int nSelSlot = GetLocalInt(oPC, MREL_LVAR_SEL_SLOT);
    int i;
    for(i = 0; i < MREL_SLOT_COUNT; i++)
    {
        json jRelic = JsonArrayGet(jAll, i);
        int  nSlot  = i + 1;

        if(JsonGetType(jRelic) == JSON_TYPE_NULL)
        {
            jNames = JsonArrayInsert(jNames, JsonString("--- (pusty slot " + IntToString(nSlot) + ")"));
            jHungs = JsonArrayInsert(jHungs, JsonString("---"));
            jProgs = JsonArrayInsert(jProgs, JsonFloat(0.0));
            jMems  = JsonArrayInsert(jMems,  JsonString("-/-"));
        }
        else
        {
            int nHunger  = JsonGetInt(JsonObjectGet(jRelic, "hunger"));
            int nMem     = JsonGetInt(JsonObjectGet(jRelic, "memory"));
            int nMemMax  = MrelMemMax(nHunger);
            string sName = JsonGetString(JsonObjectGet(jRelic, "item_name"));
            float fProg  = IntToFloat(nMem) / IntToFloat(nMemMax);

            jNames = JsonArrayInsert(jNames, JsonString(sName));
            jHungs = JsonArrayInsert(jHungs, JsonString(MrelHungerLabel(nHunger)));
            jProgs = JsonArrayInsert(jProgs, JsonFloat(fProg > 1.0 ? 1.0 : fProg));
            jMems  = JsonArrayInsert(jMems,  JsonString(IntToString(nMem) + "/" + IntToString(nMemMax)));
        }
        jEncs = JsonArrayInsert(jEncs, JsonBool(nSelSlot == nSlot));
    }

    NuiSetBind(oPC, nToken, MREL_BIND_SLOT_NAME,  jNames);
    NuiSetBind(oPC, nToken, MREL_BIND_SLOT_HUNG,  jHungs);
    NuiSetBind(oPC, nToken, MREL_BIND_SLOT_MPROG, jProgs);
    NuiSetBind(oPC, nToken, MREL_BIND_SLOT_MEM,   jMems);
    NuiSetBind(oPC, nToken, MREL_BIND_SLOT_ENC,   jEncs);
}

void MrelFeedDetail(object oPC, int nToken)
{
    string sUuid   = GetObjectUUID(oPC);
    int    nSel    = GetLocalInt(oPC, MREL_LVAR_SEL_SLOT);
    int    bHasSel = (nSel >= 1 && nSel <= MREL_SLOT_COUNT);

    if(!bHasSel)
    {
        NuiSetBind(oPC, nToken, MREL_BIND_VISION,     JsonString("Wybierz relikwię z listy, by zobaczyć jej ostatni szept."));
        NuiSetBind(oPC, nToken, MREL_BIND_ATTUNE_ENA, JsonBool(TRUE));
        NuiSetBind(oPC, nToken, MREL_BIND_REMOVE_ENA, JsonBool(FALSE));
        NuiSetBind(oPC, nToken, MREL_BIND_BLOOD_ENA,  JsonBool(FALSE));
        NuiSetBind(oPC, nToken, MREL_BIND_WAKE_ENA,   JsonBool(FALSE));
        NuiSetBind(oPC, nToken, MREL_BIND_BLOOD_LBL,  JsonString("Ofiara krwi (-5 PŻ)"));
        return;
    }

    json jRelic = MrelDbGetRelic(sUuid, nSel);
    int bEmpty  = (JsonGetType(jRelic) == JSON_TYPE_NULL);

    if(bEmpty)
    {
        NuiSetBind(oPC, nToken, MREL_BIND_VISION,     JsonString("Slot pusty. Użyj 'Poświęć', aby przywiązać przedmiot z ekwipunku."));
        NuiSetBind(oPC, nToken, MREL_BIND_ATTUNE_ENA, JsonBool(TRUE));
        NuiSetBind(oPC, nToken, MREL_BIND_REMOVE_ENA, JsonBool(FALSE));
        NuiSetBind(oPC, nToken, MREL_BIND_BLOOD_ENA,  JsonBool(FALSE));
        NuiSetBind(oPC, nToken, MREL_BIND_WAKE_ENA,   JsonBool(FALSE));
        NuiSetBind(oPC, nToken, MREL_BIND_BLOOD_LBL,  JsonString("Ofiara krwi (-5 PŻ)"));
        return;
    }

    int nHunger    = JsonGetInt(JsonObjectGet(jRelic, "hunger"));
    int nMem       = JsonGetInt(JsonObjectGet(jRelic, "memory"));
    int nMemMax    = MrelMemMax(nHunger);
    string sVisons = JsonGetString(JsonObjectGet(jRelic, "visions_json"));
    string sLast   = MrelDbGetLastVision(sVisons);

    if(sLast == "")
        sLast = "Relikwia pochłonęła już pierwsze wrażenia, lecz jeszcze nie przemówiła.";

    int bBloodOk = (nHunger >= 2 && GetCurrentHitPoints(oPC) > MREL_BLOOD_COST_HP + 5);
    int bWakeOk  = (nMem >= nMemMax);

    NuiSetBind(oPC, nToken, MREL_BIND_VISION,     JsonString(sLast));
    NuiSetBind(oPC, nToken, MREL_BIND_ATTUNE_ENA, JsonBool(FALSE));
    NuiSetBind(oPC, nToken, MREL_BIND_REMOVE_ENA, JsonBool(TRUE));
    NuiSetBind(oPC, nToken, MREL_BIND_BLOOD_ENA,  JsonBool(bBloodOk));
    NuiSetBind(oPC, nToken, MREL_BIND_WAKE_ENA,   JsonBool(bWakeOk));
    NuiSetBind(oPC, nToken, MREL_BIND_BLOOD_LBL,
        JsonString("Ofiara krwi (-" + IntToString(MREL_BLOOD_COST_HP) + " PŻ)"));
}

// ----------------------------------------------------------------
// Attunement
// ----------------------------------------------------------------

void MrelAttuneItem(object oPC, int nSlot, object oItem)
{
    if(nSlot < 1 || nSlot > MREL_SLOT_COUNT || !GetIsObjectValid(oItem)) return;
    if(GetItemPossessor(oItem) != oPC) return;

    string sUuid  = GetObjectUUID(oPC);
    string sMrelId = sUuid + "_" + IntToString(nSlot);

    // Clear any previous occupant of this slot from their item
    json jOld = MrelDbGetRelic(sUuid, nSlot);
    if(JsonGetType(jOld) != JSON_TYPE_NULL)
    {
        string sOldId = JsonGetString(JsonObjectGet(jOld, "mrel_id"));
        // Scan inventory to clear old LVAR; best-effort
        object oOld = GetFirstItemInInventory(oPC);
        while(GetIsObjectValid(oOld))
        {
            if(GetLocalString(oOld, MREL_ITEM_LVAR) == sOldId)
            {
                DeleteLocalString(oOld, MREL_ITEM_LVAR);
                break;
            }
            oOld = GetNextItemInInventory(oPC);
        }
    }

    SetLocalString(oItem, MREL_ITEM_LVAR, sMrelId);
    MrelDbAttune(sUuid, nSlot, sMrelId, GetName(oItem), GetBaseItemType(oItem));

    SendMessageToPC(oPC, "[Relikwia] Poświęciłeś przedmiot '" + GetName(oItem) +
        "' w slocie " + IntToString(nSlot) + ". Czeka na wspomnienia.");

    int nToken = NuiFindWindow(oPC, MREL_WINDOW);
    if(nToken != 0)
    {
        MrelFeedRelicList(oPC, nToken);
        MrelFeedDetail(oPC, nToken);
    }
}

// ----------------------------------------------------------------
// Removal
// ----------------------------------------------------------------

void MrelRemoveRelic(object oPC, int nSlot)
{
    if(nSlot < 1 || nSlot > MREL_SLOT_COUNT) return;
    string sUuid = GetObjectUUID(oPC);
    json jRelic  = MrelDbGetRelic(sUuid, nSlot);

    if(JsonGetType(jRelic) == JSON_TYPE_NULL) return;

    string sMrelId = JsonGetString(JsonObjectGet(jRelic, "mrel_id"));
    // Clear LVAR on item
    object oItem = GetFirstItemInInventory(oPC);
    while(GetIsObjectValid(oItem))
    {
        if(GetLocalString(oItem, MREL_ITEM_LVAR) == sMrelId)
        {
            DeleteLocalString(oItem, MREL_ITEM_LVAR);
            break;
        }
        oItem = GetNextItemInInventory(oPC);
    }

    MrelDbRemove(sUuid, nSlot);
    DeleteLocalInt(oPC, MREL_LVAR_SEL_SLOT);
    SendMessageToPC(oPC, "[Relikwia] Więź została zerwana. Przedmiot utracił swoje wspomnienia.");

    int nToken = NuiFindWindow(oPC, MREL_WINDOW);
    if(nToken != 0)
    {
        MrelFeedRelicList(oPC, nToken);
        MrelFeedDetail(oPC, nToken);
    }
}

// ----------------------------------------------------------------
// Memory feeding
// ----------------------------------------------------------------

void MrelFeedMemory(object oPC, int nAmount, int nTrigger)
{
    if(nAmount <= 0) return;
    string sUuid = GetObjectUUID(oPC);
    int i;
    for(i = 1; i <= MREL_SLOT_COUNT; i++)
    {
        json jRelic = MrelDbGetRelic(sUuid, i);
        if(JsonGetType(jRelic) == JSON_TYPE_NULL) continue;

        // Only accumulate if item is currently in possession (equipped or inventory)
        string sMrelId = JsonGetString(JsonObjectGet(jRelic, "mrel_id"));
        int bFound = FALSE;
        object oItem = GetFirstItemInInventory(oPC);
        while(GetIsObjectValid(oItem))
        {
            if(GetLocalString(oItem, MREL_ITEM_LVAR) == sMrelId) { bFound = TRUE; break; }
            oItem = GetNextItemInInventory(oPC);
        }
        if(!bFound)
        {
            // Check equipped slots
            int nSlotIdx;
            for(nSlotIdx = 0; nSlotIdx < NUM_INVENTORY_SLOTS; nSlotIdx++)
            {
                object oEq = GetItemInSlot(nSlotIdx, oPC);
                if(GetIsObjectValid(oEq) && GetLocalString(oEq, MREL_ITEM_LVAR) == sMrelId)
                {
                    bFound = TRUE;
                    break;
                }
            }
        }
        if(!bFound) continue;

        int nHunger  = JsonGetInt(JsonObjectGet(jRelic, "hunger"));
        int nMem     = JsonGetInt(JsonObjectGet(jRelic, "memory"));
        int nMemMax  = MrelMemMax(nHunger);
        string sVis  = JsonGetString(JsonObjectGet(jRelic, "visions_json"));
        int nNewMem  = nMem + nAmount;

        if(nNewMem >= nMemMax)
        {
            // Cap at max and store; wake happens when player triggers or on rest
            nNewMem = nMemMax;
            MrelDbUpdateState(sUuid, i, nHunger, nNewMem, sVis);
            SendMessageToPC(oPC, "[Relikwia] Puls nasila się — slot " + IntToString(i) + " jest gotowy na przebudzenie.");
        }
        else
        {
            MrelDbUpdateState(sUuid, i, nHunger, nNewMem, sVis);
        }
    }

    int nToken = NuiFindWindow(oPC, MREL_WINDOW);
    if(nToken != 0)
    {
        MrelFeedRelicList(oPC, nToken);
        MrelFeedDetail(oPC, nToken);
    }
}

// ----------------------------------------------------------------
// Wake (vision + effect)
// ----------------------------------------------------------------

void MrelApplyWakeEffect(object oPC, int nHunger)
{
    switch(nHunger)
    {
        case 1:
            ApplyEffectToObject(DURATION_TYPE_TEMPORARY,
                SupernaturalEffect(EffectAbilityIncrease(ABILITY_STRENGTH, 2)),
                oPC, 600.0);
            SendMessageToPC(oPC, "[Relikwia] Czujesz nagły napływ siły z głębin wspomnienia.");
            break;

        case 2:
            ApplyEffectToObject(DURATION_TYPE_TEMPORARY,
                SupernaturalEffect(EffectRegenerate(2, 6.0)),
                oPC, 300.0);
            SendMessageToPC(oPC, "[Relikwia] Twoje rany zaczynają się zamykać... szeptem dawnych bóli.");
            break;

        case 3:
            // AC bonus from accumulated battle memory + costs 1 CON
            ApplyEffectToObject(DURATION_TYPE_TEMPORARY,
                SupernaturalEffect(EffectACIncrease(4, AC_DODGE_BONUS, AC_VS_DAMAGE_TYPE_ALL)),
                oPC, 600.0);
            ApplyEffectToObject(DURATION_TYPE_PERMANENT,
                SupernaturalEffect(EffectAbilityDecrease(ABILITY_CONSTITUTION, 1)),
                oPC);
            SendMessageToPC(oPC, "[Relikwia] Wspomnienia bitew chronią cię... lecz relikwia pobiera haracz od twojego ciała.");
            FloatingTextStringOnCreature("Relikwia pobiera haracz...", oPC, FALSE);
            break;

        case 4:
            // Haste from concentrated memories + brief overwhelming stun
            ApplyEffectToObject(DURATION_TYPE_TEMPORARY,
                SupernaturalEffect(EffectHaste()),
                oPC, 60.0);
            ApplyEffectToObject(DURATION_TYPE_TEMPORARY,
                EffectStunned(),
                oPC, 3.0);
            SendMessageToPC(oPC, "[Relikwia] Przelewający się strumień wspomnień ogłusza cię — a potem popycha naprzód z nadludzką szybkością.");
            FloatingTextStringOnCreature("WIZJA PRZESZYWA!", oPC, FALSE);
            break;

        case 5:
            // Full restoration + Death Ward: the relic gives everything it has
            ApplyEffectToObject(DURATION_TYPE_INSTANT,
                EffectHeal(GetMaxHitPoints(oPC)), oPC);
            ApplyEffectToObject(DURATION_TYPE_TEMPORARY,
                SupernaturalEffect(EffectDeathWard()),
                oPC, 3600.0);
            SendMessageToPC(oPC, "[Relikwia] PRZEBUDZENIE. Relikwia przekazuje ci wszystkie pochłoniete życia. Zostajesz uzdrowiony. Zostajesz przez nią naznaczony na zawsze.");
            FloatingTextStringOnCreature("PRZEBUDZENIE RELIKWII!", oPC, FALSE);
            break;
    }
}

void MrelWakeRelic(object oPC, int nSlot)
{
    if(nSlot < 1 || nSlot > MREL_SLOT_COUNT) return;
    string sUuid = GetObjectUUID(oPC);
    json jRelic  = MrelDbGetRelic(sUuid, nSlot);
    if(JsonGetType(jRelic) == JSON_TYPE_NULL) return;

    int nHunger    = JsonGetInt(JsonObjectGet(jRelic, "hunger"));
    int nMem       = JsonGetInt(JsonObjectGet(jRelic, "memory"));
    int nMemMax    = MrelMemMax(nHunger);
    string sVisions = JsonGetString(JsonObjectGet(jRelic, "visions_json"));

    // Must be at or above threshold
    if(nMem < nMemMax) return;

    // Determine trigger type for vision (default KILL since it's the most common path)
    int nTrigger = GetLocalInt(oPC, "MREL_LAST_TRIG_" + IntToString(nSlot));
    if(nTrigger == 0) nTrigger = MREL_TRIG_KILL;

    string sVisionText = MrelGetVisionText(nTrigger, nHunger);

    // Apply effect
    MrelApplyWakeEffect(oPC, nHunger);

    // Progress hunger or loop back from 5 to 2
    int nNewHunger = (nHunger >= 5) ? 2 : nHunger + 1;
    int nNewMem    = 0;

    // Record vision
    sVisions = MrelDbAppendVision(sVisions, sVisionText, nTrigger, nHunger);
    MrelDbUpdateState(sUuid, nSlot, nNewHunger, nNewMem, sVisions);

    DeleteLocalInt(oPC, "MREL_LAST_TRIG_" + IntToString(nSlot));

    // Atmospheric notification
    SendMessageToPC(oPC, "[Relikwia — Slot " + IntToString(nSlot) + "] \"" + sVisionText + "\"");

    int nToken = NuiFindWindow(oPC, MREL_WINDOW);
    if(nToken != 0)
    {
        MrelFeedRelicList(oPC, nToken);
        MrelFeedDetail(oPC, nToken);
    }
}

// ----------------------------------------------------------------
// Integration helpers (call from module event scripts)
// ----------------------------------------------------------------

void MrelOnKill(object oKiller)
{
    if(!GetIsPC(oKiller)) return;
    SetLocalInt(oKiller, "MREL_LAST_TRIG_1", MREL_TRIG_KILL);
    SetLocalInt(oKiller, "MREL_LAST_TRIG_2", MREL_TRIG_KILL);
    SetLocalInt(oKiller, "MREL_LAST_TRIG_3", MREL_TRIG_KILL);
    MrelFeedMemory(oKiller, 2, MREL_TRIG_KILL);
}

void MrelOnSurvive(object oPC)
{
    if(!GetIsPC(oPC)) return;
    int nHP    = GetCurrentHitPoints(oPC);
    int nMaxHP = GetMaxHitPoints(oPC);
    if(nMaxHP <= 0) return;
    int nPct   = (nHP * 100) / nMaxHP;
    if(nPct > MREL_SURVIVE_HP_PCT) return;
    SetLocalInt(oPC, "MREL_LAST_TRIG_1", MREL_TRIG_SURVIVE);
    SetLocalInt(oPC, "MREL_LAST_TRIG_2", MREL_TRIG_SURVIVE);
    SetLocalInt(oPC, "MREL_LAST_TRIG_3", MREL_TRIG_SURVIVE);
    MrelFeedMemory(oPC, 3, MREL_TRIG_SURVIVE);
}

void MrelOnWitness(object oPC)
{
    if(!GetIsPC(oPC)) return;
    SetLocalInt(oPC, "MREL_LAST_TRIG_1", MREL_TRIG_WITNESS);
    SetLocalInt(oPC, "MREL_LAST_TRIG_2", MREL_TRIG_WITNESS);
    SetLocalInt(oPC, "MREL_LAST_TRIG_3", MREL_TRIG_WITNESS);
    MrelFeedMemory(oPC, 1, MREL_TRIG_WITNESS);
}

// ----------------------------------------------------------------
// Sync: re-verify that all DB relic records have matching items on
// the PC. Called on login; warns if an attuned item is missing.
// ----------------------------------------------------------------

void MrelSyncItems(object oPC)
{
    string sUuid = GetObjectUUID(oPC);
    int i;
    for(i = 1; i <= MREL_SLOT_COUNT; i++)
    {
        json jRelic = MrelDbGetRelic(sUuid, i);
        if(JsonGetType(jRelic) == JSON_TYPE_NULL) continue;

        string sMrelId   = JsonGetString(JsonObjectGet(jRelic, "mrel_id"));
        string sItemName = JsonGetString(JsonObjectGet(jRelic, "item_name"));
        int bFound = FALSE;

        int nSlotIdx;
        for(nSlotIdx = 0; nSlotIdx < NUM_INVENTORY_SLOTS; nSlotIdx++)
        {
            object oEq = GetItemInSlot(nSlotIdx, oPC);
            if(GetIsObjectValid(oEq) && GetLocalString(oEq, MREL_ITEM_LVAR) == sMrelId)
            {
                bFound = TRUE; break;
            }
        }

        if(!bFound)
        {
            object oItem = GetFirstItemInInventory(oPC);
            while(GetIsObjectValid(oItem))
            {
                if(GetLocalString(oItem, MREL_ITEM_LVAR) == sMrelId) { bFound = TRUE; break; }
                oItem = GetNextItemInInventory(oPC);
            }
        }

        if(!bFound)
            SendMessageToPC(oPC, "[Relikwia] Uwaga: relikwia ze slotu " + IntToString(i)
                + " ('" + sItemName + "') nie jest przy tobie. Wspomnienia pulsują w ciemności...");
    }
}
