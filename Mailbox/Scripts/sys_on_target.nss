#include "lib_mail"

void main()
{
    object oPC = GetLastPlayerToSelectTarget();
    if(!GetIsPC(oPC)) return;

    if(NuiFindWindow(oPC, MAIL_WINDOW) != 0)
        MailOnPlayerTarget(oPC);
}
