#include "lib_sm_def"

// --- Icon picker constants ----------------------------------------------------
const string SM_WIN_ICON_PICKER = "sm_ico_pick";
const string SM_GRP_ICO_GRID    = "sm_ico_grid";
const string SM_BIND_ICO_SEARCH = "sm_ico_srch";
const string SM_LVAR_ICO_PARENT = "SM_ICO_PAR";
const string SM_ICO_CACHE_VAR   = "SM_ICO_CACHE";
const string SM_ICO_BTN_PFX     = "sm_ico_b_";   // 9 chars
const string SM_ICO_DEFAULT     = "ir_genspell";
const string SM_BTN_C_ICON_PICK = "SM_BTN_ICOPICK";
const string SM_BIND_C_ICON     = "SM_C_ICON";
const string SM_BIND_M_ICONS    = "SM_M_ICONS";

// --- Cache helpers ------------------------------------------------------------

json SmIcoEntry(string sRes, string sName)
{
    json jE = JsonObject();
    jE = JsonObjectSet(jE, "r", JsonString(sRes));
    jE = JsonObjectSet(jE, "n", JsonString(sName));
    return jE;
}

// Build deduplicated icon collection from spells.2da, domains.2da, effecticons.2da.
// Stored on module — call once from sys_on_load.nss.
void SmBuildIconCache()
{
    json jResult = JsonArray();
    json jSeen   = JsonObject();

    // Spells
    int nRows = Get2DARowCount("spells");
    int i;
    for(i = 0; i < nRows; i++)
    {
        string sRes = Get2DAString("spells", "IconResRef", i);
        if(sRes == "" || sRes == "****") continue;
        if(JsonGetType(JsonObjectGet(jSeen, sRes)) != JSON_TYPE_NULL) continue;
        string sNameRef = Get2DAString("spells", "Name", i);
        if(sNameRef == "" || sNameRef == "****") continue;
        string sName = GetStringByStrRef(StringToInt(sNameRef));
        if(sName == "" || GetStringLeft(sName, 3) == "Bad") continue;
        jSeen   = JsonObjectSet(jSeen, sRes, JsonInt(1));
        jResult = JsonArrayInsert(jResult, SmIcoEntry(sRes, sName));
    }

    // Domains
    nRows = Get2DARowCount("domains");
    for(i = 0; i < nRows; i++)
    {
        string sRes = GetStringLowerCase(Get2DAString("domains", "Icon", i));
        if(sRes == "" || sRes == "****") continue;
        if(JsonGetType(JsonObjectGet(jSeen, sRes)) != JSON_TYPE_NULL) continue;
        string sNameRef = Get2DAString("domains", "Name", i);
        if(sNameRef == "" || sNameRef == "****") continue;
        string sName = GetStringByStrRef(StringToInt(sNameRef));
        if(sName == "" || GetStringLeft(sName, 3) == "Bad") continue;
        jSeen   = JsonObjectSet(jSeen, sRes, JsonInt(1));
        jResult = JsonArrayInsert(jResult, SmIcoEntry(sRes, sName));
    }

    // Effect icons
    nRows = Get2DARowCount("effecticons");
    for(i = 0; i < nRows; i++)
    {
        string sRes = Get2DAString("effecticons", "Icon", i);
        if(sRes == "" || sRes == "****") continue;
        if(JsonGetType(JsonObjectGet(jSeen, sRes)) != JSON_TYPE_NULL) continue;
        string sName = "";
        string sStrRef = Get2DAString("effecticons", "StrRef", i);
        if(sStrRef != "" && sStrRef != "****")
            sName = GetStringByStrRef(StringToInt(sStrRef));
        if(sName == "" || GetStringLeft(sName, 3) == "Bad")
            sName = Get2DAString("effecticons", "Label", i);
        if(sName == "") continue;
        jSeen   = JsonObjectSet(jSeen, sRes, JsonInt(1));
        jResult = JsonArrayInsert(jResult, SmIcoEntry(sRes, sName));
    }

    SetLocalJson(GetModule(), SM_ICO_CACHE_VAR, jResult);
}

