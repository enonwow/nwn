#include "lib_div_def"

void main()
{
    object oPC = GetExitingObject();
    if(!GetIsPC(oPC)) return;

    // Clean session-only LVARs; SQL state survives for reapply on next enter.
    DeleteLocalJson(oPC, DIV_LVAR_CARDS);
    DeleteLocalInt(oPC, DIV_LVAR_REVEALED);
    DeleteLocalInt(oPC, DIV_LVAR_CARDCNT);
    DeleteLocalInt(oPC, DIV_LVAR_LASTCARD);
}
