#include "lib_nui"
#include "sql_scar"

void ScarOpenWindow(object oPC);
void ScarApplyEffects(object oPC);
void ScarRemoveEffects(object oPC);
void ScarGainWound(object oPC);
void ScarRefreshHealed(object oPC);
void ScarTreatWound(object oPC, int nWoundId, int nToken);
void FeedScarList(object oPC, int nToken);
void FeedScarDetail(object oPC, int nToken, int nWoundId);

// ── Window IDs ────────────────────────────────────────────────────
const string SCAR_WINDOW     = "SCAR_WINDOW";
const string SCAR_EV_SCRIPT  = "lib_scar_ev";
const string SCAR_WIN_GEOM   = "scar_win_geom";

// List (NuiList) binds
const string SCAR_BIND_ROW_LOC    = "scar_row_loc";
const string SCAR_BIND_ROW_TYPE   = "scar_row_type";
const string SCAR_BIND_ROW_STATUS = "scar_row_sta";
const string SCAR_BIND_ROW_EFF    = "scar_row_eff";
const string SCAR_BIND_ROW_COLOR  = "scar_row_col";
const string SCAR_BIND_ROW_ENC    = "scar_row_enc";
const string SCAR_BIND_ROW_COUNT  = "scar_rowcount";

// Detail panel binds
const string SCAR_BIND_DET_HEADER = "scar_det_hdr";
const string SCAR_BIND_DET_FLAVOR = "scar_det_flav";
const string SCAR_BIND_TREAT_ENA  = "scar_treat_ena";
const string SCAR_BIND_TREAT_LBL  = "scar_treat_lbl";

// Button IDs
const string SCAR_BTN_CLOSE = "scar_btn_close";
const string SCAR_BTN_ROW   = "scar_btn_row";
const string SCAR_BTN_TREAT = "scar_btn_treat";

// PC local variable — selected wound id in UI
const string SCAR_LVAR_SEL_ID = "SCAR_SEL_ID";

// Tag written on every effect applied by this system so we can isolate them.
// Requires NWN:EE 8193.37+ for TagEffect / GetEffectTag.
const string SCAR_EFFECT_TAG = "SCAR_SYS";

// ── Wound types ───────────────────────────────────────────────────
const int SCAR_TYPE_CUT    = 0;
const int SCAR_TYPE_BURN   = 1;
const int SCAR_TYPE_PIERCE = 2;
const int SCAR_TYPE_BREAK  = 3;
const int SCAR_TYPE_NERVE  = 4;

// ── Body locations ────────────────────────────────────────────────
const int SCAR_LOC_HEAD  = 0;
const int SCAR_LOC_CHEST = 1;
const int SCAR_LOC_ARM_L = 2;
const int SCAR_LOC_ARM_R = 3;
const int SCAR_LOC_LEG_L = 4;
const int SCAR_LOC_LEG_R = 5;

// ── Wound status ──────────────────────────────────────────────────
const int SCAR_STATUS_OPEN    = 0; // untreated; stat penalty active
const int SCAR_STATUS_HEALING = 1; // treated; penalty removed, awaiting scar
const int SCAR_STATUS_SCARRED = 2; // fully healed; scar effect active

// ── Tunable config ────────────────────────────────────────────────
const int SCAR_TREAT_COST = 75;   // gold cost per treatment
const int SCAR_HEAL_HOURS = 24;   // real-time hours before wound becomes scar
const int SCAR_MAX_WOUNDS = 8;    // cap: new wounds are ignored above this

// ── String helpers (player-visible text in Polish) ─────────────────

string ScarTypeName(int nType)
{
    switch(nType)
    {
        case SCAR_TYPE_CUT:    return "Cięcie";
        case SCAR_TYPE_BURN:   return "Oparzenie";
        case SCAR_TYPE_PIERCE: return "Przebicie";
        case SCAR_TYPE_BREAK:  return "Złamanie";
        case SCAR_TYPE_NERVE:  return "Nerwy";
    }
    return "Rana";
}

string ScarLocName(int nLoc)
{
    switch(nLoc)
    {
        case SCAR_LOC_HEAD:  return "Głowa";
        case SCAR_LOC_CHEST: return "Tors";
        case SCAR_LOC_ARM_L: return "Lewe ramię";
        case SCAR_LOC_ARM_R: return "Prawe ramię";
        case SCAR_LOC_LEG_L: return "Lewa noga";
        case SCAR_LOC_LEG_R: return "Prawa noga";
    }
    return "Nieznane";
}

string ScarStatusName(int nStatus)
{
    switch(nStatus)
    {
        case SCAR_STATUS_OPEN:    return "Otwarta";
        case SCAR_STATUS_HEALING: return "Goi się";
        case SCAR_STATUS_SCARRED: return "Blizna";
    }
    return "";
}

