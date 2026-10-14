#include "lib_tatu"

void main()
{
    object oPC = GetEnteringObject();
    if(!GetIsPC(oPC)) return;

    // Re-apply all tattoo effects after login/module restart.
    // Permanent effects are not persisted across sessions in NWN.
    TatuApplyEffectsForPC(oPC);

    int nCount = JsonGetLength(TatuGetPCTattoos(oPC));
    if(nCount > 0)
        SendMessageToPC(oPC,
            "[Tatuaże] Nosisz " + IntToString(nCount)
            + " magiczn" + (nCount == 1 ? "y tatuaż" : "e tatuaże")
            + ". Pieczęcie pulsują na twojej skórze.");
}
