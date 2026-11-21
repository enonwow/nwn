#include "lib_sea"

void main()
{
    SeaTick();

    // Reschedule the next tick; runs on the module object so it never dies
    DelayCommand(SEA_TICK_INTERVAL, ExecuteScript("sea_hb_tick", GetModule()));
}
