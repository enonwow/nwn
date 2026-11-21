// lib_wyrd.nss — Wyrd System: core logic, NUI builders, and feed functions.
// Include this file in: OnModuleLoad, OnClientEnter, OnModuleHeartbeat,
// OnPlayerDeath, OnNUIEvent (via lib_wyrd_ev), and test/ritual placeables.
#include "lib_wyrd_def"

// ============================================================
// Wyrd value helpers
// ============================================================

int WyrdGet(object oPC)
{
    return GetLocalInt(oPC, WYRD_LVAR_WYRD);
}

void WyrdSet(object oPC, int nVal)
{
    if(nVal < 0)          nVal = 0;
    if(nVal > WYRD_MAX)   nVal = WYRD_MAX;
    SetLocalInt(oPC, WYRD_LVAR_WYRD, nVal);
}

// ============================================================
// Boon active state
// ============================================================

int WyrdBoonIsActive(object oPC, int nId)
{
    int nExpiry = GetLocalInt(oPC, WYRD_LVAR_BOON + IntToString(nId));
    if(nExpiry <= 0) return FALSE;
    return (WyrdGameSec() < nExpiry) ? TRUE : FALSE;
}

// ============================================================
// Persist current PC state
// ============================================================

void WyrdDbSync(object oPC)
{
    WyrdDbUpsert(
        GetObjectUUID(oPC),
        GetName(oPC),
        WyrdGet(oPC),
        GetLocalInt(oPC, WYRD_LVAR_SPENT),
        GetLocalInt(oPC, WYRD_LVAR_LAST_DECAY));
}

// ============================================================
// WyrdGrant — add wyrd, notify, update UI
// ============================================================

void WyrdGrant(object oPC, int nAmount, string sReason)
{
    int nOld = WyrdGet(oPC);
    int nNew = nOld + nAmount;
    if(nNew > WYRD_MAX) nNew = WYRD_MAX;
    WyrdSet(oPC, nNew);
    WyrdDbSync(oPC);

    FloatingTextStringOnCreature("+" + IntToString(nAmount) + " Wyrd", oPC, FALSE);
    SendMessageToPC(oPC, "[Wyrd] +" + IntToString(nAmount) + " wyrd — " + sReason);

    // Warn at spirit threshold crossing
    if(nOld < WYRD_SPIRIT_THRESHOLD && nNew >= WYRD_SPIRIT_THRESHOLD)
    {
        FloatingTextStringOnCreature(
            "Duchy Przeznaczenia czuja twoj wyrd...", oPC, FALSE);
        SendMessageToPC(oPC,
            "[Wyrd] Nagromadzenie wyrdu jest niebezpieczne. Duchy zaczynaja krazic.");
    }
    if(nNew >= WYRD_MAX)
    {
        FloatingTextStringOnCreature(
            "NEMEZIS ZMIERZA KU TOBIE!", oPC, FALSE);
        SendMessageToPC(oPC,
            "[Wyrd] Wyrd osiagnal maksimum. Nemezis przyjdzie po ciebie.");
    }

    int nToken = NuiFindWindow(oPC, WYRD_WINDOW);
    if(nToken != 0)
        WyrdFeedWindow(oPC, nToken);
}

// Deduct wyrd (private, called from WyrdBuyBoon)
void WyrdSpend(object oPC, int nAmount)
{
    int nNew   = WyrdGet(oPC) - nAmount;
    if(nNew < 0) nNew = 0;
    WyrdSet(oPC, nNew);
    int nSpent = GetLocalInt(oPC, WYRD_LVAR_SPENT) + nAmount;
    SetLocalInt(oPC, WYRD_LVAR_SPENT, nSpent);
    WyrdDbSync(oPC);
}

// ============================================================
// Apply game effect for a boon
// ============================================================

