#include "lib_bcn_def"

// ----------------------------------------------------------------
// Label / color helpers
// ----------------------------------------------------------------

string BcnGetTypeLabel(string sType)
{
    if(sType == BCN_TYPE_FIRE)   return "Ogien";
    if(sType == BCN_TYPE_SHADOW) return "Cien";
    if(sType == BCN_TYPE_SPIRIT) return "Duch";
    if(sType == BCN_TYPE_BLOOD)  return "Krew";
    if(sType == BCN_TYPE_STONE)  return "Kamien";
    return "Nieznany";
}

string BcnGetStatusLabel(int nCorruption, int bKindled)
{
    if(!bKindled)                       return "Wygaszona";
    if(nCorruption == BCN_CORR_CLEAN)   return "Plonie czysto";
    if(nCorruption == BCN_CORR_FAINT)   return "Lekko skalana";
    if(nCorruption == BCN_CORR_HEAVY)   return "Mocno skalana";
    if(nCorruption == BCN_CORR_OUT)     return "Zgaszona przez mrok";
    return "Nieznany";
}

json BcnGetStatusColor(int nCorruption, int bKindled)
{
    if(!bKindled || nCorruption == BCN_CORR_OUT) return NuiColor(100, 100, 100);
    if(nCorruption == BCN_CORR_CLEAN)            return NuiColor(255, 200, 80);
    if(nCorruption == BCN_CORR_FAINT)            return NuiColor(200, 140, 60);
    if(nCorruption == BCN_CORR_HEAVY)            return NuiColor(160, 70,  60);
    return NuiColor(80, 80, 80);
}

string BcnGetBuffDesc(string sType)
{
    if(sType == BCN_TYPE_FIRE)   return "Blogoslawienstwo: +2 HP co 6 sekund przez 2 godziny";
    if(sType == BCN_TYPE_SHADOW) return "Blogoslawienstwo: +2 Ukrywanie, +2 Cichy Ruch przez 2 godziny";
    if(sType == BCN_TYPE_SPIRIT) return "Blogoslawienstwo: +3 Koncentracja, +3 Magoznawstwo przez 2 godziny";
    if(sType == BCN_TYPE_BLOOD)  return "Blogoslawienstwo: +1 do ataku, +10 tymczasowych HP przez 2 godziny";
    if(sType == BCN_TYPE_STONE)  return "Blogoslawienstwo: +3 KP (naturalny pancerz) przez 2 godziny";
    return "";
}

string BcnGetFuelDesc(string sType)
{
    if(sType == BCN_TYPE_FIRE)   return "Zapalenie: 3x hubka (bcn_tinder)";
    if(sType == BCN_TYPE_SHADOW) return "Zapalenie: 3x popiol cienia (bcn_shadow_ash)";
    if(sType == BCN_TYPE_SPIRIT) return "Zapalenie: 3x kadzidlo (bcn_incense)";
    if(sType == BCN_TYPE_BLOOD)  return "Zapalenie: 3x fiolka krwi (bcn_blood_vial) + 15 HP";
    if(sType == BCN_TYPE_STONE)  return "Zapalenie: 3x kwarc (bcn_quartz)";
    return "";
}

// ----------------------------------------------------------------
// Inventory helpers
// ----------------------------------------------------------------

int BcnCountItemsByTag(object oPC, string sTag)
{
    int nCount = 0;
    object oItem = GetFirstItemInInventory(oPC);
    while(GetIsObjectValid(oItem))
    {
        if(GetTag(oItem) == sTag)
            nCount += GetItemStackSize(oItem);
        oItem = GetNextItemInInventory(oPC);
    }
    return nCount;
}

// Destroys exactly nNeeded items with sTag from PC inventory.
// Returns TRUE on success, FALSE if insufficient quantity.
int BcnRemoveItems(object oPC, string sTag, int nNeeded)
{
    int nLeft = nNeeded;
    object oItem = GetFirstItemInInventory(oPC);
    while(GetIsObjectValid(oItem) && nLeft > 0)
    {
        if(GetTag(oItem) == sTag)
        {
            int nStack = GetItemStackSize(oItem);
            if(nStack <= nLeft)
            {
                nLeft -= nStack;
                DestroyObject(oItem);
                oItem = GetFirstItemInInventory(oPC);   // restart after destroy
                continue;
            }
            else
            {
                SetItemStackSize(oItem, nStack - nLeft);
                nLeft = 0;
            }
        }
        oItem = GetNextItemInInventory(oPC);
    }
    return (nLeft == 0);
}

