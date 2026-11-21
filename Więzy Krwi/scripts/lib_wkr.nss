#include "lib_wkr_def"
#include "sql_wkr"

// ----------------------------------------------------------------
// Text helpers
// ----------------------------------------------------------------

string WkrTypeName(int nType)
{
    switch(nType)
    {
        case WKR_TYPE_DEBT:  return "Dług Krwi";
        case WKR_TYPE_OATH:  return "Przysięga Krwi";
        case WKR_TYPE_GUARD: return "Straż Krwi";
    }
    return "—";
}

string WkrStatusText(int nSt)
{
    switch(nSt)
    {
        case WKR_STATUS_PENDING:   return "Oczekuje";
        case WKR_STATUS_ACTIVE:    return "Aktywny";
        case WKR_STATUS_VIOLATED:  return "Naruszony";
        case WKR_STATUS_FULFILLED: return "Wypełniony";
        case WKR_STATUS_DISSOLVED: return "Rozwiązany";
    }
    return "—";
}

json WkrStatusColor(int nSt)
{
    switch(nSt)
    {
        case WKR_STATUS_PENDING:   return NuiColor(200, 200,  80);
        case WKR_STATUS_ACTIVE:    return NuiColor( 80, 200,  80);
        case WKR_STATUS_VIOLATED:  return NuiColor(220,  60,  60);
        case WKR_STATUS_FULFILLED: return NuiColor(100, 160, 220);
        case WKR_STATUS_DISSOLVED: return NuiColor(140, 140, 140);
    }
    return NuiColor(255, 255, 255);
}

int WkrIsInit(object oPC, json jBond)
{
    return JsonGetString(JsonObjectGet(jBond, "initiator_uuid")) == GetObjectUUID(oPC);
}

string WkrPartnerName(object oPC, json jBond)
{
    if(WkrIsInit(oPC, jBond))
        return JsonGetString(JsonObjectGet(jBond, "partner_name"));
    return JsonGetString(JsonObjectGet(jBond, "initiator_name"));
}

string WkrPartnerUuid(object oPC, json jBond)
{
    if(WkrIsInit(oPC, jBond))
        return JsonGetString(JsonObjectGet(jBond, "partner_uuid"));
    return JsonGetString(JsonObjectGet(jBond, "initiator_uuid"));
}

string WkrTermsSummary(object oPC, json jBond)
{
    int nType    = JsonGetInt(JsonObjectGet(jBond, "bond_type"));
    json jTerms  = JsonParse(JsonGetString(JsonObjectGet(jBond, "terms_json")));
    int nExpires = JsonGetInt(JsonObjectGet(jBond, "expires_at"));

    switch(nType)
    {
        case WKR_TYPE_DEBT:
        {
            int nGold = JsonGetInt(JsonObjectGet(jTerms, "gold"));
            string sExp = nExpires > 0 ? WkrFormatTs(nExpires) : "bezterminowo";
            string sRole = WkrIsInit(oPC, jBond) ? "Dłużnik" : "Wierzyciel";
            return sRole + " — " + IntToString(nGold) + " gp — termin: " + sExp;
        }
        case WKR_TYPE_OATH:
            return "Bliskość: +1 do rzutów obronnych. Zdrada: klątwa KON/MĄD.";
        case WKR_TYPE_GUARD:
        {
            string sInitRole = JsonGetString(JsonObjectGet(jTerms, "init_role"));
            string sMyRole   = WkrIsInit(oPC, jBond) ? sInitRole : (sInitRole == "guard" ? "ward" : "guard");
            return sMyRole == "guard" ? "Twoja rola: Strażnik (+2 KP blisko)." : "Twoja rola: Podopieczny (−3 obrażeń blisko).";
        }
    }
    return "";
}

// ----------------------------------------------------------------
// Effects
// ----------------------------------------------------------------

void WkrApplyCurse(object oTarget, int nType, int nId)
{
    string sTag = WKR_FX_CURSE + IntToString(nId);
    effect eCurse;
    switch(nType)
    {
        case WKR_TYPE_DEBT:
            eCurse = EffectAbilityDecrease(ABILITY_CHARISMA, 4);
            break;
        case WKR_TYPE_OATH:
            eCurse = EffectLinkEffects(
                EffectAbilityDecrease(ABILITY_CONSTITUTION, 3),
                EffectAbilityDecrease(ABILITY_WISDOM, 3));
            break;
        case WKR_TYPE_GUARD:
            eCurse = EffectLinkEffects(
                EffectAbilityDecrease(ABILITY_DEXTERITY, 2),
                EffectAbilityDecrease(ABILITY_STRENGTH, 2));
            break;
        default:
            eCurse = EffectAbilityDecrease(ABILITY_CHARISMA, 2);
    }
    eCurse = TagEffect(eCurse, sTag);
    eCurse = ExtraordinaryEffect(eCurse);
    ApplyEffectToObject(DURATION_TYPE_PERMANENT, eCurse, oTarget);
    ApplyEffectToObject(DURATION_TYPE_INSTANT, EffectVisualEffect(VFX_IMP_DOOM), oTarget);
    FloatingTextStringOnCreature("Krwiste więzy pękają — klątwa spada na ciebie!", oTarget, FALSE);
}

void WkrRemoveCurse(object oTarget, int nId)
{
    string sTag = WKR_FX_CURSE + IntToString(nId);
    effect eEff = GetFirstEffect(oTarget);
    while(GetIsEffectValid(eEff))
    {
        if(GetEffectTag(eEff) == sTag) RemoveEffect(oTarget, eEff);
        eEff = GetNextEffect(oTarget);
    }
}

void WkrRemoveProxFx(object oTarget, int nId)
{
    string sTag = WKR_FX_PROX + IntToString(nId);
    effect eEff = GetFirstEffect(oTarget);
    while(GetIsEffectValid(eEff))
    {
        if(GetEffectTag(eEff) == sTag) RemoveEffect(oTarget, eEff);
        eEff = GetNextEffect(oTarget);
    }
}

