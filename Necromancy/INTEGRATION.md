# Necromancy — Instrukcja integracji

## Co to robi

System nekromancji umożliwia graczom przywoływanie poległych stworów jako
nieumarłych sług (Szkielet / Zombie / Cień / Wight). Słudzy są persystentni
(baza SQL), zużywają Esencję Dusz i towarzyszą graczowi na mapie. Panel NUI
pozwala zarządzać listą sług, dokarmiać ich esencją i rozwiązywać więzy.

## Mechanika — skrót

| Element | Opis |
|---|---|
| Esencja Dusz | Waluta zdobywana z zabijania stworów; koszt przywołania: 60 pkt |
| Typy sług | Szkielet (CR<5), Zombie (CR 5–9), Cień (undead→Cień), Wight (CR≥10) |
| Limit sług | 1–5 (rośnie co 5 poziomów postaci) |
| Rozpad | Co ~6 s odejmowany jest drain (2–6 pkt/tick); sługa ginie przy 0 esencji |
| Persystencja | Sluga i jego esencja zapisywane są w kampanijnej bazie "nec" |

## Pliki

| Plik | Rola |
|---|---|
| `sql_nec.nss` | Schema SQLite, CRUD — jedyne miejsce z zapytaniami |
| `lib_nec_def.nss` | Stałe, ID bindów, pomocniki typów |
| `lib_nec.nss` | Budowanie okna NUI, cały gameplay (bind/feed/dismiss/spawn/decay) |
| `lib_nec_ev.nss` | Handler eventów NUI — podepnij jako `nui_script` |
| `sys_on_load.nss` | `CREATE TABLE IF NOT EXISTS` przy starcie modułu |
| `sys_on_enter.nss` | Rejestracja gracza + respawn sług po zalogowaniu |
| `sys_on_leave.nss` | Zapis HP i usunięcie obiektów przy wylogowaniu |
| `sys_module_hb.nss` | Tick decay + sync HP (co 6 s / co 30 s) |
| `sys_on_target.nss` | Odbiór targetu z trybu wybierania celu (wiązanie zwłok) |
| `test_nec.nss` | OnUsed na placeable — otwiera panel + daje 200 esencji testowo |

## Zależności

- **NWNX**: nie wymagane.
- **Kampanijne SQLite**: tak — baza o nazwie `"nec"` (plik `nec.sqlite` lub
  kampania o takiej nazwie). Tabele tworzone są automatycznie przy
  `OnModuleLoad`.
- **Blueprinty stworów** (resrefs w `lib_nec_def.nss`):

  | Typ | Domyślny resref | Uwaga |
  |---|---|---|
  | Szkielet | `nw_s_skelwar` | stock NWN |
  | Zombie | `nw_zombie01` | stock NWN |
  | Cień | `nw_s_shadow` | stock NWN |
  | Wight | `nw_s_wight` | stock NWN |

  Jeśli te resrefy nie istnieją w twoim hak, zaktualizuj stałe
  `NEC_RESREF_*` w `lib_nec_def.nss`.

## Jak włączyć w istniejącym module

### 1. Module OnModuleLoad
```
// Jeśli masz już skrypt:
#include "lib_nec_def"
// ...gdzieś w main():
NecCreateTables();

// Lub ustaw sys_on_load.nss bezpośrednio jako skrypt OnModuleLoad
```

### 2. Module OnClientEnter
```
#include "lib_nec"
// w main():
object oPC = GetEnteringObject();
if (GetIsPC(oPC) && !GetIsDMPossessed(oPC)) {
    NecRegisterPC(oPC);
    DelayCommand(2.0, NecSpawnServants(oPC));
}
```

### 3. Module OnClientLeave
```
#include "lib_nec"
// w main():
object oPC = GetExitingObject();
if (GetIsPC(oPC) && !GetIsDMPossessed(oPC))
    NecDespawnServants(oPC);
```

### 4. Module OnHeartbeat
```
#include "lib_nec"
// Wywołaj w istniejącym heartbeacie lub ustaw sys_module_hb.nss:
NecHeartbeat();
```

### 5. Module OnPlayerTarget
```
#include "lib_nec"
// w main() — sprawdź tylko jeśli jest ustawiona flaga NEC_LVAR_TARGETING:
object oPC = GetLastPlayerToSelectTarget();
if (GetIsPC(oPC) && GetLocalInt(oPC, NEC_LVAR_TARGETING)) {
    DeleteLocalInt(oPC, NEC_LVAR_TARGETING);
    NecBindCorpse(oPC, GetTargetingModeSelectedObject());
}
// lub użyj sys_on_target.nss bezpośrednio
```

### 6. Esencja z zabijanych stworów (opcjonalne)
Wstaw do skryptu OnDeath każdego obszaru/stwora:
```
#include "lib_nec"
// w main() (np. z nw_c2_default7.nss):
NecOnCreatureDeath(GetLastKiller(), OBJECT_SELF);
```

### 7. Otwieranie panelu przez gracza
Ustaw `test_nec.nss` (lub własny skrypt z `NecOpenWindow(oPC)`) jako OnUsed
na placeable (np. „Trupie Archiwum", „Nekronomikon" — item z OnActivate).

## Co celowo pominięto

- **Komendy sług** (Atakuj / Stój / Cofnij) — wymagałyby oddzielnego sub-menu
  NUI lub chatu; można dodać jako rozszerzenie przez panel szczegółów.
- **Unikalny wygląd sług** (zmiana koloru/modelu) — wymaga NWNX_Appearance lub
  przypisania blueprintów HAK per typ; szkielet/zombie/cień/wight z NWN stock
  wyglądają odpowiednio bez modyfikacji.
- **Atak zarażenia** sług (odradzanie nowych nieumarłych z wrogów) — celowo
  pominięty, by uniknąć lawinowego rozrostu stworów w grze multiplayer.
- **Przekraczanie limitu przez talenty/featy** — mechanizm skalowania przez
  poziom jest celowo prosty; builder może nadpisać `NecGetMaxServants`.
