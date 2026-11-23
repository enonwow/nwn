// =============================================================================
// sys_on_load.nss  (War Standard)
// =============================================================================
// Module OnLoad hook.  Creates DB tables and restores any standards that
// survived a server restart.  Call this from your existing OnLoad script:
//
//   #include "lib_wst"
//   // ...
//   WstCreateTables();
//   WstRestoreFromDb();
// =============================================================================

#include "lib_wst"

void main()
{
    WstCreateTables();
    WstRestoreFromDb();
}
