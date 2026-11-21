#include "lib_nui"

// ----------------------------------------------------------------
// Window / script identifiers
// ----------------------------------------------------------------

const string TAROT_WINDOW       = "TAROT_WINDOW";
const string TAROT_EV_SCRIPT    = "lib_tarot_ev";
const string TAROT_WIN_GEOM     = "tarot_win_geom";
const string TAROT_GRP_DETAIL   = "tarot_grp_detail";

// ----------------------------------------------------------------
// NUI bind names  (prefix TAROT_)
// ----------------------------------------------------------------

const string TAROT_BIND_DECK_LBL    = "tarot_deck_lbl";
const string TAROT_BIND_DRAW_ENA    = "tarot_draw_ena";
const string TAROT_BIND_DRAW_LBL    = "tarot_draw_lbl";
const string TAROT_BIND_RESET_ENA   = "tarot_reset_ena";

// Per-card (append IntToString(i)):
const string TAROT_BIND_CARD_IMG    = "tarot_cimg_";
const string TAROT_BIND_CARD_ENC    = "tarot_cenc_";
const string TAROT_BIND_CARD_TIP    = "tarot_ctip_";

// Detail panel
const string TAROT_BIND_DET_NAME    = "tarot_det_name";
const string TAROT_BIND_DET_FLV     = "tarot_det_flv";
const string TAROT_BIND_DET_EFF     = "tarot_det_eff";
const string TAROT_BIND_DET_OBL     = "tarot_det_obl";
const string TAROT_BIND_DET_IMG     = "tarot_det_img";
const string TAROT_BIND_DET_DRAWN   = "tarot_det_drawn";

// ----------------------------------------------------------------
// Buttons
// ----------------------------------------------------------------

const string TAROT_BTN_CLOSE        = "tarot_btn_close";
const string TAROT_BTN_CARD         = "tarot_btn_card_";  // + IntToString(i)
const string TAROT_BTN_DRAW         = "tarot_btn_draw";
const string TAROT_BTN_RESET        = "tarot_btn_reset";

// ----------------------------------------------------------------
// Local variables on PC
// ----------------------------------------------------------------

const string TAROT_LVAR_SEL_CARD    = "TAROT_SEL_CARD";  // -1 = nothing selected

// ----------------------------------------------------------------
// Effect removal tag
// ----------------------------------------------------------------

const string TAROT_EFFECT_TAG       = "TAROT_EFF_";  // + IntToString(cardId)

// ----------------------------------------------------------------
// Deck size
// ----------------------------------------------------------------

const int    TAROT_CARD_COUNT       = 22;

// ----------------------------------------------------------------
// Layout
// ----------------------------------------------------------------

const float  TAROT_W                = 700.0;
const float  TAROT_H                = 560.0;
const float  TAROT_CARD_SZ          = 62.0;   // card button size

// ----------------------------------------------------------------
// Card icons  (resrefs; add tarot_card_00..21, tarot_card_back to HAK)
// ----------------------------------------------------------------

string TarotCardIcon(int nId)
{
    string s = IntToString(nId);
    if(nId < 10) s = "0" + s;
    return "tarot_card_" + s;
}

string TarotCardBackIcon()
{
    return "tarot_card_back";
}

// ----------------------------------------------------------------
// Card names
// ----------------------------------------------------------------

string TarotCardName(int nId)
{
    switch(nId)
    {
        case 0:  return "Nieczysta Moc";
        case 1:  return "Czarna Brama";
        case 2:  return "Pieczęć Pychy";
        case 3:  return "Łańcuch Duszy";
        case 4:  return "Oko Tyranii";
        case 5:  return "Cień Szepty";
        case 6:  return "Klucz Otchłani";
        case 7:  return "Krew Ofiary";
        case 8:  return "Znak Chaosu";
        case 9:  return "Piasek Zapomnienia";
        case 10: return "Miecz Zemsty";
        case 11: return "Wierność Piekłom";
        case 12: return "Taniec Śmierci";
        case 13: return "Lustro Potępienia";
        case 14: return "Pakt Nicości";
        case 15: return "Głód Mroków";
        case 16: return "Trzecia Twarz";
        case 17: return "Spalona Chwała";
        case 18: return "Wieczne Czuwanie";
        case 19: return "Waga Grzechu";
        case 20: return "Maska Kłamcy";
        case 21: return "Koniec Ery";
    }
    return "???";
}

