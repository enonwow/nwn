# Chaos Surge — integracja w module NWN:EE

## Opis

System **Pulsacji Nicości** śledzi poziom chaosu magicznego (0–100 CP) dla każdego
gracza-czarodzieja. Powyżej progu 60 CP każdy rzut zaklęcia ma rosnącą szansę
wyzwolenia **Pulsacji** — losowego efektu z tabeli 20 wpisów (od Haste i leczenia
po polimorfię, ślepotę i eksplozję apokaliptyczną).

## Hooki modułu

| Zdarzenie modułu        | Skrypt do podpięcia  | Co robi                                  |
|-------------------------|----------------------|------------------------------------------|
| OnModuleLoad            | `sys_on_load`        | Tworzy tabelę SQLite (`chaos_state`)     |
| OnClientEnter           | `sys_on_enter`       | Ładuje stan gracza z DB                  |
| OnClientLeave           | `sys_on_leave`       | Zapisuje stan do DB przed wyjściem       |
| OnPlayerRest            | `sys_on_rest`        | Redukuje CP o 35 po odpoczynku           |

## Podpięcie pod rzucanie zaklęć (NWNX — zalecane)

Bez NWNX CP muszą być dodawane manualnie przez `ChaosAddCP(oPC, n)`.
Z NWNX podpnij się pod `NWNX_ON_SPELL_CAST_AT_BEFORE`:

```nss
// W OnModuleLoad, po ChaosCreateTables():
NWNX_Events_SubscribeEvent("NWNX_ON_SPELL_CAST_AT_BEFORE", "sys_on_spellcast");
```

Przykładowy `sys_on_spellcast.nss`:

```nss
#include "lib_chaos"

void main()
{
    object oPC = OBJECT_SELF;
    if(!GetIsPC(oPC) || GetIsDM(oPC)) return;

    // Tylko klasy rzucające zaklęcia zdobywają chaos
    int nClass = GetClassByPosition(1, oPC);
    if(nClass != CLASS_TYPE_WIZARD
    && nClass != CLASS_TYPE_SORCERER
    && nClass != CLASS_TYPE_BARD) return;

    int nSpell  = GetSpellId();
    int nCircle = GetSpellLevel(nSpell, nClass); // 0–9
    if(nCircle <= 0) return;

    // Base gain: krąg zaklęcia
    int nGain = nCircle;

    // Bonus za rzucanie w stresie
    int nMaxHP  = GetMaxHitPoints(oPC);
    int nCurHP  = GetCurrentHitPoints(oPC);
    if(nCurHP <= nMaxHP / 10) nGain += 10;
    else if(nCurHP <= nMaxHP / 3) nGain += 5;

    ChaosAddCP(oPC, nGain);
}
```

## Otwieranie okna przez gracza

Dołącz do modułu item **„Kryształ Chaosu"** (dowolny activatable) z OnActivate:

```nss
#include "lib_chaos"
void main()
{
    object oPC = GetItemActivator();
    ChaosOpenWindow(oPC);
}
```

Lub użyj placeable'a z `test_chaos.nss` w strefie testowej.

## Zależności NWNX

- Opcjonalnie: `NWNX_Events` do hooka na rzucanie zaklęć.
- Brak innych zależności NWNX; cały system działa na czystym NWN:EE + SQLite.

## SQL

Kampania (plik DB): `chaos`
Tabela: `chaos_state (uuid PK, chaos_points, total_surges, log_json, updated_at)`

## Co celowo pominięto

- Automatyczny HUD z paskiem chaosu (zawsze widoczny) — wymaga `OnModuleHeartbeat`
  lub tik-systemu; można dodać wzorując się na `Hungry Thirsty System`.
- Różnicowanie klas — aktualnie każdy gracz może zyskiwać CP (bez filtra klasy
  w skrypcie NWNX); dodać sprawdzenie klasy w `sys_on_spellcast`.
- Odporność na chaos — nie ma itemu/featu chroniącego przed pulsacją;
  proste rozszerzenie: sprawdź `GetLocalInt(oPC, "CHAOS_IMMUNE")`.
- Efekty wizualne z HAK — VFX używają standardowych stałych NWN:EE;
  jeśli moduł ma własny HAK z lepszymi efektami, podmień stałe w `ChaosExecuteSurge`.
