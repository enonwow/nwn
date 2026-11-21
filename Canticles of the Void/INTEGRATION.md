# Canticles of the Void — Integracja

## Wymagania

- NWN:EE 8193.14+ (NUI, SqlPrepareQueryCampaign, TagEffect/RemoveTaggedEffects)
- Brak NWNX — czysty NWN:EE

## Hooki modułu

### OnModuleLoad
Wywołaj (lub dołącz do istniejącego skryptu):
```
#include "lib_cvoid_def"
CvoidCreateTables();
```
Lub ustaw skrypt `sys_on_load` jako OnModuleLoad.

### OnClientEnter
Wywołaj (lub dołącz):
```
#include "lib_cvoid"
object oPC = GetEnteringObject();
if(GetIsPC(oPC) && !GetIsDMPossessed(oPC)) {
    CvoidTickDailyDecay(oPC);
    CvoidApplyTaintEffects(oPC, CvoidGetTaint(oPC));
}
```
Lub ustaw `sys_on_enter` jako OnClientEnter.

### OnNUIEvent
Ustaw `lib_cvoid_ev` jako skrypt OnNUIEvent modułu.
Jeśli używasz już innego skryptu NUI, dodaj na początku:
```
if(NuiFindWindow(NuiGetEventPlayer(), CVOID_WINDOW) == NuiGetEventWindow()) {
    ExecuteScript("lib_cvoid_ev", OBJECT_SELF);
    return;
}
```

## Obiekt testowy

Utwórz Placeable (np. "Otchłaniony Ołtarz") z tagiem `void_altar`.
Ustaw OnUsed = `test_cvoid`.

## Jak działa

1. Gracz używa ołtarza → otwiera się okno "Kantylen Otchłani".
2. Okno pokazuje 8 ciemnych kantylen z kosztami i CD.
3. Gracz wybiera kantylę, klika "Odpraw" → efekt + zmaza rośnie.
4. Zmaza persystuje w bazie między sesjami (kampania `cvoid`).
5. Przy progu 25/50/75/100 zmazy dochodzą permanentne kary/bonusy.
6. Opcja "Oczyszczenie" usuwa 25 zmazy za 500 sz. (CD 24h).
7. Zmaza naturalnie spada o 1 / dobę przy logowaniu.

## Zmaza (Void Taint) — progi

| Zmaza | Efekt |
|-------|-------|
| 0–24  | Brak trwałych efektów |
| 25–49 | −1 do rzutu obronnego na Wolę |
| 50–74 | −2 do wszystkich rzutów obronnych, −2 Charyzma |
| 75–99 | −4 do wszystkich rzutów obronnych, −2 Charyzma, efekt ciemności |
| 100   | −6 rzuty obronne, −4 Charyzma, ALE +10 do trafienia, +5 obrażeń |

## Co celowo pominięto

- Brak własnych grafik (hak.hak) — ikony i tło okna są domyślne NUI.
- Brak globalnego cooldownu między różnymi kantylenami (każda ma własny).
- Brak systemu osiągnięć/historii — zakres jest celowo wąski.
- Brak animacji cast — tylko VFX_IMP_NEGATIVE_ENERGY przy odprawieniu.
