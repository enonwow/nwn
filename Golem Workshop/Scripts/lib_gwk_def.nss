#include "lib_nui"
#include "sql_gwk"

void GwkOpenWorkshop(object oPC);
void GwkSwitchTab(object oPC, int nToken, int nTab);
void GwkFeedForgeSection(object oPC, int nToken);
void GwkFeedGolemSection(object oPC, int nToken);
void GwkAutoRecall(object oPC);

// ----------------------------------------------------------------
// Window / script IDs
// ----------------------------------------------------------------

const string GWK_WINDOW      = "GWK_WINDOW";
const string GWK_EV_SCRIPT   = "lib_gwk_ev";
const string GWK_GRP_CONTENT = "gwk_content";

// ----------------------------------------------------------------
// Bind IDs
// ----------------------------------------------------------------

// Forge section
const string GWK_BIND_TYPE_SEL    = "gwk_type_sel";
const string GWK_BIND_MAT_A_REQ   = "gwk_mat_a_req";
const string GWK_BIND_MAT_A_HAVE  = "gwk_mat_a_have";
const string GWK_BIND_MAT_A_OK    = "gwk_mat_a_ok";
const string GWK_BIND_MAT_B_REQ   = "gwk_mat_b_req";
const string GWK_BIND_MAT_B_HAVE  = "gwk_mat_b_have";
const string GWK_BIND_MAT_B_OK    = "gwk_mat_b_ok";
const string GWK_BIND_MAT_C_REQ   = "gwk_mat_c_req";
const string GWK_BIND_MAT_C_HAVE  = "gwk_mat_c_have";
const string GWK_BIND_MAT_C_OK    = "gwk_mat_c_ok";
const string GWK_BIND_DESC        = "gwk_desc";
const string GWK_BIND_FORGE_ENA   = "gwk_forge_ena";

// Golem section
const string GWK_BIND_GOLEM_NAME  = "gwk_golem_name";
const string GWK_BIND_GOLEM_HP    = "gwk_golem_hp";
const string GWK_BIND_GOLEM_BAR   = "gwk_golem_bar";
const string GWK_BIND_REPAIR_LBL  = "gwk_repair_lbl";
const string GWK_BIND_REPAIR_ENA  = "gwk_repair_ena";
const string GWK_BIND_RECALL_LBL  = "gwk_recall_lbl";

// ----------------------------------------------------------------
// Button IDs
// ----------------------------------------------------------------

const string GWK_BTN_TAB_FORGE = "gwk_btn_tab_forge";
const string GWK_BTN_TAB_GOLEM = "gwk_btn_tab_golem";
const string GWK_BTN_FORGE     = "gwk_btn_forge";
const string GWK_BTN_REPAIR    = "gwk_btn_repair";
const string GWK_BTN_RECALL    = "gwk_btn_recall";
const string GWK_BTN_DESTROY   = "gwk_btn_destroy";

// ----------------------------------------------------------------
// Local vars on PC
// ----------------------------------------------------------------

const string GWK_LVAR_TAB       = "GWK_LVAR_TAB";   // 0=forge, 1=golem

// Internal flags set on the golem creature
const string GWK_GOLEM_FLAG     = "GWK_IS_GOLEM";
const string GWK_GOLEM_TYPE_VAR = "GWK_GOLEM_TYPE";

// ----------------------------------------------------------------
// Golem type constants
// ----------------------------------------------------------------

const int GWK_TYPE_CLAY = 0;
const int GWK_TYPE_IRON = 1;
const int GWK_TYPE_BONE = 2;

// ----------------------------------------------------------------
// Item tag constants (items must exist in the module or HAK)
// ----------------------------------------------------------------

const string GWK_ITEM_CLAY = "gwk_clay";   // Bryła gliny
const string GWK_ITEM_IRON = "gwk_iron";   // Odłamek żelaza
const string GWK_ITEM_BONE = "gwk_bone";   // Fragment kości
const string GWK_ITEM_SOUL = "gwk_soul";   // Fragment duszy

// ----------------------------------------------------------------
// Creature resrefs (replace with HAK blueprints in production)
// ----------------------------------------------------------------

const string GWK_RESREF_CLAY = "nw_golem01";
const string GWK_RESREF_IRON = "nw_golem02";
const string GWK_RESREF_BONE = "nw_skel01";

// ----------------------------------------------------------------
// Window geometry
// ----------------------------------------------------------------

const float GWK_W = 640.0;
const float GWK_H = 480.0;

