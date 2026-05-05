// =============================================================================
// sys_on_load.nss
// =============================================================================
// Module OnModuleLoad event. Initializes Rations campaign tables.
// If you already have a sys_on_load script, merge the body of main() instead.
// =============================================================================

#include "lib_rations"

void main()
{
    RationsCreateTables();
}
