# Mithridate — Integracja z istniejącym modułem NWN

## Co to jest

System mithridatyzacji: gracz może przy Stole Aptekarza systematycznie zażywać kontrolowane dawki
10 trucizn, by budować odporność (poziomy 0–4). Wyższe poziomy dają premię do rzutów obronnych
Wytrwałości vs Trucizna i redukują obrażenia. Pełna odporność (poziom 4) neutralizuje
daną truciznę całkowicie. Na poziomie 3+ można sporządzić antidotum za złoto.

## Wymagane hooki

| Zdarzenie modułu | Skrypt       | Uwaga                                            |
|------------------|--------------|--------------------------------------------------|
| OnModuleLoad     | sys_on_load  | Tworzy tabelę SQLite `mit_tolerance`             |
| OnClientEnter    | sys_on_enter | Przywraca trwałe efekty po relogu               |

Jeśli masz już własny `OnModuleLoad`/`OnClientEnter`, dodaj wywołania ręcznie:

```nss
// W OnModuleLoad:
#include "sql_mit"
MitCreateTables();

// W OnClientEnter:
#include "lib_mit"
object oPC = GetEnteringObject();
if(GetIsPC(oPC) && !GetIsDMPossessed(oPC))
    DelayCommand(2.0, MitApplyTolerance(oPC));
```

## Jak wystawić okno graczowi

Umieść w module placeable z tagiem `apothecary_table` i ustaw mu OnUsed → `test_mit`.
Możesz też wywołać `MitShowWindow(oPC)` z dowolnego innego skryptu (dialog NPC, item OnActivate).

## Pliki skryptów do dodania do haka / skryptek modułu

```
lib_nui.nss
lib_nui_utility.nss
lib_mit_def.nss
sql_mit.nss
lib_mit.nss
lib_mit_ev.nss
sys_on_load.nss
sys_on_enter.nss
test_mit.nss
```

## Zależności NWNX

Brak. Moduł działa na czystym NWN:EE (1.69+).

Możliwe rozszerzenie z NWNX: przy użyciu `NWNX_Damage_SetDamageEventScript` można przechwytywać
obrażenia od trucizny i odejmować je proporcjonalnie do tolerancji (zamiast polegać wyłącznie
na premii do rzutu obronnego). Tolerancja per-trucizna jest już przechowywana w SQL, więc
rozszerzenie sprowadza się do mapowania `POISON_ID` na typy trucizn NWN.

## SQL

Kampania bazy: `"mithridate"` (osobny plik `mithridate.db`).
Tabela: `mit_tolerance` (char_uuid, poison_id, tolerance, success_doses, total_doses, overdoses, last_dosed_at).

Migracja jest idempotentna (`CREATE TABLE IF NOT EXISTS`), bezpieczna przy każdym starcie modułu.

## Co celowo pominięto

- Brak dedykowanej grafiki (tła okna, ikon trucizn) — można dodać do haka i podmienić refresy.
- Antidotum korzysta z `nw_it_mpotion015` (standardowa mikstura) jako placeholdera — docelowo
  należy dodać własny resref z odpowiednią ikoną i scriptami OnActivate.
- Efekt odporności jest jednym globalnym buforem Fort vs Poison opartym na najwyższym poziomie
  tolerancji. Dla rozróżnienia per-trucizna wymagane jest NWNX.
- Brak mechanizmu importowania istniejących efektów trucizny NWN (np. `EffectPoison`) —
  system działa jako warstwa odporności na dawkę, nie jako nakładka na cały system trucizn.
