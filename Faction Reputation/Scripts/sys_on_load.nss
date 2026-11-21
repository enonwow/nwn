// sys_on_load.nss - Faction Reputation: module OnModuleLoad hook
//
// Wire-up: Module Properties -> Events -> OnModuleLoad -> sys_on_load
// (If the module already has an OnModuleLoad script, call FacInit() from it
//  instead of replacing the existing entry point.)

#include "lib_fac"

void main()
{
    FacInit();
}
