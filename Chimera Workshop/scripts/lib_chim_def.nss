#include "lib_nui"
#include "sql_chim"

// Forward declarations for functions defined in lib_chim.nss
void ChimOpenWindow(object oPC);
void ChimFeedSlots(object oPC, int nToken);
void ChimFeedGraftList(object oPC, int nToken, string sSlot);
void ChimFeedDetail(object oPC, int nToken, json jGraft);
void ChimReapplyEffects(object oPC);
void ChimHandleInstall(object oPC, int nToken);
void ChimHandleRemove(object oPC, int nToken);

// ================================================================
// Window / event IDs
// ================================================================
const string CHIM_WINDOW       = "CHIM_WINDOW";
const string CHIM_EV_SCRIPT    = "lib_chim_ev";

// ================================================================
// Body slot names
// ================================================================
const string CHIM_SLOT_HEAD    = "head";
const string CHIM_SLOT_TORSO   = "torso";
const string CHIM_SLOT_ARMS    = "arms";
const string CHIM_SLOT_LEGS    = "legs";

// ================================================================
// NUI bind names
// ================================================================
const string CHIM_BIND_HEAD_LBL    = "chim_head_lbl";
const string CHIM_BIND_TORSO_LBL   = "chim_torso_lbl";
const string CHIM_BIND_ARMS_LBL    = "chim_arms_lbl";
const string CHIM_BIND_LEGS_LBL    = "chim_legs_lbl";
const string CHIM_BIND_HEAD_ENC    = "chim_head_enc";
const string CHIM_BIND_TORSO_ENC   = "chim_torso_enc";
const string CHIM_BIND_ARMS_ENC    = "chim_arms_enc";
const string CHIM_BIND_LEGS_ENC    = "chim_legs_enc";

const string CHIM_BIND_SEL_LBL     = "chim_sel_lbl";

const string CHIM_BIND_LST_NAME    = "chim_lst_name";
const string CHIM_BIND_LST_ENC     = "chim_lst_enc";
const string CHIM_BIND_LST_CNT     = "chim_lst_cnt";

const string CHIM_BIND_INFO_NAME   = "chim_info_name";
const string CHIM_BIND_INFO_FLAVOR = "chim_info_flavor";
const string CHIM_BIND_INFO_FX     = "chim_info_fx";
const string CHIM_BIND_INFO_REQ    = "chim_info_req";

const string CHIM_BIND_GRAFT_ENA   = "chim_graft_ena";
const string CHIM_BIND_REMOVE_ENA  = "chim_remove_ena";
const string CHIM_BIND_STATUS      = "chim_status";
const string CHIM_BIND_GEOM        = "chim_geom";

// ================================================================
// Button element IDs
// ================================================================
const string CHIM_BTN_CLOSE        = "chim_btn_close";
const string CHIM_BTN_HEAD         = "chim_btn_head";
const string CHIM_BTN_TORSO        = "chim_btn_torso";
const string CHIM_BTN_ARMS         = "chim_btn_arms";
const string CHIM_BTN_LEGS         = "chim_btn_legs";
const string CHIM_BTN_GRAFT        = "chim_btn_graft";
const string CHIM_BTN_REMOVE       = "chim_btn_remove";
const string CHIM_BTN_ROW          = "chim_btn_row";

// ================================================================
// PC-local variable names
// ================================================================
const string CHIM_LVAR_SEL_SLOT    = "CHIM_SEL_SLOT";
const string CHIM_LVAR_SEL_GRAFT   = "CHIM_SEL_GRAFT";
const string CHIM_LVAR_AVAIL       = "CHIM_AVAIL_JSON";

// ================================================================
// Economy / costs
// ================================================================
const int   CHIM_GRAFT_COST        = 500;
const int   CHIM_REMOVE_COST       = 1000;
const int   CHIM_REMOVE_HP         = 20;

// ================================================================
// Effect tag prefix; full tag = prefix + slot name, e.g. "CHIM_head"
// ================================================================
const string CHIM_EFFECT_TAG_PFX   = "CHIM_";

// ================================================================
// Window dimensions
// ================================================================
const float CHIM_WIN_W             = 620.0;
const float CHIM_WIN_H             = 510.0;

// ================================================================
// Graft catalog
// Each entry is a JsonObject with keys:
//   id       int     unique graft identifier
//   name     string  Polish display name
//   slot     string  head / torso / arms / legs
//   trophy   string  item tag consumed on install
//   trophy_n string  trophy display name
//   flavor   string  Polish flavor text (shown in detail panel)
//   fx_desc  string  Polish effects summary line
// ================================================================