void WyrdBoonApplyEffect(object oPC, int nId)
{
    float fDur = WyrdBoonDurSec(nId);
    effect eApp;

    switch(nId)
    {
        case WYRD_BOON_SAVES:
            eApp = EffectSavingThrowIncrease(SAVING_THROW_ALL, 2,
                                             SAVING_THROW_TYPE_ALL);
            break;

        case WYRD_BOON_ATTACK:
            eApp = EffectAttackBonus(1);
            break;

        case WYRD_BOON_CONCEAL:
            eApp = EffectConcealment(15, MISS_CHANCE_TYPE_NORMAL);
            break;

        case WYRD_BOON_SKILLS:
            // Link the most useful skills; NWN EE has no single SKILL_ALL_SKILLS constant.
            eApp = EffectLinkEffects(
                EffectSkillIncrease(SKILL_CONCENTRATION, 10),
                EffectLinkEffects(
                    EffectSkillIncrease(SKILL_SPOT, 10),
                    EffectLinkEffects(
                        EffectSkillIncrease(SKILL_LISTEN, 10),
                        EffectLinkEffects(
                            EffectSkillIncrease(SKILL_LORE, 10),
                            EffectLinkEffects(
                                EffectSkillIncrease(SKILL_SPELLCRAFT, 10),
                                EffectLinkEffects(
                                    EffectSkillIncrease(SKILL_HIDE, 10),
                                    EffectSkillIncrease(SKILL_DISCIPLINE, 10)))))));
            break;

        case WYRD_BOON_SEEING:
            eApp = EffectTrueSeeing();
            break;

        case WYRD_BOON_CHEAT_DEATH:
            // No mechanical effect here; consumed in sys_on_pdeath.nss.
            return;

        default:
            return;
    }

    ApplyEffectToObject(DURATION_TYPE_TEMPORARY, ExtraordinaryEffect(eApp), oPC, fDur);
}

// ============================================================
// WyrdBuyBoon — validate, deduct, apply
// ============================================================

void WyrdBuyBoon(object oPC, int nId)
{
    if(nId < 1 || nId > WYRD_BOON_COUNT) return;

    int nCost = WyrdBoonCost(nId);
    if(WyrdGet(oPC) < nCost)
    {
        SendMessageToPC(oPC, "[Wyrd] Niewystarczajacy wyrd.");
        return;
    }
    if(WyrdBoonIsActive(oPC, nId))
    {
        SendMessageToPC(oPC, "[Wyrd] Ta laska jest juz aktywna.");
        return;
    }

    WyrdSpend(oPC, nCost);

    // Store expiry timestamp
    int nDurSec = WyrdBoonDurMin(nId) * 60;
    SetLocalInt(oPC, WYRD_LVAR_BOON + IntToString(nId),
                WyrdGameSec() + nDurSec);

    WyrdBoonApplyEffect(oPC, nId);

    string sName = WyrdBoonName(nId);
    FloatingTextStringOnCreature("Laska: " + sName, oPC, FALSE);
    SendMessageToPC(oPC,
        "[Wyrd] Laska aktywna: " + sName
        + " przez " + WyrdBoonDurLabel(nId) + ".");

    int nToken = NuiFindWindow(oPC, WYRD_WINDOW);
    if(nToken != 0)
        WyrdFeedWindow(oPC, nToken);
}

// ============================================================
// Decay tick (called from module heartbeat)
// ============================================================

void WyrdDecayTick(object oPC)
{
    int nNow  = WyrdGameSec();
    int nLast = GetLocalInt(oPC, WYRD_LVAR_LAST_DECAY);
    if(nNow - nLast < WYRD_DECAY_INTERVAL) return;

    SetLocalInt(oPC, WYRD_LVAR_LAST_DECAY, nNow);

    int nCur = WyrdGet(oPC);
    if(nCur <= 0) return;

    WyrdSet(oPC, nCur - 1);
    WyrdDbSync(oPC);

    int nToken = NuiFindWindow(oPC, WYRD_WINDOW);
    if(nToken != 0)
        WyrdFeedWindow(oPC, nToken);
}

// ============================================================
// Spirit spawning (called from heartbeat when wyrd >= threshold)
// ============================================================

void WyrdCheckSpirits(object oPC)
{
    int nWyrd = WyrdGet(oPC);
    if(nWyrd < WYRD_SPIRIT_THRESHOLD) return;

    // ~10% chance per heartbeat call (every 6 real seconds = ~60 beats/min)
    if(d20(1) < 18) return;

    // Choose spirit power by wyrd level
    string sResRef = (nWyrd >= WYRD_MAX) ? "nw_demogorg01" : "nw_shadow002";
    string sLabel  = (nWyrd >= WYRD_MAX) ? "Nemezis Przeznaczenia" : "Duch Przeznaczenia";

    location lSpawn = GetLocation(oPC);
    object oSpirit = CreateObject(OBJECT_TYPE_CREATURE, sResRef, lSpawn, TRUE, sLabel);
    if(!GetIsObjectValid(oSpirit)) return;

    SetLocalString(oSpirit, "WYRD_HUNTER_UUID", GetObjectUUID(oPC));
    AssignCommand(oSpirit, ActionAttack(oPC));

    FloatingTextStringOnCreature(sLabel + " materializuje sie!", oPC, FALSE);
    SendMessageToPC(oPC,
        "[Wyrd] Twoj wyrd przyciagnal " + sLabel + "! Wydaj wyrd lub pokonaj go.");
}

