// =============================================================================
// lib_wst.nss
// =============================================================================
// Core logic and NUI for the War Standard system.
// Owns:
//   - WstPlantStandard      — spawn placeable, write SQL row
//   - WstDestroyStandard    — remove placeable, purge SQL, strip buffs
//   - WstRestoreFromDb      — called on module load to recreate placeables
//   - WstTickBuffs          — called from module heartbeat every 6 s
//   - WstOpenOverview       — open the main command panel (NUI)
//   - WstFeedOverview       — populate overview list binds
//   - WstOpenPlantDialog    — open the plant configuration panel (NUI)
//   - WstFeedPlantDesc      — update description label when type changes
//   - WstSaveOverviewPos    — debounced geometry save on window drag
// =============================================================================

#include "lib_wst_def"
#include "lib_nui"

// Forward declarations
void WstDestroyStandard(int nId);
void WstFeedOverview(object oPC, int nToken);

// =============================================================================
// Placeable helpers
// =============================================================================
object WstFindPlaceable(int nId)
{
    return GetObjectByTag(WST_TAG_PREFIX + IntToString(nId));
}

// Attempts to spawn the standard placeable; falls back to the boulder if the
// custom resref is missing from the hak (keeps the system usable without assets).
object WstSpawnPlaceable(location lLoc, string sTag)
{
    object oPl = CreateObject(OBJECT_TYPE_PLACEABLE, WST_PLACEABLE_RESREF, lLoc, FALSE, sTag);
    if(!GetIsObjectValid(oPl))
        oPl = CreateObject(OBJECT_TYPE_PLACEABLE, WST_PLACEABLE_FALLBACK, lLoc, FALSE, sTag);
    return oPl;
}

// =============================================================================
// Plant / Destroy
// =============================================================================
// Returns the new standard ID on success, 0 on failure.
int WstPlantStandard(object oPC, int nType, string sInscription)
{
    string sAreaTag = GetTag(GetArea(oPC));
    if(WstCountInArea(sAreaTag) >= WST_MAX_ACTIVE)
    {
        FloatingTextStringOnCreature(
            "*Ten rejon jest już nasycony energią sztandarów — zbyt wiele jednocześnie.*",
            oPC, FALSE);
        return 0;
    }

    location lLoc  = GetLocation(oPC);
    vector   vPos  = GetPositionFromLocation(lLoc);
    int nNow       = WstNowUnix();
    int nExpires   = nNow + WST_DURATION_MIN * 60;

    int nId = WstInsertStandard(sAreaTag,
                                vPos.x, vPos.y, vPos.z,
                                GetObjectUUID(oPC), GetName(oPC),
                                nType, sInscription,
                                nNow, nExpires);

    string sTag = WST_TAG_PREFIX + IntToString(nId);
    object oPl  = WstSpawnPlaceable(lLoc, sTag);
    if(!GetIsObjectValid(oPl))
    {
        WstDeleteStandard(nId);
        FloatingTextStringOnCreature(
            "*Ziemia odmawia przyjęcia sztandaru w tym miejscu.*", oPC, FALSE);
        return 0;
    }

    SetLocalInt(oPl,    WST_LVAR_ID,         nId);
    SetLocalInt(oPl,    WST_LVAR_TYPE,       nType);
    SetLocalString(oPl, WST_LVAR_OWNER_UUID, GetObjectUUID(oPC));
    SetPlotFlag(oPl,    FALSE);
    SetMaxHitPoints(oPl, WST_MAX_HP);

    string sName = WstGetTypeName(nType);
    if(GetStringLength(sInscription) > 0)
        sName += " — "" + sInscription + """;
    SetName(oPl, sName);

    FloatingTextStringOnCreature(
        "*Wbijasz " + WstGetTypeName(nType) + " w ziemię. Poczuj, jak pole bitwy twardnieje wokół ciebie.*",
        oPC, FALSE);
    return nId;
}

