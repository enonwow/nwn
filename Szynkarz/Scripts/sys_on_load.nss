// sys_on_load.nss — Szynkarz module init
// Hook: Module Properties -> Events -> OnModuleLoad

#include "lib_syn_def"

void main()
{
    SynCreateTables();
}
