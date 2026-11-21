#include "lib_nui"
#include "sql_pact"

void CreatePactWindow(object oPC);
void PactCheckAndApply(object oPC);
void PactApplyEffects(object oPC, string sDemonId);
void PactRemoveEffects(object oPC);
void PactCollectToll(object oPC);

// ---- Window / UI identifiers ----
const string PACT_WINDOW    = "PACT_WINDOW";
const string PACT_EV_SCRIPT = "lib_pact_ev";
const string PACT_WIN_GEOM  = "pact_win_geom";

// ---- NUI bind names ----
const string PACT_BIND_LIST_NAME    = "pact_list_name";
const string PACT_BIND_LIST_ENC     = "pact_list_enc";
const string PACT_BIND_LIST_CNT     = "pact_list_cnt";
const string PACT_BIND_DETAIL_NAME  = "pact_det_name";
const string PACT_BIND_DETAIL_LORE  = "pact_det_lore";
const string PACT_BIND_DETAIL_BUFF  = "pact_det_buff";
const string PACT_BIND_DETAIL_TOLL  = "pact_det_toll";
const string PACT_BIND_SIGN_LBL     = "pact_sign_lbl";
const string PACT_BIND_SIGN_ENA     = "pact_sign_ena";
const string PACT_BIND_STATUS_LBL   = "pact_status_lbl";
const string PACT_BIND_BREAK_LBL    = "pact_break_lbl";
const string PACT_BIND_BREAK_ENA    = "pact_break_ena";

// ---- Button IDs ----
const string PACT_BTN_CLOSE = "pact_btn_close";
const string PACT_BTN_ROW   = "pact_btn_row";
const string PACT_BTN_SIGN  = "pact_btn_sign";
const string PACT_BTN_BREAK = "pact_btn_break";

// ---- Local variables on PC ----
const string PACT_LVAR_SEL = "PACT_SEL";    // currently highlighted demon ID in UI

// ---- Demon IDs ----
const string PACT_DEMON_ORCUS   = "ORCUS";
const string PACT_DEMON_BAEL    = "BAEL";
const string PACT_DEMON_GLASYA  = "GLASYA";
const string PACT_DEMON_JUIBLEX = "JUIBLEX";

// All pact effects carry this tag prefix so they can be stripped as a group.
const string PACT_EFFECT_PREFIX = "PACT_";

// ---- Config ----
const int   PACT_DEMON_COUNT      = 4;
const int   PACT_TOLL_INTERVAL    = 7200;   // seconds between tolls (2 real hours)
const int   PACT_BREAK_HP_COST    = 20;     // HP damage when voluntarily breaking a pact
const int   PACT_BREAK_CURSE_SECS = 1800;   // duration of the break-penalty curse (30 min)

// ---- Window dimensions ----
const float PACT_W = 680.0;
const float PACT_H = 450.0;

// ---- Demon data accessors ----

string PactGetDemonId(int nIdx)
{
    if(nIdx == 0) return PACT_DEMON_ORCUS;
    if(nIdx == 1) return PACT_DEMON_BAEL;
    if(nIdx == 2) return PACT_DEMON_GLASYA;
    return PACT_DEMON_JUIBLEX;
}

string PactGetDemonName(string sId)
{
    if(sId == PACT_DEMON_ORCUS)   return "Pakt Agonii — Orcus";
    if(sId == PACT_DEMON_BAEL)    return "Pakt Zelaza — Bael";
    if(sId == PACT_DEMON_GLASYA)  return "Pakt Cienia — Glasya";
    if(sId == PACT_DEMON_JUIBLEX) return "Pakt Odmetu — Juiblex";
    return "—";
}

string PactGetDemonBuff(string sId)
{
    if(sId == PACT_DEMON_ORCUS)   return "Premia: Regeneracja 2 PZ/runde (nadprzyrodzona)";
    if(sId == PACT_DEMON_BAEL)    return "Premia: +4 do Sily (nadprzyrodzony)";
    if(sId == PACT_DEMON_GLASYA)  return "Premia: +6 do Skradania i Ukrywania sie";
    if(sId == PACT_DEMON_JUIBLEX) return "Premia: +5 do AC naturalnego";
    return "";
}

string PactGetDemonToll(string sId)
{
    if(sId == PACT_DEMON_ORCUS)   return "Haracz (co 2h): 12 obrazen negatywnych";
    if(sId == PACT_DEMON_BAEL)    return "Haracz (co 2h): 8 obrazen + 50 doswiadczenia";
    if(sId == PACT_DEMON_GLASYA)  return "Haracz (co 2h): 60 doswiadczenia";
    if(sId == PACT_DEMON_JUIBLEX) return "Haracz (co 2h): 10 obrazen kwasem + losowa klatwa";
    return "";
}

string PactGetDemonLore(string sId)
{
    if(sId == PACT_DEMON_ORCUS)
        return "Orcus, Niosacy Laske Czaszki, daruje nieumarla witalnosc tym,\n"
             + "ktorzy podpisza sie wlasna krwia. Krew powraca — lecz\n"
             + "z kazdym haraczem niesie ze soba coraz wiecej mroku.";
    if(sId == PACT_DEMON_BAEL)
        return "Bael, Wielki Krol Piekiel, kuje sile z cudzej slabosci.\n"
             + "Jego zelazna dlon zaciska sie na ramieniu sygnatariusza\n"
             + "z kazdym pobranym haraczem — cicho, nieublaganie.";
    if(sId == PACT_DEMON_GLASYA)
        return "Glasya, Corka Asmodeia, handluje cieniem i zapomnieniem.\n"
             + "Ci, ktorzy pisza jej imie we wlasnej krwi, znikaja ze\n"
             + "swiata — ona zas zachowuje kazde wspomnienie dla siebie.";
    if(sId == PACT_DEMON_JUIBLEX)
        return "Juiblex, Bezksztaltny, nie posiada formy ani litosci.\n"
             + "Jego bloto z Otchlani opancerza cialo, lecz z kazdym\n"
             + "haraczem rozpuszcza kolejny fragment jazni sygnatariusza.";
    return "";
}
