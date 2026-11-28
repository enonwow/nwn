#include "lib_mrk"

// Hook into the module's OnCreatureDeath event.
// IMPORTANT: Call this from your existing module OnCreatureDeath handler,
// or set this as the OnCreatureDeath script if no other handler exists.
//
//   ExecuteScript("sys_on_death", OBJECT_SELF); // from your existing handler

void main()
{
    object oVictim = OBJECT_SELF;
    object oKiller = GetLastKiller();

    // Walk the killer up to the actual PC (handles henchman assists etc.)
    if(!GetIsPC(oKiller))
    {
        object oMaster = GetMaster(oKiller);
        if(GetIsObjectValid(oMaster) && GetIsPC(oMaster))
            oKiller = oMaster;
        else
            return;
    }

    MrkOnCreatureDeath(oKiller, oVictim);
}
