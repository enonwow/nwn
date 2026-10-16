// =============================================================================
// sys_on_load.nss
// =============================================================================
// Module OnModuleLoad event. Creates Wanted system campaign tables.
// Merge into your existing OnModuleLoad handler if you have one.
// =============================================================================

#include "lib_wnt"

void main()
{
    WantedCreateTables();
}
