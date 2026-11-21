// sys_on_load.nss — module OnModuleLoad: initialise the Chaos Surge DB schema.
// Hook: Module → Events → OnModuleLoad

#include "lib_chaos_def"

void main()
{
    ChaosCreateTables();
}
