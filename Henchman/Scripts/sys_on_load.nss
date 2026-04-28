// sys_on_load.nss
// OnModuleLoad - henchman system initialization
#include "lib_hench_def"

void main()
{
    HenchCreateTable();
    HenchUiCreateTable();
    HenchScanRoster();
    SetMaxHenchmen(1);
    ExecuteScript(HENCH_SCRIPT_SUBSCRIBE, OBJECT_SELF);
}
