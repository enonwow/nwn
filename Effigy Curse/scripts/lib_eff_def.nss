#include "lib_nui"

void EffNotifyCreator(string sCreatorUuid, string sMsg);

// ----------------------------------------------------------------
// Window
// ----------------------------------------------------------------

const string EFF_WINDOW             = "EFF_WINDOW";
const string EFF_EV_SCRIPT          = "lib_eff_ev";

// Tabs (implemented as visibility-swapped groups)
const int EFF_TAB_CREATE            = 0;
const int EFF_TAB_MINE              = 1;
const int EFF_TAB_AFFECTED          = 2;

// ----------------------------------------------------------------
// Binds — Create tab
// ----------------------------------------------------------------

const string EFF_BIND_TAB_ACTIVE    = "eff_tab_active";   // JsonArray[3] of bool

const string EFF_BIND_TGT_NAMES     = "eff_tgt_names";
const string EFF_BIND_TGT_ENC       = "eff_tgt_enc";

const string EFF_BIND_C1_ACTIVE     = "eff_c1_active";
const string EFF_BIND_C2_ACTIVE     = "eff_c2_active";
const string EFF_BIND_C3_ACTIVE     = "eff_c3_active";
const string EFF_BIND_C4_ACTIVE     = "eff_c4_active";

const string EFF_BIND_COST_LBL      = "eff_cost_lbl";
const string EFF_BIND_FLAVOR_LBL    = "eff_flavor_lbl";
const string EFF_BIND_TGT_LBL       = "eff_tgt_lbl";
const string EFF_BIND_CREATE_ENA    = "eff_create_ena";
const string EFF_BIND_TAB0_VIS      = "eff_tab0_vis";
const string EFF_BIND_TAB1_VIS      = "eff_tab1_vis";
const string EFF_BIND_TAB2_VIS      = "eff_tab2_vis";

// ----------------------------------------------------------------
// Binds — My Effigies tab
// ----------------------------------------------------------------

const string EFF_BIND_MINE_TGTS     = "eff_mine_tgts";
const string EFF_BIND_MINE_TYPES    = "eff_mine_types";
const string EFF_BIND_MINE_AGES     = "eff_mine_ages";
const string EFF_BIND_MINE_ENC      = "eff_mine_enc";
const string EFF_BIND_MINE_COLORS   = "eff_mine_colors";
const string EFF_BIND_SMASH_ENA     = "eff_smash_ena";
const string EFF_BIND_MINE_INFO     = "eff_mine_info";

// ----------------------------------------------------------------
// Binds — Affected tab
// ----------------------------------------------------------------

const string EFF_BIND_AFF_SRCS      = "eff_aff_srcs";
const string EFF_BIND_AFF_TYPES     = "eff_aff_types";
const string EFF_BIND_AFF_ENC       = "eff_aff_enc";
const string EFF_BIND_DETECT_LBL    = "eff_detect_lbl";
const string EFF_BIND_CLEANSE_ENA   = "eff_cleanse_ena";
const string EFF_BIND_AFF_INFO      = "eff_aff_info";

// ----------------------------------------------------------------
// Buttons
// ----------------------------------------------------------------

const string EFF_BTN_CLOSE          = "eff_btn_close";
const string EFF_BTN_TAB0           = "eff_btn_tab0";
const string EFF_BTN_TAB1           = "eff_btn_tab1";
const string EFF_BTN_TAB2           = "eff_btn_tab2";
const string EFF_BTN_TGT_ROW        = "eff_btn_tgt";
const string EFF_BTN_C1             = "eff_btn_c1";
const string EFF_BTN_C2             = "eff_btn_c2";
const string EFF_BTN_C3             = "eff_btn_c3";
const string EFF_BTN_C4             = "eff_btn_c4";
const string EFF_BTN_CREATE         = "eff_btn_create";
const string EFF_BTN_MINE_ROW       = "eff_btn_mine";
const string EFF_BTN_SMASH          = "eff_btn_smash";
const string EFF_BTN_DETECT         = "eff_btn_detect";
const string EFF_BTN_CLEANSE        = "eff_btn_cleanse";
const string EFF_BTN_AFF_ROW        = "eff_btn_aff";