json ChimBuildGraftTable()
{
    json jT = JsonArray();
    json g;

    // ---- HEAD ----

    g = JsonObject();
    g = JsonObjectSet(g, "id",      JsonInt(1));
    g = JsonObjectSet(g, "name",    JsonString("Oko Bazyliszka"));
    g = JsonObjectSet(g, "slot",    JsonString(CHIM_SLOT_HEAD));
    g = JsonObjectSet(g, "trophy",  JsonString("ds_basilisk_eye"));
    g = JsonObjectSet(g, "trophy_n",JsonString("Oko Bazyliszka"));
    g = JsonObjectSet(g, "flavor",  JsonString("Martwe złote oko wbudowuje się w twój oczodół. Widzisz zbyt wiele. Zbyt wyraźnie."));
    g = JsonObjectSet(g, "fx_desc", JsonString("+ Odporność na Paraliż  |  − 2 Charyzmy"));
    jT = JsonArrayInsert(jT, g);

    g = JsonObject();
    g = JsonObjectSet(g, "id",      JsonInt(2));
    g = JsonObjectSet(g, "name",    JsonString("Koreks Umysłożercy"));
    g = JsonObjectSet(g, "slot",    JsonString(CHIM_SLOT_HEAD));
    g = JsonObjectSet(g, "trophy",  JsonString("ds_mind_flayer_brain"));
    g = JsonObjectSet(g, "trophy_n",JsonString("Mózg Umysłożercy"));
    g = JsonObjectSet(g, "flavor",  JsonString("Purpurowe włókna splatają się z twoimi zwojami. Myśli stają się ostrzejsze — i bardziej obce."));
    g = JsonObjectSet(g, "fx_desc", JsonString("+ 2 Inteligencji  |  − 2 Siły"));
    jT = JsonArrayInsert(jT, g);

    // ---- TORSO ----

    g = JsonObject();
    g = JsonObjectSet(g, "id",      JsonInt(3));
    g = JsonObjectSet(g, "name",    JsonString("Ciało Trolla"));
    g = JsonObjectSet(g, "slot",    JsonString(CHIM_SLOT_TORSO));
    g = JsonObjectSet(g, "trophy",  JsonString("ds_troll_heart"));
    g = JsonObjectSet(g, "trophy_n",JsonString("Serce Trolla"));
    g = JsonObjectSet(g, "flavor",  JsonString("Zieleń trolla przetacza się pod skórą jak żywy porost. Rany zatykają się same — dopóki nie dosięgnie ich ogień."));
    g = JsonObjectSet(g, "fx_desc", JsonString("+ Regeneracja 1 HP/6s  |  − 50% odporności na Ogień"));
    jT = JsonArrayInsert(jT, g);

    g = JsonObject();
    g = JsonObjectSet(g, "id",      JsonInt(4));
    g = JsonObjectSet(g, "name",    JsonString("Łuski Smoka"));
    g = JsonObjectSet(g, "slot",    JsonString(CHIM_SLOT_TORSO));
    g = JsonObjectSet(g, "trophy",  JsonString("ds_dragon_scale"));
    g = JsonObjectSet(g, "trophy_n",JsonString("Łuska Smoka"));
    g = JsonObjectSet(g, "flavor",  JsonString("Łuski wrastają między żebra. Każdy ruch skrzypi jak pancerz kowala — ciężki, niezawodny."));
    g = JsonObjectSet(g, "fx_desc", JsonString("+ 2 Zbroja Naturalna  |  − 1 Siły"));
    jT = JsonArrayInsert(jT, g);

    // ---- ARMS ----

    g = JsonObject();
    g = JsonObjectSet(g, "id",      JsonInt(5));
    g = JsonObjectSet(g, "name",    JsonString("Szpony Ghula"));
    g = JsonObjectSet(g, "slot",    JsonString(CHIM_SLOT_ARMS));
    g = JsonObjectSet(g, "trophy",  JsonString("ds_ghoul_claw"));
    g = JsonObjectSet(g, "trophy_n",JsonString("Szpon Ghula"));
    g = JsonObjectSet(g, "flavor",  JsonString("Zakrzywione kości wysuwają się z opuszków palców o zmierzchu. W dzień chowają się — prawie."));
    g = JsonObjectSet(g, "fx_desc", JsonString("+ 2 do Ataku  |  − 1 Konstytucji"));
    jT = JsonArrayInsert(jT, g);

    g = JsonObject();
    g = JsonObjectSet(g, "id",      JsonInt(6));
    g = JsonObjectSet(g, "name",    JsonString("Jadowity Gruczoł Wiwerna"));
    g = JsonObjectSet(g, "slot",    JsonString(CHIM_SLOT_ARMS));
    g = JsonObjectSet(g, "trophy",  JsonString("ds_wyvern_spine"));
    g = JsonObjectSet(g, "trophy_n",JsonString("Kręgosłup Wiwerna"));
    g = JsonObjectSet(g, "flavor",  JsonString("Gruczoły jadowe sączą się w nadgarstkach. Ukłucie boli jeszcze przez dwa dni."));
    g = JsonObjectSet(g, "fx_desc", JsonString("+ 1k6 trucizny (kwas) do ataku wręcz  |  − 1 Zręczności"));
    jT = JsonArrayInsert(jT, g);

    g = JsonObject();
    g = JsonObjectSet(g, "id",      JsonInt(7));
    g = JsonObjectSet(g, "name",    JsonString("Mięśnie Ogra"));
    g = JsonObjectSet(g, "slot",    JsonString(CHIM_SLOT_ARMS));
    g = JsonObjectSet(g, "trophy",  JsonString("ds_ogre_tendon"));
    g = JsonObjectSet(g, "trophy_n",JsonString("Ścięgno Ogra"));
    g = JsonObjectSet(g, "flavor",  JsonString("Żyły grubieją jak postronki. Siła gromadzi się w ramionach — ciężka, tępa, niezawodna."));
    g = JsonObjectSet(g, "fx_desc", JsonString("+ 2 Siły  |  − 1 Inteligencji"));
    jT = JsonArrayInsert(jT, g);

    // ---- LEGS ----

    g = JsonObject();
    g = JsonObjectSet(g, "id",      JsonInt(8));
    g = JsonObjectSet(g, "name",    JsonString("Ścięgna Pająka Fazowego"));
    g = JsonObjectSet(g, "slot",    JsonString(CHIM_SLOT_LEGS));
    g = JsonObjectSet(g, "trophy",  JsonString("ds_phase_spider_gland"));
    g = JsonObjectSet(g, "trophy_n",JsonString("Gruczoł Pająka Fazowego"));
    g = JsonObjectSet(g, "flavor",  JsonString("Stawy migoczą w przyćmionym świetle. Krok nie zostawia śladu — przez chwilę przynajmniej."));
    g = JsonObjectSet(g, "fx_desc", JsonString("+ 2 Spostrzegawczości i Poszukiwania  |  − 1 Mądrości"));
    jT = JsonArrayInsert(jT, g);

    g = JsonObject();
    g = JsonObjectSet(g, "id",      JsonInt(9));
    g = JsonObjectSet(g, "name",    JsonString("Kości Lodowego Giganta"));
    g = JsonObjectSet(g, "slot",    JsonString(CHIM_SLOT_LEGS));
    g = JsonObjectSet(g, "trophy",  JsonString("ds_frost_giant_bone"));
    g = JsonObjectSet(g, "trophy_n",JsonString("Kość Lodowego Giganta"));
    g = JsonObjectSet(g, "flavor",  JsonString("Kolana trzeszczą jak lód w mrozie. Za to krok ma ciężar lawiny."));
    g = JsonObjectSet(g, "fx_desc", JsonString("+ Odporność na Zimno 10/—  |  − 2 Zręczności"));
    jT = JsonArrayInsert(jT, g);

    g = JsonObject();
    g = JsonObjectSet(g, "id",      JsonInt(10));
    g = JsonObjectSet(g, "name",    JsonString("Esencja Cienia"));
    g = JsonObjectSet(g, "slot",    JsonString(CHIM_SLOT_LEGS));
    g = JsonObjectSet(g, "trophy",  JsonString("ds_shadow_essence"));
    g = JsonObjectSet(g, "trophy_n",JsonString("Esencja Cienia"));
    g = JsonObjectSet(g, "flavor",  JsonString("Twoje nogi rzucają cień nie tam, gdzie powinny. Nocą znikają niemal zupełnie."));
    g = JsonObjectSet(g, "fx_desc", JsonString("+ 4 Ukrywania i Cichego Ruchu  |  − 2 Woli"));
    jT = JsonArrayInsert(jT, g);

    return jT;
}

