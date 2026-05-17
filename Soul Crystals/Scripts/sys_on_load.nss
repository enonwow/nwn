// sys_on_load.nss — Soul Crystals: module OnModuleLoad hook.
// Creates persistent SQLite tables for the soc campaign database.

#include "lib_soc_def"

void main()
{
    SocCreateTables();
}
