//::///////////////////////////////////////////////////////////////
//:: lib_fshop_ev — Feat Shop, event handler NUI
//::///////////////////////////////////////////////////////////////
//:: Faza 5: routing kliknięć i watch eventów dla okna sklepu.
//::   - Mode tabs (Kupno/Sprzedaż) → swap mode + rebuild
//::   - Section tabs → swap section + rebuild
//::   - Feat icon → wybór feata + feed info panel
//::   - Action button → kup / sprzedaj feat + rebuild
//::   - Search input → encouraged highlight bez rebuild
//::///////////////////////////////////////////////////////////////

#include "lib_fshop"
#include "nwnx_creature"


// ===== Forward declarations =====
void FShopHandleClick(object oPC, int nToken, string sElem);
void FShopHandleBuy(object oPC, int nToken, int nFeatId);
void FShopHandleSell(object oPC, int nToken, int nFeatId);
int  FShopExtractFeatId(string sElem);


// ===== Entry point =====

void main()
{
    object oPC      = NuiGetEventPlayer();
    int    nToken   = NuiGetEventWindow();
    string sEvent   = NuiGetEventType();
    string sElem    = NuiGetEventElement();

    string sWinId = NuiGetWindowId(oPC, nToken);

    if(sEvent == "close")
    {
        if(sWinId == FSHOP_TREE_WIN_ID)
        {
            // Tree window zamkniete: tylko cleanup tokenu, main window zostaje
            DeleteLocalInt(oPC, FSHOP_LVAR_TREE_TOKEN);
            DeleteLocalInt(oPC, FSHOP_LVAR_TREE_FOCUS);
            DeleteLocalInt(oPC, FSHOP_LVAR_TREE_F_SPEC);
            DeleteLocalJson(oPC, FSHOP_LVAR_TREE_HISTORY);
            return;
        }
        if(sWinId == FSHOP_VAR_WIN_ID)
        {
            // Variant picker zamkniety: tylko cleanup tokenu
            DeleteLocalInt(oPC, FSHOP_LVAR_VAR_TOKEN);
            return;
        }
        // Main window zamkniete: pelen cleanup + zamknij tree+variant jezeli otwarte
        DestroyFShopTreeWindow(oPC);
        DestroyFShopVariantWindow(oPC);
        DeleteLocalInt(oPC, FSHOP_LVAR_TOKEN);
        DeleteLocalInt(oPC, FSHOP_LVAR_SEL_FEAT);
        DeleteLocalInt(oPC, FSHOP_LVAR_SEL_MODE);
        DeleteLocalString(oPC, FSHOP_LVAR_SEARCH);
        return;
    }

    // Watch na FSHOP_BIND_SEARCH wylaczony — filter triggered tylko klikiem
    // przycisku FSHOP_BTN_SEARCH (handled w FShopHandleClick poniżej).

    if(sEvent == "click")
    {
        FShopHandleClick(oPC, nToken, sElem);
        return;
    }

    // NuiGroup feat rows fire MOUSEDOWN, NIE click. Filtrujemy tylko
    // FSHOP_BTN_FEAT_PRE i FSHOP_BTN_VAR_FEAT_PRE zeby NuiButtony (ktore
    // strzelaja i mousedown i click) nie fire'owaly handlera dwa razy.
    if(sEvent == "mousedown")
    {
        int nLenF = GetStringLength(FSHOP_BTN_FEAT_PRE);
        if(GetStringLeft(sElem, nLenF) == FSHOP_BTN_FEAT_PRE)
        {
            FShopHandleClick(oPC, nToken, sElem);
            return;
        }
        int nLenV = GetStringLength(FSHOP_BTN_VAR_FEAT_PRE);
        if(GetStringLeft(sElem, nLenV) == FSHOP_BTN_VAR_FEAT_PRE)
        {
            FShopHandleClick(oPC, nToken, sElem);
            return;
        }
        return;
    }
}


// ===== Click router =====

