// lib_nec.nss — Necromancy: NUI construction, servant lifecycle, essence economy

#include "lib_nec_def"

// ----------------------------------------------------------------
// Forward declarations
// ----------------------------------------------------------------

json  NecBuildWindow(object oPC);
void  NecOpenWindow(object oPC);
void  NecFeedRoster(object oPC, int nToken);
void  NecFeedDetail(object oPC, int nToken, int nServantId);
void  NecClearDetail(object oPC, int nToken);
void  NecFeedEssencePool(object oPC, int nToken);
void  NecUpdateBindState(object oPC, int nToken);
void  NecBindCorpse(object oPC, object oCorpse);
void  NecDoFeed(object oPC, int nToken, int nServantId);
void  NecDoDismiss(object oPC, int nToken, int nServantId);
object NecSpawnServant(object oPC, json jRow);
void  NecSpawnServants(object oPC);
void  NecDespawnServants(object oPC);
void  NecProcessDecay(object oPC);
void  NecSyncServantHP(object oPC);
void  NecOnCreatureDeath(object oKiller, object oCorpse);

// ----------------------------------------------------------------
// NUI — window construction
// ----------------------------------------------------------------

json NecBuildWindow(object oPC)
{
    float fScale = GetNuiScaleDimension(oPC, 1.0);

    // ---- List template ----
    json jCells = JsonArray();

    json jCellName = NuiListTemplateCell(
        NuiLabel(NuiBind(NEC_BIND_ROW_NAME), JsonInt(NUI_HALIGN_LEFT), JsonInt(NUI_VALIGN_MIDDLE)),
        165.0, FALSE);
    jCells = JsonArrayInsert(jCells, jCellName);

    json jCellType = NuiListTemplateCell(
        NuiLabel(NuiBind(NEC_BIND_ROW_TYPE), JsonInt(NUI_HALIGN_CENTER), JsonInt(NUI_VALIGN_MIDDLE)),
        72.0, FALSE);
    jCells = JsonArrayInsert(jCells, jCellType);

    json jCellHP = NuiListTemplateCell(
        NuiProgressBar(NuiBind(NEC_BIND_ROW_HP)),
        80.0, FALSE);
    jCells = JsonArrayInsert(jCells, jCellHP);

    json jCellEss = NuiListTemplateCell(
        NuiProgressBar(NuiBind(NEC_BIND_ROW_ESS)),
        80.0, FALSE);
    jCells = JsonArrayInsert(jCells, jCellEss);

    json jRowBtn = NuiId(NuiButton(JsonString("▶")), NEC_BTN_ROW);
    jRowBtn = NuiEnabled(jRowBtn, JsonBool(TRUE));
    jCells = JsonArrayInsert(jCells, NuiListTemplateCell(jRowBtn, 48.0, FALSE));

    json jTemplate = NuiListTemplate(jCells, 40.0, TRUE);
    json jList     = NuiList(jTemplate, NuiBind(NEC_BIND_ROW_COUNT), 40.0);

    // ---- Left panel: header + list ----
    json jRosterHeader = JsonArray();
    jRosterHeader = JsonArrayInsert(jRosterHeader,
        NuiLabel(NuiBind(NEC_BIND_SLOT_LBL), JsonInt(NUI_HALIGN_LEFT), JsonInt(NUI_VALIGN_MIDDLE)));
    json jRosterHeaderRow = NuiRow(jRosterHeader);

    json jRosterCol = JsonArray();
    jRosterCol = JsonArrayInsert(jRosterCol, jRosterHeaderRow);
    jRosterCol = JsonArrayInsert(jRosterCol, jList);
    json jLeftGroup = NuiGroup(NuiCol(jRosterCol), TRUE, NUI_SCROLLBARS_NONE);
    jLeftGroup = NuiWidth(jLeftGroup, 460.0);

    // ---- Right panel: servant detail ----
    json jDetTitle = NuiLabel(JsonString("SZCZEGÓŁY"), JsonInt(NUI_HALIGN_CENTER), JsonInt(NUI_VALIGN_MIDDLE));
    jDetTitle = NuiForegroundColor(jDetTitle, GetNuiColorNwnGold());
    jDetTitle = NuiHeight(jDetTitle, 24.0);

    json jDetName = NuiLabel(NuiBind(NEC_BIND_DET_NAME),
        JsonInt(NUI_HALIGN_CENTER), JsonInt(NUI_VALIGN_MIDDLE));
    jDetName = NuiHeight(jDetName, 22.0);

    json jDetInfo = NuiLabel(NuiBind(NEC_BIND_DET_INFO),
        JsonInt(NUI_HALIGN_LEFT), JsonInt(NUI_VALIGN_TOP));
    jDetInfo = NuiHeight(jDetInfo, 40.0);

    // HP bar row
    json jDetHPRow = JsonArray();
    jDetHPRow = JsonArrayInsert(jDetHPRow,
        NuiWidth(NuiLabel(JsonString("PW:"), JsonInt(NUI_HALIGN_LEFT), JsonInt(NUI_VALIGN_MIDDLE)), 28.0));
    jDetHPRow = JsonArrayInsert(jDetHPRow, NuiProgressBar(NuiBind(NEC_BIND_DET_HP_BAR)));

    // Essence bar row
    json jDetEssRow = JsonArray();
    jDetEssRow = JsonArrayInsert(jDetEssRow,
        NuiWidth(NuiLabel(JsonString("Esn:"), JsonInt(NUI_HALIGN_LEFT), JsonInt(NUI_VALIGN_MIDDLE)), 28.0));
    jDetEssRow = JsonArrayInsert(jDetEssRow, NuiProgressBar(NuiBind(NEC_BIND_DET_ESS_BAR)));

    // Feed row
    json jFeedInput = NuiTextEdit(JsonString("25"), NuiBind(NEC_BIND_FEED_AMT), 5, FALSE);
    jFeedInput = NuiWidth(jFeedInput, 52.0);
    json jFeedBtn = NuiId(
        NuiEnabled(NuiButton(JsonString("Nakarm")), NuiBind(NEC_BIND_FEED_ENA)),
        NEC_BTN_FEED);
    json jFeedRow = JsonArray();
    jFeedRow = JsonArrayInsert(jFeedRow, jFeedInput);
    jFeedRow = JsonArrayInsert(jFeedRow, jFeedBtn);

    // Dismiss button
    json jDismissBtn = NuiId(
        NuiEnabled(NuiButton(JsonString("Pożegnaj sługę")), NuiBind(NEC_BIND_DISMISS_ENA)),
        NEC_BTN_DISMISS);

    json jDetCol = JsonArray();
    jDetCol = JsonArrayInsert(jDetCol, NuiHeight(jDetTitle, 28.0));
    jDetCol = JsonArrayInsert(jDetCol, NuiHeight(jDetName, 26.0));
    jDetCol = JsonArrayInsert(jDetCol, NuiHeight(jDetInfo, 44.0));
    jDetCol = JsonArrayInsert(jDetCol, NuiHeight(NuiRow(jDetHPRow), 28.0));
    jDetCol = JsonArrayInsert(jDetCol, NuiHeight(NuiRow(jDetEssRow), 28.0));
    jDetCol = JsonArrayInsert(jDetCol, CreateEmptyRow(oPC, 6.0));
    jDetCol = JsonArrayInsert(jDetCol,
        NuiHeight(NuiLabel(JsonString("Nakarm esencją:"),
            JsonInt(NUI_HALIGN_LEFT), JsonInt(NUI_VALIGN_MIDDLE)), 20.0));
    jDetCol = JsonArrayInsert(jDetCol, NuiHeight(NuiRow(jFeedRow), 32.0));
    jDetCol = JsonArrayInsert(jDetCol, NuiSpacer());
    jDetCol = JsonArrayInsert(jDetCol, NuiHeight(jDismissBtn, 32.0));

    json jRightGroup = NuiGroup(NuiCol(jDetCol), TRUE, NUI_SCROLLBARS_NONE);

    // ---- Body row ----
    json jBody = JsonArray();
    jBody = JsonArrayInsert(jBody, jLeftGroup);
    jBody = JsonArrayInsert(jBody, jRightGroup);

    // ---- Footer row ----
    json jEssLbl = NuiLabel(NuiBind(NEC_BIND_ESSENCE_LBL),
        JsonInt(NUI_HALIGN_LEFT), JsonInt(NUI_VALIGN_MIDDLE));

    json jBindBtn = NuiId(
        NuiEnabled(NuiButton(JsonString("Przywołaj Umarłych")), NuiBind(NEC_BIND_BIND_ENA)),
        NEC_BTN_BIND);
    jBindBtn = NuiWidth(jBindBtn, 160.0);

    json jCloseBtn = NuiId(NuiButton(JsonString("Zamknij")), NEC_BTN_CLOSE);
    jCloseBtn = NuiWidth(jCloseBtn, 80.0);

    json jFooter = JsonArray();
    jFooter = JsonArrayInsert(jFooter, jEssLbl);
    jFooter = JsonArrayInsert(jFooter, NuiSpacer());
    jFooter = JsonArrayInsert(jFooter, jBindBtn);
    jFooter = JsonArrayInsert(jFooter, jCloseBtn);

    // ---- Root layout ----
    json jRoot = JsonArray();
    jRoot = JsonArrayInsert(jRoot, NuiHeight(NuiRow(jBody), 420.0));
    jRoot = JsonArrayInsert(jRoot, NuiHeight(NuiRow(jFooter), 38.0));

    json jGeom = NuiRect(
        GetNuiScaleDimension(oPC, 50.0),
        GetNuiScaleDimension(oPC, 50.0),
        GetNuiScaleDimension(oPC, NEC_W),
        GetNuiScaleDimension(oPC, NEC_H));

    return NuiWindow(
        NuiCol(jRoot),
        JsonString("Nekromancja — Słudzy Ciemności"),
        NuiBind(NEC_WIN_GEOM),
        JsonBool(FALSE),
        JsonBool(FALSE),
        JsonBool(TRUE),
        JsonBool(FALSE),
        JsonBool(TRUE),
        NEC_EV_SCRIPT);
}

