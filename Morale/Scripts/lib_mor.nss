#include "lib_mor_def"
#include "sql_mor"

// ----------------------------------------------------------------
// Morale accessors
// ----------------------------------------------------------------

int MorGet(object oPC)
{
    return GetLocalInt(oPC, "MOR_VALUE");
}

void MorSet(object oPC, int nValue)
{
    if(nValue > MOR_MAX) nValue = MOR_MAX;
    if(nValue < MOR_MIN) nValue = MOR_MIN;
    SetLocalInt(oPC, "MOR_VALUE", nValue);
    MorSave(oPC, nValue);
}

// Returns 0=none 1=shaken 2=frightened 3=panicked 4=broken
int MorGetTier(int nMorale)
{
    if(nMorale > MOR_THRESHOLD_SHAKEN)     return 0;
    if(nMorale > MOR_THRESHOLD_FRIGHTENED) return 1;
    if(nMorale > MOR_THRESHOLD_PANICKED)   return 2;
    if(nMorale > MOR_THRESHOLD_BROKEN)     return 3;
    return 4;
}

string MorTierName(int nTier)
{
    switch(nTier)
    {
        case 0: return "Niezachwiany";
        case 1: return "Wzburzony";
        case 2: return "Przestraszony";
        case 3: return "W panice";
        case 4: return "Złamany";
    }
    return "Nieznany";
}

string MorTierDesc(int nTier)
{
    switch(nTier)
    {
        case 0: return "Duch bojowy nienaruszony.";
        case 1: return "Ręce lekko drżą. -1 do ataków i rzutów obronnych.";
        case 2: return "Strach ściska gardło. -2 do ataków i rzutów obronnych.";
        case 3: return "Instynkt ucieczki bierze górę. -4 do ataków i rzutów; chwilowe odruchy ucieczki.";
        case 4: return "Wola walki całkowicie złamana. -5 do ataków i rzutów; spazmatyczna ucieczka.";
    }
    return "";
}

// ----------------------------------------------------------------
// Effect management
// ----------------------------------------------------------------

void MorRemovePenalties(object oPC)
{
    effect eCheck = GetFirstEffect(oPC);
    while(GetIsEffectValid(eCheck))
    {
        if(GetEffectTag(eCheck) == MOR_EFFECT_TAG)
            RemoveEffect(oPC, eCheck);
        eCheck = GetNextEffect(oPC);
    }
}

// Applies the appropriate stacking penalties for the current tier.
// All effects are tagged MOR_EFFECT_TAG for clean removal.
void MorApplyPenalties(object oPC)
{
    MorRemovePenalties(oPC);

    int nTier = MorGetTier(MorGet(oPC));
    if(nTier == 0) return;

    int nAttack = 0;
    int nSave   = 0;

    switch(nTier)
    {
        case 1: nAttack = -1; nSave = -1; break;
        case 2: nAttack = -2; nSave = -2; break;
        case 3: nAttack = -4; nSave = -4; break;
        case 4: nAttack = -5; nSave = -5; break;
    }

    effect eAtk  = TagEffect(EffectAttackDecrease(nAttack * -1), MOR_EFFECT_TAG);
    effect eSave = TagEffect(EffectSavingThrowDecrease(nSave * -1, SAVING_THROW_ALL), MOR_EFFECT_TAG);

    ApplyEffectToObject(DURATION_TYPE_PERMANENT, eAtk,  oPC);
    ApplyEffectToObject(DURATION_TYPE_PERMANENT, eSave, oPC);

    // Frightened and above: Dexterity penalty represents trembling
    if(nTier >= 2)
    {
        effect eDex = TagEffect(EffectAbilityDecrease(ABILITY_DEXTERITY, nTier - 1), MOR_EFFECT_TAG);
        ApplyEffectToObject(DURATION_TYPE_PERMANENT, eDex, oPC);
    }
}

// ----------------------------------------------------------------
// Log helpers
// ----------------------------------------------------------------

