# Stronghold — Integracja

## Opis

Moduł **Stronghold (Twierdza)** pozwala każdej postaci rozbudowywać własną
twierdzę złożoną z 6 budynków (po 3 poziomy każdy). Każdy budynek ulepszany
za złoto i czas nadaje permanentne bonusy do statystyk (atak, rzuty obronne,
umiejętności, PŻ itp.). Postęp zapisywany jest w bazie SQLite per-postać.

### Budynki

| ID | Nazwa         | Lv1           | Lv2                  | Lv3                        |
|----|---------------|---------------|----------------------|----------------------------|
| 0  | Koszary       | +1 do trafienia | +2 do trafienia    | +2 traf., +2 do obrażeń    |
| 1  | Laboratorium  | +1 rzuty obr. | +2 rzuty obr.        | +2 rzuty obr., +4 SR       |
| 2  | Kaplica       | +10 THP       | +20 THP              | +30 THP                    |
| 3  | Biblioteka    | +3 Lore/App.  | +5 Lore/App.         | +5 Lore/App., +1 INT       |
| 4  | Lochy         | +3 Intimidate | +3 Intim., +2 Persu. | +4 Intim., +3 Persu., +1 AC |
| 5  | Wieżyczka     | +3 Spot/Listen | +4 Spot/Listen, +3 Search | +5 Spot/Listen/Search, +2 Tumble |

### Koszty ulepszeń

| Poziom | Złoto | Czas   |
|--------|-------|--------|
| 1      | 500   | 1 min  |
| 2      | 1500  | 5 min  |
| 3      | 3000  | 10 min |

Anulowanie rozbudowy zwraca 50% kosztu.

## Wymagane hooki

### OnModuleLoad
Dodaj wywołanie do swojego skryptu `OnModuleLoad`:

```nss
#include "lib_sth_def"
// ...
StrongholdCreateTables();
```

Lub ustaw `sys_on_load` jako skrypt `OnModuleLoad` (jeśli moduł nie ma jeszcze własnego).

### OnClientEnter
Dodaj wywołanie do swojego skryptu `OnClientEnter`:

```nss
#include "lib_sth"
// ...
object oPC = GetEnteringObject();
if(GetIsPC(oPC))
{
    StrongholdCheckUpgrades(oPC);
    StrongholdApplyBonuses(oPC);
}
```

Lub ustaw `sys_on_enter` jako skrypt `OnClientEnter`.

## Otwieranie UI

Podepnij `test_sth` pod zdarzenie `OnUsed` dowolnego placeable (np. "Zarząd
Twierdzy"). Możesz też wywołać `StrongholdOpen(oPC)` bezpośrednio z dowolnego
skryptu konwersacji lub zdarzenia NPC.

## Zależności NWNX

Brak — moduł korzysta wyłącznie z wbudowanych funkcji NWN:EE (NUI, SQLite,
efekty tagowane przez `TagEffect` / `RemoveEffectByTag`).

Minimalna wersja: **NWN:EE 8193.36** (wprowadzono `TagEffect` i `RemoveEffectByTag`).

## Baza danych

Kampania SQLite: `stronghold`
Tabela: `sth_buildings(pc_uuid, building_id, level, upgrade_finish)`

Schemat jest idempotentny — bezpieczna wielokrotna inicjalizacja przez
`CREATE TABLE IF NOT EXISTS`.

## Co celowo pominięto

- **Wizualne reprezentacje budynków** — brak niestandardowych ikon HAK;
  budynki pokazane jako tekst, co nie wymaga modyfikacji pliku HAK.
- **System własności gruntu** — każda postać ma domyślnie dostęp do twierdzy;
  DM może ograniczyć dostęp do UI przez własną logikę przed wywołaniem
  `StrongholdOpen`.
- **Budynki kooperacyjne** — twierdza jest ściśle per-postać; wersja
  guildhall wymagałaby drugiego schematu SQL.
- **Efekty poza rogue-aplikacją** — bonusy są reaplikowane przy każdym
  wejściu do modułu i nie przeżywają relogu; to świadome kompromis
  z NWN:EE lifecycle.