// ----------------------------------------------------------------
// Curse types
// ----------------------------------------------------------------

const int EFF_CURSE_ANGUISH         = 1;  // 1d4 damage per heartbeat
const int EFF_CURSE_WITHER          = 2;  // -2 STR, -2 CON permanent while active
const int EFF_CURSE_BLINDNESS       = 3;  // 25% chance of 4s blindness each heartbeat
const int EFF_CURSE_TORPOR          = 4;  // -2 DEX, 20% chance of 3s slow each heartbeat

// ----------------------------------------------------------------
// Gold costs
// ----------------------------------------------------------------

const int EFF_COST_ANGUISH          = 300;
const int EFF_COST_WITHER           = 500;
const int EFF_COST_BLINDNESS        = 400;
const int EFF_COST_TORPOR           = 600;

// ----------------------------------------------------------------
// Mechanics
// ----------------------------------------------------------------

const int EFF_DETECT_DC             = 18;
const int EFF_CLEANSE_COST          = 800;
const int EFF_SMASH_DAMAGE_MIN      = 8;   // min damage on smash (d10+8)
const int EFF_SMASH_DAMAGE_MAX      = 18;  // max
const int EFF_MAX_EFFIGIES_PER_PC   = 4;

// ----------------------------------------------------------------
// LVARs on PC
// ----------------------------------------------------------------

const string EFF_LVAR_SEL_TGT_UUID  = "EFF_SEL_TGT_UUID";
const string EFF_LVAR_SEL_TGT_NAME  = "EFF_SEL_TGT_NAME";
const string EFF_LVAR_SEL_CURSE     = "EFF_SEL_CURSE";
const string EFF_LVAR_SEL_MINE_ID   = "EFF_SEL_MINE_ID";
const string EFF_LVAR_SEL_AFF_ID    = "EFF_SEL_AFF_ID";
const string EFF_LVAR_DETECTED_IDS  = "EFF_DETECTED_IDS"; // JsonArray of int effigy ids detected

// ----------------------------------------------------------------
// Window dimensions
// ----------------------------------------------------------------

const float EFF_W                   = 660.0;
const float EFF_H                   = 520.0;

// ----------------------------------------------------------------
// Helpers
// ----------------------------------------------------------------

string EffCurseName(int nType)
{
    switch(nType)
    {
        case EFF_CURSE_ANGUISH:   return "Meczarnia";
        case EFF_CURSE_WITHER:    return "Więdnięcie";
        case EFF_CURSE_BLINDNESS: return "Zaćmienie";
        case EFF_CURSE_TORPOR:    return "Otępienie";
    }
    return "Nieznana";
}

int EffCurseCost(int nType)
{
    switch(nType)
    {
        case EFF_CURSE_ANGUISH:   return EFF_COST_ANGUISH;
        case EFF_CURSE_WITHER:    return EFF_COST_WITHER;
        case EFF_CURSE_BLINDNESS: return EFF_COST_BLINDNESS;
        case EFF_CURSE_TORPOR:    return EFF_COST_TORPOR;
    }
    return 999999;
}

string EffCurseFlavor(int nType)
{
    switch(nType)
    {
        case EFF_CURSE_ANGUISH:
            return "Figurka pulsuje czerwienią. Każde bicie serca ofiary\nto ukłucie niewidzialnej igły.";
        case EFF_CURSE_WITHER:
            return "Wosk powoli żółknie. Mięśnie i krew ofiary\nstają się słabsze z każdym dniem.";
        case EFF_CURSE_BLINDNESS:
            return "Oczy figurki okryte czarnym woskiem.\nOfiara widzi coraz gorzej — mroki rosną.";
        case EFF_CURSE_TORPOR:
            return "Figurka owinięta pajęczynami. Ruchy ofiary\nstają się ciężkie niczym przez bagno.";
    }
    return "";
}

void EffNotifyCreator(string sCreatorUuid, string sMsg)
{
    object oPC = GetFirstPC();
    while(GetIsObjectValid(oPC))
    {
        if(GetObjectUUID(oPC) == sCreatorUuid)
        {
            SendMessageToPC(oPC, "[Figurka] " + sMsg);
            return;
        }
        oPC = GetNextPC();
    }
}
