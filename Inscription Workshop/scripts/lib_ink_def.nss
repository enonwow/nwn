#include "sql_ink"

// ----------------------------------------------------------------
// Window & event identifiers
// ----------------------------------------------------------------

const string INK_WINDOW        = "INK_WINDOW";
const string INK_EV_SCRIPT     = "lib_ink_ev";
const string INK_GRP_SWAP      = "INK_GRP_SWAP";
const string INK_WIN_GEOM      = "ink_win_geom";

// ----------------------------------------------------------------
// Bind names — Grimoire tab
// ----------------------------------------------------------------

const string INK_BIND_FORM_NAME    = "ink_form_name";
const string INK_BIND_FORM_DC_TXT  = "ink_form_dc_txt";
const string INK_BIND_FORM_STATUS  = "ink_form_status";
const string INK_BIND_FORM_ENC     = "ink_form_enc";
const string INK_BIND_FORM_COLOR   = "ink_form_color";

// ----------------------------------------------------------------
// Bind names — Workshop tab
// ----------------------------------------------------------------

const string INK_BIND_WS_TITLE     = "ink_ws_title";
const string INK_BIND_WS_DESC      = "ink_ws_desc";
const string INK_BIND_WS_DC        = "ink_ws_dc";
const string INK_BIND_WS_SKILL     = "ink_ws_skill";
const string INK_BIND_WS_RESULT    = "ink_ws_result";
const string INK_BIND_WS_INSCR_EN  = "ink_ws_inscr_en";
const string INK_BIND_COMP_NAME    = "ink_comp_name";
const string INK_BIND_COMP_HAVE    = "ink_comp_have";
const string INK_BIND_COMP_COLOR   = "ink_comp_color";

// ----------------------------------------------------------------
// Bind names — History tab
// ----------------------------------------------------------------

const string INK_BIND_HIST_TEXT    = "ink_hist_text";
const string INK_BIND_HIST_COLOR   = "ink_hist_color";

// ----------------------------------------------------------------
// Button identifiers
// ----------------------------------------------------------------

const string INK_BTN_CLOSE         = "ink_btn_close";
const string INK_BTN_TAB_GRIMOIRE  = "ink_btn_tab_g";
const string INK_BTN_TAB_WORKSHOP  = "ink_btn_tab_w";
const string INK_BTN_TAB_HISTORY   = "ink_btn_tab_h";
const string INK_BTN_FORM_ROW      = "ink_btn_form_row";
const string INK_BTN_INSCRIBE      = "ink_btn_inscribe";
const string INK_BTN_WS_BACK       = "ink_btn_ws_back";

// ----------------------------------------------------------------
// PC local variables
// ----------------------------------------------------------------

const string INK_LVAR_SEL_FORM     = "INK_SEL_FORMULA";

// ----------------------------------------------------------------
// Layout dimensions
// ----------------------------------------------------------------

const float INK_W                  = 680.0;
const float INK_H                  = 500.0;

// ----------------------------------------------------------------
// Skill used for the inscription check (SKILL_SPELLCRAFT = 25)
// ----------------------------------------------------------------

const int INK_SKILL_ID             = SKILL_SPELLCRAFT;

// ----------------------------------------------------------------
// Formula constants
// ----------------------------------------------------------------

const int INK_FORMULA_COUNT        = 8;
const int INK_FORM_FIRST_ADV       = 5;   // IDs >= 5 require discovery

const int INK_FORM_CLARITY         = 1;
const int INK_FORM_PROTECTION      = 2;
const int INK_FORM_FEAR            = 3;
const int INK_FORM_ACID            = 4;
const int INK_FORM_VAMPIRIC        = 5;
const int INK_FORM_ZONE_TRUTH      = 6;
const int INK_FORM_CURSE           = 7;
const int INK_FORM_DARKNESS        = 8;

// ----------------------------------------------------------------
// Component item tags
// ----------------------------------------------------------------

const string INK_TAG_PARCHMENT     = "ink_parchment";
const string INK_TAG_INK_BLUE      = "ink_vial_blue";
const string INK_TAG_INK_RED       = "ink_vial_red";
const string INK_TAG_INK_BLACK     = "ink_vial_black";
const string INK_TAG_BONE_POWDER   = "ink_bone_powder";
const string INK_TAG_MOONSTONE     = "ink_moonstone";
const string INK_TAG_BLOOD_VIAL    = "ink_blood_vial";

// Tag on items that teach advanced formulas when used/activated
const string INK_TAG_TOME          = "ink_spell_tome";
const string INK_VAR_TOME_ID       = "INK_TOME_FORMULA";

// ----------------------------------------------------------------
// Formula data: names
// ----------------------------------------------------------------

