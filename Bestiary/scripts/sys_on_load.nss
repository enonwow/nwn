// sys_on_load.nss — OnModuleLoad: initialise Codex Bestiarum tables
// Hook: Module Properties -> Events -> OnModuleLoad
#include "sql_bst"

void main()
{
    BstCreateTables();
}
