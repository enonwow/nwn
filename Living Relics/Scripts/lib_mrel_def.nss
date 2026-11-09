#include "lib_nui"
#include "sql_mrel"

void MrelCreateWindow(object oPC);
void MrelFeedRelicList(object oPC, int nToken);
void MrelFeedDetail(object oPC, int nToken);
void MrelAttuneItem(object oPC, int nSlot, object oItem);
void MrelRemoveRelic(object oPC, int nSlot);
void MrelFeedMemory(object oPC, int nAmount, int nTrigger);
void MrelWakeRelic(object oPC, int nSlot);
void MrelApplyWakeEffect(object oPC, int nHunger);
void MrelOnKill(object oKiller);
void MrelOnSurvive(object oPC);
void MrelOnWitness(object oPC);
void MrelSyncItems(object oPC);

// === Window / event IDs ===
const string MREL_WINDOW         = "MREL_WINDOW";
const string MREL_EV_SCRIPT      = "lib_mrel_ev";
const string MREL_WIN_GEOM       = "mrel_win_geom";

// === NUI bind names ===
const string MREL_BIND_SLOT_NAME  = "mrel_slot_name";
const string MREL_BIND_SLOT_HUNG  = "mrel_slot_hung";
const string MREL_BIND_SLOT_MPROG = "mrel_slot_prog";
const string MREL_BIND_SLOT_MEM   = "mrel_slot_mem";
const string MREL_BIND_SLOT_ENC   = "mrel_slot_enc";
const string MREL_BIND_VISION     = "mrel_vision";
const string MREL_BIND_ATTUNE_ENA = "mrel_attune_ena";
const string MREL_BIND_REMOVE_ENA = "mrel_remove_ena";
const string MREL_BIND_BLOOD_ENA  = "mrel_blood_ena";
const string MREL_BIND_BLOOD_LBL  = "mrel_blood_lbl";
const string MREL_BIND_WAKE_ENA   = "mrel_wake_ena";
const string MREL_BIND_DETAIL_VIS = "mrel_detail_vis";
const string MREL_BIND_SLOT_CNT   = "mrel_slot_cnt";

// === Button IDs ===
const string MREL_BTN_CLOSE       = "mrel_btn_close";
const string MREL_BTN_ROW         = "mrel_btn_row";
const string MREL_BTN_ATTUNE      = "mrel_btn_attune";
const string MREL_BTN_REMOVE      = "mrel_btn_remove";
const string MREL_BTN_BLOOD       = "mrel_btn_blood";
const string MREL_BTN_WAKE        = "mrel_btn_wake";

// === Local vars on PC ===
const string MREL_LVAR_SEL_SLOT   = "MREL_SEL_SLOT";
const string MREL_LVAR_ATTUNING   = "MREL_ATTUNING";

// === Layout ===
const float  MREL_W               = 580.0;
const float  MREL_H               = 460.0;
const int    MREL_SLOT_COUNT      = 3;

// === Memory thresholds per hunger level ===
const int MREL_MEM_MAX_H1         = 10;
const int MREL_MEM_MAX_H2         = 13;
const int MREL_MEM_MAX_H3         = 16;
const int MREL_MEM_MAX_H4         = 20;
const int MREL_MEM_MAX_H5         = 25;

// === Trigger types ===
const int MREL_TRIG_KILL          = 0;
const int MREL_TRIG_SURVIVE       = 1;
const int MREL_TRIG_WITNESS       = 2;
const int MREL_TRIG_REST          = 3;

// === LVAR stamped on the item when attuned ===
const string MREL_ITEM_LVAR       = "MREL_ID";

// === Blood offering cost in HP ===
const int MREL_BLOOD_COST_HP      = 5;
const int MREL_BLOOD_MEMORY_GAIN  = 3;

// === HP threshold below which "survive" trigger fires ===
const int MREL_SURVIVE_HP_PCT     = 20;

// ----------------------------------------------------------------

