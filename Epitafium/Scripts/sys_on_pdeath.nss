// sys_on_pdeath.nss — Module OnPlayerDeath hook for Epitafium
// Hook: Module → Events → OnPlayerDeath → "sys_on_pdeath"
//
// Captures the death location, attempts to detect the killer's name,
// then opens the epitaph write window after a short delay so the
// player has time to process the death screen.

#include "lib_tomb"

void TombOnDeath(object oPC)
{
    // Store death location before the body is moved.
    object oArea  = GetArea(oPC);
    vector vPos   = GetPosition(oPC);

    SetLocalString(oPC, TOMB_LVAR_AREA,  GetTag(oArea));
    SetLocalFloat (oPC, TOMB_LVAR_POS_X, vPos.x);
    SetLocalFloat (oPC, TOMB_LVAR_POS_Y, vPos.y);
    SetLocalFloat (oPC, TOMB_LVAR_POS_Z, vPos.z);

    // Try to name the killer. GetLastKiller() is PC-level, but
    // many servers store it via SetLocalObject in the PC's OnDeath.
    // We fall back to a generic string if unavailable.
    object oKiller = GetLocalObject(oPC, "TOMB_KILLER");
    string sCause  = "poległ(a) w walce";
    if(GetIsObjectValid(oKiller))
    {
        if(GetIsPC(oKiller))
            sCause = "poległ(a) z ręki " + GetName(oKiller);
        else
            sCause = "zabity/a przez " + GetName(oKiller);
        DeleteLocalObject(oPC, "TOMB_KILLER");
    }
    SetLocalString(oPC, TOMB_LVAR_CAUSE, sCause);

    // Delay to let the death screen settle before opening NUI.
    DelayCommand(4.0, TombCreateWriteWindow(oPC));
}

void main()
{
    object oPC = GetLastPlayerDied();
    if(!GetIsObjectValid(oPC)) return;
    if(!GetIsPC(oPC) || GetIsDM(oPC)) return;

    TombOnDeath(oPC);
}
