#include "lib_nui"
#include "sql_dur"

void DurCreateWindow(object oPC);
void DurFeedWindow(object oPC, int nToken);
void DurFeedDetail(object oPC, int nToken, int nSlotIdx);
void DurRecalcPenalties(object oPC);
void DurDecayCombatPC(object oPC);
void DurCheckAllSlots(object oPC);
void DurDoRepair(object oPC, int nToken, int nSlotIdx, int bField);
void DurDoRepairAll(object oPC, int nToken);

// ----------------------------------------------------------------
// Window / event IDs
// ----------------------------------------------------------------

const string DUR_WINDOW    = "DUR_WINDOW";
const string DUR_EV_SCRIPT = "lib_dur_ev";
const string DUR_WIN_GEOM  = "dur_win_geom";

// ----------------------------------------------------------------
// NuiList array binds (one value per row in the slot list)
// ----------------------------------------------------------------

const string DUR_BIND_SLOT_NAME   = "dur_slot_name";   // string  — slot label
const string DUR_BIND_ITEM_NAME   = "dur_item_name";   // string  — item name or "(brak)"
const string DUR_BIND_SLOT_PCT    = "dur_slot_pct";    // float   — 0.0–1.0 for progress bar
const string DUR_BIND_BAR_COLOR   = "dur_bar_col";     // NuiColor
const string DUR_BIND_SLOT_STATUS = "dur_slot_stat";   // string  — "Dobry" / "Zużyty" etc.
const string DUR_BIND_STAT_COLOR  = "dur_stat_col";    // NuiColor
const string DUR_BIND_ROW_ENC     = "dur_row_enc";     // bool    — currently selected row
const string DUR_BIND_ROWCOUNT    = "dur_rowcount";    // int     — number of rows

// ----------------------------------------------------------------
// Detail panel binds (scalar, updated on row select)
// ----------------------------------------------------------------

const string DUR_BIND_DETAIL_NAME = "dur_detail_name"; // string  — "Naprawiasz: <name>"
const string DUR_BIND_DETAIL_INFO = "dur_detail_info"; // string  — cost text block
const string DUR_BIND_REPAIR_ENA  = "dur_repair_ena";  // bool    — forge repair available
const string DUR_BIND_FIELD_ENA   = "dur_field_ena";   // bool    — field repair available
const string DUR_BIND_REPALL_ENA  = "dur_repall_ena";  // bool    — repair-all available
const string DUR_BIND_STATUS_MSG  = "dur_status_msg";  // string  — feedback line

// ----------------------------------------------------------------
// Button IDs
// ----------------------------------------------------------------

const string DUR_BTN_ROW    = "dur_btn_row";
const string DUR_BTN_REPAIR = "dur_btn_repair";
const string DUR_BTN_FIELD  = "dur_btn_field";
const string DUR_BTN_REPALL = "dur_btn_repall";
const string DUR_BTN_CLOSE  = "dur_btn_close";

// ----------------------------------------------------------------
// PC local vars
// ----------------------------------------------------------------

const string DUR_LVAR_SEL    = "DUR_SEL_SLOT";   // int — selected slot index (0..DUR_SLOT_COUNT-1)
const string DUR_LVAR_FORGE  = "DUR_AT_FORGE";   // int 1 if opened at a forge placeable

// ----------------------------------------------------------------
// Layout
// ----------------------------------------------------------------

const float DUR_W = 660.0;
const float DUR_H = 510.0;

// ----------------------------------------------------------------
// Tracked inventory slots (indices 0–6)
// ----------------------------------------------------------------

const int DUR_SLOT_COUNT = 7;

// ----------------------------------------------------------------
// Durability thresholds & penalties
// ----------------------------------------------------------------

const int DUR_THR_WORN    = 75;   // 75–100: no penalty
const int DUR_THR_DAMAGED = 50;   // 50–74: -1 to attack / AC
const int DUR_THR_BROKEN  = 25;   // 25–49: -2 to attack / AC
                                   //  1–24: -4 to attack / AC
                                   //     0: -6 to attack / AC (destroyed)

