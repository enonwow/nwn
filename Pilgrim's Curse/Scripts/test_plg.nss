#include "lib_plg"

// OnUsed script for both shrine placeables and the status-book placeable.
// Attach to:
//   • placeables with tag "plg_shrine_*"  → shrine interaction
//   • placeable with tag "plg_catharsis"  → catharsis altar
//   • any other placeable                 → opens status window
void main()
{
    object oPC = GetLastUsedBy();
    if(!GetIsPC(oPC)) return;

    string sTag = GetTag(OBJECT_SELF);

    if(GetStringLeft(sTag, 11) == "plg_shrine_" || sTag == PLG_CATHARSIS_TAG)
    {
        PlgHandleShrine(oPC, OBJECT_SELF);
        return;
    }

    PlgOpenWindow(oPC);
}