// ----------------------------------------------------------------
// Flavor text (visible to player)
// ----------------------------------------------------------------

string TarotCardFlavor(int nId)
{
    switch(nId)
    {
        case 0:  return "\"Krew pulsuje ciemniej. Coś z otchłani usłyszało twoje wołanie.\"";
        case 1:  return "\"Między światami jest luka. Ktoś otworzył drzwi od tamtej strony.\"";
        case 2:  return "\"Pycha nosi twarz aniołów. To właśnie czyni ją tak niebezpieczną.\"";
        case 3:  return "\"Łańcuch nie boli — dopóki nie próbujesz odejść.\"";
        case 4:  return "\"Jedno oko patrzy na świat. Drugie patrzy na ciebie.\"";
        case 5:  return "\"Szepty w cieniu istniały zawsze. Teraz słyszysz słowa.\"";
        case 6:  return "\"Każdy zamek to obietnica. Ten klucz dotrzymuje jej w obie strony.\"";
        case 7:  return "\"Czerwień ma swój smak. Ci, którzy wiedzą, nie mogą zapomnieć.\"";
        case 8:  return "\"Chaos nie niszczy — przekształca. Różnica jest subtelna, gdy płoniesz.\"";
        case 9:  return "\"Zapomnienie jest łaską. I przekleństwem. Często jednocześnie.\"";
        case 10: return "\"Zemsta jest zimna. Ci, którzy to mówią, nigdy jej nie smakali.\"";
        case 11: return "\"Piekło ma swoich wiernych. Nie zawsze wiedzą, czemu służą.\"";
        case 12: return "\"Taniec na grobach. Kroki znasz w kościach — bo zawsze tam były.\"";
        case 13: return "\"Lustro kłamie. Aż do dnia, gdy mówi prawdę — wtedy jest już za późno.\"";
        case 14: return "\"Nic za coś. Wieczna transakcja, której warunki czytasz dopiero po podpisaniu.\"";
        case 15: return "\"W ciemności nie ma cieni. Ona sama jest wszystkim.\"";
        case 16: return "\"Trzy twarze: ta którą nosisz, ta którą pokazujesz, ta której się boisz.\"";
        case 17: return "\"Chwała pali. Ci, którzy przeżyli, noszą jej ślady na zawsze.\"";
        case 18: return "\"Sen jest małą śmiercią. Ten, kto nie śpi, nie umiera po trochu.\"";
        case 19: return "\"Grzechy mają wagę. Skala nigdy się nie myli — tylko ty kłamiesz.\"";
        case 20: return "\"Kłamstwo ma nogi. Prawda leży w rowie na poboczu drogi.\"";
        case 21: return "\"Wszystko ma swój koniec. Pytanie brzmi: czy to twój?\"";
    }
    return "";
}

// ----------------------------------------------------------------
// Effect description (what the card actually does)
// ----------------------------------------------------------------