// ----------------------------------------------------------------
// Buff application
// ----------------------------------------------------------------

void BcnApplyBuff(object oPC, string sType)
{
    effect eBuff;
    float fDur = IntToFloat(BCN_BUFF_DURATION_SEC);

    if(sType == BCN_TYPE_FIRE)
    {
        eBuff = SupernaturalEffect(EffectRegenerate(2, 6.0));
    }
    else if(sType == BCN_TYPE_SHADOW)
    {
        effect eH = EffectSkillIncrease(SKILL_HIDE, 2);
        effect eM = EffectSkillIncrease(SKILL_MOVE_SILENTLY, 2);
        eBuff = SupernaturalEffect(EffectLinkEffects(eH, eM));
    }
    else if(sType == BCN_TYPE_SPIRIT)
    {
        effect eC = EffectSkillIncrease(SKILL_CONCENTRATION, 3);
        effect eS = EffectSkillIncrease(SKILL_SPELLCRAFT, 3);
        eBuff = SupernaturalEffect(EffectLinkEffects(eC, eS));
    }
    else if(sType == BCN_TYPE_BLOOD)
    {
        effect eA = EffectAttackIncrease(1);
        effect eT = EffectTemporaryHitpoints(10);
        eBuff = SupernaturalEffect(EffectLinkEffects(eA, eT));
    }
    else if(sType == BCN_TYPE_STONE)
    {
        eBuff = SupernaturalEffect(EffectACIncrease(3, AC_NATURAL_BONUS));
    }
    else return;

    ApplyEffectToObject(DURATION_TYPE_TEMPORARY, eBuff, oPC, fDur);
    ApplyEffectToObject(DURATION_TYPE_INSTANT,
        EffectVisualEffect(VFX_IMP_HOLY_AID), oPC);
}

// ----------------------------------------------------------------
// Game actions
// ----------------------------------------------------------------

void BcnTryKindle(object oPC, object oBeacon, int nToken)
{
    string sTag  = GetTag(oBeacon);
    string sType = GetLocalString(oBeacon, BCN_VAR_TYPE);
    if(sType == "") sType = BCN_TYPE_FIRE;

    // Already kindled and not extinguished
    if(BcnIsKindled(sTag))
    {
        SendMessageToPC(oPC, "[Latarnia] Plomien juz plonie — nie trzeba jej zapalac.");
        return;
    }

    string sFuelTag;
    if     (sType == BCN_TYPE_FIRE)   sFuelTag = BCN_ITEM_TINDER;
    else if(sType == BCN_TYPE_SHADOW) sFuelTag = BCN_ITEM_SHADOW_ASH;
    else if(sType == BCN_TYPE_SPIRIT) sFuelTag = BCN_ITEM_INCENSE;
    else if(sType == BCN_TYPE_BLOOD)  sFuelTag = BCN_ITEM_BLOOD_VIAL;
    else if(sType == BCN_TYPE_STONE)  sFuelTag = BCN_ITEM_QUARTZ;

    if(BcnCountItemsByTag(oPC, sFuelTag) < 3)
    {
        SendMessageToPC(oPC, "[Latarnia] Brakuje trzech porcji materialu rytualnego.");
        return;
    }

    if(sType == BCN_TYPE_BLOOD)
    {
        if(GetCurrentHitPoints(oPC) <= BCN_BLOOD_HP_COST)
        {
            SendMessageToPC(oPC, "[Latarnia] Pieczec krwi wymaga ofiary — zbyt malo sily zyciowej.");
            return;
        }
        // Blood cost: deal magical damage that cannot kill (leave at 1 HP)
        effect eDmg = EffectDamage(BCN_BLOOD_HP_COST, DAMAGE_TYPE_MAGICAL);
        ApplyEffectToObject(DURATION_TYPE_INSTANT, eDmg, oPC);
    }

    BcnRemoveItems(oPC, sFuelTag, 3);
    BcnKindle(sTag, GetName(oPC));
    BcnLearnBeacon(GetObjectUUID(oPC), sTag);

    ApplyEffectAtLocation(DURATION_TYPE_INSTANT,
        EffectVisualEffect(VFX_FNF_SMOKE_PUFF), GetLocation(oBeacon));
    ApplyEffectToObject(DURATION_TYPE_INSTANT,
        EffectVisualEffect(VFX_IMP_HEALING_L), oBeacon);

    SendMessageToPC(oPC,
        "[Latarnia] Plomien rozblyskal. Latarnia plonie — Ciemnosc cofnela sie o krok.");
    FloatingTextStringOnCreature("Latarnia zapalona!", oPC, FALSE);

    BcnFeedStatus(oPC, nToken, oBeacon);
    BcnFeedKnownList(oPC, nToken);
}

