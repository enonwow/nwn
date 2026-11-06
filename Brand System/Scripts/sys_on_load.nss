// sys_on_load.nss -- Module OnLoad hook for Brand System
// Hooks into: Module OnLoad event
#include "lib_brand_def"

void main()
{
    BrandCreateTables();
}