// Gold cost per missing durability point for forge repair
const int DUR_GOLD_PER_POINT    = 8;
// Field repair: 3× the forge cost, no forge needed
const int DUR_FIELD_REPAIR_MULT = 3;
// Field repair kit item tag (module author assigns to any item)
const string DUR_TAG_KIT        = "dur_repair_kit";

// ----------------------------------------------------------------
// Slot mapping helpers
// ----------------------------------------------------------------

int DurGetInventorySlot(int nIdx)
{
    switch(nIdx)
    {
        case 0: return INVENTORY_SLOT_RIGHTHAND;
        case 1: return INVENTORY_SLOT_LEFTHAND;
        case 2: return INVENTORY_SLOT_CHEST;
        case 3: return INVENTORY_SLOT_HEAD;
        case 4: return INVENTORY_SLOT_BOOTS;
        case 5: return INVENTORY_SLOT_ARMS;
        case 6: return INVENTORY_SLOT_CLOAK;
    }
    return INVENTORY_SLOT_RIGHTHAND;
}

string DurGetSlotLabel(int nIdx)
{
    switch(nIdx)
    {
        case 0: return "Broń Główna";
        case 1: return "Lewa Ręka";
        case 2: return "Zbroja";
        case 3: return "Hełm";
        case 4: return "Buty";
        case 5: return "Rękawice";
        case 6: return "Peleryna";
    }
    return "Nieznany";
}

int DurGetPenalty(int nDurability)
{
    if(nDurability >= DUR_THR_WORN)    return 0;
    if(nDurability >= DUR_THR_DAMAGED) return 1;
    if(nDurability >= DUR_THR_BROKEN)  return 2;
    if(nDurability > 0)                return 4;
    return 6;
}

string DurGetStatusText(int nDurability)
{
    if(nDurability >= DUR_THR_WORN)    return "Dobry";
    if(nDurability >= DUR_THR_DAMAGED) return "Zużyty";
    if(nDurability >= DUR_THR_BROKEN)  return "Uszkodzony";
    if(nDurability > 0)                return "Złamany";
    return "Zniszczony";
}

json DurGetStatusColor(int nDurability)
{
    if(nDurability >= DUR_THR_WORN)    return NuiColor( 80, 200,  80);
    if(nDurability >= DUR_THR_DAMAGED) return NuiColor(220, 200,  60);
    if(nDurability >= DUR_THR_BROKEN)  return NuiColor(220, 120,  40);
    return NuiColor(200, 40, 40);
}

// Returns TRUE if the item in this slot contributes to attack penalty
int DurIsWeaponSlot(int nIdx, object oItem)
{
    if(nIdx == 0) return TRUE;
    if(nIdx == 1)
    {
        int nBase = GetBaseItemType(oItem);
        if(nBase == BASE_ITEM_SMALLSHIELD ||
           nBase == BASE_ITEM_LARGESHIELD ||
           nBase == BASE_ITEM_TOWERSHIELD)
            return FALSE;
        return TRUE;
    }
    return FALSE;
}

// Returns TRUE if this slot contributes to AC penalty (armor / shield)
int DurIsArmorSlot(int nIdx, object oItem)
{
    if(nIdx == 2) return TRUE;
    if(nIdx == 1)
    {
        int nBase = GetBaseItemType(oItem);
        if(nBase == BASE_ITEM_SMALLSHIELD ||
           nBase == BASE_ITEM_LARGESHIELD ||
           nBase == BASE_ITEM_TOWERSHIELD)
            return TRUE;
    }
    return FALSE;
}

// Gold repair cost for nMissing durability points
int DurRepairCost(int nMissing, int bField)
{
    int nBase = nMissing * DUR_GOLD_PER_POINT;
    return bField ? nBase * DUR_FIELD_REPAIR_MULT : nBase;
}
