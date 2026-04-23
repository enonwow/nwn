#include "nw_inc_nui"

// --- Window IDs --------------------------------------------------------------
const string SM_WIN_MENU   = "SM_MENU";
const string SM_WIN_DELETE = "SM_DELETE";

// --- Swap group ---------------------------------------------------------------
const string SM_GRP_SWAP = "SM_SWAP";
const string SM_BTN_BACK = "SM_BTN_BACK";

// --- LVARs on PC -------------------------------------------------------------
const string SM_LVAR_SEL_IDX     = "SM_SEL_IDX";     // selected seq index in menu (-1 = none)
const string SM_LVAR_EDIT_IDX    = "SM_EDIT_IDX";    // index being edited (-1 = new)
const string SM_LVAR_SPELLS      = "SM_SPELLS";      // JsonArray spells being built in create window
const string SM_LVAR_PENDING     = "SM_PENDING";     // JsonArray spells waiting for target selection
const string SM_LVAR_TARGET_MODE = "SM_TARGET_MODE"; // int target mode for pending cast

// --- Menu bind names ---------------------------------------------------------
const string SM_BIND_M_NAMES    = "SM_M_NAMES";
const string SM_BIND_M_COUNT    = "SM_M_COUNT";
const string SM_BIND_M_ENC      = "SM_M_ENC";
const string SM_BIND_M_ROW      = "SM_M_ROW";
const string SM_BIND_M_CAST_EN  = "SM_M_CAST_EN";
const string SM_BIND_M_EDIT_EN  = "SM_M_EDIT_EN";
const string SM_BIND_M_DEL_EN   = "SM_M_DEL_EN";

// --- Create window bind names -------------------------------------------------
const string SM_BIND_C_SPELL_NAMES  = "SM_C_SP_NAMES";
const string SM_BIND_C_SPELL_COUNT  = "SM_C_SP_COUNT";
const string SM_BIND_C_SPELL_ICONS  = "SM_C_SP_ICONS";
const string SM_BIND_C_SPELL_ENC   = "SM_C_SP_ENC";
const string SM_BIND_C_SPELL_ROW   = "SM_C_SP_ROW";
const string SM_BIND_C_SEL_NAMES   = "SM_C_SEL_NAMES";
const string SM_BIND_C_SEL_ICONS   = "SM_C_SEL_ICONS";
const string SM_BIND_C_SEL_COUNT   = "SM_C_SEL_COUNT";
const string SM_BIND_C_SEQ_NAME    = "SM_C_SEQ_NAME";
const string SM_BIND_C_CLS_ENT     = "SM_C_CLS_ENT";
const string SM_BIND_C_CLS_IDX     = "SM_C_CLS_IDX";
const string SM_BIND_C_LVL_ENT     = "SM_C_LVL_ENT";
const string SM_BIND_C_LVL_IDX     = "SM_C_LVL_IDX";
const string SM_BIND_C_META_ENT    = "SM_C_META_ENT";
const string SM_BIND_C_META_IDX    = "SM_C_META_IDX";
const string SM_BIND_C_TARGET_MODE = "SM_C_TMODE";
const int SM_TARGET_SELF  = 0;
const int SM_TARGET_ALLY  = 1;
const int SM_TARGET_ENEMY = 2;
const int SM_TARGET_AREA  = 3;
const string SM_BIND_C_ADD_EN      = "SM_C_ADD_EN";
const string SM_BIND_C_SAVE_EN     = "SM_C_SAVE_EN";
const string SM_BIND_C_SPELL_META_VIS  = "SM_C_SP_MV";
const string SM_BIND_C_SPELL_META_ICON = "SM_C_SP_MI";
const string SM_BIND_C_SPELL_DOM_VIS   = "SM_C_SP_DV";
const string SM_BIND_C_SPELL_DOM_ICON  = "SM_C_SP_DI";
const string SM_BIND_C_SPELL_SEARCH    = "SM_C_SP_SRCH";

// --- Button IDs ---------------------------------------------------------------
const string SM_BTN_NEW        = "SM_BTN_NEW";
const string SM_BTN_CAST       = "SM_BTN_CAST";
const string SM_BTN_EDIT       = "SM_BTN_EDIT";
const string SM_BTN_DELETE     = "SM_BTN_DELETE";
const string SM_BTN_M_ROW      = "SM_BTN_M_ROW";
const string SM_BTN_SAVE       = "SM_BTN_SAVE";
const string SM_BTN_CANCEL     = "SM_BTN_CANCEL";
const string SM_BTN_C_SP_ROW   = "SM_BTN_C_SP_ROW";
const string SM_BTN_C_ADD      = "SM_BTN_C_ADD";
const string SM_BTN_C_DEL_SEL  = "SM_BTN_C_DEL_SEL"; // + IntToString(idx)
const string SM_GRP_SEL_ICONS  = "SM_GRP_SEL";
const string SM_BTN_DEL_CONFIRM = "SM_BTN_DEL_OK";
const string SM_BTN_DEL_CANCEL  = "SM_BTN_DEL_CANCEL";

