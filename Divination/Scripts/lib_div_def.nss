#include "lib_nui"
#include "sql_div"

// Forward declarations
void DivShowWindow(object oPC);
void DivFeedMain(object oPC, int nToken);
void DivFeedCards(object oPC, int nToken);
void DivStartReading(object oPC, int nToken, int nCardCount);
void DivRevealCard(object oPC, int nToken, int nSlot);
void DivAcceptFate(object oPC, int nToken);
void DivRemoveAllDivEffects(object oPC);
void DivRemoveNegativeDivEffects(object oPC);
void DivReapplyPersistentEffects(object oPC);

// ----------------------------------------------------------------
// Window & group IDs
// ----------------------------------------------------------------

const string DIV_WINDOW      = "DIV_WIN";
const string DIV_EV_SCRIPT   = "lib_div_ev";
const string DIV_WIN_GEOM    = "div_win_geom";
const string DIV_GRP_SWAP    = "div_grp_swap";

// ----------------------------------------------------------------
// Main view bind names
// ----------------------------------------------------------------

const string DIV_BIND_EFF_NAME      = "div_eff_name";
const string DIV_BIND_EFF_TIME      = "div_eff_time";
const string DIV_BIND_EFF_COLOR     = "div_eff_color";
const string DIV_BIND_EFF_LEN       = "div_eff_len";
const string DIV_BIND_EFFLIST_VIS   = "div_efflist_vis";
const string DIV_BIND_NOEFF_LBL     = "div_noeff_lbl";
const string DIV_BIND_NOEFF_VIS     = "div_noeff_vis";
const string DIV_BIND_BTN_READ_ENA  = "div_read_ena";
const string DIV_BIND_COOLDOWN_LBL  = "div_cd_lbl";

// ----------------------------------------------------------------
// Reading view bind names
// ----------------------------------------------------------------

// Per-slot (append IntToString(i), i=0..4)
const string DIV_BIND_SLOT_LBL  = "div_slot_lbl_";
const string DIV_BIND_SLOT_ENA  = "div_slot_ena_";
const string DIV_BIND_SLOT_COL  = "div_slot_col_";
const string DIV_BIND_SLOT_VIS  = "div_slot_vis_";
const string DIV_BIND_SLOT_TIP  = "div_slot_tip_";

const string DIV_BIND_DETAIL_VIS  = "div_det_vis";
const string DIV_BIND_DETAIL_NAME = "div_det_name";
const string DIV_BIND_DETAIL_FLAV = "div_det_flav";
const string DIV_BIND_DETAIL_EFF  = "div_det_eff";
const string DIV_BIND_ACCEPT_ENA  = "div_accept_ena";
const string DIV_BIND_RD_TITLE    = "div_rd_title";

// ----------------------------------------------------------------
// Button IDs
// ----------------------------------------------------------------

const string DIV_BTN_CLOSE  = "div_close";
const string DIV_BTN_SMALL  = "div_small";
const string DIV_BTN_GRAND  = "div_grand";
const string DIV_BTN_CARD   = "div_card_";   // + IntToString(i)
const string DIV_BTN_ACCEPT = "div_accept";
const string DIV_BTN_BACK   = "div_back";

// ----------------------------------------------------------------
// LVARs on PC (session-only, cleared on leave)
// ----------------------------------------------------------------

const string DIV_LVAR_CARDS    = "DIV_CARDS";
const string DIV_LVAR_REVEALED = "DIV_REVEALED";   // int bitmask
const string DIV_LVAR_CARDCNT  = "DIV_CARD_COUNT";
const string DIV_LVAR_LASTCARD = "DIV_LAST_CARD";

// ----------------------------------------------------------------
// Game constants
// ----------------------------------------------------------------

const int   DIV_SMALL_CARDS  = 3;
const int   DIV_GRAND_CARDS  = 5;
const int   DIV_MAX_SLOTS    = 5;
const int   DIV_SMALL_COST   = 50;
const int   DIV_GRAND_COST   = 150;
const int   DIV_COOLDOWN_S   = 86400;  // 24h real time
const int   DIV_DUR_LONG_S   = 14400; // 4h default effect duration
const int   DIV_DUR_MED_S    = 7200;  // 2h
const int   DIV_DUR_SHORT_S  = 3600;  // 1h

// ----------------------------------------------------------------
// Card IDs (Major Arcana, dark fantasy flavoured)
// ----------------------------------------------------------------