int WkrHasProxFx(object oTarget, int nId)
{
    string sTag = WKR_FX_PROX + IntToString(nId);
    effect eEff = GetFirstEffect(oTarget);
    while(GetIsEffectValid(eEff))
    {
        if(GetEffectTag(eEff) == sTag) return TRUE;
        eEff = GetNextEffect(oTarget);
    }
    return FALSE;
}

// ----------------------------------------------------------------
// Heartbeat logic
// ----------------------------------------------------------------

// Searches online PCs for a given UUID; returns OBJECT_INVALID if offline.
object WkrFindPC(string sUuid)
{
    object oPC = GetFirstPC();
    while(GetIsObjectValid(oPC))
    {
        if(GetObjectUUID(oPC) == sUuid) return oPC;
        oPC = GetNextPC();
    }
    return OBJECT_INVALID;
}

void WkrUpdateProximityForPC(object oPC)
{
    string sUuid = GetObjectUUID(oPC);
    json jBonds  = WkrGetBonds(sUuid);
    int nCount   = JsonGetLength(jBonds);
    int i;

    for(i = 0; i < nCount; i++)
    {
        json jBond = JsonArrayGet(jBonds, i);
        int nSt    = JsonGetInt(JsonObjectGet(jBond, "status"));
        if(nSt != WKR_STATUS_ACTIVE) continue;

        int nType = JsonGetInt(JsonObjectGet(jBond, "bond_type"));
        if(nType != WKR_TYPE_OATH && nType != WKR_TYPE_GUARD) continue;

        int nId    = JsonGetInt(JsonObjectGet(jBond, "id"));
        string sPartUuid = WkrPartnerUuid(oPC, jBond);
        object oPartner  = WkrFindPC(sPartUuid);

        int bNear = GetIsObjectValid(oPartner)
                 && GetArea(oPC) == GetArea(oPartner)
                 && GetDistanceBetween(oPC, oPartner) <= WKR_PROXIMITY_DIST;

        int bHas = WkrHasProxFx(oPC, nId);

        if(bNear && !bHas)
        {
            effect eBonus;
            string sTag = WKR_FX_PROX + IntToString(nId);

            if(nType == WKR_TYPE_OATH)
            {
                eBonus = EffectSavingThrowIncrease(SAVING_THROW_ALL, 1, SAVING_THROW_TYPE_ALL);
            }
            else
            {
                json jTerms  = JsonParse(JsonGetString(JsonObjectGet(jBond, "terms_json")));
                string sInitR = JsonGetString(JsonObjectGet(jTerms, "init_role"));
                string sMyR   = WkrIsInit(oPC, jBond) ? sInitR : (sInitR == "guard" ? "ward" : "guard");

                if(sMyR == "guard")
                    eBonus = EffectACIncrease(2, AC_DODGE_BONUS, AC_VS_DAMAGE_TYPE_ALL);
                else
                    eBonus = EffectDamageReduction(3, DAMAGE_POWER_PLUS_ONE, 0);
            }

            eBonus = TagEffect(eBonus, WKR_FX_PROX + IntToString(nId));
            eBonus = SupernaturalEffect(eBonus);
            ApplyEffectToObject(DURATION_TYPE_PERMANENT, eBonus, oPC);
        }
        else if(!bNear && bHas)
        {
            WkrRemoveProxFx(oPC, nId);
        }
    }
}

void WkrCheckOverdueDebts()
{
    json jOverdue = WkrGetOverdueDebts();
    int nCount    = JsonGetLength(jOverdue);
    int i;

    for(i = 0; i < nCount; i++)
    {
        json   jRow      = JsonArrayGet(jOverdue, i);
        int    nId       = JsonGetInt(JsonObjectGet(jRow, "id"));
        string sDebtor   = JsonGetString(JsonObjectGet(jRow, "initiator_uuid"));
        string sDebtorN  = JsonGetString(JsonObjectGet(jRow, "initiator_name"));
        string sCreditor = JsonGetString(JsonObjectGet(jRow, "partner_uuid"));

        WkrSetStatus(nId, WKR_STATUS_VIOLATED);

        object oDebtor = WkrFindPC(sDebtor);
        if(GetIsObjectValid(oDebtor))
            WkrApplyCurse(oDebtor, WKR_TYPE_DEBT, nId);

        object oCreditor = WkrFindPC(sCreditor);
        if(GetIsObjectValid(oCreditor))
            SendMessageToPC(oCreditor,
                "[Więzy Krwi] " + sDebtorN + " nie spłacił długu — klątwa spada na dłużnika.");
    }
}

// Restores curse effects for a PC logging in (curse may have been applied while offline).
void WkrRestoreOnEnter(object oPC)
{
    string sUuid  = GetObjectUUID(oPC);
    json jBonds   = WkrGetBonds(sUuid);
    int nCount    = JsonGetLength(jBonds);
    int i;

    for(i = 0; i < nCount; i++)
    {
        json jBond  = JsonArrayGet(jBonds, i);
        int nSt     = JsonGetInt(JsonObjectGet(jBond, "status"));
        int nId     = JsonGetInt(JsonObjectGet(jBond, "id"));
        int nType   = JsonGetInt(JsonObjectGet(jBond, "bond_type"));
        int bIsInit = WkrIsInit(oPC, jBond);

        // Re-apply curse if this PC was the violator (debtor for debt, either for oath/guard).
        if(nSt == WKR_STATUS_VIOLATED)
        {
            // Only the initiator is the debtor for DEBT type.
            // For OATH/GUARD violation the status gets set on the PC who betrayed,
            // but we store violation globally. Re-apply to this PC conservatively
            // — let a DM remove manually if needed.
            if(nType == WKR_TYPE_DEBT && bIsInit)
                WkrApplyCurse(oPC, nType, nId);
            else if(nType != WKR_TYPE_DEBT)
                WkrApplyCurse(oPC, nType, nId);
        }
    }

    // Check for pending invite stored offline via LVAR — inform player.
    int nPendId = GetLocalInt(oPC, WKR_LVAR_PEND_ID);
    if(nPendId > 0)
    {
        string sFrom = GetLocalString(oPC, WKR_LVAR_PEND_FROM);
        SendMessageToPC(oPC,
            "[Więzy Krwi] Czeka na ciebie zaproszenie od: " + sFrom +
            ". Otwórz okno Więzy Krwi → Zaproś, aby odpowiedzieć.");
    }
}