// Short effect label shown in the list column
string ScarEffectLabel(int nType, int nStatus)
{
    if(nStatus == SCAR_STATUS_OPEN)
    {
        switch(nType)
        {
            case SCAR_TYPE_CUT:    return "-1 ZZR";
            case SCAR_TYPE_BURN:   return "-1 CHA";
            case SCAR_TYPE_PIERCE: return "-1 KON";
            case SCAR_TYPE_BREAK:  return "-1 SIŁ";
            case SCAR_TYPE_NERVE:  return "-1 INT";
        }
    }
    else if(nStatus == SCAR_STATUS_SCARRED)
    {
        switch(nType)
        {
            case SCAR_TYPE_CUT:    return "+1 Zastraszanie";
            case SCAR_TYPE_BURN:   return "Odp. ogień 5";
            case SCAR_TYPE_PIERCE: return "+1 Wytrwałość";
            case SCAR_TYPE_BREAK:  return "+1 Wytrwałość";
            case SCAR_TYPE_NERVE:  return "-1 Konc / +1 Nas.";
        }
    }
    return "—";
}

// Flavor text for an open / healing wound
string ScarFlavorOpen(int nType, int nLoc)
{
    string sLoc;
    switch(nLoc)
    {
        case SCAR_LOC_HEAD:  sLoc = "Na głowie"; break;
        case SCAR_LOC_CHEST: sLoc = "Na torsi"; break;
        case SCAR_LOC_ARM_L: sLoc = "Na lewym ramieniu"; break;
        case SCAR_LOC_ARM_R: sLoc = "Na prawym ramieniu"; break;
        case SCAR_LOC_LEG_L: sLoc = "Na lewej nodze"; break;
        case SCAR_LOC_LEG_R: sLoc = "Na prawej nodze"; break;
        default: sLoc = "Gdzieś"; break;
    }
    switch(nType)
    {
        case SCAR_TYPE_CUT:
            return sLoc + " widzisz głębokie cięcie, które wciąż sączy krew pod bandażem. "
                + "Każdy ruch rozrywa strupki. Chirurg mógłby zszyć ranę i zapobiec zakażeniu.";
        case SCAR_TYPE_BURN:
            return sLoc + " skóra jest zgrubiała i pokryta pęcherzami. Zapach przypalenia nie odpuszcza. "
                + "Zimny balsam ograniczyłby zniszczenia, lecz ślad pozostanie na zawsze.";
        case SCAR_TYPE_PIERCE:
            return sLoc + " tkwi wąska, lecz głęboka rana po klindze lub bełcie. "
                + "Wewnątrz może wciąż tkwić odłamek metalu. Lekarz powinien zbadać ranę przed gojeniem.";
        case SCAR_TYPE_BREAK:
            return sLoc + " kość trzeszczała podczas walki jak sucha gałąź. "
                + "Każdy chwyt wywołuje przeszywający ból. Bez szyn i odpoczynku gojenie idzie krzywo.";
        case SCAR_TYPE_NERVE:
            return sLoc + " palce lub mięśnie są częściowo odrętwiali po trafieniu błyskawicą "
                + "lub ciosie w splot nerwów. Myśli rozpraszają się. Ból jest tępy i ciągły.";
    }
    return "Rana wymaga opieki medycznej.";
}

// Flavor text for a fully healed scar
string ScarFlavorScar(int nType, int nLoc)
{
    string sLoc;
    switch(nLoc)
    {
        case SCAR_LOC_HEAD:  sLoc = "Na głowie"; break;
        case SCAR_LOC_CHEST: sLoc = "Na torsi"; break;
        case SCAR_LOC_ARM_L: sLoc = "Na lewym ramieniu"; break;
        case SCAR_LOC_ARM_R: sLoc = "Na prawym ramieniu"; break;
        case SCAR_LOC_LEG_L: sLoc = "Na lewej nodze"; break;
        case SCAR_LOC_LEG_R: sLoc = "Na prawej nodze"; break;
        default: sLoc = "Gdzieś"; break;
    }
    switch(nType)
    {
        case SCAR_TYPE_CUT:
            return sLoc + " biegnie blada nitka blizny po cięciu. "
                + "Niejedna negocjacja skończyła się ugodą, gdy rozmówca zauważył ten ślad po raz pierwszy.";
        case SCAR_TYPE_BURN:
            return sLoc + " skóra jest zgrubiała i błyszcząca niczym wyprawa na starym bucie. "
                + "Blizna po oparzeniu zahartowała ciało na żar — lecz dawna uroda odeszła bezpowrotnie.";
        case SCAR_TYPE_PIERCE:
            return sLoc + " okrągła blizna po przebiciu wgłębia się jak odcisk monety. "
                + "Tors zapamiętał każde wbicie ostrza — i wytrzymuje teraz nieco więcej.";
        case SCAR_TYPE_BREAK:
            return sLoc + " kość zrosła się grubsza niż wcześniej. "
                + "Mówią, że złamana kość jest mocniejsza po zrośnięciu. I coś jest w tej mądrości.";
        case SCAR_TYPE_NERVE:
            return sLoc + " drobne mrowienie przypomina o przeszłości przy każdej zmianie pogody. "
                + "Umysł, choć wolniejszy podczas skupienia, wyostrzył słuch w poszukiwaniu zagrożeń.";
    }
    return "Blizna zagoiła się, lecz jej historia pozostaje wyryта na ciele.";
}
