// lib_chaos.nss — NUI layout, feed functions, surge table, and gameplay logic
// for the Chaos Surge system.

#include "lib_chaos_def"

// ── DB wrappers (write/read PC local vars ↔ SQL) ─────────────────────────────

void ChaosSaveState(object oPC)
{
    int nCP    = GetLocalInt (oPC, CHAOS_LVAR_CP);
    int nTotal = GetLocalInt (oPC, CHAOS_LVAR_TOTAL);
    json jLog  = GetLocalJson(oPC, CHAOS_LVAR_LOG);
    if(JsonGetType(jLog) != JSON_TYPE_ARRAY)
        jLog = JsonArray();

    ChaosSave(GetObjectUUID(oPC), nCP, nTotal, JsonDump(jLog));
}

void ChaosLoadState(object oPC)
{
    json jData = ChaosLoad(GetObjectUUID(oPC));
    if(JsonGetType(jData) == JSON_TYPE_NULL)
    {
        SetLocalInt (oPC, CHAOS_LVAR_CP,    0);
        SetLocalInt (oPC, CHAOS_LVAR_TOTAL, 0);
        SetLocalJson(oPC, CHAOS_LVAR_LOG,   JsonArray());
        return;
    }

    SetLocalInt(oPC, CHAOS_LVAR_CP,    JsonGetInt(JsonObjectGet(jData, "cp")));
    SetLocalInt(oPC, CHAOS_LVAR_TOTAL, JsonGetInt(JsonObjectGet(jData, "total")));

    json jLog = JsonParse(JsonGetString(JsonObjectGet(jData, "log")));
    SetLocalJson(oPC, CHAOS_LVAR_LOG,
        JsonGetType(jLog) == JSON_TYPE_ARRAY ? jLog : JsonArray());
}

// ── CP accessors ──────────────────────────────────────────────────────────────

int ChaosGetCP(object oPC)
{
    return GetLocalInt(oPC, CHAOS_LVAR_CP);
}

void ChaosSetCP(object oPC, int nNew)
{
    if(nNew < 0)         nNew = 0;
    if(nNew > CHAOS_MAX) nNew = CHAOS_MAX;
    SetLocalInt(oPC, CHAOS_LVAR_CP, nNew);
}

// Adds nAmt to CP, warns on threshold crossing, and may trigger passive surge.
// Returns TRUE if a surge was triggered automatically.
int ChaosAddCP(object oPC, int nAmt)
{
    int nOld = ChaosGetCP(oPC);
    ChaosSetCP(oPC, nOld + nAmt);
    int nNew = ChaosGetCP(oPC);

    if(nNew >= CHAOS_THRESHOLD && nOld < CHAOS_THRESHOLD)
    {
        FloatingTextStringOnCreature("Pulsacja Nicości... narasta!", oPC, FALSE);
        SendMessageToPC(oPC,
            "[Chaos] Próg przekroczony — magia jest niestabilna! "
            "Chaos: " + IntToString(nNew) + "/" + IntToString(CHAOS_MAX) + ".");
    }

    // In the surge zone: probability = (CP - threshold) percent
    if(nNew >= CHAOS_THRESHOLD)
    {
        int nChance = nNew - CHAOS_THRESHOLD;
        if(Random(100) < nChance)
        {
            ChaosRollSurge(oPC);
            return TRUE;
        }
    }
    return FALSE;
}

// ── Status / colour helpers ───────────────────────────────────────────────────

string ChaosGetStatusLabel(int nCP)
{
    if(nCP < 30)  return "Spokój";
    if(nCP < 60)  return "Wzburzenie";
    if(nCP < 85)  return "Kryzys";
    return "APOKALIPSA";
}

json ChaosGetStatusColor(int nCP)
{
    if(nCP < 30)  return NuiColor(100, 200,  80);
    if(nCP < 60)  return NuiColor(220, 200,  60);
    if(nCP < 85)  return NuiColor(220, 120,  40);
    return NuiColor(220, 50, 50);
}

json ChaosGetMeterColor(int nCP)
{
    if(nCP < 30)  return NuiColor(70,  170,  60);
    if(nCP < 60)  return NuiColor(190, 170,  40);
    if(nCP < 85)  return NuiColor(190,  90,  25);
    return NuiColor(190, 30, 30);
}

// ── Surge table helpers ───────────────────────────────────────────────────────