// ----------------------------------------------------------------
// Open / refresh window
// ----------------------------------------------------------------

void NecOpenWindow(object oPC)
{
    int nToken = NuiFindWindow(oPC, NEC_WINDOW);
    if (nToken != 0)
    {
        NuiSetGroupLayout(oPC, nToken, "root", NecBuildWindow(oPC));
        NecFeedRoster(oPC, nToken);
        NecClearDetail(oPC, nToken);
        NecFeedEssencePool(oPC, nToken);
        NecUpdateBindState(oPC, nToken);
        return;
    }

    nToken = NuiCreate(oPC, NecBuildWindow(oPC), NEC_WINDOW);
    if (nToken == 0) return;

    NuiSetBind(oPC, nToken, NEC_WIN_GEOM,
        NuiRect(50.0, 50.0,
            GetNuiScaleDimension(oPC, NEC_W),
            GetNuiScaleDimension(oPC, NEC_H)));

    NecFeedRoster(oPC, nToken);
    NecClearDetail(oPC, nToken);
    NecFeedEssencePool(oPC, nToken);
    NecUpdateBindState(oPC, nToken);
}

// ----------------------------------------------------------------
// Data feed helpers
// ----------------------------------------------------------------

void NecFeedRoster(object oPC, int nToken)
{
    json jServants = NecGetServants(oPC);
    int  nCount    = JsonGetLength(jServants);
    int  nMax      = NecGetMaxServants(oPC);

    NuiSetBind(oPC, nToken, NEC_BIND_SLOT_LBL,
        JsonString("Słudzy: " + IntToString(nCount) + " / " + IntToString(nMax)));
    NuiSetBind(oPC, nToken, NEC_BIND_ROW_COUNT, JsonInt(nCount));

    json jNames = JsonArray();
    json jTypes = JsonArray();
    json jHPs   = JsonArray();
    json jEsses = JsonArray();
    json jEncs  = JsonArray();

    int nSelId = GetLocalInt(oPC, NEC_LVAR_SEL_ID);
    int i;
    for (i = 0; i < nCount; i++)
    {
        json jRow   = JsonArrayGet(jServants, i);
        int  nId    = JsonGetInt   (JsonObjectGet(jRow, "id"));
        int  nHPCur = JsonGetInt   (JsonObjectGet(jRow, "hp_current"));
        int  nHPMax = JsonGetInt   (JsonObjectGet(jRow, "hp_max"));
        int  nEss   = JsonGetInt   (JsonObjectGet(jRow, "essence"));
        int  nType  = JsonGetInt   (JsonObjectGet(jRow, "servant_type"));
        string sName = JsonGetString(JsonObjectGet(jRow, "servant_name"));

        jNames = JsonArrayInsert(jNames, JsonString(sName));
        jTypes = JsonArrayInsert(jTypes, JsonString(NecTypeName(nType)));

        float fHP  = (nHPMax > 0) ? IntToFloat(nHPCur) / IntToFloat(nHPMax) : 0.0;
        float fEss = IntToFloat(nEss) / IntToFloat(NEC_MAX_ESSENCE);
        jHPs  = JsonArrayInsert(jHPs,  JsonFloat(fHP));
        jEsses = JsonArrayInsert(jEsses, JsonFloat(fEss));
        jEncs  = JsonArrayInsert(jEncs,  JsonBool(nId == nSelId));
    }

    NuiSetBind(oPC, nToken, NEC_BIND_ROW_NAME, jNames);
    NuiSetBind(oPC, nToken, NEC_BIND_ROW_TYPE, jTypes);
    NuiSetBind(oPC, nToken, NEC_BIND_ROW_HP,   jHPs);
    NuiSetBind(oPC, nToken, NEC_BIND_ROW_ESS,  jEsses);
    NuiSetBind(oPC, nToken, NEC_BIND_ROW_ENC,  jEncs);
}