// --- Limits -------------------------------------------------------------------
const int SM_MAX_SEQ    = 10;
const int SM_MAX_SPELLS = 20;

// --- Spell JSON field keys ----------------------------------------------------
const string SM_F_ID     = "id";
const string SM_F_CLASS  = "class";
const string SM_F_LEVEL  = "level";
const string SM_F_META   = "meta";
const string SM_F_DOMAIN = "domain";
const string SM_F_NAME       = "name";
const string SM_F_ICON       = "icon";
const string SM_F_DOMAIN_ICON = "dicon";

#include "sql_sm"

// --- Minimal NUI helpers (no lib_nui dependency) ------------------------------
const string SM_EVENT_WATCH      = "watch";
const string SM_EVENT_OPEN       = "open";
const string SM_EVENT_CLOSE      = "close";
const string SM_EVENT_CLICK      = "click";
const string SM_EVENT_MOUSEDOWN  = "mousedown";
const string SM_EVENT_MOUSEUP    = "mouseup";
const string SM_EVENT_MOUSESCROLL = "mousescroll";

int SmHexToInt(string s)
{
    if(GetStringLeft(s, 2) == "0x" || GetStringLeft(s, 2) == "0X")
        s = GetStringRight(s, GetStringLength(s) - 2);
    s = GetStringLowerCase(s);
    int nResult = 0;
    int nLen = GetStringLength(s);
    int i;
    for(i = 0; i < nLen; i++)
    {
        int d = FindSubString("0123456789abcdef", GetSubString(s, i, 1));
        if(d < 0) return nResult;
        nResult = nResult * 16 + d;
    }
    return nResult;
}

float SmScale(object oPC, float fVal)
{
    int nScale = GetPlayerDeviceProperty(oPC, PLAYER_DEVICE_PROPERTY_GUI_SCALE);
    float fScale = nScale / 100.0;
    if(fScale > 1.5) fScale = 1.5;
    return fVal / fScale;
}

json SmEmptyRow(object oPC, float fH)
{
    json jRow = JsonArray();
    jRow = JsonArrayInsert(jRow, NuiHeight(NuiSpacer(), SmScale(oPC, fH)));
    return NuiRow(jRow);
}

void SmOffEnc(object oPC, int nToken, string sEncBind, string sRowBind)
{
    json jRow = NuiGetBind(oPC, nToken, sRowBind);
    if(JsonGetType(jRow) == JSON_TYPE_INTEGER)
    {
        int nRow = JsonGetInt(jRow);
        json jEnc = NuiGetBind(oPC, nToken, sEncBind);
        jEnc = JsonArraySet(jEnc, nRow, JsonBool(FALSE));
        NuiSetBind(oPC, nToken, sEncBind, jEnc);
    }
    NuiSetBind(oPC, nToken, sRowBind, JsonNull());
}

void SmOnEnc(object oPC, int nToken, string sEncBind, string sRowBind, int nRow)
{
    json jEnc = NuiGetBind(oPC, nToken, sEncBind);
    jEnc = JsonArraySet(jEnc, nRow, JsonBool(TRUE));
    NuiSetBind(oPC, nToken, sEncBind, jEnc);
    NuiSetBind(oPC, nToken, sRowBind, JsonInt(nRow));
}

// --- Spell helpers ------------------------------------------------------------

int SmGetLevelBeforeMeta(int nLevel, int nMeta)
{
    if(nMeta & METAMAGIC_EXTEND)   nLevel -= 1;
    if(nMeta & METAMAGIC_EMPOWER)  nLevel -= 2;
    if(nMeta & METAMAGIC_QUICKEN)  nLevel -= 4;
    if(nMeta & METAMAGIC_MAXIMIZE) nLevel -= 3;
    if(nMeta & METAMAGIC_SILENT)   nLevel -= 1;
    if(nMeta & METAMAGIC_STILL)    nLevel -= 1;
    return nLevel;
}

int SmIsAvailable(object oPC, int nSpellId, int nClassId, int nLevel, int nMeta, int bDomain)
{
    if(Get2DAString("classes", "MemorizesSpells", nClassId) == "1")
    {
        int nCount = GetMemorizedSpellCountByLevel(oPC, nClassId, nLevel);
        int i;
        for(i = 0; i < nCount; i++)
        {
            if(GetMemorizedSpellId(oPC, nClassId, nLevel, i) == nSpellId
               && GetMemorizedSpellReady(oPC, nClassId, nLevel, i))
                return TRUE;
        }
        return FALSE;
    }
    int nDomLvl = bDomain ? SmGetLevelBeforeMeta(nLevel, nMeta) : 0;
    return GetSpellUsesLeft(oPC, nClassId, nSpellId, nMeta, nDomLvl) > 0;
}

