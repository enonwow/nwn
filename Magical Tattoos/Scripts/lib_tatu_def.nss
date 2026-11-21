#include "lib_nui"
#include "sql_tatu"

// Forward declarations for functions defined in lib_tatu.nss
void TatuOpenWindow(object oPC);
void FeedTatuDesignList(object oPC, int nToken, json jDesigns, json jTattoos);
void FeedTatuBodyMap(object oPC, int nToken, json jTattoos);
void FeedTatuDetail(object oPC, int nToken, json jDesigns, json jTattoos);
void TatuApplyEffectsForPC(object oPC);
void TatuRemoveEffectsForSlot(object oPC, int nSlotIdx);
void TatuDoApply(object oPC, int nToken);
void TatuDoRemove(object oPC, int nToken);
void TatuRefreshAll(object oPC, int nToken);

// ----------------------------------------------------------------
// Window IDs
// ----------------------------------------------------------------

const string TATU_WINDOW    = "TATU_WINDOW";
const string TATU_EV_SCRIPT = "lib_tatu_ev";
const string TATU_WIN_GEOM  = "tatu_win_geom";

// ----------------------------------------------------------------
// Bind IDs — Design list
// ----------------------------------------------------------------

const string TATU_BIND_LIST_NAME  = "tatu_list_name";
const string TATU_BIND_LIST_SLOT  = "tatu_list_slot";
const string TATU_BIND_LIST_ENC   = "tatu_list_enc";
const string TATU_BIND_LIST_COLOR = "tatu_list_color";
const string TATU_BIND_LIST_COUNT = "tatu_list_count";

// ----------------------------------------------------------------
// Bind IDs — Body map (one per slot, append "_0" … "_4")
// ----------------------------------------------------------------

const string TATU_BIND_SLOT_LBL = "tatu_slot_lbl";
const string TATU_BIND_SLOT_ENC = "tatu_slot_enc";

// ----------------------------------------------------------------
// Bind IDs — Detail panel
// ----------------------------------------------------------------

const string TATU_BIND_DET_NAME   = "tatu_det_name";
const string TATU_BIND_DET_DESC   = "tatu_det_desc";
const string TATU_BIND_DET_EFFECT = "tatu_det_effect";
const string TATU_BIND_DET_REQ    = "tatu_det_req";
const string TATU_BIND_DET_CURSE  = "tatu_det_curse";
const string TATU_BIND_APPLY_ENA  = "tatu_apply_ena";
const string TATU_BIND_APPLY_LBL  = "tatu_apply_lbl";
const string TATU_BIND_REMOVE_ENA = "tatu_remove_ena";

// ----------------------------------------------------------------
// Button IDs
// ----------------------------------------------------------------

const string TATU_BTN_CLOSE  = "tatu_btn_close";
const string TATU_BTN_ROW    = "tatu_btn_row";
const string TATU_BTN_SLOT   = "tatu_btn_slot";  // + "_0" … "_4"
const string TATU_BTN_APPLY  = "tatu_btn_apply";
const string TATU_BTN_REMOVE = "tatu_btn_remove";

// ----------------------------------------------------------------
// LVARs on PC
// ----------------------------------------------------------------

const string TATU_LVAR_SEL_DESIGN = "TATU_SEL_DESIGN";    // int: 0 = none
const string TATU_LVAR_SEL_SLOT   = "TATU_SEL_SLOT_IDX";  // int: -1 = none, 0-4 = slot

// ----------------------------------------------------------------
// Slot definitions
// ----------------------------------------------------------------

const int    TATU_SLOT_COUNT = 5;
// Slot name strings stored in SQL
const string TATU_SLOT_HEAD  = "GLOWA";
const string TATU_SLOT_NECK  = "SZYJA";
const string TATU_SLOT_CHEST = "PIERSI";
const string TATU_SLOT_LEFT  = "LEWE_RAMIE";
const string TATU_SLOT_RIGHT = "PRAWE_RAMIE";

// ----------------------------------------------------------------
// Effect tagging (TATU_EFFECT_TAG_BASE + slot_idx per slot)
// ----------------------------------------------------------------