// ----------------------------------------------------------------
// NUI — Window builder
// ----------------------------------------------------------------

json WkrBuildWindow(object oPC)
{
    // ---- Tab row ----
    json jTabs = JsonArray();
    jTabs = JsonArrayInsert(jTabs,
        NuiButton(JsonString("Aktywne więzi"), WKR_BTN_TAB_LIST));
    jTabs = JsonArrayInsert(jTabs,
        NuiButton(JsonString("Zaproś do więzi"), WKR_BTN_TAB_INV));
    json jTabRow = NuiRow(jTabs);

    // ============================
    // LIST VIEW
    // ============================
    // Header
    json jLHdr = JsonArray();
    jLHdr = JsonArrayInsert(jLHdr,
        NuiLabel(JsonString("Partner"), JsonInt(NUI_HALIGN_LEFT), JsonInt(NUI_VALIGN_MIDDLE)));
    jLHdr = JsonArrayInsert(jLHdr,
        NuiWidth(NuiLabel(JsonString("Rodzaj / Status"), JsonInt(NUI_HALIGN_CENTER), JsonInt(NUI_VALIGN_MIDDLE)), 170.0));
    json jListHdrRow = NuiRow(jLHdr);

    // List rows template
    json jColName = NuiListTemplateCell(
        NuiLabel(NuiBind(WKR_BIND_ROW_NAME), JsonInt(NUI_HALIGN_LEFT), JsonInt(NUI_VALIGN_MIDDLE)),
        0.0, TRUE);
    json jColInfo = NuiListTemplateCell(
        NuiButtonSelect(NuiBind(WKR_BIND_ROW_INFO), WKR_BTN_ROW, NuiBind(WKR_BIND_ROW_ENC)),
        170.0, FALSE);
    json jTemplate = JsonArray();
    jTemplate = JsonArrayInsert(jTemplate, jColName);
    jTemplate = JsonArrayInsert(jTemplate, jColInfo);

    json jList = NuiList(jTemplate, NuiBind(WKR_BIND_ROW_COUNT), 28.0);
    jList = NuiHeight(jList, 150.0);
    jList = NuiScrollbars(jList, NUI_SCROLLBARS_Y);

    // Detail panel
    json jDtlCols = JsonArray();

    json jDtlHdr = NuiForegroundColor(
        NuiLabel(NuiBind(WKR_BIND_DTL_HDR), JsonInt(NUI_HALIGN_LEFT), JsonInt(NUI_VALIGN_MIDDLE)),
        NuiColor(220, 160, 80));

    json jRowPar = JsonArray();
    jRowPar = JsonArrayInsert(jRowPar,
        NuiWidth(NuiLabel(JsonString("Partner:"), JsonInt(NUI_HALIGN_LEFT), JsonInt(NUI_VALIGN_MIDDLE)), 90.0));
    jRowPar = JsonArrayInsert(jRowPar,
        NuiLabel(NuiBind(WKR_BIND_DTL_PAR), JsonInt(NUI_HALIGN_LEFT), JsonInt(NUI_VALIGN_MIDDLE)));

    json jRowTerms = JsonArray();
    jRowTerms = JsonArrayInsert(jRowTerms,
        NuiWidth(NuiLabel(JsonString("Warunki:"), JsonInt(NUI_HALIGN_LEFT), JsonInt(NUI_VALIGN_MIDDLE)), 90.0));
    jRowTerms = JsonArrayInsert(jRowTerms,
        NuiLabel(NuiBind(WKR_BIND_DTL_TERMS), JsonInt(NUI_HALIGN_LEFT), JsonInt(NUI_VALIGN_MIDDLE)));

    json jRowSt = JsonArray();
    jRowSt = JsonArrayInsert(jRowSt,
        NuiWidth(NuiLabel(JsonString("Status:"), JsonInt(NUI_HALIGN_LEFT), JsonInt(NUI_VALIGN_MIDDLE)), 90.0));
    json jStLbl = NuiForegroundColor(
        NuiLabel(NuiBind(WKR_BIND_DTL_ST), JsonInt(NUI_HALIGN_LEFT), JsonInt(NUI_VALIGN_MIDDLE)),
        NuiBind(WKR_BIND_DTL_ST_COL));
    jRowSt = JsonArrayInsert(jRowSt, jStLbl);

    json jRowExp = JsonArray();
    jRowExp = JsonArrayInsert(jRowExp,
        NuiWidth(NuiLabel(JsonString("Termin:"), JsonInt(NUI_HALIGN_LEFT), JsonInt(NUI_VALIGN_MIDDLE)), 90.0));
    jRowExp = JsonArrayInsert(jRowExp,
        NuiLabel(NuiBind(WKR_BIND_DTL_EXP), JsonInt(NUI_HALIGN_LEFT), JsonInt(NUI_VALIGN_MIDDLE)));

    json jDtlBtns = JsonArray();
    jDtlBtns = JsonArrayInsert(jDtlBtns,
        NuiEnabled(NuiButton(NuiBind(WKR_BIND_PAY_LBL), WKR_BTN_PAY), NuiBind(WKR_BIND_PAY_ENA)));
    jDtlBtns = JsonArrayInsert(jDtlBtns,
        NuiEnabled(NuiButton(JsonString("Rozwiąż"), WKR_BTN_DISSOLVE), NuiBind(WKR_BIND_DISS_ENA)));

    jDtlCols = JsonArrayInsert(jDtlCols, NuiSpacer());
    jDtlCols = JsonArrayInsert(jDtlCols, jDtlHdr);
    jDtlCols = JsonArrayInsert(jDtlCols, NuiRow(jRowPar));
    jDtlCols = JsonArrayInsert(jDtlCols, NuiRow(jRowTerms));
    jDtlCols = JsonArrayInsert(jDtlCols, NuiRow(jRowSt));
    jDtlCols = JsonArrayInsert(jDtlCols, NuiRow(jRowExp));
    jDtlCols = JsonArrayInsert(jDtlCols, NuiRow(jDtlBtns));

    json jDetailGroup = NuiGroup(NuiCol(jDtlCols), TRUE, NUI_SCROLLBARS_NONE);
    jDetailGroup = NuiHeight(jDetailGroup, 185.0);
    jDetailGroup = NuiVisible(jDetailGroup, NuiBind(WKR_BIND_DTL_VIS));

    json jListCols = JsonArray();
    jListCols = JsonArrayInsert(jListCols, jListHdrRow);
    jListCols = JsonArrayInsert(jListCols, jList);
    jListCols = JsonArrayInsert(jListCols, jDetailGroup);
    json jListView = NuiVisible(NuiGroup(NuiCol(jListCols), FALSE, NUI_SCROLLBARS_NONE), NuiBind(WKR_BIND_VIS_LIST));

    // ============================
    // INVITE VIEW
    // ============================
    json jInvCols = JsonArray();

    // Type selector
    json jTypeHdr = NuiForegroundColor(
        NuiLabel(JsonString("Rodzaj więzi:"), JsonInt(NUI_HALIGN_LEFT), JsonInt(NUI_VALIGN_MIDDLE)),
        NuiColor(200, 160, 100));
    jInvCols = JsonArrayInsert(jInvCols, jTypeHdr);

    json jTypeBtns = JsonArray();
    jTypeBtns = JsonArrayInsert(jTypeBtns,
        NuiButtonSelect(JsonString("Dług Krwi"), WKR_BTN_TYPE_DEBT, NuiBind(WKR_BIND_T1_SEL)));
    jTypeBtns = JsonArrayInsert(jTypeBtns,
        NuiButtonSelect(JsonString("Przysięga"), WKR_BTN_TYPE_OATH, NuiBind(WKR_BIND_T2_SEL)));
    jTypeBtns = JsonArrayInsert(jTypeBtns,
        NuiButtonSelect(JsonString("Straż Krwi"), WKR_BTN_TYPE_GUARD, NuiBind(WKR_BIND_T3_SEL)));
    jInvCols = JsonArrayInsert(jInvCols, NuiRow(jTypeBtns));

    json jTypeDesc = NuiHeight(NuiForegroundColor(
        NuiLabel(NuiBind(WKR_BIND_TYPE_DESC), JsonInt(NUI_HALIGN_LEFT), JsonInt(NUI_VALIGN_TOP)),
        NuiColor(160, 160, 160)), 36.0);
    jInvCols = JsonArrayInsert(jInvCols, jTypeDesc);

    // Gold input (shown for DEBT only)
    json jGoldRow = JsonArray();
    jGoldRow = JsonArrayInsert(jGoldRow,
        NuiWidth(NuiLabel(JsonString("Kwota (gp):"), JsonInt(NUI_HALIGN_LEFT), JsonInt(NUI_VALIGN_MIDDLE)), 110.0));
    jGoldRow = JsonArrayInsert(jGoldRow, NuiTextEdit(JsonString(""), WKR_BIND_GOLD_TXT, 8, FALSE));
    json jGoldGroup = NuiVisible(NuiGroup(NuiRow(jGoldRow), FALSE, NUI_SCROLLBARS_NONE), NuiBind(WKR_BIND_SHOW_GOLD));
    jInvCols = JsonArrayInsert(jInvCols, jGoldGroup);

    // Role selector (shown for GUARD only)
    json jRoleRow = JsonArray();
    jRoleRow = JsonArrayInsert(jRoleRow,
        NuiWidth(NuiLabel(JsonString("Twoja rola:"), JsonInt(NUI_HALIGN_LEFT), JsonInt(NUI_VALIGN_MIDDLE)), 110.0));
    jRoleRow = JsonArrayInsert(jRoleRow,
        NuiButtonSelect(JsonString("Strażnik"), WKR_BTN_ROLE_GUARD, NuiBind(WKR_BIND_ROLE_G)));
    jRoleRow = JsonArrayInsert(jRoleRow,
        NuiButtonSelect(JsonString("Podopieczny"), WKR_BTN_ROLE_WARD, NuiBind(WKR_BIND_ROLE_W)));
    json jRoleGroup = NuiVisible(NuiGroup(NuiRow(jRoleRow), FALSE, NUI_SCROLLBARS_NONE), NuiBind(WKR_BIND_SHOW_ROLE));
    jInvCols = JsonArrayInsert(jInvCols, jRoleGroup);

    // Partner row
    json jPartRow = JsonArray();
    jPartRow = JsonArrayInsert(jPartRow,
        NuiWidth(NuiLabel(JsonString("Partner:"), JsonInt(NUI_HALIGN_LEFT), JsonInt(NUI_VALIGN_MIDDLE)), 110.0));
    jPartRow = JsonArrayInsert(jPartRow,
        NuiLabel(NuiBind(WKR_BIND_PNAME), JsonInt(NUI_HALIGN_LEFT), JsonInt(NUI_VALIGN_MIDDLE)));
    jPartRow = JsonArrayInsert(jPartRow,
        NuiWidth(NuiButton(JsonString("Wskaż ↗"), WKR_BTN_PICK), 90.0));
    jInvCols = JsonArrayInsert(jInvCols, NuiRow(jPartRow));

    json jHpNote = NuiForegroundColor(
        NuiLabel(JsonString("Zapieczętowanie kosztuje " + IntToString(WKR_SEAL_HP_COST) + " PŻ z obu stron."),
            JsonInt(NUI_HALIGN_LEFT), JsonInt(NUI_VALIGN_MIDDLE)),
        NuiColor(200, 100, 100));
    jInvCols = JsonArrayInsert(jInvCols, jHpNote);

    jInvCols = JsonArrayInsert(jInvCols,
        NuiEnabled(NuiButton(JsonString("⚔  Zapieczętuj więź  (−" + IntToString(WKR_SEAL_HP_COST) + " PŻ)"), WKR_BTN_SEAL),
            NuiBind(WKR_BIND_SEAL_ENA)));

    json jPendLbl = NuiForegroundColor(
        NuiLabel(NuiBind(WKR_BIND_PEND_LBL), JsonInt(NUI_HALIGN_LEFT), JsonInt(NUI_VALIGN_MIDDLE)),
        NuiColor(200, 180, 80));
    jInvCols = JsonArrayInsert(jInvCols, jPendLbl);

    jInvCols = JsonArrayInsert(jInvCols,
        NuiEnabled(NuiButton(JsonString("✓  Przyjmij zaproszenie  (−" + IntToString(WKR_SEAL_HP_COST) + " PŻ)"), WKR_BTN_ACCEPT),
            NuiBind(WKR_BIND_ACC_ENA)));

    json jInvView = NuiVisible(NuiGroup(NuiCol(jInvCols), FALSE, NUI_SCROLLBARS_NONE), NuiBind(WKR_BIND_VIS_INV));

    // ============================
    // ROOT
    // ============================
    json jRoot = JsonArray();
    jRoot = JsonArrayInsert(jRoot, jTabRow);
    jRoot = JsonArrayInsert(jRoot, jListView);
    jRoot = JsonArrayInsert(jRoot, jInvView);
    jRoot = JsonArrayInsert(jRoot, NuiButton(JsonString("Zamknij"), WKR_BTN_CLOSE));

    return NuiWindow(NuiCol(jRoot), JsonString("⚔  Więzy Krwi"),
        NuiBind(WINDOW_GEOMETRY), JsonBool(FALSE), JsonBool(FALSE),
        JsonBool(TRUE), JsonBool(FALSE), JsonBool(TRUE));
}