void WstDestroyStandard(int nId)
{
    object oPl = WstFindPlaceable(nId);
    if(GetIsObjectValid(oPl)) DestroyObject(oPl);
    WstDeleteStandard(nId);

    // Strip buffs from every PC that was anchored to this standard.
    object oPC = GetFirstPC();
    while(GetIsObjectValid(oPC))
    {
        if(GetLocalInt(oPC, WST_LVAR_BUFF_ID) == nId)
        {
            WstRemoveBuff(oPC);
            DeleteLocalInt(oPC, WST_LVAR_BUFF_ID);
            FloatingTextStringOnCreature(
                "*Sztandar upada — jego moc odpływa z twoich żył...*", oPC, FALSE);
        }
        oPC = GetNextPC();
    }
}

// Called from sys_on_load.nss to recreate placeables for standards that
// survived a server restart.
void WstRestoreFromDb()
{
    sqlquery q = WstQueryAllIds();
    while(SqlStep(q))
    {
        int nId = SqlGetInt(q, 0);
        struct WstRow s = WstGetStandard(nId);
        if(s.id == 0) continue;

        // If the standard expired while the server was offline, purge it now.
        if(s.expiresAt <= WstNowUnix())
        {
            WstDeleteStandard(nId);
            continue;
        }

        object oArea = GetObjectByTag(s.areaTag);
        if(!GetIsObjectValid(oArea)) continue;

        location lLoc = Location(oArea, Vector(s.x, s.y, s.z), 0.0);
        string sTag   = WST_TAG_PREFIX + IntToString(nId);

        // Only spawn if the placeable isn't already in the world (guards against
        // double calls on multi-module setups).
        if(GetIsObjectValid(GetObjectByTag(sTag))) continue;

        object oPl = WstSpawnPlaceable(lLoc, sTag);
        if(!GetIsObjectValid(oPl)) continue;

        SetLocalInt(oPl,    WST_LVAR_ID,         nId);
        SetLocalInt(oPl,    WST_LVAR_TYPE,       s.nType);
        SetLocalString(oPl, WST_LVAR_OWNER_UUID, s.ownerUUID);
        SetPlotFlag(oPl, FALSE);
        SetMaxHitPoints(oPl, WST_MAX_HP);

        // Restore HP from DB (damage carries over restarts).
        int nHpToRemove = WST_MAX_HP - s.hp;
        if(nHpToRemove > 0)
            ApplyEffectToObject(DURATION_TYPE_INSTANT,
                EffectDamage(nHpToRemove, DAMAGE_TYPE_BLUDGEONING), oPl);

        string sName = WstGetTypeName(s.nType);
        if(GetStringLength(s.inscription) > 0)
            sName += " — "" + s.inscription + """;
        SetName(oPl, sName);
    }
}

// =============================================================================
// Buff tick — called from module heartbeat
// =============================================================================
void WstTickBuffs()
{
    int nNow = WstNowUnix();

    // --- Expire overdue standards ---
    sqlquery qExp = WstQueryExpired(nNow);
    while(SqlStep(qExp))
        WstDestroyStandard(SqlGetInt(qExp, 0));

    // --- For each PC, determine which standard (if any) should buff them ---
    object oPC = GetFirstPC();
    while(GetIsObjectValid(oPC))
    {
        string sAreaTag = GetTag(GetArea(oPC));
        int nFoundId    = 0;
        int nFoundType  = 0;

        sqlquery qStd = WstQueryByArea(sAreaTag);
        while(SqlStep(qStd))
        {
            int   nId   = SqlGetInt(qStd, 0);
            int   nType = SqlGetInt(qStd, 1);
            float fX    = SqlGetFloat(qStd, 2);
            float fY    = SqlGetFloat(qStd, 3);
            float fZ    = SqlGetFloat(qStd, 4);

            // Use vector distance to avoid needing the placeable object for the check.
            vector vStd = Vector(fX, fY, fZ);
            vector vPC  = GetPosition(oPC);
            float  fDx  = vStd.x - vPC.x;
            float  fDy  = vStd.y - vPC.y;
            float  fDz  = vStd.z - vPC.z;
            float  fD   = sqrt(fDx*fDx + fDy*fDy + fDz*fDz);

            if(fD <= WST_RANGE_M)
            {
                // Also verify the placeable is still alive; if not, sync HP to DB.
                object oPl = WstFindPlaceable(nId);
                if(GetIsObjectValid(oPl))
                {
                    int nCurHp = GetCurrentHitPoints(oPl);
                    if(nCurHp <= 0)
                    {
                        WstDestroyStandard(nId);
                        continue;
                    }
                    WstSetStandardHp(nId, nCurHp);
                }
                nFoundId   = nId;
                nFoundType = nType;
                break; // first standard in range wins; can extend to best-type logic later
            }
        }

        int nPrevId = GetLocalInt(oPC, WST_LVAR_BUFF_ID);
        if(nFoundId != 0)
        {
            if(nPrevId != nFoundId)
            {
                // Moved into range of a new standard (or first tick in range).
                SetLocalInt(oPC, WST_LVAR_BUFF_ID, nFoundId);
                WstApplyBuff(oPC, nFoundType);
            }
            // else still in range of same standard — do nothing (buff is permanent)
        }
        else if(nPrevId != 0)
        {
            // Moved out of all standard ranges.
            WstRemoveBuff(oPC);
            DeleteLocalInt(oPC, WST_LVAR_BUFF_ID);
        }

        oPC = GetNextPC();
    }
}

