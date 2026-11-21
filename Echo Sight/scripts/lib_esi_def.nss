// lib_esi_def.nss — Echo Sight: constants, bind names, and shared helpers

#include "lib_nui"
#include "sql_esi"

// --- Window IDs ---
const string ESI_WIN_CODEX   = "ESI_CODEX";
const string ESI_WIN_VISION  = "ESI_VISION";
const string ESI_EV_SCRIPT   = "lib_esi_ev";

// --- Window geometry (pre-scale) ---
const float ESI_CODEX_W   = 760.0;
const float ESI_CODEX_H   = 520.0;
const float ESI_VISION_W  = 520.0;
const float ESI_VISION_H  = 420.0;

// --- Echo placeable tag and local variable names (set by DM/builder) ---
const string ESI_OBJ_TAG        = "esi_echo";
const string ESI_VAR_TITLE      = "ESI_ECHO_TITLE";    // string  — title shown in codex
const string ESI_VAR_TEXT       = "ESI_ECHO_TEXT";     // string  — full vision text
const string ESI_VAR_CATEGORY   = "ESI_ECHO_CAT";      // int     — 0-4 (see below)
const string ESI_VAR_DC         = "ESI_ECHO_DC";       // int     — Spot DC, 0 = always succeed
const string ESI_VAR_BONUS_TYPE = "ESI_ECHO_BTYPE";    // int     — bonus type on consume
const string ESI_VAR_BONUS_VAL  = "ESI_ECHO_BVAL";     // int     — bonus magnitude
const string ESI_VAR_TRAUMA     = "ESI_ECHO_TRAUMA";   // int     — 1 = traumatic (1d4 dmg on absorb)
const string ESI_VAR_FLAVOR     = "ESI_ECHO_FLAVOR";   // string  — one-line codex summary

// --- Category indices ---
const int ESI_CAT_MURDER   = 0;
const int ESI_CAT_BATTLE   = 1;
const int ESI_CAT_RITUAL   = 2;
const int ESI_CAT_BETRAYAL = 3;
const int ESI_CAT_AGONY    = 4;

// --- Bonus types ---
const int ESI_BONUS_NONE     = 0;
const int ESI_BONUS_ATTACK   = 1;   // +N to all attack rolls
const int ESI_BONUS_SAVES    = 2;   // +N to all saving throws
const int ESI_BONUS_SEARCH   = 3;   // +N to Search skill
const int ESI_BONUS_TEMP_HP  = 4;   // +(N*5) temporary hit points

// --- Effect tag used for all Echo Sight bonuses ---
const string ESI_EFFECT_TAG = "ESI_BONUS";

// --- NUI bind names: codex list (list-bound arrays) ---
const string ESI_BIND_ROW_TITLE  = "esi_row_title";
const string ESI_BIND_ROW_CAT    = "esi_row_cat";
const string ESI_BIND_ROW_FLAVOR = "esi_row_flavor";
const string ESI_BIND_ROW_STATUS = "esi_row_status";
const string ESI_BIND_ROW_ENC    = "esi_row_enc";
const string ESI_BIND_ROW_COLOR  = "esi_row_color";
const string ESI_BIND_ROW_CNT    = "esi_row_cnt";    // NuiList row count

// --- NUI bind names: detail panel (scalar) ---
const string ESI_BIND_DET_TITLE    = "esi_det_title";
const string ESI_BIND_DET_CAT      = "esi_det_cat";
const string ESI_BIND_DET_TEXT     = "esi_det_text";
const string ESI_BIND_DET_BONUS    = "esi_det_bonus";
const string ESI_BIND_DET_CONS_LBL = "esi_det_clbl";
const string ESI_BIND_CONSUME_ENA  = "esi_cons_ena";

// --- NUI bind names: footer ---
const string ESI_BIND_COUNT   = "esi_count";

// --- NUI bind names: vision window ---
const string ESI_BIND_VIS_TITLE  = "esi_vis_title";
const string ESI_BIND_VIS_CAT    = "esi_vis_cat";
const string ESI_BIND_VIS_TEXT   = "esi_vis_text";
const string ESI_BIND_VIS_TRAUMA = "esi_vis_trauma";

