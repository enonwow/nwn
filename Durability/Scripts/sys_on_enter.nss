#include "lib_dur"

void DurWarnDamagedOnEnter(object oPC)
{
    int nWorn = 0;
    int i;
    for(i = 0; i < DUR_SLOT_COUNT; i++)
    {
        object oItem = GetItemInSlot(DurGetInventorySlot(i), oPC);
        if(!GetIsObjectValid(oItem)) continue;
        if(DurGetDurability(oItem) < DUR_THR_WORN)
            nWorn++;
    }
    if(nWorn > 0)
        SendMessageToPC(oPC,
            "[Wytrzymałość] Uwaga: " + IntToString(nWorn) +
            " przedmiot(ów) wymaga naprawy. Odwiedź kowala.");
}

void main()
{
    object oPC = GetEnteringObject();
    if(!GetIsPC(oPC) || GetIsDMPossessed(oPC)) return;

    // Initialise all equipped items in DB and restore active penalties.
    // 2-second delay so inventory OnEquip hooks fire first.
    DelayCommand(2.0, DurCheckAllSlots(oPC));
    DelayCommand(3.0, DurWarnDamagedOnEnter(oPC));
}