// ----------------------------------------------------------------
// Feed helpers (called after open and after data changes)
// ----------------------------------------------------------------

void WkrFeedList(object oPC, int nToken)
{
    json jBonds = WkrGetBonds(GetObjectUUID(oPC));
    SetLocalJson(oPC, WKR_LVAR_BONDS_JSON, jBonds);

    int nCount = JsonGetLength(jBonds);
    json jNames = JsonArray();
    json jInfos = JsonArray();
    json jEncs  = JsonArray();
    int nSelId  = GetLocalInt(oPC, WKR_LVAR_SEL_ID);
    int i;

    for(i = 0; i < nCount; i++)
    {
        json jB     = JsonArrayGet(jBonds, i);
        int nId     = JsonGetInt(JsonObjectGet(jB, "id"));
        int nType   = JsonGetInt(JsonObjectGet(jB, "bond_type"));
        int nSt     = JsonGetInt(JsonObjectGet(jB, "status"));
        string sPar = WkrPartnerName(oPC, jB);

        jNames = JsonArrayInsert(jNames, JsonString(sPar));
        jInfos = JsonArrayInsert(jInfos,
            JsonString(WkrTypeName(nType) + " — " + WkrStatusText(nSt)));
        jEncs  = JsonArrayInsert(jEncs, JsonBool(nId == nSelId));
    }

    NuiSetBind(oPC, nToken, WKR_BIND_ROW_NAME,  jNames);
    NuiSetBind(oPC, nToken, WKR_BIND_ROW_INFO,  jInfos);
    NuiSetBind(oPC, nToken, WKR_BIND_ROW_ENC,   jEncs);
    NuiSetBind(oPC, nToken, WKR_BIND_ROW_COUNT, JsonInt(nCount));
}

