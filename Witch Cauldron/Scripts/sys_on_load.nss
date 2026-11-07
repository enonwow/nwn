// sys_on_load.nss — Witch Cauldron: module OnModuleLoad hook
#include "sql_wca"

void main()
{
    WcaCreateTables();
}
