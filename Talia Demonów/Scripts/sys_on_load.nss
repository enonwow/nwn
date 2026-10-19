#include "sql_tarot"

// Called from the module's OnModuleLoad event.
// Initialise the tarot database schema (idempotent).

void main()
{
    TarotInitDB();
}
