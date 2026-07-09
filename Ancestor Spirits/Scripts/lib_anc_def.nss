// lib_anc_def.nss — Ancestor Spirits: constants, data accessors, effects

#include "lib_nui"
#include "sql_anc"

// Forward declarations for functions defined in lib_anc.nss
void AncCreateWindow(object oPC);
void AncFeedAltar(object oPC, int nToken);
void AncFeedLineage(object oPC, int nToken);
void AncOpen(object oPC);

// ---------------------------------------------------------------
// Window / group / event
// ---------------------------------------------------------------

const string ANC_WINDOW     = "ANC_WINDOW";
const string ANC_EV_SCRIPT  = "lib_anc_ev";
const string ANC_GRP_SWAP   = "ANC_GRP_SWAP";
const string ANC_WIN_GEOM   = "anc_win_geom";

// ---------------------------------------------------------------
// Bind names — lineage selection view
// ---------------------------------------------------------------

const string ANC_BIND_LIN_NAMES    = "anc_lin_names";
const string ANC_BIND_LIN_DESCS    = "anc_lin_descs";
const string ANC_BIND_LIN_ENC      = "anc_lin_enc";
const string ANC_BIND_LIN_ROWCOUNT = "anc_lin_cnt";

// ---------------------------------------------------------------
// Bind names — altar view
// ---------------------------------------------------------------

const string ANC_BIND_LINEAGE_LBL  = "anc_lin_lbl";
const string ANC_BIND_FAVOR_LBL    = "anc_favor_lbl";
const string ANC_BIND_FAVOR_VAL    = "anc_favor_val";
const string ANC_BIND_OFFER_TXT    = "anc_offer_txt";
const string ANC_BIND_OFFER_ENA    = "anc_offer_ena";

// Ancestor row binds — append slot index (0/1/2) to each prefix
const string ANC_BIND_ANAME        = "anc_aname_";
const string ANC_BIND_ADESC        = "anc_adesc_";
const string ANC_BIND_ACOST        = "anc_acost_";
const string ANC_BIND_ASTAT        = "anc_astat_";
const string ANC_BIND_ASTATCOL     = "anc_astatcol_";
const string ANC_BIND_ABTN_ENA     = "anc_abtn_ena_";

// History list
const string ANC_BIND_HIST_ROWS    = "anc_hist_rows";
const string ANC_BIND_HIST_CNT     = "anc_hist_cnt";

// ---------------------------------------------------------------
// Button IDs
// ---------------------------------------------------------------

const string ANC_BTN_CLOSE         = "anc_btn_close";
const string ANC_BTN_LIN_ROW       = "anc_btn_linrow";
const string ANC_BTN_OFFER         = "anc_btn_offer";
const string ANC_BTN_INVOKE        = "anc_btn_invoke_";  // + slot index

// ---------------------------------------------------------------
// Lineage IDs
// ---------------------------------------------------------------

const int ANC_LINEAGE_NONE    = -1;
const int ANC_LINEAGE_WARRIOR =  0;
const int ANC_LINEAGE_MAGE    =  1;
const int ANC_LINEAGE_ROGUE   =  2;
const int ANC_LINEAGE_NOBLE   =  3;
const int ANC_LINEAGE_PEASANT =  4;
const int ANC_LINEAGE_COUNT   =  5;

// ---------------------------------------------------------------
// Costs per slot (slot 0 = cheapest, slot 2 = most powerful)
// ---------------------------------------------------------------

const int ANC_COST_SLOT_0     = 15;
const int ANC_COST_SLOT_1     = 30;
const int ANC_COST_SLOT_2     = 60;

// ---------------------------------------------------------------
// Window dimensions
// ---------------------------------------------------------------

const float ANC_W             = 480.0;
const float ANC_H             = 590.0;

// ---------------------------------------------------------------
// Lineage data
// ---------------------------------------------------------------

string AncGetLineageName(int nLineage)
{
    switch(nLineage)
    {
        case ANC_LINEAGE_WARRIOR: return "Ród Wojowniczy";
        case ANC_LINEAGE_MAGE:    return "Ród Magiczny";
        case ANC_LINEAGE_ROGUE:   return "Ród Łotrzykowski";
        case ANC_LINEAGE_NOBLE:   return "Ród Szlachecki";
        case ANC_LINEAGE_PEASANT: return "Ród Wieśniaczy";
    }
    return "Nieznany Ród";
}

string AncGetLineageDesc(int nLineage)
{
    switch(nLineage)
    {
        case ANC_LINEAGE_WARRIOR:
            return "Krew wojowników. Przodkowie dadzą siłę, pancerz i szaleństwo bitewne.";
        case ANC_LINEAGE_MAGE:
            return "Linia czarowników. Duchy użyczą wiedzy, wglądu i ochrony przed magią.";
        case ANC_LINEAGE_ROGUE:
            return "Ród łotrzyków. Przodkowie nauczą cienia, zwinności i niewidzialności.";
        case ANC_LINEAGE_NOBLE:
            return "Szlachecka krew. Duchy obdarzą dostojeństwem, wdziękiem i ochroną losu.";
        case ANC_LINEAGE_PEASANT:
            return "Korzenie sięgają ziemi. Przodkowie dadzą hart ciała, odporność i odrodzenie.";
    }
    return "";
}

