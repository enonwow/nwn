// sys_on_load.nss — Watchfire: module OnLoad hook

#include "lib_wf_def"

void main()
{
    // Tables are created per-character on first use (SqlPrepareQueryObject),
    // so no global schema setup is needed here.
    // This hook exists as the standard module-init attachment point.
}