string InkGetFormulaName(int nId)
{
    switch(nId)
    {
        case INK_FORM_CLARITY:    return "Mgiełka Umysłu";
        case INK_FORM_PROTECTION: return "Pieczęć Ochronna";
        case INK_FORM_FEAR:       return "Zaklęcie Grozy";
        case INK_FORM_ACID:       return "Kwas Melfego";
        case INK_FORM_VAMPIRIC:   return "Dotyk Wampira";
        case INK_FORM_ZONE_TRUTH: return "Pieczęć Prawdy";
        case INK_FORM_CURSE:      return "Klątwą Objęty";
        case INK_FORM_DARKNESS:   return "Szept Ciemności";
    }
    return "Nieznana formuła";
}

// ----------------------------------------------------------------
// Formula data: flavor descriptions (player-facing Polish text)
// ----------------------------------------------------------------

string InkGetFormulaDesc(int nId)
{
    switch(nId)
    {
        case INK_FORM_CLARITY:
            return "Zwój oczyszcza umysł z mgły magicznej. Prosty przepis — podstawa każdego skryptorium.";
        case INK_FORM_PROTECTION:
            return "Starożytna pieczęć odpędza istoty podłe. Kamień księżycowy musi być starty na proch, zanim atrament wsiąknie w pergamin.";
        case INK_FORM_FEAR:
            return "Słowa wypisane prochem kości przynoszą paniczny strach. Popularne wśród łowców głów i egzorcystów.";
        case INK_FORM_ACID:
            return "Receptura wielkiego Melfego — szafirowy i obsydianowy atrament splecione w jedno zaklęcie kwasowe.";
        case INK_FORM_VAMPIRIC:
            return "Zakazany zapis wysysający vitum z ofiary. Krew i proch kości są wymagane — i odwaga kaligrafisty.";
        case INK_FORM_ZONE_TRUTH:
            return "Starożytna pieczęć wymuszająca prawdomówność. Rzadko widywana poza skarbnicami Inkwizycji.";
        case INK_FORM_CURSE:
            return "Najcięższa z klątw utrwalona na pergaminie. Mówią, że wielu skrybów zwariowało przy jej przepisywaniu.";
        case INK_FORM_DARKNESS:
            return "Zaklęcie ciemności szeptane w nocy. Obsydianowy atrament pochłania samo światło pergaminu.";
    }
    return "";
}

// ----------------------------------------------------------------
// Formula data: Spellcraft DC
// ----------------------------------------------------------------

int InkGetFormulaDC(int nId)
{
    switch(nId)
    {
        case INK_FORM_CLARITY:    return 10;
        case INK_FORM_PROTECTION: return 12;
        case INK_FORM_FEAR:       return 14;
        case INK_FORM_ACID:       return 15;
        case INK_FORM_VAMPIRIC:   return 18;
        case INK_FORM_ZONE_TRUTH: return 16;
        case INK_FORM_CURSE:      return 20;
        case INK_FORM_DARKNESS:   return 13;
    }
    return 99;
}

// ----------------------------------------------------------------
// Formula data: scroll resrefs to create on success
// ----------------------------------------------------------------

string InkGetFormulaScrollResref(int nId)
{
    switch(nId)
    {
        case INK_FORM_CLARITY:    return "nw_sc_clrcomp";
        case INK_FORM_PROTECTION: return "nw_sc_protcevl";
        case INK_FORM_FEAR:       return "nw_sc_causfe";
        case INK_FORM_ACID:       return "nw_sc_melf";
        case INK_FORM_VAMPIRIC:   return "nw_sc_vamptouc";
        case INK_FORM_ZONE_TRUTH: return "nw_sc_dominate";
        case INK_FORM_CURSE:      return "nw_sc_bestwo";
        case INK_FORM_DARKNESS:   return "nw_sc_darkns";
    }
    return "";
}

// ----------------------------------------------------------------
// Formula data: component list
// Returns JsonArray of {tag, qty, label}
// ----------------------------------------------------------------

