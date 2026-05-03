//::///////////////////////////////////////////////////////////////
//:: lib_fshop_def — Feat Shop, definicje + cache
//::///////////////////////////////////////////////////////////////
//:: One-pass parser feat.2da → JsonObject cache na module.
//:: Bez topo-sort, bez longest-path. depth liczone on-demand
//:: per sekcja w UI (lib_fshop.nss).
//:: Klasy (cls_feat_*.2da) sprawdzane on-demand per gracz w
//:: MeetsClass (lib_fshop_st.nss) — tylko dla 3 klas gracza.
//::///////////////////////////////////////////////////////////////


// ===== Local vars na module (cache) =====
const string FSHOP_LVAR_CACHE    = "FSHOP_CACHE";    // JsonObject {featId: featData}
const string FSHOP_LVAR_BY_SEC   = "FSHOP_BY_SEC";   // JsonObject {sectionId: [featIds]}
const string FSHOP_LVAR_CHILDREN = "FSHOP_CHILDREN"; // JsonObject {parentId: [childIds]} — PREREQFEAT only
const string FSHOP_LVAR_MF_DATA  = "FSHOP_MF_DATA";  // JsonObject {mfId: {n, d, i}} — pelne metadata z masterfeats.2da
const string FSHOP_LVAR_BUILT    = "FSHOP_BUILT";    // 1 jeśli zbudowany

// Klucze pól w grupie masterfeat (spojne z FK_*)
const string FK_MF_NAME = "n";
const string FK_MF_DESC = "d";
const string FK_MF_ICON = "i";

// ===== Cena =====
const int FSHOP_PRICE_BUY  = 1000;
const int FSHOP_PRICE_SELL = 500;

// ===== Klucze pól w jFeat (krótkie żeby JSON był mniejszy) =====
const string FK_NAME        = "n";
const string FK_ICON        = "i";
const string FK_DESC        = "d";
const string FK_CAT         = "c";    // TOOLSCATEGORIES 1..6
const string FK_ALL         = "all";  // ALLCLASSESCANUSE 0/1
const string FK_P1          = "p1";   // PREREQFEAT1
const string FK_P2          = "p2";   // PREREQFEAT2
const string FK_SUCC        = "su";   // SUCCESSOR
const string FK_OR          = "or";   // JsonArray of OrReqFeat0..4 (niepustych)
const string FK_MIN_STR     = "mS";
const string FK_MIN_DEX     = "mD";
const string FK_MIN_CON     = "mC";
const string FK_MIN_INT     = "mI";
const string FK_MIN_WIS     = "mW";
const string FK_MIN_CHA     = "mH";
const string FK_MIN_BAB     = "mB";
const string FK_MIN_LEVEL   = "mL";
const string FK_MIN_LCLASS  = "mLc";  // klasa gdzie level wymagany
const string FK_MIN_SPELL   = "mSp";
const string FK_REQ_SK1     = "rs1";
const string FK_REQ_SK1_R   = "rk1";
const string FK_REQ_SK2     = "rs2";
const string FK_REQ_SK2_R   = "rk2";
const string FK_EPIC        = "ep";
const string FK_MF          = "mf";   // MASTERFEAT (rodzina wariantow weapon-specific)


// ===== Helpery 2da =====

// Zwraca int z kolumny 2da; -1 jeśli pusty/****
int FShop2daInt(string s2da, string sCol, int nRow)
{
    string s = Get2DAString(s2da, sCol, nRow);
    if(s == "") return -1;
    return StringToInt(s);
}

// Zwraca string z TLK (po deref strref); "" jeśli pusty
string FShop2daStrRef(string s2da, string sCol, int nRow)
{
    string s = Get2DAString(s2da, sCol, nRow);
    if(s == "") return "";
    return GetStringByStrRef(StringToInt(s));
}


// ===== Skip rules =====
//
// Zwraca TRUE jeśli feat z feat.2da pod nRow powinien byc pominiety podczas
// budowy cache (nigdy nie pojawi sie w sklepie). Centralne miejsce dla regul.
//
// Rozszerzaj o kolejne if(...) return TRUE; — jedna regula per linia.
//
// Aktualne reguly:
//   1) MinLevel == 99  — Bioware convention dla hidden/disabled featow
//                        (np. monster feats, racial-only, NPC-only)
int FShopShouldSkipFeat(int nRow)
{
    // 1) MinLevel == 99 → ukryty/wylaczony feat
    if(FShop2daInt("feat", "MinLevel", nRow) == 99) return TRUE;

    return FALSE;
}


