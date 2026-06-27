#include "lib_sea_def"

void main()
{
    SeaCreateTables();

    // Guard against double-start (e.g. module reload)
    if (GetLocalInt(GetModule(), SEA_LVAR_TICKING)) return;
    SetLocalInt(GetModule(), SEA_LVAR_TICKING, 1);

    // Kick off the recurring weather tick
    DelayCommand(SEA_TICK_INTERVAL, ExecuteScript("sea_hb_tick", GetModule()));
}
