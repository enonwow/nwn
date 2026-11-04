# Memento Mori — Instrukcja integracji

## Co robi moduł

Gdy gracz umiera, może wyryć **Kamień Pamiątki** (cairn stone) w miejscu śmierci
z ostatnimi słowami. Inni gracze mogą znaleźć kamień, odczytać wiadomość i „opłakać"
poległego, zyskując tymczasowe błogosławieństwo i wydłużając życie kamienia.
Po zebraniu `MMORI_LEGENDARY_THRESH` opłakujących kamień staje się **legendą**
i daje silniejszy efekt bojowy.

## Wymagane hooki w module NWN

| Zdarzenie modułu | Skrypt     | Opis |
|-----------------|------------|------|
| OnModuleLoad    | sys_on_load | tworzy tabele SQLite |
| OnPlayerDeath   | sys_on_death | zapisuje współrzędne śmierci |
| OnPlayerRespawn | sys_on_respawn | otwiera okno Ostatnich Słów |

Jeśli moduł już korzysta z własnych skryptów na tych zdarzeniach,
wywołaj odpowiednie funkcje z `lib_mmori.nss` wewnątrz istniejącego skryptu:

```nwscript
// Przykład dla OnPlayerDeath z istniejącym skryptem
#include "lib_mmori"
// ... (istniejący kod)
void main()
{
    // ... twój dotychczasowy kod ...
    MmoriOnPlayerDeath(GetLastPlayerDied());
}
```

## Skrypt OnUsed dla kamienia pamiątki

Każdy spawned cairn (`plc_brlstn1`, tag `mmori_cairn_<id>`) musi mieć
przypisany skrypt `sys_on_cairn` do zdarzenia **OnUsed**.

Możesz to ustawić przez blueprint (GUI modułu) lub skryptowo:
```nwscript
SetEventScript(oCairn, EVENT_SCRIPT_PLACEABLE_ON_USED, "sys_on_cairn");
```

Ustaw to w `MmoriSpawnCairn()` jeśli chcesz to zautomatyzować — przykład
w `lib_mmori.nss:MmoriSpawnCairn()`.

## NWNX

Moduł **nie wymaga NWNX**. Używa wyłącznie standardowego NWScript + NUI + SQLite
(`SqlPrepareQueryCampaign` z bazą `"mmori"`).

## Testowanie

1. Dodaj do modułu pusty **Placeable** z skryptem `OnUsed = test_mmori`.
2. Użyj — otworzy się okno Ostatnich Słów.
3. Zatwierdź — kamień spawnieje w bieżącej lokacji.
4. Ustaw zmienną lokalną `MMORI_TEST_MODE = "cairn"` na tym samym placeablu,
   użyj ponownie — otworzy okno pierwszego kamienia w bazie (jako obca postać).

## Strojenie

Stałe do zmiany w `lib_mmori_def.nss`:

| Stała | Domyślnie | Znaczenie |
|-------|-----------|-----------|
| `MMORI_EXPIRY_DAYS` | 14 | po ilu dniach nieaktywny kamień wygasa |
| `MMORI_LEGENDARY_THRESH` | 7 | ilu opłakujących do statusu legendy |
| `MMORI_BUFF_DURATION` | 300 | czas (s) trwania błogosławieństwa |
| `MMORI_RECLAIM_HP_BONUS` | 10 | HP przywracane za odebranie własnego kamienia |
| `MMORI_CAIRN_RESREF` | `plc_brlstn1` | resref placeablu kamienia (musi być w HAK/module) |

## Co celowo pominięto

- Powiadamianie online gracza, gdy ktoś opłakuje jego kamień — łatwe do dodania
  przez analogię do `MailNotifyOnline`.
- Mapa kamieni legendy (server-wide listing) — możliwa przez `MmoriGetLegendaryCount`
  i osobne okno NUI.
- Ekspiracja kamieni legendy — intencjonalnie trwałe; można dodać oddzielny próg.
- Customowy model 3D kamienia — `MMORI_CAIRN_RESREF` można zmienić na własny zasób w HAK.
