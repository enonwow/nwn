# Hazard — Trzy Smocze Kości: Integration Guide

## Wymagania

- NWN:EE 8193.36+ (NUI + SQLite campaign DB)
- NWNX: **nie wymagany**
- Kampania SQLite o nazwie `haz` tworzona automatycznie przez `HazCreateTables()`

## Hooki modułu

| Zdarzenie modułu | Skrypt               |
|------------------|----------------------|
| OnModuleLoad     | `sys_on_load.nss`    |
| OnClientEnter    | `sys_on_enter.nss`   |

Jeśli moduł ma już własne OnModuleLoad / OnClientEnter, dodaj wywołanie:

```nss
// OnModuleLoad
HazCreateTables();

// OnClientEnter
object oPC = GetEnteringObject();
if(GetIsPC(oPC) && !GetIsDMPossessed(oPC)) HazRegisterPlayer(oPC);
```

## Placeable — stół hazardowy

1. W toolsecie utwórz placeable (np. `plc_table`).
2. Ustaw zdarzenie **OnUsed** na `test_haz`.
3. Dodaj skrypt do HAK modułu razem ze wszystkimi plikami `lib_haz*.nss`,
   `sql_haz.nss`.

Alternatywnie wywołuj `HazOpenWindow(oPC)` z dowolnego zdarzenia
(rozmowy NPC, skrzyni, klawisza skrótu przez Ribbon System).

## Pliki

```
Hazard/Scripts/
  sql_haz.nss        — schemat SQLite + zapytania
  lib_haz_def.nss    — stałe, ID bindów, ID przycisków, LVARy
  lib_haz.nss        — mechanika gry, scoring, budowa UI, funkcje feed
  lib_haz_ev.nss     — główny handler eventów NUI
  sys_on_load.nss    — OnModuleLoad: tworzy tabele SQL
  sys_on_enter.nss   — OnClientEnter: rejestruje gracza
  test_haz.nss       — OnUsed dla placeable-demo
```

## Mechanika gry — Trzy Smocze Kości

Gracz stawia zakład (10–5000 szt. złota) i rzuca trzema sześciościennymi
kośćmi przeciwko krupierowi (dom).

### Kolejność rundy

1. Gracz ustawia zakład i opcjonalnie włącza **Cenę Krwi**.
2. Kliknięcie **Rzuć kości** → rzut 3k6.
3. Gracz może kliknąć każdą kość, by ją **trzymać** (podświetlona).
4. Kliknięcie **Przerzuć wolne** → wolne kości przerzucone (raz na rundę).
5. Kliknięcie **Stój** → krupier ujawnia swoje kości i wynik porównany.

### Układy (rosnąco)

| Układ             | Punktacja        | Opis                    |
|-------------------|------------------|-------------------------|
| Wysoka Kość       | 3–18             | suma trzech kości       |
| Para Bazyliszka   | 3000–3605        | para + kicker           |
| Wąż Schodowy      | 4100–4400        | sekwencja (n, n+1, n+2) |
| Smok Trojaki      | 5100–5600        | trójka                  |

### Wypłaty (w przypadku wygranej)

| Układ gracza    | Podstawowy zysk  |
|-----------------|-----------------|
| Wysoka Kość/Para| 1× zakład       |
| Wąż Schodowy    | 1,5× zakład     |
| Smok Trojaki    | 2× zakład       |

Remis (równy wynik): zakład zwrócony bez zysku ani straty.

### Cena Krwi

Przed rzutem gracz może zaznaczyć **Cena Krwi**:

- **Wygrana** → wszystkie wypłaty pomnożone przez ×3.
- **Porażka** → standardowa strata złota PLUS 10% maksymalnych punktów HP
  jako obrażenia od negatywnej energii.

### AI krupiera

Krupier rzuca 3k6. Jeśli wynik < Para Bazyliszka z dwójek (3201 pkt),
przerzuca najgorszą jedną kość. Strategia jest prosta i łatwa do pokonania
przez sprawne trzymanie kości.

## Baza danych

Tabela `haz_players` w kampanii `haz`:

```sql
CREATE TABLE IF NOT EXISTS haz_players (
  uuid       TEXT PRIMARY KEY,
  char_name  TEXT NOT NULL DEFAULT '',
  wins       INTEGER NOT NULL DEFAULT 0,
  losses     INTEGER NOT NULL DEFAULT 0,
  pushes     INTEGER NOT NULL DEFAULT 0,
  gold_won   INTEGER NOT NULL DEFAULT 0,
  gold_lost  INTEGER NOT NULL DEFAULT 0
);
```

## Co celowo pominięto

- Gra wieloosobowa (gracz vs gracz) — wymagałaby synchronizacji sesji.
- Animacje rzutu kośćmi — NWN NUI nie obsługuje animacji sprite.
- Dług (możliwość gry na kredyt) — celowo, by unikać exploitów złota.
- Limity dzienne / ograniczniki anty-farm — do rozważenia przez serwer.
