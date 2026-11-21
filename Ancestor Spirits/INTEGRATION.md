# Ancestor Spirits — Duchy Przodków

## Co to robi
System kultu przodków dla dark fantasy CRPG. Gracz raz wybiera jeden z 5 rodowodów krwi (Wojowniczy, Magiczny, Lotrzykowski, Szlachecki, Wiesniaezy), skladajac ofiare ze zlota w zamian za Laske (0–100). Zgromadzona Laske wydaje na przywolanie jednego z 3 duchow przodkow przynaleznych do rodu — kazdy daje inny tymczasowy efekt mechaniczny i ma 24h cooldown. NUI zawiera dwa widoki: wybor rodu (jednorazowy) i panel oltarza z paskiem Laski, trzema wierszami przodkow ze statusem i historia ostatnich 5 przywolan.

## Wymagania
- NWN:EE 8193.35.14+
- Brak zaleznosci od NWNX
- Baza SQL: kampania `anc` (SQLite, tworzona automatycznie przy starcie modulu)

## Pliki
| Plik | Rola |
|---|---|
| `sql_anc.nss` | Warstwa SQL: tabele, CRUD |
| `lib_anc_def.nss` | Stale, dane przodkow, aplikacja efektow, AncInvokeAncestor |
| `lib_anc.nss` | Budowanie NUI, feed danych, handlery akcji |
| `lib_anc_ev.nss` | Handler zdarzen NUI (skrypt zdarzenia okna) |
| `sys_on_load.nss` | OnModuleLoad — tworzy tabele SQL |
| `sys_on_enter.nss` | OnClientEnter — rejestruje PC i pokazuje stan Laski |
| `test_anc.nss` | OnUsed dla placeabla-oltarza |
| `lib_nui.nss` | Wspoldzielona biblioteka NUI (kopia z Mailbox) |
| `lib_nui_utility.nss` | Wspoldzielona biblioteka NUI utils |

## Jak wlaczyc w istniejacym module
1. Dodaj wszystkie skrypty z folderu `Scripts/` do HAK lub bezposrednio do modulu.
2. Podepnij `sys_on_load` do zdarzenia **OnModuleLoad** modulu.
3. Podepnij `sys_on_enter` do zdarzenia **OnClientEnter** modulu.
4. Dodaj placeable (np. `plc_altar2` lub dowolny oltarz) do modulu.
5. Ustaw **OnUsed** tego placeabla na `test_anc`.

## Zależnosci SQL
Trzy tabele w kampanii SQLite `anc`:
- `anc_chars` — rodowod i stan Laski per postac (klucz: UUID)
- `anc_cooldowns` — znaczniki czasu ostatnich przywolan (klucz: UUID + ancestor_id)
- `anc_history` — historia do 5 ostatnich przywolan per postac

Wszystkie tabele sa idempotentnie tworzone przez `AncCreateTables()` (CREATE TABLE IF NOT EXISTS).

## Efekty przodkow

| Ród | Przodek (slot 0 / 1 / 2) | Efekt |
|---|---|---|
| Wojowniczy | Ragnar Zelazny | STR +4 / 10 min |
| Wojowniczy | Zbroja Krwi | AC +4 / 5 min |
| Wojowniczy | Duchy Berserow | Haste + STR +4 / 2 min |
| Magiczny | Stara Wiedzma | INT +4 / 10 min |
| Magiczny | Mistrz Ritualow | WIS +4 / 10 min |
| Magiczny | Straznik Runow | Spell Resistance +10 / 10 min |
| Lotrzykowski | Czarny Noz | DEX +4 / 10 min |
| Lotrzykowski | Mistrzyni Cieni | Niewidzialnosc / 1 min |
| Lotrzykowski | Gildyjny Szpieg | Hide+MoveS +10 / 30 min |
| Szlachecki | Lord Ashenvale | CHA +4 / 10 min |
| Szlachecki | Pani Fortuny | WIS+INT+CHA +2 / 10 min |
| Szlachecki | Krwawa Rada | Saves ALL +5 / 5 min |
| Wiesniaezy | Stara Zielarka | Temp HP +50 / 1h |
| Wiesniaezy | Matka Ziemia | Immunity Disease / 2h |
| Wiesniaezy | Duch Pol | CON +4 + Regen 2/6s / 10 min |

## Co celowo pominieto
- Animacje przywolania i efekty dzwiekowe (wymagalyby zasobow w HAK).
- Mozliwosc zmiany rodu — jest to celowa, permanentna decyzja fabularna.
- Plik `.mod` — srodowisko nie obsluguje pakowania modulu; uzyj Toolset NWN:EE.
- Ochrona przed DM-restem (resetem buflow) — out of scope dla tej wersji.