string MrelHungerLabel(int nHunger)
{
    switch(nHunger)
    {
        case 1: return "Głodna";
        case 2: return "Spragniona";
        case 3: return "Wygłodniała";
        case 4: return "Pożerająca";
        case 5: return "PRZEBUDZONA";
    }
    return "---";
}

int MrelMemMax(int nHunger)
{
    switch(nHunger)
    {
        case 1: return MREL_MEM_MAX_H1;
        case 2: return MREL_MEM_MAX_H2;
        case 3: return MREL_MEM_MAX_H3;
        case 4: return MREL_MEM_MAX_H4;
        case 5: return MREL_MEM_MAX_H5;
    }
    return MREL_MEM_MAX_H1;
}

// Returns a dark-fantasy Polish vision string based on trigger and hunger.
string MrelGetVisionText(int nTrigger, int nHunger)
{
    int nRoll = d2();
    switch(nHunger)
    {
        case 1:
            if(nTrigger == MREL_TRIG_KILL)
                return (nRoll == 1)
                    ? "Krew jest ciepła. Pamiętam. Pamiętam wszystko."
                    : "Ten, kto padł — nosił w sobie starą bliznę. Teraz jest moja.";
            if(nTrigger == MREL_TRIG_SURVIVE)
                return (nRoll == 1)
                    ? "Byłeś bliski końca. Widziałam cię takim już raz, dawno temu."
                    : "Każda rana to wspomnienie. Twoje blizny zaczynają być i moimi.";
            if(nTrigger == MREL_TRIG_WITNESS)
                return "Ta śmierć była niespokojną. Teraz nawiedza i mnie.";
            return "Przez mgłę snu widzę starą rzeź. Czyją? Może twoją. Może moją.";

        case 2:
            if(nTrigger == MREL_TRIG_KILL)
                return (nRoll == 1)
                    ? "Oczy tego stworzenia wciąż wiercą się w moje wspomnienia. Nosiłam ich wzrok przez wieki."
                    : "Czuję ich ostatnie tchnienie jak własne. Oddychaj uważnie.";
            if(nTrigger == MREL_TRIG_SURVIVE)
                return "Pamiętam jak ginął mój poprzedni właściciel. Tak samo krzyczał.";
            if(nTrigger == MREL_TRIG_WITNESS)
                return "Widziałam wiele śmierci. Ta mnie niepokoi. Była zbyt znajoma.";
            return "Sen? Nie dla ciebie. Jestem głodna wspomnień — daj mi więcej.";

        case 3:
            if(nTrigger == MREL_TRIG_KILL)
                return "Czuję ich ostatni strach jak własny. Smakuje gorzko. Pragnę więcej.";
            if(nTrigger == MREL_TRIG_SURVIVE)
                return "Prawie umarłeś. Byłabym wolna. Część mnie tego pragnęła.";
            if(nTrigger == MREL_TRIG_WITNESS)
                return "Ta śmierć zasila mnie lepiej niż twoja krew. Zostań przy umierających.";
            return "Moje wspomnienia pożerają twoje. Czy to twoje imię? Czy moje?";

        case 4:
            if(nTrigger == MREL_TRIG_KILL)
                return "Spełniona. Na chwilę. Czuję jak zapomnienie wraca. Daj mi więcej.";
            if(nTrigger == MREL_TRIG_SURVIVE)
                return "Żyjesz. Dobrze. Żywi noszą mnie dłużej. Na razie.";
            if(nTrigger == MREL_TRIG_WITNESS)
                return "Ich duch przepłynął przeze mnie. Zostało po nich coś... użytecznego.";
            return "W twoich snach chodzi ktoś z moją twarzą. To nie ja. Nie całkiem.";

        case 5:
            return "JESTEM PRZEBUDZONA. Pamiętam każdego, kto mnie niósł. Każdą ich śmierć. Każdą chwałę. Teraz ty. Spełnię moje przeznaczenie — i pochłonę wspomnienie tej chwili.";
    }
    return "Relikwia milczy.";
}
