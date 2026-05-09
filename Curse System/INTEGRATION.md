# Curse System — Integracja

## Co to robi

System klątw dla dark-fantasy CRPG. Gracze mogą być dotknięci jedną z 6 nazwanych
klątw (Gnijąca Dłoń, Piętno Zarazy, Cień Rozpaczy, Klątwa Drżenia, Mróz Duszy,
Pieczęć Krwi). Każda klątwa ma 3 stadia nasilenia, mechaniczne kary (utrata statystyk,
spowolnienie, spell failure, HP drain) i flavor text po polsku. Zdjęcie klątwy wymaga
przedmiotu Święty Olej (`crs_hol_oil`) i złota. Stadium postępuje automatycznie co ~10
minut realnego czasu.

## Wymagania

- **NWN:EE** build 8193.36 lub wyższy (NUI + TagEffect + SqlPrepareQueryCampaign).
- Brak zależności NWNX — wszystko korzysta z natywnego API.
- Kampania SQLite o nazwie `curses` (CreateCampaignDatabase automatycznie).

## Hooki do podpięcia w istniejącym module

| Zdarzenie modułu | Skrypt do wywołania | Opis |
|---|---|---|
| OnModuleLoad | `sys_on_load.nss` | Tworzy tabelę `crs_active` |
| OnClientEnter | `sys_on_enter.nss` | Przywraca efekty, startuje tick |
| OnClientLeave | `sys_on_leave.nss` | Czyści flagę tickingu |

Jeśli masz już własne skrypty na te zdarzenia, włącz je przez `#include` i wywołaj
odpowiednią funkcję (`CrsCreateTables()`, itd.).

## Jak nadać/zdjąć klątwę z kodu

```nss
#include "lib_crs"

// Nadaj klątwę:
CrsInflict(oPC, CRS_CURSE_PLAGUE_BRAND);

// Otwórz panel klątw:
CrsOpenWindow(oPC);

// Wymuś zdjęcie (bez kosztu — np. kapłan NPC):
CrsRemoveEffects(oPC, CRS_CURSE_PLAGUE_BRAND);
CrsDeleteCurse(oPC, CRS_CURSE_PLAGUE_BRAND);
```

## Przedmiot: Święty Olej

Stwórz w Toolset przedmiot o tagu `crs_hol_oil` (np. zwykły `it_misc_bottle` z
nadpisanym tagiem). Umieść go w module lub sprzedawcy. Gracz musi mieć ten przedmiot
w ekwipunku, by móc skorzystać z przycisku „Zdjąć" w panelu.

## Test (placeable OnUsed)

1. W Toolset stwórz placeable, ustaw `OnUsed = test_crs`.
2. Umieść w obszarze startowym.
3. Kliknij: nałoży wszystkie 6 klątw i da 3× Święty Olej.
4. Kliknij ponownie: otworzy panel klątw.

## Pliki

| Plik | Rola |
|---|---|
| `lib_crs_def.nss` | Stałe, lookup nazw/opisów, forward decl |
| `sql_crs.nss` | Schemat SQLite + CRUD |
| `lib_crs.nss` | Efekty, logika tick, budowanie i otwieranie NUI |
| `lib_crs_ev.nss` | Handler eventów NUI |
| `sys_on_load.nss` | Init tabel |
| `sys_on_enter.nss` | Restore efektów + start tick |
| `sys_on_leave.nss` | Cleanup flagi tick |
| `test_crs.nss` | Demo placeable |
| `lib_nui.nss` / `lib_nui_utility.nss` | Pomocnicy NUI (wspólne z innymi modułami) |

## Co celowo pominięto

- **HAK z ikoną** — brak niestandardowych ikon; używa domyślnych NWN.
- **DM panel** — brak osobnego okna dla DM; DM może nadawać klątwy przez
  `CrsInflict(oPC, id)` z konsolera lub własnego skryptu.
- **Chat command** (`!klątwy`) — zasugerowany w on_enter, ale nie zaimplementowany;
  podepnij przez `OnPlayerChat` wg własnych potrzeb.
- **Odporności rasowe** — klątwy działają na wszystkich; dodaj sprawdzenie rasy/klasy
  przed `CrsInflict` jeśli potrzebujesz wyjątków.
