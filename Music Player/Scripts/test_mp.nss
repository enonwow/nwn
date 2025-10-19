#include "lib_mp"

void main()
{
    json jMusicList = MPCreateList();

    jMusicList = MPCreateEntry(jMusicList,
        "battle-of-the-dragons-8037", 237);

    jMusicList = MPCreateEntry(jMusicList,
        "rpg-medieval-animated-music-320583", 134);

    jMusicList = MPCreateEntry(jMusicList,
        "rpg-mistic-music-contrasting-and-looped-320585", 117);

    object oPC = GetLastUsedBy();

    CreateMPWindow(oPC, OBJECT_SELF, jMusicList, FALSE);
}
