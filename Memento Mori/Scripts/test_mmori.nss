#include "lib_mmori"

// OnUsed on a test placeable — simulates the death+respawn flow for demonstration.
// Use on a placeable in your test module to preview both windows.
void main()
{
    object oPC = GetLastUsedBy();
    if(!GetIsPC(oPC)) return;

    string sMode = GetLocalString(OBJECT_SELF, "MMORI_TEST_MODE");

    if(sMode == "cairn")
    {
        // Find the first active cairn in the DB and open its window.
        sqlquery q = SqlPrepareQueryCampaign("mmori",
            "SELECT id FROM mmori_marks WHERE is_active = 1 ORDER BY id DESC LIMIT 1");
        if(SqlStep(q))
        {
            int nId = SqlGetInt(q, 0);
            MmoriOnCairnUsed(oPC, GetObjectByTag(MMORI_CAIRN_TAG_PREFIX + IntToString(nId)));
        }
        else
            SendMessageToPC(oPC, "[Memento Mori Test] Brak kamieni w bazie. Najpierw utwórz jeden.");
        return;
    }

    // Default: simulate a death at current location, then open Last Words window.
    SetLocalString(oPC, MMORI_LVAR_DEATH_AREA,  GetTag(GetArea(oPC)));
    SetLocalString(oPC, MMORI_LVAR_DEATH_ANAME, GetName(GetArea(oPC)));
    SetLocalFloat (oPC, MMORI_LVAR_DEATH_X,     GetPositionFromLocation(GetLocation(oPC)).x);
    SetLocalFloat (oPC, MMORI_LVAR_DEATH_Y,     GetPositionFromLocation(GetLocation(oPC)).y);
    SetLocalFloat (oPC, MMORI_LVAR_DEATH_Z,     GetPositionFromLocation(GetLocation(oPC)).z);

    CreateMmoriMarkWindow(oPC);
    SendMessageToPC(oPC, "[Memento Mori Test] Okno Ostatnich Słów otwarte. Zatwierdź, aby spawned kamień.");
}