void WkrFeedDetail(object oPC, int nToken, int nId)
{
    if(nId <= 0)
    {
        NuiSetBind(oPC, nToken, WKR_BIND_DTL_VIS, JsonBool(FALSE));
        return;
    }
    json jBond = WkrGetBond(nId);
    if(JsonGetType(jBond) == JSON_TYPE_NULL)
    {
        NuiSetBind(oPC, nToken, WKR_BIND_DTL_VIS, JsonBool(FALSE));
        return;
    }

    int nType   = JsonGetInt(JsonObjectGet(jBond, "bond_type"));
    int nSt     = JsonGetInt(JsonObjectGet(jBond, "status"));
    int nExp    = JsonGetInt(JsonObjectGet(jBond, "expires_at"));
    string sPar = WkrPartnerName(oPC, jBond);

    NuiSetBind(oPC, nToken, WKR_BIND_DTL_VIS,    JsonBool(TRUE));
    NuiSetBind(oPC, nToken, WKR_BIND_DTL_HDR,    JsonString(WkrTypeName(nType)));
    NuiSetBind(oPC, nToken, WKR_BIND_DTL_PAR,    JsonString(sPar));
    NuiSetBind(oPC, nToken, WKR_BIND_DTL_TERMS,  JsonString(WkrTermsSummary(oPC, jBond)));
    NuiSetBind(oPC, nToken, WKR_BIND_DTL_ST,     JsonString(WkrStatusText(nSt)));
    NuiSetBind(oPC, nToken, WKR_BIND_DTL_ST_COL, WkrStatusColor(nSt));
    NuiSetBind(oPC, nToken, WKR_BIND_DTL_EXP,
        JsonString(nExp > 0 ? WkrFormatTs(nExp) : "—"));

    int bIsInit = WkrIsInit(oPC, jBond);
    json jTerms = JsonParse(JsonGetString(JsonObjectGet(jBond, "terms_json")));
    int nDebt   = JsonGetInt(JsonObjectGet(jTerms, "gold"));
    int bDebtMine = nType == WKR_TYPE_DEBT && bIsInit;
    int bCanPay   = bDebtMine && (nSt == WKR_STATUS_ACTIVE || nSt == WKR_STATUS_VIOLATED)
                 && GetGold(oPC) >= nDebt && nDebt > 0;
    NuiSetBind(oPC, nToken, WKR_BIND_PAY_ENA, JsonBool(bCanPay));
    NuiSetBind(oPC, nToken, WKR_BIND_PAY_LBL,
        JsonString("Spłać dług (" + IntToString(nDebt) + " gp)"));

    int bCanDiss = nSt == WKR_STATUS_ACTIVE || nSt == WKR_STATUS_PENDING;
    NuiSetBind(oPC, nToken, WKR_BIND_DISS_ENA, JsonBool(bCanDiss));
}