// ---------------------------------------------------------------
// Ancestor data  (ancestor ID = lineage * 3 + slot)
// ---------------------------------------------------------------

string AncGetAncestorName(int nAncId)
{
    switch(nAncId)
    {
        // Warrior lineage
        case  0: return "Ragnar Żelazny";
        case  1: return "Zbroja Krwi";
        case  2: return "Duchy Berserków";
        // Mage lineage
        case  3: return "Stara Wiedźma";
        case  4: return "Mistrz Rytuałów";
        case  5: return "Strażnik Runów";
        // Rogue lineage
        case  6: return "Czarny Nóż";
        case  7: return "Mistrzyni Cieni";
        case  8: return "Gildyjny Szpieg";
        // Noble lineage
        case  9: return "Lord Ashenvale";
        case 10: return "Pani Fortuny";
        case 11: return "Krwawa Rada";
        // Peasant lineage
        case 12: return "Stara Zielarka";
        case 13: return "Matka Ziemia";
        case 14: return "Duch Pól";
    }
    return "Nieznany Przodek";
}

string AncGetAncestorDesc(int nAncId)
{
    switch(nAncId)
    {
        case  0: return "Siła +4 przez 10 min.";
        case  1: return "Pancerz +4 przez 5 min.";
        case  2: return "Pośpiech i Siła +4 przez 2 min.";
        case  3: return "Inteligencja +4 przez 10 min.";
        case  4: return "Mądrość +4 przez 10 min.";
        case  5: return "Odporność na zaklęcia +10 przez 10 min.";
        case  6: return "Zręczność +4 przez 10 min.";
        case  7: return "Niewidzialność przez 1 min.";
        case  8: return "Ukrycie i Cichy Krok +10 przez 30 min.";
        case  9: return "Charyzma +4 przez 10 min.";
        case 10: return "MĄD+INT+CHA +2 przez 10 min.";
        case 11: return "Rzuty obronne +5 przez 5 min.";
        case 12: return "Tymczasowe HP +50 przez 1 godz.";
        case 13: return "Odporność na choroby przez 2 godz.";
        case 14: return "Kondycja +4 i regeneracja 2 HP/6s przez 10 min.";
    }
    return "";
}

int AncGetCostBySlot(int nSlot)
{
    switch(nSlot)
    {
        case 0: return ANC_COST_SLOT_0;
        case 1: return ANC_COST_SLOT_1;
        case 2: return ANC_COST_SLOT_2;
    }
    return 9999;
}

// ---------------------------------------------------------------
// Status / cooldown helpers
// ---------------------------------------------------------------

// Returns seconds remaining on cooldown, or 0 if ready.
int AncGetCooldownRemaining(object oPC, int nAncestorId)
{
    int nNow      = AncGetCurrentUnix();
    int nLast     = AncGetLastInvoked(oPC, nAncestorId);
    if(nLast == 0) return 0;
    int nElapsed  = nNow - nLast;
    if(nElapsed >= ANC_COOLDOWN_SECS) return 0;
    return ANC_COOLDOWN_SECS - nElapsed;
}

string AncFormatCooldown(int nSecsRemaining)
{
    if(nSecsRemaining <= 0) return "Dostepny";
    int nHours = nSecsRemaining / 3600;
    int nMins  = (nSecsRemaining % 3600) / 60;
    if(nHours > 0)
        return "Odnawia sie: " + IntToString(nHours) + "h " + IntToString(nMins) + "m";
    return "Odnawia sie: " + IntToString(nMins) + "m";
}

// ---------------------------------------------------------------
// Effect application helpers (complex multi-effect cases)
// ---------------------------------------------------------------

void AncApplyBerserk(object oPC)
{
    ApplyEffectToObject(DURATION_TYPE_TEMPORARY,
        EffectLinkEffects(
            EffectHaste(),
            EffectAbilityIncrease(ABILITY_STRENGTH, 4)),
        oPC, 120.0);
}

void AncApplySpy(object oPC)
{
    ApplyEffectToObject(DURATION_TYPE_TEMPORARY,
        EffectLinkEffects(
            EffectSkillIncrease(SKILL_HIDE, 10),
            EffectSkillIncrease(SKILL_MOVE_SILENTLY, 10)),
        oPC, 1800.0);
}

