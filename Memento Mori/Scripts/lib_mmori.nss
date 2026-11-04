#include "lib_mmori_def"

// ----------------------------------------------------------------
// Utility helpers
// ----------------------------------------------------------------

// Rebuilds a Location from stored area tag + coordinates.
location MmoriDeathLocation(string sAreaTag, float fX, float fY, float fZ)
{
    object oArea = GetObjectByTag(sAreaTag);
    return Location(oArea, Vector(fX, fY, fZ), 0.0);
}

// Applies a brief mourning blessing to oPC.
void MmoriApplyMourningBuff(object oPC, int bLegendary)
{
    if(bLegendary)
    {
        // Duszny błysk legendy — bonus do AB i chwilowa odporność na strach
        effect eAB   = EffectAttackIncrease(3);
        effect eFear = EffectImmunity(IMMUNITY_TYPE_FEAR);
        effect eVfx  = EffectVisualEffect(VFX_IMP_HOLY_AID);
        ApplyEffectToObject(DURATION_TYPE_TEMPORARY, eAB,   oPC, IntToFloat(MMORI_BUFF_DURATION));
        ApplyEffectToObject(DURATION_TYPE_TEMPORARY, eFear, oPC, IntToFloat(MMORI_BUFF_DURATION));
        ApplyEffectToObject(DURATION_TYPE_INSTANT,   eVfx,  oPC);
        SendMessageToPC(oPC, "[Memento Mori] Legenda przemawia z zaświatów — krew w żyłach kipi.");
    }
    else
    {
        // Cichy smutek — skromny bonus do regeneracji HP
        effect eRegen = EffectRegenerate(2, 6.0);
        effect eVfx   = EffectVisualEffect(VFX_IMP_HEALING_S);
        ApplyEffectToObject(DURATION_TYPE_TEMPORARY, eRegen, oPC, IntToFloat(MMORI_BUFF_DURATION));
        ApplyEffectToObject(DURATION_TYPE_INSTANT,   eVfx,   oPC);
        SendMessageToPC(oPC, "[Memento Mori] Pamięć o poległym koi twoje rany.");
    }
}

// HP bonus when owner reclaims their own cairn.
void MmoriApplyReclaimBuff(object oPC)
{
    effect eHeal = EffectHeal(MMORI_RECLAIM_HP_BONUS);
    effect eVfx  = EffectVisualEffect(VFX_IMP_HARM);
    ApplyEffectToObject(DURATION_TYPE_INSTANT, eHeal, oPC);
    ApplyEffectToObject(DURATION_TYPE_INSTANT, eVfx,  oPC);
    SendMessageToPC(oPC, "[Memento Mori] Odzyskujesz ślad po sobie — śmierć nie wzięła cię jeszcze.");
}

// Spawns the physical cairn placeable at the stored death location.
// Returns the created object (OBJECT_INVALID on failure).
object MmoriSpawnCairn(int nMarkId, string sAreaTag, float fX, float fY, float fZ)
{
    location lSpawn = MmoriDeathLocation(sAreaTag, fX, fY, fZ);
    string sTag     = MMORI_CAIRN_TAG_PREFIX + IntToString(nMarkId);
    object oCairn   = CreateObject(OBJECT_TYPE_PLACEABLE, MMORI_CAIRN_RESREF, lSpawn, FALSE, sTag);
    if(GetIsObjectValid(oCairn))
    {
        SetLocalInt(oCairn, MMORI_LVAR_MARK_ID, nMarkId);
        SetPlaceableIllumination(oCairn, FALSE);
        SetEventScript(oCairn, EVENT_SCRIPT_PLACEABLE_ON_USED, "sys_on_cairn");
    }
    return oCairn;
}

// Finds an active cairn object by mark ID.
object MmoriGetCairnObject(int nMarkId)
{
    string sTag = MMORI_CAIRN_TAG_PREFIX + IntToString(nMarkId);
    return GetObjectByTag(sTag);
}

// ----------------------------------------------------------------
// Last Words window
// ----------------------------------------------------------------

