// test_plg_dm.nss - placeable OnUsed for DM panel
// Only DMs can open the panel.
// Hook: placeable OnUsed (e.g. lever with tag plg_dm_panel)

#include "lib_plg_dm"

void main()
{
    object oUser = GetLastUsedBy();
    if(!GetIsDM(oUser))
    {
        SendMessageToPC(oUser, "Only Dungeon Masters can open this panel.");
        return;
    }
    CreatePlgDmWindow(oUser);
}
