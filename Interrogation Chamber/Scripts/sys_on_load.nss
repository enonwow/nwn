#include "sql_intr"

void main()
{
    IntrCreateTables();

    // Seed sample confessions for common creature resrefs.
    // Module builders can add more with IntrAddConfession()
    // or by setting INTR_SECRET_75/50/25/0 LVARs on individual creatures.

    IntrAddConfession("nw_bandit001", 75,
        "Mamy kryjowke przy polnocnej bramie. Straza zmienia sie o polnocy.");
    IntrAddConfession("nw_bandit001", 50,
        "Placi nam ktos z Rady. Nie znam twarzy — tylko zloto i rozkazy.");
    IntrAddConfession("nw_bandit001", 25,
        "Skradziono artefakt z archiwum. Teraz lezy pod oltarzem Bane.");
    IntrAddConfession("nw_bandit001", 0,
        "To Radny Halveth! On sprzedal miasto! Blagam — to koniec!");

    IntrAddConfession("nw_cultist001", 75,
        "Spotykamy sie w nocy pod ruinami starego klasztoru.");
    IntrAddConfession("nw_cultist001", 50,
        "Rytualy wymagaja... ofiar. Trzy dusze w noc przesilenia.");
    IntrAddConfession("nw_cultist001", 25,
        "Ksiega Czarnej Pierscienia jest ukryta w krypcie pod wieza.");
    IntrAddConfession("nw_cultist001", 0,
        "Mroczny Pan zmartwychwstanie! Wszyscy jestescie juz martwi!");

    IntrAddConfession("nw_orc001", 75,
        "Oboz jest za rzeką, przy spalonym mlynie.");
    IntrAddConfession("nw_orc001", 50,
        "Wódz ma mape do starego skarbca elfow.");
    IntrAddConfession("nw_orc001", 25,
        "Szaman przyzywal cos... cos starego. Boimy sie tego.");
    IntrAddConfession("nw_orc001", 0,
        "Pakt... pakt z cieniem! Plemie jest przeklate! Uciekajcie!");
}