void CreateMmoriMarkWindow(object oPC)
{
    if(NuiFindWindow(oPC, MMORI_WIN_LASTWORDS) != 0) return;

    float fBtnH   = GetNuiScaleDimension(oPC, 32.0);
    float fTextH  = GetNuiScaleDimension(oPC, 100.0);
    float fLabelH = GetNuiScaleDimension(oPC, 24.0);

    float fCX = (IntToFloat(GetPlayerDeviceProperty(oPC, PLAYER_DEVICE_PROPERTY_GUI_WIDTH))  - GetNuiScaleDimension(oPC, MMORI_LW_W)) / 2.0;
    float fCY = (IntToFloat(GetPlayerDeviceProperty(oPC, PLAYER_DEVICE_PROPERTY_GUI_HEIGHT)) - GetNuiScaleDimension(oPC, MMORI_LW_H)) / 2.0;
    json jGeom = NuiRect(fCX, fCY, GetNuiScaleDimension(oPC, MMORI_LW_W), GetNuiScaleDimension(oPC, MMORI_LW_H));

    // "Poległeś w [obszar]. Możesz zostawić ślad po sobie..."
    json jAreaLbl = NuiLabel(NuiBind(MMORI_BIND_LW_AREA), JsonInt(NUI_HALIGN_CENTER), JsonInt(NUI_VALIGN_MIDDLE));
    jAreaLbl = NuiHeight(jAreaLbl, fLabelH);

    json jHintLbl = NuiLabel(
        JsonString("Ostatnie słowa wyryte w kamieniu — inni mogą je odnaleźć."),
        JsonInt(NUI_HALIGN_CENTER), JsonInt(NUI_VALIGN_MIDDLE));
    jHintLbl = NuiHeight(jHintLbl, fLabelH);

    json jTextEdit = NuiTextEdit(
        JsonString("Moje słowa do potomnych..."),
        NuiBind(MMORI_BIND_LW_TXT), 180, TRUE);
    jTextEdit = NuiHeight(jTextEdit, fTextH);

    json jConfBtn = NuiButton(JsonString("Zostaw Ślad"));
    jConfBtn = NuiId(jConfBtn, MMORI_BTN_LW_CONFIRM);
    jConfBtn = NuiWidth(jConfBtn, GetNuiScaleDimension(oPC, 160.0));
    jConfBtn = NuiHeight(jConfBtn, fBtnH);

    json jSkipBtn = NuiButton(JsonString("Zapomnij"));
    jSkipBtn = NuiId(jSkipBtn, MMORI_BTN_LW_SKIP);
    jSkipBtn = NuiWidth(jSkipBtn, GetNuiScaleDimension(oPC, 100.0));
    jSkipBtn = NuiHeight(jSkipBtn, fBtnH);

    json jBtnRow = JsonArray();
    jBtnRow = JsonArrayInsert(jBtnRow, jConfBtn);
    jBtnRow = JsonArrayInsert(jBtnRow, NuiSpacer());
    jBtnRow = JsonArrayInsert(jBtnRow, jSkipBtn);

    json jCol = JsonArray();
    jCol = JsonArrayInsert(jCol, jAreaLbl);
    jCol = JsonArrayInsert(jCol, jHintLbl);
    jCol = JsonArrayInsert(jCol, jTextEdit);
    jCol = JsonArrayInsert(jCol, NuiRow(jBtnRow));

    json jRoot = NuiCol(jCol);

    json jWin = NuiWindow(jRoot,
        JsonString("Memento Mori"),
        NuiBind(MMORI_BIND_LW_GEOM),
        JsonBool(FALSE), JsonBool(FALSE), JsonBool(FALSE),
        JsonBool(TRUE),  JsonBool(FALSE));

    int nToken = NuiCreate(oPC, jWin, MMORI_WIN_LASTWORDS, MMORI_EV_SCRIPT);
    NuiSetBind(oPC, nToken, MMORI_BIND_LW_GEOM, jGeom);
    NuiSetBind(oPC, nToken, MMORI_BIND_LW_TXT,  JsonString(""));

    string sArea = GetLocalString(oPC, MMORI_LVAR_DEATH_ANAME);
    NuiSetBind(oPC, nToken, MMORI_BIND_LW_AREA,
        JsonString("Poległeś w: " + sArea + "."));
}