// ===== Public getters =====
//
// Build cache → patrz fshop_build.nss (standalone, runnable script).
// Wywoływany RAZ w sys_on_load (OnModuleLoad) lub przez DM (dm_runscript).
// Tu tylko gettery — bez heavy ops, czyste odczyty z LocalJson na module.

// Zwraca cały cache (jeden GetLocalJson). UI woła RAZ na render
// i operuje na lokalnej kopii — bez ponownych GetLocalJson w pętli.
json FShopGetCache()
{
    return GetLocalJson(GetModule(), FSHOP_LVAR_CACHE);
}

// Zwraca tablicę feat IDs dla danej sekcji (TOOLSCATEGORIES 1..6).
// nSection=0 → "Wszystkie": konkatenacja wszystkich sekcji 1..6.
json FShopGetSection(int nSection)
{
    json jBySec = GetLocalJson(GetModule(), FSHOP_LVAR_BY_SEC);
    if(nSection == 0)
    {
        json jAll = JsonArray();
        int s;
        for(s = 1; s <= 6; s++)
        {
            json jPart = JsonObjectGet(jBySec, IntToString(s));
            if(JsonGetType(jPart) != JSON_TYPE_ARRAY) continue;
            int nL = JsonGetLength(jPart);
            int i;
            for(i = 0; i < nL; i++) jAll = JsonArrayInsert(jAll, JsonArrayGet(jPart, i));
        }
        return jAll;
    }
    return JsonObjectGet(jBySec, IntToString(nSection));
}

// Zwraca pre-computed children index (PREREQFEAT only) z modułu.
// Używany przez tree window w miejsce lokalnego rebuilda — oszczędza ~10k ops per render.
json FShopGetChildrenIndex()
{
    return GetLocalJson(GetModule(), FSHOP_LVAR_CHILDREN);
}

// Zwraca JsonObject z metadanymi grupy masterfeat (name/desc/icon).
// Pusty JsonObject jezeli mfId < 0 (= brak MASTERFEAT w feat.2da) lub grupa
// nie zdefiniowana. UWAGA: row 0 to "ImprovedCritical" — valid masterfeat!
// Pre-built w fshop_build.
//
// Pola: FK_MF_NAME, FK_MF_DESC, FK_MF_ICON
json FShopGetMasterfeatData(int nMfId)
{
    if(nMfId < 0) return JsonObject();
    json jData = GetLocalJson(GetModule(), FSHOP_LVAR_MF_DATA);
    if(JsonGetType(jData) != JSON_TYPE_OBJECT) return JsonObject();
    json jGrp = JsonObjectGet(jData, IntToString(nMfId));
    if(JsonGetType(jGrp) != JSON_TYPE_OBJECT) return JsonObject();
    return jGrp;
}

// Convenience getters per pole (zwracaja "" jezeli brak)
string FShopGetMasterfeatName(int nMfId)
{
    json jGrp = FShopGetMasterfeatData(nMfId);
    json jN = JsonObjectGet(jGrp, FK_MF_NAME);
    if(JsonGetType(jN) != JSON_TYPE_STRING) return "";
    return JsonGetString(jN);
}

string FShopGetMasterfeatDesc(int nMfId)
{
    json jGrp = FShopGetMasterfeatData(nMfId);
    json jD = JsonObjectGet(jGrp, FK_MF_DESC);
    if(JsonGetType(jD) != JSON_TYPE_STRING) return "";
    return JsonGetString(jD);
}

string FShopGetMasterfeatIcon(int nMfId)
{
    json jGrp = FShopGetMasterfeatData(nMfId);
    json jI = JsonObjectGet(jGrp, FK_MF_ICON);
    if(JsonGetType(jI) != JSON_TYPE_STRING) return "";
    return JsonGetString(jI);
}

// Wyciąga jFeat z LOKALNEJ kopii cache (bez ponownego GetLocalJson).
// Używaj w pętlach po featach w sekcji.
json FShopFeatFromCache(json jCache, int nFeatId)
{
    return JsonObjectGet(jCache, IntToString(nFeatId));
}

// Czy feat istnieje w cache (pasował do filtru)?
int FShopFeatInCache(json jCache, int nFeatId)
{
    json jF = JsonObjectGet(jCache, IntToString(nFeatId));
    return JsonGetType(jF) == JSON_TYPE_OBJECT;
}

