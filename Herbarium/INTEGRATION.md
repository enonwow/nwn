# Herbarium — Integracja z istniejącym modułem

## Wymagania

- NWN 1.87+ (UUID, SqlPrepareQueryCampaign, NUI)
- NWNX: **nie wymagany**
- Hak: musi zawierać `lib_nui.nss` i `lib_nui_utility.nss` (standardowe dla tego repo)

## Hooki modułu

| Zdarzenie         | Podłącz skrypt         |
|-------------------|------------------------|
| OnModuleLoad      | `sys_on_load`          |
| OnClientEnter     | `sys_on_enter` (opcja) |

> `sys_on_enter` jest opcjonalny — jedynie powiadamia gracza o zasobach ziół.

## Węzły ziół (placeables)

1. Umieść dowolny placeable w obszarze (np. `PLC_MushMoss`, krzewy).
2. Ustaw jego **OnUsed** script na `test_herb`.
3. Dodaj zmienną lokalną `HERB_TYPE` (Integer) = 1–8:

| Wartość | Zioło              | Sezon   |
|---------|--------------------|---------|
| 1       | Krwawnik           | Jesień  |
| 2       | Nocny Cień         | Zima    |
| 3       | Słonecznik Polny   | Wiosna  |
| 4       | Strach-Ziele       | Każda   |
| 5       | Żelazokora         | Lato    |
| 6       | Grobowamiętka      | Zima    |
| 7       | Pustokwiat         | Każda   |
| 8       | Wiedźmia Koniczyna | Każda   |

Każdy węzeł ma 3 plony; odnawiają się po 24 godzinach rzeczywistych od ostatniego zbioru.

## Dziennik Zielarza (stand)

Umieść dodatkowy placeable (np. stół aptekarza) z `OnUsed = test_herb`  
i **bez** zmiennej `HERB_TYPE` (lub z wartością 0) — otworzy sam dziennik.

## Baza danych

Dwie tabele w campaign DB `herbarium`:

- `herb_nodes` — stan plonów per węzeł (PK: tag placeable)
- `herb_player` — zasoby i wiedza per postać (PK: uuid + herb_type)

Obie tabele tworzone idempotentnie przez `HerbCreateTables()` w `sys_on_load`.

## Co celowo pominięto

- **Craftowanie** — zioła są zużywane bezpośrednio; integracja z systemem alchemii
  możliwa przez wywołanie `HerbPlayerConsume()` z zewnętrznego modułu.
- **Ikony ziół** — wymagałyby dedykowanych zasobów w hak; zastąpione opisem tekstowym.
- **Odnawianie przez heartbeat** — regen obliczany lazily przy otwarciu okna (oszczędność
  skryptów modułowych).
- **Limity per postać** — brak maksymalnej liczby ziół w sakwie; można dodać
  górny próg w `HerbPlayerGive()`.