void MorAddLog(object oPC, string sEntry)
{
    json jLog = GetLocalJson(oPC, MOR_LVAR_LOG);
    if(JsonGetType(jLog) != JSON_TYPE_ARRAY)
        jLog = JsonArray();

    jLog = JsonArrayInsert(jLog, JsonString(sEntry));
    // Keep only last 8 entries
    while(JsonGetLength(jLog) > 8)
        jLog = JsonArrayDel(jLog, 0);

    SetLocalJson(oPC, MOR_LVAR_LOG, jLog);
}

// ----------------------------------------------------------------
// NUI window build helpers
// ----------------------------------------------------------------

// Builds and opens the morale window.
void MorOpenWindow(object oPC)
{
    int nToken = NuiFindWindow(oPC, MOR_WINDOW);
    if(nToken != 0)
    {
        MorFeedWindow(oPC, nToken);
        return;
    }

    // ---- Layout ----
    json jRows = JsonArray();

    // Title row
    {
        json jTitle = NuiLabel(JsonString("Morale Bojowe"), NuiHAlignCenter(), NuiVAlignMiddle());
        jTitle = NuiHeight(jTitle, 28.0);
        jRows = JsonArrayInsert(jRows, NuiRow(JsonArrayInsert(JsonArray(), jTitle)));
    }

    // Separator
    jRows = JsonArrayInsert(jRows, CreateEmptyRow(oPC, 4.0));

    // State label (colored by tier)
    {
        json jStateLbl = NuiLabel(NuiBind(MOR_BIND_STATE_LBL), NuiHAlignCenter(), NuiVAlignMiddle());
        json jRow = JsonArrayInsert(JsonArray(), NuiHeight(jStateLbl, 26.0));
        jRows = JsonArrayInsert(jRows, NuiRow(jRow));
    }

    // Morale number
    {
        json jNum = NuiLabel(NuiBind(MOR_BIND_MORALE_NUM), NuiHAlignCenter(), NuiVAlignMiddle());
        json jRow = JsonArrayInsert(JsonArray(), NuiHeight(jNum, 20.0));
        jRows = JsonArrayInsert(jRows, NuiRow(jRow));
    }

    // Progress bar row
    {
        json jBar = NuiProgress(NuiBind(MOR_BIND_BAR_VAL));
        jBar = NuiHeight(jBar, 22.0);
        json jRow = JsonArrayInsert(JsonArray(), jBar);
        jRows = JsonArrayInsert(jRows, NuiRow(jRow));
    }

    jRows = JsonArrayInsert(jRows, CreateEmptyRow(oPC, 6.0));

    // Debuff label header
    {
        json jHdr = NuiLabel(JsonString("Aktywne kary:"), NuiHAlignLeft(), NuiVAlignMiddle());
        json jRow = JsonArrayInsert(JsonArray(), NuiHeight(jHdr, 18.0));
        jRows = JsonArrayInsert(jRows, NuiRow(jRow));
    }

    // Debuff description
    {
        json jDebuff = NuiLabel(NuiBind(MOR_BIND_DEBUFF_LBL), NuiHAlignLeft(), NuiVAlignTop());
        jDebuff = NuiHeight(jDebuff, 50.0);
        jDebuff = NuiTooltip(jDebuff, JsonString("Kary wynikające z obecnego stanu morale"));
        json jRow = JsonArrayInsert(JsonArray(), jDebuff);
        jRows = JsonArrayInsert(jRows, NuiRow(jRow));
    }

    jRows = JsonArrayInsert(jRows, CreateEmptyRow(oPC, 6.0));

    // Log header
    {
        json jHdr = NuiLabel(JsonString("Ostatnie zdarzenia:"), NuiHAlignLeft(), NuiVAlignMiddle());
        json jRow = JsonArrayInsert(JsonArray(), NuiHeight(jHdr, 18.0));
        jRows = JsonArrayInsert(jRows, NuiRow(jRow));
    }

    // Log list (listbox style via NuiList)
    {
        // Each row: one label
        json jTemplateCols = JsonArray();
        json jLogLbl       = NuiLabel(NuiBind(MOR_BIND_LOG_ROWS), NuiHAlignLeft(), NuiVAlignMiddle());
        jTemplateCols = JsonArrayInsert(jTemplateCols, NuiWidth(jLogLbl, 280.0));
        json jList = NuiList(NuiRow(jTemplateCols), NuiBind(MOR_BIND_LOG_ENC), 20.0, FALSE);
        jList = NuiHeight(jList, 140.0);
        json jRow = JsonArrayInsert(JsonArray(), jList);
        jRows = JsonArrayInsert(jRows, NuiRow(jRow));
    }

    jRows = JsonArrayInsert(jRows, CreateEmptyRow(oPC, 6.0));

    // Buttons row
    {
        json jBtnSteel = NuiButton(JsonString("Zahartuj się"));
        jBtnSteel = NuiId(jBtnSteel, MOR_BTN_STEEL);
        jBtnSteel = NuiEnabled(jBtnSteel, NuiBind(MOR_BIND_STEEL_ENA));
        jBtnSteel = NuiTooltip(jBtnSteel, NuiBind(MOR_BIND_STEEL_TIP));
        jBtnSteel = NuiWidth(jBtnSteel, 130.0);
        jBtnSteel = NuiHeight(jBtnSteel, 28.0);

        json jBtnClose = NuiButton(JsonString("Zamknij"));
        jBtnClose = NuiId(jBtnClose, MOR_BTN_CLOSE);
        jBtnClose = NuiWidth(jBtnClose, 100.0);
        jBtnClose = NuiHeight(jBtnClose, 28.0);

        json jBtnRow = JsonArray();
        jBtnRow = JsonArrayInsert(jBtnRow, jBtnSteel);
        jBtnRow = JsonArrayInsert(jBtnRow, NuiSpacer());
        jBtnRow = JsonArrayInsert(jBtnRow, jBtnClose);
        jRows = JsonArrayInsert(jRows, NuiRow(jBtnRow));
    }

    // ---- Window definition ----
    json jCol  = JsonArrayInsert(JsonArray(), NuiCol(jRows));
    json jRoot = NuiWindow(
        NuiRow(jCol),
        JsonString("Morale Bojowe"),
        NuiBind(MOR_WIN_GEOM),
        JsonBool(FALSE),  // resizable
        JsonBool(FALSE),  // collapsed
        JsonBool(TRUE),   // closable
        JsonBool(FALSE),  // transparent
        JsonBool(TRUE)    // border
    );

    float fX = (1920.0 - MOR_WIN_W) / 2.0;
    float fY = (1080.0 - MOR_WIN_H) / 2.0;
    json jGeom = NuiRect(fX, fY, MOR_WIN_W, MOR_WIN_H);

    nToken = NuiCreate(oPC, jRoot, MOR_WINDOW);
    NuiSetBind(oPC, nToken, MOR_WIN_GEOM, jGeom);

    NuiSetBindScript(oPC, nToken, MOR_WIN_GEOM, MOR_EV_SCRIPT);

    MorFeedWindow(oPC, nToken);
}

