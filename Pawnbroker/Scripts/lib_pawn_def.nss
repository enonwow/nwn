#include "lib_nui"
#include "sql_pawn"

void CreatePawnWindow(object oPC);
void SwapToBrowseView(object oPC, int nToken);
void SwapToPawnView(object oPC, int nToken);
void FeedBrowseList(object oPC, int nToken);
void FeedBrowseDetail(object oPC, int nToken, int nId);
void FeedPawnSlots(object oPC, int nToken);
void FeedPawnOffer(object oPC, int nToken);
void PawnOnPlayerTarget(object oPC);

// ----------------------------------------------------------------
// Window / event identifiers
// ----------------------------------------------------------------

const string PAWN_WINDOW      = "PAWN_WINDOW";
const string PAWN_EV_SCRIPT   = "lib_pawn_ev";
const string PAWN_GRP_SWAP    = "PAWN_GRP_SWAP";
const string PAWN_WIN_GEOM    = "pawn_win_geom";

// ----------------------------------------------------------------
// Browse-view binds
// ----------------------------------------------------------------

const string PAWN_BIND_ROW_NAME     = "pawn_row_name";
const string PAWN_BIND_ROW_STATUS   = "pawn_row_status";
const string PAWN_BIND_ROW_DAYS     = "pawn_row_days";
const string PAWN_BIND_ROW_COST     = "pawn_row_cost";
const string PAWN_BIND_ROW_ENC      = "pawn_row_enc";
const string PAWN_BIND_ROW_COLOR    = "pawn_row_color";
const string PAWN_BIND_ROW_COST_CLR = "pawn_row_cclr";

const string PAWN_BIND_DET_NAME     = "pawn_det_name";
const string PAWN_BIND_DET_INFO     = "pawn_det_info";
const string PAWN_BIND_REDEEM_ENA   = "pawn_redeem_ena";
const string PAWN_BIND_REDEEM_LBL   = "pawn_redeem_lbl";
const string PAWN_BIND_FLAVOR       = "pawn_flavor";

// ----------------------------------------------------------------
// Pawn-view binds
// ----------------------------------------------------------------

const string PAWN_BIND_SLOT_IMG     = "pawn_slot_img";   // + IntToString(i)
const string PAWN_BIND_SLOT_TIP     = "pawn_slot_tip";   // + IntToString(i)
const string PAWN_BIND_OFFER_LBL    = "pawn_offer_lbl";
const string PAWN_BIND_CONFIRM_ENA  = "pawn_confirm_ena";
const string PAWN_BIND_PAWN_FLAVOR  = "pawn_p_flavor";

// ----------------------------------------------------------------
// Buttons
// ----------------------------------------------------------------

const string PAWN_BTN_CLOSE       = "pawn_btn_close";
const string PAWN_BTN_TO_PAWN     = "pawn_btn_to_pawn";
const string PAWN_BTN_BACK        = "pawn_btn_back";
const string PAWN_BTN_ROW         = "pawn_btn_row";
const string PAWN_BTN_REDEEM      = "pawn_btn_redeem";
const string PAWN_BTN_SLOT        = "pawn_btn_slot";     // + IntToString(i)
const string PAWN_BTN_CONFIRM     = "pawn_btn_confirm";

// ----------------------------------------------------------------
// Local variables on PC
// ----------------------------------------------------------------

const string PAWN_LVAR_SEL_ID     = "PAWN_SEL_ID";
const string PAWN_LVAR_SLOTS      = "PAWN_SLOTS";        // JsonArray of slot objects
const string PAWN_LVAR_TARGET_IDX = "PAWN_TARGET_IDX";   // which slot we are filling

// ----------------------------------------------------------------
// Slot count & value ratio
// ----------------------------------------------------------------

const int   PAWN_SLOT_COUNT    = 5;
const float PAWN_VALUE_RATIO   = 0.25;   // pawnbroker pays 25% of GPV

// ----------------------------------------------------------------
// Window dimensions
// ----------------------------------------------------------------

const float PAWN_W = 680.0;
const float PAWN_H = 460.0;

// ----------------------------------------------------------------
// Flavor texts (Polish, dark fantasy)
// ----------------------------------------------------------------

const string PAWN_FLAVOR_GREET   = "Zastawnik mierzy cię zimnym spojrzeniem. Wszystko ma swoją cenę — pytanie, czy jesteś gotów ją zapłacić.";
const string PAWN_FLAVOR_EXPIRED = "Termin minął. Moje, z prawa. Ale... za odpowiednią nadpłatę mogę o tym zapomnieć.";
const string PAWN_FLAVOR_EMPTY   = "Żadnych zastawów. Przyjdź, gdy bieda zagoni cię w kąt — a zawsze to zrobi.";
const string PAWN_FLAVOR_PAWN    = "Co chcesz zastawić? Przyjmuję broń, zbroję, klejnoty. Żywych stworzeń nie.";
const string PAWN_FLAVOR_CONFIRM = "Dobry interes. Pamiętaj: siedem dni, potem to moje — a odsetki nie śpią.";
const string PAWN_FLAVOR_REDEEMED = "Twoje. Ale następnym razem nie zwlekaj tak długo.";
