#include "lib_bb"

void main()
{
    object oPC = GetLastPlayerToSelectTarget();
    if(!GetIsPC(oPC)) return;

    // Only handle capture-mode targeting
    if(!GetLocalInt(oPC, BB_LVAR_CAPTURING)) return;
    DeleteLocalInt(oPC, BB_LVAR_CAPTURING);

    object oTarget = GetTargetingModeSelectedObject();
    if(!GetIsObjectValid(oTarget) || GetObjectType(oTarget) != OBJECT_TYPE_CREATURE)
    {
        SendMessageToPC(oPC, "[Pêtacz] Cel nie jest bestiê.");
        return;
    }

    if(GetIsPC(oTarget) || GetAssociateType(oTarget) != ASSOCIATE_TYPE_NONE)
    {
        SendMessageToPC(oPC, "[Pêtacz] Nie można schwytać istoty rozumnej ani towarzysza.");
        return;
    }

    // HP threshold check
    int nMaxHP  = GetMaxHitPoints(oTarget);
    int nCurHP  = GetCurrentHitPoints(oTarget);
    int nPct    = (nMaxHP > 0) ? (nCurHP * 100 / nMaxHP) : 100;
    if(nPct > BB_HP_CAP_THRESH)
    {
        SendMessageToPC(oPC, "[Pêtacz] Bestia jest zbyt silna — osłab ją poniżej " + IntToString(BB_HP_CAP_THRESH) + "% HP.");
        return;
    }

    // Skill check: Animal Empathy vs DC
    int nSkill = GetSkillRank(SKILL_ANIMAL_EMPATHY, oPC);
    int nRoll  = d20() + nSkill;
    if(nRoll < BB_CAP_SKILL_DC)
    {
        SendMessageToPC(oPC, "[Pêtacz] Rzut na Dressurê zwierząt nie powiódł siê ("
            + IntToString(nRoll) + " vs DC " + IntToString(BB_CAP_SKILL_DC) + ").");
        return;
    }

    // Capture!
    string sResRef = GetResRef(oTarget);
    string sName   = GetName(oTarget);
    int nApp       = GetAppearanceType(oTarget);

    // Destroy the creature from the world
    DestroyObject(oTarget);

    int nId = BbInsertBeast(oPC, sResRef, sName, nApp);
    if(nId < 0)
    {
        SendMessageToPC(oPC, "[Pêtacz] Błąd bazy danych — nie udało siê zapisać bestii.");
        return;
    }

    SendMessageToPC(oPC, "[Pêtacz] Schwytałeś " + sName + "! (Dressura: "
        + IntToString(nRoll) + " vs DC " + IntToString(BB_CAP_SKILL_DC) + ")");
    SendMessageToPC(oPC, "[Pêtacz] Otwórz księgę Pêtacza, aby zarządzać bestiami.");

    // Refresh window if open
    int nToken = NuiFindWindow(oPC, BB_WINDOW);
    if(nToken != 0)
    {
        BbFeedBeastList(oPC, nToken);
        SetLocalInt(oPC, BB_LVAR_SEL_ID, nId);
        BbFeedBeastDetails(oPC, nToken, nId);
    }
}