// Returns how many times oPC can still cast nSpellId (for slot budget across a sequence).
int SmCountAvailable(object oPC, int nSpellId, int nClassId, int nLevel, int nMeta, int bDomain)
{
    if(Get2DAString("classes", "MemorizesSpells", nClassId) == "1")
    {
        int nCount = GetMemorizedSpellCountByLevel(oPC, nClassId, nLevel);
        int nReady = 0;
        int i;
        for(i = 0; i < nCount; i++)
        {
            if(GetMemorizedSpellId(oPC, nClassId, nLevel, i) == nSpellId
               && GetMemorizedSpellReady(oPC, nClassId, nLevel, i))
                nReady++;
        }
        return nReady;
    }
    int nDomLvl = bDomain ? SmGetLevelBeforeMeta(nLevel, nMeta) : 0;
    return GetSpellUsesLeft(oPC, nClassId, nSpellId, nMeta, nDomLvl);
}

// Returns icon resref for metamagic overlay (bottom-left corner of spell icon).
string SmGetMetaIcon(int nMeta)
{
    if(nMeta == METAMAGIC_EMPOWER)  return "ir_empower_thumbnail";
    if(nMeta == METAMAGIC_EXTEND)   return "ir_extend_thumbnail";
    if(nMeta == METAMAGIC_MAXIMIZE) return "ir_maximize_thumbnail";
    if(nMeta == METAMAGIC_QUICKEN)  return "ir_quicken_thumbnail";
    if(nMeta == METAMAGIC_SILENT)   return "ir_silent_thumbnail";
    if(nMeta == METAMAGIC_STILL)    return "ir_still_thumbnail";
    return "";
}

// Returns the slot-level cost of a metamagic flag (NWScript METAMAGIC_* encoding).
int SmMetaCost(int nMeta)
{
    int nCost = 0;
    if(nMeta & METAMAGIC_EXTEND)   nCost += 1;
    if(nMeta & METAMAGIC_EMPOWER)  nCost += 2;
    if(nMeta & METAMAGIC_QUICKEN)  nCost += 4;
    if(nMeta & METAMAGIC_MAXIMIZE) nCost += 3;
    if(nMeta & METAMAGIC_SILENT)   nCost += 1;
    if(nMeta & METAMAGIC_STILL)    nCost += 1;
    return nCost;
}

// Returns spell IDs available to oPC at base spell level nBaseLevel for nClassId.
// Divine prepared (MemorizesSpells=1, SpellBookRestricted=0 — Cleric/Druid etc.): scans spells.2da.
// Spellbook classes (Wizard) or spontaneous (Sorc/Bard): GetKnownSpellId.
json SmSpellIds(object oPC, int nClassId, int nBaseLevel)
{
    json jIds = JsonArray();
    if(Get2DAString("classes", "MemorizesSpells", nClassId) == "1"
    && Get2DAString("classes", "SpellBookRestricted", nClassId) != "1")
    {
        string sCol = Get2DAString("classes", "SpellTableColumn", nClassId);
        int nTotal = Get2DARowCount("spells"); int i;
        for(i = 0; i < nTotal; i++)
        {
            string sL = Get2DAString("spells", sCol, i);
            if(sL == "" || sL == "****") continue;
            if(StringToInt(sL) == nBaseLevel)
                jIds = JsonArrayInsert(jIds, JsonInt(i));
        }
    }
    else
    {
        int nCount = GetKnownSpellCount(oPC, nClassId, nBaseLevel); int i;
        for(i = 0; i < nCount; i++)
            jIds = JsonArrayInsert(jIds, JsonInt(GetKnownSpellId(oPC, nClassId, nBaseLevel, i)));
    }
    return jIds;
}

// Returns TRUE if nSpellId fits the given target mode filter.
int SmMatchesTargetMode(int nSpellId, int nTargetMode)
{
    int nTF = SmHexToInt(Get2DAString("spells", "TargetType", nSpellId));
    int bHostile = Get2DAString("spells", "HostileSetting", nSpellId) == "1";
    if(nTargetMode == SM_TARGET_SELF)  return (nTF & 0x01) != 0;
    if(nTargetMode == SM_TARGET_ALLY)  return (nTF & 0x02) != 0 && !bHostile;
    if(nTargetMode == SM_TARGET_ENEMY) return ((nTF & 0x02) || (nTF & 0x04)) && bHostile;
    if(nTargetMode == SM_TARGET_AREA)  return (nTF & 0x04) != 0;
    return FALSE;
}

