#include "lib_sgl"

void main()
{
    SglCreateTables();
    // Re-apply ground visual effects for all persistent sigils so they glow
    // after a server restart. Effects last 1 hour; they're re-applied each restart.
    SglRestoreVisuals();
}