void WkrShowListView(object oPC, int nToken)
{
    NuiSetBind(oPC, nToken, WKR_BIND_VIS_LIST, JsonBool(TRUE));
    NuiSetBind(oPC, nToken, WKR_BIND_VIS_INV,  JsonBool(FALSE));
    SetLocalInt(oPC, WKR_LVAR_VIEW, 0);
    WkrFeedList(oPC, nToken);
    WkrFeedDetail(oPC, nToken, GetLocalInt(oPC, WKR_LVAR_SEL_ID));
}

void WkrShowInviteView(object oPC, int nToken)
{
    NuiSetBind(oPC, nToken, WKR_BIND_VIS_LIST, JsonBool(FALSE));
    NuiSetBind(oPC, nToken, WKR_BIND_VIS_INV,  JsonBool(TRUE));
    SetLocalInt(oPC, WKR_LVAR_VIEW, 1);

    int nType = GetLocalInt(oPC, WKR_LVAR_INV_TYPE);
    if(nType == 0) nType = WKR_TYPE_DEBT;

    NuiSetBind(oPC, nToken, WKR_BIND_T1_SEL, JsonBool(nType == WKR_TYPE_DEBT));
    NuiSetBind(oPC, nToken, WKR_BIND_T2_SEL, JsonBool(nType == WKR_TYPE_OATH));
    NuiSetBind(oPC, nToken, WKR_BIND_T3_SEL, JsonBool(nType == WKR_TYPE_GUARD));
    NuiSetBind(oPC, nToken, WKR_BIND_SHOW_GOLD, JsonBool(nType == WKR_TYPE_DEBT));
    NuiSetBind(oPC, nToken, WKR_BIND_SHOW_ROLE, JsonBool(nType == WKR_TYPE_GUARD));

    string sDesc;
    switch(nType)
    {
        case WKR_TYPE_DEBT:
            sDesc = "Pożyczka. Niespłacona do terminu klnie dłużnika utratą 4 PKC.";
            break;
        case WKR_TYPE_OATH:
            sDesc = "Wzajemna przysięga. Bliskość +1 do obrony. Zdrada: −3 KON i MĄD.";
            break;
        case WKR_TYPE_GUARD:
            sDesc = "Strażnik zyska +2 KP, podopieczny −3 obrażeń, gdy stoją obok siebie.";
            break;
    }
    NuiSetBind(oPC, nToken, WKR_BIND_TYPE_DESC, JsonString(sDesc));

    string sPName = GetLocalString(oPC, WKR_LVAR_P_NAME);
    NuiSetBind(oPC, nToken, WKR_BIND_PNAME, JsonString(sPName == "" ? "(nie wybrano)" : sPName));

    int bCanSeal = sPName != "" && GetLocalString(oPC, WKR_LVAR_P_UUID) != "";
    NuiSetBind(oPC, nToken, WKR_BIND_SEAL_ENA, JsonBool(bCanSeal));

    // Pending invite
    int nPendId = GetLocalInt(oPC, WKR_LVAR_PEND_ID);
    string sPendFrom = GetLocalString(oPC, WKR_LVAR_PEND_FROM);
    NuiSetBind(oPC, nToken, WKR_BIND_PEND_LBL,
        JsonString(nPendId > 0 ? "Zaproszenie od: " + sPendFrom : ""));
    NuiSetBind(oPC, nToken, WKR_BIND_ACC_ENA, JsonBool(nPendId > 0));

    int bIsGuard = GetLocalInt(oPC, WKR_LVAR_IS_GUARD) != 0;
    NuiSetBind(oPC, nToken, WKR_BIND_ROLE_G, JsonBool(bIsGuard));
    NuiSetBind(oPC, nToken, WKR_BIND_ROLE_W, JsonBool(!bIsGuard));
}

// ----------------------------------------------------------------
// Window open / close
// ----------------------------------------------------------------

void WkrOpen(object oPC)
{
    int nToken = NuiFindWindow(oPC, WKR_WINDOW);
    if(nToken != 0)
    {
        WkrShowListView(oPC, nToken);
        return;
    }

    nToken = NuiCreate(oPC, WkrBuildWindow(oPC), WKR_WINDOW);
    if(nToken == 0) return;

    NuiSetBind(oPC, nToken, WINDOW_GEOMETRY, NuiRect(60.0, 60.0, 470.0, 540.0));

    WkrShowListView(oPC, nToken);
}

// ----------------------------------------------------------------
// Actions
// ----------------------------------------------------------------

void WkrOnPlayerTarget(object oPC)
{
    int nToken = NuiFindWindow(oPC, WKR_WINDOW);
    if(nToken == 0) return;

    object oTarget = GetTargetingModeSelectedObject();
    if(!GetIsObjectValid(oTarget) || !GetIsPC(oTarget) || oTarget == oPC)
    {
        SendMessageToPC(oPC, "[Więzy Krwi] Musisz wskazać innego gracza.");
        return;
    }

    string sUuid = GetObjectUUID(oTarget);
    string sName = GetName(oTarget);
    SetLocalString(oPC, WKR_LVAR_P_UUID, sUuid);
    SetLocalString(oPC, WKR_LVAR_P_NAME, sName);

    NuiSetBind(oPC, nToken, WKR_BIND_PNAME, JsonString(sName));
    NuiSetBind(oPC, nToken, WKR_BIND_SEAL_ENA, JsonBool(TRUE));
}