void NecFeedDetail(object oPC, int nToken, int nServantId)
{
    json jRow = NecGetServant(nServantId);
    if (JsonGetType(jRow) == JSON_TYPE_NULL)
    {
        NecClearDetail(oPC, nToken);
        return;
    }

    string sName = JsonGetString(JsonObjectGet(jRow, "servant_name"));
    int    nType = JsonGetInt   (JsonObjectGet(jRow, "servant_type"));
    int    nHPCur= JsonGetInt   (JsonObjectGet(jRow, "hp_current"));
    int    nHPMax= JsonGetInt   (JsonObjectGet(jRow, "hp_max"));
    int    nEss  = JsonGetInt   (JsonObjectGet(jRow, "essence"));

    NuiSetBind(oPC, nToken, NEC_BIND_DET_NAME, JsonString(sName));
    NuiSetBind(oPC, nToken, NEC_BIND_DET_INFO,
        JsonString("Typ: " + NecTypeName(nType) +
                   "   PW: " + IntToString(nHPCur) + "/" + IntToString(nHPMax) +
                   "   Esn: " + IntToString(nEss) + "/" + IntToString(NEC_MAX_ESSENCE)));

    float fHP  = (nHPMax > 0) ? IntToFloat(nHPCur) / IntToFloat(nHPMax) : 0.0;
    float fEss = IntToFloat(nEss) / IntToFloat(NEC_MAX_ESSENCE);
    NuiSetBind(oPC, nToken, NEC_BIND_DET_HP_BAR,  JsonFloat(fHP));
    NuiSetBind(oPC, nToken, NEC_BIND_DET_ESS_BAR, JsonFloat(fEss));

    NuiSetBind(oPC, nToken, NEC_BIND_FEED_AMT, JsonString(IntToString(NEC_FEED_DEFAULT)));
    NuiSetBind(oPC, nToken, NEC_BIND_FEED_ENA,    JsonBool(TRUE));
    NuiSetBind(oPC, nToken, NEC_BIND_DISMISS_ENA, JsonBool(TRUE));
}

