// sys_on_load.nss — module OnModuleLoad hook.
//   Creates database tables. Safe to run multiple times (idempotent).

#include "lib_san_def"

void main()
{
    SanCreateTables();
}
