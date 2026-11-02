// sys_on_enter.nss — Watchfire: OnClientEnter hook

#include "lib_wf_def"

void main()
{
    object oPC = GetEnteringObject();
    if(!GetIsPC(oPC)) return;

    // Ensure the session table exists for this character
    WfCreateTables(oPC);
}
