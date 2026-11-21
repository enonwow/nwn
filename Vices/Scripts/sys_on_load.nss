// sys_on_load.nss — OnModuleLoad hook for Vices.
// Creates the campaign DB tables on module start.
#include "lib_vic_def"

void main()
{
    VicCreateTables();
}