const int TATU_EFFECT_TAG_BASE = 7000;

// ----------------------------------------------------------------
// Layout dimensions (unscaled)
// ----------------------------------------------------------------

const float TATU_W        = 740.0;
const float TATU_H        = 520.0;
const float TATU_LIST_W   = 270.0;
const float TATU_ROW_H    = 28.0;
const float TATU_BTN_H    = 30.0;
const float TATU_MAP_H    = 200.0;
const float TATU_SLOT_BTN_W = 160.0;
const float TATU_SLOT_ARM_W = 120.0;
const float TATU_DETAIL_H = 195.0;

// ----------------------------------------------------------------
// Remove ritual cost
// ----------------------------------------------------------------

const int TATU_REMOVE_GOLD = 150;
const int TATU_REMOVE_DMG  = 5;

// ----------------------------------------------------------------
// Slot helpers
// ----------------------------------------------------------------

string TatuGetSlotName(int nIdx)
{
    if(nIdx == 0) return TATU_SLOT_HEAD;
    if(nIdx == 1) return TATU_SLOT_NECK;
    if(nIdx == 2) return TATU_SLOT_CHEST;
    if(nIdx == 3) return TATU_SLOT_LEFT;
    if(nIdx == 4) return TATU_SLOT_RIGHT;
    return "";
}

string TatuGetSlotLabel(int nIdx)
{
    if(nIdx == 0) return "Głowa";
    if(nIdx == 1) return "Szyja";
    if(nIdx == 2) return "Piersi";
    if(nIdx == 3) return "Lewe Ramię";
    if(nIdx == 4) return "Prawe Ramię";
    return "";
}

int TatuGetSlotIndex(string sSlot)
{
    if(sSlot == TATU_SLOT_HEAD)  return 0;
    if(sSlot == TATU_SLOT_NECK)  return 1;
    if(sSlot == TATU_SLOT_CHEST) return 2;
    if(sSlot == TATU_SLOT_LEFT)  return 3;
    if(sSlot == TATU_SLOT_RIGHT) return 4;
    return -1;
}

// ----------------------------------------------------------------
// Ink name mapping (tag → display name)
// ----------------------------------------------------------------

string TatuInkName(string sTag)
{
    if(sTag == "ink_crow")   return "Atrament Kruczy";
    if(sTag == "ink_sight")  return "Atrament Wizji";
    if(sTag == "ink_bile")   return "Atrament Żółciowy";
    if(sTag == "ink_bone")   return "Atrament Kostny";
    if(sTag == "ink_stone")  return "Atrament Kamienny";
    if(sTag == "ink_iron")   return "Atrament Żelazny";
    if(sTag == "ink_ash")    return "Atrament Popielny";
    if(sTag == "ink_shadow") return "Atrament Cienia";
    if(sTag == "ink_blood")  return "Atrament Krwawy";
    return sTag;
}

// ----------------------------------------------------------------
// Effect text builders
// ----------------------------------------------------------------

string TatuSkillName(int nSkillId)
{
    if(nSkillId == 0)  return "Oswajanie Zwierząt";
    if(nSkillId == 1)  return "Skupienie";
    if(nSkillId == 2)  return "Rozbrajanie Pułapek";
    if(nSkillId == 3)  return "Dyscyplina";
    if(nSkillId == 4)  return "Leczenie";
    if(nSkillId == 5)  return "Ukrywanie";
    if(nSkillId == 6)  return "Nasłuchiwanie";
    if(nSkillId == 7)  return "Wiedza";
    if(nSkillId == 8)  return "Skradanie";
    if(nSkillId == 9)  return "Otwieranie Zamków";
    if(nSkillId == 10) return "Parowanie";
    if(nSkillId == 11) return "Występy";
    if(nSkillId == 12) return "Przekonywanie";
    if(nSkillId == 13) return "Kieszonkowstwo";
    if(nSkillId == 14) return "Szukanie";
    if(nSkillId == 15) return "Stawianie Pułapek";
    if(nSkillId == 16) return "Magia Zaklęć";
    if(nSkillId == 17) return "Spostrzegawczość";
    if(nSkillId == 18) return "Drwiny";
    if(nSkillId == 19) return "Akrobatyka";
    if(nSkillId == 20) return "Użycie Magii";
    return "Umiejętność";
}

