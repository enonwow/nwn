// sys_on_load.nss — Module OnModuleLoad hook for Epitafium
// Hook: Module → Events → OnModuleLoad → "sys_on_load"

#include "lib_tomb"

void main()
{
    TombCreateTables();
    TombDeleteExpired();
    TombRespawnAll();
}
