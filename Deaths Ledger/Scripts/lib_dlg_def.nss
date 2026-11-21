#include "lib_nui"
#include "sql_dlg"

void DlgOpenLedger(object oPC);
void DlgApplyDebtEffects(object oPC);
void DlgRemoveDebtEffects(object oPC);
void DlgFeedLedger(object oPC, int nToken);
void DlgFeedAltarView(object oPC, int nToken);

// ----------------------------------------------------------------
// Window IDs
// ----------------------------------------------------------------

const string DLG_WIN_BARGAIN    = "DLG_WIN_BARGAIN";
const string DLG_WIN_LEDGER     = "DLG_WIN_LEDGER";
const string DLG_EV_SCRIPT      = "lib_dlg_ev";

// ----------------------------------------------------------------
// Binds — bargain window
// ----------------------------------------------------------------

const string DLG_BIND_BARG_FLAVOR   = "dlg_barg_flavor";
const string DLG_BIND_BARG_DEBT_LBL = "dlg_barg_debt_lbl";
const string DLG_BIND_BARG_WARN     = "dlg_barg_warn";

// ----------------------------------------------------------------
// Binds — ledger window
// ----------------------------------------------------------------

const string DLG_BIND_LED_DEBT_LBL  = "dlg_led_debt";
const string DLG_BIND_LED_EFFECTS   = "dlg_led_fx";
const string DLG_BIND_LED_GOLD_COST = "dlg_led_gp_cost";
const string DLG_BIND_LED_HP_COST   = "dlg_led_hp_cost";
const string DLG_BIND_LED_PEN_LBL   = "dlg_led_pen_lbl";
const string DLG_BIND_LED_PEN_ENA   = "dlg_led_pen_ena";
const string DLG_BIND_LED_PAY_ENA   = "dlg_led_pay_ena";
const string DLG_BIND_LED_HP_ENA    = "dlg_led_hp_ena";
const string DLG_BIND_LED_TITLE     = "dlg_led_title";
const string DLG_BIND_GEOM_LED      = "dlg_geom_led";
const string DLG_BIND_GEOM_BARG     = "dlg_geom_barg";

// ----------------------------------------------------------------
// Buttons
// ----------------------------------------------------------------

const string DLG_BTN_BARGAIN_ACCEPT = "dlg_btn_accept";
const string DLG_BTN_BARGAIN_REFUSE = "dlg_btn_refuse";
const string DLG_BTN_CLOSE          = "dlg_btn_close";
const string DLG_BTN_PAY_GOLD       = "dlg_btn_pay_gold";
const string DLG_BTN_PAY_HP         = "dlg_btn_pay_hp";
const string DLG_BTN_PENANCE        = "dlg_btn_penance";

// ----------------------------------------------------------------
// Local vars on PC
// ----------------------------------------------------------------

const string DLG_LVAR_DYING         = "DLG_DYING";     // 1 while bargain popup is open

// ----------------------------------------------------------------
// Layout
// ----------------------------------------------------------------

const float DLG_W_BARG  = 480.0;
const float DLG_H_BARG  = 360.0;
const float DLG_W_LED   = 540.0;
const float DLG_H_LED   = 480.0;

// ----------------------------------------------------------------
// Game constants
// ----------------------------------------------------------------

const int   DLG_GOLD_PER_DEBT   = 500;
const int   DLG_HP_PCT_PER_DEBT = 10;
const int   DLG_EMISSARY_HOURS  = 20;   // real-time hours between emissary spawns
const int   DLG_PENANCE_DAYS    = 7;    // real-time days for a penance quest
const string DLG_EMISSARY_RESREF_1 = "nw_shskel001";   // Skeletal Warrior (debt 3–4)
const string DLG_EMISSARY_RESREF_2 = "nw_shshad001";   // Shadow (debt 5–7)
const string DLG_EMISSARY_RESREF_3 = "nw_shwight001";  // Wight (debt 8–10)
const string DLG_EMISSARY_TAG      = "DLG_EMISSARY";