// ----------------------------------------------------------------
// Cairn Vision window (for other players viewing the stone)
// ----------------------------------------------------------------

json BuildMmoriCairnRoot(object oPC, int bOwner)
{
    float fBtnH   = GetNuiScaleDimension(oPC, 32.0);
    float fBodyH  = GetNuiScaleDimension(oPC, 120.0);
    float fLblH   = GetNuiScaleDimension(oPC, 22.0);

    // Header: deceased name + area + age
    json jHeader = NuiLabel(NuiBind(MMORI_BIND_CA_HEADER), JsonInt(NUI_HALIGN_CENTER), JsonInt(NUI_VALIGN_MIDDLE));
    jHeader = NuiHeight(jHeader, fLblH);

    // Legend indicator (only visible for legendary marks)
    json jLegend = NuiLabel(
        JsonString("— KAMIENIARZ LEGENDY —"),
        JsonInt(NUI_HALIGN_CENTER), JsonInt(NUI_VALIGN_MIDDLE));
    jLegend = NuiHeight(jLegend, fLblH);
    jLegend = NuiVisible(jLegend, NuiBind(MMORI_BIND_CA_LEGEND));
    jLegend = NuiStyleForegroundColor(jLegend, NuiColor(255, 215, 0));

    // Last words body
    json jWords = NuiGroup(NuiText(NuiBind(MMORI_BIND_CA_WORDS), FALSE), TRUE, NUI_SCROLLBARS_NONE);
    jWords = NuiHeight(jWords, fBodyH);

    // Footer: mourner count
    json jFooter = NuiLabel(NuiBind(MMORI_BIND_CA_FOOTER), JsonInt(NUI_HALIGN_CENTER), JsonInt(NUI_VALIGN_MIDDLE));
    jFooter = NuiHeight(jFooter, fLblH);

    // Buttons row
    json jMournBtn = NuiButton(NuiBind(MMORI_BIND_CA_MOURN));
    jMournBtn = NuiId(jMournBtn, MMORI_BTN_CA_MOURN);
    jMournBtn = NuiEnabled(jMournBtn, NuiBind(MMORI_BIND_CA_MOURNA));
    jMournBtn = NuiVisible(jMournBtn, JsonBool(!bOwner));
    jMournBtn = NuiWidth(jMournBtn, GetNuiScaleDimension(oPC, 160.0));
    jMournBtn = NuiHeight(jMournBtn, fBtnH);

    json jReclaimBtn = NuiButton(JsonString("Zabierz Kamień"));
    jReclaimBtn = NuiId(jReclaimBtn, MMORI_BTN_CA_RECLAIM);
    jReclaimBtn = NuiVisible(jReclaimBtn, NuiBind(MMORI_BIND_CA_RECLAIM));
    jReclaimBtn = NuiWidth(jReclaimBtn, GetNuiScaleDimension(oPC, 160.0));
    jReclaimBtn = NuiHeight(jReclaimBtn, fBtnH);

    json jCloseBtn = NuiButton(JsonString("Zamknij"));
    jCloseBtn = NuiId(jCloseBtn, MMORI_BTN_CA_CLOSE);
    jCloseBtn = NuiWidth(jCloseBtn, GetNuiScaleDimension(oPC, 100.0));
    jCloseBtn = NuiHeight(jCloseBtn, fBtnH);

    json jBtnRow = JsonArray();
    jBtnRow = JsonArrayInsert(jBtnRow, jMournBtn);
    jBtnRow = JsonArrayInsert(jBtnRow, jReclaimBtn);
    jBtnRow = JsonArrayInsert(jBtnRow, NuiSpacer());
    jBtnRow = JsonArrayInsert(jBtnRow, jCloseBtn);

    json jCol = JsonArray();
    jCol = JsonArrayInsert(jCol, jHeader);
    jCol = JsonArrayInsert(jCol, jLegend);
    jCol = JsonArrayInsert(jCol, jWords);
    jCol = JsonArrayInsert(jCol, jFooter);
    jCol = JsonArrayInsert(jCol, NuiRow(jBtnRow));

    return NuiCol(jCol);
}

