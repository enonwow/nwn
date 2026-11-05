# Miasma — Integration Guide

## Czym jest ten moduł?

System środowiskowego skażenia powietrzem (Opar Zarazy). Wyznaczone obszary
emitują Opar — gracze przebywający w strefie akumulują Ekspozycję co 6 sekund.
Przekroczenie progów (20 / 50 / 80) aplikuje narastające osłabienia specyficzne
dla typu (Nekrotyczny, Bagnienny, Demoniczny). Cleansing via zioło lub opuszczenie strefy.

## Podpięcie hooków

| Zdarzenie modułu | Skrypt       | Akcja                                   |
|------------------|-------------|------------------------------------------|
| OnModuleLoad     | sys_on_load | `MiaCreateTables()` — inicjalizacja bazy |
| OnClientEnter    | sys_on_enter | `MiaStartTick(oPC)` — start pętli tików |
| OnClientLeave    | sys_on_leave | Czyszczenie efektów i zmiennych         |
| OnActivateItem   | sys_on_activate | Panel MG (przedmiot `mia_dm_tool`) |

Jeżeli moduł posiada już te hooki, wklej ciało `main()` do istniejących skryptów.

## NWNX

Brak. Moduł nie wymaga żadnych pluginów NWNX.

## SQL

Kampania SQLite: `miasma` (tworzona automatycznie przy pierwszym uruchomieniu).
Tabela: `mia_areas(area_tag, intensity, mia_type)`.
Ekspozycja gracza przechowywana tylko jako zmienna lokalna — resetuje się przy relogu.

## Jak odpalić test?

1. Umieść Placeable z OnUsed = `test_mia` w obszarze modułu.
2. Uruchom moduł. Gracz używa Placeable → dostaje 30 pkt ekspozycji,
   obszar zostaje oznaczony jako Nekrotyczny / poz. 5.
3. MG używa Placeable → otwiera panel zarządzania strefami.

## Zasoby do dodania do HAK

| Resref            | Typ         | Opis                                   |
|-------------------|-------------|----------------------------------------|
| `mia_herb_clns`   | Item        | Zioło oczyszczające (stackowalny misc) |
| `mia_dm_tool`     | Item        | Narzędzie MG otwierające panel         |

## Co celowo pominięto

- Trwałość ekspozycji między sesjami (design decyzja: śmierć/relog resetuje, nie kara podwójna)
- Transmisja Oparu między graczami (mogłoby generować griefing)
- Automatyczne generowanie stref bez interwencji MG (wymaga NWNX_Area)
