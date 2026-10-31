#include "lib_sleg_def"

// OnDeath for any NPC — increment kill counter on the killer if they are a PC.
void main()
{
    object oKiller = GetLastKiller();

    // Walk up assist chain to find the actual PC
    if(!GetIsPC(oKiller))
        oKiller = GetMaster(oKiller);
    if(!GetIsPC(oKiller)) return;

    SetLocalInt(oKiller, SLEG_LVAR_KILLS, GetLocalInt(oKiller, SLEG_LVAR_KILLS) + 1);
}