// Category: 0=harmful, 1=mixed, 2=beneficial  (used for log colouring)
int ChaosGetSurgeCategory(int nRoll)
{
    switch(nRoll)
    {
        case  1: return 0;
        case  2: return 2;
        case  3: return 2;
        case  4: return 0;
        case  5: return 2;
        case  6: return 0;
        case  7: return 1;
        case  8: return 2;
        case  9: return 2;
        case 10: return 2;
        case 11: return 0;
        case 12: return 0;
        case 13: return 0;
        case 14: return 0;
        case 15: return 1;
        case 16: return 2;
        case 17: return 0;
        case 18: return 0;
        case 19: return 1;
        case 20: return 0;
    }
    return 1;
}

json ChaosGetSurgeColor(int nRoll)
{
    int nCat = ChaosGetSurgeCategory(nRoll);
    if(nCat == 0) return NuiColor(200,  60,  60);
    if(nCat == 1) return NuiColor(200, 160,  50);
    return NuiColor(70, 170, 70);
}

string ChaosGetSurgeName(int nRoll)
{
    switch(nRoll)
    {
        case  1: return "Płomień Chaosu";
        case  2: return "Oka Burzy";
        case  3: return "Pośpiech Szaleńca";
        case  4: return "Klątwa Milczenia";
        case  5: return "Lot Ducha";
        case  6: return "Tarza Czasu";
        case  7: return "Zgrozę Wyzwól";
        case  8: return "Apogeum Mocy";
        case  9: return "Osłona Absolutna";
        case 10: return "Dar Opatrzności";
        case 11: return "Skruch";
        case 12: return "Wezwanie Cienia";
        case 13: return "Gwałtowny Odrzut";
        case 14: return "Ślepota Otchłani";
        case 15: return "Przemiana Bestii";
        case 16: return "Złoty Deszcz";
        case 17: return "Wir Chaosu";
        case 18: return "Paraliż Woli";
        case 19: return "Szał Bitewny";
        case 20: return "Apokalipsa";
    }
    return "Nieznana Pulsacja";
}

// ── Log management ────────────────────────────────────────────────────────────

void ChaosAppendLog(object oPC, int nRoll)
{
    json jEntry = JsonObject();
    jEntry = JsonObjectSet(jEntry, "name", JsonString(ChaosGetSurgeName(nRoll)));
    jEntry = JsonObjectSet(jEntry, "roll", JsonInt(nRoll));
    jEntry = JsonObjectSet(jEntry, "cat",  JsonInt(ChaosGetSurgeCategory(nRoll)));

    json jLog = GetLocalJson(oPC, CHAOS_LVAR_LOG);
    if(JsonGetType(jLog) != JSON_TYPE_ARRAY)
        jLog = JsonArray();

    // Prepend newest entry; trim to LOG_MAX
    json jNew = JsonArray();
    jNew = JsonArrayInsert(jNew, jEntry);
    int i;
    int nLen = JsonGetLength(jLog);
    for(i = 0; i < nLen && i < CHAOS_LOG_MAX - 1; i++)
        jNew = JsonArrayInsert(jNew, JsonArrayGet(jLog, i));

    SetLocalJson(oPC, CHAOS_LVAR_LOG, jNew);
}

// ── Effect helper ─────────────────────────────────────────────────────────────

void ChaosRemoveTaggedEffects(object oPC, string sTag)
{
    effect e = GetFirstEffect(oPC);
    while(GetIsEffectValid(e))
    {
        if(GetEffectTag(e) == sTag)
            RemoveEffect(oPC, e);
        e = GetNextEffect(oPC);
    }
}

// ── Surge execution — 20-entry table ─────────────────────────────────────────

