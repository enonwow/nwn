// lib_inq_def.nss - Inquisition: constants, IDs, flavor helpers

#include "lib_nui"
#include "sql_inq"

void InqOpenDossierWindow(object oPC);
void InqOpenDmWindow(object oDM);
void InqAddCharge(object oPC, int nActId);
void InqApplyRatingEffects(object oPC, int nRating);
void InqRemoveRatingEffects(object oPC);
void InqFeedDossier(object oPC, int nToken);
void InqFeedDmPanel(object oDM, int nToken);

// ============================================================
// Heretical act IDs
// ============================================================
const int INQ_ACT_FORBIDDEN_MAGIC    = 0;
const int INQ_ACT_DEMON_CONTACT      = 1;
const int INQ_ACT_BLASPHEMY          = 2;
const int INQ_ACT_FORBIDDEN_TOME     = 3;
const int INQ_ACT_UNDEAD_CONSORTING  = 4;
const int INQ_ACT_DARK_RITUAL        = 5;
const int INQ_ACT_COUNT              = 6;

// ============================================================
// Rating thresholds
// ============================================================
const int INQ_THRESHOLD_CLEAN        = 0;
const int INQ_THRESHOLD_SUSPECT      = 1;
const int INQ_THRESHOLD_ACCUSED      = 26;
const int INQ_THRESHOLD_CONVICTED    = 51;
const int INQ_THRESHOLD_CONDEMNED    = 76;
const int INQ_RATING_MAX             = 100;

// ============================================================
// Reduction amounts
// ============================================================
const int INQ_CONFESS_REDUCTION      = 15;
const int INQ_RECANT_REDUCTION       = 25;
const int INQ_CONFESS_GOLD_PER_10    = 100;

// ============================================================
// Window identifiers
// ============================================================
const string INQ_WINDOW_DOSSIER      = "INQ_DOSSIER";
const string INQ_WINDOW_DM           = "INQ_DM";
const string INQ_WINDOW_DM_ACT       = "INQ_DM_ACT";
const string INQ_EV_SCRIPT           = "lib_inq_ev";

// ============================================================
// Bind names — dossier window
// ============================================================
const string INQ_BIND_STATUS_LBL     = "inq_status_lbl";
const string INQ_BIND_STATUS_COLOR   = "inq_status_color";
const string INQ_BIND_RATING_TXT     = "inq_rating_txt";
const string INQ_BIND_METER_VAL      = "inq_meter_val";
const string INQ_BIND_CHARGE_NAME    = "inq_charge_name";
const string INQ_BIND_CHARGE_TOTAL   = "inq_charge_total";
const string INQ_BIND_CHARGE_VIS     = "inq_charge_vis";
const string INQ_BIND_FLAVOR_TXT     = "inq_flavor_txt";
const string INQ_BIND_CONFESS_ENA    = "inq_confess_ena";
const string INQ_BIND_RECANT_ENA     = "inq_recant_ena";

// ============================================================
// Bind names — DM window
// ============================================================
const string INQ_BIND_DM_LIST_NAME   = "inq_dm_name";
const string INQ_BIND_DM_LIST_RATING = "inq_dm_rating";
const string INQ_BIND_DM_LIST_STATUS = "inq_dm_status";
const string INQ_BIND_DM_LIST_ENC    = "inq_dm_enc";
const string INQ_BIND_DM_DETAIL_LBL  = "inq_dm_detail";
const string INQ_BIND_DM_ACT_LABEL   = "inq_dm_act_lbl";
const string INQ_BIND_DM_ACT_ENC     = "inq_dm_act_enc";

// ============================================================
// Button IDs
// ============================================================
const string INQ_BTN_CLOSE           = "inq_btn_close";
const string INQ_BTN_CONFESS         = "inq_btn_confess";
const string INQ_BTN_RECANT          = "inq_btn_recant";
const string INQ_BTN_DM_CLOSE        = "inq_btn_dm_close";
const string INQ_BTN_DM_ROW          = "inq_btn_dm_row";
const string INQ_BTN_DM_ADD_ACT      = "inq_btn_dm_add";
const string INQ_BTN_DM_PARDON       = "inq_btn_dm_pardon";
const string INQ_BTN_DM_CLEAR        = "inq_btn_dm_clear";
const string INQ_BTN_DM_ACT_ROW      = "inq_btn_dm_act";
const string INQ_BTN_DM_ACT_CLOSE    = "inq_btn_dm_act_cls";

// ============================================================
// Local variables on PC / DM
// ============================================================
const string INQ_LVAR_TOKEN          = "INQ_NUI_TOKEN";
const string INQ_LVAR_DM_TOKEN       = "INQ_DM_NUI_TOKEN";
const string INQ_LVAR_DM_SEL_UUID    = "INQ_DM_SEL_UUID";
const string INQ_LVAR_DM_SEL_NAME    = "INQ_DM_SEL_NAME";

