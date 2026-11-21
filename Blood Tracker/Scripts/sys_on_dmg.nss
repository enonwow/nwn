#include "lib_btrk"

// Assign this script as the OnDamaged event of any NPC whose blood trails
// you want tracked. For PCs the module heartbeat handles trail dropping;
// this script is only needed for non-PC creatures.
// With NWNX_Events you can register it globally — see INTEGRATION.md.

void main()
{
    object oCreature = OBJECT_SELF;
    if(GetIsPC(oCreature)) return;  // PCs handled by sys_on_hb

    int nDmg = GetTotalDamageDealt();
    BtrkDropTrail(oCreature, nDmg);
}