string TatuSaveName(int nSaveType)
{
    if(nSaveType == 0) return "Wszystkie Rzuty";
    if(nSaveType == 1) return "Tężyzna";
    if(nSaveType == 2) return "Refleks";
    if(nSaveType == 3) return "Wola";
    return "Rzut Obronny";
}

string TatuBuildEffectText(json jDesign)
{
    string sParts = "";

    int nBonAb  = JsonGetInt(JsonObjectGet(jDesign, "bon_ab"));
    int nBonAc  = JsonGetInt(JsonObjectGet(jDesign, "bon_ac"));
    int nBonSk  = JsonGetInt(JsonObjectGet(jDesign, "bon_skill"));
    int nBonSkV = JsonGetInt(JsonObjectGet(jDesign, "bon_skill_v"));
    int nBonSv  = JsonGetInt(JsonObjectGet(jDesign, "bon_save"));
    int nBonSvV = JsonGetInt(JsonObjectGet(jDesign, "bon_save_v"));
    int nBonRs  = JsonGetInt(JsonObjectGet(jDesign, "bon_resist"));

    if(nBonAb > 0)
        sParts = sParts + "Atak +" + IntToString(nBonAb) + "   ";
    if(nBonAc > 0)
        sParts = sParts + "Zbroja +" + IntToString(nBonAc) + "   ";
    if(nBonSk >= 0 && nBonSkV > 0)
        sParts = sParts + TatuSkillName(nBonSk) + " +" + IntToString(nBonSkV) + "   ";
    if(nBonSv >= 0 && nBonSvV > 0)
        sParts = sParts + TatuSaveName(nBonSv) + " +" + IntToString(nBonSvV) + "   ";
    if(nBonRs > 0)
        sParts = sParts + "Odp. Ogień " + IntToString(nBonRs) + "   ";

    if(sParts == "") return "(brak efektu)";
    return sParts;
}

string TatuBuildCurseText(json jDesign)
{
    if(!JsonGetInt(JsonObjectGet(jDesign, "is_cursed"))) return "";

    string sCurse = "";
    int nCurAb   = JsonGetInt(JsonObjectGet(jDesign, "curse_ab"));
    int nCurSv   = JsonGetInt(JsonObjectGet(jDesign, "curse_saves"));
    int nCurCha  = JsonGetInt(JsonObjectGet(jDesign, "curse_cha"));

    if(nCurAb > 0)  sCurse = sCurse + "Atak –" + IntToString(nCurAb) + "   ";
    if(nCurSv > 0)  sCurse = sCurse + "Rzuty Obronne –" + IntToString(nCurSv) + "   ";
    if(nCurCha > 0) sCurse = sCurse + "Charyzma –" + IntToString(nCurCha) + "   ";

    return sCurse;
}

// ----------------------------------------------------------------
// JSON cache helper
// ----------------------------------------------------------------

json TatuFindDesignById(json jDesigns, int nId)
{
    int nCount = JsonGetLength(jDesigns);
    int i;
    for(i = 0; i < nCount; i++)
    {
        json jD = JsonArrayGet(jDesigns, i);
        if(JsonGetInt(JsonObjectGet(jD, "id")) == nId)
            return jD;
    }
    return JsonNull();
}

// Returns design_id for a given slot from the PC tattoos array, or 0.
int TatuFindTattooInSlot(json jTattoos, string sSlot)
{
    int nCount = JsonGetLength(jTattoos);
    int i;
    for(i = 0; i < nCount; i++)
    {
        json jT = JsonArrayGet(jTattoos, i);
        if(JsonGetString(JsonObjectGet(jT, "slot")) == sSlot)
            return JsonGetInt(JsonObjectGet(jT, "design_id"));
    }
    return 0;
}
