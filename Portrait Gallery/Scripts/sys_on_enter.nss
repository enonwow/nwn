#include "lib_por"

void main()
{
    object oPC = GetEnteringObject();
    if(!GetIsPC(oPC) || GetIsDMPossessed(oPC)) return;

    // Reapply portrait curse if portrait is damaged, remove it if repaired.
    // Also removes the buff tag from the previous session so the cooldown
    // is reset — the last_buff_at SQL timestamp governs the real cooldown.
    PorCheckOnEnter(oPC);

    // Notify the player if their portrait has crossed a shadow threshold
    // since they last logged in (flavour message only, no extra SQL query).
    json jPor = PorGetByOwner(oPC);
    if(JsonGetType(jPor) == JSON_TYPE_NULL) return;

    int nScore = JsonGetInt(JsonObjectGet(jPor, "shadow_score"));
    int nState = JsonGetInt(JsonObjectGet(jPor, "state"));

    if(nState == POR_STATE_MEMORIAL)
    {
        SendMessageToPC(oPC, "[Portret] Twoj portret w galerii nosi teraz imie epitafium.");
        return;
    }

    if(nScore >= POR_SHADOW_DAMNED)
        SendMessageToPC(oPC, "[Portret] Twoj portret jest przeklety. Jego oblicze spoglada na ciebie z niemym wyrzutem...");
    else if(nScore >= POR_SHADOW_CORRUPTED)
        SendMessageToPC(oPC, "[Portret] Twoj portret jest skazony. Cienie zearly juz wieksza czesc plótna.");
    else if(nScore >= POR_SHADOW_TAINTED)
        SendMessageToPC(oPC, "[Portret] Twoj portret jest zmacony. Farby ciemnieja z kazdym minietym dniem.");
}
