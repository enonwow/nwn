# Kowalnia Ciała — Integracja

## Skrypty do podpięcia

| Zdarzenie modułu     | Skrypt                    | Uwagi                                    |
|----------------------|---------------------------|------------------------------------------|
| OnModuleLoad         | `sys_on_load`             | Tworzy schemat SQLite (idempotentne)     |
| OnClientEnter        | `sys_on_enter`            | Reaplikuje efekty, resetuje cooldowny    |
| OnPlayerRest         | `sys_on_rest`             | Resetuje cooldowny zdolności aktywnych   |
| OnPlayerTarget       | `sys_on_target`           | Obsługuje targeting zdolności aktywnych  |
| NUI event script     | `lib_fcraft_ev`           | Ustawić w NuiCreate jako event_script    |

Jeśli moduł już korzysta z tych zdarzeń przez własne skrypty,
wywołaj odpowiednią funkcję ręcznie w istniejącym skrypcie:

```nss
// OnClientEnter
#include "lib_fcraft"
void main() {
    object oPC = GetEnteringObject();
    if(GetIsPC(oPC)) FcraftReapplyAll(oPC);
    // ... reszta logiki
}

// OnPlayerTarget — sprawdź flagę najpierw
#include "lib_fcraft_ev"
void main() {
    object oPC = GetLastPlayerToSelectTarget();
    if(GetLocalString(oPC, FCRAFT_LVAR_TARGETING) != "")
        FcraftOnTarget(oPC);
    // ... reszta logiki
}
```

## Baza danych

Campaign database: `fleshcraft` (plik `fleshcraft.fpt` w katalogu save).
Tabela: `fcraft_mods(uuid, mod_id, installed_at)`.
Dane globalne, serwer-side — bezpieczne dla PW.

## Składniki organiczne (wymagane itemy)

Każda modyfikacja wymaga jeden item w ekwipunku gracza.
Poniższe resrefy to przykładowe nazwy — stwórz itemy w toolsecie:

| mod_id     | resref             | Sugerowana nazwa               |
|------------|--------------------|-------------------------------|
| CHITIN     | fcraft_comp_chitin | Chitynowa Płyta (z gnolli)    |
| DEMONSEYE  | fcraft_comp_deye   | Demoniczne Oko                 |
| SINEWARM   | fcraft_comp_sinew  | Ścięgna Olbrzyma               |
| BONEFIST   | fcraft_comp_bone   | Kość Bestii                    |
| SPIDER     | fcraft_comp_sgland | Gruczoł Olbrzymiego Pająka     |
| IRONHIDE   | fcraft_comp_ironfl | Zestwardniała Skóra            |
| VENOMFANG  | fcraft_comp_venom  | Worek z Jadem                  |
| HEARTVAULT | fcraft_comp_heart  | Serce Golema                   |
| STONEEYE   | fcraft_comp_beye   | Oko Beholdera                  |
| SHADOW     | fcraft_comp_shade  | Esencja Cienia                 |

## Placeable — Stół Rzeźbiarza

1. Stwórz placeable w toolsecie (np. chirurgiczny stół lub ołtarz).
2. Ustaw skrypt OnUsed: `test_fcraft`.
3. Umieść w module.

## Zależności NWNX

Brak — moduł używa wyłącznie vanilla NWScript i NUI.

## Testy

1. Wejdź do modułu → sprawdź komunikat `[Kowalnia] X modyfikacja/-e ciała aktywne.`
2. Kliknij placeable → okno NUI powinno się otworzyć.
3. Wybierz modyfikację z katalogu → szczegóły po prawej.
4. Dodaj składnik (daj sobie item przez `dm_giveitem fcraft_comp_chitin`) → kliknij Wszczep.
5. Zakładka "Twoje Modyfikacje" → lista aktywnych.
6. Zdolność aktywna (Spider/Venomfang/Shadow) → "Użyj Zdolności" → tryb targetingu.
7. Wyloguj i zaloguj → efekty powinny być reaplikowane.

## Celowo pominięto

- Modele 2DA / appearance zmiany — wymagałyby własnego haka z overrides;
  można dodać jako rozszerzenie integrując z modułem Appearance.
- Limit czasu modyfikacji — modyfikacje są permanentne (można usunąć za opłatą).
- GUI NPC sprzedającego składniki — integracja ze sklepem poza zakresem.
