// =============================================================================
// sys_on_enter.nss  (War Standard)
// =============================================================================
// Module OnClientEnter hook.  Gives the PC a War Standard Kit if they don't
// have one yet, and immediately applies buffs if they enter near an active
// standard.  Call from your existing OnClientEnter script:
//
//   #include "lib_wst"
//   // ...
//   WstOnClientEnter(GetEnteringObject());
// =============================================================================

#include "lib_wst"

void WstOnClientEnter(object oPC)
{
    if(!GetIsPC(oPC) || GetIsDM(oPC)) return;

    // Give a War Standard Kit on first login (one-time).
    // The kit is a usable item (OnActivateItem -> WstOpenOverview).
    if(!GetItemPossessedBy(oPC, WST_TAG_KIT) &&
       !GetLocalInt(GetModule(), "WST_KIT_" + GetObjectUUID(oPC)))
    {
        CreateItemOnObject(WST_TAG_KIT, oPC);
        SetLocalInt(GetModule(), "WST_KIT_" + GetObjectUUID(oPC), 1);
    }

    // Trigger an immediate buff check so the PC isn't unbuffed for 6 s after entering.
    DelayCommand(2.0, WstTickBuffs());
}

void main()
{
    WstOnClientEnter(GetEnteringObject());
}