string TarotCardEffect(int nId)
{
    switch(nId)
    {
        case 0:  return "Siła +2.";
        case 1:  return "Zręczność +2. Prędkość poruszania +20%.";
        case 2:  return "Wszystkie rzuty obronne +2.";
        case 3:  return "Kondycja +2. Dyscyplina +6.";
        case 4:  return "Zastraszanie +10. Przekonywanie -4.";
        case 5:  return "Dostrzeganie +6. Słuchanie +6.";
        case 6:  return "Otwieranie zamków +8. Rozbrajanie pułapek +4.";
        case 7:  return "Regeneracja 1 HP/rundę. Kondycja -2.";
        case 8:  return "Inteligencja +2. Mądrość +2.";
        case 9:  return "Rzut woli vs. czary umysłu +8.";
        case 10: return "Premia do ataku +2. Klasa pancerza -1.";
        case 11: return "Rzuty obronne vs. czary +3.";
        case 12: return "Premia do ataku +2. Zręczność +2.";
        case 13: return "Dostrzeganie +6. Szukanie +6. Widzenie niewidzialnego.";
        case 14: return "Rzuty obronne vs. czary +4. Mądrość -2.";
        case 15: return "Widzenie w ciemności. Klasa pancerza -1.";
        case 16: return "Blefowanie +12. Przekonywanie +6.";
        case 17: return "Odporność na ogień 15%. Kondycja -1.";
        case 18: return "Rzut woli +6. Odporność na magię snu i ogłuszenie +4.";
        case 19: return "Charyzma +2. Przekonywanie +8.";
        case 20: return "Blefowanie +15. Przekonywanie +6.";
        case 21: return "Wszystkie atrybuty +1 (Siła, Zręczność, Kondycja, Inteligencja, Mądrość, Charyzma).";
    }
    return "";
}

// ----------------------------------------------------------------
// Obligation / curse text
// ----------------------------------------------------------------

string TarotCardObligation(int nId)
{
    switch(nId)
    {
        case 0:  return "Klątwa: Demony wyczuwają twoją moc — są na ciebie bardziej wyczulone.";
        case 1:  return "Klątwa: Raz na jakiś czas brama otwiera się sama — duchy wchodzą.";
        case 2:  return "Klątwa: Pycha czyni cię trudnym w rozmowie — -4 do Przekonywania.";
        case 3:  return "Klątwa: Kapłani i druidzi wyczuwają, że coś w tobie jest uwiązane.";
        case 4:  return "Klątwa: Tyrania odpycha sojuszników — -4 do Przekonywania.";
        case 5:  return "Klątwa: Słyszysz więcej niż chcesz — szepty potrafią rozpraszać.";
        case 6:  return "Klątwa: Twoje własne zamki mogą się otwierać niespodziewanie.";
        case 7:  return "Kara: Kondycja -2 (trwale wpływa na max HP i rzuty obronne).";
        case 8:  return "Klątwa: Chaos przenika twoje myśli — koncentracja jest trudniejsza.";
        case 9:  return "Klątwa: Rzut woli wymagany by zapamiętać ważne szczegóły rozmów.";
        case 10: return "Kara: Klasa pancerza -1 (agresywna postawa osłabia obronę).";
        case 11: return "Klątwa: Piekielna aura — kapłani Dobra reagują na ciebie nieprzychylnie.";
        case 12: return "Klątwa: Bitewny trans — trudno kontrolować siłę ataku w ferworze walki.";
        case 13: return "Klątwa: Lustro odbija twój wewnętrzny mrok — NPCe mogą to wyczuć.";
        case 14: return "Kara: Mądrość -2 (cena za dostęp do wiedzy, której nie powinieneś mieć).";
        case 15: return "Kara: Klasa pancerza -1 (nocna natura czyni cię nieco mniej czujnym w dzień).";
        case 16: return "Klątwa: Zbyt wiele twarzy — trudno komukolwiek naprawdę ci ufać.";
        case 17: return "Kara: Kondycja -1 (ogień pochłonął część żywotności).";
        case 18: return "Klątwa: Duchy nie dają spokoju w miastach — odpoczynek w tawernach jest niemożliwy.";
        case 19: return "Klątwa: Kapłani Dobra traktują twój spokój grzechu jako prowokację.";
        case 20: return "Klątwa: Raz na dobę musisz powiedzieć kłamstwo — inaczej prawda boli.";
        case 21: return "Klątwa: Coś w zaświatach zaczyna odliczać twoje dni. Kiedy zegar wybije — nikt nie wie.";
    }
    return "";
}
