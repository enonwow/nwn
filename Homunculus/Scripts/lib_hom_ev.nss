// lib_hom_ev.nss — NUI event handler for the Homunculus module
#include "lib_hom"

void main()
{
    object oPC    = NuiGetEventPlayer();
    int    nToken = NuiGetEventWindow();
    string sEvent = NuiGetEventType();
    string sElem  = NuiGetEventElement();

    if(nToken != NuiFindWindow(oPC, HOM_WINDOW)) return;

    if(sEvent == EVENT_TYPE_CLOSE)
    {
        DeleteLocalInt(oPC, HOM_LVAR_VIEW);
        return;
    }

    if(sEvent != EVENT_TYPE_CLICK) return;

    int nView = GetLocalInt(oPC, HOM_LVAR_VIEW);

    // ---- Status / craft view buttons ----
    if(nView == 0)
    {
        if(sElem == HOM_BTN_CLOSE)
        {
            NuiDestroy(oPC, nToken);
            return;
        }

        if(sElem == HOM_BTN_CRAFT)
        {
            HomCraft(oPC);
            HomShowMain(oPC, nToken);
            NuiSetBind(oPC, nToken, HOM_BIND_TITLE, JsonString("Homunkulus"));
            return;
        }

        if(sElem == HOM_BTN_USE)
        {
            HomUseAbility(oPC);
            HomShowMain(oPC, nToken);
            return;
        }

        if(sElem == HOM_BTN_FEED)
        {
            HomFeedCompanion(oPC);
            HomShowMain(oPC, nToken);
            return;
        }

        if(sElem == HOM_BTN_RENAME)
        {
            if(!HomExists(oPC)) return;
            HomShowRename(oPC, nToken);
            return;
        }

        if(sElem == HOM_BTN_SACRIFICE)
        {
            HomSacrifice(oPC);
            HomShowMain(oPC, nToken);
            NuiSetBind(oPC, nToken, HOM_BIND_TITLE, JsonString("Laboratorium Alchemiczne"));
            return;
        }

        return;
    }

    // ---- Rename view buttons ----
    if(nView == 1)
    {
        if(sElem == HOM_BTN_RENAME_CC)
        {
            HomShowMain(oPC, nToken);
            return;
        }

        if(sElem == HOM_BTN_RENAME_OK)
        {
            string sNewName = JsonGetString(NuiGetBind(oPC, nToken, HOM_BIND_NAME_TXT));
            sNewName = GetStringLeft(TrimString(sNewName), HOM_MAX_NAME);

            if(sNewName == "")
            {
                SendMessageToPC(oPC, "[Homunkulus] Imię nie może być puste.");
                return;
            }

            HomSetName(oPC, sNewName);
            HomAddLog(oPC, "Zmieniono imię na: " + sNewName);
            SendMessageToPC(oPC, "[Homunkulus] Twój towarzysz zostanie odtąd zwany: " + sNewName + ".");

            NuiSetBind(oPC, nToken, HOM_BIND_TITLE, JsonString(sNewName));
            HomShowMain(oPC, nToken);
            return;
        }

        return;
    }
}
