#include "lib_mail"

void main()
{
    object oPC = GetLastUsedBy();
    CreateMailWindow(oPC);
}
