# Kartomancer — Integracja z modułem NWN

## Co to robi

Gracz może prowadzić **Dziennik Kartografa**: szkicować mapy odwiedzanych obszarów z poziomem zagrożenia (I–V), zasobami naturalnymi (zioła, ruda, woda, ruiny, kapliczka) i odręcznymi notatkami (do 300 znaków). Posiadanie mapy bieżącego obszaru przyznaje permanentny (na czas pobytu) bonus +2 do Lore i Search. Mapy można sprzedać „Faktorowi Kartografów" za złoto proporcjonalne do zagrożenia (50–600 sz.), a także przekazać kopię innemu graczowi.

## Hooki do podpięcia

| Zdarzenie modułu | Skrypt                | Opis                                            |
|------------------|-----------------------|-------------------------------------------------|
| OnModuleLoad       | `sys_on_load`     | Tworzy tabele SQLite                                        |
| Area → OnEnter     | `sys_on_enter`    | Usuwa stary bonus i aplikuje nowy dla wejścia do obszaru    |
| Area → OnExit      | `sys_on_leave`    | Usuwa bonus przy opuszczaniu obszaru                        |
| OnPlayerTarget     | `sys_on_target`   | Obsługuje tryb targeting dla przekazywania mapy             |
| OnNUIEvent         | `lib_carto_ev`    | Obsługuje zdarzenia okna NUI                                |

`sys_on_enter` / `sys_on_leave` są **zdarzeniami poziomu obszaru** (Area OnEnter/OnExit), nie modułu. Ustaw je na każdym obszarze w module lub dodaj wywołania do centralnego area-level dispatchera:
- `CartoInitDB()` w OnModuleLoad
- `CartoRemoveAreaBonus(oPC); CartoApplyAreaBonus(oPC);` w Area OnEnter
- `CartoRemoveAreaBonus(oPC)` w Area OnExit
- W OnPlayerTarget sprawdź `GetLocalInt(oPC, CARTO_LVAR_TARGETING)` i wywołaj `CartoOnPlayerTarget(oPC)`

## Jak otworzyć dziennik

Ustaw `OnUsed` placeholdera / NPC konwersacji na `test_carto`, albo wywołaj bezpośrednio:

```nss
#include "lib_carto"
CartoOpen(GetPCSpeaker());
```

## Zależności NWNX

Brak wymaganych zależności NWNX. Moduł używa wyłącznie wbudowanego API NWN:EE (NUI, SQLite, efektów).

## Baza danych

Kampania SQLite: `"carto"` (plik `carto.sqlite` w katalogu danych kampanii).

Tabela: `carto_maps` — jeden wpis per (player_uuid, area_tag). Wszystkie dane są idempotentne: wielokrotne uruchomienie `CartoInitDB()` jest bezpieczne dzięki `CREATE TABLE IF NOT EXISTS`.

## Złoto skupu za mapę

| Poziom zagrożenia | Złoto |
|-------------------|-------|
| I                 | 50 sz.  |
| II                | 120 sz. |
| III               | 250 sz. |
| IV                | 400 sz. |
| V                 | 600 sz. |

## Co celowo pominięto

- **Fizyczny przedmiot „mapa"**: dziennik to wyłącznie UI, nie item w ekwipunku. Upraszcza integrację; modder może dodać item jako „klucz" do otwarcia okna.
- **Ograniczenie liczby map na gracza**: techniczne max 50 per gracz (hardkodowane w `CartoCopyMapTo`). Można zwiększyć stałą `CARTO_MAX_MAPS`.
- **Handel mapami za złoto między graczami**: przekazywanie jest darmowe — modder może dodać wymianę złota w `CartoCopyMapTo` / `CartoHandleTransfer` przed wywołaniem `CartoCopyMapTo`.
- **Miniatura mapy / grafika**: okno nie rysuje graficznej mapy terenu (NWN EE DrawList nie daje dostępu do geometrii obszaru). Zamiast tego notatki tekstowe i metadane.