void BcnTryRest(object oPC, object oBeacon, int nToken)
{
    string sTag = GetTag(oBeacon);

    if(!BcnIsKindled(sTag))
    {
        SendMessageToPC(oPC, "[Latarnia] Latarnia jest zgaszona lub skalana — odpoczynek niemozliwy.");
        return;
    }

    int nNow      = BcnNow();
    int nLastRest = BcnGetLastRest(GetObjectUUID(oPC), sTag);
    int nElapsed  = nNow - nLastRest;

    if(nLastRest > 0 && nElapsed < BCN_REST_COOLDOWN_SEC)
    {
        int nMinsLeft = (BCN_REST_COOLDOWN_SEC - nElapsed) / 60 + 1;
        SendMessageToPC(oPC, "[Latarnia] Sily jeszcze sie nie odbudowaly. Wróc za "
            + IntToString(nMinsLeft) + " minut.");
        return;
    }

    string sType = GetLocalString(oBeacon, BCN_VAR_TYPE);
    if(sType == "") sType = BCN_TYPE_FIRE;

    effect eHeal = EffectHeal(GetMaxHitPoints(oPC) - GetCurrentHitPoints(oPC));
    if(GetCurrentHitPoints(oPC) < GetMaxHitPoints(oPC))
        ApplyEffectToObject(DURATION_TYPE_INSTANT, eHeal, oPC);

    BcnApplyBuff(oPC, sType);
    BcnRecordRest(GetObjectUUID(oPC), sTag);

    ApplyEffectAtLocation(DURATION_TYPE_INSTANT,
        EffectVisualEffect(VFX_FNF_LOS_NORMAL_10), GetLocation(oBeacon));
    SendMessageToPC(oPC,
        "[Latarnia] Cieplo plomienia przenika cialo i dusze. Sily odzyskane.");
    FloatingTextStringOnCreature("Odpoczyales przy latarni.", oPC, FALSE);

    BcnFeedStatus(oPC, nToken, oBeacon);
    BcnFeedKnownList(oPC, nToken);
}

void BcnTryPurify(object oPC, object oBeacon, int nToken)
{
    string sTag = GetTag(oBeacon);
    json jB = BcnGetBeacon(sTag);
    if(JsonGetType(jB) == JSON_TYPE_NULL) return;

    int nCorr = JsonGetInt(JsonObjectGet(jB, "corruption"));
    if(nCorr == BCN_CORR_CLEAN)
    {
        SendMessageToPC(oPC, "[Latarnia] Latarnia jest juz czysta.");
        return;
    }

    if(BcnCountItemsByTag(oPC, BCN_ITEM_HOLY_WATER) < 1)
    {
        SendMessageToPC(oPC, "[Latarnia] Potrzebujesz swieconej wody (bcn_holy_water).");
        return;
    }

    BcnRemoveItems(oPC, BCN_ITEM_HOLY_WATER, 1);
    BcnPurify(sTag);

    json jBAfter  = BcnGetBeacon(sTag);
    int nCorrAfter = JsonGetInt(JsonObjectGet(jBAfter, "corruption"));

    ApplyEffectAtLocation(DURATION_TYPE_INSTANT,
        EffectVisualEffect(VFX_IMP_HOLY_AID), GetLocation(oBeacon));

    if(nCorrAfter == BCN_CORR_CLEAN)
        SendMessageToPC(oPC, "[Latarnia] Swiecona woda splonela w bialym ogniu. Latarnia oczyszczona.");
    else
        SendMessageToPC(oPC, "[Latarnia] Pieczec skazy slabnie. Latarnia wymaga dalszej oczyszczenia.");

    BcnFeedStatus(oPC, nToken, oBeacon);
    BcnFeedKnownList(oPC, nToken);
}

// ----------------------------------------------------------------
// NUI feed functions — populate bind data after any state change
// ----------------------------------------------------------------

