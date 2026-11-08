// Module OnLoad hook for the Forge Trial module.
// Creates the forge database table if it does not yet exist.

#include "lib_frg_def"

void main()
{
    FrgCreateTables();
}