// --- Button IDs ---
const string ESI_BTN_CLOSE   = "esi_btn_close";
const string ESI_BTN_ROW     = "esi_btn_row";
const string ESI_BTN_CONSUME = "esi_btn_consume";
const string ESI_BTN_ABSORB  = "esi_btn_absorb";
const string ESI_BTN_REJECT  = "esi_btn_reject";

// --- PC local variable keys ---
const string ESI_LVAR_SEL_UUID = "ESI_SEL_UUID";
const string ESI_LVAR_PENDING  = "ESI_PENDING";    // JSON: pending vision data awaiting player choice

// --- Limits ---
const int ESI_MAX_ECHOES = 20;

// ----------------------------------------------------------------
// Helpers
// ----------------------------------------------------------------

string EsiCategoryName(int nCat)
{
    switch(nCat)
    {
        case ESI_CAT_MURDER:   return "Morderstwo";
        case ESI_CAT_BATTLE:   return "Bitwa";
        case ESI_CAT_RITUAL:   return "Rytuał";
        case ESI_CAT_BETRAYAL: return "Zdrada";
        case ESI_CAT_AGONY:    return "Agonia";
    }
    return "Nieznane";
}

// Short single-letter prefix for the codex list (saves horizontal space)
string EsiCategoryPrefix(int nCat)
{
    switch(nCat)
    {
        case ESI_CAT_MURDER:   return "[M]";
        case ESI_CAT_BATTLE:   return "[B]";
        case ESI_CAT_RITUAL:   return "[R]";
        case ESI_CAT_BETRAYAL: return "[Z]";
        case ESI_CAT_AGONY:    return "[A]";
    }
    return "[?]";
}

string EsiBonusDescription(int nType, int nVal)
{
    switch(nType)
    {
        case ESI_BONUS_ATTACK:  return "+" + IntToString(nVal) + " do ataków";
        case ESI_BONUS_SAVES:   return "+" + IntToString(nVal) + " do rzutów obronnych";
        case ESI_BONUS_SEARCH:  return "+" + IntToString(nVal) + " do Przeszukiwania";
        case ESI_BONUS_TEMP_HP: return "+" + IntToString(nVal * 5) + " tymczasowych PŻ";
    }
    return "Brak premii";
}

void EsiApplyBonus(object oPC, int nType, int nVal)
{
    effect eBonus;
    switch(nType)
    {
        case ESI_BONUS_ATTACK:
            eBonus = EffectAttackIncrease(nVal, ATTACK_BONUS_MISC);
            break;
        case ESI_BONUS_SAVES:
            eBonus = EffectSavingThrowIncrease(SAVING_THROW_ALL, nVal, SAVING_THROW_TYPE_ALL);
            break;
        case ESI_BONUS_SEARCH:
            eBonus = EffectSkillIncrease(SKILL_SEARCH, nVal);
            break;
        case ESI_BONUS_TEMP_HP:
            eBonus = EffectTemporaryHitpoints(nVal * 5);
            break;
        default:
            return;
    }
    eBonus = TagEffect(eBonus, ESI_EFFECT_TAG);
    ApplyEffectToObject(DURATION_TYPE_PERMANENT, eBonus, oPC);
}

void EsiRemoveAllBonuses(object oPC)
{
    effect e = GetFirstEffect(oPC);
    while(GetIsEffectValid(e))
    {
        effect eNext = GetNextEffect(oPC);
        if(GetEffectTag(e) == ESI_EFFECT_TAG)
            RemoveEffect(oPC, e);
        e = eNext;
    }
}

void EsiReapplyAllBonuses(object oPC)
{
    EsiRemoveAllBonuses(oPC);
    json jBonuses = EsiGetAllActiveBonuses(oPC);
    int nCount = JsonGetLength(jBonuses);
    int i;
    for(i = 0; i < nCount; i++)
    {
        json jB   = JsonArrayGet(jBonuses, i);
        int nType = JsonGetInt(JsonObjectGet(jB, "bonus_type"));
        int nVal  = JsonGetInt(JsonObjectGet(jB, "bonus_val"));
        EsiApplyBonus(oPC, nType, nVal);
    }
}
