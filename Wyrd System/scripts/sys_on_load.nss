// sys_on_load.nss — Wyrd System module initialization.
// Hook as OnModuleLoad (or call WyrdDbInit() from an existing OnModuleLoad).
#include "lib_wyrd"

void main()
{
    WyrdDbInit();
}