void FShopHandleClick(object oPC, int nToken, string sElem)
{
    // Tree window: "Pokaz drzewo" — refocus tree na panel feat. Push STARY focus
    // do history (zeby Wstecz mogl wrocic). Preserve history przez recreate.
    if(sElem == FSHOP_BTN_TREE_REFOCUS)
    {
        int nPanel = GetLocalInt(oPC, FSHOP_LVAR_TREE_PANEL);
        if(nPanel <= 0) return;
        int nNewFocus = nPanel - 1;

        int nOldFocusRaw = GetLocalInt(oPC, FSHOP_LVAR_TREE_FOCUS);
        int nOldFocus = (nOldFocusRaw > 0 ? nOldFocusRaw - 1 : -1);

        // Skip refocus jezeli i tak ten sam focus (no-op)
        if(nOldFocus == nNewFocus) return;

        // Save history before recreate (CreateFShopTreeWindow → DestroyFShopTreeWindow → clear)
        json jHist = GetLocalJson(oPC, FSHOP_LVAR_TREE_HISTORY);
        if(JsonGetType(jHist) != JSON_TYPE_ARRAY) jHist = JsonArray();

        // Push old focus do history (dla Wstecz)
        if(nOldFocus >= 0)
        {
            jHist = JsonArrayInsert(jHist, JsonInt(nOldFocus));
        }

        CreateFShopTreeWindow(oPC, nNewFocus);
        SetLocalJson(oPC, FSHOP_LVAR_TREE_HISTORY, jHist);
        return;
    }

    // Tree window: "Wstecz" — pop ostatni focus z history, refocus tree na niego.
    // Pusta historia + Wstecz = close window.
    if(sElem == FSHOP_BTN_TREE_BACK)
    {
        int nTreeTokenB = GetLocalInt(oPC, FSHOP_LVAR_TREE_TOKEN);
        if(nTreeTokenB <= 0) return;

        json jHist = GetLocalJson(oPC, FSHOP_LVAR_TREE_HISTORY);
        if(JsonGetType(jHist) != JSON_TYPE_ARRAY || JsonGetLength(jHist) == 0)
        {
            // Pusty stack → close window
            DestroyFShopTreeWindow(oPC);
            return;
        }

        // Pop ostatni focus
        int nLast = JsonGetLength(jHist) - 1;
        int nPrevFocus = JsonGetInt(JsonArrayGet(jHist, nLast));
        jHist = JsonArrayDel(jHist, nLast);

        // Recreate tree z popped focus, preserve remaining history
        CreateFShopTreeWindow(oPC, nPrevFocus);
        SetLocalJson(oPC, FSHOP_LVAR_TREE_HISTORY, jHist);
        return;
    }

    // Tree window: ikony feaTow w drzewie (prefix fst_) — aktualizuje prawy
    // panel tree window. Bez zmiany history — tylko Pokaz drzewo dotyka history.
    int nLenTree = GetStringLength(FSHOP_BTN_TREE_FEAT_PRE);
    if(GetStringLeft(sElem, nLenTree) == FSHOP_BTN_TREE_FEAT_PRE)
    {
        string sIdT = GetSubString(sElem, nLenTree, GetStringLength(sElem) - nLenTree);
        if(sIdT == "") return;
        int nFidT = StringToInt(sIdT);

        int nTreeToken = GetLocalInt(oPC, FSHOP_LVAR_TREE_TOKEN);
        if(nTreeToken <= 0) return;

        FeedFShopTreePanel(oPC, nTreeToken, nFidT);
        return;
    }

    // "Pokaz drzewo" — otwiera tree window dla aktualnie wybranego feata.
    // GENERIC mode → tree pokaze group view (forced w CreateFShopTreeWindow).
    // SPECIFIC mode → tree pokaze specific variants matching focus.
    if(sElem == FSHOP_BTN_TREE_OPEN)
    {
        int nSelTree = FShopSelectedFeat(oPC);
        if(nSelTree < 0) return;
        CreateFShopTreeWindow(oPC, nSelTree);
        return;
    }

    // "Detale" — otwiera variant picker dla aktualnie wybranego feata
    if(sElem == FSHOP_BTN_VARIANTS)
    {
        int nSelVar = FShopSelectedFeat(oPC);
        if(nSelVar < 0) return;
        CreateFShopVariantWindow(oPC, nSelVar);
        return;
    }

    // Variant feat click (prefix fsv_) — wybor konkretnego wariantu z rodziny.
    // Przelacza tryb na SPECIFIC, zamyka variant picker, odswieza main info panel.
    int nLenVar = GetStringLength(FSHOP_BTN_VAR_FEAT_PRE);
    if(GetStringLeft(sElem, nLenVar) == FSHOP_BTN_VAR_FEAT_PRE)
    {
        string sIdV = GetSubString(sElem, nLenVar, GetStringLength(sElem) - nLenVar);
        if(sIdV == "") return;
        int nFidV = StringToInt(sIdV);

        FShopSetSelectedFeat(oPC, nFidV);
        FShopSetSelMode(oPC, FSHOP_SEL_MODE_SPECIFIC);
        DestroyFShopVariantWindow(oPC);

        int nMainToken = GetLocalInt(oPC, FSHOP_LVAR_TOKEN);
        if(nMainToken > 0)
        {
            FeedFShopInfoPanel(oPC, nMainToken);
            json jCache = FShopGetCache();
            json jSec   = FShopGetSection(FShopSection(oPC));
            FeedFShopFeatStates(oPC, nMainToken, FShopMode(oPC), FShopSection(oPC), jCache, jSec);
        }
        return;
    }

    // Search button — pobiera value z bind, zapisuje LVAR i rebuilduje liste
    if(sElem == FSHOP_BTN_SEARCH)
    {
        json jVal = NuiGetBind(oPC, nToken, FSHOP_BIND_SEARCH);
        string sQuery = JsonGetString(jVal);
        FeedFShopSearch(oPC, nToken, sQuery);
        return;
    }

    // Mode tabs
    if(sElem == FSHOP_BTN_BUY)
    {
        if(FShopMode(oPC) == FSHOP_MODE_BUY) return;
        FShopSetSelectedFeat(oPC, -1);
        CreateFShopWindow(oPC, FSHOP_MODE_BUY, FShopSection(oPC));
        return;
    }
    if(sElem == FSHOP_BTN_SELL)
    {
        if(FShopMode(oPC) == FSHOP_MODE_SELL) return;
        FShopSetSelectedFeat(oPC, -1);
        CreateFShopWindow(oPC, FSHOP_MODE_SELL, FShopSection(oPC));
        return;
    }

    // Section tabs (0=Wszystkie, 1..6=oryginalne sekcje)
    int s;
    for(s = 0; s <= 6; s++)
    {
        if(sElem == FSHOP_BTN_SEC_PRE + IntToString(s))
        {
            if(FShopSection(oPC) == s) return;
            FShopSetSelectedFeat(oPC, -1);
            CreateFShopWindow(oPC, FShopMode(oPC), s);
            return;
        }
    }

    // Filter "Dostepne" — toggle on/off, recreate window.
    // Storage offset+1: 1=jawnie OFF, 2=jawnie ON (0=unset → default ON).
    if(sElem == FSHOP_BTN_FILTER_ACQ)
    {
        int bOn = FShopFilterAcq(oPC);
        SetLocalInt(oPC, FSHOP_LVAR_FILTER_ACQ, bOn ? 1 : 2);  // ON→OFF / OFF→ON
        CreateFShopWindow(oPC, FShopMode(oPC), FShopSection(oPC));
        return;
    }

    // Action button (Kup / Sprzedaj)
    if(sElem == FSHOP_BTN_ACTION)
    {
        int nFeatId = FShopSelectedFeat(oPC);
        if(nFeatId < 0) return;

        if(FShopMode(oPC) == FSHOP_MODE_BUY)
        {
            FShopHandleBuy(oPC, nToken, nFeatId);
        }
        else
        {
            FShopHandleSell(oPC, nToken, nFeatId);
        }
        return;
    }

    // Feat icon click w main liscie — domyslnie GENERIC mode.
    // FeedFShopInfoPanel sam wykryje czy feat ma rodzine wariantow i ustawi
    // panel odpowiednio (strip suffix, disable Pokaz drzewo, show Detale).
    int nFeatId = FShopExtractFeatId(sElem);
    if(nFeatId >= 0)
    {
        FShopSetSelectedFeat(oPC, nFeatId);
        FShopSetSelMode(oPC, FSHOP_SEL_MODE_GENERIC);
        DestroyFShopVariantWindow(oPC);  // jezeli picker otwarty z poprzedniej selekcji — zamknij
        // Tylko refresh bindów panelu i encouraged — bez rebuild okna
        FeedFShopInfoPanel(oPC, nToken);
        json jCache = FShopGetCache();
        json jSec   = FShopGetSection(FShopSection(oPC));
        FeedFShopFeatStates(oPC, nToken, FShopMode(oPC), FShopSection(oPC), jCache, jSec);
        return;
    }
}


