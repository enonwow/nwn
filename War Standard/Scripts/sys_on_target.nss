// =============================================================================
// sys_on_target.nss  (War Standard)
// =============================================================================
// Module OnActivateItem hook.  Called when the player uses the War Standard
// Kit item from their inventory.  Opens the overview panel.
//
// Wire in your existing OnActivateItem script:
//
//   #include "lib_wst"
//   // ...
//   if(GetTag(GetItemActivated()) == WST_TAG_KIT)
//       WstOpenOverview(GetItemActivator());
// =============================================================================

#include "lib_wst"

void main()
{
    object oItem = GetItemActivated();
    if(GetTag(oItem) != WST_TAG_KIT) return;

    WstOpenOverview(GetItemActivator());
}