// Refreshes all dynamic binds for the currently open window.
void MorFeedWindow(object oPC, int nToken)
{
    int nMorale  = MorGet(oPC);
    int nTier    = MorGetTier(nMorale);
    float fBarVal = IntToFloat(nMorale) / IntToFloat(MOR_MAX);

    // State label
    NuiSetBind(oPC, nToken, MOR_BIND_STATE_LBL,  JsonString(MorTierName(nTier)));

    // Morale number
    NuiSetBind(oPC, nToken, MOR_BIND_MORALE_NUM, JsonString(IntToString(nMorale) + " / " + IntToString(MOR_MAX)));

    // Bar value
    NuiSetBind(oPC, nToken, MOR_BIND_BAR_VAL, JsonFloat(fBarVal));

    // Debuff description
    NuiSetBind(oPC, nToken, MOR_BIND_DEBUFF_LBL, JsonString(MorTierDesc(nTier)));

    // Log
    json jLog = GetLocalJson(oPC, MOR_LVAR_LOG);
    if(JsonGetType(jLog) != JSON_TYPE_ARRAY)
        jLog = JsonArray();

    int nLogLen = JsonGetLength(jLog);
    json jLogRows = JsonArray();
    json jLogEnc  = JsonArray();
    int i;
    for(i = nLogLen - 1; i >= 0; i--)
    {
        jLogRows = JsonArrayInsert(jLogRows, JsonArrayGet(jLog, i));
        jLogEnc  = JsonArrayInsert(jLogEnc,  JsonBool(FALSE));
    }
    NuiSetBind(oPC, nToken, MOR_BIND_LOG_ROWS, jLogRows);
    NuiSetBind(oPC, nToken, MOR_BIND_LOG_ENC,  jLogEnc);

    // Steel button
    int nNow      = FloatToInt(GetGameTime() / 1000.0);  // rough seconds
    int nLastUsed = GetLocalInt(oPC, MOR_LVAR_STEEL_TIME);
    int bReady    = (nNow - nLastUsed) >= MOR_STEEL_COOLDOWN;
    NuiSetBind(oPC, nToken, MOR_BIND_STEEL_ENA, JsonBool(bReady && nMorale < MOR_MAX));

    string sTip;
    if(!bReady)
    {
        int nRemain = MOR_STEEL_COOLDOWN - (nNow - nLastUsed);
        sTip = "Zahartuj się (dostępne za ~" + IntToString(nRemain) + "s)";
    }
    else
        sTip = "Zahartuj się: koszt " + IntToString(MOR_STEEL_GOLD_COST) + " szt. złota, przywraca " + IntToString(MOR_STEEL_MORALE_GAIN) + " morale.";
    NuiSetBind(oPC, nToken, MOR_BIND_STEEL_TIP, JsonString(sTip));
}

