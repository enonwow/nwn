// sys_on_load.nss - module OnModuleLoad
// Hook: Module Properties -> Events -> OnModuleLoad

#include "sql_rit"

void main()
{
    RitCreateTables();
}