// ============================================================
// Handle the Cheat Death boon in OnPlayerDeath
// ============================================================

// Returns TRUE if the boon was active and consumed (PC should be resurrected).
int WyrdCheckCheatDeath(object oPC)
{
    if(!WyrdBoonIsActive(oPC, WYRD_BOON_CHEAT_DEATH)) return FALSE;

    // Consume the boon
    DeleteLocalInt(oPC, WYRD_LVAR_BOON + IntToString(WYRD_BOON_CHEAT_DEATH));

    FloatingTextStringOnCreature(
        "Przeznaczenie odsuwa smierc!", oPC, FALSE);
    SendMessageToPC(oPC,
        "[Wyrd] Ocalenie pochlonieło twoja smierc. Laska została skonsumowana.");

    // Resurrection is delayed; engine may be mid-death-processing.
    DelayCommand(1.0, ApplyEffectToObject(DURATION_TYPE_INSTANT,
                                          EffectResurrection(), oPC));
    DelayCommand(1.5, ApplyEffectToObject(DURATION_TYPE_INSTANT,
                                          EffectHeal(1), oPC));
    return TRUE;
}

// ============================================================
// NUI: status flavor text and color
// ============================================================

string WyrdStatusText(int nWyrd)
{
    if(nWyrd <= 0)   return "Nic przeznaczenia drzy ledwie wyczuwalnie.";
    if(nWyrd <= 20)  return "Palce losu muskaja twoje ramie.";
    if(nWyrd <= 40)  return "Przeznaczenie dostrzega cie w tlumie.";
    if(nWyrd <= 60)  return "Wyrd pulsuje w twoich zylach jak trucizna.";
    if(nWyrd <= 74)  return "Ciemne moce zacierajа dlonie — zbliżasz sie do krawedzi.";
    if(nWyrd <= 89)  return "UWAGA: Duchy Przeznaczenia kraza wokol ciebie...";
    return               "NIEBEZPIECZENSTWO: Nemezis zmierza ku tobie.";
}

json WyrdStatusColor(int nWyrd)
{
    if(nWyrd <= 40) return NuiColor(200, 200, 200, 255);
    if(nWyrd <= 74) return NuiColor(210, 160, 50, 255);
    if(nWyrd <= 89) return NuiColor(220, 80, 30, 255);
    return              NuiColor(200, 30, 30, 255);
}

// ============================================================
// NUI: build boons content (list of 6 rows)
// ============================================================