// Tags for persistent effect identification
const string INQ_EFFECT_TAG_SUSPECT  = "INQ_EFF_SUSPECT";
const string INQ_EFFECT_TAG_ACCUSED  = "INQ_EFF_ACCUSED";
const string INQ_EFFECT_TAG_CONVICT  = "INQ_EFF_CONVICT";
const string INQ_EFFECT_TAG_CONDEMN  = "INQ_EFF_CONDEMN";

// Layout
const float INQ_W                    = 520.0;
const float INQ_H                    = 500.0;
const float INQ_DM_W                 = 580.0;
const float INQ_DM_H                 = 520.0;

// Window geometry bind names
const string INQ_WIN_GEOM            = "inq_win_geom";
const string INQ_WIN_ACT_GEOM        = "inq_win_act_geom";

// DM list count bind
const string INQ_BIND_DM_LIST_COUNT  = "inq_dm_count";

// ============================================================
// Pure data helpers
// ============================================================

int InqGetActWeight(int nActId)
{
    switch(nActId)
    {
        case INQ_ACT_FORBIDDEN_MAGIC:   return 12;
        case INQ_ACT_DEMON_CONTACT:     return 18;
        case INQ_ACT_BLASPHEMY:         return 8;
        case INQ_ACT_FORBIDDEN_TOME:    return 15;
        case INQ_ACT_UNDEAD_CONSORTING: return 20;
        case INQ_ACT_DARK_RITUAL:       return 25;
    }
    return 10;
}

string InqGetActName(int nActId)
{
    switch(nActId)
    {
        case INQ_ACT_FORBIDDEN_MAGIC:   return "Użycie zakazanej magii";
        case INQ_ACT_DEMON_CONTACT:     return "Kontakt z demonem";
        case INQ_ACT_BLASPHEMY:         return "Bluźnierstwo";
        case INQ_ACT_FORBIDDEN_TOME:    return "Posiadanie zakazanego tomu";
        case INQ_ACT_UNDEAD_CONSORTING: return "Obcowanie z nieumarłymi";
        case INQ_ACT_DARK_RITUAL:       return "Udział w mrocznym rytuale";
    }
    return "Nieznana herezja";
}

string InqGetStatusLabel(int nRating)
{
    if(nRating < INQ_THRESHOLD_SUSPECT)   return "Czysty";
    if(nRating < INQ_THRESHOLD_ACCUSED)   return "Pod obserwacją";
    if(nRating < INQ_THRESHOLD_CONVICTED) return "Oskarżony heretyk";
    if(nRating < INQ_THRESHOLD_CONDEMNED) return "Skazany heretyk";
    return "Wyklęty";
}

string InqGetStatusFlavor(int nRating)
{
    if(nRating < INQ_THRESHOLD_SUSPECT)
        return "Twoja dusza jest czysta w oczach Inkwizycji — przynajmniej na razie.";
    if(nRating < INQ_THRESHOLD_ACCUSED)
        return "Inkwizytorzy zaczęli zadawać pytania. Strzeż się, dokąd chodzisz i z kim rozmawiasz.";
    if(nRating < INQ_THRESHOLD_CONVICTED)
        return "Formalny nakaz aresztowania został wydany. Każdy inkwizytor ma twoje imię na liście.";
    if(nRating < INQ_THRESHOLD_CONDEMNED)
        return "Pieczęć heretyka wypala twoją skórę. Każdy widzi. Nie ma odwrotu bez łaski biskupa.";
    return "Jesteś wyklęty. Inkwizycja poluje na ciebie bez ostrzeżenia. Śmierć albo wygnanie.";
}

json InqGetStatusColor(int nRating)
{
    if(nRating < INQ_THRESHOLD_SUSPECT)   return NuiColor(160, 220, 160, 255);
    if(nRating < INQ_THRESHOLD_ACCUSED)   return NuiColor(220, 220, 80,  255);
    if(nRating < INQ_THRESHOLD_CONVICTED) return NuiColor(220, 130, 50,  255);
    if(nRating < INQ_THRESHOLD_CONDEMNED) return NuiColor(200, 70,  70,  255);
    return NuiColor(160, 40, 160, 255);
}

// Effect description shown at each threshold
string InqGetEffectDesc(int nRating)
{
    if(nRating < INQ_THRESHOLD_SUSPECT)
        return "Brak efektów.";
    if(nRating < INQ_THRESHOLD_ACCUSED)
        return "Inkwizytorzy mogą cię przesłuchać. Brak mechanicznych kar.";
    if(nRating < INQ_THRESHOLD_CONVICTED)
        return "-2 do Charyzmatu: napiętnowany społecznie.";
    if(nRating < INQ_THRESHOLD_CONDEMNED)
        return "-2 Charyzma, -1 AC: pieczęć heretyka i permanentny strach.";
    return "-4 Charyzma, -2 AC, -2 do rzutów obronnych: wyklęty.";
}
