// sys_on_death.nss  –  Corruption: OnPlayerDeath hook
// Potępiony (Damned) characters bleed corruption on death —
// a faint warning before possible permanent consequences.

#include "lib_cor"

void main()
{
    object oPC = GetLastPlayerDied();
    if(!GetIsObjectValid(oPC)) return;

    int nCorruption = GetLocalInt(oPC, COR_LVAR_CORRUPTION);
    int nStage      = CorGetStage(nCorruption);

    if(nStage == COR_STAGE_DAMNED)
    {
        SendMessageToPC(oPC,
            "[Korupcja] W chwili śmierci twa dusza krzyczy. "
            "Demony tańczą wokół twojego ciała.");
        // Purely atmospheric — no extra penalty on death to avoid frustrating players.
        // Builders can add penalties here (e.g., permanent stat loss, XP drain).
    }
}