json WyrdBuildBoonsView(object oPC)
{
    float fBtnW  = 80.0;
    float fCostW = 70.0;
    float fDurW  = 50.0;
    float fRowH  = 34.0;
    int   nWyrd  = WyrdGet(oPC);

    json jRows = JsonArray();

    // Column header row
    json jHdrCols = JsonArray();
    json jHdrName = NuiLabel(JsonString("Laska"),
                             JsonInt(NUI_HALIGN_LEFT), JsonInt(NUI_VALIGN_MIDDLE));
    json jHdrCost = NuiLabel(JsonString("Koszt"),
                             JsonInt(NUI_HALIGN_CENTER), JsonInt(NUI_VALIGN_MIDDLE));
    jHdrCost = NuiWidth(jHdrCost, fCostW);
    json jHdrDur  = NuiLabel(JsonString("Czas"),
                             JsonInt(NUI_HALIGN_CENTER), JsonInt(NUI_VALIGN_MIDDLE));
    jHdrDur = NuiWidth(jHdrDur, fDurW);
    json jHdrBtn  = NuiLabel(JsonString(""),
                             JsonInt(NUI_HALIGN_CENTER), JsonInt(NUI_VALIGN_MIDDLE));
    jHdrBtn = NuiWidth(jHdrBtn, fBtnW);
    jHdrCols = JsonArrayInsert(jHdrCols, jHdrName);
    jHdrCols = JsonArrayInsert(jHdrCols, jHdrCost);
    jHdrCols = JsonArrayInsert(jHdrCols, jHdrDur);
    jHdrCols = JsonArrayInsert(jHdrCols, jHdrBtn);
    json jHdrRow = NuiHeight(NuiRow(jHdrCols), fRowH * 0.7);
    jRows = JsonArrayInsert(jRows, jHdrRow);

    int i;
    for(i = 1; i <= WYRD_BOON_COUNT; i++)
    {
        int bActive = WyrdBoonIsActive(oPC, i);
        int nCost   = WyrdBoonCost(i);
        int bEna    = (!bActive) && (nWyrd >= nCost);

        string sBtnText = bActive ? "Aktywna" : "Kup";
        string sBind    = IntToString(i);

        // Name label with tooltip containing full description
        json jName = NuiLabel(JsonString(WyrdBoonName(i)),
                              JsonInt(NUI_HALIGN_LEFT), JsonInt(NUI_VALIGN_MIDDLE));
        jName = NuiTooltip(jName, JsonString(WyrdBoonDesc(i)));

        // Cost label
        json jCost = NuiLabel(JsonString(IntToString(nCost) + " Wy"),
                              JsonInt(NUI_HALIGN_CENTER), JsonInt(NUI_VALIGN_MIDDLE));
        jCost = NuiWidth(jCost, fCostW);

        // Duration label
        json jDur = NuiLabel(JsonString(WyrdBoonDurLabel(i)),
                             JsonInt(NUI_HALIGN_CENTER), JsonInt(NUI_VALIGN_MIDDLE));
        jDur = NuiWidth(jDur, fDurW);

        // Buy button — text and enabled state are bound for live refresh
        json jBtn = NuiButton(NuiBind(WYRD_BIND_BOON_BTN + sBind));
        jBtn = NuiId(jBtn, WYRD_BTN_BUY + sBind);
        jBtn = NuiEnabled(jBtn, NuiBind(WYRD_BIND_BOON_ENA + sBind));
        jBtn = NuiWidth(jBtn, fBtnW);
        jBtn = NuiTooltip(jBtn, JsonString(WyrdBoonDesc(i)));

        json jRowCols = JsonArray();
        jRowCols = JsonArrayInsert(jRowCols, jName);
        jRowCols = JsonArrayInsert(jRowCols, jCost);
        jRowCols = JsonArrayInsert(jRowCols, jDur);
        jRowCols = JsonArrayInsert(jRowCols, jBtn);

        jRows = JsonArrayInsert(jRows, NuiHeight(NuiRow(jRowCols), fRowH));
    }

    // Flavor note at the bottom
    json jNote = NuiLabel(
        JsonString("Powyzej " + IntToString(WYRD_SPIRIT_THRESHOLD)
                   + " wyrdu duchy zaczynaja sie materializowac."),
        JsonInt(NUI_HALIGN_LEFT), JsonInt(NUI_VALIGN_MIDDLE));
    jNote = NuiStyleForegroundColor(jNote, NuiColor(160, 100, 60, 255));
    jRows = JsonArrayInsert(jRows, NuiHeight(NuiRow(
        JsonArrayInsert(JsonArray(), jNote)), 28.0));

    return NuiCol(jRows);
}

// ============================================================
// NUI: build ledger (top spenders)
// ============================================================