void NecClearDetail(object oPC, int nToken)
{
    NuiSetBind(oPC, nToken, NEC_BIND_DET_NAME,    JsonString("— brak wybranego sługi —"));
    NuiSetBind(oPC, nToken, NEC_BIND_DET_INFO,    JsonString(""));
    NuiSetBind(oPC, nToken, NEC_BIND_DET_HP_BAR,  JsonFloat(0.0));
    NuiSetBind(oPC, nToken, NEC_BIND_DET_ESS_BAR, JsonFloat(0.0));
    NuiSetBind(oPC, nToken, NEC_BIND_FEED_ENA,    JsonBool(FALSE));
    NuiSetBind(oPC, nToken, NEC_BIND_DISMISS_ENA, JsonBool(FALSE));
}

void NecFeedEssencePool(object oPC, int nToken)
{
    int nEss = NecGetEssencePool(oPC);
    NuiSetBind(oPC, nToken, NEC_BIND_ESSENCE_LBL,
        JsonString("Esencja Dusz: " + IntToString(nEss)));
}

// Recompute which interactive controls are enabled.
void NecUpdateBindState(object oPC, int nToken)
{
    int nCount = NecGetServantCount(oPC);
    int nMax   = NecGetMaxServants(oPC);
    int nPool  = NecGetEssencePool(oPC);

    int bCanBind = (nCount < nMax) && (nPool >= NEC_BIND_COST);
    NuiSetBind(oPC, nToken, NEC_BIND_BIND_ENA, JsonBool(bCanBind));
}

