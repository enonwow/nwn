#include "lib_nui"
#include "sql_grv"

void GrvCreateBurialWindow(object oPC);
void GrvCreateShopWindow(object oPC);
void GrvCreateGraveWindow(object oPC, int nGraveId);
void GrvFeedBurialWindow(object oPC, int nToken);
void GrvFeedShopWindow(object oPC, int nToken);
void GrvFeedGraveWindow(object oPC, int nToken, int nGraveId);

// ----------------------------------------------------------------
// Window IDs
// ----------------------------------------------------------------

const string GRV_WINDOW        = "GRV_WINDOW";
const string GRV_WIN_SHOP      = "GRV_WIN_SHOP";
const string GRV_WIN_GRAVE     = "GRV_WIN_GRAVE";
const string GRV_EV_SCRIPT     = "lib_grv_ev";

const string GRV_GRP_SWAP      = "GRV_GRP_SWAP";

// ----------------------------------------------------------------
// Burial window binds
// ----------------------------------------------------------------

const string GRV_BIND_WIN_GEOM      = "grv_win_geom";
const string GRV_BIND_DECEASED      = "grv_deceased";
const string GRV_BIND_TYPE0_ENC     = "grv_type0_enc";
const string GRV_BIND_TYPE1_ENC     = "grv_type1_enc";
const string GRV_BIND_TYPE2_ENC     = "grv_type2_enc";
const string GRV_BIND_MAT_DESC      = "grv_mat_desc";
const string GRV_BIND_GRACE_LBL     = "grv_grace_lbl";
const string GRV_BIND_GOLD_TXT      = "grv_gold_txt";
const string GRV_BIND_BURY_ENA      = "grv_bury_ena";
const string GRV_BIND_STATUS_LBL    = "grv_status_lbl";
const string GRV_BIND_MARKS_LBL     = "grv_marks_lbl";

// ----------------------------------------------------------------
// Shop window binds
// ----------------------------------------------------------------

const string GRV_BIND_SHOP_GEOM     = "grv_shop_geom";
const string GRV_BIND_SHOP_GRACE    = "grv_shop_grace";
const string GRV_BIND_SHOP_ROWNAME  = "grv_shop_rowname";
const string GRV_BIND_SHOP_ROWCOST  = "grv_shop_rowcost";
const string GRV_BIND_SHOP_ROWENA   = "grv_shop_rowena";
const string GRV_BIND_SHOP_ROWENC   = "grv_shop_rowenc";
const string GRV_BIND_SHOP_ROWDESC  = "grv_shop_rowdesc";
const string GRV_BIND_SHOP_COUNT    = "grv_shop_count";

// ----------------------------------------------------------------
// Grave interaction window binds
// ----------------------------------------------------------------

const string GRV_BIND_GRAVE_GEOM    = "grv_grave_geom";
const string GRV_BIND_GRAVE_TITLE   = "grv_grave_title";
const string GRV_BIND_GRAVE_INFO    = "grv_grave_info";
const string GRV_BIND_GRAVE_DESEC   = "grv_grave_desec_ena";
const string GRV_BIND_PRAY_ENA      = "grv_pray_ena";
const string GRV_BIND_PRAY_LBL      = "grv_pray_lbl";

// ----------------------------------------------------------------
// Buttons
// ----------------------------------------------------------------

const string GRV_BTN_CLOSE          = "grv_btn_close";
const string GRV_BTN_TYPE0          = "grv_btn_type0";
const string GRV_BTN_TYPE1          = "grv_btn_type1";
const string GRV_BTN_TYPE2          = "grv_btn_type2";
const string GRV_BTN_BURY           = "grv_btn_bury";
const string GRV_BTN_OPEN_SHOP      = "grv_btn_shop";
const string GRV_BTN_SHOP_CLOSE     = "grv_btn_shopclose";
const string GRV_BTN_BUY            = "grv_btn_buy";
const string GRV_BTN_GRAVE_CLOSE    = "grv_btn_graveclose";
const string GRV_BTN_PRAY           = "grv_btn_pray";
const string GRV_BTN_DESECRATE      = "grv_btn_desecrate";

// ----------------------------------------------------------------
// Local vars on PC
// ----------------------------------------------------------------

const string GRV_LVAR_TYPE          = "GRV_BURIAL_TYPE";
const string GRV_LVAR_GRAVE_ID      = "GRV_ACTIVE_GRAVE";

// ----------------------------------------------------------------
// Grave types
// ----------------------------------------------------------------

const int GRV_TYPE_MOUND   = 0;
const int GRV_TYPE_STONE   = 1;
const int GRV_TYPE_CRYPT   = 2;