// ===== Akcje kup / sprzedaj =====

void FShopHandleBuy(object oPC, int nToken, int nFeatId)
{
    json jCache = FShopGetCache();
    json jFeat  = JsonObjectGet(jCache, IntToString(nFeatId));

    json jClassSet = FShopBuildClassFeatSet(oPC);
    int nState = FShopGetState(oPC, nFeatId, jFeat, jClassSet);
    if(nState != FSHOP_ST_AVAILABLE)
    {
        SendMessageToPC(oPC, "You do not meet the requirements for this feat.");
        return;
    }
    if(GetGold(oPC) < FSHOP_PRICE_BUY)
    {
        SendMessageToPC(oPC, "Not enough gold — you need " + FShopGoldText(FSHOP_PRICE_BUY) + ".");
        return;
    }

    AssignCommand(oPC, TakeGoldFromCreature(FSHOP_PRICE_BUY, oPC, TRUE));
    NWNX_Creature_AddFeat(oPC, nFeatId);

    string sName = JsonGetString(JsonObjectGet(jFeat, FK_NAME));
    SendMessageToPC(oPC, "Kupiono feat: " + sName + " za " + FShopGoldText(FSHOP_PRICE_BUY) + ".");

    CreateFShopWindow(oPC, FShopMode(oPC), FShopSection(oPC));
}

