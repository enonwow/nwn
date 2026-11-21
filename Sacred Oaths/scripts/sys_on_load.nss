// sys_on_load.nss — module OnModuleLoad: initialise Sacred Oaths DB

#include "lib_oath_def"

void main()
{
    OathCreateTables();
}
