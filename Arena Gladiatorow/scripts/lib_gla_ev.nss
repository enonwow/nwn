#include "lib_gla"

void main()
{
    object oPC    = NuiGetEventPlayer();
    int    nToken = NuiGetEventWindow();
    string sEvent = NuiGetEventType();
    string sElem  = NuiGetEventElement();

    if(nToken != NuiFindWindow(oPC, ARENA_WINDOW)) return;

    if(sEvent == EVENT_TYPE_OPEN)
    {
        ArenaFeedLeaderboard(oPC, nToken);
        ArenaFeedStatus(oPC, nToken);
        return;
    }

    if(sEvent == EVENT_TYPE_CLOSE)
    {
        // Nothing to clean up here — the fight continues if in progress.
        return;
    }

    if(sEvent != EVENT_TYPE_CLICK) return;

    // ---- Tab buttons ----
    if(sElem == ARENA_BTN_TAB_BOARD)
    {
        SetLocalString(oPC, ARENA_LVAR_TAB, "board");
        NuiSetGroupLayout(oPC, nToken, ARENA_GRP_SWAP, ArenaBuildLeaderboardView(oPC));
        ArenaFeedLeaderboard(oPC, nToken);
        return;
    }

    if(sElem == ARENA_BTN_TAB_MINE)
    {
        SetLocalString(oPC, ARENA_LVAR_TAB, "mine");
        NuiSetGroupLayout(oPC, nToken, ARENA_GRP_SWAP, ArenaBuildStatusView(oPC));
        ArenaFeedStatus(oPC, nToken);
        return;
    }

    if(sElem == ARENA_BTN_CLOSE)
    {
        NuiDestroy(oPC, nToken);
        return;
    }

    // ---- League selector ----
    if(sElem == ARENA_BTN_L1)
    {
        if(GetLocalInt(oPC, ARENA_LVAR_IN_FIGHT))
        {
            SendMessageToPC(oPC, "[Arena] Nie możesz zmieniać ligi w trakcie walki.");
            return;
        }
        SetLocalInt(oPC, ARENA_LVAR_LEAGUE, ARENA_LEAGUE_RECRUIT);
        NuiSetBind(oPC, nToken, ARENA_BIND_L1_ENC, JsonBool(TRUE));
        NuiSetBind(oPC, nToken, ARENA_BIND_L2_ENC, JsonBool(FALSE));
        NuiSetBind(oPC, nToken, ARENA_BIND_L3_ENC, JsonBool(FALSE));
        return;
    }

    if(sElem == ARENA_BTN_L2)
    {
        if(GetLocalInt(oPC, ARENA_LVAR_IN_FIGHT))
        {
            SendMessageToPC(oPC, "[Arena] Nie możesz zmieniać ligi w trakcie walki.");
            return;
        }
        SetLocalInt(oPC, ARENA_LVAR_LEAGUE, ARENA_LEAGUE_WARRIOR);
        NuiSetBind(oPC, nToken, ARENA_BIND_L1_ENC, JsonBool(FALSE));
        NuiSetBind(oPC, nToken, ARENA_BIND_L2_ENC, JsonBool(TRUE));
        NuiSetBind(oPC, nToken, ARENA_BIND_L3_ENC, JsonBool(FALSE));
        return;
    }

    if(sElem == ARENA_BTN_L3)
    {
        if(GetLocalInt(oPC, ARENA_LVAR_IN_FIGHT))
        {
            SendMessageToPC(oPC, "[Arena] Nie możesz zmieniać ligi w trakcie walki.");
            return;
        }
        SetLocalInt(oPC, ARENA_LVAR_LEAGUE, ARENA_LEAGUE_CHAMPION);
        NuiSetBind(oPC, nToken, ARENA_BIND_L1_ENC, JsonBool(FALSE));
        NuiSetBind(oPC, nToken, ARENA_BIND_L2_ENC, JsonBool(FALSE));
        NuiSetBind(oPC, nToken, ARENA_BIND_L3_ENC, JsonBool(TRUE));
        return;
    }

    // ---- Fight button ----
    if(sElem == ARENA_BTN_FIGHT)
    {
        ArenaStartFight(oPC);
        return;
    }
}