void FeedMmoriCairnView(object oPC, int nToken, int nMarkId)
{
    json jMark = MmoriGetMark(nMarkId);
    if(JsonGetType(jMark) == JSON_TYPE_NULL)
    {
        NuiDestroy(oPC, nToken);
        return;
    }

    string sName       = JsonGetString(JsonObjectGet(jMark, "player_name"));
    string sAreaName   = JsonGetString(JsonObjectGet(jMark, "area_name"));
    int    nDiedAt     = JsonGetInt   (JsonObjectGet(jMark, "died_at"));
    int    nMourners   = JsonGetInt   (JsonObjectGet(jMark, "mourner_count"));
    int    bLegendary  = JsonGetInt   (JsonObjectGet(jMark, "is_legendary"));
    string sWords      = JsonGetString(JsonObjectGet(jMark, "last_words"));

    string sHeader = sName + "  |  " + sAreaName + "  |  " + MmoriFormatAge(nDiedAt);
    string sFooter = "Opłakujących: " + IntToString(nMourners);
    if(bLegendary) sFooter = sFooter + "  •  Legenda";

    int bAlreadyMourned = MmoriHasMourned(nMarkId, GetObjectUUID(oPC));
    string sMournLbl = bAlreadyMourned ? "Już opłakany" : "Opłakuj";

    NuiSetBind(oPC, nToken, MMORI_BIND_CA_HEADER, JsonString(sHeader));
    NuiSetBind(oPC, nToken, MMORI_BIND_CA_WORDS,  JsonString(sWords != "" ? sWords : "Żadnych słów."));
    NuiSetBind(oPC, nToken, MMORI_BIND_CA_FOOTER, JsonString(sFooter));
    NuiSetBind(oPC, nToken, MMORI_BIND_CA_MOURN,  JsonString(sMournLbl));
    NuiSetBind(oPC, nToken, MMORI_BIND_CA_MOURNA, JsonBool(!bAlreadyMourned));
    NuiSetBind(oPC, nToken, MMORI_BIND_CA_LEGEND, JsonBool(bLegendary));
}

void CreateMmoriCairnWindow(object oPC, int nMarkId)
{
    if(NuiFindWindow(oPC, MMORI_WIN_CAIRN) != 0)
    {
        int nToken = NuiFindWindow(oPC, MMORI_WIN_CAIRN);
        SetLocalInt(oPC, MMORI_LVAR_MARK_ID, nMarkId);
        FeedMmoriCairnView(oPC, nToken, nMarkId);
        return;
    }

    float fCX = (IntToFloat(GetPlayerDeviceProperty(oPC, PLAYER_DEVICE_PROPERTY_GUI_WIDTH))  - GetNuiScaleDimension(oPC, MMORI_CA_W)) / 2.0;
    float fCY = (IntToFloat(GetPlayerDeviceProperty(oPC, PLAYER_DEVICE_PROPERTY_GUI_HEIGHT)) - GetNuiScaleDimension(oPC, MMORI_CA_H)) / 2.0;
    json jGeom = NuiRect(fCX, fCY, GetNuiScaleDimension(oPC, MMORI_CA_W), GetNuiScaleDimension(oPC, MMORI_CA_H));

    json jWin = NuiWindow(BuildMmoriCairnRoot(oPC, FALSE),
        JsonString("Kamień Pamiątki"),
        NuiBind(MMORI_BIND_CA_GEOM),
        JsonBool(FALSE), JsonBool(FALSE), JsonBool(FALSE),
        JsonBool(TRUE),  JsonBool(FALSE));

    int nToken = NuiCreate(oPC, jWin, MMORI_WIN_CAIRN, MMORI_EV_SCRIPT);
    NuiSetBind(oPC, nToken, MMORI_BIND_CA_GEOM,    jGeom);
    NuiSetBind(oPC, nToken, MMORI_BIND_CA_RECLAIM, JsonBool(FALSE));

    SetLocalInt(oPC, MMORI_LVAR_MARK_ID, nMarkId);
    FeedMmoriCairnView(oPC, nToken, nMarkId);
}

