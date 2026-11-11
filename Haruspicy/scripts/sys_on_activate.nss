#include "lib_haru"

// Module OnActivateItem hook.
// Called when a PC right-clicks and "Uses" an item from inventory.
// Items with tag HARU_KIT_TAG enter targeting mode so the PC can
// point at a readable corpse.

const string HARU_KIT_TAG = "haru_kit";

void main()
{
    object oItem = GetItemActivated();
    object oPC   = GetItemActivator();

    if(!GetIsPC(oPC)) return;
    if(GetTag(oItem) != HARU_KIT_TAG) return;

    SetLocalInt(oPC, HARU_LVAR_TARGETING, 1);
    EnterTargetingMode(oPC, OBJECT_TYPE_CREATURE | OBJECT_TYPE_PLACEABLE);
    SendMessageToPC(oPC, "[Haruspika] Wskaź zwloki istoty do odczytu.");
}
