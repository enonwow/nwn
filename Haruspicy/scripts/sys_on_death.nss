#include "lib_haru"

// Hook into module OnCreatureDeath event: OBJECT_SELF is the module,
// GetLastKilled() returns the creature. For creature's own OnDeath
// event, replace GetLastKilled() with OBJECT_SELF.

void main()
{
    object oDead = GetLastKilled();
    if(!GetIsObjectValid(oDead)) return;

    // Skip PCs and constructs — they have no readable entrails
    if(GetIsPC(oDead)) return;
    if(GetRacialType(oDead) == RACIAL_TYPE_CONSTRUCT) return;

    // Skip trivially weak creatures
    float fCR = GetChallengeRating(oDead);
    if(fCR < 2.0) return;

    int nCType = HaruClassifyCreature(oDead);
    int nCR    = FloatToInt(fCR);

    // Mark the creature's body as readable
    SetLocalInt   (oDead, HARU_SRC_READABLE, 1);
    SetLocalString(oDead, HARU_SRC_CNAME,    GetName(oDead));
    SetLocalInt   (oDead, HARU_SRC_CTYPE,    nCType);
    SetLocalInt   (oDead, HARU_SRC_CR,       nCR);

    // Notify the killer if they are a PC in range
    object oKiller = GetLastKiller();
    if(GetIsPC(oKiller) && GetDistanceBetween(oKiller, oDead) <= 20.0)
        SendMessageToPC(oKiller,
            "[Haruspika] Mozesz odczytac wnętrznosci " + GetName(oDead)
            + " — uzyj Zestawu Haruspika i wskaż zwloki.");
}
