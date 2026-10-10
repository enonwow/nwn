#include "sql_astr"

// OnModuleLoad — initialises persistent SQL schema for astral logs.
void main()
{
    AstrCreateTables();
}
