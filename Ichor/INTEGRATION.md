# Ichor — Namaszczenie Ostrza: Instrukcja integracji

## Zależności

- **NWN:EE 8193.36+** (NUI, `SqlPrepareQueryCampaign`, `AddItemProperty DURATION_TYPE_TEMPORARY`)
- Brak wymagań NWNX.
- Kampania SQLite: plik `ichor.sqlite` tworzony automatycznie w katalogu kampanii serwera.

## Wymagane hooki w module

### 1. `OnModuleLoad`

```
#include "lib_ichor_def"
void main() {
    IchorCreateTables();   // lub wywołaj plik sys_on_load.nss
}
```

Alternatywnie: dodaj `ExecuteScript("sys_on_load", GetModule())` do istniejącego OnLoad.

### 2. `OnClientEnter`

```
ExecuteScript("sys_on_enter", GetEnteringObject());
```

Czyści przeterminowane rekordy i informuje gracza o aktywnych powłokach.

### 3. `OnCreatureDeath` (opcjonalnie, ale zalecane)

Aby gracze mogli zbierać ichor automatycznie po zabiciu stworów:

```
// W skrypcie OnDeath istoty (lub w module-level OnDeath):
#include "lib_ichor"
void main() {
    IchorMarkCorpse(OBJECT_SELF);
    // ... reszta logeiki śmierci
}
```

lub bezpośrednio ustaw zmienną lokalną na istocie przed jej śmiercią:

```
SetLocalString(oCreature, "ICHOR_FORCE_TYPE", "demon");   // force override
```

Po śmierci istota ma `ICHOR_TYPE` ustawione automatycznie przez rasę (`GetRacialType`).

### 4. Placeable „Corpus Ichor" (zbieranie ichoru)

Dodaj do modułu placeable z:
- `OnUsed` → skrypt, który wywołuje `IchorHarvestFromCorpse(GetLastUsedBy(), OBJECT_SELF)`
- Ustaw tag `ichor_corpus`

Opcjonalnie: `sys_on_death.nss` tworzy placeable w miejscu śmierci:
```
// (w sys_on_death.nss, po IchorMarkCorpse):
if(GetLocalString(oDead, "ICHOR_TYPE") != "")
    CreateObject(OBJECT_TYPE_PLACEABLE, "ichor_corpus", GetLocation(oDead));
```

### 5. Otwieranie panelu

Ichor panel otwiera się przez `IchorOpen(oPC)`. Możesz to podpiąć pod:
- Aktywację specjalnego przedmiotu (rozmowa → `IchorOpen`)
- Węzeł rozmowy z NPC-rzemieślnikiem
- Domyślny klawisz skrótu (wymaga NWNX_Player)
- Testowy placeable: skrypt `test_ichor.nss`

## Typy stworzeń i efekty

| Typ klucza     | Rasa NWN                  | Efekt item property           |
|----------------|---------------------------|-------------------------------|
| `undead`       | RACIAL_TYPE_UNDEAD        | +1k6 obrażeń negatywnych      |
| `demon`        | RACIAL_TYPE_OUTSIDER + ZŁY| +1k6 obrażeń ogniowych        |
| `dragon`       | RACIAL_TYPE_DRAGON        | +2k6 obrażeń ogniowych        |
| `lycanthrope`  | (ICHOR_FORCE_TYPE)        | +2 do rzutu ataku             |
| `construct`    | RACIAL_TYPE_CONSTRUCT     | +1k6 obrażeń elektrycznych    |
| `fey`          | RACIAL_TYPE_FEY           | +1 bonus ulepszeń (atak+obr.) |
| `aberration`   | RACIAL_TYPE_ABERRATION    | +1k6 obrażeń kwasowych        |
| `beast`        | RACIAL_TYPE_BEAST/ANIMAL  | +1k4 obrażeń (zimno)          |

## Uwagi projektowe

- **Maks. 2 powłoki** jednocześnie na jednej broni (sloty 1 i 2).
- **Czas trwania**: 3600 sekund (1 godzina gry/real-time). Zmienna `ICHOR_DURATION_SEC`.
- **Usuń** przycisk usuwa pierwszą tymczasową właściwość danego typu z broni. Stałe właściwości broni z tego samego bucket-u (np. permanentny ogień) NIE są usuwane — tylko te z `DURATION_TYPE_TEMPORARY`.
- Esencje są przechowywane w kampanijnej bazie SQLite (`ichor_essences`), a nie jako przedmioty w ekwipunku.
- `test_ichor.nss` dodaje po jednej esencji każdego typu i otwiera panel — przydatne do demonstracji bez stawiania stworzeń.

## Co celowo pominięto

- Receptury mieszania esencji (mogłoby być rozszerzeniem).
- Wizualny efekt VFX na broni przy aktywnej powłoce (wymaga NWNX_Effect lub EffectBeam).
- Różne poziomy mocy esencji zależne od CR sttworzenia (uproszczono do stałego efektu per typ).
- Cooldown na zbieranie z tego samego ciała przez wielu graczy (każdy może zebrać raz).
