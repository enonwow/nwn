#include "lib_ln"

// Module OnClientEnter — remind attuned players that their network awaits.
void main()
{
    object oPC = GetEnteringObject();
    if(!GetIsPC(oPC)) return;

    int nCount = LnGetAttunementCount(oPC);
    if(nCount > 0)
    {
        string sMsg = "[Węzły] Masz " + IntToString(nCount)
            + " nastrojenie(ń) do węzłów mocy. Użyj dowolnego węzła, by otworzyć panel.";
        DelayCommand(4.0, SendMessageToPC(oPC, sMsg));
    }
}
