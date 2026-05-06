# Plague — Integracja z modułem NWN

## Wymagane hooki

| Zdarzenie modułu | Skrypt |
|---|---|
| OnModuleLoad | `sys_on_load` |
| OnClientEnter | `sys_on_enter` |
| OnHeartbeat | `sys_on_heartbeat` |

Jeśli moduł ma już własne skrypty dla tych zdarzeń, wywołaj
odpowiednie funkcje Plague z istniejącego skryptu:

```nwscript
// W istniejącym OnModuleLoad:
#include "sql_plg"
// ...
PlgCreateTables();

// W istniejącym OnClientEnter:
#include "lib_plg"
// ...
object oPC = GetEnteringObject();
if(GetIsPC(oPC)) PlgOnClientEnter(oPC);

// W istniejącym OnHeartbeat:
#include "lib_plg"
// ...
object oPC = GetFirstPC();
while(GetIsObjectValid(oPC))
{
    PlgCheckProgression(oPC);
    PlgApplyPerTick(oPC);
    oPC = GetNextPC();
}
```

## Zależności

- **NWN:EE 8193+** — wymagane dla funkcji `TagEffect`, `GetEffectTag`
  (`RemoveEffect` iteruje po efektach ręcznie, więc nie wymaga NWNX)
- **SQLite (natywny NWN:EE)** — kampania `"plague"` tworzona automatycznie
- **NWNX** — *niewymagany*

## Placeable "Zwierciadło Diagnostyczne"

Stwórz dowolny placeable (np. lustro lub kryształowa kula).
Ustaw jego skrypt **OnUsed**: `test_plg`.

W trybie produkcyjnym zastąp `test_plg` dedykowanym skryptem
wywołującym wyłącznie `CreatePlgWindow(oPC)` bez opcji debug.

## Zarażanie postaci z zewnętrznych skryptów

```nwscript
#include "lib_plg"

// Zaraź gracza Bagienną Gorączką (PLG_DIS_SWAMP_FEVER = 2):
PlgContractAndNotify(oPC, PLG_DIS_SWAMP_FEVER);

// Ulecz:
PlgCureAndNotify(oPC);
```

## Przedmioty leczące

Każda choroba wymaga przedmiotu o konkretnym tagu w ekwipunku gracza.
Stwórz te przedmioty w swoim module i umieść je w świecie gry:

| Choroba | Tag przedmiotu | Propozycja nazwy PL |
|---|---|---|
| Czarna Dżuma | `plg_rem_plaga` | Napar z czarnej malwy |
| Krwawa Zgnilizna | `plg_rem_krew` | Ziołowy bandaż hemostatyczny |
| Bagienka Gorączka | `plg_rem_bagna` | Korzeń topoli bagiennej |
| Nekrotyczna Rana | `plg_rem_nkr` | Poświęcona woda |
| Przekleństwo Wilkołaka | `plg_rem_wilk` | Srebrna woda |

Przedmioty mogą być zwykłymi misc-itemami lub potionami — system
sprawdza jedynie tag (`GetItemPossessedBy`).

## Skrócone czasy do testów

Domyślne interwały (godziny rzeczywiste) są zaprojektowane pod
sesje CRPG. Do testów możesz edytować `PlgPhaseInterval` w `lib_plg_def.nss`:

```nwscript
// Zmień np. dla Bagiennej Gorączki wszystkie fazy na 60 sekund:
case PLG_PHASE_INCUBATION: return 60;
case PLG_PHASE_MILD:       return 60;
case PLG_PHASE_SEVERE:     return 60;
```

Panel debug `test_plg` oferuje też natychmiastowe zarażenie i uzdrowienie.

## Co celowo pominięto

- Transmisja przez kontakt z zainfekowanymi NPC/graczami — nie ma
  dedykowanego hooka do proximity check bez NWNX; łatwo dodać
  wywołując `PlgContractAndNotify` z trigger OnEnter lub creature
  OnHeartbeat z odpowiednią logiką odległości.
- Wizualne zmiany wyglądu postaci per-faza (bąble, bladość) — wymaga
  hak z dedykowanymi teksturami; poza zakresem tego modułu.
- System odporności / szczepień — do rozbudowania jako follow-up.
- Resetowanie SQL po utracie postaci — decyzja mechaniki serwera
  (obecne zachowanie: choroba zostaje dopóki nie wyleczona lub
  nie usunięta ręcznie z tabeli `plg_diseases`).
