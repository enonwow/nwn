#include "lib_grim"

// OnUsed script for a test placeable "Stół Badań" (Research Desk).
//
// Gives the PC a sample set of fragments so they can try the Grimoire immediately,
// then opens the Grimoire window.  In production the fragments come from world drops;
// the CreateItemOnObject calls below require the HAK items to exist (see INTEGRATION.md).

void GrimGiveTestFragment(object oPC, int nType, int nTier, int nQty)
{
    string sTag    = GrimFragTag(nType, nTier);
    string sResref = sTag;          // resref matches tag by convention in the HAK
    object oItem   = CreateItemOnObject(sResref, oPC, nQty);
    if(GetIsObjectValid(oItem))
    {
        SetTag(oItem, sTag);
        SetName(oItem, GrimFragName(nType, nTier));
    }
    else
    {
        // HAK item not present; warn once and continue
        SendMessageToPC(oPC, "[Grimuar] UWAGA: brak resref '" + sResref + "' w HAK — dodaj go w toolsecie.");
    }
}

void main()
{
    object oPC = GetLastUsedBy();
    if(!GetIsPC(oPC)) return;

    // Give enough fragments for recipe 1 (ignis1 + ignis1) and recipe 6 (ignis2 + vita1)
    GrimGiveTestFragment(oPC, GRIM_TYPE_IGNIS,  1, 2);  // two Minor Ignis → recipe 1
    GrimGiveTestFragment(oPC, GRIM_TYPE_IGNIS,  2, 1);  // Major Ignis
    GrimGiveTestFragment(oPC, GRIM_TYPE_VITA,   1, 1);  // Minor Vita  → recipe 6 with ignis2
    GrimGiveTestFragment(oPC, GRIM_TYPE_GLACIES, 1, 2); // two Minor Glacies → recipe 2
    GrimGiveTestFragment(oPC, GRIM_TYPE_UMBRA,  1, 1);  // Minor Umbra (recipe 3 needs another)
    GrimGiveTestFragment(oPC, GRIM_TYPE_VOID,   1, 2);  // two Minor Void → recipe 4

    GrimOpenWindow(oPC);
}
