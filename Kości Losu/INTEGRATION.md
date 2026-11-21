# Kości Losu — Instrukcja integracji

## Co to robi

Stół do gry w kości (poker-dice) dla klimatu dark fantasy. Dwóch graczy (postać i karczmarz NPC)
rzuca po 5 kości d6. Wygrywają układy: para, dwie pary, trójka, full, kareta, pięć jednakowych.
Wyjątkowe wyniki wywołują efekty fabularne (błogosławieństwo lub klątwa).
Wyniki są trwale zapisywane w SQLite per-postać (wygrane, straty, złoto, seria).
Wspólna pula jackpotu rośnie z każdym zakładem.

## Hooki modułu

| Zdarzenie     | Skrypt do podpięcia |
|---------------|---------------------|
| OnModuleLoad  | `sys_on_load`       |
| OnNuiEvent    | `lib_dice_ev`       |

W Toolsecie:
1. Otwórz Module Properties → Scripts.
2. Ustaw `OnModuleLoad` na `sys_on_load` (lub dołącz wywołanie `DiceCreateTables()` do istniejącego skryptu load).
3. Ustaw `OnNuiEvent` na `lib_dice_ev` (lub dodaj `#include "lib_dice_ev"` i wywołaj main() z istniejącego handlera).

## Placeable "stół do gry"

1. Umieść dowolny placeable (np. `plc_tableround` — okrągły stół karczmowy).
2. W zakładce Scripts ustaw `OnUsed` na `test_dice`.
3. Ustaw `Useable = TRUE`.

## Baza danych (SQLite)

Skrypt `sys_on_load` tworzy kampanię `dice` z tabelami:
- `dice_records` — statystyki per-postać (UUID, imię, wygrane, straty, złoto, seria).
- `dice_jackpot` — globalna pula jackpotu (domyślnie seed 200 gp).

Tabele są idempotentne (`CREATE TABLE IF NOT EXISTS`), więc można bezpiecznie uruchamiać wielokrotnie.

## Zależności NWNX

Brak. Moduł używa wyłącznie NWScript + NUI + SQLite (wbudowane w NWN:EE 8193.36+).

## Mechanika zakładu

- Minimalna stawka: 10 gp, maksymalna: 5000 gp.
- Remis zwraca stawkę.
- Wygrana: +stawka gp (1:1).
- Przegrana: −stawka gp.
- 5% każdej stawki (min 1 gp) zasila pulę jackpotu.
- Pięć jednakowych (gracz): zgarnia całą pulę jackpotu + błogosławieństwo (+1 atak/rzuty na 1h).
- Pięć jedynek (gracz): przegrywa zakład + klątwa (−1 rzuty obronne na 30 min).

## Co celowo pominięto

- Gra wieloosobowa (gracz vs gracz) — wymagałaby kolejkowania NUI i synchronizacji.
- Dźwięki kości — wymagałyby zasobów w haku.
- Obrazki ścianek kości — wymagałyby TGA/DDS w haku; zastąpiono liczbami tekstowymi.
- Limit dzienny zakładów — nie zakłada się trybu PW; można dodać kolumnę `last_roll_date` w DB.
