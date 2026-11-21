#include "lib_ln"

// Placeable OnUsed script for a Ley Node.
//
// Builder setup:
//   Tag       — any unique string; becomes the node's DB key.
//   Name      — displayed in the NUI panel (e.g. "Kamień Mgły").
//   Local Int "LN_TYPE" — 1 Arcane, 2 Martial, 3 Vital, 4 Shadow.
//   OnUsed    — set to this script ("test_ln").
void main()
{
    object oPC   = GetLastUsedBy();
    object oSelf = OBJECT_SELF;
    if(!GetIsPC(oPC)) return;

    LnEnsureNodeRegistered(oSelf);

    // Pin the selected tag so the detail pane opens on this node.
    SetLocalString(oPC, LN_LVAR_SEL_TAG, GetTag(oSelf));

    LnOpenPanel(oPC);
}