// ----------------------------------------------------------------
// Bind corpse (raise undead servant)
// ----------------------------------------------------------------

void NecBindCorpse(object oPC, object oCorpse)
{
    int nToken = NuiFindWindow(oPC, NEC_WINDOW);

    if (!GetIsObjectValid(oCorpse) ||
        GetObjectType(oCorpse) != OBJECT_TYPE_CREATURE ||
        !GetIsDead(oCorpse) ||
        GetIsPC(oCorpse))
    {
        SendMessageToPC(oPC, "[Nekromancja] Cel musi być zwłokami poległego stwora.");
        NecUpdateBindState(oPC, nToken);
        return;
    }

    if (GetDistanceBetween(oPC, oCorpse) > 5.0)
    {
        SendMessageToPC(oPC, "[Nekromancja] Zbliż się do zwłok, by nałożyć Pieczęć Krwi.");
        NecUpdateBindState(oPC, nToken);
        return;
    }

    int nCount = NecGetServantCount(oPC);
    int nMax   = NecGetMaxServants(oPC);
    if (nCount >= nMax)
    {
        SendMessageToPC(oPC, "[Nekromancja] Osiągnąłeś limit sług. Pożegnaj jednego, by przywołać nowego.");
        NecUpdateBindState(oPC, nToken);
        return;
    }

    if (!NecSpendEssenceFromPool(oPC, NEC_BIND_COST))
    {
        SendMessageToPC(oPC, "[Nekromancja] Niewystarczająca Esencja Dusz. Potrzebujesz " +
            IntToString(NEC_BIND_COST) + " punktów.");
        NecUpdateBindState(oPC, nToken);
        return;
    }

    int    nType   = NecGetServantType(oCorpse);
    int    nHPMax  = NecTypeBaseHP(nType);
    string sName   = GetName(oCorpse);

    // Placeholder tag; will be updated with the real DB id after insert.
    int    nId     = NecInsertServant(oPC, "NEC_PENDING", sName, nType, nHPMax, NEC_START_ESSENCE);
    if (nId == 0)
    {
        SendMessageToPC(oPC, "[Nekromancja] Błąd bazy danych — nie udało się zapisać sługi.");
        NecAddEssenceToPool(oPC, NEC_BIND_COST); // refund
        return;
    }

    string sTag  = NecServantTag(GetObjectUUID(oPC), nId);
    // Update the tag now that we have the real id.
    sqlquery qTag = SqlPrepareQueryCampaign("nec",
        "UPDATE nec_servants SET servant_tag = @tag WHERE id = @id");
    SqlBindString(qTag, "@tag", sTag);
    SqlBindInt(qTag,    "@id",  nId);
    SqlStep(qTag);

    // Spawn creature near PC.
    location lLoc   = GetLocation(oPC);
    string sResRef  = NecTypeResRef(nType);
    object oServant = CreateObject(OBJECT_TYPE_CREATURE, sResRef, lLoc, FALSE, sTag);

    if (!GetIsObjectValid(oServant))
    {
        SendMessageToPC(oPC, "[Nekromancja] Nie można wezwać stwora — sprawdź resref w hak.");
        NecDismissServant(nId);
        NecAddEssenceToPool(oPC, NEC_BIND_COST);
        return;
    }

    // Ally faction, follow PC.
    SetFaction(oServant, GetFaction(oPC));
    AssignCommand(oServant, ActionFollow(oPC, 2.0));

    // VFX on the corpse to mark it as bound.
    ApplyEffectToObject(DURATION_TYPE_INSTANT,
        EffectVisualEffect(VFX_IMP_DEATH), oCorpse);

    FloatingTextStringOnCreature(
        "Pieczęć Krwi pulsuje słabo... " + sName + " powstaje z martwych.",
        oPC, FALSE);

    if (nToken != 0)
    {
        NecFeedRoster(oPC, nToken);
        NecFeedEssencePool(oPC, nToken);
        NecUpdateBindState(oPC, nToken);
    }
}