json SmGetIconCache()
{
    return GetLocalJson(GetModule(), SM_ICO_CACHE_VAR);
}

// --- Picker window ------------------------------------------------------------

// Build or rebuild the icon grid (called after NuiCreate and on search watch).
void SmRebuildIconGrid(object oPC, int nToken, string sFilter)
{
    json jCache = SmGetIconCache();
    int  nTotal = JsonGetLength(jCache);
    float fSize = SmScale(oPC, 40.0);

    json jRows  = JsonArray();
    json jRow   = JsonArray();
    int  nInRow = 0;

    int i;
    for(i = 0; i < nTotal; i++)
    {
        json   jEntry = JsonArrayGet(jCache, i);
        string sRes   = JsonGetString(JsonObjectGet(jEntry, "r"));
        string sName  = JsonGetString(JsonObjectGet(jEntry, "n"));

        if(sFilter != "" &&
           FindSubString(GetStringLowerCase(sName), GetStringLowerCase(sFilter)) == -1)
            continue;

        json jBtn = NuiButtonImage(JsonString(sRes));
        jBtn = NuiWidth(jBtn,  fSize);
        jBtn = NuiHeight(jBtn, fSize);
        jBtn = NuiId(jBtn, SM_ICO_BTN_PFX + IntToString(i));
        jBtn = NuiTooltip(jBtn, JsonString(sName));

        jRow = JsonArrayInsert(jRow, jBtn);
        nInRow++;

        if(nInRow >= 10)
        {
            jRows  = JsonArrayInsert(jRows, NuiRow(jRow));
            jRow   = JsonArray();
            nInRow = 0;
        }
    }
    if(nInRow > 0)
        jRows = JsonArrayInsert(jRows, NuiRow(jRow));

    NuiSetGroupLayout(oPC, nToken, SM_GRP_ICO_GRID, NuiCol(jRows));
}

void SmCreateIconPicker(object oPC, int nParentToken)
{
    // Close any existing picker first
    int nExisting = NuiFindWindow(oPC, SM_WIN_ICON_PICKER);
    if(nExisting > 0) NuiDestroy(oPC, nExisting);

    SetLocalInt(oPC, SM_LVAR_ICO_PARENT, nParentToken);

    float fW = SmScale(oPC, 500.0);
    float fH = SmScale(oPC, 480.0);

    json jCol = JsonArray();

    // Search field
    {
        json jSearch = NuiTextEdit(JsonString("Search..."),
            NuiBind(SM_BIND_ICO_SEARCH), 64, FALSE);
        jSearch = NuiId(jSearch, SM_BIND_ICO_SEARCH);
        jSearch = NuiHeight(jSearch, SmScale(oPC, 28.0));
        json jRow = JsonArray();
        jRow = JsonArrayInsert(jRow, jSearch);
        jCol = JsonArrayInsert(jCol, NuiRow(jRow));
    }

    // Icon grid placeholder (rebuilt by SmRebuildIconGrid after NuiCreate)
    {
        json jGrid = NuiGroup(NuiRow(JsonArray()), FALSE, NUI_SCROLLBARS_Y);
        jGrid = NuiId(jGrid, SM_GRP_ICO_GRID);
        jGrid = NuiHeight(jGrid, SmScale(oPC, 380.0));
        json jRow = JsonArray();
        jRow = JsonArrayInsert(jRow, jGrid);
        jCol = JsonArrayInsert(jCol, NuiRow(jRow));
    }

    json jRoot = NuiCol(jCol);
    json jWin  = NuiWindow(jRoot, JsonString("Pick Icon"),
        NuiRect(-1.0, -1.0, fW, fH),
        JsonBool(FALSE), JsonBool(FALSE), JsonBool(TRUE),
        JsonBool(FALSE), JsonBool(TRUE));

    int nToken = NuiCreate(oPC, jWin, SM_WIN_ICON_PICKER, "lib_sm_ev");

    NuiSetBind(oPC, nToken, SM_BIND_ICO_SEARCH, JsonString(""));
    NuiSetBindWatch(oPC, nToken, SM_BIND_ICO_SEARCH, TRUE);
    SmRebuildIconGrid(oPC, nToken, "");
}