// ----------------------------------------------------------------
// Balance constants
// ----------------------------------------------------------------

const int GRV_GOLD_MOUND   = 0;
const int GRV_GOLD_STONE   = 50;
const int GRV_GOLD_CRYPT   = 200;

const int GRV_GRACE_MOUND  = 1;
const int GRV_GRACE_STONE  = 3;
const int GRV_GRACE_CRYPT  = 10;

const int GRV_GHOST_GOLD_MIN    = 50;
const int GRV_GHOST_CHANCE_BASE = 25;

const int GRV_DESEC_CURSE_THRESHOLD = 5;
const int GRV_DESEC_HEAVY_THRESHOLD = 10;
const int GRV_FORGIVE_COOLDOWN_SEC  = 86400;

// Shop
const int GRV_SHOP_COUNT = 5;

// ----------------------------------------------------------------
// Layout
// ----------------------------------------------------------------

const float GRV_WIN_W    = 480.0;
const float GRV_WIN_H    = 400.0;
const float GRV_SHOP_W   = 440.0;
const float GRV_SHOP_H   = 340.0;
const float GRV_GRAVE_W  = 400.0;
const float GRV_GRAVE_H  = 290.0;

// ----------------------------------------------------------------
// Helpers
// ----------------------------------------------------------------

string GrvGetGraveTypeName(int nType)
{
    if(nType == GRV_TYPE_STONE) return "Kamienny Nagrobek";
    if(nType == GRV_TYPE_CRYPT) return "Krypta Szlachecka";
    return "Usypana Mogiła";
}

string GrvGetGraveTypeMaterials(int nType)
{
    if(nType == GRV_TYPE_STONE) return "Koszt: 50 sztuk złota";
    if(nType == GRV_TYPE_CRYPT) return "Koszt: 200 sztuk złota";
    return "Koszt: bezpłatnie";
}

int GrvGetGraveTypeGoldCost(int nType)
{
    if(nType == GRV_TYPE_STONE) return GRV_GOLD_STONE;
    if(nType == GRV_TYPE_CRYPT) return GRV_GOLD_CRYPT;
    return GRV_GOLD_MOUND;
}

int GrvGetGraveTypeGrace(int nType)
{
    if(nType == GRV_TYPE_STONE) return GRV_GRACE_STONE;
    if(nType == GRV_TYPE_CRYPT) return GRV_GRACE_CRYPT;
    return GRV_GRACE_MOUND;
}

string GrvGetShopItemName(int nIdx)
{
    switch(nIdx)
    {
        case 0: return "Pokora Kości";
        case 1: return "Pieczęć Przed Zepsuciem";
        case 2: return "Wzrok Przez Zasłonę";
        case 3: return "Tarcza Przed Śmiercią";
        case 4: return "Rozgrzeszenie";
    }
    return "";
}

string GrvGetShopItemDesc(int nIdx)
{
    switch(nIdx)
    {
        case 0: return "Grabarz odmawia modlitwę — odzysk 2k8 HP";
        case 1: return "Starożytna pieczęć — +2 do AC (8h)";
        case 2: return "Oczy widzą to, co ukryte — True Seeing (1h)";
        case 3: return "Sam Śmierć cofnie się przed tobą — Death Ward (1h)";
        case 4: return "Ceremonialnie zdejmuje z ciebie jedno Piętno Zbezczeszczenia";
    }
    return "";
}

int GrvGetShopItemCost(int nIdx)
{
    switch(nIdx)
    {
        case 0: return 3;
        case 1: return 5;
        case 2: return 8;
        case 3: return 15;
        case 4: return 10;
    }
    return 999;
}

