#include "lib_lycan"

// Module OnClientEnter — restore effects and start the per-PC heartbeat.

void main()
{
    object oPC = GetEnteringObject();
    if(!GetIsPC(oPC) || GetIsDMPossessed(oPC)) return;

    // Advance stage in case real-world time passed while offline.
    LycanCheckAdvanceStage(oPC);

    int nStage = LycanGetInfectionStage(oPC);
    if(nStage > 0)
    {
        LycanApplyStageEffects(oPC, nStage);

        string sMsg = "[Wilkołactwo] Klątwa wilka nadal cię trawi. Etap: "
                    + LycanGetStageLabel(nStage) + ".";
        DelayCommand(3.0f, SendMessageToPC(oPC, sMsg));

        // If the PC logs in during a full moon and is stage-3, transform them.
        if(LycanIsFullMoon() && nStage == LYCAN_STAGE_FULL)
            DelayCommand(5.0f, LycanTransform(oPC));
    }

    // Start the 6-second heartbeat loop for this PC.
    DelayCommand(6.0f, LycanHeartbeat(oPC));
}