// ----------------------------------------------------------------
// Feed essence to selected servant
// ----------------------------------------------------------------

void NecDoFeed(object oPC, int nToken, int nServantId)
{
    if (nServantId <= 0) return;

    string sAmtStr = JsonGetString(NuiGetBind(oPC, nToken, NEC_BIND_FEED_AMT));
    int    nAmount = StringToInt(sAmtStr);
    if (nAmount <= 0)
    {
        SendMessageToPC(oPC, "[Nekromancja] Podaj dodatnią liczbę punktów esencji.");
        return;
    }

    int nPool = NecGetEssencePool(oPC);
    if (nPool < nAmount)
    {
        SendMessageToPC(oPC, "[Nekromancja] Masz tylko " + IntToString(nPool) + " Esencji Dusz.");
        return;
    }

    json jRow = NecGetServant(nServantId);
    if (JsonGetType(jRow) == JSON_TYPE_NULL) return;

    int nCurrentEss = JsonGetInt(JsonObjectGet(jRow, "essence"));
    int nHeadroom   = NEC_MAX_ESSENCE - nCurrentEss;
    if (nHeadroom <= 0)
    {
        SendMessageToPC(oPC, "[Nekromancja] Sługa jest już nasycony esencją.");
        return;
    }

    int nActual = (nAmount > nHeadroom) ? nHeadroom : nAmount;
    if (!NecSpendEssenceFromPool(oPC, nActual))
    {
        SendMessageToPC(oPC, "[Nekromancja] Błąd przy pobieraniu esencji z puli.");
        return;
    }

    NecFeedServantEssence(nServantId, nActual, NEC_MAX_ESSENCE);

    string sServantName = JsonGetString(JsonObjectGet(jRow, "servant_name"));
    FloatingTextStringOnCreature(
        sServantName + " pochłania " + IntToString(nActual) + " pkt Esencji.",
        oPC, FALSE);

    NecFeedRoster(oPC, nToken);
    NecFeedDetail(oPC, nToken, nServantId);
    NecFeedEssencePool(oPC, nToken);
    NecUpdateBindState(oPC, nToken);
}

// ----------------------------------------------------------------
// Dismiss servant
// ----------------------------------------------------------------