void ChaosExecuteSurge(object oPC, int nRoll)
{
    string sName = ChaosGetSurgeName(nRoll);
    location lPC = GetLocation(oPC);

    FloatingTextStringOnCreature("Pulsacja: " + sName + "!", oPC, FALSE);
    SendMessageToPC(oPC, "[Chaos] ◈ Pulsacja Nicości — " + sName + "!");

    ApplyEffectAtLocation(DURATION_TYPE_INSTANT,
        EffectVisualEffect(VFX_FNF_LOS_EVIL_10), lPC);

    switch(nRoll)
    {
        case 1: // Płomień Chaosu — 2d6 ogień na siebie
        {
            int nDmg = d6(2);
            ApplyEffectToObject(DURATION_TYPE_INSTANT,
                EffectDamage(nDmg, DAMAGE_TYPE_FIRE), oPC);
            ApplyEffectToObject(DURATION_TYPE_INSTANT,
                EffectVisualEffect(VFX_IMP_FLAME_M), oPC);
            SendMessageToPC(oPC,
                "Ogień chaosu trawi twoje ciało — " + IntToString(nDmg) + " obrażeń od ognia.");
            break;
        }
        case 2: // Oka Burzy — 3d6 błyskawica na najbliższego wroga
        {
            object oEnemy = GetNearestCreature(
                CREATURE_TYPE_REPUTATION, REPUTATION_TYPE_ENEMY, oPC, 1);
            if(!GetIsObjectValid(oEnemy))
                oEnemy = oPC; // brak wrogów — uderza w rzucającego
            int nDmg = d6(3);
            ApplyEffectToObject(DURATION_TYPE_INSTANT,
                EffectDamage(nDmg, DAMAGE_TYPE_ELECTRICAL), oEnemy);
            ApplyEffectToObject(DURATION_TYPE_INSTANT,
                EffectVisualEffect(VFX_IMP_LIGHTNING_M), oEnemy);
            SendMessageToPC(oPC,
                "Piorun uderza " + GetName(oEnemy) + " za " + IntToString(nDmg) + " obrażeń.");
            break;
        }
        case 3: // Pośpiech Szaleńca — Haste 20 sekund
        {
            effect eH = TagEffect(SupernaturalEffect(EffectHaste()), CHAOS_TAG_SURGE_BUFF);
            ApplyEffectToObject(DURATION_TYPE_TEMPORARY, eH, oPC, 20.0);
            ApplyEffectToObject(DURATION_TYPE_INSTANT,
                EffectVisualEffect(VFX_IMP_HASTE), oPC);
            SendMessageToPC(oPC, "Czas przyspiesza — błyskawiczne ruchy przez 20 sekund!");
            break;
        }
        case 4: // Klątwa Milczenia — Cisza 30 sekund na siebie
        {
            effect eS = TagEffect(EffectSilence(), CHAOS_TAG_SURGE_BUFF);
            ApplyEffectToObject(DURATION_TYPE_TEMPORARY, eS, oPC, 30.0);
            ApplyEffectToObject(DURATION_TYPE_INSTANT,
                EffectVisualEffect(VFX_DUR_BLACKOUT), oPC);
            SendMessageToPC(oPC, "Klątwa zaciska gardło — milczysz przez 30 sekund.");
            break;
        }
        case 5: // Lot Ducha — Niewidzialność 15 sekund
        {
            effect eInv = TagEffect(
                EffectInvisibility(INVISIBILITY_TYPE_NORMAL), CHAOS_TAG_SURGE_BUFF);
            ApplyEffectToObject(DURATION_TYPE_TEMPORARY, eInv, oPC, 15.0);
            ApplyEffectToObject(DURATION_TYPE_INSTANT,
                EffectVisualEffect(VFX_IMP_INVISIBILITY), oPC);
            SendMessageToPC(oPC, "Duch pochłania twe ciało — stajesz się niewidzialny (15 s)!");
            break;
        }
        case 6: // Tarza Czasu — Slow AoE 20 sekund, promień 6 m
        {
            SendMessageToPC(oPC, "Czas gęstnieje wokół ciebie jak smoła...");
            int i = 1;
            object oNear = GetNearestObject(OBJECT_TYPE_CREATURE, oPC, i);
            while(GetIsObjectValid(oNear)
                  && GetDistanceBetween(oNear, oPC) <= 6.0
                  && i <= 20)
            {
                if(oNear != oPC)
                {
                    ApplyEffectToObject(DURATION_TYPE_TEMPORARY, EffectSlow(), oNear, 20.0);
                    ApplyEffectToObject(DURATION_TYPE_INSTANT,
                        EffectVisualEffect(VFX_IMP_SLOW), oNear);
                }
                i++;
                oNear = GetNearestObject(OBJECT_TYPE_CREATURE, oPC, i);
            }
            break;
        }
        case 7: // Zgrozę Wyzwól — Strach AoE na wrogów, promień 5 m, 15 sekund
        {
            SendMessageToPC(oPC, "Emanacja grozy wypełza z twoich oczu...");
            int i = 1;
            object oNear = GetNearestObject(OBJECT_TYPE_CREATURE, oPC, i);
            while(GetIsObjectValid(oNear)
                  && GetDistanceBetween(oNear, oPC) <= 5.0
                  && i <= 20)
            {
                if(oNear != oPC && GetIsEnemy(oNear, oPC))
                {
                    ApplyEffectToObject(DURATION_TYPE_TEMPORARY,
                        EffectFrightened(), oNear, 15.0);
                    ApplyEffectToObject(DURATION_TYPE_INSTANT,
                        EffectVisualEffect(VFX_IMP_FEAR_S), oNear);
                }
                i++;
                oNear = GetNearestObject(OBJECT_TYPE_CREATURE, oPC, i);
            }
            break;
        }
        case 8: // Apogeum Mocy — +4 Charyzma na 60 sekund
        {
            effect eCha = TagEffect(SupernaturalEffect(
                EffectAbilityIncrease(ABILITY_CHARISMA, 4)), CHAOS_TAG_SURGE_BUFF);
            ApplyEffectToObject(DURATION_TYPE_TEMPORARY, eCha, oPC, 60.0);
            ApplyEffectToObject(DURATION_TYPE_INSTANT,
                EffectVisualEffect(VFX_IMP_GOOD_HELP), oPC);
            SendMessageToPC(oPC, "Magiczna aura spowija cię — Charyzma +4 przez 60 sekund!");
            break;
        }
        case 9: // Osłona Absolutna — 50% miss chance 10 sekund
        {
            effect eConc = TagEffect(SupernaturalEffect(
                EffectConcealment(50, MISS_CHANCE_TYPE_NORMAL)), CHAOS_TAG_SURGE_BUFF);
            ApplyEffectToObject(DURATION_TYPE_TEMPORARY, eConc, oPC, 10.0);
            ApplyEffectToObject(DURATION_TYPE_INSTANT,
                EffectVisualEffect(VFX_IMP_GLOBE_USE), oPC);
            SendMessageToPC(oPC, "Tarcza nicości rozmywa twoją formę — 50%% szans spudłowania (10 s)!");
            break;
        }
        case 10: // Dar Opatrzności — leczenie 30 HP
        {
            int nHeal = 30;
            ApplyEffectToObject(DURATION_TYPE_INSTANT, EffectHeal(nHeal), oPC);
            ApplyEffectToObject(DURATION_TYPE_INSTANT,
                EffectVisualEffect(VFX_IMP_HEALING_G), oPC);
            SendMessageToPC(oPC,
                "Nicość oddaje dług — odzyskujesz " + IntToString(nHeal) + " HP!");
            break;
        }
        case 11: // Skruch — 20 obrażeń psychicznych na siebie
        {
            int nDmg = 20;
            ApplyEffectToObject(DURATION_TYPE_INSTANT,
                EffectDamage(nDmg, DAMAGE_TYPE_PSYCHIC), oPC);
            ApplyEffectToObject(DURATION_TYPE_INSTANT,
                EffectVisualEffect(VFX_IMP_NEGATIVE_ENERGY), oPC);
            SendMessageToPC(oPC,
                "Chaos odbija się przeciw tobie — " + IntToString(nDmg) + " obrażeń psychicznych!");
            break;
        }
        case 12: // Wezwanie Cienia — spawnuje cień (nieujarzmiony)
        {
            ApplyEffectAtLocation(DURATION_TYPE_INSTANT,
                EffectVisualEffect(VFX_FNF_SUMMON_UNDEAD), lPC);
            CreateObject(OBJECT_TYPE_CREATURE, "nw_shadow", lPC);
            SendMessageToPC(oPC,
                "Z nicości wyłania się Cień — nieujarzmiony i głodny!");
            break;
        }
        case 13: // Gwałtowny Odrzut — knockdown 6 sekund
        {
            effect eKnock = TagEffect(EffectKnockdown(), CHAOS_TAG_SURGE_BUFF);
            ApplyEffectToObject(DURATION_TYPE_TEMPORARY, eKnock, oPC, 6.0);
            ApplyEffectToObject(DURATION_TYPE_INSTANT,
                EffectVisualEffect(VFX_IMP_PULSE_WIND), oPC);
            SendMessageToPC(oPC, "Eksplozja mocy rzuca cię na ziemię na 6 sekund!");
            break;
        }
        case 14: // Ślepota Otchłani — ślepota 20 sekund
        {
            effect eBlind = TagEffect(EffectBlindness(), CHAOS_TAG_SURGE_BUFF);
            ApplyEffectToObject(DURATION_TYPE_TEMPORARY, eBlind, oPC, 20.0);
            ApplyEffectToObject(DURATION_TYPE_INSTANT,
                EffectVisualEffect(VFX_DUR_BLIND_DEAF_M), oPC);
            SendMessageToPC(oPC, "Otchłań wypełnia twoje oczy — niewidzący przez 20 sekund!");
            break;
        }
        case 15: // Przemiana Bestii — polimorf (wilkołak) 30 sekund
        {
            effect ePoly = TagEffect(
                EffectPolymorph(POLYMORPH_TYPE_WEREWOLF, TRUE), CHAOS_TAG_SURGE_BUFF);
            ApplyEffectToObject(DURATION_TYPE_TEMPORARY, ePoly, oPC, 30.0);
            ApplyEffectToObject(DURATION_TYPE_INSTANT,
                EffectVisualEffect(VFX_IMP_POLYMORPH), oPC);
            SendMessageToPC(oPC, "Kości łamią się — przeobrażasz się w Bestię na 30 sekund!");
            break;
        }
        case 16: // Złoty Deszcz — losowa ilość złota (10–60)
        {
            int nGold = (Random(6) + 1) * 10;
            GiveGoldToCreature(oPC, nGold);
            ApplyEffectToObject(DURATION_TYPE_INSTANT,
                EffectVisualEffect(VFX_IMP_SUPER_HEROISM), oPC);
            SendMessageToPC(oPC,
                "Złoty deszcz chaosu — " + IntToString(nGold) + " sztuk złota spada z nieba!");
            break;
        }
        case 17: // Wir Chaosu — Entangle 10 sekund
        {
            effect eEnt = TagEffect(EffectEntangle(), CHAOS_TAG_SURGE_BUFF);
            ApplyEffectToObject(DURATION_TYPE_TEMPORARY, eEnt, oPC, 10.0);
            ApplyEffectToObject(DURATION_TYPE_INSTANT,
                EffectVisualEffect(VFX_DUR_WEB), oPC);
            SendMessageToPC(oPC, "Pętle z nicości oplatają cię — uwięziony na 10 sekund!");
            break;
        }
        case 18: // Paraliż Woli — ogłuszenie 6 sekund
        {
            effect eStun = TagEffect(EffectStunned(), CHAOS_TAG_SURGE_BUFF);
            ApplyEffectToObject(DURATION_TYPE_TEMPORARY, eStun, oPC, 6.0);
            ApplyEffectToObject(DURATION_TYPE_INSTANT,
                EffectVisualEffect(VFX_DUR_STUNNED), oPC);
            SendMessageToPC(oPC, "Wola nicości kruszy twój umysł — ogłuszony na 6 sekund!");
            break;
        }
        case 19: // Szał Bitewny — +4 SIŁ/KON, -2 KP, 30 sekund
        {
            effect eStr  = EffectAbilityIncrease(ABILITY_STRENGTH,     4);
            effect eCon  = EffectAbilityIncrease(ABILITY_CONSTITUTION, 4);
            effect eAC   = EffectACDecrease(2);
            effect eLink = EffectLinkEffects(eStr, EffectLinkEffects(eCon, eAC));
            effect eRage = TagEffect(SupernaturalEffect(eLink), CHAOS_TAG_SURGE_BUFF);
            ApplyEffectToObject(DURATION_TYPE_TEMPORARY, eRage, oPC, 30.0);
            ApplyEffectToObject(DURATION_TYPE_INSTANT,
                EffectVisualEffect(VFX_IMP_DIVINE_STRIKE_FIRE), oPC);
            SendMessageToPC(oPC,
                "Szał bitewny opanowuje cię — SIŁ+4, KON+4, KP-2 przez 30 sekund!");
            break;
        }
        case 20: // Apokalipsa — 10d6 magiczny AoE 5 m + reset CP do 0
        {
            SendMessageToPC(oPC,
                "◈◈◈ APOKALIPSA CHAOSU ◈◈◈ Nicość eksploduje wokół ciebie!");
            ApplyEffectAtLocation(DURATION_TYPE_INSTANT,
                EffectVisualEffect(VFX_FNF_NATURES_BALANCE), lPC);

            int nDmg = d6(10);
            // Obrażenia dla siebie
            ApplyEffectToObject(DURATION_TYPE_INSTANT,
                EffectDamage(nDmg, DAMAGE_TYPE_MAGICAL), oPC);
            // AoE: wszystkie stworzenia w promieniu 5 m
            int i = 1;
            object oNear = GetNearestObject(OBJECT_TYPE_CREATURE, oPC, i);
            while(GetIsObjectValid(oNear)
                  && GetDistanceBetween(oNear, oPC) <= 5.0
                  && i <= 20)
            {
                if(oNear != oPC)
                    ApplyEffectToObject(DURATION_TYPE_INSTANT,
                        EffectDamage(nDmg, DAMAGE_TYPE_MAGICAL), oNear);
                i++;
                oNear = GetNearestObject(OBJECT_TYPE_CREATURE, oPC, i);
            }
            // Apokalipsa wypala chaos do zera
            ChaosSetCP(oPC, 0);
            SendMessageToPC(oPC,
                "Eksplozja zadała " + IntToString(nDmg) +
                " obrażeń w promieniu 5 metrów. Pulsacja Nicości opadła do zera.");
            break;
        }
        default: break;
    }
}

