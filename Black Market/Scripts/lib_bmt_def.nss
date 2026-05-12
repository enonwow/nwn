#include "lib_nui"

// ----------------------------------------------------------------
// Configuration — defined before sql_bmt include so sql functions
// can reference these constants directly.
// ----------------------------------------------------------------

const int    BMT_REFRESH_SECS    = 21600;  // stock rotation period: 6 real hours
const int    BMT_STOCK_COUNT     = 8;      // items in rotating stock
const int    BMT_FENCE_RATE      = 40;     // percent of gold value paid when fencing
const int    BMT_HEAT_PER_BUY    = 6;      // heat gained per purchase
const int    BMT_HEAT_PER_SELL   = 4;      // heat gained per fenced item
const int    BMT_HEAT_MAX        = 100;
const int    BMT_HEAT_WARN       = 70;     // threshold for guard consequences
const int    BMT_HEAT_DECAY_HOUR = 2;      // heat lost per real hour offline/idle

// ----------------------------------------------------------------
// Layout
// ----------------------------------------------------------------

const float  BMT_W   = 580.0;
const float  BMT_H   = 500.0;

#include "sql_bmt"

// ----------------------------------------------------------------
// Window / group IDs
// ----------------------------------------------------------------

const string BMT_WINDOW     = "BMT_WINDOW";
const string BMT_EV_SCRIPT  = "lib_bmt_ev";
const string BMT_GRP_SWAP   = "BMT_GRP_SWAP";
const string BMT_WIN_GEOM   = "bmt_win_geom";

// ----------------------------------------------------------------
// Bind names — buy tab
// ----------------------------------------------------------------

const string BMT_BIND_ROW_NAME    = "bmt_row_name";
const string BMT_BIND_ROW_PRICE   = "bmt_row_price";
const string BMT_BIND_ROW_QTY     = "bmt_row_qty";
const string BMT_BIND_ROW_ENC     = "bmt_row_enc";
const string BMT_BIND_ROWCNT      = "bmt_rowcnt";
const string BMT_BIND_FLAVOR      = "bmt_flavor";
const string BMT_BIND_BUY_ENA     = "bmt_buy_ena";
const string BMT_BIND_BUY_LBL     = "bmt_buy_lbl";
const string BMT_BIND_REFRESH_LBL = "bmt_refresh_lbl";

// ----------------------------------------------------------------
// Bind names — sell tab
// ----------------------------------------------------------------

const string BMT_BIND_OFFER_LBL   = "bmt_offer_lbl";
const string BMT_BIND_SELL_ENA    = "bmt_sell_ena";

// ----------------------------------------------------------------
// Bind names — shared
// ----------------------------------------------------------------

const string BMT_BIND_HEAT_LBL    = "bmt_heat_lbl";
const string BMT_BIND_HEAT_COLOR  = "bmt_heat_color";

// ----------------------------------------------------------------
// Button IDs
// ----------------------------------------------------------------

const string BMT_BTN_CLOSE        = "bmt_btn_close";
const string BMT_BTN_ROW          = "bmt_btn_row";
const string BMT_BTN_BUY          = "bmt_btn_buy";
const string BMT_BTN_TAB_BUY      = "bmt_btn_tab_buy";
const string BMT_BTN_TAB_SELL     = "bmt_btn_tab_sell";
const string BMT_BTN_PICK_ITEM    = "bmt_btn_pick";
const string BMT_BTN_SELL_CONFIRM = "bmt_btn_sellcfm";

// ----------------------------------------------------------------
// Local variables stored on the PC object
// ----------------------------------------------------------------

const string BMT_LVAR_SEL_STOCK   = "BMT_SEL_STOCK";   // selected bmt_stock.id
const string BMT_LVAR_SEL_NAME    = "BMT_SEL_NAME";    // name of selected item
const string BMT_LVAR_SEL_PRICE   = "BMT_SEL_PRICE";   // gold cost of selected
const string BMT_LVAR_SELL_NAME   = "BMT_SELL_NAME";   // name of item being fenced
const string BMT_LVAR_SELL_PRICE  = "BMT_SELL_PRICE";  // gold offered by Passur
const string BMT_LVAR_SELL_SERIAL = "BMT_SELL_SERIAL"; // JsonDump of serialized item
const string BMT_LVAR_MODE        = "BMT_MODE";        // 0 = buy, 1 = sell

// ----------------------------------------------------------------
// Forward declarations
// ----------------------------------------------------------------

void BmtShowWindow(object oPC);
void BmtFeedBuyTab(object oPC, int nToken);
void BmtFeedSellTab(object oPC, int nToken);
void BmtHandleTarget(object oPC);
