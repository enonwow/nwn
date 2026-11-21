// sys_on_load.nss — Necromancy: module OnModuleLoad hook
// Creates persistent database tables if they don't exist yet.

#include "lib_nec_def"

void main()
{
    NecCreateTables();
}
