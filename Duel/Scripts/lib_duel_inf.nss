// lib_duel_inf.nss
// Honor Duels - rules / info window. Self-contained subsystem.
// Open via CreateDuelInfoWindow(oPC) from any context (placeable, button, etc.).
#include "lib_nui"

const string DUEL_INF_WINDOW    = "DUEL_INF_WINDOW";
const string DUEL_INF_EV_SCRIPT = "lib_duel_inf_ev";

const string DUEL_INF_BTN_CLOSE = "duel_inf_btn_close";

const float  DUEL_INF_W = 520.0;
const float  DUEL_INF_H = 430.0;

// Rules text shown in the body of the info window.
string GetDuelInfoText()
{
    return
        "Honor Duels\n\n"
        + "Settle disputes the formal way - challenge another player to a duel "
        + "of honor. The challenger picks a target via the gauntlet icon, the "
        + "challenged player gets a popup. Once both agree, a 5-second countdown "
        + "begins and the fight starts on the spot.\n\n"

        + "One duel at a time:\n"
        + "Each player can be involved in only ONE duel or pending challenge "
        + "at a time (as challenger OR challenged). You cannot send a second "
        + "challenge while one is in flight, and you cannot challenge a player "
        + "who is already busy. Wait until the current one resolves or expires.\n\n"

        + "Same party = automatic split:\n"
        + "If you challenge someone from your own party, you will be removed "
        + "from the party automatically. Friendly fire is off in a party so the "
        + "duel could not resolve otherwise. The party itself stays intact for "
        + "the other player and any other members - only the challenger leaves. "
        + "After the duel you can re-form the party manually.\n\n"

        + "Arena:\n"
        + "The arena center is fixed at the spot where the CHALLENGER stood "
        + "when sending the challenge. The visible glowing aura on the ground "
        + "marks the boundary (~10 meters radius). Both duelists must stay "
        + "inside the aura AND inside the same area - leaving for 6 continuous "
        + "seconds counts as a forfeit.\n\n"

        + "HUD:\n"
        + "While a duel is active you see a small HP bar window in the upper "
        + "left corner showing your own and your opponent's hit points. You "
        + "can drag it; the position is remembered for next duel.\n\n"

        + "Win conditions:\n"
        + " - Killing blow from your opponent: you lose the duel but do not "
        + "actually die. The system resurrects you on the spot at 1 HP - no "
        + "loot, no respawn screen, no real death penalty.\n"
        + " - Fleeing the arena: leaving the aura / area for more than 6 "
        + "seconds counts as a forfeit and the bigger honor hit.\n"
        + " - If both fall in the same tick: no winner, no honor change.\n\n"

        + "Honor:\n"
        + " +10  win\n"
        + "  -3  loss\n"
        + "   0  declined challenge (declining is your right - no penalty)\n"
        + " -25  forfeit (fleeing the arena)\n\n"

        + "Cooldown and timeouts:\n"
        + " - 30 seconds between sent challenges (anti-spam)\n"
        + " - Pending challenges expire automatically after 5 minutes if not "
        + "answered.";
}

void CreateDuelInfoWindow(object oPC)
{
    int nExisting = NuiFindWindow(oPC, DUEL_INF_WINDOW);
    if(nExisting != 0)
    {
        NuiDestroy(oPC, nExisting);
        return;
    }

    float fW    = GetNuiScaleDimension(oPC, DUEL_INF_W);
    float fH    = GetNuiScaleDimension(oPC, DUEL_INF_H);
    float fBtnH = GetNuiScaleDimension(oPC, 30.0);

    // Body - scrollable text
    json jText = NuiText(JsonString(GetDuelInfoText()));
    jText = NuiHeight(jText, fH - GetNuiScaleDimension(oPC, 90.0));

    // Close button row
    json jClose = NuiButton(JsonString("Close"));
    jClose = NuiId(jClose, DUEL_INF_BTN_CLOSE);
    jClose = NuiHeight(jClose, fBtnH);
    jClose = NuiWidth(jClose, GetNuiScaleDimension(oPC, 120.0));

    json jBtnRow = JsonArray();
    jBtnRow = JsonArrayInsert(jBtnRow, NuiSpacer());
    jBtnRow = JsonArrayInsert(jBtnRow, jClose);
    jBtnRow = JsonArrayInsert(jBtnRow, NuiSpacer());

    json jCol = JsonArray();
    jCol = JsonArrayInsert(jCol, jText);
    jCol = JsonArrayInsert(jCol, NuiRow(jBtnRow));

    json jRoot = NuiCol(jCol);

    json jNui = NuiWindow(jRoot,
        JsonString("Honor Duels - Rules"),
        NuiRect(-1.0, -1.0, fW, fH),
        JsonBool(FALSE),  // resizable
        JsonBool(FALSE),  // collapsed
        JsonBool(TRUE),   // closable
        JsonBool(FALSE),  // transparent
        JsonBool(TRUE));  // border

    NuiCreate(oPC, jNui, DUEL_INF_WINDOW, DUEL_INF_EV_SCRIPT);
}
