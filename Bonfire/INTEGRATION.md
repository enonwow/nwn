# Bonfire System — Integracja

## Co to robi

System ognisk (wzorowany na Dark Souls). Gracz może zapalić ognisko przy
użyciu Łuczywa (`bfire_tinder`), odpocząć przy nim (pełne leczenie, usunięcie
debuffów, uzupełnienie Flaszek Ocalenia), szybko podróżować do innych zapalonych
ognisk, oraz czytać i zostawiać wiadomości dla innych graczy.

## Wymagania

- NWN:EE z obsługą NUI (`nw_inc_nui` w hakpaku)
- `lib_nui.nss` i `lib_nui_utility.nss` w hakpaku (ze Appearance/Mailbox)
- Brak wymagań NWNX dla rdzenia systemu

## Podpięcie hooków

| Zdarzenie modułu       | Skrypt                  |
|------------------------|-------------------------|
| OnModuleLoad           | `sys_on_load`           |
| OnClientEnter          | `sys_on_enter`          |
| NUI Event Script       | `lib_bfire_ev` (auto)   |

Jeśli masz już własne skrypty OnModuleLoad / OnClientEnter, wywołaj z nich:
```nss
// OnModuleLoad:
#include "lib_bfire_def"
BfireCreateTables();

// OnClientEnter:
#include "lib_bfire_def"
object oPC = GetEnteringObject();
if(GetIsPC(oPC)) BfireEnsurePC(GetObjectUUID(oPC));
```

## Konfiguracja ognisk w module

1. Umieść placeable'a w obszarze.
2. Nadaj mu tag w formacie `bonfire_XXXX` (np. `bonfire_oboz`, `bonfire_ruiny`).
3. Ustaw skrypt OnUsed: `test_bfire`.
4. Opcjonalne zmienne lokalne na placeablu (ustawiane w toolsecie):
   - `BFIRE_START_LIT` (int, 1) — ognisko startuje zapalone
   - `BFIRE_DISPLAY_NAME` (string) — nazwa wyświetlana w UI zamiast pola Name

## Item: Łuczywo (bfire_tinder)

Stwórz item (np. Miscellaneous Small) z tag `bfire_tinder` i dodaj do haka.
Można go stackować; jedno użycie zużywa 1 sztukę ze stosu.
Gracze mogą go kupować u handlarzy lub znajdować jako loot.

## Testy

1. Umieść 2+ placeable'y z tagami `bonfire_test1`, `bonfire_test2`.
2. Na `bonfire_test1` ustaw `BFIRE_START_LIT = 1`.
3. Wejdź do modułu jako gracz — bonfire_test1 powinno być od razu dostępne.
4. Przy `bonfire_test2`: użyj ogniska → w UI powinna być opcja "Zapal Ognisko"
   (wymaga `bfire_tinder` w ekwipunku).
5. Po zapaleniu: opcja "Podróżuj" powinna pokazać oba ogniska na liście.

## Pominięto celowo

- Respawn wrogów przy odpoczynku — wymaga NWNX lub własnej logiki per-obszar
- Przywrócenie slotów czarów przy odpoczynku — wymaga NWNX_Creature
- Animacja "siadania przy ognisku" — wymaga custom animacji w haku
- Limit wiadomości per gracz — można dodać SQL-owo jeśli gracze spamują
