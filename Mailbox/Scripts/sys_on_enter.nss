#include "lib_mail"

void main()
{
    object oPC = GetEnteringObject();
    if(!GetIsPC(oPC)) return;

    MailRegisterPlayer(oPC);
    MailExpireOld();

    int nUnread = MailGetUnreadCount(oPC);
    if(nUnread > 0)
    {
        string sMsg = "[Mail] You have " + IntToString(nUnread) + " unread message(s). Use the mailbox to read them.";
        FloatingTextStringOnCreature(sMsg, oPC, FALSE);
        SendMessageToPC(oPC, sMsg);
        DelayCommand(3.0, MailShowNotification(oPC));
    }
}
