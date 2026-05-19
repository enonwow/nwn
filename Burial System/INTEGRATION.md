# Burial System — Integration Guide

## Czego potrzeba

| Zależność | Wersja | Uwagi |
|-----------|--------|-------|
| NWN:EE    | ≥ 8193.36 | NUI, SqlPrepareQueryCampaign |
| `lib_nui.nss` + `lib_nui_utility.nss` | z Mailbox lub Appearance | GetNuiScaleDimension, NUI helpers |
| NWNX      | nie wymagany | — |

## Hooki modułu do podpięcia

| Zdarzenie modułu | Skrypt |
|-----------------|--------|
| OnModuleLoad    | `sys_on_load.nss` |
| OnPlayerTargeting | `sys_on_target.nss` |

Jeśli masz już `sys_on_target.nss` z innego modułu (np. Mailbox), **dodaj wywołanie**
`BurOnPlayerTarget(OBJECT_SELF);` na końcu istniejącego skryptu zamiast zastępować plik.

## Placeable w Toolsecie

1. Stwórz lub wybierz dowolny placeable (np. „Płyta Nagrobna", grave slab).
2. Ustaw pole **OnUsed** na skrypt `test_bur`.
3. Umieść go w obszarze dostępnym dla graczy.

Gracze klikają placeable, by otworzyć **Rejestr Grobów**.
Przycisk **Pogrzeb** włącza tryb celowania — gracz klika na martwe ciało NPC.

## Baza danych

Dane zapisywane w kampanii `burial` (SQLite):

```
bur_graves     — każdy pochówek z typem rytuału, obszarem, datą
bur_meditation — cooldown medytacji per gracz per grób
```

Obie tabele tworzone idempotentnie przez `BurCreateTables()` przy starcie modułu.

## Rytuały pochówku

| Typ | Koszt | Efekt dla grabarza |
|-----|-------|--------------------|
| Prosty | 0 sz | HP Regen +2 przez 1 godz. |
| Zaszczytny | 100 sz | Attack +1 przez 2 godz. |
| Przeklęty | 0 sz | Klątwa na zbezcześciciela |

## Medytacja przy grobie

Raz na 24 godziny (czas rzeczywisty z SQLite):

- Prosty → +25 PD
- Zaszczytny → +50 PD, Saving Throws +1 / 1 godz.
- Przeklęty → Saving Throws -1 / 30 min (kara za niebezpieczną refleksję)

## Zbezczeszczenie grobu

Dostępne w UI dla grobów, które gracz sam pochował:

| Typ grobu | Złoto | Efekt karny |
|-----------|-------|-------------|
| Prosty | 20–80 sz | brak |
| Zaszczytny | 70–130 sz | Attack -1 / 1 godz. |
| Przeklęty | 20–80 sz | Curse: wszystkie cechy -2 / 2 godz. |

## Co celowo pominięto

- Sprawdzanie odległości od grobu przy medytacji/profanacji — zakłada się, że gracze odgrywają
  podróż do miejsca pochówku; łatwo dodać GetDistanceBetweenLocations z zapisaną lokalizacją.
- Wizualne znaczniki (placeables na mapie) — wymagałoby NWNX_Object lub zapisu lokalizacji
  i SpawnObject per grób; pominięte, by unikać zależności NWNX.
- Pochówek graczy-postaci — celowo wyłączony; mechanika powinna dotyczyć wrogów NPC.
- Eksport listy grobów do globalnego rejestru — każdy gracz widzi tylko swoje pochówki.