void FShopHandleSell(object oPC, int nToken, int nFeatId)
{
    json jCache = FShopGetCache();

    if(!FShopCanSell(oPC, nFeatId, jCache))
    {
        SendMessageToPC(oPC, "Cannot sell this feat — another owned feat requires it.");
        return;
    }

    NWNX_Creature_RemoveFeat(oPC, nFeatId);
    AssignCommand(oPC, GiveGoldToCreature(oPC, FSHOP_PRICE_SELL));

    json jFeat = JsonObjectGet(jCache, IntToString(nFeatId));
    string sName = JsonGetString(JsonObjectGet(jFeat, FK_NAME));
    SendMessageToPC(oPC, "Sprzedano feat: " + sName + " za " + FShopGoldText(FSHOP_PRICE_SELL) + ".");

    FShopSetSelectedFeat(oPC, -1);
    CreateFShopWindow(oPC, FShopMode(oPC), FShopSection(oPC));
}


// ===== Helper: extract feat ID z elementu "fs_f_<id>" =====

int FShopExtractFeatId(string sElem)
{
    int nLen = GetStringLength(FSHOP_BTN_FEAT_PRE);
    if(GetStringLeft(sElem, nLen) != FSHOP_BTN_FEAT_PRE) return -1;
    string sId = GetSubString(sElem, nLen, GetStringLength(sElem) - nLen);
    if(sId == "") return -1;
    return StringToInt(sId);
}