void NecDoDismiss(object oPC, int nToken, int nServantId)
{
    if (nServantId <= 0) return;

    json jRow = NecGetServant(nServantId);
    if (JsonGetType(jRow) == JSON_TYPE_NULL) return;

    string sTag     = JsonGetString(JsonObjectGet(jRow, "servant_tag"));
    string sName    = JsonGetString(JsonObjectGet(jRow, "servant_name"));
    object oServant = GetObjectByTag(sTag);

    NecDismissServant(nServantId);

    if (GetIsObjectValid(oServant))
    {
        ApplyEffectToObject(DURATION_TYPE_INSTANT,
            EffectVisualEffect(VFX_IMP_DEATH), oServant);
        DestroyObject(oServant, 1.0);
    }

    FloatingTextStringOnCreature(
        sName + " rozpada się w pył. Wasze więzi zostają zerwane.",
        oPC, FALSE);

    DeleteLocalInt(oPC, NEC_LVAR_SEL_ID);
    NecFeedRoster(oPC, nToken);
    NecClearDetail(oPC, nToken);
    NecFeedEssencePool(oPC, nToken);
    NecUpdateBindState(oPC, nToken);
}

// ----------------------------------------------------------------
// Servant lifecycle — spawn / despawn
// ----------------------------------------------------------------

object NecSpawnServant(object oPC, json jRow)
{
    string sTag    = JsonGetString(JsonObjectGet(jRow, "servant_tag"));
    int    nType   = JsonGetInt   (JsonObjectGet(jRow, "servant_type"));
    string sResRef = NecTypeResRef(nType);
    location lLoc  = GetLocation(oPC);

    object oServant = CreateObject(OBJECT_TYPE_CREATURE, sResRef, lLoc, FALSE, sTag);
    if (!GetIsObjectValid(oServant)) return OBJECT_INVALID;

    SetFaction(oServant, GetFaction(oPC));
    AssignCommand(oServant, ActionFollow(oPC, 2.0));
    return oServant;
}

// Restores all active servants when a PC logs in.
void NecSpawnServants(object oPC)
{
    json jServants = NecGetServants(oPC);
    int  nCount    = JsonGetLength(jServants);
    int  i;
    for (i = 0; i < nCount; i++)
    {
        json   jRow  = JsonArrayGet(jServants, i);
        string sTag  = JsonGetString(JsonObjectGet(jRow, "servant_tag"));
        int    nId   = JsonGetInt   (JsonObjectGet(jRow, "id"));

        // Only spawn if not already in the world.
        if (!GetIsObjectValid(GetObjectByTag(sTag)))
            NecSpawnServant(oPC, jRow);
    }
}

// Saves live HP and destroys creature objects when a PC logs out.
void NecDespawnServants(object oPC)
{
    json jServants = NecGetServants(oPC);
    int  nCount    = JsonGetLength(jServants);
    int  i;
    for (i = 0; i < nCount; i++)
    {
        json   jRow     = JsonArrayGet(jServants, i);
        int    nId      = JsonGetInt   (JsonObjectGet(jRow, "id"));
        string sTag     = JsonGetString(JsonObjectGet(jRow, "servant_tag"));
        object oServant = GetObjectByTag(sTag);

        if (GetIsObjectValid(oServant))
        {
            int nHP = GetCurrentHitPoints(oServant);
            NecUpdateServantHP(nId, (nHP < 0) ? 0 : nHP);
            DestroyObject(oServant);
        }
    }
}

// ----------------------------------------------------------------
// Heartbeat: decay and HP sync
// ----------------------------------------------------------------

