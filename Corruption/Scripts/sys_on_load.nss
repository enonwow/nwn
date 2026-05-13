// sys_on_load.nss  –  Corruption: OnModuleLoad hook
// Call this from the module's OnModuleLoad event script.

#include "lib_cor_def"

void main()
{
    CorCreateTables();
}