// Build spell list for create window.
int SmClassHasDomains(object oPC, int nClassId);

// If nId has SubRadSpell entries, returns them as separate entries (parent hidden).
// sBaseName = parent name, sSuffix = e.g. " - Empower", bDomain = 1 for domain spells.
// sDomIcon = domain icon resref (or "" for non-domain spells).
json SmGetSubRadEntries(int nId, string sBaseName, string sSuffix, int nMeta,
                        int nTargetMode, int bDomain, string sDomIcon)
{
    json jSubs = JsonArray();
    int k;
    for(k = 1; k <= 5; k++)
    {
        string sSub = Get2DAString("spells", "SubRadSpell" + IntToString(k), nId);
        if(sSub == "" || sSub == "****") continue;
        int nSubId = StringToInt(sSub);
        if(nSubId <= 0) continue;
        if(!SmMatchesTargetMode(nSubId, nTargetMode)) continue;
        string sSubName = GetStringByStrRef(StringToInt(Get2DAString("spells", "Name", nSubId)));
        if(sSubName == "" || GetStringLeft(sSubName, 3) == "Bad") continue;
        json jE = JsonObject();
        jE = JsonObjectSet(jE, SM_F_ID,     JsonInt(nSubId));
        jE = JsonObjectSet(jE, SM_F_NAME,   JsonString(sBaseName + " — " + sSubName + sSuffix));
        jE = JsonObjectSet(jE, SM_F_ICON,   JsonString(Get2DAString("spells", "IconResRef", nSubId)));
        jE = JsonObjectSet(jE, SM_F_META,        JsonInt(nMeta));
        jE = JsonObjectSet(jE, SM_F_DOMAIN,      JsonInt(bDomain));
        jE = JsonObjectSet(jE, SM_F_DOMAIN_ICON, JsonString(sDomIcon));
        jSubs = JsonArrayInsert(jSubs, jE);
    }
    return jSubs;
}

// Gathers meta-variant entries for one metamagic type; returns empty array if filter/feat mismatch.
// nMetaFilter = nMeta from SmGatherSpells (0 = show all, non-0 = only that type).
json SmGatherMetaSpells(object oPC, int nClassId, int nLevel,
    int nTargetMode, int nMetaFilter,
    int nMetaFlag, int nCost, int nMetaBit, int nFeat, string sSuffix)
{
    json jOut = JsonArray();
    if(nMetaFilter != 0 && nMetaFilter != nMetaFlag) return jOut;
    if(!GetHasFeat(nFeat, oPC)) return jOut;
    int nBase = nLevel - nCost;
    if(nBase < 0) return jOut;
    json jIds = SmSpellIds(oPC, nClassId, nBase);
    int i;
    for(i = 0; i < JsonGetLength(jIds); i++)
    {
        int nId = JsonGetInt(JsonArrayGet(jIds, i));
        if(!(SmHexToInt(Get2DAString("spells", "MetaMagic", nId)) & nMetaBit)) continue;
        if(!SmMatchesTargetMode(nId, nTargetMode)) continue;
        string sName = GetStringByStrRef(StringToInt(Get2DAString("spells", "Name", nId)));
        if(sName == "" || GetStringLeft(sName, 3) == "Bad") continue;
        json jE = JsonObject();
        jE = JsonObjectSet(jE, SM_F_ID,          JsonInt(nId));
        jE = JsonObjectSet(jE, SM_F_NAME,        JsonString(sName + sSuffix));
        jE = JsonObjectSet(jE, SM_F_ICON,        JsonString(Get2DAString("spells", "IconResRef", nId)));
        jE = JsonObjectSet(jE, SM_F_META,        JsonInt(nMetaFlag));
        jE = JsonObjectSet(jE, SM_F_DOMAIN,      JsonInt(0));
        jE = JsonObjectSet(jE, SM_F_DOMAIN_ICON, JsonString(""));
        json jSubs = SmGetSubRadEntries(nId, sName, sSuffix, nMetaFlag, nTargetMode, 0, "");
        if(JsonGetLength(jSubs) > 0) {
            int s; for(s = 0; s < JsonGetLength(jSubs); s++)
                jOut = JsonArrayInsert(jOut, JsonArrayGet(jSubs, s));
        } else {
            jOut = JsonArrayInsert(jOut, jE);
        }
    }
    return jOut;
}