void BcnFeedStatus(object oPC, int nToken, object oBeacon)
{
    string sTag  = GetTag(oBeacon);
    string sType = GetLocalString(oBeacon, BCN_VAR_TYPE);
    string sName = GetLocalString(oBeacon, BCN_VAR_NAME);
    if(sType == "") sType = BCN_TYPE_FIRE;
    if(sName == "") sName = "Nieznana Latarnia";

    json jB      = BcnGetBeacon(sTag);
    int bKindled = BcnIsKindled(sTag);
    int nCorr    = (JsonGetType(jB) == JSON_TYPE_NULL) ? 0
                    : JsonGetInt(JsonObjectGet(jB, "corruption"));
    string sKindledBy = (JsonGetType(jB) == JSON_TYPE_NULL) ? ""
                    : JsonGetString(JsonObjectGet(jB, "kindled_by"));

    NuiSetBind(oPC, nToken, BCN_BIND_BEACON_NAME, JsonString(sName));
    NuiSetBind(oPC, nToken, BCN_BIND_TYPE_LBL,    JsonString("[" + BcnGetTypeLabel(sType) + "]"));
    NuiSetBind(oPC, nToken, BCN_BIND_STATUS_LBL,  JsonString(BcnGetStatusLabel(nCorr, bKindled)));
    NuiSetBind(oPC, nToken, BCN_BIND_STATUS_COL,  BcnGetStatusColor(nCorr, bKindled));

    string sKindlerLine = bKindled
        ? ("Zapalona przez: " + sKindledBy)
        : "Latarnia oczekuje na ogien.";
    NuiSetBind(oPC, nToken, BCN_BIND_KINDLER_LBL, JsonString(sKindlerLine));
    NuiSetBind(oPC, nToken, BCN_BIND_BUFF_DESC,   JsonString(BcnGetBuffDesc(sType)));
    NuiSetBind(oPC, nToken, BCN_BIND_FUEL_DESC,
        JsonString(bKindled ? "" : BcnGetFuelDesc(sType)));

    // Cooldown info
    string sCooldown = "";
    if(bKindled)
    {
        int nNow     = BcnNow();
        int nLastR   = BcnGetLastRest(GetObjectUUID(oPC), sTag);
        int nElapsed = nNow - nLastR;
        if(nLastR > 0 && nElapsed < BCN_REST_COOLDOWN_SEC)
        {
            int nMinsLeft = (BCN_REST_COOLDOWN_SEC - nElapsed) / 60 + 1;
            sCooldown = "Odpoczynek gotowy za: " + IntToString(nMinsLeft) + " min";
        }
        else
            sCooldown = "Odpoczynek: dostepny";
    }
    NuiSetBind(oPC, nToken, BCN_BIND_COOLDOWN_LBL, JsonString(sCooldown));

    // Button enable states
    int bExtinguished = (nCorr == BCN_CORR_OUT);
    NuiSetBind(oPC, nToken, BCN_BIND_KINDLE_ENA,
        JsonBool(!bKindled || bExtinguished));
    NuiSetBind(oPC, nToken, BCN_BIND_REST_ENA,
        JsonBool(bKindled && !bExtinguished));
    NuiSetBind(oPC, nToken, BCN_BIND_PURIFY_ENA,
        JsonBool(bKindled && nCorr > BCN_CORR_CLEAN));
}

void BcnFeedKnownList(object oPC, int nToken)
{
    json jRows = BcnGetKnownBeacons(GetObjectUUID(oPC));
    int nCount = JsonGetLength(jRows);

    json jTypes = JsonArray();
    json jAreas = JsonArray();
    json jSts   = JsonArray();
    json jCols  = JsonArray();
    json jEncs  = JsonArray();

    int i;
    for(i = 0; i < nCount; i++)
    {
        json jRow    = JsonArrayGet(jRows, i);
        string sType = JsonGetString(JsonObjectGet(jRow, "beacon_type"));
        int nCorr    = JsonGetInt   (JsonObjectGet(jRow, "corruption"));
        string sKBy  = JsonGetString(JsonObjectGet(jRow, "kindled_by"));
        int bKindled = (sKBy != "" && nCorr < BCN_CORR_OUT);
        int nRests   = JsonGetInt   (JsonObjectGet(jRow, "rest_count"));
        string sArea = JsonGetString(JsonObjectGet(jRow, "area_name"));
        string sSt   = BcnGetStatusLabel(nCorr, bKindled)
                        + " [x" + IntToString(nRests) + "]";

        jTypes = JsonArrayInsert(jTypes, JsonString(BcnGetTypeLabel(sType)));
        jAreas = JsonArrayInsert(jAreas, JsonString(sArea));
        jSts   = JsonArrayInsert(jSts,   JsonString(sSt));
        jCols  = JsonArrayInsert(jCols,  BcnGetStatusColor(nCorr, bKindled));
        jEncs  = JsonArrayInsert(jEncs,  JsonBool(FALSE));
    }

    NuiSetBind(oPC, nToken, BCN_BIND_KNOWN_CNT,  JsonInt(nCount));
    NuiSetBind(oPC, nToken, BCN_BIND_KNOWN_TYPE,  jTypes);
    NuiSetBind(oPC, nToken, BCN_BIND_KNOWN_AREA,  jAreas);
    NuiSetBind(oPC, nToken, BCN_BIND_KNOWN_ST,    jSts);
    NuiSetBind(oPC, nToken, BCN_BIND_KNOWN_COL,   jCols);
    NuiSetBind(oPC, nToken, BCN_BIND_KNOWN_ENC,   jEncs);
}