void CreateMmoriOwnCairnWindow(object oPC, int nMarkId, object oCairn)
{
    // Reuse the same window ID but with reclaim button visible.
    if(NuiFindWindow(oPC, MMORI_WIN_CAIRN) != 0)
        NuiDestroy(oPC, NuiFindWindow(oPC, MMORI_WIN_CAIRN));

    float fCX = (IntToFloat(GetPlayerDeviceProperty(oPC, PLAYER_DEVICE_PROPERTY_GUI_WIDTH))  - GetNuiScaleDimension(oPC, MMORI_CA_W)) / 2.0;
    float fCY = (IntToFloat(GetPlayerDeviceProperty(oPC, PLAYER_DEVICE_PROPERTY_GUI_HEIGHT)) - GetNuiScaleDimension(oPC, MMORI_CA_H)) / 2.0;
    json jGeom = NuiRect(fCX, fCY, GetNuiScaleDimension(oPC, MMORI_CA_W), GetNuiScaleDimension(oPC, MMORI_CA_H));

    json jWin = NuiWindow(BuildMmoriCairnRoot(oPC, TRUE),
        JsonString("Twój Kamień Pamiątki"),
        NuiBind(MMORI_BIND_CA_GEOM),
        JsonBool(FALSE), JsonBool(FALSE), JsonBool(FALSE),
        JsonBool(TRUE),  JsonBool(FALSE));

    int nToken = NuiCreate(oPC, jWin, MMORI_WIN_CAIRN, MMORI_EV_SCRIPT);
    NuiSetBind(oPC, nToken, MMORI_BIND_CA_GEOM,    jGeom);
    NuiSetBind(oPC, nToken, MMORI_BIND_CA_RECLAIM, JsonBool(TRUE));

    // Store cairn object reference via local int on PC (mark ID enough to find it later)
    SetLocalInt(oPC, MMORI_LVAR_MARK_ID, nMarkId);
    FeedMmoriCairnView(oPC, nToken, nMarkId);
}

// ----------------------------------------------------------------
// Core flow: on death, store location; on respawn, prompt player
// ----------------------------------------------------------------

void MmoriOnPlayerDeath(object oPC)
{
    if(!GetIsPC(oPC)) return;

    location lDeath = GetLocation(oPC);
    object   oArea  = GetAreaFromLocation(lDeath);
    vector   vPos   = GetPositionFromLocation(lDeath);

    SetLocalString(oPC, MMORI_LVAR_DEATH_AREA,  GetTag(oArea));
    SetLocalString(oPC, MMORI_LVAR_DEATH_ANAME, GetName(oArea));
    SetLocalFloat (oPC, MMORI_LVAR_DEATH_X,     vPos.x);
    SetLocalFloat (oPC, MMORI_LVAR_DEATH_Y,     vPos.y);
    SetLocalFloat (oPC, MMORI_LVAR_DEATH_Z,     vPos.z);
    SetLocalInt   (oPC, MMORI_LVAR_PENDING,     1);
}

void MmoriOnPlayerRespawn(object oPC)
{
    if(!GetIsPC(oPC)) return;
    if(!GetLocalInt(oPC, MMORI_LVAR_PENDING)) return;
    DeleteLocalInt(oPC, MMORI_LVAR_PENDING);

    // Small delay so the respawn transition finishes first.
    DelayCommand(0.5, CreateMmoriMarkWindow(oPC));
}