// nLevel = SLOT level. Base spells appear at their base level, meta variants
// at (base + cost). A spell appears here only when base + cost == nLevel.
// nMeta  = 0: show base spells (base==nLevel) + all meta variants (base+cost==nLevel).
//          non-0: show only that meta type (base+cost==nLevel, spell supports meta).
// nTargetMode = SM_TARGET_SELF/ALLY/ENEMY/AREA — filters by TargetType + HostileSetting.
// Domain spells are always included (no checkbox), also filtered by nTargetMode.
// Returns JsonArray of {id, name, icon, meta, domain, dicon}.
json SmGatherSpells(object oPC, int nClassId, int nLevel, int nTargetMode, int nMeta)
{
    json jResult = JsonArray();

    // -- Base spells: slot level == nLevel, only when Meta = Brak -------------
    if(nMeta == 0)
    {
        json jIds = SmSpellIds(oPC, nClassId, nLevel); int i;
        for(i = 0; i < JsonGetLength(jIds); i++)
        {
            int nId = JsonGetInt(JsonArrayGet(jIds, i));
            if(!SmMatchesTargetMode(nId, nTargetMode)) continue;
            string sName = GetStringByStrRef(StringToInt(Get2DAString("spells", "Name", nId)));
            if(sName == "" || GetStringLeft(sName, 3) == "Bad") continue;
            json jE = JsonObject();
            jE = JsonObjectSet(jE, SM_F_ID,          JsonInt(nId));
            jE = JsonObjectSet(jE, SM_F_NAME,        JsonString(sName));
            jE = JsonObjectSet(jE, SM_F_ICON,        JsonString(Get2DAString("spells", "IconResRef", nId)));
            jE = JsonObjectSet(jE, SM_F_META,        JsonInt(0));
            jE = JsonObjectSet(jE, SM_F_DOMAIN_ICON, JsonString(""));
            json jSubsB = SmGetSubRadEntries(nId, sName, "", 0, nTargetMode, 0, "");
            if(JsonGetLength(jSubsB) > 0) { int sB; for(sB = 0; sB < JsonGetLength(jSubsB); sB++) jResult = JsonArrayInsert(jResult, JsonArrayGet(jSubsB, sB)); }
            else jResult = JsonArrayInsert(jResult, jE);
        }
    }

    // -- Domain spells: from domains.2da, always shown, filtered by target mode -
    if(nMeta == 0 && SmClassHasDomains(oPC, nClassId))
    {
        int nDomIdx;
        for(nDomIdx = 1; nDomIdx <= 2; nDomIdx++)
        {
            int nDomain = GetDomain(oPC, nDomIdx, nClassId);
            if(nDomain == 0) continue;
            string sDomStr = Get2DAString("domains", "Level_" + IntToString(nLevel), nDomain);
            if(sDomStr == "" || sDomStr == "****") continue;
            int nDomId = StringToInt(sDomStr);
            int bDup = FALSE; int kk;
            for(kk = 0; kk < JsonGetLength(jResult); kk++)
                if(JsonGetInt(JsonObjectGet(JsonArrayGet(jResult, kk), SM_F_ID)) == nDomId) { bDup = TRUE; break; }
            if(bDup) continue;
            if(!SmMatchesTargetMode(nDomId, nTargetMode)) continue;
            string sDomName = GetStringByStrRef(StringToInt(Get2DAString("spells", "Name", nDomId)));
            if(sDomName == "" || GetStringLeft(sDomName, 3) == "Bad") continue;
            string sDomIconRes = GetStringLowerCase(Get2DAString("domains", "Icon", nDomain));
            json jDE = JsonObject();
            jDE = JsonObjectSet(jDE, SM_F_ID,          JsonInt(nDomId));
            jDE = JsonObjectSet(jDE, SM_F_NAME,        JsonString(sDomName));
            jDE = JsonObjectSet(jDE, SM_F_ICON,        JsonString(Get2DAString("spells", "IconResRef", nDomId)));
            jDE = JsonObjectSet(jDE, SM_F_META,        JsonInt(0));
            jDE = JsonObjectSet(jDE, SM_F_DOMAIN,      JsonInt(1));
            jDE = JsonObjectSet(jDE, SM_F_DOMAIN_ICON, JsonString(sDomIconRes));
            json jSubsDom = SmGetSubRadEntries(nDomId, sDomName, "", 0, nTargetMode, 1, sDomIconRes);
            if(JsonGetLength(jSubsDom) > 0) { int sD; for(sD = 0; sD < JsonGetLength(jSubsDom); sD++) jResult = JsonArrayInsert(jResult, JsonArrayGet(jSubsDom, sD)); }
            else jResult = JsonArrayInsert(jResult, jDE);
        }
    }

    // -- Metamagic variants (Empower/Extend/Maximize/Quicken) -----------------
    json jMeta; int m;
    jMeta = SmGatherMetaSpells(oPC, nClassId, nLevel, nTargetMode, nMeta,
        METAMAGIC_EMPOWER,  2, 0x01, FEAT_EMPOWER_SPELL,  " - Empower");
    for(m = 0; m < JsonGetLength(jMeta); m++) jResult = JsonArrayInsert(jResult, JsonArrayGet(jMeta, m));

    jMeta = SmGatherMetaSpells(oPC, nClassId, nLevel, nTargetMode, nMeta,
        METAMAGIC_EXTEND,   1, 0x02, FEAT_EXTEND_SPELL,   " - Extend");
    for(m = 0; m < JsonGetLength(jMeta); m++) jResult = JsonArrayInsert(jResult, JsonArrayGet(jMeta, m));

    jMeta = SmGatherMetaSpells(oPC, nClassId, nLevel, nTargetMode, nMeta,
        METAMAGIC_MAXIMIZE, 3, 0x04, FEAT_MAXIMIZE_SPELL, " - Maximize");
    for(m = 0; m < JsonGetLength(jMeta); m++) jResult = JsonArrayInsert(jResult, JsonArrayGet(jMeta, m));

    jMeta = SmGatherMetaSpells(oPC, nClassId, nLevel, nTargetMode, nMeta,
        METAMAGIC_QUICKEN,  4, 0x08, FEAT_QUICKEN_SPELL,  " - Quicken");
    for(m = 0; m < JsonGetLength(jMeta); m++) jResult = JsonArrayInsert(jResult, JsonArrayGet(jMeta, m));

    return jResult;
}

