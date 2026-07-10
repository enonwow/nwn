#include "lib_vend"

// OnUsed placeable — opens Vengeance Ledger window.
// DM use: injects a test grudge from the first other online PC.
void main()
{
    object oPC = GetLastUsedBy();
    if (!GetIsPC(oPC)) return;

    if (GetIsDM(oPC))
    {
        // DM helper: add one grudge of each type from the first other online PC
        object oOther = GetFirstPC();
        while (GetIsObjectValid(oOther) && oOther == oPC)
            oOther = GetNextPC();

        if (!GetIsObjectValid(oOther))
        {
            SendMessageToPC(oPC, "[Test] Potrzebny jest drugi gracz online jako krzywdziciel.");
            return;
        }

        VendAddGrudge(oPC, oOther, VEND_WRONG_KILLED, "");
        VendAddGrudge(oPC, oOther, VEND_WRONG_STOLEN, "sword_01");
        VendAddGrudge(oPC, oOther, VEND_WRONG_CURSED, "");

        SendMessageToPC(oPC,
            "[Test] Dodano 3 testowe wpisy krzywdy od: " + GetName(oOther));
        SendMessageToPC(oPC,
            "[Test] Aby przetestować Zemstę, zabij " + GetName(oOther) + ".");
        return;
    }

    CreateVendWindow(oPC);
}