json WyrdBuildLedgerView(object oPC)
{
    json jTop = WyrdDbTopSpenders(12);
    int  nCnt = JsonGetLength(jTop);

    json jRows = JsonArray();

    // Header
    json jHdr = JsonArray();
    json jHn  = NuiLabel(JsonString("Postac"),
                         JsonInt(NUI_HALIGN_LEFT), JsonInt(NUI_VALIGN_MIDDLE));
    json jHs  = NuiLabel(JsonString("Wydano"),
                         JsonInt(NUI_HALIGN_RIGHT), JsonInt(NUI_VALIGN_MIDDLE));
    jHs = NuiWidth(jHs, 80.0);
    jHdr = JsonArrayInsert(jHdr, jHn);
    jHdr = JsonArrayInsert(jHdr, jHs);
    jRows = JsonArrayInsert(jRows, NuiHeight(NuiRow(jHdr), 28.0));

    if(nCnt == 0)
    {
        json jEmpty = NuiLabel(
            JsonString("Nikt jeszcze nie wydal wyrdu. Los obserwuje."),
            JsonInt(NUI_HALIGN_CENTER), JsonInt(NUI_VALIGN_MIDDLE));
        jEmpty = NuiStyleForegroundColor(jEmpty, NuiColor(160, 120, 80, 255));
        jRows = JsonArrayInsert(jRows, NuiHeight(NuiRow(
            JsonArrayInsert(JsonArray(), jEmpty)), 32.0));
    }

    int i;
    for(i = 0; i < nCnt; i++)
    {
        json jEntry = JsonArrayGet(jTop, i);
        string sName  = JsonGetString(JsonObjectGet(jEntry, "n"));
        int    nSpent = JsonGetInt(JsonObjectGet(jEntry, "s"));

        json jRow = JsonArray();
        json jN   = NuiLabel(JsonString(sName),
                             JsonInt(NUI_HALIGN_LEFT), JsonInt(NUI_VALIGN_MIDDLE));
        json jS   = NuiLabel(JsonString(IntToString(nSpent) + " Wy"),
                             JsonInt(NUI_HALIGN_RIGHT), JsonInt(NUI_VALIGN_MIDDLE));
        jS = NuiWidth(jS, 80.0);
        jRow = JsonArrayInsert(jRow, jN);
        jRow = JsonArrayInsert(jRow, jS);
        jRows = JsonArrayInsert(jRows, NuiHeight(NuiRow(jRow), 28.0));
    }

    return NuiGroup(NuiCol(jRows), JsonBool(TRUE), NUI_SCROLLBARS_Y);
}

// ============================================================
// WyrdSwapView — rebuild the content group with the chosen view
// ============================================================

void WyrdSwapView(object oPC, int nToken, int nView)
{
    SetLocalInt(oPC, WYRD_LVAR_VIEW, nView);
    json jContent = (nView == 1)
        ? WyrdBuildLedgerView(oPC)
        : WyrdBuildBoonsView(oPC);
    NuiSetGroupLayout(oPC, nToken, WYRD_GRP_CONTENT, jContent);

    // Re-feed binds after layout swap
    WyrdFeedWindow(oPC, nToken);
}

// ============================================================
// WyrdFeedWindow — update all dynamic binds in the open window
// ============================================================

void WyrdFeedWindow(object oPC, int nToken)
{
    int nWyrd = WyrdGet(oPC);

    // Meter
    NuiSetBind(oPC, nToken, WYRD_BIND_METER,
               JsonFloat(IntToFloat(nWyrd) / IntToFloat(WYRD_MAX)));
    NuiSetBind(oPC, nToken, WYRD_BIND_METER_LBL,
               JsonString(IntToString(nWyrd) + " / " + IntToString(WYRD_MAX)));
    NuiSetBind(oPC, nToken, WYRD_BIND_STATUS_LBL,
               JsonString(WyrdStatusText(nWyrd)));
    NuiSetBind(oPC, nToken, WYRD_BIND_STATUS_COL,
               WyrdStatusColor(nWyrd));

    // Per-boon button states
    int i;
    for(i = 1; i <= WYRD_BOON_COUNT; i++)
    {
        int bActive = WyrdBoonIsActive(oPC, i);
        int bEna    = (!bActive) && (nWyrd >= WyrdBoonCost(i));
        string sBind = IntToString(i);

        NuiSetBind(oPC, nToken, WYRD_BIND_BOON_BTN + sBind,
                   JsonString(bActive ? "Aktywna" : "Kup"));
        NuiSetBind(oPC, nToken, WYRD_BIND_BOON_ENA + sBind,
                   JsonBool(bEna));
    }
}

// ============================================================
// WyrdOpenWindow — create (or raise) the main Wyrd UI
// ============================================================

