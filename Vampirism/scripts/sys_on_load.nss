#include "lib_vamp"

// Heartbeat loop runs on the module object every 6 s.
// Processes all online vampire PCs without overriding any PC scripts.
void VampHBLoop();

void VampHBLoop()
{
    object oPC = GetFirstPC();
    while(GetIsObjectValid(oPC))
    {
        if(VampIsVampire(oPC))
            VampOnHeartbeat(oPC);
        oPC = GetNextPC();
    }
    DelayCommand(6.0, VampHBLoop());
}

void main()
{
    VampCreateTables();
    // Slight delay so the module finishes loading before first tick
    DelayCommand(2.0, VampHBLoop());
}
