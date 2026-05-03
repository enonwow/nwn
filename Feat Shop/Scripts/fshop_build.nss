//::///////////////////////////////////////////////////////////////
//:: fshop_build — Feat Shop, build cache (standalone)
//::///////////////////////////////////////////////////////////////
//:: Standalone skrypt budujący cache feat.2da → JsonObject na module.
//:: Wywoływany RAZ przy starcie modułu (OnModuleLoad) lub ręcznie
//:: przez DM (dm_runscript fshop_build).
//::
//:: Cały algorytm w main() — bez wrapperów, bez ukrytych callsites.
//::   - Iteruje feat.2da do końca (Get2DARowCount, NIE while sLabel!="")
//::   - Filtr: nazwa OK, ikona OK, TOOLSCATEGORIES 1..6
//::   - Per valid feat: JsonObject z 25 polami (krótkie klucze)
//::   - Indeks per sekcja: JsonArray feat IDs
//::   - Idempotentne: BUILT==1 → no-op
//::   - Ustawia limit instrukcji (~13M ops potrzebne dla ~800 valid featów)
//::///////////////////////////////////////////////////////////////

#include "lib_fshop_def"
#include "nwnx_util"


void main()
{
    object oMod = GetModule();

    // Idempotentne — ponowne wywołanie no-op
    if(GetLocalInt(oMod, FSHOP_LVAR_BUILT) == 1) return;

    // Default NWScript limit = ~500k instrukcji.
    // Build potrzebuje ~13M (1100 rzędów × ~25 JsonObjectSet × value-copy O(N²)).
    // UWAGA: -1 to RESET do default, NIE unlimited.
    int nOldLimit = NWNX_Util_GetInstructionLimit();
    NWNX_Util_SetInstructionLimit(100000000);

    json jCache = JsonObject();
    json jBySec = JsonObject();
    json jMfData = JsonObject();   // {mfId: {n, d, i}} z masterfeats.2da, lazy-fill

    int nCount = Get2DARowCount("feat");
    int nRow;
    for(nRow = 0; nRow < nCount; nRow++)
    {
        // === Filtr ===
        string sName = FShop2daStrRef("feat", "FEAT", nRow);
        string sIcon = Get2DAString("feat", "ICON", nRow);
        int    nCat  = FShop2daInt("feat", "TOOLSCATEGORIES", nRow);

        if(sName == "" || sName == "Bad Strref") continue;
        if(sIcon == "")                          continue;
        if(nCat < 1 || nCat > 6)                 continue;
        if(FShopShouldSkipFeat(nRow))            continue;  // skip rules (MinLevel==99 itd)

        // === Build feat data ===
        json jFeat = JsonObject();
        jFeat = JsonObjectSet(jFeat, FK_NAME,       JsonString(sName));
        jFeat = JsonObjectSet(jFeat, FK_ICON,       JsonString(sIcon));
        jFeat = JsonObjectSet(jFeat, FK_DESC,       JsonString(FShop2daStrRef("feat","DESCRIPTION",nRow)));
        jFeat = JsonObjectSet(jFeat, FK_CAT,        JsonInt(nCat));
        jFeat = JsonObjectSet(jFeat, FK_ALL,        JsonInt(FShop2daInt("feat","ALLCLASSESCANUSE",nRow)));

        // Prereq feats
        jFeat = JsonObjectSet(jFeat, FK_P1,         JsonInt(FShop2daInt("feat","PREREQFEAT1",nRow)));
        jFeat = JsonObjectSet(jFeat, FK_P2,         JsonInt(FShop2daInt("feat","PREREQFEAT2",nRow)));
        jFeat = JsonObjectSet(jFeat, FK_SUCC,       JsonInt(FShop2daInt("feat","SUCCESSOR",nRow)));

        // OrReq tablica niepustych
        json jOr = JsonArray();
        int oi;
        for(oi = 0; oi <= 4; oi++)
        {
            int v = FShop2daInt("feat","OrReqFeat"+IntToString(oi),nRow);
            if(v >= 0) jOr = JsonArrayInsert(jOr, JsonInt(v));
        }
        jFeat = JsonObjectSet(jFeat, FK_OR, jOr);

        // Wymagania stats
        jFeat = JsonObjectSet(jFeat, FK_MIN_STR,    JsonInt(FShop2daInt("feat","MINSTR",nRow)));
        jFeat = JsonObjectSet(jFeat, FK_MIN_DEX,    JsonInt(FShop2daInt("feat","MINDEX",nRow)));
        jFeat = JsonObjectSet(jFeat, FK_MIN_CON,    JsonInt(FShop2daInt("feat","MINCON",nRow)));
        jFeat = JsonObjectSet(jFeat, FK_MIN_INT,    JsonInt(FShop2daInt("feat","MININT",nRow)));
        jFeat = JsonObjectSet(jFeat, FK_MIN_WIS,    JsonInt(FShop2daInt("feat","MINWIS",nRow)));
        jFeat = JsonObjectSet(jFeat, FK_MIN_CHA,    JsonInt(FShop2daInt("feat","MINCHA",nRow)));
        jFeat = JsonObjectSet(jFeat, FK_MIN_BAB,    JsonInt(FShop2daInt("feat","MINATTACKBONUS",nRow)));
        jFeat = JsonObjectSet(jFeat, FK_MIN_LEVEL,  JsonInt(FShop2daInt("feat","MinLevel",nRow)));
        jFeat = JsonObjectSet(jFeat, FK_MIN_LCLASS, JsonInt(FShop2daInt("feat","MinLevelClass",nRow)));
        jFeat = JsonObjectSet(jFeat, FK_MIN_SPELL,  JsonInt(FShop2daInt("feat","MINSPELLLVL",nRow)));
        jFeat = JsonObjectSet(jFeat, FK_REQ_SK1,    JsonInt(FShop2daInt("feat","REQSKILL",nRow)));
        jFeat = JsonObjectSet(jFeat, FK_REQ_SK1_R,  JsonInt(FShop2daInt("feat","ReqSkillMinRanks",nRow)));
        jFeat = JsonObjectSet(jFeat, FK_REQ_SK2,    JsonInt(FShop2daInt("feat","REQSKILL2",nRow)));
        jFeat = JsonObjectSet(jFeat, FK_REQ_SK2_R,  JsonInt(FShop2daInt("feat","ReqSkillMinRanks2",nRow)));
        jFeat = JsonObjectSet(jFeat, FK_EPIC,       JsonInt(FShop2daInt("feat","PreReqEpic",nRow)));
        int nMfRow = FShop2daInt("feat","MASTERFEAT",nRow);
        jFeat = JsonObjectSet(jFeat, FK_MF,         JsonInt(nMfRow));

        // Lazy-fill masterfeat metadata: pierwsze trafienie na MF > 0 lookupuje
        // STRREF/DESCRIPTION/ICON z masterfeats.2da. Kolejne feaTy z tej samej
        // rodziny pomijaja lookup (sprawdzenie JsonGetType O(1)).
        //
        // Wszystkie 3 kolumny na raz, wzor jak w feat.2da:
        //   - STRREF = strref nazwy (np. 6489 → "Improved Critical")
        //   - DESCRIPTION = strref opisu (np. 228 → pelen tekst opisu)
        //   - ICON = resref ikony (np. ife_impcrit)
        // UWAGA: nMfRow >= 0 — row 0 (ImprovedCritical) to VALID masterfeat!
        // FShop2daInt zwraca -1 dla pustego MASTERFEAT w feat.2da.
        if(nMfRow >= 0)
        {
            string sMfKey = IntToString(nMfRow);
            if(JsonGetType(JsonObjectGet(jMfData, sMfKey)) != JSON_TYPE_OBJECT)
            {
                string sMfName = FShop2daStrRef("masterfeats", "STRREF",      nMfRow);
                string sMfDesc = FShop2daStrRef("masterfeats", "DESCRIPTION", nMfRow);
                string sMfIcon = Get2DAString("masterfeats", "ICON",          nMfRow);

                json jMfGrp = JsonObject();
                jMfGrp = JsonObjectSet(jMfGrp, FK_MF_NAME, JsonString(sMfName));
                jMfGrp = JsonObjectSet(jMfGrp, FK_MF_DESC, JsonString(sMfDesc));
                jMfGrp = JsonObjectSet(jMfGrp, FK_MF_ICON, JsonString(sMfIcon));
                jMfData = JsonObjectSet(jMfData, sMfKey, jMfGrp);
            }
        }

        // === Save w cache ===
        jCache = JsonObjectSet(jCache, IntToString(nRow), jFeat);

        // === Indeks sekcji ===
        string sCat = IntToString(nCat);
        json jArr = JsonObjectGet(jBySec, sCat);
        if(JsonGetType(jArr) != JSON_TYPE_ARRAY) jArr = JsonArray();
        jArr = JsonArrayInsert(jArr, JsonInt(nRow));
        jBySec = JsonObjectSet(jBySec, sCat, jArr);
    }

    // === Build children index (PREREQFEAT only) ===
    // Pre-computed at boot, używany w tree window zamiast lokalnego rebuilda.
    // Bez OR-relacji żeby nie wybuchać na feaTach typu Weapon Proficiency.
    json jChildren = JsonObject();
    json jKeys = JsonObjectKeys(jCache);
    int nKeysLen = JsonGetLength(jKeys);
    int ki;
    for(ki = 0; ki < nKeysLen; ki++)
    {
        string sKidKey = JsonGetString(JsonArrayGet(jKeys, ki));
        json jKidF = JsonObjectGet(jCache, sKidKey);
        int kp1 = JsonGetInt(JsonObjectGet(jKidF, FK_P1));
        int kp2 = JsonGetInt(JsonObjectGet(jKidF, FK_P2));
        int kpp;
        for(kpp = 0; kpp < 2; kpp++)
        {
            int nPar = (kpp == 0 ? kp1 : kp2);
            if(nPar < 0) continue;
            string sPar = IntToString(nPar);
            json jKidsArr = JsonObjectGet(jChildren, sPar);
            if(JsonGetType(jKidsArr) != JSON_TYPE_ARRAY) jKidsArr = JsonArray();
            jKidsArr = JsonArrayInsert(jKidsArr, JsonInt(StringToInt(sKidKey)));
            jChildren = JsonObjectSet(jChildren, sPar, jKidsArr);
        }
    }

    // Save raz na końcu
    SetLocalJson(oMod, FSHOP_LVAR_CACHE, jCache);
    SetLocalJson(oMod, FSHOP_LVAR_BY_SEC, jBySec);
    SetLocalJson(oMod, FSHOP_LVAR_CHILDREN, jChildren);
    SetLocalJson(oMod, FSHOP_LVAR_MF_DATA,  jMfData);
    SetLocalInt(oMod, FSHOP_LVAR_BUILT, 1);

    // Przywróć poprzedni limit
    NWNX_Util_SetInstructionLimit(nOldLimit);
}
