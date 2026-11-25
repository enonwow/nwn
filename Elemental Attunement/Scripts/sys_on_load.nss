// sys_on_load.nss — module OnModuleLoad hook for Elemental Attunement
#include "sql_eatt"

void main()
{
    EattCreateTables();
}