// ----------------------------------------------------------------
// Terror trigger evaluation — called each heartbeat tick
// ----------------------------------------------------------------

// Counts enemies within radius.
int MorCountEnemiesNearby(object oPC, float fRadius)
{
    int nCount  = 0;
    object oObj = GetFirstObjectInShape(SHAPE_SPHERE, fRadius, GetLocation(oPC), FALSE, OBJECT_TYPE_CREATURE);
    while(GetIsObjectValid(oObj))
    {
        if(oObj != oPC && GetIsEnemy(oObj, oPC) && GetObjectType(oObj) == OBJECT_TYPE_CREATURE)
            nCount++;
        oObj = GetNextObjectInShape(SHAPE_SPHERE, fRadius, GetLocation(oPC), FALSE, OBJECT_TYPE_CREATURE);
    }
    return nCount;
}

// Returns TRUE if any nearby creature is undead.
int MorHasNearbyUndead(object oPC, float fRadius)
{
    object oObj = GetFirstObjectInShape(SHAPE_SPHERE, fRadius, GetLocation(oPC), FALSE, OBJECT_TYPE_CREATURE);
    while(GetIsObjectValid(oObj))
    {
        if(GetRacialType(oObj) == RACIAL_TYPE_UNDEAD && GetIsEnemy(oObj, oPC))
            return TRUE;
        oObj = GetNextObjectInShape(SHAPE_SPHERE, fRadius, GetLocation(oPC), FALSE, OBJECT_TYPE_CREATURE);
    }
    return FALSE;
}

