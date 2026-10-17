#include "lib_msk"

// Podpinany pod OnPlayerTarget — jesli gracz rzuca czar podczas maskowania,
// nalicz podejrzenia. Wywolywane rowniez przez OnSpellCast jesli dostepne.
void main()
{
    object oPC = GetLastPlayerToSelectTarget();
    if(!GetIsPC(oPC)) return;

    // Tylko jesli tryb celowania zostal uruchomiony przez casting
    // (heurystyka: cel to stworzenie lub area-effect)
    MskAddSpellSuspicion(oPC);
}