void MmoriConfirmMark(object oPC)
{
    int nToken = NuiFindWindow(oPC, MMORI_WIN_LASTWORDS);
    string sWords = JsonGetString(NuiGetBind(oPC, nToken, MMORI_BIND_LW_TXT));

    string sAreaTag  = GetLocalString(oPC, MMORI_LVAR_DEATH_AREA);
    string sAreaName = GetLocalString(oPC, MMORI_LVAR_DEATH_ANAME);
    float  fX        = GetLocalFloat (oPC, MMORI_LVAR_DEATH_X);
    float  fY        = GetLocalFloat (oPC, MMORI_LVAR_DEATH_Y);
    float  fZ        = GetLocalFloat (oPC, MMORI_LVAR_DEATH_Z);

    if(sAreaTag == "")
    {
        SendMessageToPC(oPC, "[Memento Mori] Nie znaleziono miejsca śmierci.");
        NuiDestroy(oPC, nToken);
        return;
    }

    int nMarkId = MmoriInsertMark(GetObjectUUID(oPC), GetName(oPC),
                                  sAreaTag, sAreaName, fX, fY, fZ, sWords);
    if(nMarkId <= 0)
    {
        SendMessageToPC(oPC, "[Memento Mori] Nie udało się uwiecznić śladu.");
        NuiDestroy(oPC, nToken);
        return;
    }

    object oCairn = MmoriSpawnCairn(nMarkId, sAreaTag, fX, fY, fZ);
    if(!GetIsObjectValid(oCairn))
        SendMessageToPC(oPC, "[Memento Mori] Kamień pamiątki nie mógł zostać wzniesiony (zły obszar).");
    else
        SendMessageToPC(oPC, "[Memento Mori] Kamień pamiątki stoi tam, gdzie padłeś.");

    NuiDestroy(oPC, nToken);

    DeleteLocalString(oPC, MMORI_LVAR_DEATH_AREA);
    DeleteLocalString(oPC, MMORI_LVAR_DEATH_ANAME);
    DeleteLocalFloat (oPC, MMORI_LVAR_DEATH_X);
    DeleteLocalFloat (oPC, MMORI_LVAR_DEATH_Y);
    DeleteLocalFloat (oPC, MMORI_LVAR_DEATH_Z);
}

void MmoriHandleMourn(object oPC)
{
    int nToken  = NuiFindWindow(oPC, MMORI_WIN_CAIRN);
    int nMarkId = GetLocalInt(oPC, MMORI_LVAR_MARK_ID);
    if(nMarkId <= 0 || nToken == 0) return;

    if(MmoriHasMourned(nMarkId, GetObjectUUID(oPC)))
    {
        SendMessageToPC(oPC, "[Memento Mori] Ten kamień już opłakałeś.");
        return;
    }

    MmoriAddMourner(nMarkId, GetObjectUUID(oPC), MMORI_LEGENDARY_THRESH);

    json jMark = MmoriGetMark(nMarkId);
    int bLegendary = JsonGetInt(JsonObjectGet(jMark, "is_legendary"));

    MmoriApplyMourningBuff(oPC, bLegendary);
    FeedMmoriCairnView(oPC, nToken, nMarkId);
}

void MmoriHandleReclaim(object oPC)
{
    int nToken  = NuiFindWindow(oPC, MMORI_WIN_CAIRN);
    int nMarkId = GetLocalInt(oPC, MMORI_LVAR_MARK_ID);
    if(nMarkId <= 0 || nToken == 0) return;

    MmoriDeactivateMark(nMarkId);

    object oCairn = MmoriGetCairnObject(nMarkId);
    if(GetIsObjectValid(oCairn))
        DestroyObject(oCairn, 0.0);

    MmoriApplyReclaimBuff(oPC);
    NuiDestroy(oPC, nToken);
    DeleteLocalInt(oPC, MMORI_LVAR_MARK_ID);
}

// Called from sys_on_cairn.nss when a player uses a cairn placeable.
void MmoriOnCairnUsed(object oPC, object oCairn)
{
    int nMarkId = GetLocalInt(oCairn, MMORI_LVAR_MARK_ID);
    if(nMarkId <= 0) return;

    json jMark = MmoriGetMark(nMarkId);
    if(JsonGetType(jMark) == JSON_TYPE_NULL)
    {
        SendMessageToPC(oPC, "[Memento Mori] Kamień jest pusty — ślad zaginął.");
        return;
    }

    string sOwnerUuid = JsonGetString(JsonObjectGet(jMark, "player_uuid"));
    if(sOwnerUuid == GetObjectUUID(oPC))
        CreateMmoriOwnCairnWindow(oPC, nMarkId, oCairn);
    else
        CreateMmoriCairnWindow(oPC, nMarkId);
}
