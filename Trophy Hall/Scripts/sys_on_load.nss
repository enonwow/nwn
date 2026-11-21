// sys_on_load.nss — Trophy Hall: module init
// Hook: OnModuleLoad (or add to existing OnModuleLoad via ExecuteScript)

#include "sql_trph"

void main()
{
    TrphCreateTables();
}
