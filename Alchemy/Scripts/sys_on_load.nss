// sys_on_load.nss
// Module OnModuleLoad — no persistent tables needed at module scope;
// per-PC tables are created on first enter (sys_on_enter.nss).
// Sets the module NUI event script so lib_alch_ev.nss receives events.
#include "lib_alch_def"

void main()
{
    SetEventScript(GetModule(), EVENT_SCRIPT_MODULE_ON_NUI_EVENT, ALCH_EV_SCRIPT);
}