// TRUE if nClassId grants domain spells to oPC (i.e. first domain is defined).
int SmClassHasDomains(object oPC, int nClassId)
{
    return GetDomain(oPC, 1, nClassId) != 0;
}

// --- Build metamagic combo entries for PC (only feats they have) --------------
// Returns [[label, METAMAGIC_*], ...]; always includes Brak (0).
json SmGetPlayerMetas(object oPC)
{
    json jM = JsonArray();
    jM = JsonArrayInsert(jM, JsonArrayInsert(JsonArrayInsert(JsonArray(), JsonString("None")),    JsonInt(0)));
    if(GetHasFeat(FEAT_EMPOWER_SPELL,  oPC)) jM = JsonArrayInsert(jM, JsonArrayInsert(JsonArrayInsert(JsonArray(), JsonString("Empower")),  JsonInt(METAMAGIC_EMPOWER)));
    if(GetHasFeat(FEAT_EXTEND_SPELL,   oPC)) jM = JsonArrayInsert(jM, JsonArrayInsert(JsonArrayInsert(JsonArray(), JsonString("Extend")),   JsonInt(METAMAGIC_EXTEND)));
    if(GetHasFeat(FEAT_MAXIMIZE_SPELL, oPC)) jM = JsonArrayInsert(jM, JsonArrayInsert(JsonArrayInsert(JsonArray(), JsonString("Maximize")), JsonInt(METAMAGIC_MAXIMIZE)));
    if(GetHasFeat(FEAT_QUICKEN_SPELL,  oPC)) jM = JsonArrayInsert(jM, JsonArrayInsert(JsonArrayInsert(JsonArray(), JsonString("Quicken")),  JsonInt(METAMAGIC_QUICKEN)));
    return jM;
}

