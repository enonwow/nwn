#include "lib_plg_def"

// Seed eight sample shrines.  Tags must match placeable tags in the area.
// Lore strings are visible to players — keep them dark-fantasy flavoured.
void SeedShrines()
{
    PlgRegisterShrine(
        "plg_shrine_shadow_01",
        "Kamienny Krąg Cieni",
        "Osiem kamieni ustawionych w milczący okrąg. "
        "Każdy z nich nosi wyryte imię boga, który już dawno o sobie zapomniał. "
        "Powietrze jest gęste od nieobecności.",
        "shadow", 1);

    PlgRegisterShrine(
        "plg_shrine_shadow_02",
        "Ołtarz Zapomnianego",
        "Ktoś przyniósł tu kwiaty — zgniłe, wyschnięte. "
        "Napis na postumencie głosi: »Kto mnie zna, ten mnie traci«. "
        "Dotknięcie kamienia zostawia na palcach siny ślad.",
        "shadow", 2);

    PlgRegisterShrine(
        "plg_shrine_blood_01",
        "Kaplica Krwawej Ofiary",
        "Rynnę pod ołtarzem wypełnia coś czarnego i gęstego. "
        "Modlitewnik leżący w kącie jest zapisany od środka — "
        "ludzką krwią, starannym pismem.",
        "blood", 1);

    PlgRegisterShrine(
        "plg_shrine_blood_02",
        "Studnia Czerwonej Mgły",
        "Cembrowina bez dna, z której od czasu do czasu "
        "unosi się ciepła para o zapachu miedzi. "
        "Legendy mówią, że wrzucona moneta nigdy nie brzęka.",
        "blood", 2);

    PlgRegisterShrine(
        "plg_shrine_death_01",
        "Grobowiec Pierwszego Upadłego",
        "Epitafium wyryto w języku, którego nikt już nie czyta. "
        "Tłumaczenie wykute obok głosi jedynie: »Pierwszy z nas«. "
        "W kącie stoi butelka wina — nietkniętego od wieków.",
        "death", 1);

    PlgRegisterShrine(
        "plg_shrine_death_02",
        "Katakumby Wiecznego Snu",
        "Sto jeden wnęk, sto jeden czaszek. Setna pierwsza jest pusta. "
        "Lokalni mieszkańcy przysięgają, że od dziesięciu lat wnęka czeka. "
        "Nie mówią na kogo.",
        "death", 2);

    PlgRegisterShrine(
        "plg_shrine_chaos_01",
        "Wir Szaleństwa",
        "Wzory wypalione w ziemi nie mają symetrii ani powtórzeń. "
        "Patrząc na nie zbyt długo czuje się, "
        "że własne myśli zaczynają przeskakiwać bez powodu.",
        "chaos", 1);

    PlgRegisterShrine(
        "plg_shrine_chaos_02",
        "Kolumna Przekleństwa",
        "Czterdzieści stop monolitu pokrywają wyryte twarze "
        "— różne, lecz wszystkie z tym samym wyrazem. "
        "Pieczęć u podstawy pulsuje słabo, jak serce w agonii.",
        "chaos", 2);
}

void main()
{
    PlgCreateTables();
    SeedShrines();
}
