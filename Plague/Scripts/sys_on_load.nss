// sys_on_load.nss - module OnModuleLoad event
// Hook: Module Properties -> Events -> OnModuleLoad

#include "sql_plg_events"

void main()
{
    PlgCreateTables();
    PlgCreateEventsTable();
}