// --- Build spell level combo entries for a specific class ---------------------
// Returns [[label, slotLevel], ...] for SLOT levels where PC would see >= 1 spell.
// Prepared casters: uses GetMemorizedSpellCountByLevel to check actual slot availability.
// Spontaneous casters: uses GetKnownSpellCount + nMaxBase cap for meta slot levels.
json SmGetPlayerLevels(object oPC, int nClassId)
{
    int bEmp = GetHasFeat(FEAT_EMPOWER_SPELL,  oPC);
    int bExt = GetHasFeat(FEAT_EXTEND_SPELL,   oPC);
    int bMax = GetHasFeat(FEAT_MAXIMIZE_SPELL, oPC);
    int bQck = GetHasFeat(FEAT_QUICKEN_SPELL,  oPC);
    // Divine prepared (Cleric/Druid etc.): has memorized slots, all class spells available.
    // Spellbook restricted (Wizard) or spontaneous (Sorc/Bard): known spells list.
    int bDivine = Get2DAString("classes", "MemorizesSpells", nClassId) == "1"
               && Get2DAString("classes", "SpellBookRestricted", nClassId) != "1";

    // Build bitmask of levels that have spells/slots
    int nHasMask = 0;
    int nLvl;
    if(bDivine)
    {
        // Cross-check slots against spells.2da: GetMemorizedSpellCountByLevel can return > 0
        // for level 0 even when the class has no spells there (e.g. Ranger), which would add
        // a "ghost" level 0 entry to the combo and shift all visible levels by one.
        string sDivCol = Get2DAString("classes", "SpellTableColumn", nClassId);
        int nSpellRows = Get2DARowCount("spells"); int nSpellRow;
        int nSpellMask = 0;
        for(nSpellRow = 0; nSpellRow < nSpellRows; nSpellRow++)
        {
            string sL = Get2DAString("spells", sDivCol, nSpellRow);
            if(sL == "" || sL == "****") continue;
            int nSL = StringToInt(sL);
            if(nSL >= 0 && nSL <= 9) nSpellMask |= (1 << nSL);
        }
        for(nLvl = 0; nLvl <= 9; nLvl++)
            if(GetMemorizedSpellCountByLevel(oPC, nClassId, nLvl) > 0 && ((nSpellMask >> nLvl) & 1))
                nHasMask |= (1 << nLvl);
    }
    else
    {
        for(nLvl = 0; nLvl <= 9; nLvl++)
            if(GetKnownSpellCount(oPC, nClassId, nLvl) > 0)
                nHasMask |= (1 << nLvl);
    }

    // For non-divine (Wizard/Sorc/Bard): meta can create slot levels beyond known base levels.
    // Cap at nMaxBase to avoid showing unreachable meta levels.
    int nMaxBase = 0;
    if(!bDivine)
        for(nLvl = 9; nLvl >= 0; nLvl--)
            if((nHasMask >> nLvl) & 1) { nMaxBase = nLvl; break; }

    json jEntries = JsonArray();
    int nLevel;
    for(nLevel = 0; nLevel <= 9; nLevel++)
    {
        int bHas = (nHasMask >> nLevel) & 1;
        if(!bDivine)
        {
            // Wizard/Sorc/Bard: include slot levels reachable via meta from known base levels
            if(!bHas && nLevel <= nMaxBase && bEmp && nLevel >= 2 && ((nHasMask >> (nLevel-2)) & 1)) bHas = TRUE;
            if(!bHas && nLevel <= nMaxBase && bExt && nLevel >= 1 && ((nHasMask >> (nLevel-1)) & 1)) bHas = TRUE;
            if(!bHas && nLevel <= nMaxBase && bMax && nLevel >= 3 && ((nHasMask >> (nLevel-3)) & 1)) bHas = TRUE;
            if(!bHas && nLevel <= nMaxBase && bQck && nLevel >= 4 && ((nHasMask >> (nLevel-4)) & 1)) bHas = TRUE;
        }
        if(!bHas) continue;
        jEntries = JsonArrayInsert(jEntries,
            JsonArrayInsert(JsonArrayInsert(JsonArray(),
                JsonString(IntToString(nLevel))), JsonInt(nLevel)));
    }
    return jEntries;
}

// --- Build player class combo entries -----------------------------------------
// Returns JsonObject {"ids": JsonArray of class ids, "names": JsonArray of class names}
// Only classes with PlayerClass=1 and a SpellTableColumn are included.
json SmGetPlayerClasses(object oPC)
{
    json jIds   = JsonArray();
    json jNames = JsonArray();
    int nRows = Get2DARowCount("classes");
    int i;
    for(i = 0; i < nRows; i++)
    {
        if(Get2DAString("classes", "PlayerClass", i) != "1") continue;
        if(GetLevelByClass(i, oPC) == 0) continue;
        string sCol = Get2DAString("classes", "SpellTableColumn", i);
        if(sCol == "" || sCol == "****") continue;

        string sName = GetStringByStrRef(StringToInt(Get2DAString("classes", "Name", i)));
        if(sName == "" || GetStringLeft(sName, 3) == "Bad") continue;

        jIds   = JsonArrayInsert(jIds,   JsonInt(i));
        jNames = JsonArrayInsert(jNames, JsonString(sName));
    }
    json jResult = JsonObject();
    jResult = JsonObjectSet(jResult, "ids",   jIds);
    jResult = JsonObjectSet(jResult, "names", jNames);
    return jResult;
}

// --- Execute sequence ---------------------------------------------------------
void SmCastSpell(object oPC, object oTarget, int nSpellId, int nMeta, int nDomainLevel)
{
    AssignCommand(oPC, ActionCastSpellAtObject(nSpellId, oTarget, nMeta, FALSE, nDomainLevel));
}

void SmCastSpellAtLoc(object oPC, object oArea, float fx, float fy, float fz, int nSpellId, int nMeta, int nDomainLevel)
{
    location lLoc = Location(oArea, Vector(fx, fy, fz), 0.0f);
    AssignCommand(oPC, ActionCastSpellAtLocation(nSpellId, lLoc, nMeta, FALSE, nDomainLevel));
}

int SmGetTargetType(int nSpellId)
{
    return SmHexToInt(Get2DAString("spells", "TargetType", nSpellId));
}

