// sys_on_load.nss — initialise the Homunculus module on module load
#include "sql_hom"

void main()
{
    HomCreateTables();
}