// ----------------------------------------------------------------
// NUI layout builder
// ----------------------------------------------------------------

json BcnBuildLayout(object oPC)
{
    float fBtnH  = GetNuiScaleDimension(oPC, 30.0);
    float fRowH  = GetNuiScaleDimension(oPC, 24.0);
    float fListH = GetNuiScaleDimension(oPC, 130.0);

    // ---- Title row: beacon name | type label | close ----
    json jNameLbl = NuiLabel(NuiBind(BCN_BIND_BEACON_NAME),
        JsonInt(NUI_HALIGN_LEFT), JsonInt(NUI_VALIGN_MIDDLE));
    jNameLbl = NuiStyleForegroundColor(jNameLbl, NuiColor(230, 200, 120));

    json jTypeLbl = NuiLabel(NuiBind(BCN_BIND_TYPE_LBL),
        JsonInt(NUI_HALIGN_RIGHT), JsonInt(NUI_VALIGN_MIDDLE));
    jTypeLbl = NuiWidth(jTypeLbl, GetNuiScaleDimension(oPC, 85.0));

    json jCloseBtn = NuiButton(JsonString("X"));
    jCloseBtn = NuiId(jCloseBtn, BCN_BTN_CLOSE);
    jCloseBtn = NuiWidth(jCloseBtn, GetNuiScaleDimension(oPC, 28.0));
    jCloseBtn = NuiHeight(jCloseBtn, fBtnH);

    json jTitleRow = JsonArray();
    jTitleRow = JsonArrayInsert(jTitleRow, jNameLbl);
    jTitleRow = JsonArrayInsert(jTitleRow, jTypeLbl);
    jTitleRow = JsonArrayInsert(jTitleRow, jCloseBtn);

    // ---- Info rows ----
    json jStatusLbl = NuiLabel(NuiBind(BCN_BIND_STATUS_LBL),
        JsonInt(NUI_HALIGN_LEFT), JsonInt(NUI_VALIGN_MIDDLE));
    jStatusLbl = NuiStyleForegroundColor(jStatusLbl, NuiBind(BCN_BIND_STATUS_COL));
    jStatusLbl = NuiHeight(jStatusLbl, fRowH);

    json jKindlerLbl = NuiLabel(NuiBind(BCN_BIND_KINDLER_LBL),
        JsonInt(NUI_HALIGN_LEFT), JsonInt(NUI_VALIGN_MIDDLE));
    jKindlerLbl = NuiHeight(jKindlerLbl, fRowH);

    json jBuffLbl = NuiLabel(NuiBind(BCN_BIND_BUFF_DESC),
        JsonInt(NUI_HALIGN_LEFT), JsonInt(NUI_VALIGN_MIDDLE));
    jBuffLbl = NuiHeight(jBuffLbl, fRowH);

    json jFuelLbl = NuiLabel(NuiBind(BCN_BIND_FUEL_DESC),
        JsonInt(NUI_HALIGN_LEFT), JsonInt(NUI_VALIGN_MIDDLE));
    jFuelLbl = NuiHeight(jFuelLbl, fRowH);

    json jCooldownLbl = NuiLabel(NuiBind(BCN_BIND_COOLDOWN_LBL),
        JsonInt(NUI_HALIGN_LEFT), JsonInt(NUI_VALIGN_MIDDLE));
    jCooldownLbl = NuiHeight(jCooldownLbl, fRowH);

    // ---- Action buttons ----
    float fActW = GetNuiScaleDimension(oPC, 135.0);

    json jKindleBtn = NuiButton(JsonString("Zapal"));
    jKindleBtn = NuiId(jKindleBtn, BCN_BTN_KINDLE);
    jKindleBtn = NuiEnabled(jKindleBtn, NuiBind(BCN_BIND_KINDLE_ENA));
    jKindleBtn = NuiWidth(jKindleBtn, fActW);
    jKindleBtn = NuiHeight(jKindleBtn, fBtnH);
    jKindleBtn = NuiTooltip(jKindleBtn, JsonString("Zapala latarnie — zuzywa material rytualny"));

    json jRestBtn = NuiButton(JsonString("Odpocznij"));
    jRestBtn = NuiId(jRestBtn, BCN_BTN_REST);
    jRestBtn = NuiEnabled(jRestBtn, NuiBind(BCN_BIND_REST_ENA));
    jRestBtn = NuiWidth(jRestBtn, fActW);
    jRestBtn = NuiHeight(jRestBtn, fBtnH);
    jRestBtn = NuiTooltip(jRestBtn, JsonString("Odpoczywa przy latarni — przywraca HP i nadaje blogoslawienstwo"));

    json jPurifyBtn = NuiButton(JsonString("Oczyscz"));
    jPurifyBtn = NuiId(jPurifyBtn, BCN_BTN_PURIFY);
    jPurifyBtn = NuiEnabled(jPurifyBtn, NuiBind(BCN_BIND_PURIFY_ENA));
    jPurifyBtn = NuiWidth(jPurifyBtn, fActW);
    jPurifyBtn = NuiHeight(jPurifyBtn, fBtnH);
    jPurifyBtn = NuiTooltip(jPurifyBtn, JsonString("Oczyszcza skalanie — zuzywa swiecona wode (bcn_holy_water)"));

    json jActRow = JsonArray();
    jActRow = JsonArrayInsert(jActRow, jKindleBtn);
    jActRow = JsonArrayInsert(jActRow, NuiSpacer());
    jActRow = JsonArrayInsert(jActRow, jRestBtn);
    jActRow = JsonArrayInsert(jActRow, NuiSpacer());
    jActRow = JsonArrayInsert(jActRow, jPurifyBtn);

    // ---- Known beacons list header ----
    json jKnHdr = NuiLabel(JsonString("Znane latarnie:"),
        JsonInt(NUI_HALIGN_LEFT), JsonInt(NUI_VALIGN_MIDDLE));
    jKnHdr = NuiHeight(jKnHdr, fRowH);

    // ---- Known list template: type(70) | area(170) | status+rests(elastic) ----
    float fKnTypeW = GetNuiScaleDimension(oPC, 70.0);
    float fKnAreaW = GetNuiScaleDimension(oPC, 170.0);

    json jKnTypeLbl = NuiLabel(NuiBind(BCN_BIND_KNOWN_TYPE),
        JsonInt(NUI_HALIGN_LEFT), JsonInt(NUI_VALIGN_MIDDLE));
    jKnTypeLbl = NuiStyleForegroundColor(jKnTypeLbl, NuiBind(BCN_BIND_KNOWN_COL));

    json jKnAreaLbl = NuiLabel(NuiBind(BCN_BIND_KNOWN_AREA),
        JsonInt(NUI_HALIGN_LEFT), JsonInt(NUI_VALIGN_MIDDLE));

    json jKnStLbl = NuiLabel(NuiBind(BCN_BIND_KNOWN_ST),
        JsonInt(NUI_HALIGN_LEFT), JsonInt(NUI_VALIGN_MIDDLE));
    jKnStLbl = NuiStyleForegroundColor(jKnStLbl, NuiBind(BCN_BIND_KNOWN_COL));

    // Wrap row in a group so the whole row is a single NuiListTemplateCell
    json jRowInner = JsonArray();
    jRowInner = JsonArrayInsert(jRowInner, NuiWidth(jKnTypeLbl, fKnTypeW));
    jRowInner = JsonArrayInsert(jRowInner, NuiWidth(jKnAreaLbl, fKnAreaW));
    jRowInner = JsonArrayInsert(jRowInner, jKnStLbl);

    json jRowWidget = NuiGroup(NuiRow(jRowInner), TRUE, NUI_SCROLLBARS_NONE);
    jRowWidget = NuiId(jRowWidget, BCN_BTN_KNOWN_ROW);
    jRowWidget = NuiEncouraged(jRowWidget, NuiBind(BCN_BIND_KNOWN_ENC));

    json jKnTmpl = JsonArrayInsert(JsonArray(),
        NuiListTemplateCell(jRowWidget, 0.0, TRUE));
    json jKnList = NuiList(jKnTmpl, NuiBind(BCN_BIND_KNOWN_CNT), fRowH);
    jKnList = NuiHeight(jKnList, fListH);

    // ---- Assemble main column ----
    json jCol = JsonArray();
    jCol = JsonArrayInsert(jCol, NuiRow(jTitleRow));
    jCol = JsonArrayInsert(jCol, NuiRow(JsonArrayInsert(JsonArray(), jStatusLbl)));
    jCol = JsonArrayInsert(jCol, NuiRow(JsonArrayInsert(JsonArray(), jKindlerLbl)));
    jCol = JsonArrayInsert(jCol, NuiRow(JsonArrayInsert(JsonArray(), jBuffLbl)));
    jCol = JsonArrayInsert(jCol, NuiRow(JsonArrayInsert(JsonArray(), jFuelLbl)));
    jCol = JsonArrayInsert(jCol, NuiRow(JsonArrayInsert(JsonArray(), jCooldownLbl)));
    jCol = JsonArrayInsert(jCol, NuiRow(jActRow));
    jCol = JsonArrayInsert(jCol, NuiRow(JsonArrayInsert(JsonArray(), jKnHdr)));
    jCol = JsonArrayInsert(jCol, jKnList);

    // Side spacers keep content centered
    float fContentW = GetNuiScaleDimension(oPC, 460.0);
    json jSide = NuiCol(JsonArrayInsert(JsonArray(), NuiSpacer()));
    json jMainRow = JsonArray();
    jMainRow = JsonArrayInsert(jMainRow, jSide);
    jMainRow = JsonArrayInsert(jMainRow, NuiWidth(NuiCol(jCol), fContentW));
    jMainRow = JsonArrayInsert(jMainRow, jSide);
    return NuiRow(jMainRow);
}