// Per-tick fear trigger evaluation.
void MorTick(object oPC)
{
    if(!GetIsObjectValid(oPC) || !GetIsPC(oPC)) return;
    if(GetIsDead(oPC)) return;

    int nMorale  = MorGet(oPC);
    int nDrain   = 0;
    int bAnyTrig = FALSE;
    string sLogEntry = "";

    // Trigger: nearby undead
    if(MorHasNearbyUndead(oPC, 10.0))
    {
        nDrain  += MOR_DRAIN_UNDEAD;
        bAnyTrig = TRUE;
        sLogEntry = "Obecność nieumarłych...";
    }

    // Trigger: darkness (simplified via area ambient light)
    // NWN exposes no direct light API per PC; use tile light value as proxy via GetTileMainLight1Color.
    // Fallback: check if in interior area with lighting flag.
    {
        object oArea = GetArea(oPC);
        if(GetIsObjectValid(oArea))
        {
            int nDaytime = GetIsDawn() || GetIsDay();
            // Interior areas at night count as dark
            int bInterior = GetLocalInt(oArea, "AREA_IS_INTERIOR"); // server sets this
            if(!nDaytime && bInterior)
            {
                nDrain  += MOR_DRAIN_DARK;
                bAnyTrig = TRUE;
                if(sLogEntry == "") sLogEntry = "Ciemność zagęszcza się...";
            }
        }
    }

    // Trigger: PC below 25% HP
    int nHP    = GetCurrentHitPoints(oPC);
    int nMaxHP = GetMaxHitPoints(oPC);
    if(nMaxHP > 0 && nHP <= nMaxHP / 4)
    {
        nDrain  += MOR_DRAIN_LOWHP;
        bAnyTrig = TRUE;
        if(sLogEntry == "") sLogEntry = "Rany są poważne...";
    }

    // Trigger: outnumbered 3:1 in combat
    if(GetIsInCombat(oPC))
    {
        int nEnemies = MorCountEnemiesNearby(oPC, 8.0);
        if(nEnemies >= 3)
        {
            nDrain  += MOR_DRAIN_OUTNUMBERED;
            bAnyTrig = TRUE;
            if(sLogEntry == "") sLogEntry = "Wróg ze wszystkich stron...";
        }
    }

    // Passive recovery when no triggers
    if(!bAnyTrig && nDrain == 0)
    {
        if(nMorale < MOR_MAX)
        {
            nMorale += MOR_RESTORE_PASSIVE;
            MorSet(oPC, nMorale);
        }
    }
    else
    {
        nMorale -= nDrain;
        MorSet(oPC, nMorale);
        if(sLogEntry != "")
            MorAddLog(oPC, sLogEntry);
    }

    // Apply tier-appropriate penalties
    int nOldPenalty = GetLocalInt(oPC, MOR_LVAR_PENALTY);
    int nNewTier    = MorGetTier(nMorale);
    if(nNewTier != nOldPenalty)
    {
        MorApplyPenalties(oPC);
        SetLocalInt(oPC, MOR_LVAR_PENALTY, nNewTier);
        if(nNewTier > nOldPenalty)
        {
            string sTierName = MorTierName(nNewTier);
            FloatingTextStringOnCreature("*" + sTierName + " — morale spada*", oPC, FALSE);
            MorAddLog(oPC, "Stan zmieniony: " + sTierName);
        }
        else
        {
            MorAddLog(oPC, "Morale odbudowane: " + MorTierName(nNewTier));
        }
    }

    // Flee impulse at panicked / broken tiers
    if(nNewTier >= 3 && GetIsInCombat(oPC))
    {
        int nNow      = FloatToInt(GetGameTime() / 1000.0);
        int nLastFlee = GetLocalInt(oPC, MOR_LVAR_FLEE_SENT);
        // Flee impulse at most once per 30 seconds
        if((nNow - nLastFlee) >= 30)
        {
            SetLocalInt(oPC, MOR_LVAR_FLEE_SENT, nNow);
            // Apply daze to represent panic stun
            effect ePanic = TagEffect(EffectDazed(), MOR_EFFECT_TAG + "_FLEE");
            ApplyEffectToObject(DURATION_TYPE_TEMPORARY, ePanic, oPC, 3.0);
            SendMessageToPC(oPC, "*Ogarnia cię paraliżujący strach — nogi odmawiają posłuszeństwa!*");
            MorAddLog(oPC, "Atak paniki!");
        }
    }

    // Refresh open window
    int nToken = NuiFindWindow(oPC, MOR_WINDOW);
    if(nToken != 0)
        MorFeedWindow(oPC, nToken);

    // Reschedule heartbeat
    DelayCommand(MOR_HB_DELAY, MorTick(oPC));
}