json InkGetFormulaComponents(int nId)
{
    json jComps = JsonArray();

    // Parchment is always required
    json jParch = JsonObject();
    jParch = JsonObjectSet(jParch, "tag",   JsonString(INK_TAG_PARCHMENT));
    jParch = JsonObjectSet(jParch, "qty",   JsonInt(1));
    jParch = JsonObjectSet(jParch, "label", JsonString("Pergamin"));
    jComps = JsonArrayInsert(jComps, jParch);

    switch(nId)
    {
        case INK_FORM_CLARITY:
        {
            json j = JsonObject();
            j = JsonObjectSet(j, "tag",   JsonString(INK_TAG_INK_BLUE));
            j = JsonObjectSet(j, "qty",   JsonInt(1));
            j = JsonObjectSet(j, "label", JsonString("Szafirowy atrament"));
            jComps = JsonArrayInsert(jComps, j);
            break;
        }
        case INK_FORM_PROTECTION:
        {
            json j = JsonObject();
            j = JsonObjectSet(j, "tag",   JsonString(INK_TAG_INK_RED));
            j = JsonObjectSet(j, "qty",   JsonInt(1));
            j = JsonObjectSet(j, "label", JsonString("Rubinowy atrament"));
            jComps = JsonArrayInsert(jComps, j);
            j = JsonObject();
            j = JsonObjectSet(j, "tag",   JsonString(INK_TAG_MOONSTONE));
            j = JsonObjectSet(j, "qty",   JsonInt(1));
            j = JsonObjectSet(j, "label", JsonString("Kamień księżycowy"));
            jComps = JsonArrayInsert(jComps, j);
            break;
        }
        case INK_FORM_FEAR:
        {
            json j = JsonObject();
            j = JsonObjectSet(j, "tag",   JsonString(INK_TAG_INK_BLACK));
            j = JsonObjectSet(j, "qty",   JsonInt(1));
            j = JsonObjectSet(j, "label", JsonString("Obsydianowy atrament"));
            jComps = JsonArrayInsert(jComps, j);
            j = JsonObject();
            j = JsonObjectSet(j, "tag",   JsonString(INK_TAG_BONE_POWDER));
            j = JsonObjectSet(j, "qty",   JsonInt(1));
            j = JsonObjectSet(j, "label", JsonString("Proch kości"));
            jComps = JsonArrayInsert(jComps, j);
            break;
        }
        case INK_FORM_ACID:
        {
            json j = JsonObject();
            j = JsonObjectSet(j, "tag",   JsonString(INK_TAG_INK_BLUE));
            j = JsonObjectSet(j, "qty",   JsonInt(1));
            j = JsonObjectSet(j, "label", JsonString("Szafirowy atrament"));
            jComps = JsonArrayInsert(jComps, j);
            j = JsonObject();
            j = JsonObjectSet(j, "tag",   JsonString(INK_TAG_INK_BLACK));
            j = JsonObjectSet(j, "qty",   JsonInt(1));
            j = JsonObjectSet(j, "label", JsonString("Obsydianowy atrament"));
            jComps = JsonArrayInsert(jComps, j);
            break;
        }
        case INK_FORM_VAMPIRIC:
        {
            json j = JsonObject();
            j = JsonObjectSet(j, "tag",   JsonString(INK_TAG_BLOOD_VIAL));
            j = JsonObjectSet(j, "qty",   JsonInt(1));
            j = JsonObjectSet(j, "label", JsonString("Fiolka krwi"));
            jComps = JsonArrayInsert(jComps, j);
            j = JsonObject();
            j = JsonObjectSet(j, "tag",   JsonString(INK_TAG_BONE_POWDER));
            j = JsonObjectSet(j, "qty",   JsonInt(2));
            j = JsonObjectSet(j, "label", JsonString("Proch kości x2"));
            jComps = JsonArrayInsert(jComps, j);
            break;
        }
        case INK_FORM_ZONE_TRUTH:
        {
            json j = JsonObject();
            j = JsonObjectSet(j, "tag",   JsonString(INK_TAG_INK_BLUE));
            j = JsonObjectSet(j, "qty",   JsonInt(2));
            j = JsonObjectSet(j, "label", JsonString("Szafirowy atrament x2"));
            jComps = JsonArrayInsert(jComps, j);
            j = JsonObject();
            j = JsonObjectSet(j, "tag",   JsonString(INK_TAG_MOONSTONE));
            j = JsonObjectSet(j, "qty",   JsonInt(1));
            j = JsonObjectSet(j, "label", JsonString("Kamień księżycowy"));
            jComps = JsonArrayInsert(jComps, j);
            break;
        }
        case INK_FORM_CURSE:
        {
            json j = JsonObject();
            j = JsonObjectSet(j, "tag",   JsonString(INK_TAG_BLOOD_VIAL));
            j = JsonObjectSet(j, "qty",   JsonInt(1));
            j = JsonObjectSet(j, "label", JsonString("Fiolka krwi"));
            jComps = JsonArrayInsert(jComps, j);
            j = JsonObject();
            j = JsonObjectSet(j, "tag",   JsonString(INK_TAG_BONE_POWDER));
            j = JsonObjectSet(j, "qty",   JsonInt(1));
            j = JsonObjectSet(j, "label", JsonString("Proch kości"));
            jComps = JsonArrayInsert(jComps, j);
            j = JsonObject();
            j = JsonObjectSet(j, "tag",   JsonString(INK_TAG_INK_BLACK));
            j = JsonObjectSet(j, "qty",   JsonInt(2));
            j = JsonObjectSet(j, "label", JsonString("Obsydianowy atrament x2"));
            jComps = JsonArrayInsert(jComps, j);
            break;
        }
        case INK_FORM_DARKNESS:
        {
            json j = JsonObject();
            j = JsonObjectSet(j, "tag",   JsonString(INK_TAG_INK_BLACK));
            j = JsonObjectSet(j, "qty",   JsonInt(2));
            j = JsonObjectSet(j, "label", JsonString("Obsydianowy atrament x2"));
            jComps = JsonArrayInsert(jComps, j);
            break;
        }
    }
    return jComps;
}

int InkIsFormulaAdvanced(int nId)
{
    return (nId >= INK_FORM_FIRST_ADV);
}
