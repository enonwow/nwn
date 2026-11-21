#include "lib_btrk"

// OnUsed script for a test placeable.
// Demonstrates the Blood Tracker UI and optionally seeds fake trail data.

void SeedTestTrails(object oPC)
{
    object oArea  = GetArea(oPC);
    string sArea  = GetTag(oArea);
    vector vBase  = GetPosition(oPC);

    // Three test trails at different freshness ages (simulated by expires_at offsets)
    // Trail 1 — fresh, 8m NE
    BtrkInsertTrail(sArea, vBase.x + 6.0, vBase.y + 6.0, vBase.z,
        "", "Zraniony Goblin",  18);

    // Trail 2 — stale-ish, 20m South
    BtrkInsertTrail(sArea, vBase.x,        vBase.y - 20.0, vBase.z,
        "", "Zbrojny Rycerz",   42);

    // Trail 3 — old, 35m West
    BtrkInsertTrail(sArea, vBase.x - 34.0, vBase.y + 2.0,  vBase.z,
        "", "Nieznane Stworzenie", 9);

    SendMessageToPC(oPC, "[Tropiciel] Zasiano 3 testowe ślady w okolicy.");
}

void main()
{
    object oPC = GetLastUsedBy();
    if(!GetIsPC(oPC)) return;

    // Seed trails on first use if area has none
    string sArea = GetTag(GetArea(oPC));
    if(BtrkTrailCountInArea(sArea) == 0)
        SeedTestTrails(oPC);

    BtrkOpen(oPC);
}