const int   DIV_CARD_FOOL       = 0;
const int   DIV_CARD_MAGICIAN   = 1;
const int   DIV_CARD_PRIESTESS  = 2;
const int   DIV_CARD_EMPRESS    = 3;
const int   DIV_CARD_EMPEROR    = 4;
const int   DIV_CARD_HIEROPHANT = 5;
const int   DIV_CARD_LOVERS     = 6;
const int   DIV_CARD_CHARIOT    = 7;
const int   DIV_CARD_STRENGTH   = 8;
const int   DIV_CARD_HERMIT     = 9;
const int   DIV_CARD_WHEEL      = 10;
const int   DIV_CARD_JUSTICE    = 11;
const int   DIV_CARD_HANGED     = 12;
const int   DIV_CARD_DEATH      = 13;
const int   DIV_CARD_TEMPERANCE = 14;
const int   DIV_CARD_DEVIL      = 15;
const int   DIV_CARD_TOWER      = 16;
const int   DIV_CARD_STAR       = 17;
const int   DIV_CARD_MOON       = 18;
const int   DIV_CARD_SUN        = 19;
const int   DIV_CARD_JUDGEMENT  = 20;
const int   DIV_CARD_WORLD      = 21;
const int   DIV_CARD_COUNT      = 22;

// ----------------------------------------------------------------
// Layout
// ----------------------------------------------------------------

const float DIV_W          = 500.0;
const float DIV_H          = 640.0;
const float DIV_CONTENT_W  = 460.0;
const float DIV_CARD_W     = 76.0;
const float DIV_CARD_H     = 106.0;

// ================================================================
// Card data accessors
// ================================================================

string DivCardName(int n)
{
    switch(n)
    {
        case DIV_CARD_FOOL:       return "Głupiec";
        case DIV_CARD_MAGICIAN:   return "Mag";
        case DIV_CARD_PRIESTESS:  return "Kapłanka";
        case DIV_CARD_EMPRESS:    return "Cesarzowa";
        case DIV_CARD_EMPEROR:    return "Cesarz";
        case DIV_CARD_HIEROPHANT: return "Kapłan";
        case DIV_CARD_LOVERS:     return "Kochankowie";
        case DIV_CARD_CHARIOT:    return "Rydwan";
        case DIV_CARD_STRENGTH:   return "Siła";
        case DIV_CARD_HERMIT:     return "Pustelnik";
        case DIV_CARD_WHEEL:      return "Koło Fortuny";
        case DIV_CARD_JUSTICE:    return "Sprawiedliwość";
        case DIV_CARD_HANGED:     return "Wisielec";
        case DIV_CARD_DEATH:      return "Śmierć";
        case DIV_CARD_TEMPERANCE: return "Umiarkowanie";
        case DIV_CARD_DEVIL:      return "Diabeł";
        case DIV_CARD_TOWER:      return "Wieża";
        case DIV_CARD_STAR:       return "Gwiazda";
        case DIV_CARD_MOON:       return "Księżyc";
        case DIV_CARD_SUN:        return "Słońce";
        case DIV_CARD_JUDGEMENT:  return "Sąd Ostateczny";
        case DIV_CARD_WORLD:      return "Świat";
    }
    return "?";
}

string DivCardFlavor(int n)
{
    switch(n)
    {
        case DIV_CARD_FOOL:
            return "\"Brak mądrości chroni przez chwilę... lecz przepaść nie czeka.\"";
        case DIV_CARD_MAGICIAN:
            return "\"Wiedza to narzędzie. Jak każde narzędzie — ma dwa końce.\"";
        case DIV_CARD_PRIESTESS:
            return "\"Tajemnica przemawia ciszą. Słuchaj, nim ciemność wróci.\"";
        case DIV_CARD_EMPRESS:
            return "\"Z ziemi rodzi się siła. Z bólu rodzi się mądrość.\"";
        case DIV_CARD_EMPEROR:
            return "\"Władza to ciężar. Niosą go wyłącznie silni.\"";
        case DIV_CARD_HIEROPHANT:
            return "\"Tradycja jest łańcuchem — ocal siebie lub zakuj innych.\"";
        case DIV_CARD_LOVERS:
            return "\"Miłość i zdrada — dwie strony tej samej monety.\"";
        case DIV_CARD_CHARIOT:
            return "\"Prędkość jest jedynym ratunkiem, gdy mury runęły.\"";
        case DIV_CARD_STRENGTH:
            return "\"Mięśnie nie kłamią. Żelazo też nie.\"";
        case DIV_CARD_HERMIT:
            return "\"Samotność uczy rzeczy, których tłum nigdy nie pojmie.\"";
        case DIV_CARD_WHEEL:
            return "\"Fortuna kręci kołem bez litości. Dziś dar, jutro kara.\"";
        case DIV_CARD_JUSTICE:
            return "\"Sprawiedliwość nie ma oczu, lecz ma dłonie.\"";
        case DIV_CARD_HANGED:
            return "\"Zawieszony między dwiema prawdami — żadnej nie znasz.\"";
        case DIV_CARD_DEATH:
            return "\"Śmierć nie pyta o gotowość. Po prostu przychodzi.\"";
        case DIV_CARD_TEMPERANCE:
            return "\"Cnota czyści skazę. Lecz ile warte jest oczyszczenie?\"";
        case DIV_CARD_DEVIL:
            return "\"Strach jest łańcuchem — ty go więżesz lub nosisz sam.\"";
        case DIV_CARD_TOWER:
            return "\"Ruiny są dowodem tego, co mogło być wzniosłe.\"";
        case DIV_CARD_STAR:
            return "\"Gwiazdy pamiętają to, co świat zdążył zapomnieć.\"";
        case DIV_CARD_MOON:
            return "\"Księżyc skrywa to, co dzień ujawnia blaskiem stali.\"";
        case DIV_CARD_SUN:
            return "\"Łaska Słońca jest rzadka i oślepiająca jak wyrok.\"";
        case DIV_CARD_JUDGEMENT:
            return "\"Przeznaczenie jeszcze nie skończyło z tobą.\"";
        case DIV_CARD_WORLD:
            return "\"Ciężar świata — nagroda dla tych, którzy przeżyli.\"";
    }
    return "";
}