// ── Surge trigger ─────────────────────────────────────────────────────────────

void ChaosRollSurge(object oPC)
{
    int nRoll = Random(20) + 1;

    int nTotal = GetLocalInt(oPC, CHAOS_LVAR_TOTAL) + 1;
    SetLocalInt(oPC, CHAOS_LVAR_TOTAL, nTotal);

    ChaosAppendLog(oPC, nRoll);

    // Spend CP unless surge 20 already zeroed it
    int nCP = ChaosGetCP(oPC);
    if(nCP > 0)
        ChaosSetCP(oPC, nCP - CHAOS_SURGE_COST < 0 ? 0 : nCP - CHAOS_SURGE_COST);

    ChaosExecuteSurge(oPC, nRoll);

    // Refresh UI if open
    int nToken = NuiFindWindow(oPC, CHAOS_WINDOW);
    if(nToken != 0)
        FeedChaosWindow(oPC, nToken);

    ChaosSaveState(oPC);
}

// ── NUI layout ────────────────────────────────────────────────────────────────

json BuildChaosLayout(object oPC)
{
    float fBtnH  = GetNuiScaleDimension(oPC, 32.0);
    float fRowH  = GetNuiScaleDimension(oPC, 26.0);
    float fLogH  = GetNuiScaleDimension(oPC, 200.0);
    float fBarH  = GetNuiScaleDimension(oPC, 28.0);

    // — Status row: label left, CP value right —
    json jStatusLbl = NuiLabel(NuiBind(CHAOS_BIND_STATUS_LBL),
        JsonInt(NUI_HALIGN_LEFT), JsonInt(NUI_VALIGN_MIDDLE));
    jStatusLbl = NuiStyleForegroundColor(jStatusLbl, NuiBind(CHAOS_BIND_STATUS_COL));
    jStatusLbl = NuiHeight(jStatusLbl, GetNuiScaleDimension(oPC, 24.0));

    json jCpLbl = NuiLabel(NuiBind(CHAOS_BIND_CP_LBL),
        JsonInt(NUI_HALIGN_RIGHT), JsonInt(NUI_VALIGN_MIDDLE));
    jCpLbl = NuiWidth(jCpLbl, GetNuiScaleDimension(oPC, 80.0));
    jCpLbl = NuiHeight(jCpLbl, GetNuiScaleDimension(oPC, 24.0));

    json jStatusRow = JsonArray();
    jStatusRow = JsonArrayInsert(jStatusRow, jStatusLbl);
    jStatusRow = JsonArrayInsert(jStatusRow, NuiSpacer());
    jStatusRow = JsonArrayInsert(jStatusRow, jCpLbl);

    // — Chaos progress bar —
    json jBar = NuiProgress(NuiBind(CHAOS_BIND_METER_VAL));
    jBar = NuiHeight(jBar, fBarH);
    jBar = NuiStyleForegroundColor(jBar, NuiBind(CHAOS_BIND_METER_COL));
    jBar = NuiTooltip(jBar, JsonString("Poziom Pulsacji Nicości (0–100)"));

    // — Log header —
    json jLogHdr = NuiLabel(JsonString("── Historia Pulsacji ──"),
        JsonInt(NUI_HALIGN_CENTER), JsonInt(NUI_VALIGN_MIDDLE));
    jLogHdr = NuiHeight(jLogHdr, GetNuiScaleDimension(oPC, 22.0));

    // — Log list —
    json jLogLbl = NuiLabel(NuiBind(CHAOS_BIND_LOG_TEXT),
        JsonInt(NUI_HALIGN_LEFT), JsonInt(NUI_VALIGN_MIDDLE));
    jLogLbl = NuiStyleForegroundColor(jLogLbl, NuiBind(CHAOS_BIND_LOG_COL));

    json jLogCell = NuiGroup(
        NuiRow(JsonArrayInsert(JsonArray(), jLogLbl)),
        FALSE, NUI_SCROLLBARS_NONE);

    json jLogTmpl = JsonArrayInsert(JsonArray(),
        NuiListTemplateCell(jLogCell, 0.0, TRUE));

    json jLogList = NuiList(jLogTmpl, NuiBind(CHAOS_BIND_LOG_CNT), fRowH);
    jLogList = NuiHeight(jLogList, fLogH);

    // — Footer: total label + Wyzwól Chaos + Zamknij —
    json jTotalLbl = NuiLabel(NuiBind(CHAOS_BIND_TOTAL_LBL),
        JsonInt(NUI_HALIGN_LEFT), JsonInt(NUI_VALIGN_MIDDLE));

    json jSurgeBtn = NuiButton(NuiBind(CHAOS_BIND_SURGE_LBL));
    jSurgeBtn = NuiId(jSurgeBtn, CHAOS_BTN_SURGE);
    jSurgeBtn = NuiEnabled(jSurgeBtn, NuiBind(CHAOS_BIND_SURGE_ENA));
    jSurgeBtn = NuiWidth(jSurgeBtn, GetNuiScaleDimension(oPC, 210.0));
    jSurgeBtn = NuiHeight(jSurgeBtn, fBtnH);
    jSurgeBtn = NuiTooltip(jSurgeBtn,
        JsonString("Celowo wyzwól Pulsację Nicości kosztem "
                   + IntToString(CHAOS_SURGE_COST) + " CP. Efekt jest losowy!"));

    json jCloseBtn = NuiButton(JsonString("Zamknij"));
    jCloseBtn = NuiId(jCloseBtn, CHAOS_BTN_CLOSE);
    jCloseBtn = NuiWidth(jCloseBtn, GetNuiScaleDimension(oPC, 90.0));
    jCloseBtn = NuiHeight(jCloseBtn, fBtnH);

    json jFooterRow = JsonArray();
    jFooterRow = JsonArrayInsert(jFooterRow, jTotalLbl);
    jFooterRow = JsonArrayInsert(jFooterRow, NuiSpacer());
    jFooterRow = JsonArrayInsert(jFooterRow, jSurgeBtn);
    jFooterRow = JsonArrayInsert(jFooterRow,
        NuiWidth(NuiSpacer(), GetNuiScaleDimension(oPC, 8.0)));
    jFooterRow = JsonArrayInsert(jFooterRow, jCloseBtn);

    // — Assemble column —
    json jCol = JsonArray();
    jCol = JsonArrayInsert(jCol, NuiRow(jStatusRow));
    jCol = JsonArrayInsert(jCol, jBar);
    jCol = JsonArrayInsert(jCol, CreateEmptyRow(oPC, 6.0));
    jCol = JsonArrayInsert(jCol, jLogHdr);
    jCol = JsonArrayInsert(jCol, jLogList);
    jCol = JsonArrayInsert(jCol, CreateEmptyRow(oPC, 6.0));
    jCol = JsonArrayInsert(jCol, NuiRow(jFooterRow));

    // Side spacers for horizontal centering
    json jSide = NuiCol(JsonArrayInsert(JsonArray(), NuiSpacer()));
    float fCont = GetNuiScaleDimension(oPC, 440.0);
    json jMain  = JsonArray();
    jMain = JsonArrayInsert(jMain, jSide);
    jMain = JsonArrayInsert(jMain, NuiWidth(NuiCol(jCol), fCont));
    jMain = JsonArrayInsert(jMain, jSide);

    return NuiRow(jMain);
}