// Rozszerza JsonArray sekcji o WSZYSTKIE feaTy w drzewie:
//   - UP: prereqi (PREREQFEAT1/2) — zeby dziecko mialo widocznych rodzicow
//   - DOWN: dzieci (feaTy ktorych ten jest prereqem) — zeby drzewo bylo pelne
//     niezaleznie od TOOLSCATEGORIES dziecka (np. Improved Power Attack jest
//     epic/class ale chcemy zeby pokazal sie razem z Power Attack w sekcji Walka)
//
// BFS single-pass z O(1) set membership.
// Buduje lokalny jAllChildren (children index z calego cache) raz na poczatku.
json FShopExpandSectionWithPrereqs(json jCache, json jSec)
{
    if(JsonGetType(jSec) != JSON_TYPE_ARRAY) return jSec;

    // ---- 0. Build local children index from cache (~5-10k ops, one pass) ----
    json jAllChildren = JsonObject();   // {parentId: [child1, child2,...]}
    json jAllKeys = JsonObjectKeys(jCache);
    int nAllKeys = JsonGetLength(jAllKeys);
    int kk;
    for(kk = 0; kk < nAllKeys; kk++)
    {
        string sKidKey = JsonGetString(JsonArrayGet(jAllKeys, kk));
        json jKidF = JsonObjectGet(jCache, sKidKey);
        int kp1 = JsonGetInt(JsonObjectGet(jKidF, FK_P1));
        int kp2 = JsonGetInt(JsonObjectGet(jKidF, FK_P2));
        int kpp;
        for(kpp = 0; kpp < 2; kpp++)
        {
            int nPar = (kpp == 0 ? kp1 : kp2);
            if(nPar < 0) continue;
            string sPar = IntToString(nPar);
            json jKidsArr = JsonObjectGet(jAllChildren, sPar);
            if(JsonGetType(jKidsArr) != JSON_TYPE_ARRAY) jKidsArr = JsonArray();
            jKidsArr = JsonArrayInsert(jKidsArr, JsonInt(StringToInt(sKidKey)));
            jAllChildren = JsonObjectSet(jAllChildren, sPar, jKidsArr);
        }
    }

    // ---- 1. Build initial membership set from current jSec ----
    json jSet = JsonObject();
    int nInit = JsonGetLength(jSec);
    int i;
    for(i = 0; i < nInit; i++)
    {
        string sFid = IntToString(JsonGetInt(JsonArrayGet(jSec, i)));
        jSet = JsonObjectSet(jSet, sFid, JsonInt(1));
    }

    // ---- 2. BFS walk: UP (prereqs) + DOWN (children) ----
    i = 0;
    while(i < JsonGetLength(jSec))
    {
        int nFid = JsonGetInt(JsonArrayGet(jSec, i));
        json jF = JsonObjectGet(jCache, IntToString(nFid));
        if(JsonGetType(jF) == JSON_TYPE_OBJECT)
        {
            // UP: prereqi
            int p1 = JsonGetInt(JsonObjectGet(jF, FK_P1));
            int p2 = JsonGetInt(JsonObjectGet(jF, FK_P2));
            int pp;
            for(pp = 0; pp < 2; pp++)
            {
                int nPid = (pp == 0 ? p1 : p2);
                if(nPid < 0) continue;
                string sPid = IntToString(nPid);
                if(JsonGetType(JsonObjectGet(jSet, sPid)) == JSON_TYPE_INTEGER) continue;
                json jPF = JsonObjectGet(jCache, sPid);
                if(JsonGetType(jPF) != JSON_TYPE_OBJECT) continue;
                jSec = JsonArrayInsert(jSec, JsonInt(nPid));
                jSet = JsonObjectSet(jSet, sPid, JsonInt(1));
            }

            // DOWN: dzieci (z lokalnego children indexu)
            json jKids = JsonObjectGet(jAllChildren, IntToString(nFid));
            if(JsonGetType(jKids) == JSON_TYPE_ARRAY)
            {
                int nKidsCnt = JsonGetLength(jKids);
                int kc;
                for(kc = 0; kc < nKidsCnt; kc++)
                {
                    int nKidId = JsonGetInt(JsonArrayGet(jKids, kc));
                    string sKidId = IntToString(nKidId);
                    if(JsonGetType(JsonObjectGet(jSet, sKidId)) == JSON_TYPE_INTEGER) continue;
                    jSec = JsonArrayInsert(jSec, JsonInt(nKidId));
                    jSet = JsonObjectSet(jSet, sKidId, JsonInt(1));
                }
            }
        }
        i++;
    }

    return jSec;
}