void WyrdOpenWindow(object oPC)
{
    // Destroy existing instance so geometry & binds are clean
    int nOld = NuiFindWindow(oPC, WYRD_WINDOW);
    if(nOld != 0) NuiDestroy(oPC, nOld);

    int nWyrd = WyrdGet(oPC);

    // ---- Top bar: tab buttons + close ----
    float fBtnH  = 30.0;
    float fBtnW  = 100.0;

    json jTabBoons = NuiButton(JsonString("Laski"));
    jTabBoons = NuiId(jTabBoons, WYRD_BTN_TAB_BOONS);
    jTabBoons = NuiWidth(jTabBoons, fBtnW);
    jTabBoons = NuiHeight(jTabBoons, fBtnH);

    json jTabLedger = NuiButton(JsonString("Kronika"));
    jTabLedger = NuiId(jTabLedger, WYRD_BTN_TAB_LEDGER);
    jTabLedger = NuiWidth(jTabLedger, fBtnW);
    jTabLedger = NuiHeight(jTabLedger, fBtnH);

    json jClose = NuiButton(JsonString("X"));
    jClose = NuiId(jClose, WYRD_BTN_CLOSE);
    jClose = NuiWidth(jClose, 28.0);
    jClose = NuiHeight(jClose, fBtnH);

    json jTabRowCols = JsonArray();
    jTabRowCols = JsonArrayInsert(jTabRowCols, jTabBoons);
    jTabRowCols = JsonArrayInsert(jTabRowCols, jTabLedger);
    jTabRowCols = JsonArrayInsert(jTabRowCols, NuiSpacer());
    jTabRowCols = JsonArrayInsert(jTabRowCols, jClose);

    // ---- Meter row ----
    json jProgress = NuiProgressBar(NuiBind(WYRD_BIND_METER));
    jProgress = NuiHeight(jProgress, 20.0);

    json jMeterLbl = NuiLabel(NuiBind(WYRD_BIND_METER_LBL),
                               JsonInt(NUI_HALIGN_CENTER), JsonInt(NUI_VALIGN_MIDDLE));
    jMeterLbl = NuiHeight(jMeterLbl, 22.0);

    json jStatusLbl = NuiLabel(NuiBind(WYRD_BIND_STATUS_LBL),
                                JsonInt(NUI_HALIGN_CENTER), JsonInt(NUI_VALIGN_MIDDLE));
    jStatusLbl = NuiStyleForegroundColor(jStatusLbl, NuiBind(WYRD_BIND_STATUS_COL));
    jStatusLbl = NuiHeight(jStatusLbl, 22.0);

    // ---- Content group (swappable) ----
    int nView = GetLocalInt(oPC, WYRD_LVAR_VIEW);
    json jInitContent = (nView == 1)
        ? WyrdBuildLedgerView(oPC)
        : WyrdBuildBoonsView(oPC);

    json jContentGroup = NuiGroup(jInitContent, JsonBool(FALSE), NUI_SCROLLBARS_NONE);
    jContentGroup = NuiId(jContentGroup, WYRD_GRP_CONTENT);

    // ---- Assemble root layout ----
    json jRoot = JsonArray();
    jRoot = JsonArrayInsert(jRoot, NuiHeight(NuiRow(jTabRowCols), fBtnH + 4.0));
    jRoot = JsonArrayInsert(jRoot, NuiHeight(NuiRow(
        JsonArrayInsert(JsonArray(), jProgress)), 22.0));
    jRoot = JsonArrayInsert(jRoot, NuiHeight(NuiRow(
        JsonArrayInsert(JsonArray(), jMeterLbl)), 24.0));
    jRoot = JsonArrayInsert(jRoot, NuiHeight(NuiRow(
        JsonArrayInsert(JsonArray(), jStatusLbl)), 24.0));
    jRoot = JsonArrayInsert(jRoot, NuiRow(
        JsonArrayInsert(JsonArray(), jContentGroup)));

    float fW = GetNuiScaleDimension(oPC, WYRD_W, 1.5);
    float fH = GetNuiScaleDimension(oPC, WYRD_H, 1.5);

    json jWindow = NuiWindow(
        NuiCol(jRoot),
        JsonString("Krosno Przeznaczenia"),
        NuiBind(WYRD_WIN_GEOM),
        JsonBool(FALSE),   // resizable
        JsonBool(FALSE),   // collapsed
        JsonBool(TRUE),    // closable
        JsonBool(FALSE),   // transparent
        JsonBool(TRUE)     // border
    );

    int nToken = NuiCreate(oPC, jWindow, WYRD_WINDOW);
    if(nToken == 0) return;

    NuiSetBind(oPC, nToken, WYRD_WIN_GEOM, NuiRect(-1.0, -1.0, fW, fH));

    WyrdFeedWindow(oPC, nToken);
}