void WkrHandleSeal(object oPC, int nToken)
{
    string sMyUuid  = GetObjectUUID(oPC);
    string sMyName  = GetName(oPC);
    string sPUuid   = GetLocalString(oPC, WKR_LVAR_P_UUID);
    string sPName   = GetLocalString(oPC, WKR_LVAR_P_NAME);

    if(sPUuid == "")
    {
        SendMessageToPC(oPC, "[Więzy Krwi] Brak wybranego partnera.");
        return;
    }

    object oPartner = WkrFindPC(sPUuid);
    if(!GetIsObjectValid(oPartner))
    {
        SendMessageToPC(oPC, "[Więzy Krwi] Partner nie jest teraz w grze.");
        return;
    }

    if(WkrCountActive(sMyUuid) >= WKR_MAX_ACTIVE)
    {
        SendMessageToPC(oPC, "[Więzy Krwi] Masz już " + IntToString(WKR_MAX_ACTIVE) + " aktywnych więzi.");
        return;
    }

    int nType = GetLocalInt(oPC, WKR_LVAR_INV_TYPE);
    if(nType == 0) nType = WKR_TYPE_DEBT;

    json jTerms  = JsonObject();
    int nExpires = 0;

    if(nType == WKR_TYPE_DEBT)
    {
        string sGold = JsonGetString(NuiGetBind(oPC, nToken, WKR_BIND_GOLD_TXT));
        int nGold    = StringToInt(sGold);
        if(nGold <= 0)
        {
            SendMessageToPC(oPC, "[Więzy Krwi] Podaj dodatnią kwotę długu.");
            return;
        }
        jTerms   = JsonObjectSet(jTerms, "gold", JsonInt(nGold));
        nExpires = WkrNow() + WKR_DEBT_HOURS * 3600;
    }
    else if(nType == WKR_TYPE_GUARD)
    {
        int bIsGuard = GetLocalInt(oPC, WKR_LVAR_IS_GUARD) != 0;
        jTerms = JsonObjectSet(jTerms, "init_role", JsonString(bIsGuard ? "guard" : "ward"));
    }

    // HP cost
    if(GetCurrentHitPoints(oPC) <= WKR_SEAL_HP_COST)
    {
        SendMessageToPC(oPC, "[Więzy Krwi] Za mało PŻ, by przyłożyć pieczęć.");
        return;
    }
    ApplyEffectToObject(DURATION_TYPE_INSTANT,
        EffectDamage(WKR_SEAL_HP_COST, DAMAGE_TYPE_MAGICAL, DAMAGE_POWER_PLUS_ONE), oPC);
    ApplyEffectToObject(DURATION_TYPE_INSTANT, EffectVisualEffect(VFX_IMP_MAGICAL_VISION), oPC);

    int nId = WkrCreateBond(sMyUuid, sMyName, sPUuid, sPName, nType, JsonDump(jTerms), nExpires);
    if(nId == 0)
    {
        SendMessageToPC(oPC, "[Więzy Krwi] Błąd tworzenia więzi.");
        return;
    }

    SetLocalInt   (oPartner, WKR_LVAR_PEND_ID,   nId);
    SetLocalString(oPartner, WKR_LVAR_PEND_FROM,  sMyName);

    SendMessageToPC(oPartner,
        "[Więzy Krwi] " + sMyName + " proponuje ci więź: " + WkrTypeName(nType) +
        ". Otwórz okno Więzy Krwi → Zaproś, aby odpowiedzieć.");
    FloatingTextStringOnCreature("Krew wycieka z dłoni — więź oczekuje na odwzajemnienie…", oPC, FALSE);

    // Refresh partner's invite panel if open
    int nPToken = NuiFindWindow(oPartner, WKR_WINDOW);
    if(nPToken != 0 && GetLocalInt(oPartner, WKR_LVAR_VIEW) == 1)
        WkrShowInviteView(oPartner, nPToken);

    // Clear local state
    DeleteLocalString(oPC, WKR_LVAR_P_UUID);
    DeleteLocalString(oPC, WKR_LVAR_P_NAME);
    SetLocalInt(oPC, WKR_LVAR_INV_TYPE, 0);
    WkrShowListView(oPC, nToken);
}

void WkrHandleAccept(object oPC, int nToken)
{
    int nId = GetLocalInt(oPC, WKR_LVAR_PEND_ID);
    if(nId <= 0)
    {
        SendMessageToPC(oPC, "[Więzy Krwi] Brak aktywnego zaproszenia.");
        return;
    }

    if(GetCurrentHitPoints(oPC) <= WKR_SEAL_HP_COST)
    {
        SendMessageToPC(oPC, "[Więzy Krwi] Za mało PŻ, by przyłożyć pieczęć.");
        return;
    }
    ApplyEffectToObject(DURATION_TYPE_INSTANT,
        EffectDamage(WKR_SEAL_HP_COST, DAMAGE_TYPE_MAGICAL, DAMAGE_POWER_PLUS_ONE), oPC);
    ApplyEffectToObject(DURATION_TYPE_INSTANT, EffectVisualEffect(VFX_IMP_MAGICAL_VISION), oPC);

    WkrActivateBond(nId);
    DeleteLocalInt   (oPC, WKR_LVAR_PEND_ID);
    DeleteLocalString(oPC, WKR_LVAR_PEND_FROM);

    json jBond = WkrGetBond(nId);
    string sInitUuid = JsonGetString(JsonObjectGet(jBond, "initiator_uuid"));
    int nType        = JsonGetInt(JsonObjectGet(jBond, "bond_type"));

    object oInit = WkrFindPC(sInitUuid);
    if(GetIsObjectValid(oInit))
    {
        SendMessageToPC(oInit,
            "[Więzy Krwi] " + GetName(oPC) + " przyłożył pieczęć — więź " + WkrTypeName(nType) + " jest aktywna.");
        FloatingTextStringOnCreature("Pieczęć krwi pulsuje słabo — więź zawarta.", oInit, FALSE);
        int nIToken = NuiFindWindow(oInit, WKR_WINDOW);
        if(nIToken != 0)
            WkrShowListView(oInit, nIToken);
    }

    FloatingTextStringOnCreature("Pieczęć krwi pulsuje słabo — więź zawarta.", oPC, FALSE);
    ApplyEffectToObject(DURATION_TYPE_INSTANT, EffectVisualEffect(VFX_IMP_HOLY_AID), oPC);

    WkrShowListView(oPC, nToken);
}