void GrvApplyShopEffect(object oPC, int nIdx)
{
    switch(nIdx)
    {
        case 0:
        {
            int nHeal = d8(2);
            effect eHeal = EffectHeal(nHeal);
            ApplyEffectToObject(DURATION_TYPE_INSTANT, eHeal, oPC);
            FloatingTextStringOnCreature("Kości cicho szepczą... +" + IntToString(nHeal) + " HP", oPC, FALSE);
            break;
        }
        case 1:
        {
            effect eAC = EffectACIncrease(2, AC_DODGE_BONUS);
            eAC = EffectLinkEffects(eAC, EffectVisualEffect(VFX_DUR_PROTECTION_GOOD_MINOR));
            ApplyEffectToObject(DURATION_TYPE_TEMPORARY, eAC, oPC, 28800.0);
            FloatingTextStringOnCreature("Pieczęć pulsuje na twojej skórze...", oPC, FALSE);
            break;
        }
        case 2:
        {
            effect eSight = EffectTrueSeeing();
            eSight = EffectLinkEffects(eSight, EffectVisualEffect(VFX_DUR_SPELL_TRUE_SEEING));
            ApplyEffectToObject(DURATION_TYPE_TEMPORARY, eSight, oPC, 3600.0);
            FloatingTextStringOnCreature("Zasłona między światami staje się przezroczysta...", oPC, FALSE);
            break;
        }
        case 3:
        {
            effect eDW = EffectImmunity(IMMUNITY_TYPE_DEATH);
            eDW = EffectLinkEffects(eDW, EffectImmunity(IMMUNITY_TYPE_NEGATIVE_LEVEL));
            eDW = EffectLinkEffects(eDW, EffectVisualEffect(VFX_DUR_PROTECTION_GOOD_MAJOR));
            ApplyEffectToObject(DURATION_TYPE_TEMPORARY, eDW, oPC, 3600.0);
            FloatingTextStringOnCreature("Śmierć omija cię szerokim łukiem...", oPC, FALSE);
            break;
        }
        case 4:
        {
            GrvRemoveDesecMark(oPC);
            GrvLogPrayer(oPC, 0);
            FloatingTextStringOnCreature("Piętno Zbezczeszczenia słabnie...", oPC, FALSE);
            break;
        }
    }
}

void GrvApplyCursePenalties(object oPC, int nMarks)
{
    if(nMarks < GRV_DESEC_CURSE_THRESHOLD) return;

    // Remove old graveyard curse before applying new
    effect eCurrent = GetFirstEffect(oPC);
    while(GetIsEffectValid(eCurrent))
    {
        if(GetEffectTag(eCurrent) == "GRV_DESEC_CURSE")
            RemoveEffect(oPC, eCurrent);
        eCurrent = GetNextEffect(oPC);
    }

    effect eCurse;
    if(nMarks >= GRV_DESEC_HEAVY_THRESHOLD)
    {
        eCurse = EffectSavingThrowDecrease(SAVING_THROW_ALL, 4);
        eCurse = EffectLinkEffects(eCurse, EffectAbilityDecrease(ABILITY_WISDOM, 2));
        eCurse = EffectLinkEffects(eCurse, EffectVisualEffect(VFX_DUR_DARKNESS));
        FloatingTextStringOnCreature("Kości martwych krzyczą w twojej głowie...", oPC, FALSE);
    }
    else
    {
        eCurse = EffectSavingThrowDecrease(SAVING_THROW_ALL, 2);
        eCurse = EffectLinkEffects(eCurse, EffectVisualEffect(VFX_DUR_BLUR));
        FloatingTextStringOnCreature("Cień wisi nad tobą niewidzialny...", oPC, FALSE);
    }

    eCurse = TagEffect(eCurse, "GRV_DESEC_CURSE");
    ApplyEffectToObject(DURATION_TYPE_PERMANENT, eCurse, oPC);
}

void GrvApplyPrayerBuff(object oPC)
{
    effect eBuff = EffectSavingThrowIncrease(SAVING_THROW_ALL, 2, SAVING_THROW_TYPE_ALL);
    eBuff = EffectLinkEffects(eBuff, EffectVisualEffect(VFX_DUR_PROTECTION_GOOD_MINOR));
    eBuff = TagEffect(eBuff, "GRV_PRAYER_BUFF");
    ApplyEffectToObject(DURATION_TYPE_TEMPORARY, eBuff, oPC, 28800.0);
}

void GrvTrySpawnGhost(object oPC, string sDeceasedName, int nGoldBuried)
{
    if(nGoldBuried < GRV_GHOST_GOLD_MIN) return;

    int nChance = GRV_GHOST_CHANCE_BASE + (nGoldBuried / 20);
    if(nChance > 75) nChance = 75;
    if(d100() > nChance) return;

    // Ghost manifests as a spectral blessing rather than a creature (no NWNX required)
    effect eGhost = EffectSavingThrowIncrease(SAVING_THROW_ALL, 1, SAVING_THROW_TYPE_ALL);
    eGhost = EffectLinkEffects(eGhost, EffectAttackIncrease(1));
    eGhost = EffectLinkEffects(eGhost, EffectVisualEffect(VFX_DUR_GHOSTLY_VISAGE));
    eGhost = TagEffect(eGhost, "GRV_GHOST_BLESS");
    ApplyEffectToObject(DURATION_TYPE_TEMPORARY, eGhost, oPC, 1800.0);

    string sMsg = "Duch " + sDeceasedName + " pojawia się przy twoim boku i czuwa przez chwilę...";
    FloatingTextStringOnCreature(sMsg, oPC, FALSE);
    SendMessageToPC(oPC, "[Cmentarz] " + sMsg);
}