// ----------------------------------------------------------------
// Debt-level descriptions (Polish player-facing)
// ----------------------------------------------------------------

string DlgDebtLabel(int nDebt)
{
    if(nDebt <= 0)  return "Dług: czysty";
    if(nDebt == 1)  return "Dług: I — Dotknięcie Śmierci";
    if(nDebt == 2)  return "Dług: II — Piętno Umarłych";
    if(nDebt == 3)  return "Dług: III — Posłaniec Śmierci";
    if(nDebt == 4)  return "Dług: IV — Gnijące Ciało";
    if(nDebt == 5)  return "Dług: V — Cień Przeznaczenia";
    if(nDebt == 6)  return "Dług: VI — Zepsute Kości";
    if(nDebt == 7)  return "Dług: VII — Wyjęty spod Życia";
    if(nDebt == 8)  return "Dług: VIII — Własność Śmierci";
    if(nDebt == 9)  return "Dług: IX — Ostatnie Tchnienie";
    return                  "Dług: X — Skazany";
}

string DlgEffectDesc(int nDebt)
{
    if(nDebt <= 0)
        return "Brak kar — dusza czysta jak łza noworodka.";

    string s = "";
    int nSavePen  = (nDebt >= 7) ? -3 : (nDebt >= 4) ? -2 : -1;
    int nNegPen   = (nDebt >= 8) ? -4 : (nDebt >= 5) ? -3 : (nDebt >= 2) ? -2 : 0;
    int nStrPen   = (nDebt >= 9) ? -5 : (nDebt >= 6) ? -4 : (nDebt >= 4) ? -3 : (nDebt >= 3) ? -2 : 0;

    s += "• Rzuty obronne vs śmierć: " + IntToString(nSavePen) + "\n";
    if(nNegPen < 0)
        s += "• Rzuty obronne vs neg. energię: " + IntToString(nNegPen) + "\n";
    if(nStrPen < 0)
        s += "• Siła: " + IntToString(nStrPen) + "\n";
    if(nDebt >= 3)
        s += "• Posłaniec Śmierci śledzi cię co dobę.\n";
    if(nDebt >= 5)
        s += "• Aura śmierci — wrogowie dostrzegają piętno.\n";
    if(nDebt >= 8)
        s += "• Blisko końca — Śmierć może się pojawić osobiście.\n";
    return s;
}

string DlgBargainFlavor(int nDebt)
{
    if(nDebt == 0)
        return "«Twój czas nie nadszedł. Jeszcze. Mogę zabrać cię teraz... "
             + "lub dać ci jeszcze chwilę. Lecz każda chwila ma cenę.»\n\n"
             + "Pieczęć krwi pulsuje słabo w powietrzu.";
    if(nDebt <= 2)
        return "«Znowu tu jesteś. Byłem cierpliwy. Moje piętno już na tobie — "
             + "czujesz je w kościach o świcie? Przyjmij kolejny oddech... "
             + "jeśli nie boisz się kosztów.»\n\n"
             + "Pieczęć pulsuje mocniej. Wokół unosi się zapach starego żelaza.";
    if(nDebt <= 5)
        return "«Ach. Kolejny raz. Mój Posłaniec już idzie twoim śladem. "
             + "Mogę wskrzesić cię ponownie — ale wiedz: długi się kumulują. "
             + "Kiedyś sam po ciebie przyjdę.»\n\n"
             + "Ciemność wokół mruga. Czujesz jak coś ciągnie za duszę.";
    return "«Jesteś prawie moim. Jeszcze jeden krok i to koniec. "
         + "Ale lubię się bawić. Chcesz kolejną szansę? Zapłać cenę.»\n\n"
         + "Rzeczywistość drżi. Pieczęć krwi płonie zimnym ogniem.";
}
