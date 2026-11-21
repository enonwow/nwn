# Burial Rites — Instrukcja integracji

## Wymagania

- NWN Enhanced Edition 8193+
- Standardowa biblioteka NWN EE (`nw_inc_nui`)
- Brak zależności NWNX

## Hooki modułu

Podepnij poniższe skrypty do odpowiednich zdarzeń modułu w Toolsecie lub
istniejącym skrypcie `sys_on_*` przez `ExecuteScript`:

| Zdarzenie modułu | Skrypt | Co robi |
|---|---|---|
| OnModuleLoad | `sys_on_load.nss` | Tworzy tabele SQLite (`bur_records`) |
| OnClientEnter | `sys_on_enter.nss` | Rejestruje postać, przywraca trwałe efekty |

Jeśli moduł ma już własne `sys_on_load` i `sys_on_enter`, dodaj na końcu:

```nwscript
// w sys_on_load:
ExecuteScript("sys_on_load", GetModule());   // NIE! zamiast tego:
BurCreateTables();                            // dołącz #include "lib_bur_def"

// w sys_on_enter:
ExecuteScript("sys_on_enter", GetEnteringObject());
```

Lub po prostu wywołaj odpowiednie funkcje bezpośrednio po ich dołączeniu.

## Placeable — stół grabarza

1. Stwórz w Toolsecie placeable typu "Altar" lub "Stone Table".
2. Ustaw skrypt `OnUsed` = `test_bur`.
3. Opcjonalnie: nadaj tag `BUR_WORKBENCH`.

## Przedmioty (opcjonalne)

Ryty Przyzwoity i Święty wymagają przedmiotów. Stwórz je w Toolsecie
z tagami (tag = resref dla uproszczenia):

| Przedmiot | Tag | Opis |
|---|---|---|
| Świeca Pogrzebowa | `bur_candle` | Mała świeca woskowa |
| Olejek Ostatni | `bur_oil` | Flakonik z ostatnim namaszczeniem |
| Pergamin Imion | `bur_scroll` | Pergamin z imionami poległych |

Dodaj te przedmioty do loot tables, sklepu kapłańskiego lub jako nagrody
questowe. Bez nich gracze mogą korzystać tylko z Ubogiego Pochówku.

## Baza danych

Dane są zapisywane w kampanii SQLite o nazwie `burial` (plik `burial.sqlite`
w folderze `/modules/<moduł>/`). Tabela:

```sql
CREATE TABLE IF NOT EXISTS bur_records (
    pc_uuid TEXT PRIMARY KEY,
    total_pauper INTEGER DEFAULT 0,
    total_proper INTEGER DEFAULT 0,
    total_sacred INTEGER DEFAULT 0,
    last_pauper_time INTEGER DEFAULT 0
);
```

## Mechanika skrótowo

- **Ubogi Pochówek** — bezpłatny, odnowienie 1h; `+1 do obron vs. śmierć` (1h)
- **Przyzwoity Pochówek** — 50gp + Świeca; `AC+1, obrony+1, regen 1HP/6s` (4h)
- **Święty Ryt Przejścia** — 200gp + Olejek + Pergamin; `AC+2, obrony+2, regen 2HP/6s, +10% ruchu` (8h)
- **Piętno Grabarza** (5 świętych rytów) — trwały efekt wizualny, flaga `BUR_LVAR_MARKED`
- **Błogosławieństwo Spokoju** (25 łącznych) — trwały `+1 obrony vs. śmierć`

## Co celowo pominięto

- Brak fizycznego zbierania zwłok/tokenów — usunięto zależność od OnCreatureDeath
- Brak animacji grabarza/NPC — czysta mechanika bez dialogów
- Brak zarządzania grobami na mapie — to materiał na osobny moduł
