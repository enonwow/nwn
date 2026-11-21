# Trap Maker — Warsztat Pułapek

Mechaniczny system tworzenia i rozmieszczania pułapek. Gracze zbierają komponenty, składają 6 typów pułapek na stole rzemieślniczym (NUI), a następnie rozmieszczają je w środowisku przez tryb celowania. Pułapki odpalają się na pobliskie stworzenia i niszczą po aktywacji.

## Hooki modułu

Podepnij skrypty do zdarzeń modułu w toolsecie:

| Zdarzenie modułu      | Skrypt              |
|-----------------------|---------------------|
| OnModuleLoad          | `sys_on_load`       |
| OnClientEnter         | `sys_on_enter`      |
| OnPlayerTarget        | `sys_on_target`     |
| OnNuiEvent            | `lib_trap_ev`       |

Jeśli już masz własne skrypty dla tych zdarzeń, dodaj wywołania funkcji z `lib_trap` lub `lib_trap_def` do istniejących skryptów.

## Placeable warsztatu

W toolsecie stwórz dowolny Placeable (np. stół roboczy) i ustaw:
- **Tag**: dowolny (np. `TRAP_WORKSHOP`)
- **OnUsed**: `test_trap`

## Komponenty (itemy)

Stwórz w toolsecie przedmioty z tagami pasującymi do stałych z `lib_trap_def.nss`:

| Tag                  | Opis wyświetlany        |
|----------------------|-------------------------|
| `TRAP_COMP_BLADE`    | Ostrze                  |
| `TRAP_COMP_SPRING`   | Sprężyna                |
| `TRAP_COMP_DART`     | Strzałka                |
| `TRAP_COMP_POISON`   | Fiolka trucizny         |
| `TRAP_COMP_OIL`      | Kolba olejku            |
| `TRAP_COMP_FLINT`    | Krzesiwo                |
| `TRAP_COMP_POWDER`   | Fleszkiproch            |
| `TRAP_COMP_GLASS`    | Fiolka szklana          |
| `TRAP_COMP_BELL`     | Dzwoneczek              |
| `TRAP_COMP_WIRE`     | Drut                    |
| `TRAP_COMP_ROPE`     | Linka                   |
| `TRAP_COMP_HOOK`     | Hak                     |

Możesz dodać te przedmioty do loot tables potworów, sklepów lub skrzyń, żeby gracze musieli je aktywnie szukać.

## Placeable pułapki

Stała `TRAP_PLACEA_RESREF` (domyślnie `x2_plc_trap001`) musi istnieć w module lub hakpaku. Podmień na własny asset z hak-u dla lepszego efektu wizualnego (np. niewidoczny trigger lub marker pułapki).

## NWNX

Moduł **nie wymaga NWNX**. Wszystkie funkcje korzystają z wbudowanego NWScript + NUI + SQLite.

## Testy

1. Uruchom moduł, podejdź do placowalnego warsztatu, użyj go.
2. Skrypt `test_trap.nss` da ci zestaw testowych komponentów (raz na sesję).
3. W oknie NUI wybierz przepis, skuć pułapkę.
4. Zdobyta pułapka pojawi się w ekwipunku.
5. Kliknij przycisk **Rozstaw pułapkę** — kursor przejdzie w tryb celowania.
6. Kliknij na podłogę w zasięgu 5m — pułapka zostanie umieszczona.
7. Podejdź (lub wyślij inną postać) do pułapki — odpalenie nastąpi w ciągu 6 sekund (heartbeat).
8. Użyj pułapki prawym przyciskiem → próba rozbrojenia testem Disable Trap.

## Co celowo pominięto

- **HAK / własne modele** — skrypty zakładają istnienie standardowych resref-ów; do produkcji należy podmienić na własne assety.
- **Wykrywanie pasywne (Spot)** — zamierzono jako przyszłe rozszerzenie; na razie pułapkę widać, bo placeable jest widoczny. Można ukryć placeable (alpha = 0 przez NWNX_Object) i dodać heartbeat do PC sprawdzający Spot vs. detect_dc.
- **Crafting skill check** — skucie nie wymaga rzutu; można dodać Test Craft (Rogue special ability) jako opcjonalną próbę.
- **Wielokrotne efekty (AOE)** — pułapka trafia jeden cel i niszczy się; brak splash damage.
