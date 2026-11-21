# Epitafium — Instrukcja integracji

## Co to jest

Moduł tworzy fizyczne nagrobki w miejscach śmierci PC. Gracz po śmierci
może wyryć epitafium (max 200 znaków) i podać przyczynę. Inni gracze
mogą kliknąć nagrobek, przeczytać napis i złożyć hołd (50 zł → buff
AC+1 / Spot+2 na 1h). Nagrobki persystują przez 30 dni w kampanijnym
SQLite i są respawnowane przy każdym załadowaniu modułu.

## Zależności

- NWN:EE (NUI API)
- Brak NWNX (opcjonalnie: NWNX_Object dla lepszej trwałości placeabli)
- Placeable resref `plc_grvmark1` z podstawowej gry (kamień nagrobny)

## Hooki do podpięcia

| Zdarzenie modułu       | Skrypt             |
|------------------------|--------------------|
| OnModuleLoad           | `sys_on_load`      |
| OnPlayerDeath          | `sys_on_pdeath`    |

Jeśli masz już własny `OnModuleLoad` / `OnPlayerDeath`, dodaj wywołania
na końcu istniejących skryptów:

```nss
// W swoim OnModuleLoad:
#include "lib_tomb"
// ... twój kod ...
TombCreateTables();
TombDeleteExpired();
TombRespawnAll();

// W swoim OnPlayerDeath:
#include "lib_tomb"
// ... twój kod ...
object oPC = GetLastPlayerDied();
if(GetIsObjectValid(oPC) && GetIsPC(oPC) && !GetIsDM(oPC))
    TombOnDeath(oPC);
```

## Opcjonalne: przekazanie zabójcy

Jeśli twój moduł korzysta ze zdarzenia OnCreatureDeath dla PC, możesz
tam ustawić:

```nss
// W OnCreatureDeath (na PC):
SetLocalObject(OBJECT_SELF, "TOMB_KILLER", GetKiller());
```

Skrypt `sys_on_pdeath` odczyta ten lvar i wypełni pole przyczyny śmierci.
Bez tego pola gracz może wpisać przyczynę ręcznie w oknie NUI.

## Test

1. Umieść w obszarze testowym placeable z `OnUsed = test_tomb`.
2. Uruchom moduł, wejdź jako PC, użyj placeable.
3. Pierwsze użycie → okno epitafium z lokalizacją placeable.
4. Wpisz tekst, kliknij "Wyryt napis" → nagrobek pojawia się w miejscu.
5. Użyj placeable ponownie → okno odczytu nagrobka z przyciskiem hołdu.
6. Kliknij "Złóż hołd" (50 zł) → buff + aktualizacja licznika.
7. Zrestartuj moduł → nagrobek powinien pojawić się ponownie (respawn).

## Weryfikacja resrefa

Użyty resref `plc_grvmark1` to standardowy kamień nagrobny z NWN.
Jeśli chcesz użyć własnego placeabla z haka, zmień stałą
`TOMB_STONE_RESREF` w `lib_tomb_def.nss`.

## Co celowo pominięto

- **Admin NUI** z listą wszystkich nagrobków — można dodać jako
  rozszerzenie (wystarczy odczytać `TombGetAllActive()` i wyświetlić
  w oknie).
- **Animacja rycia** (emote przy tworzeniu nagrobka) — wymaga
  `AssignCommand` z `ActionPlayAnimation`, można dodać w `TombFinalizeMemorial`.
- **Unikalne placeable per obszar** — obecna implementacja używa jednego
  resrefa; zróżnicowanie wyglądu w zależności od biome/obszaru możliwe
  przez zamianę `TOMB_STONE_RESREF` na funkcję wybierającą po tagu obszaru.
- **Limit nagrobków per PC** — nie wprowadzono; można dodać sprawdzenie
  COUNT w SQL przed insertem.
- **NWNX** — nie jest wymagany; bez NWNX placeables nie są trwałe po
  twardym resecie serwera, ale SQL je odtwarza przy OnModuleLoad.
