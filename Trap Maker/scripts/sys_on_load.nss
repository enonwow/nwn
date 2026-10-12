#include "lib_trap_def"

void main()
{
    TrapCreateTables();
    // Purge placed-trap entries older than 24h (safety net for unloaded areas)
    TrapPurgeStale(24);
}
