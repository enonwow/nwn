#include "lib_nui"
#include "sql_carto"

void CartoOpen(object oPC);
void CartoSwapToList(object oPC, int nToken);
void CartoSwapToEdit(object oPC, int nToken);
void CartoFeedList(object oPC, int nToken);
void CartoFeedEdit(object oPC, int nToken);
void CartoHandleSave(object oPC, int nToken);
void CartoHandleSell(object oPC, int nToken);
void CartoHandleSellAll(object oPC, int nToken);
void CartoHandleDelete(object oPC, int nToken);
void CartoHandleTransfer(object oPC, int nToken);
void CartoOnPlayerTarget(object oPC);
void CartoApplyAreaBonus(object oPC);
void CartoRemoveAreaBonus(object oPC);

// ----------------------------------------------------------------
// Window / group IDs
// ----------------------------------------------------------------

const string CARTO_WIN          = "CARTO_WIN_MAIN";
const string CARTO_EV_SCRIPT    = "lib_carto_ev";
const string CARTO_GRP_SWAP     = "CARTO_GRP_SWAP";
const string CARTO_WIN_GEOM     = "carto_win_geom";

// ----------------------------------------------------------------
// List-view NuiList binds (parallel arrays)
// ----------------------------------------------------------------

const string CARTO_BIND_ROW_NAME    = "carto_row_name";
const string CARTO_BIND_ROW_DANGER  = "carto_row_danger";
const string CARTO_BIND_ROW_RES     = "carto_row_res";
const string CARTO_BIND_ROW_COLOR   = "carto_row_color";
const string CARTO_BIND_ROW_ENC     = "carto_row_enc";
const string CARTO_BIND_ROW_CNT     = "carto_row_cnt";

// ----------------------------------------------------------------
// Edit-view binds
// ----------------------------------------------------------------

const string CARTO_BIND_AREA_LBL    = "carto_area_lbl";
const string CARTO_BIND_D1_ENC      = "carto_d1_enc";
const string CARTO_BIND_D2_ENC      = "carto_d2_enc";
const string CARTO_BIND_D3_ENC      = "carto_d3_enc";
const string CARTO_BIND_D4_ENC      = "carto_d4_enc";
const string CARTO_BIND_D5_ENC      = "carto_d5_enc";
const string CARTO_BIND_CHK_HERBS   = "carto_chk_herbs";
const string CARTO_BIND_CHK_ORE     = "carto_chk_ore";
const string CARTO_BIND_CHK_WATER   = "carto_chk_water";
const string CARTO_BIND_CHK_RUINS   = "carto_chk_ruins";
const string CARTO_BIND_CHK_SHRINE  = "carto_chk_shrine";
const string CARTO_BIND_NOTES       = "carto_notes";
const string CARTO_BIND_SELL_ENA    = "carto_sell_ena";
const string CARTO_BIND_DEL_ENA     = "carto_del_ena";
const string CARTO_BIND_XFER_ENA    = "carto_xfer_ena";
const string CARTO_BIND_GOLD_LBL    = "carto_gold_lbl";
const string CARTO_BIND_STATUS      = "carto_status";

// ----------------------------------------------------------------
// Button IDs
// ----------------------------------------------------------------

const string CARTO_BTN_CLOSE        = "carto_btn_close";
const string CARTO_BTN_NEWMAP       = "carto_btn_newmap";
const string CARTO_BTN_SELLALL      = "carto_btn_sellall";
const string CARTO_BTN_ROW          = "carto_btn_row";
const string CARTO_BTN_D1           = "carto_btn_d1";
const string CARTO_BTN_D2           = "carto_btn_d2";
const string CARTO_BTN_D3           = "carto_btn_d3";
const string CARTO_BTN_D4           = "carto_btn_d4";
const string CARTO_BTN_D5           = "carto_btn_d5";
const string CARTO_BTN_SAVE         = "carto_btn_save";
const string CARTO_BTN_DEL         = "carto_btn_del";
const string CARTO_BTN_SELL         = "carto_btn_sell";
const string CARTO_BTN_XFER         = "carto_btn_xfer";
const string CARTO_BTN_BACK         = "carto_btn_back";

// ----------------------------------------------------------------
// Local variables on PC
// ----------------------------------------------------------------

const string CARTO_LVAR_EDIT_TAG    = "CARTO_EDIT_TAG";
const string CARTO_LVAR_DANGER      = "CARTO_EDIT_DANGER";
const string CARTO_LVAR_TARGETING   = "CARTO_TARGETING";
const string CARTO_LVAR_XFER_TAG    = "CARTO_XFER_TAG";
const string CARTO_LVAR_MAPS_CACHE  = "CARTO_MAPS_JSON";

// ----------------------------------------------------------------
// Dimensions
// ----------------------------------------------------------------

const float  CARTO_WIN_W            = 680.0;
const float  CARTO_WIN_H            = 500.0;

// ----------------------------------------------------------------
// Gold per danger level for selling
// ----------------------------------------------------------------

const int    CARTO_GOLD_D1          = 50;
const int    CARTO_GOLD_D2          = 120;
const int    CARTO_GOLD_D3          = 250;
const int    CARTO_GOLD_D4          = 400;
const int    CARTO_GOLD_D5          = 600;

// ----------------------------------------------------------------
// Limits
// ----------------------------------------------------------------

const int    CARTO_NOTES_MAX        = 300;
const int    CARTO_MAX_MAPS         = 50;

// ----------------------------------------------------------------
// Effect tag for the area-knowledge skill bonus
// ----------------------------------------------------------------

const string CARTO_EFFECT_TAG       = "CARTO_AREA_BONUS";
const int    CARTO_BONUS_AMOUNT     = 2;

// ----------------------------------------------------------------
// Helper: gold value for danger level
// ----------------------------------------------------------------

int CartoGoldForDanger(int nDanger)
{
    switch(nDanger)
    {
        case 1: return CARTO_GOLD_D1;
        case 2: return CARTO_GOLD_D2;
        case 3: return CARTO_GOLD_D3;
        case 4: return CARTO_GOLD_D4;
        case 5: return CARTO_GOLD_D5;
    }
    return CARTO_GOLD_D1;
}

// ----------------------------------------------------------------
// Helper: danger label string (skulls)
// ----------------------------------------------------------------

string CartoDangerLabel(int nDanger)
{
    switch(nDanger)
    {
        case 1: return "czaszka";
        case 2: return "czaszki";
        case 3: return "3 czaszki";
        case 4: return "4 czaszki";
        case 5: return "5 czaszek";
    }
    return "?";
}

// ----------------------------------------------------------------
// Helper: resource summary string
// ----------------------------------------------------------------

string CartoResourceSummary(int nHerbs, int nOre, int nWater, int nRuins, int nShrine)
{
    string s = "";
    if(nHerbs  ) s += "Z";
    if(nOre    ) s += "R";
    if(nWater  ) s += "W";
    if(nRuins  ) s += "U";
    if(nShrine ) s += "K";
    if(s == "") return "brak";
    return s;
}