// Called once per module heartbeat for a single PC.
void NecProcessDecay(object oPC)
{
    json jServants = NecGetServants(oPC);
    int  nCount    = JsonGetLength(jServants);
    int  i;
    for (i = 0; i < nCount; i++)
    {
        json   jRow  = JsonArrayGet(jServants, i);
        int    nId   = JsonGetInt(JsonObjectGet(jRow, "id"));
        int    nType = JsonGetInt(JsonObjectGet(jRow, "servant_type"));
        int    nEss  = JsonGetInt(JsonObjectGet(jRow, "essence"));
        string sTag  = JsonGetString(JsonObjectGet(jRow, "servant_tag"));
        string sName = JsonGetString(JsonObjectGet(jRow, "servant_name"));

        int nDrain = NecTypeDrain(nType);
        int nNew   = nEss - nDrain;

        if (nNew <= 0)
        {
            // Essence depleted: servant collapses.
            NecDismissServant(nId);
            object oServant = GetObjectByTag(sTag);
            if (GetIsObjectValid(oServant))
            {
                ApplyEffectToObject(DURATION_TYPE_INSTANT,
                    EffectVisualEffect(VFX_IMP_DEATH), oServant);
                DestroyObject(oServant, 0.5);
            }
            FloatingTextStringOnCreature(
                sName + " obraca się w proch — esencja wyczerpana.",
                oPC, FALSE);

            // Refresh open window.
            int nToken = NuiFindWindow(oPC, NEC_WINDOW);
            if (nToken != 0)
            {
                int nSelId = GetLocalInt(oPC, NEC_LVAR_SEL_ID);
                NecFeedRoster(oPC, nToken);
                if (nSelId == nId)
                {
                    DeleteLocalInt(oPC, NEC_LVAR_SEL_ID);
                    NecClearDetail(oPC, nToken);
                }
                NecUpdateBindState(oPC, nToken);
            }
        }
        else
        {
            NecUpdateServantEssence(nId, nNew);
        }
    }
}

// Syncs live HP of all servants with DB values and destroys dead ones.
void NecSyncServantHP(object oPC)
{
    json jServants = NecGetServants(oPC);
    int  nCount    = JsonGetLength(jServants);
    int  i;
    for (i = 0; i < nCount; i++)
    {
        json   jRow     = JsonArrayGet(jServants, i);
        int    nId      = JsonGetInt   (JsonObjectGet(jRow, "id"));
        string sTag     = JsonGetString(JsonObjectGet(jRow, "servant_tag"));
        string sName    = JsonGetString(JsonObjectGet(jRow, "servant_name"));
        object oServant = GetObjectByTag(sTag);

        if (!GetIsObjectValid(oServant)) continue;

        int nHP = GetCurrentHitPoints(oServant);
        if (nHP <= 0)
        {
            NecDismissServant(nId);
            DestroyObject(oServant);
            FloatingTextStringOnCreature(
                sName + " pada martwy po raz drugi. Krąg zostaje zamknięty.",
                oPC, FALSE);

            int nToken = NuiFindWindow(oPC, NEC_WINDOW);
            if (nToken != 0)
            {
                int nSelId = GetLocalInt(oPC, NEC_LVAR_SEL_ID);
                NecFeedRoster(oPC, nToken);
                if (nSelId == nId)
                {
                    DeleteLocalInt(oPC, NEC_LVAR_SEL_ID);
                    NecClearDetail(oPC, nToken);
                }
                NecUpdateBindState(oPC, nToken);
            }
        }
        else
        {
            NecUpdateServantHP(nId, nHP);
        }
    }
}

// ----------------------------------------------------------------
// Module integration hook — call from your OnCreatureDeath script
// ----------------------------------------------------------------

// Call this from the area/module OnCreatureDeath with oKiller = GetLastKiller()
// and oCorpse = OBJECT_SELF. Adds essence to the killer's pool if they're a PC.
void NecOnCreatureDeath(object oKiller, object oCorpse)
{
    if (!GetIsPC(oKiller)) return;
    if (GetIsPC(oCorpse))  return;        // don't yield essence for player kills

    int nAmount = NecEssenceForCR(oCorpse);
    if (nAmount <= 0) return;

    NecAddEssenceToPool(oKiller, nAmount);

    int nToken = NuiFindWindow(oKiller, NEC_WINDOW);
    if (nToken != 0)
    {
        NecFeedEssencePool(oKiller, nToken);
        NecUpdateBindState(oKiller, nToken);
    }
}