string DivCardEffectDesc(int n)
{
    switch(n)
    {
        case DIV_CARD_FOOL:
            return "KLĄTWA: -1 do trafień, -1 do KP (4 godz.)";
        case DIV_CARD_MAGICIAN:
            return "+1 do trafień, +1 do wszystkich rzutów obronnych (4 godz.)";
        case DIV_CARD_PRIESTESS:
            return "Natychmiast regeneruje 20% maksimum PŻ.";
        case DIV_CARD_EMPRESS:
            return "+2 do Budowy (4 godz.)";
        case DIV_CARD_EMPEROR:
            return "+2 do Siły (4 godz.)";
        case DIV_CARD_HIEROPHANT:
            return "+2 do rzutów Wolą (4 godz.)";
        case DIV_CARD_LOVERS:
            return "+2 do Charyzmy (4 godz.)";
        case DIV_CARD_CHARIOT:
            return "+2 do rzutów Refleksem (4 godz.)";
        case DIV_CARD_STRENGTH:
            return "+1 do trafień i +1 do obrażeń (4 godz.)";
        case DIV_CARD_HERMIT:
            return "+4 do Skradania i Ukrywania, Nadwzroczność (4 godz.)";
        case DIV_CARD_WHEEL:
            return "Natychmiastowy los: złoto, kara lub nicość.";
        case DIV_CARD_JUSTICE:
            return "+2 do Dyscypliny i Perswazji (4 godz.)";
        case DIV_CARD_HANGED:
            return "KLĄTWA: -1 do trafień, -1 do wszystkich rzutów (4 godz.)";
        case DIV_CARD_DEATH:
            return "KLĄTWA: ogłuszenie 3s, -2 do Budowy (4 godz.)";
        case DIV_CARD_TEMPERANCE:
            return "Usuwa pieczęcie klątw. +2 do KP (2 godz.)";
        case DIV_CARD_DEVIL:
            return "+4 do Zastraszania, -2 do Charyzmy (4 godz.)";
        case DIV_CARD_TOWER:
            return "KLĄTWA: natychmiastowe 3k8 obrażeń magicznych.";
        case DIV_CARD_STAR:
            return "Natychmiast 40% PŻ + regeneracja 2 PŻ/6s (2 godz.)";
        case DIV_CARD_MOON:
            return "Widzenie Niewidzialnych (2 godz.), -1 do trafień (2 godz.)";
        case DIV_CARD_SUN:
            return "+2 do WSZYSTKICH cech (1 godz.)";
        case DIV_CARD_JUDGEMENT:
            return "+2 do wszystkich rzutów, Odporność na Strach (4 godz.)";
        case DIV_CARD_WORLD:
            return "+1 do WSZYSTKICH cech (4 godz.)";
    }
    return "";
}

int DivCardIsNegative(int n)
{
    return (n == DIV_CARD_FOOL  || n == DIV_CARD_HANGED  ||
            n == DIV_CARD_DEATH || n == DIV_CARD_TOWER   ||
            n == DIV_CARD_WHEEL);
}

// Returns FALSE for instant-only cards that need no SQL entry.
int DivCardIsPersistent(int n)
{
    return (n != DIV_CARD_PRIESTESS &&
            n != DIV_CARD_WHEEL     &&
            n != DIV_CARD_TOWER     &&
            n != DIV_CARD_TEMPERANCE);
}

int DivCardDurationS(int n)
{
    if(n == DIV_CARD_SUN)        return DIV_DUR_SHORT_S;
    if(n == DIV_CARD_MOON)       return DIV_DUR_MED_S;
    if(n == DIV_CARD_STAR)       return DIV_DUR_MED_S;
    if(n == DIV_CARD_TEMPERANCE) return DIV_DUR_MED_S;
    return DIV_DUR_LONG_S;
}

json DivCardColor(int n)
{
    if(DivCardIsNegative(n))
        return NuiColor(210, 80, 80);
    switch(n)
    {
        case DIV_CARD_PRIESTESS:
        case DIV_CARD_STAR:      return NuiColor(100, 200, 150);
        case DIV_CARD_SUN:       return NuiColor(255, 215, 70);
        case DIV_CARD_MOON:      return NuiColor(150, 185, 225);
        case DIV_CARD_TEMPERANCE:return NuiColor(120, 200, 200);
    }
    return NuiColor(185, 165, 120);
}