// =============================================================================
// NUI — Overview panel
// =============================================================================
json WstBuildOverviewLayout()
{
    // Header row
    json jTitle = NuiLabel(JsonString("Sztandary Bitwy"),
        JsonInt(NUI_HALIGN_CENTER), JsonInt(NUI_VALIGN_MIDDLE));
    jTitle = NuiHeight(jTitle, 24.0);

    // List columns: [Name / Inscription] [Owner] [HP bar]
    float fRowH = 32.0;

    json jNameCell = NuiListTemplateCell(
        NuiId(NuiButton(NuiBind(WST_BIND_OVR_NAMES)), WST_BTN_OVR_ROW),
        0.0, TRUE);

    json jHpBar = NuiProgress(NuiBind(WST_BIND_OVR_HP_VAL));
    jHpBar = NuiStyleForegroundColor(jHpBar, NuiBind(WST_BIND_OVR_HP_COL));
    jHpBar = NuiWidth(jHpBar, 60.0);
    json jHpCell = NuiListTemplateCell(jHpBar, 60.0, FALSE);

    json jTmpl = JsonArray();
    jTmpl = JsonArrayInsert(jTmpl, jNameCell);
    jTmpl = JsonArrayInsert(jTmpl, jHpCell);

    json jList = NuiList(jTmpl, NuiBind(WST_BIND_OVR_COUNT), fRowH, TRUE, NUI_SCROLLBARS_Y);
    jList = NuiHeight(jList, 180.0);

    // Footer buttons
    json jBtnPlant = NuiId(NuiButton(JsonString("Wznieś Sztandar")), WST_BTN_OVR_PLANT);
    json jBtnClose = NuiId(NuiButton(JsonString("Zamknij")),          WST_BTN_OVR_CLOSE);
    jBtnClose = NuiWidth(jBtnClose, 80.0);

    json jFoot = JsonArray();
    jFoot = JsonArrayInsert(jFoot, jBtnPlant);
    jFoot = JsonArrayInsert(jFoot, jBtnClose);

    json jCol = JsonArray();
    jCol = JsonArrayInsert(jCol, NuiRow(JsonArrayInsert(JsonArray(), jTitle)));
    jCol = JsonArrayInsert(jCol, jList);
    jCol = JsonArrayInsert(jCol, NuiRow(jFoot));

    return NuiCol(jCol);
}