void WkrHandlePay(object oPC, int nToken)
{
    int nId = GetLocalInt(oPC, WKR_LVAR_SEL_ID);
    if(nId <= 0) return;

    json jBond = WkrGetBond(nId);
    if(JsonGetType(jBond) == JSON_TYPE_NULL) return;

    int nType = JsonGetInt(JsonObjectGet(jBond, "bond_type"));
    if(nType != WKR_TYPE_DEBT || !WkrIsInit(oPC, jBond)) return;

    json jTerms  = JsonParse(JsonGetString(JsonObjectGet(jBond, "terms_json")));
    int nGold    = JsonGetInt(JsonObjectGet(jTerms, "gold"));
    if(GetGold(oPC) < nGold)
    {
        SendMessageToPC(oPC, "[Więzy Krwi] Niewystarczająca ilość złota.");
        return;
    }

    AssignCommand(oPC, TakeGoldFromCreature(nGold, oPC, TRUE));

    string sCredUuid = JsonGetString(JsonObjectGet(jBond, "partner_uuid"));
    object oCreditor = WkrFindPC(sCredUuid);
    if(GetIsObjectValid(oCreditor))
    {
        GiveGoldToCreature(oCreditor, nGold);
        SendMessageToPC(oCreditor,
            "[Więzy Krwi] " + GetName(oPC) + " spłacił dług: " + IntToString(nGold) + " gp.");
    }
    else
    {
        // Creditor offline — mark gold as stored in terms for manual distribution
        jTerms = JsonObjectSet(jTerms, "paid_offline", JsonInt(nGold));
        WkrUpdateTerms(nId, JsonDump(jTerms));
    }

    int nSt = JsonGetInt(JsonObjectGet(jBond, "status"));
    if(nSt == WKR_STATUS_VIOLATED) WkrRemoveCurse(oPC, nId);

    WkrSetStatus(nId, WKR_STATUS_FULFILLED);
    FloatingTextStringOnCreature("Dług spłacony — pieczęć krwi gaśnie.", oPC, FALSE);
    ApplyEffectToObject(DURATION_TYPE_INSTANT, EffectVisualEffect(VFX_IMP_DISPEL), oPC);

    SetLocalInt(oPC, WKR_LVAR_SEL_ID, 0);
    WkrShowListView(oPC, nToken);
}

void WkrHandleDissolve(object oPC, int nToken)
{
    int nId = GetLocalInt(oPC, WKR_LVAR_SEL_ID);
    if(nId <= 0) return;

    json jBond = WkrGetBond(nId);
    if(JsonGetType(jBond) == JSON_TYPE_NULL) return;

    WkrSetStatus(nId, WKR_STATUS_DISSOLVED);
    WkrRemoveProxFx(oPC, nId);

    string sPartUuid = WkrPartnerUuid(oPC, jBond);
    object oPartner  = WkrFindPC(sPartUuid);
    if(GetIsObjectValid(oPartner))
    {
        WkrRemoveProxFx(oPartner, nId);
        SendMessageToPC(oPartner,
            "[Więzy Krwi] " + GetName(oPC) + " rozwiązał powiązanie jednostronnie.");
        int nPToken = NuiFindWindow(oPartner, WKR_WINDOW);
        if(nPToken != 0)
            WkrShowListView(oPartner, nPToken);
    }

    FloatingTextStringOnCreature("Więź rozerwana — krwawa pieczęć zanika.", oPC, FALSE);
    ApplyEffectToObject(DURATION_TYPE_INSTANT, EffectVisualEffect(VFX_IMP_DISPEL), oPC);

    SetLocalInt(oPC, WKR_LVAR_SEL_ID, 0);
    WkrShowListView(oPC, nToken);
}

// Called from sys_on_pc_killed to detect oath betrayal.
void WkrCheckBetrayal(object oKiller, object oVictim)
{
    if(!GetIsPC(oKiller) || !GetIsPC(oVictim)) return;

    string sKillerUuid = GetObjectUUID(oKiller);
    string sVictimUuid = GetObjectUUID(oVictim);

    json jBonds = WkrGetBonds(sKillerUuid);
    int nCount  = JsonGetLength(jBonds);
    int i;

    for(i = 0; i < nCount; i++)
    {
        json jBond = JsonArrayGet(jBonds, i);
        if(JsonGetInt(JsonObjectGet(jBond, "bond_type")) != WKR_TYPE_OATH) continue;
        if(JsonGetInt(JsonObjectGet(jBond, "status")) != WKR_STATUS_ACTIVE) continue;

        string sPartner = WkrPartnerUuid(oKiller, jBond);
        if(sPartner != sVictimUuid) continue;

        int nId = JsonGetInt(JsonObjectGet(jBond, "id"));
        WkrSetStatus(nId, WKR_STATUS_VIOLATED);
        WkrApplyCurse(oKiller, WKR_TYPE_OATH, nId);
        WkrRemoveProxFx(oKiller, nId);
        SendMessageToPC(oKiller, "[Więzy Krwi] Złamałeś przysięgę krwi — klątwa spada.");
    }
}