// ----------------------------------------------------------------
// Type helpers
// ----------------------------------------------------------------

string GwkGetTypeName(int nType)
{
    switch(nType)
    {
        case GWK_TYPE_CLAY: return "Golem Gliniany";
        case GWK_TYPE_IRON: return "Golem Żelazny";
        case GWK_TYPE_BONE: return "Golem Kostny";
    }
    return "Golem";
}

string GwkGetTypeDesc(int nType)
{
    switch(nType)
    {
        case GWK_TYPE_CLAY:
            return "Ulepiony z błota i mrocznej woli, koloss z gliny wlecze się ospale, "
                   "lecz znosi miecz i ogień niczym kamień. Dobry sługa dla tych, "
                   "którzy cenią trwałość ponad prędkość.";
        case GWK_TYPE_IRON:
            return "Skute w ogniu kuźni, żelazne ciało odpiera żelazo i niektóre zaklęcia. "
                   "Wymaga rzadkich składników, lecz pancerz kruszy zęby wrogich mieczy. "
                   "Pieczęć duszy pulsuje w nim mocno.";
        case GWK_TYPE_BONE:
            return "Zszyte z kości poległych, lekkie i szybkie niczym śmierć. "
                   "Kruche jak kryształ — jedno mocne uderzenie może je rozpaść. "
                   "Idealne do szybkich zadań, nie do oblężeń.";
    }
    return "";
}

string GwkGetResRef(int nType)
{
    switch(nType)
    {
        case GWK_TYPE_CLAY: return GWK_RESREF_CLAY;
        case GWK_TYPE_IRON: return GWK_RESREF_IRON;
        case GWK_TYPE_BONE: return GWK_RESREF_BONE;
    }
    return GWK_RESREF_CLAY;
}

int GwkGetMaxHp(int nType)
{
    switch(nType)
    {
        case GWK_TYPE_CLAY: return 60;
        case GWK_TYPE_IRON: return 90;
        case GWK_TYPE_BONE: return 40;
    }
    return 60;
}

// Material costs per type
int GwkGetMatClay(int nType) { return (nType == GWK_TYPE_CLAY) ? 6 : (nType == GWK_TYPE_IRON) ? 3 : 0; }
int GwkGetMatIron(int nType) { return (nType == GWK_TYPE_IRON) ? 4 : 0; }
int GwkGetMatBone(int nType) { return (nType == GWK_TYPE_BONE) ? 6 : 0; }

// Repair costs: half forge cost, minimum 1 if type uses that material
int GwkGetRepairClay(int nType) { int n = GwkGetMatClay(nType); return (n > 1) ? n / 2 : n; }
int GwkGetRepairIron(int nType) { int n = GwkGetMatIron(nType); return (n > 1) ? n / 2 : n; }
int GwkGetRepairBone(int nType) { int n = GwkGetMatBone(nType); return (n > 1) ? n / 2 : n; }

// ----------------------------------------------------------------
// Inventory helpers
// ----------------------------------------------------------------

int GwkCountItem(object oPC, string sTag)
{
    int nCount = 0;
    object oItem = GetFirstItemInInventory(oPC);
    while(GetIsObjectValid(oItem))
    {
        if(GetTag(oItem) == sTag)
            nCount += GetItemStackSize(oItem);
        oItem = GetNextItemInInventory(oPC);
    }
    return nCount;
}

// Removes nAmount items by tag. Returns TRUE on success.
int GwkTakeItem(object oPC, string sTag, int nAmount)
{
    if(nAmount <= 0) return TRUE;
    int nLeft = nAmount;
    object oItem = GetFirstItemInInventory(oPC);
    while(GetIsObjectValid(oItem) && nLeft > 0)
    {
        if(GetTag(oItem) == sTag)
        {
            int nStack = GetItemStackSize(oItem);
            if(nStack <= nLeft)
            {
                nLeft -= nStack;
                DestroyObject(oItem);
            }
            else
            {
                SetItemStackSize(oItem, nStack - nLeft);
                nLeft = 0;
            }
        }
        oItem = GetNextItemInInventory(oPC);
    }
    return nLeft == 0;
}

// Returns the live golem creature assigned as a henchman, or OBJECT_INVALID.
object GwkFindGolem(object oPC)
{
    int i;
    for(i = 1; i <= 5; i++)
    {
        object oH = GetHenchman(oPC, i);
        if(!GetIsObjectValid(oH)) break;
        if(GetLocalInt(oH, GWK_GOLEM_FLAG)) return oH;
    }
    return OBJECT_INVALID;
}
