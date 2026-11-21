# Vengeance Ledger — Integracja

## Co to jest

**Księga Krzywd** – system zemsty i urazy dla persistent world. Każda krzywda (śmierć z ręki
innego gracza, kradzież, klątwa) tworzy wpis w Księdze ofiary. Aktywne wpisy dają premię do
ataku i obrażeń (**Furia**). Przetrzymywane zbyt długo karzą karą do PP (**Żal**). Rozliczenie
krzywdy przez zabicie krzywdziciela nagradza tymczasowym bufem bitewnym (**Zemsta**). Gracz może
też Wyrzec się krzywdy za cenę 50 PD.

---

## Wymagane hooki modułu

| Zdarzenie | Skrypt | Rola |
|---|---|---|
| `OnModuleLoad` | `sys_on_load.nss` | Tworzy tabele SQLite |
| `OnClientEnter` | `sys_on_enter.nss` | Rejestruje gracza, aplikuje efekty |
| `OnPlayerDeath` | `sys_on_death.nss` | Tworzy wpis po śmierci z ręki PC |

Jeśli moduł ma już własne skrypty w tych hookach, wywołaj bezpośrednio:

```nss
// OnModuleLoad — po innych inicjalizacjach:
#include "lib_vend_def"
VendCreateTables();

// OnClientEnter:
#include "lib_vend"
object oPC = GetEnteringObject();
if (GetIsPC(oPC)) { VendRegisterPlayer(oPC); ApplyVendEffects(oPC); }

// OnPlayerDeath — na końcu skryptu śmierci:
#include "lib_vend"
// (patrz sys_on_death.nss — wywołaj VendAddGrudge + VendCheckFulfillment)
```

---

## Otwieranie UI

Podepnij `test_vend.nss` jako **OnUsed** do placeable (np. mroczna tablica, krwawy ołtarz, czarna
księga). Normalny gracz otwiera okno; DM może wstrzykiwać testowe wpisy.

Lub wywołaj bezpośrednio:
```nss
#include "lib_vend"
CreateVendWindow(oPC);
```

---

## Dodawanie krzywd ręcznie (DM / integracja z innymi systemami)

```nss
#include "lib_vend"

// nWrongType: VEND_WRONG_KILLED=1, VEND_WRONG_STOLEN=2, VEND_WRONG_CURSED=3
// sItemTag: tag przedmiotu (dla STOLEN), "" w pozostałych przypadkach
VendAddGrudge(oVictim, oWrongdoer, VEND_WRONG_STOLEN, "item_tag");
```

Funkcja ignoruje duplikaty (nie doda dwóch aktywnych wpisów tego samego typu dla tej samej pary).

---

## Mechanika — szczegóły

| Efekt | Warunek | Wartość | Tag efektu |
|---|---|---|---|
| **Furia** (+AB, +OBR magiczne) | ≥1 aktywny wpis | +1/+1 za wpis, max +3 | `VEND_FURY` |
| **Żal** (–PP) | wpis starszy niż 21 dni | –1 PP za wpis, max –3 | `VEND_RESENT` |
| **Zemsta** (+AB, +OBR, +rzuty) | zabicie krzywdziciela | +2/+2/+2 na 1h | `VEND_FULFILL` |

Efekty Furia i Żal są permanentne (reaplikowane przy logowaniu i zmianie stanu). Zemsta jest
tymczasowa (3600 sekund).

---

## Zależności

- **NWN:EE 87.8193.37+** — wymagane `GetEffectTag()` / `TagEffect()` (dodane w EE)
- **lib_nui.nss + lib_nui_utility.nss** — dostępne w tym repo (Mailbox, Appearance); wrzuć
  do skryptów modułu, jeśli jeszcze ich nie masz
- **NWNX**: brak — w pełni vanilla NWN:EE

---

## Co celowo pominięto

- **Auto-wykrywanie kradzieży i kląt**: NWN bez NWNX nie dostarcza niezawodnego zdarzenia
  OnItemStolen PC→PC. Wpisuj ręcznie przez VendAddGrudge() lub DM.
- **Alianse / krzywdy na bliskich**: mechanika "wróg wroga" to osobny moduł.
- **Wielokrotne wpisy tego samego typu w tej samej parze**: system blokuje duplikaty —
  jedno aktywne Morderstwo na parę. Drugi kill tworzy wpis dopiero po rozliczeniu pierwszego.
- **Edycja historii**: historia jest tylko do odczytu; wpisy archiwalne nie mogą być usunięte.