// ── Feed binds ────────────────────────────────────────────────────────────────

void FeedChaosWindow(object oPC, int nToken)
{
    int nCP     = ChaosGetCP(oPC);
    int nTotal  = GetLocalInt(oPC, CHAOS_LVAR_TOTAL);
    json jLog   = GetLocalJson(oPC, CHAOS_LVAR_LOG);
    if(JsonGetType(jLog) != JSON_TYPE_ARRAY)
        jLog = JsonArray();
    int nLogLen = JsonGetLength(jLog);

    // Meter
    float fVal = IntToFloat(nCP) / IntToFloat(CHAOS_MAX);
    NuiSetBind(oPC, nToken, CHAOS_BIND_METER_VAL, JsonFloat(fVal));
    NuiSetBind(oPC, nToken, CHAOS_BIND_METER_COL, ChaosGetMeterColor(nCP));
    NuiSetBind(oPC, nToken, CHAOS_BIND_CP_LBL,
        JsonString(IntToString(nCP) + " / " + IntToString(CHAOS_MAX)));
    NuiSetBind(oPC, nToken, CHAOS_BIND_STATUS_LBL, JsonString(ChaosGetStatusLabel(nCP)));
    NuiSetBind(oPC, nToken, CHAOS_BIND_STATUS_COL, ChaosGetStatusColor(nCP));

    // Log list arrays
    json jTexts  = JsonArray();
    json jColors = JsonArray();
    int i;
    for(i = 0; i < nLogLen; i++)
    {
        json jEntry  = JsonArrayGet(jLog, i);
        string sName = JsonGetString(JsonObjectGet(jEntry, "name"));
        int nRoll    = JsonGetInt   (JsonObjectGet(jEntry, "roll"));
        string sLine = IntToString(nLogLen - i) + ". " + sName;

        jTexts  = JsonArrayInsert(jTexts,  JsonString(sLine));
        jColors = JsonArrayInsert(jColors, ChaosGetSurgeColor(nRoll));
    }
    NuiSetBind(oPC, nToken, CHAOS_BIND_LOG_TEXT, jTexts);
    NuiSetBind(oPC, nToken, CHAOS_BIND_LOG_COL,  jColors);
    NuiSetBind(oPC, nToken, CHAOS_BIND_LOG_CNT,  JsonInt(nLogLen));

    // Footer
    NuiSetBind(oPC, nToken, CHAOS_BIND_TOTAL_LBL,
        JsonString("Łączne pulsacje: " + IntToString(nTotal)));

    int bCanSurge = (nCP >= CHAOS_SURGE_COST);
    NuiSetBind(oPC, nToken, CHAOS_BIND_SURGE_ENA, JsonBool(bCanSurge));
    NuiSetBind(oPC, nToken, CHAOS_BIND_SURGE_LBL,
        JsonString("Wyzwól Chaos (koszt: " + IntToString(CHAOS_SURGE_COST) + " CP)"));
}

