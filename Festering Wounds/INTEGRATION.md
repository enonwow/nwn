# Festering Wounds — Integracja

## Wymagania

- NWN:EE 8193.36.13+ (`GetEffectTag`, `TagEffect`, `ExtraordinaryEffect`)
- Brak NWNX (moduł w pełni vanilla NWN:EE)

## Hooki modułu

| Zdarzenie | Skrypt do podpięcia lub wywołania |
|---|---|
| `OnModuleLoad` | `sys_on_load` — tworzy tabelę SQL |
| `OnClientEnter` | `sys_on_enter` — przywraca efekty, startuje pętlę serca |
| `OnClientLeave` | `sys_on_leave` — zatrzymuje pętlę serca |

Jeśli serwer ma już własne skrypty na te zdarzenia, wywołaj odpowiednie funkcje bezpośrednio:

```nwscript
// W istniejącym OnModuleLoad:
#include "lib_fwnd_def"
FwndCreateTables();

// W istniejącym OnClientEnter:
#include "lib_fwnd"
// (po sprawdzeniu GetIsPC)
int nCount = FwndCountWounds(oPC);
if(nCount > 0) { ... }
SetLocalInt(oPC, FWND_LVAR_LOOP_RUN, 1);
DelayCommand(5.0, FwndPCLoop(oPC));

// W istniejącym OnClientLeave:
SetLocalInt(oPC, FWND_LVAR_LOOP_RUN, 0);
```

## Zadawanie ran (przez DM lub mechanikę serwera)

W skrypcie OnHitCastSpell itemu, OnPhysicalAttackHit (NWNX_Events), lub dowolnym OnUsed:

```nwscript
#include "lib_fwnd"

// nType: FWND_TYPE_VAMPIRE / NECROTIC / DEMONIC / VENOM / CURSED
FwndInflictWound(oTarget, FWND_TYPE_VAMPIRE, GetName(OBJECT_SELF));
FwndApplyWoundEffects(oTarget);
```

Wywołanie `FwndInflictWound` dwukrotnie z tym samym typem wzmacnia istniejącą ranę o 1 (do max 5), nie tworzy duplikatu.

## Otwieranie UI z poziomu innego skryptu

```nwscript
#include "lib_fwnd"
FwndOpen(oPC);
```

## Itemy lecznicze

Stwórz stackowalne itemy (Miscellaneous Small) z poniższymi tagami. Gracze kupują/zbierają je i leczą rany przez UI.

| Tag | Leczy ranę |
|---|---|
| `fwnd_holy_water` | Ukąszenie Wampira (CON) |
| `fwnd_life_salve` | Gnilna Rana (STR) |
| `fwnd_ward_herb` | Szrama Demoniczna (WIS) |
| `fwnd_antitoxin` | Głębokie Zatrucie (DEX) |
| `fwnd_exorcism` | Przeklęte Cięcie (ATK) |
| `fwnd_life_leaf` | Dowolna rana (-1 siła) |

Użycie lekarstwa niszczy 1 sztukę ze stosu.

## Baza danych

Campaign DB: `festering_wounds`, tabela `fwnd_wounds`.  
Schemat: `(id, pc_uuid, wound_type, severity, inflicted_at, last_progressed, source_name)`.

## Testowanie

1. Umieść na mapie placeable z OnUsed = `test_fwnd`.
2. Kliknij kolejno — każde kliknięcie dodaje kolejny typ rany (1→2→3→4→5→1...).
3. UI otworzy się automatycznie.
4. Sprawdź efekty w ekranie postaci (kary STR/CON/WIS/DEX/ATK).

## Co celowo pominięto

- **Wizualne tintowanie postaci** — wymaga NWNX_Appearance lub Engine plugin
- **Automatyczny wyzwalacz przy trafieniu** — wymaga NWNX_Events (OnPhysicalAttackHit); bez NWNX rany zadawane są przez osobne skrypty DM/itemy
- **Timer odliczania do progresji w UI** — wymagałby synchronizacji heartbeat z frontendem; dodaje złożoność bez proporcjonalnej wartości
- **Limit ran** — celowo brak (maks. 5 typów × siła 5 = max kary; mechanika jest samodyscyplinująca)