// ----------------------------------------------------------------
// Window create / reuse
// ----------------------------------------------------------------

void BcnOpenWindow(object oPC, object oBeacon)
{
    string sTag  = GetTag(oBeacon);
    string sType = GetLocalString(oBeacon, BCN_VAR_TYPE);
    string sArea = GetName(GetArea(oBeacon));
    if(sType == "") sType = BCN_TYPE_FIRE;

    BcnEnsureRecord(sTag, sArea, sType);
    BcnLearnBeacon(GetObjectUUID(oPC), sTag);
    SetLocalObject(oPC, BCN_LVAR_BEACON_OBJ, oBeacon);

    int nToken = NuiFindWindow(oPC, BCN_WINDOW);
    if(nToken != 0)
    {
        // Window already open — just refresh data
        BcnFeedStatus(oPC, nToken, oBeacon);
        BcnFeedKnownList(oPC, nToken);
        return;
    }

    float fCX = (IntToFloat(GetPlayerDeviceProperty(oPC, PLAYER_DEVICE_PROPERTY_GUI_WIDTH))
                    - GetNuiScaleDimension(oPC, BCN_W)) / 2.0;
    float fCY = (IntToFloat(GetPlayerDeviceProperty(oPC, PLAYER_DEVICE_PROPERTY_GUI_HEIGHT))
                    - GetNuiScaleDimension(oPC, BCN_H)) / 2.0;
    json jGeom = NuiRect(fCX, fCY,
        GetNuiScaleDimension(oPC, BCN_W),
        GetNuiScaleDimension(oPC, BCN_H));

    json jLayout = BcnBuildLayout(oPC);
    json jWin = NuiWindow(jLayout,
        JsonBool(FALSE),
        NuiBind(BCN_WIN_GEOM),
        JsonBool(FALSE),
        JsonBool(FALSE),
        JsonBool(FALSE),
        JsonBool(TRUE),
        JsonBool(FALSE));

    nToken = NuiCreate(oPC, jWin, BCN_WINDOW, BCN_EV_SCRIPT);
    NuiSetBind(oPC, nToken, BCN_WIN_GEOM, jGeom);

    BcnFeedStatus(oPC, nToken, oBeacon);
    BcnFeedKnownList(oPC, nToken);
}
