#include "lib_sgl"

// Module OnHeartbeat — staggered proximity check every SGL_HB_MODULO heartbeats.
// Heartbeat fires every 6 seconds; with modulo 3 this checks every ~18 seconds.

void main()
{
    int nCount = GetLocalInt(GetModule(), "SGL_HB_COUNT");
    nCount     = (nCount + 1) % SGL_HB_MODULO;
    SetLocalInt(GetModule(), "SGL_HB_COUNT", nCount);
    if(nCount != 0) return;

    SglCheckProximity();
}
