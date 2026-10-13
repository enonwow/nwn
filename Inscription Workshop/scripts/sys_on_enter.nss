#include "lib_ink_def"

void main()
{
    object oPC = GetEnteringObject();
    if(!GetIsPC(oPC) || GetIsDMPossessed(oPC)) return;

    // Grant all 4 basic formulas to every player on first entry
    int i;
    for(i = 1; i < INK_FORM_FIRST_ADV; i++)
        InkLearnFormula(oPC, i);
}