void AncApplyFortune(object oPC)
{
    ApplyEffectToObject(DURATION_TYPE_TEMPORARY,
        EffectLinkEffects(
            EffectLinkEffects(
                EffectAbilityIncrease(ABILITY_WISDOM, 2),
                EffectAbilityIncrease(ABILITY_INTELLIGENCE, 2)),
            EffectAbilityIncrease(ABILITY_CHARISMA, 2)),
        oPC, 600.0);
}

void AncApplySpirit(object oPC)
{
    ApplyEffectToObject(DURATION_TYPE_TEMPORARY,
        EffectLinkEffects(
            EffectAbilityIncrease(ABILITY_CONSTITUTION, 4),
            EffectRegenerate(2, 6.0)),
        oPC, 600.0);
}

void AncApplyAncestorEffect(object oPC, int nAncId)
{
    switch(nAncId)
    {
        case  0:
            ApplyEffectToObject(DURATION_TYPE_TEMPORARY,
                EffectAbilityIncrease(ABILITY_STRENGTH, 4), oPC, 600.0);
            break;
        case  1:
            ApplyEffectToObject(DURATION_TYPE_TEMPORARY,
                EffectACIncrease(4, AC_DODGE_BONUS, DAMAGE_TYPE_ALL), oPC, 300.0);
            break;
        case  2: AncApplyBerserk(oPC);  break;
        case  3:
            ApplyEffectToObject(DURATION_TYPE_TEMPORARY,
                EffectAbilityIncrease(ABILITY_INTELLIGENCE, 4), oPC, 600.0);
            break;
        case  4:
            ApplyEffectToObject(DURATION_TYPE_TEMPORARY,
                EffectAbilityIncrease(ABILITY_WISDOM, 4), oPC, 600.0);
            break;
        case  5:
            ApplyEffectToObject(DURATION_TYPE_TEMPORARY,
                EffectSpellResistanceIncrease(10), oPC, 600.0);
            break;
        case  6:
            ApplyEffectToObject(DURATION_TYPE_TEMPORARY,
                EffectAbilityIncrease(ABILITY_DEXTERITY, 4), oPC, 600.0);
            break;
        case  7:
            ApplyEffectToObject(DURATION_TYPE_TEMPORARY,
                EffectInvisibility(INVISIBILITY_TYPE_NORMAL), oPC, 60.0);
            break;
        case  8: AncApplySpy(oPC);      break;
        case  9:
            ApplyEffectToObject(DURATION_TYPE_TEMPORARY,
                EffectAbilityIncrease(ABILITY_CHARISMA, 4), oPC, 600.0);
            break;
        case 10: AncApplyFortune(oPC);  break;
        case 11:
            ApplyEffectToObject(DURATION_TYPE_TEMPORARY,
                EffectSavingThrowIncrease(SAVING_THROW_ALL, 5, SAVING_THROW_TYPE_ALL),
                oPC, 300.0);
            break;
        case 12:
            ApplyEffectToObject(DURATION_TYPE_TEMPORARY,
                EffectTemporaryHitpoints(50), oPC, 3600.0);
            break;
        case 13:
            ApplyEffectToObject(DURATION_TYPE_TEMPORARY,
                EffectImmunity(IMMUNITY_TYPE_DISEASE), oPC, 7200.0);
            break;
        case 14: AncApplySpirit(oPC);   break;
    }
}

// ---------------------------------------------------------------
// Core invocation logic (does not touch NUI — callers do that)
// ---------------------------------------------------------------

void AncInvokeAncestor(object oPC, int nSlot)
{
    int nLineage  = AncGetLineage(oPC);
    if(nLineage == ANC_LINEAGE_NONE) return;

    int nAncId    = nLineage * 3 + nSlot;
    int nCost     = AncGetCostBySlot(nSlot);
    int nFavor    = AncGetFavor(oPC);
    int nCooldown = AncGetCooldownRemaining(oPC, nAncId);
    string sName  = AncGetAncestorName(nAncId);

    if(nCooldown > 0)
    {
        SendMessageToPC(oPC,
            "[Przodkowie] " + sName + " nie moze jeszcze odpowiedziec. "
            + AncFormatCooldown(nCooldown) + ".");
        return;
    }
    if(nFavor < nCost)
    {
        SendMessageToPC(oPC,
            "[Przodkowie] Za malo Laski, by wezwac " + sName
            + ". Potrzebujesz " + IntToString(nCost)
            + " (masz " + IntToString(nFavor) + ").");
        return;
    }

    AncSpendFavor(oPC, nCost);
    AncSetInvoked(oPC, nAncId);
    AncAddHistory(oPC, nAncId, sName);
    AncApplyAncestorEffect(oPC, nAncId);

    FloatingTextStringOnCreature(
        "Pieczen krwi pulsuje slabo... duch " + sName + " przemawia.", oPC, FALSE);
    SendMessageToPC(oPC,
        "[Przodkowie] " + sName + " odpowiedzial na twoje wezwanie. Laska -"
        + IntToString(nCost) + ".");
}