// ── Window open ───────────────────────────────────────────────────────────────

void ChaosOpenWindow(object oPC)
{
    int nToken = NuiFindWindow(oPC, CHAOS_WINDOW);
    if(nToken != 0)
    {
        FeedChaosWindow(oPC, nToken);
        return;
    }

    float fW = GetNuiScaleDimension(oPC, CHAOS_W);
    float fH = GetNuiScaleDimension(oPC, CHAOS_H);
    float fCX = (IntToFloat(GetPlayerDeviceProperty(oPC,
        PLAYER_DEVICE_PROPERTY_GUI_WIDTH))  - fW) / 2.0;
    float fCY = (IntToFloat(GetPlayerDeviceProperty(oPC,
        PLAYER_DEVICE_PROPERTY_GUI_HEIGHT)) - fH) / 2.0;
    json jGeom = NuiRect(fCX, fCY, fW, fH);

    json jWin = NuiWindow(
        BuildChaosLayout(oPC),
        JsonString("Pulsacja Nicości"),
        NuiBind(CHAOS_WIN_GEOM),
        JsonBool(FALSE),  // not resizable
        JsonBool(FALSE),  // not collapsed
        JsonBool(TRUE),   // closable (system X fires EVENT_TYPE_CLOSE)
        JsonBool(FALSE),  // solid background
        JsonBool(TRUE));  // with border

    nToken = NuiCreate(oPC, jWin, CHAOS_WINDOW, CHAOS_EV_SCRIPT);
    NuiSetBind(oPC, nToken, CHAOS_WIN_GEOM, jGeom);
    FeedChaosWindow(oPC, nToken);
}
