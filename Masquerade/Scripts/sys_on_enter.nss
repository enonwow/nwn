#include "lib_msk"

void main()
{
    object oPC = GetEnteringObject();
    if(!GetIsPC(oPC)) return;

    // Sprawdz, czy gracz ma w ekwipunku maski, i zarejestruj je
    object oItem = GetFirstItemInInventory(oPC);
    while(GetIsObjectValid(oItem))
    {
        string sTag = GetTag(oItem);
        if(GetStringLeft(sTag, 9) == "msk_mask_")
            MskRegisterMaskForPC(oPC, sTag);
        oItem = GetNextItemInInventory(oPC);
    }

    // Jesli gracz byl zalogowany z aktywna maska i wraca (np. po relog)
    // zresetuj stan maski — nie mozna zachowac podszywania przez relog
    if(MskIsActive(oPC))
    {
        SetPCNameOverride(oPC, "", OBJECT_INVALID, PC_NAME_OVERRIDE_TYPE_REPLACE_ALWAYS);
        DeleteLocalInt   (oPC, MSK_LVAR_ACTIVE_ID);
        DeleteLocalString(oPC, MSK_LVAR_ACTIVE_NAME);
        MskSetSuspicion  (oPC, 0);
        SendMessageToPC  (oPC, "[Masquerade] Oblicze zostało zdjęte po ponownym wejściu do świata.");
    }
}
