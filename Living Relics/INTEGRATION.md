# Living Relics — Integration Guide

## Wymagania
- NWN:EE (1.69+)
- Brak wymagań NWNX — cały system działa na czystym NWScript + SQL Campaign DB.

## Pliki skryptów
Skopiuj zawartość folderu `Scripts/` do folderu `override/` lub do HAK modułu.

## Hooki modułu

### OnModuleLoad
Wywołaj inicjalizację tabel:
```nss
#include "lib_mrel_def"
// w module OnLoad:
MrelCreateTables();
```
Lub po prostu podepnij `sys_on_load.nss` jako skrypt OnModuleLoad.

### OnClientEnter
Wywołaj synchronizację przedmiotów dla wchodzącego gracza:
```nss
#include "lib_mrel"
// w OnClientEnter:
object oPC = GetEnteringObject();
if(GetIsPC(oPC)) {
    MrelSyncItems(oPC);
}
```
Lub podepnij `sys_on_enter.nss`.

### OnPlayerRest
Relikwie pochłaniają sny podczas odpoczynku (+1 pamięć) i auto-budzą się gdy pełne:
```nss
// podepnij sys_on_rest.nss jako OnPlayerRest
```

### OnPlayerTarget
Obsługuje wybór przedmiotu do atunementu:
```nss
// podepnij sys_on_target.nss jako OnPlayerTarget
```

### OnCreatureDeath (creature lub moduł)
Aby relikwie zbierały wspomnienia z walk, wywołaj po śmierci stworzenia:
```nss
#include "lib_mrel"
// w skrypcie OnCreatureDeath (lub module OnCreatureDeath):
object oKiller = GetLastKiller();
MrelOnKill(oKiller);  // +2 pamięci dla zabójcy

// Opcjonalnie: +1 dla świadków w pobliżu
object oNear = GetNearestCreature(CREATURE_TYPE_PLAYER_CHAR, TRUE, OBJECT_SELF, 1);
while(GetIsObjectValid(oNear) && GetDistanceToObject(oNear) <= 10.0)
{
    if(oNear != oKiller) MrelOnWitness(oNear);
    oNear = GetNearestCreature(CREATURE_TYPE_PLAYER_CHAR, TRUE, OBJECT_SELF, GetObjectByTag("NEXT_OBJ_IDX"));
}
```

### OnCombatRoundEnd (opcjonalnie)
Aby wykrywać moment "przeżycia przy niskim HP":
```nss
#include "lib_mrel"
// Na końcu rundy lub po walce:
object oPC = /* gracz */;
MrelOnSurvive(oPC); // sprawdza wewnętrznie, czy HP < 20%
```

## Otwieranie okna
Ustaw placeable z `test_mrel.nss` jako OnUsed, lub wywołaj bezpośrednio:
```nss
#include "lib_mrel"
MrelCreateWindow(oPC);
```

## Baza danych
- Kampania: `"mrel"` (plik `mrel.sqlite` w katalogu kampanii modułu)
- Tabela: `mrel_relics`
- Bezpieczna migracja: `CREATE TABLE IF NOT EXISTS` — można włączyć do istniejącego modułu bez kolizji.

## Co celowo pominięto
- **Automatyczne skanowanie ekwipunku przy każdej akcji** — mogłoby być drogie; zamiast
  tego synchronizacja następuje przy wejściu i przy otwieraniu okna.
- **Efekty wizualne (VFX)** na przebudzeniu — można dodać `ApplyEffectToObject` z
  `EffectVisualEffect(VFX_*)` przed efektami w `MrelApplyWakeEffect`.
- **Wspomnienia na broni vs. pancerzu** — celowo nie różnicujemy bonu zależnie od
  typu przedmiotu; ułatwia to wchodzenie bez HAK z ikonami.
- **Mnóstwo poziomów głodu powyżej 5** — system jest zamknięty (H5→H2 po przebudzeniu),
  co daje naturalny cykl bez nieskończonego skalowania.
