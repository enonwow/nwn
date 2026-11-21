// sys_on_enter.nss — Wyrd System: restore persistent wyrd when PC enters.
// Hook as OnClientEnter (or call WyrdOnClientEnter() from an existing handler).
#include "lib_wyrd"

void WyrdOnClientEnter()
{
    object oPC = GetEnteringObject();
    if(!GetIsPC(oPC) || GetIsDMPossessed(oPC)) return;

    string sUuid = GetObjectUUID(oPC);

    // Restore from DB
    int nWyrd  = WyrdDbLoadWyrd(sUuid);
    int nSpent = WyrdDbLoadSpent(sUuid);
    int nDecay = WyrdDbLoadLastDecay(sUuid);

    WyrdSet(oPC, nWyrd);
    SetLocalInt(oPC, WYRD_LVAR_SPENT,      nSpent);
    SetLocalInt(oPC, WYRD_LVAR_LAST_DECAY, nDecay);

    if(nWyrd > 0)
        SendMessageToPC(oPC,
            "[Wyrd] Twoj wyrd: " + IntToString(nWyrd) + " / "
            + IntToString(WYRD_MAX)
            + ". " + WyrdStatusText(nWyrd));
}

void main()
{
    WyrdOnClientEnter();
}
