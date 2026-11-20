# Familiar Bond — Instrukcja integracji

## Co to jest

Familiar Bond to system więzi z zwierzęciem-towarzyszem (znamię wiedźmy).
Gracz wybiera jednego z 5 towarzyszy, zleca mu zadania i zarządza więzią przez interfejs NUI.
Wszystkie dane są przechowywane w SQL (kampania `familiar`).

## Wymagania

- Neverwinter Nights: Enhanced Edition (NUI API)
- Brak wymagań NWNX

## Podpięcie hooków modułu

W skryptach zdarzeń modułu wywołaj odpowiednie funkcje:

### OnModuleLoad
```
#include "lib_fam_def"
// ...
FamCreateTables();
```
Lub skorzystaj z `sys_on_load.nss` bezpośrednio jako skryptu OnModuleLoad
(jeśli nie masz własnego).

### OnClientEnter
```
#include "lib_fam"
// ...
object oPC = GetEnteringObject();
if(GetIsPC(oPC) && !GetIsDMPossessed(oPC))
    FamRestoreEffects(oPC);
```
Lub użyj `sys_on_enter.nss` bezpośrednio.

### OnPlayerTarget
```
#include "lib_fam"
// ...
object oPC = GetLastPlayerToSelectTarget();
if(GetIsPC(oPC) && GetLocalInt(oPC, FAM_LVAR_TARGETING))
    FamOnCarryTarget(oPC);
```
Lub użyj `sys_on_target.nss` bezpośrednio.

### Opcjonalnie: OnModuleHeartbeat
Aby Czuwanie (Vigil) ostrzegało o wrogach w czasie rzeczywistym,
wywołaj `FamCheckVigil(oPC)` dla każdego gracza w heartbeat:
```
object oPC = GetFirstPC();
while(GetIsObjectValid(oPC))
{
    FamCheckVigil(oPC);
    oPC = GetNextPC();
}
```

## Kamień Więzi (Bonding Stone)

Umieść dowolny placeable w module i ustaw jego skrypt OnUsed na `test_fam`.
Sugerowany tag: `bonding_stone`.

Opcjonalnie zamiast kamienia możesz dać graczowi item (np. amulet),
którego skrypt OnActivate wywołuje `FamOpenWindow(oPC)`.

## Loot po Zbieraniu (Forage)

Domyślnie forage daje złoto (5–20 sztuk + bonus za poziom więzi).
Aby dodać niestandardowe przedmioty, utwórz blueprinty w HAK z resrefami:

| Towarzysz       | Resref           | Sugerowany item              |
|-----------------|------------------|------------------------------|
| Kruk            | `fam_loot_raven` | Błyskotka, moneta srebrna    |
| Czarny Kot      | `fam_loot_cat`   | Wiązanka ziół, korzenie      |
| Jadowita Ropucha| `fam_loot_toad`  | Jadowite jagody, grzyb       |
| Tkacz-Cień      | `fam_loot_spider`| Jedwab, kokon pająka         |
| Puchacz         | `fam_loot_owl`   | Magiczne pióro, runiczna     |

Jeśli resref nie istnieje, gracz otrzymuje dodatkowe złoto.

## SQL

Kampania: `familiar`  
Tabele: `fam_familiar`, `fam_log`

Schemat tworzy się automatycznie przy `FamCreateTables()` z `CREATE TABLE IF NOT EXISTS`.

## Efekty na graczu

- **Czuwanie (Vigil)**: +4 Słuch, +4 Spostrzegawczość przez 10 minut (ExtraordinaryEffect)
- **Żałoba (Mourning)**: -2 Mądrość, -1 Charyzma przez 24h po uwolnieniu towarzysza

Efekty są nakładane przez `ApplyEffectToObject(DURATION_TYPE_TEMPORARY, ...)` i
przywracane przy logowaniu przez `FamRestoreEffects()`.

## Pliki

| Plik                        | Opis                                       |
|-----------------------------|--------------------------------------------|
| `sql_fam.nss`               | Schema SQL, CRUD dla familiar              |
| `lib_fam_def.nss`           | Stałe, ID bindów, helpery tekstowe         |
| `lib_fam.nss`               | Logika, UI builder, handlery komend        |
| `lib_fam_ev.nss`            | Handler eventów NUI (skrypt event-script)  |
| `sys_on_load.nss`           | Init tabel — podpięcie pod OnModuleLoad    |
| `sys_on_enter.nss`          | Restore efektów — podpięcie OnClientEnter  |
| `sys_on_target.nss`         | Carry targeting — podpięcie OnPlayerTarget |
| `test_fam.nss`              | OnUsed na Kamień Więzi                     |
