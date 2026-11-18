# Lombard — Zastawnik (Pawnbroker)

## Podpięcie hooków w module

| Zdarzenie modułu          | Skrypt do wywołania  | Uwaga                                           |
|--------------------------|----------------------|-------------------------------------------------|
| OnModuleLoad             | `sys_on_load`        | Tworzy tabelę SQLite (idempotentne)             |
| OnPlayerTargetingSelect  | `sys_on_target`      | Obsługuje wybór przedmiotu w trybie celowania   |

Jeżeli moduł posiada już własne skrypty dla tych zdarzeń, wywołaj
`ExecuteScript("sys_on_load", OBJECT_SELF)` i analogicznie dla target —
lub dodaj `#include "lib_pawn"` i bezpośrednie wywołanie `PawnOnPlayerTarget`.

## Uruchomienie zastawnika

Umieść placea (NPC lub skrzynię) i ustaw mu skrypt `test_pawn` w polu **OnUsed**.
Gracz klika placea → otwiera się okno NUI Zastawnika.

## Zależności

- **Bez NWNX** — moduł działa na czystym NWN:EE / NWSCRIPT.
- Campaign DB: plik `pawnbroker.sqlite` tworzony automatycznie.
- Shared utilities: `lib_nui.nss`, `lib_nui_utility.nss` — zawarte w folderze.

## Mechanika (skrótowo)

1. Gracz klika placea → `CreatePawnWindow(oPC)`
2. Widok *Przeglądaj*: lista aktywnych zastawów z terminami i kosztami wykupu.
3. Widok *Zastaw*: 5 gniazd; kliknięcie gniazda → tryb celowania → wybór przedmiotu.
   Poinformowany o wartości oferty (25% GPV przedmiotu) przed potwierdzeniem.
4. Po potwierdzeniu: przedmiot znika z ekwipunku, gracz otrzymuje złoto, rekord w SQLite.
5. Wykup: gracz płaci pożyczkę + 10% odsetek za każdy miniony dzień.
   Po 7 dniach zastaw "wygasa" (flaga), lecz nadal można go wykupić (odsetki rosną).
   Brak automatycznego usuwania — zastawnik zawsze ma towar.

## Parametry konfigurowalne (sql_pawn.nss)

| Stała                    | Domyślna wartość | Opis                                   |
|--------------------------|-----------------|----------------------------------------|
| `PAWN_EXPIRY_DAYS`       | 7               | Dni do "wygaśnięcia" zastawu           |
| `PAWN_INTEREST_PCT_DAY`  | 10              | Odsetki % za każdy dzień zwłoki        |
| `PAWN_MAX_ACTIVE`        | 10              | Maks. aktywnych zastawów na postać     |
| `PAWN_VALUE_RATIO`       | 0.25            | Procent GPV wypłacany jako pożyczka    |

## Celowo pominięto

- Automatyczne usuwanie wygasłych zastawów — zastawnik jako NPC nigdy nie wyrzuca towaru;
  to decyzja DM. Można dodać periodyczne czyszczenie w OnHeartbeat.
- Interfejs DM do przeglądania wszystkich zastawów — `PawnGetAll()` jest gotowe w `sql_pawn.nss`,
  wystarczy podpiąć pod dowolny DM-command.
- Animacje/dźwięki przy otwieraniu okna — można dodać przez `PlaySound` / `ActionPlayAnimation`.
- Sortowanie listy zastawów — aktualnie po dacie zastawu (ASC).