void WstOpenOverview(object oPC)
{
    if(!GetIsPC(oPC) || GetIsDM(oPC)) return;

    int nExist = NuiFindWindow(oPC, WST_WIN_OVR);
    if(nExist != 0)
    {
        // Refresh and bring to front instead of opening a duplicate.
        WstFeedOverview(oPC, nExist);
        return;
    }

    json jGeom = NuiRect(-1.0, -1.0, 340.0, 290.0);
    json jWin  = NuiWindow(WstBuildOverviewLayout(),
        JsonString("Sztandary Bitwy"),
        NuiBind(WST_BIND_OVR_GEOM),
        JsonBool(FALSE),  // resizable
        JsonBool(FALSE),  // collapsed
        JsonBool(TRUE),   // closable
        JsonBool(FALSE),  // transparent
        JsonBool(TRUE));  // border

    int nToken = NuiCreate(oPC, jWin, WST_WIN_OVR, "lib_wst_ev");
    SetLocalInt(oPC, WST_LVAR_OVR_TOKEN, nToken);
    NuiSetBind(oPC, nToken, WST_BIND_OVR_GEOM, jGeom);
    WstFeedOverview(oPC, nToken);
}

void WstFeedOverview(object oPC, int nToken)
{
    json jNames  = JsonArray();
    json jHpVals = JsonArray();
    json jHpCols = JsonArray();

    int nCount = 0;
    sqlquery q = WstQueryAllIds();
    while(SqlStep(q))
    {
        struct WstRow s = WstGetStandard(SqlGetInt(q, 0));
        if(s.id == 0) continue;

        // Row label: "[Type] Owner — Inscription"
        string sLabel = WstGetTypeName(s.nType) + " [" + s.ownerName + "]";
        if(GetStringLength(s.inscription) > 0)
            sLabel += " — " + s.inscription;

        // Remaining time annotation
        int nRemain = s.expiresAt - WstNowUnix();
        int nMins   = nRemain / 60;
        if(nMins < 0) nMins = 0;
        sLabel += " (" + IntToString(nMins) + " min)";

        jNames = JsonArrayInsert(jNames, JsonString(sLabel));

        float fHpFrac = IntToFloat(s.hp) / IntToFloat(WST_MAX_HP);
        if(fHpFrac < 0.0) fHpFrac = 0.0;
        if(fHpFrac > 1.0) fHpFrac = 1.0;
        jHpVals = JsonArrayInsert(jHpVals, JsonFloat(fHpFrac));

        json jColor;
        if(fHpFrac >= 0.6)      jColor = NuiColor(80,  200, 80,  255);
        else if(fHpFrac >= 0.3) jColor = NuiColor(220, 180, 50,  255);
        else                    jColor = NuiColor(200, 70,  70,  255);
        jHpCols = JsonArrayInsert(jHpCols, jColor);

        nCount++;
    }

    NuiSetBind(oPC, nToken, WST_BIND_OVR_NAMES,  jNames);
    NuiSetBind(oPC, nToken, WST_BIND_OVR_HP_VAL, jHpVals);
    NuiSetBind(oPC, nToken, WST_BIND_OVR_HP_COL, jHpCols);
    NuiSetBind(oPC, nToken, WST_BIND_OVR_COUNT,  JsonInt(nCount));
}

// Called by the event handler after a drag; debounce prevents rapid SQL writes.
void WstSaveOverviewPos(object oPC)
{
    int nToken = GetLocalInt(oPC, WST_LVAR_OVR_TOKEN);
    if(nToken == 0) { DeleteLocalInt(oPC, WST_LVAR_GEOM_DELAY); return; }
    // Position is already in NuiBind; nothing extra to persist here.
    // Extend this if you add a UI-position table to sql_wst.nss.
    DeleteLocalInt(oPC, WST_LVAR_GEOM_DELAY);
}