// Returns the graft entry for the given id, or JsonNull() if not found.
json ChimGetGraftById(int nId)
{
    json jT = ChimBuildGraftTable();
    int nCount = JsonGetLength(jT);
    int i;
    for(i = 0; i < nCount; i++)
    {
        json g = JsonArrayGet(jT, i);
        if(JsonGetInt(JsonObjectGet(g, "id")) == nId)
            return g;
    }
    return JsonNull();
}

// Returns all grafts for a given body slot.
json ChimGetGraftsForSlot(string sSlot)
{
    json jT = ChimBuildGraftTable();
    json jResult = JsonArray();
    int nCount = JsonGetLength(jT);
    int i;
    for(i = 0; i < nCount; i++)
    {
        json g = JsonArrayGet(jT, i);
        if(JsonGetString(JsonObjectGet(g, "slot")) == sSlot)
            jResult = JsonArrayInsert(jResult, g);
    }
    return jResult;
}

// Polish display name for a slot.
string ChimSlotDisplayName(string sSlot)
{
    if(sSlot == CHIM_SLOT_HEAD)  return "Głowa";
    if(sSlot == CHIM_SLOT_TORSO) return "Tułów";
    if(sSlot == CHIM_SLOT_ARMS)  return "Ramiona";
    if(sSlot == CHIM_SLOT_LEGS)  return "Nogi";
    return sSlot;
}

// Label text for one slot button: "Głowa: Oko Bazyliszka" or "Głowa: — pusty —".
string ChimSlotButtonLabel(object oPC, string sSlot)
{
    int nInstalled = ChimGetInstalledGraft(GetObjectUUID(oPC), sSlot);
    string sDisp   = ChimSlotDisplayName(sSlot);
    if(nInstalled == 0)
        return sDisp + ": — pusty —";
    json jGraft = ChimGetGraftById(nInstalled);
    if(JsonGetType(jGraft) == JSON_TYPE_NULL)
        return sDisp + ": — błąd —";
    return sDisp + ": " + JsonGetString(JsonObjectGet(jGraft, "name"));
}
