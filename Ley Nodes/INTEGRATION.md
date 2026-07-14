# Węzły Mocy — Integracja

## Co to robi

Gracze odkrywają starożytne **Węzły Mocy** (placeables) rozmieszczone w module.
Mogą się do nich nastroić za 100 złotych, tworząc trwałą więź (SQLite).
Stojąc przy nastroj onym węźle, mogą wchłonąć jego energię (koszt 25 ładunku),
zdobywając 10-minutową premię mechaniczną.
Węzeł regeneruje 1 ładunek / minutę, max 100.

| Typ      | Efekt                                          |
|----------|------------------------------------------------|
| Arkaniczny (1) | +2 do rzutów obronnych vs czary (10 min) |
| Wojenny (2)    | +2 do rzutów trafienia (10 min)         |
| Witalny (3)    | Regeneracja 1 PŻ / 10 s (10 min)       |
| Cieniowy (4)   | +4 do Ukrywania i Cichego Chodu (10 min)|

Gracz może mieć maks. 5 nastrojeń. Zwolnienie węzła jest trwałe i nie zwraca złota.

## Zależności

- Standardowy NWScript + NUI (nw_inc_nui).
- SQLite campaign DB `leynodes` — tworzona automatycznie.
- Brak wymagań NWNX.

## Pliki

```
Ley Nodes/scripts/
├── sql_ln.nss       — schemat SQL i wszystkie zapytania
├── lib_ln_def.nss   — stałe, ID bindów, forward declarations
├── lib_ln.nss       — logika główna + budowanie NUI + feedery
├── lib_ln_ev.nss    — handler eventów NUI (script na NuiCreate)
├── sys_on_load.nss  — OnModuleLoad: CREATE TABLE IF NOT EXISTS
├── sys_on_enter.nss — OnClientEnter: powiadomienie o nastrojeniach
└── test_ln.nss      — OnUsed placeable: rejestruje węzeł, otwiera panel
```

Skopiuj do scripts/ modułu również `lib_nui.nss` i `lib_nui_utility.nss`
(znajdziesz je w `Mailbox/Scripts/`).

## Jak włączyć

1. **Hooki modułu**:
   - `OnModuleLoad` → `sys_on_load` (lub dołącz `LnCreateTables()` do istniejącego)
   - `OnClientEnter` → `sys_on_enter` (lub dołącz call do istniejącego)

2. **Placeables węzłów** — w Toolsecie utwórz placeable (np. kamienny słup, runiczna stela):
   - **Tag** — unikalny string, np. `LN_OGROD_01` (staje się kluczem DB)
   - **Name** — wyświetlana nazwa, np. `Kamienny Krąg Mocy`
   - **Local Int** `LN_TYPE` — typ węzła: `1/2/3/4`
   - **OnUsed** → `test_ln`

3. Umieść dowolną liczbę węzłów na mapach; każdy musi mieć unikalny tag.

## Co celowo pominięto

- **Cooldown między sycyfonami** — wystarczy ograniczenie ładunku węzła.
- **Animacja rytuału** — ActionPlayAnimation przed sycyfonem można dodać.
- **Efekt wizualny na węźle** (pulsujące światło) — wymaga dodatkowego
  heartbeat lub VFX placeable; dobrze pasuje jako rozszerzenie.
- **Degeneracja nastrojenia** — więź jest permanentna; korozja w czasie
  byłaby kolejną warstwą mechaniki.
- **Panel DM** — Mistrz Gry może ręcznie UPDATE ln_nodes.charge w DB.
