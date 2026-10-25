# Arcane Echo — Integracja

## Co to robi

Arcane Echo rejestruje każde rzucone zaklęcie jako trwały ślad magiczny w bazie SQL
(kampania `echo`). Gracz posiadający **Kryształ Rezonansu** (`echo_crystal`) może
otworzyć interfejs NUI, który wyświetla listę śladów w bieżącej lokacji: szkołę magii,
nazwę czaru, wiek śladu i siłę rzucającego. Kliknięcie wpisu ujawnia szczegóły, w tym
zamaskowaną tożsamość rzucającego (rasa/klasa, bez imienia). Właściciel śladów może je
za złoto zacierać.

## Hooki — co podpiąć

| Zdarzenie modułu | Skrypt |
|---|---|
| `OnModuleLoad` | dodaj wywołanie `EchoCreateTables()` z `sql_echo.nss` lub użyj bezpośrednio `sys_on_load.nss` |
| `OnClientEnter` | dodaj wywołanie `sys_on_enter.nss` (notyfikacja przy wejściu do obszaru) |
| `OnSpellCast` (moduł) | uruchom `sys_on_spell.nss` — OBJECT_SELF = rzucający, używa `GetLastSpell()` |
| placeable `OnUsed` (detektor) | ustaw `test_echo.nss` — otwiera UI |

### Alternatywa: OnSpellCastAt na obszarze

Jeśli moduł nie ma globalnego hooka `OnSpellCast`, użyj hooka `OnSpellCastAt` na każdym
obszarze lub na niewidzialnym obiekcie trigger w kluczowych lokacjach. W tym scenariuszu
`OBJECT_SELF` to cel zaklęcia; rzucający to `GetLastSpellCaster()`.

## Baza danych

- Kampania: `echo`
- Tabela: `echo_traces` — automatyczna migracja idempotentna przez `CREATE TABLE IF NOT EXISTS`
- Dane wygasają po `ECHO_DECAY_HOURS` (domyślnie 48h) — decay wywoływany przy każdym rzuceniu
  czaru oraz przy załadowaniu modułu.

## Zależności

- Czyste NWScript + NWN:EE NUI — brak NWNX.
- `lib_nui.nss` i `lib_nui_utility.nss` z repozytorium (standardowe helpery NUI).

## HAK

- Dodaj do HAK plik ikony `echo_crystal.uti` — prefab przedmiotu Kryształu Rezonansu
  (tag: `echo_crystal`). Skrypt `OnActivated` przedmiotu → `test_echo.nss`.
- Opcjonalnie: ikonki szkół magii `ir_evoca`, `ir_necro`, `ir_illus` itd.
  (jeśli brak w domyślnym HAK, etykiety tekstowe wyświetlają się bez ikony).

## Jak przetestować

1. Wrzuć skrypty do katalogu skryptów modułu.
2. Dodaj do `OnModuleLoad`: `ExecuteScript("sys_on_load", GetModule());`
3. Ustaw `test_echo.nss` jako `OnUsed` na dowolnym placeable.
4. Wejdź na obszar, użyj placeable — seed wstawi 3 testowe ślady, UI się otworzy.
5. Rzuć kilka zaklęć, odśwież listę — nowe ślady pojawiają się w czasie rzeczywistym.

## Co celowo pominięto

- Ikonki szkół magii — używamy etykiet tekstowych, by nie wymuszać konkretnego HAK.
- Detekcja śladów od NPCs jako gracze (tylko PCs mają UUID) — ślady NPC mają pusty UUID
  i wyświetlają się jako "Nieznany".
- System rang/perków wymaganych do odczytu śladów — łatwy do dokompletowania przez
  dodanie sprawdzenia umiejętności `SKILL_SPELLCRAFT` przed `EchoOpenDetector()`.
- Limit zasięgu detekcji (ślady z całego obszaru, nie z określonego promienia).