// =============================================================================
// NUI — Plant dialog
// =============================================================================
json WstBuildPlantLayout()
{
    // Type dropdown
    json jTypeEntries = JsonArray();
    jTypeEntries = JsonArrayInsert(jTypeEntries, NuiComboEntry("Gonfalon Legionu",  WST_TYPE_LEGION));
    jTypeEntries = JsonArrayInsert(jTypeEntries, NuiComboEntry("Chorągiew Pokuty",  WST_TYPE_SACRED));
    jTypeEntries = JsonArrayInsert(jTypeEntries, NuiComboEntry("Sztandar Grozy",    WST_TYPE_TERROR));
    json jCombo = NuiCombo(jTypeEntries, NuiBind(WST_BIND_PLT_TYPE));

    json jTypeLbl = NuiLabel(JsonString("Typ sztandaru:"),
        JsonInt(NUI_HALIGN_LEFT), JsonInt(NUI_VALIGN_MIDDLE));
    jTypeLbl = NuiWidth(jTypeLbl, 110.0);

    json jTypeRow = JsonArray();
    jTypeRow = JsonArrayInsert(jTypeRow, jTypeLbl);
    jTypeRow = JsonArrayInsert(jTypeRow, jCombo);

    // Inscription input
    json jInscrLbl = NuiLabel(JsonString("Napis (do " + IntToString(WST_MAX_INSCRIPTION) + " znaków):"),
        JsonInt(NUI_HALIGN_LEFT), JsonInt(NUI_VALIGN_MIDDLE));
    jInscrLbl = NuiHeight(jInscrLbl, 20.0);

    json jInput = NuiInputEdit(JsonString("Np. Pro gloria…"),
        NuiBind(WST_BIND_PLT_INSCR), WST_MAX_INSCRIPTION, FALSE);

    // Description label (updates on type change via watch event)
    json jDescLbl = NuiLabel(NuiBind(WST_BIND_PLT_DESC),
        JsonInt(NUI_HALIGN_LEFT), JsonInt(NUI_VALIGN_TOP));
    jDescLbl = NuiHeight(jDescLbl, 60.0);

    // Buttons
    json jConfirm = NuiId(NuiButton(JsonString("Wbij w ziemię")), WST_BTN_PLT_CONFIRM);
    json jCancel  = NuiId(NuiButton(JsonString("Anuluj")),         WST_BTN_PLT_CANCEL);
    jCancel = NuiWidth(jCancel, 70.0);

    json jBtnRow = JsonArray();
    jBtnRow = JsonArrayInsert(jBtnRow, jConfirm);
    jBtnRow = JsonArrayInsert(jBtnRow, jCancel);

    json jCol = JsonArray();
    jCol = JsonArrayInsert(jCol, NuiRow(jTypeRow));
    jCol = JsonArrayInsert(jCol, NuiRow(JsonArrayInsert(JsonArray(), jInscrLbl)));
    jCol = JsonArrayInsert(jCol, NuiRow(JsonArrayInsert(JsonArray(), jInput)));
    jCol = JsonArrayInsert(jCol, NuiRow(JsonArrayInsert(JsonArray(), jDescLbl)));
    jCol = JsonArrayInsert(jCol, NuiRow(jBtnRow));

    return NuiCol(jCol);
}

void WstOpenPlantDialog(object oPC)
{
    if(!GetIsPC(oPC) || GetIsDM(oPC)) return;
    if(NuiFindWindow(oPC, WST_WIN_PLT) != 0) return;

    json jGeom = NuiRect(-1.0, -1.0, 320.0, 240.0);
    json jWin  = NuiWindow(WstBuildPlantLayout(),
        JsonString("Wznoś Sztandar"),
        NuiBind(WST_BIND_PLT_GEOM),
        JsonBool(FALSE),
        JsonBool(FALSE),
        JsonBool(TRUE),
        JsonBool(FALSE),
        JsonBool(TRUE));

    int nToken = NuiCreate(oPC, jWin, WST_WIN_PLT, "lib_wst_ev");
    SetLocalInt(oPC, WST_LVAR_PLT_TOKEN, nToken);

    NuiSetBind(oPC, nToken, WST_BIND_PLT_GEOM,  jGeom);
    NuiSetBind(oPC, nToken, WST_BIND_PLT_TYPE,  JsonInt(WST_TYPE_LEGION));
    NuiSetBind(oPC, nToken, WST_BIND_PLT_INSCR, JsonString(""));
    NuiSetBind(oPC, nToken, WST_BIND_PLT_DESC,  JsonString(WstGetTypeDesc(WST_TYPE_LEGION)));
    NuiSetBindWatch(oPC, nToken, WST_BIND_PLT_TYPE, TRUE);
}

// Called from the event handler when the type combo changes.
void WstFeedPlantDesc(object oPC, int nToken, int nType)
{
    NuiSetBind(oPC, nToken, WST_BIND_PLT_DESC, JsonString(WstGetTypeDesc(nType)));
}
