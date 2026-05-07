// sys_on_chat.nss - module OnPlayerChat event
// Hook: Module Properties -> Events -> OnPlayerChat
//
// Filtrujemy DM commands "!plg ..." i dispatch do PlgDmHandleChatCommand.
// Jezeli komenda zostanie przetworzona, suppressujemy wiadomosc z czatu.

#include "lib_plg_dm"

void main()
{
    object oPC     = GetPCChatSpeaker();
    string sChatMsg = GetPCChatMessage();

    if(PlgDmHandleChatCommand(oPC, sChatMsg))
    {
        // Suppress wiadomosci z czatu (tylko DM widzi response)
        SetPCChatMessage("");
    }
}
