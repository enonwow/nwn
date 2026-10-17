#include "lib_msk"

// Skrypt OnUsed na placeablu demonstracyjnym.
// Placeable tag: msk_test_chest
//
// Daje graczowi jedna z dostepnych masek (po kolei),
// rejestruje ja i otwiera panel Masquerade.
void main()
{
    object oPC = GetLastUsedBy();
    if(!GetIsPC(oPC)) return;

    // Przyznaj testowa maske jesli gracz nie ma zadnej w DB
    json jOwned = MskGetOwnedMasks(oPC);
    if(JsonGetLength(jOwned) == 0)
    {
        // Zarejestruj wszystkie startowe maski dla gracza
        MskRegisterMaskForPC(oPC, "msk_mask_merchant");
        MskRegisterMaskForPC(oPC, "msk_mask_guard");
        MskRegisterMaskForPC(oPC, "msk_mask_noble");
        MskRegisterMaskForPC(oPC, "msk_mask_pilgrim");
        MskRegisterMaskForPC(oPC, "msk_mask_executioner");

        SendMessageToPC(oPC,
            "[Masquerade] Odnalazłeś skrzynię z obliczami. "
            "Pięć tożsamości jest teraz w twoim zasięgu.");
        FloatingTextStringOnCreature(
            "Skrzynia oblicz — 5 nowych masek dodano do twojego panelu.",
            oPC, FALSE);
    }
    else
    {
        SendMessageToPC(oPC, "[Masquerade] Twoje oblicza czekają w panelu.");
    }

    MskOpenPanel(oPC);
}
