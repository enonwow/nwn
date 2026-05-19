#include "lib_herb"

// OnUsed script for herb-node placeables and the herbalist's journal stand.
//
// Herb node setup (in toolset):
//   Tag    — unique per node instance (used as SQL primary key)
//   Local Int "HERB_TYPE" = 1..8  (matches HERB_* constants)
//
// Journal stand: same script, HERB_TYPE = 0 or omitted -> opens journal only.

void main()
{
    object oPC   = GetLastUsedBy();
    object oSelf = OBJECT_SELF;

    if(!GetIsPC(oPC)) return;

    int nType = GetLocalInt(oSelf, "HERB_TYPE");

    if(nType < 1 || nType > HERB_TYPE_COUNT)
    {
        // Acts as a pure journal stand
        OpenJournalWindow(oPC);
        return;
    }

    // Register node in SQL on first use (idempotent)
    HerbNodeEnsure(GetTag(oSelf), nType, HERB_NODE_CHARGES);
    OpenHarvestWindow(oPC, oSelf);
}