// ----------------------------------------------------------------
// Rest bonus
// ----------------------------------------------------------------

void MorRestoreOnRest(object oPC)
{
    int nMorale = MorGet(oPC);
    int nGain   = 20;
    MorSet(oPC, nMorale + nGain);
    MorApplyPenalties(oPC);
    SetLocalInt(oPC, MOR_LVAR_PENALTY, MorGetTier(MorGet(oPC)));
    MorAddLog(oPC, "Odpoczynek wzmocnił ducha +" + IntToString(nGain));
    SendMessageToPC(oPC, "[Morale] Odpoczynek przywrócił ci " + IntToString(nGain) + " punktów morale.");
    int nToken = NuiFindWindow(oPC, MOR_WINDOW);
    if(nToken != 0)
        MorFeedWindow(oPC, nToken);
}

// ----------------------------------------------------------------
// "Zahartuj się" — voluntary morale boost at gold cost
// ----------------------------------------------------------------

void MorDoSteel(object oPC)
{
    int nGold = GetGold(oPC);
    if(nGold < MOR_STEEL_GOLD_COST)
    {
        SendMessageToPC(oPC, "[Morale] Nie stać cię na ten gest odwagi (brakuje złota).");
        return;
    }

    int nNow      = FloatToInt(GetGameTime() / 1000.0);
    int nLastUsed = GetLocalInt(oPC, MOR_LVAR_STEEL_TIME);
    if((nNow - nLastUsed) < MOR_STEEL_COOLDOWN)
    {
        SendMessageToPC(oPC, "[Morale] Musi minąć więcej czasu, zanim znów sięgniesz po odwagę.");
        return;
    }

    AssignCommand(oPC, TakeGoldFromCreature(MOR_STEEL_GOLD_COST, oPC, TRUE));
    SetLocalInt(oPC, MOR_LVAR_STEEL_TIME, nNow);

    int nMorale = MorGet(oPC);
    MorSet(oPC, nMorale + MOR_STEEL_MORALE_GAIN);
    MorApplyPenalties(oPC);
    SetLocalInt(oPC, MOR_LVAR_PENALTY, MorGetTier(MorGet(oPC)));
    MorAddLog(oPC, "Przełknięcie strachu +" + IntToString(MOR_STEEL_MORALE_GAIN));
    SendMessageToPC(oPC, "[Morale] Zaciskasz zęby i łykasz strach. Morale wzrosło o " + IntToString(MOR_STEEL_MORALE_GAIN) + ".");
    FloatingTextStringOnCreature("*Twarda wola — strach ustępuje*", oPC, FALSE);

    int nToken = NuiFindWindow(oPC, MOR_WINDOW);
    if(nToken != 0)
        MorFeedWindow(oPC, nToken);
}

// ----------------------------------------------------------------
// Initialization per PC
// ----------------------------------------------------------------

void MorInitPC(object oPC)
{
    // Load from DB; seed at full morale on first visit
    int nMorale = MorLoad(oPC);
    SetLocalInt(oPC, "MOR_VALUE", nMorale);
    SetLocalInt(oPC, MOR_LVAR_PENALTY, 0);
    MorRemovePenalties(oPC);
    MorApplyPenalties(oPC);

    // Start personal heartbeat if not already running
    if(!GetLocalInt(oPC, MOR_LVAR_HB_RUNNING))
    {
        SetLocalInt(oPC, MOR_LVAR_HB_RUNNING, TRUE);
        DelayCommand(MOR_HB_DELAY, MorTick(oPC));
    }
}

// ----------------------------------------------------------------
// Module-level init
// ----------------------------------------------------------------

void MorOnModuleLoad()
{
    MorCreateTables();
}
