#include "lib_mia"

// Module OnActivateItem.
// Assign this to a DM tool item (resref: mia_dm_tool) to open the management panel.
// Merge into your existing sys_on_activate if one already exists.
void main()
{
    object oItem = GetItemActivated();
    object oPC   = GetItemActivator();

    if(GetResRef(oItem) == "mia_dm_tool")
    {
        if(!GetIsDM(oPC))
        {
            SendMessageToPC(oPC, "[Opar] Ten przedmiot jest przeznaczony tylko dla MG.");
            return;
        }
        MiaCreateDmPanel(oPC);
    }
}
