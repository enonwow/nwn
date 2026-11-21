#include "lib_bfire"

// Place this script in the OnUsed slot of any placeable tagged "bonfire_XXXX".
// Optional local vars on the placeable (set in toolset):
//   BFIRE_START_LIT   (int)    1 = bonfire starts already lit
//   BFIRE_DISPLAY_NAME (string) overrides the Name field shown in UI

void main()
{
    object oPC      = GetLastUsedBy();
    object oBonfire = OBJECT_SELF;

    if(!GetIsPC(oPC)) return;

    // Auto-light bonfires that were configured to start lit but haven't been
    // registered yet (e.g. first server start after the tables were created).
    string sTag = GetTag(oBonfire);
    if(!BfireIsLit(sTag) && GetLocalInt(oBonfire, BFIRE_OVAR_START_LIT))
    {
        string sArea = GetName(GetArea(oBonfire));
        BfireLightBonfire(sTag, sArea, "Pradawna Siła");
    }

    BfireOpenWindow(oPC, oBonfire);
}