void SmExecute(object oPC, json jSpells, int nTargetMode)
{
    int n = JsonGetLength(jSpells);
    if(n == 0) return;

    if(nTargetMode == SM_TARGET_SELF)
    {
        int i;
        for(i = 0; i < n; i++)
        {
            json jS      = JsonArrayGet(jSpells, i);
            int nSpellId = JsonGetInt(JsonObjectGet(jS, SM_F_ID));
            int nClassId = JsonGetInt(JsonObjectGet(jS, SM_F_CLASS));
            int nLevel   = JsonGetInt(JsonObjectGet(jS, SM_F_LEVEL));
            int nMeta    = JsonGetInt(JsonObjectGet(jS, SM_F_META));
            int bDomain  = JsonGetInt(JsonObjectGet(jS, SM_F_DOMAIN));
            string sName = JsonGetString(JsonObjectGet(jS, SM_F_NAME));
            if(!SmIsAvailable(oPC, nSpellId, nClassId, nLevel, nMeta, bDomain))
            {
                string sMemorizes = Get2DAString("classes", "MemorizesSpells", nClassId);
                SendMessageToPC(oPC, sName + (sMemorizes == "1" ? ": spell not prepared" : ": no uses left today"));
                continue;
            }
            int nDomLvl = bDomain ? SmGetLevelBeforeMeta(nLevel, nMeta) : 0;
            AssignCommand(oPC, ActionCastSpellAtObject(nSpellId, oPC, nMeta, FALSE, nDomLvl, PROJECTILE_PATH_TYPE_DEFAULT, FALSE, nClassId, FALSE));
        }
        return;
    }

    SetLocalJson(oPC, SM_LVAR_PENDING, jSpells);
    SetLocalInt(oPC, SM_LVAR_TARGET_MODE, nTargetMode);
    if(nTargetMode == SM_TARGET_AREA)
        EnterTargetingMode(oPC, OBJECT_TYPE_CREATURE | OBJECT_TYPE_TILE);
    else
        EnterTargetingMode(oPC, OBJECT_TYPE_CREATURE);
}

void SmOnPlayerTarget()
{
    object oPC = GetLastPlayerToSelectTarget();
    json jPending   = GetLocalJson(oPC, SM_LVAR_PENDING);
    int nTargetMode = GetLocalInt(oPC, SM_LVAR_TARGET_MODE);

    if(JsonGetType(jPending) == JSON_TYPE_NULL) return;
    DeleteLocalJson(oPC, SM_LVAR_PENDING);
    DeleteLocalInt(oPC, SM_LVAR_TARGET_MODE);

    object oTarget  = GetTargetingModeSelectedObject();
    vector vPos     = GetTargetingModeSelectedPosition();
    int bIsCreature = GetObjectType(oTarget) == OBJECT_TYPE_CREATURE;

    int n = JsonGetLength(jPending);
    int i;
    for(i = 0; i < n; i++)
    {
        json jS      = JsonArrayGet(jPending, i);
        int nSpellId = JsonGetInt(JsonObjectGet(jS, SM_F_ID));
        int nClassId = JsonGetInt(JsonObjectGet(jS, SM_F_CLASS));
        int nLevel   = JsonGetInt(JsonObjectGet(jS, SM_F_LEVEL));
        int nMeta    = JsonGetInt(JsonObjectGet(jS, SM_F_META));
        int bDomain  = JsonGetInt(JsonObjectGet(jS, SM_F_DOMAIN));
        string sName = JsonGetString(JsonObjectGet(jS, SM_F_NAME));

        if(!SmIsAvailable(oPC, nSpellId, nClassId, nLevel, nMeta, bDomain))
        {
            string sMemorizes = Get2DAString("classes", "MemorizesSpells", nClassId);
            SendMessageToPC(oPC, sName + (sMemorizes == "1" ? ": brak przygotowanego czaru" : ": brak uzyc na dzis"));
            continue;
        }

        int nDomLvl = bDomain ? SmGetLevelBeforeMeta(nLevel, nMeta) : 0;

        if(nTargetMode == SM_TARGET_ALLY || nTargetMode == SM_TARGET_ENEMY)
        {
            if(!bIsCreature) { SendMessageToPC(oPC, sName + ": requires a creature target"); continue; }
            AssignCommand(oPC, ActionCastSpellAtObject(nSpellId, oTarget, nMeta, FALSE, nDomLvl, PROJECTILE_PATH_TYPE_DEFAULT, FALSE, nClassId, FALSE));
        }
        else // SM_TARGET_AREA
        {
            vector v = bIsCreature ? GetPosition(oTarget) : vPos;
            object a = bIsCreature ? GetArea(oTarget) : GetArea(oPC);
            location lLoc = Location(a, v, 0.0f);
            AssignCommand(oPC, ActionCastSpellAtLocation(nSpellId, lLoc, nMeta, FALSE, PROJECTILE_PATH_TYPE_DEFAULT, FALSE, nClassId, FALSE, nDomLvl));
        }
    }
}
