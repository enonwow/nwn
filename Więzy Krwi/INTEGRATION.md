# Więzy Krwi — Instrukcja integracji

## Co to robi

System umożliwia graczom zawieranie magicznych kontraktów krwi z innymi graczami.
Każdy kontrakt jest pieczętowany PŻ obu stron i przechowywany trwale w SQLite.

## Hooki modułu do podpięcia

| Hook NWN                | Skrypt w module        |
|-------------------------|------------------------|
| OnModuleLoad            | `sys_on_load`          |
| OnClientEnter           | `sys_on_enter`         |
| OnModuleHeartbeat       | `sys_on_hb`            |
| OnPlayerDeath           | `sys_on_pc_killed`     |
| OnNuiEvent              | `lib_wkr_ev`           |
| OnPlayerTarget          | wywołaj `WkrOnPlayerTarget(GetLastPlayerToSelectTarget())` |

Jeśli moduł ma już skrypty OnModuleLoad / OnClientEnter / OnHeartbeat,
dopisz wywołania funkcji z `lib_wkr` do istniejących skryptów.

## OnPlayerTarget

NWN nie ma dedykowanego hooka — `EnterTargetingMode` wywołuje event
`OnPlayerTarget` na module. Jeśli korzystasz z innego modułu który też
używa trybu celowania, rozróżnij kontekst przez zmienną lokalną lub
sprawdź czy gracz ma otwarty token WKR_WINDOW:

```nss
#include "lib_wkr"
void main()
{
    object oPC = GetLastPlayerToSelectTarget();
    if(NuiFindWindow(oPC, WKR_WINDOW) != 0)
        WkrOnPlayerTarget(oPC);
    // ... inne systemy
}
```

## Baza danych

Dane przechowywane są w kampanii o nazwie `wkr` (plik `wkr.sqlite`).
Tabela tworzona idempotentnie przy `OnModuleLoad`.

## Testowanie

1. Umieść placeable z OnUsed = `test_wkr` na mapie testowej.
2. Uruchom dwa konta (DM + PC lub dwa PC).
3. PC A używa placeable → otwiera się okno Więzy Krwi.
4. PC A: zakładka „Zaproś" → wybierz typ, wpisz kwotę (dla Długu), kliknij PC B.
5. PC B otrzymuje powiadomienie; otwiera okno i klika „Przyjmij".
6. Oboje tracą 5 PŻ; powiązanie pojawia się na liście obu graczy.

## Zależności NWNX

Brak. Moduł używa wyłącznie NWScript + natywnego NUI + `SqlPrepareQueryCampaign`.

## Ograniczenia i pominięcia

- Przy Długu Krwi i offline'owym wierzycielu złoto jest odnotowywane
  w `terms_json.paid_offline` — wymagana ręczna dystrybucja przez DM.
- Rozwiązanie więzi jest jednostronne (nie wymaga zgody partnera) —
  by wymagać konsensusu, dodaj pole `dissolve_request_uuid` do tabeli.
- Brak UI powiadomień push — gracze są informowani przez `SendMessageToPC`
  i `FloatingTextStringOnCreature`.
- Klątwa za Straż Krwi nie jest automatycznie aplikowana za śmierć podopiecznego
  bez strażnika — wymaga dodatkowego hooka `OnPlayerDeath` z logiką lokalizacji.
