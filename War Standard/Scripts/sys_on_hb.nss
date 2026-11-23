// =============================================================================
// sys_on_hb.nss  (War Standard)
// =============================================================================
// Module OnHeartbeat hook (fires every 6 seconds).
// Routes to WstTickBuffs() which applies or removes standard buffs for all
// PCs, persists current HP of live standards, and prunes expired ones.
//
// Wire up in your existing OnHeartbeat script:
//
//   #include "lib_wst"
//   // ...
//   WstTickBuffs();
// =============================================================================

#include "lib_wst"

void main()
{
    WstTickBuffs();
}
