# Sins & Absolution — Integracja

## Co to jest

System śledzenia grzechów postaci (SQLite per UUID). Każdy grzech dodaje punkty;
narastający wynik nakłada trwałe kary statystyk. Absolucja kosztuje złoto;
alternatywą jest „Mroczne Objęcie" — nieodwracalna zgoda na mrok w zamian za bonusy bojowe.

## Hooki modułu

| Zdarzenie          | Skrypt             |
|--------------------|--------------------|
| `OnModuleLoad`     | `sys_on_load`      |
| `OnClientEnter`    | `sys_on_enter`     |
| `OnUsed` (placeable) | `test_sin`       |

Plik `lib_sin_ev` podpinamy jako skrypt NUI (`NUI_EVENT_SCRIPT`) — robi to automatycznie
`SinOpenWindow` przez wywołanie `NuiCreate(oPC, jNui, SIN_WINDOW, "lib_sin_ev")`.

## Publiczne API

```nwscript
#include "lib_sin"

// Dodaj grzech (z dowolnego skryptu gry, np. OnDeath, OnTheft, OnSpellCast).
SinAddSin(oPC, SIN_TYPE_MURDER, 8, "Zabójstwo kupca w Athkatli");

// Sprawdź aktualny poziom.
int nScore = SinGetScore(oPC);

// Otwórz okno spowiedzi dla gracza (np. OnConversation NPC).
SinOpenWindow(oPC);
```

## Typy grzechów i zalecane ciężary

| Stała                | Przykłady zastosowania                               | Typowy ciężar |
|----------------------|------------------------------------------------------|---------------|
| `SIN_TYPE_MURDER`    | Zabójstwo sojusznika, niewinnego, strażnika          | 5–15          |
| `SIN_TYPE_THEFT`     | Kradzież ze sklepu/kościoła, kieszonkowanie          | 2–6           |
| `SIN_TYPE_BLASPHEMY` | Zbezczeszczenie ołtarza, obrażenie bóstwa            | 3–8           |
| `SIN_TYPE_DARK_RITUAL` | Rytuał kultystyczny, taniec z demonami             | 8–15          |
| `SIN_TYPE_BETRAYAL`  | Zdrada gildii, kompana, sojusznika                   | 4–10          |
| `SIN_TYPE_UNDEAD`    | Ożywianie zwłok, kontrola nieumarłych                | 5–10          |
| `SIN_TYPE_DEMON_PACT`| Pakt z istotą demoniczną                             | 10–20         |
| `SIN_TYPE_CORRUPTION`| Przekupstwo urzędnika, sabotaż                       | 3–7           |
| `SIN_TYPE_DESECRATION`| Profanacja grobów/kościoła, zbezczeszczenie relikwii| 3–8           |

## Progi i kary

| Próg (score) | Nazwa           | Kary                                   |
|--------------|-----------------|----------------------------------------|
| 0–9          | Czysty          | brak                                   |
| 10–24        | Skażony         | −1 Cha                                 |
| 25–49        | Nieczysty       | −2 Cha, −1 Mąd                         |
| 50–74        | Niegodziwiec    | −3 Cha, −2 Mąd, −1 Int                 |
| 75–99        | Przeklęty       | −3 Cha, −2 Mąd, −2 Int, −2 Wola       |
| 100+         | POTĘPIONY       | −4 Cha, −3 Mąd, −3 Int, −3 Wola + ikona|

Kary są supernaturalne (nie znika po odpoczynku, nie da się rozwiać Dispel Magic).

## Mroczne Objęcie

Dostępne przy ≥ 75 pkt grzechu. Nieodwracalne. Dodaje +15 pkt grzechu i:
- +2 Siły
- +2 Budowy
- +1 obrażenia nekrotyczne (każde trafienie)
- Odporność na Strach

Blokuje absolucję na zawsze. Efekty tagowane `SIN_EMBRACE_TAG`; przywracane przy
każdym `OnClientEnter`.

## Absolucja

Koszt: `score × 80` sz. Dostępna tylko dla niezapieczętowanych. Zeruje score i log.

## Przykład integracji z systemem walk

```nwscript
// W skrypcie OnDeath NPC:
object oKiller = GetLastKiller();
if (GetIsPC(oKiller))
{
    // Jeśli ofiara jest sojuszniczym NPC lub strażnikiem:
    if (GetFactionEqual(oKiller, GetFactionLeader(OBJECT_SELF)) == FALSE)
        SinAddSin(oKiller, SIN_TYPE_MURDER, 10, "Zabójstwo " + GetName(OBJECT_SELF));
}
```

## Zależności

- **NWNX:** brak
- **SQLite:** kampania `"sins"` (baza tworzona automatycznie w `sys_on_load`)
- **NWN:EE:** min. build 8193.14 (NUI + `TagEffect` + `EffectIcon`)

## Co celowo pominięto

- Automatyczne wyzwalanie grzechów z systemu walki — wymaga modyfikacji
  skryptów `OnDeath`/`OnSpellCast`; integracja przez API jest zamierzona.
- Kara dla klas kleryk/paladyn (utrata slotów zaklęć) — wymaga ingerencji
  w system zaklęć lub NWNX; można dołożyć w `SinApplyPenalties`.
- UI konfesjonału NPC-driven — wystarczy podpiąć `SinOpenWindow(oPC)` do
  `OnConversation` odpowiedniego NPC.
- Rozgrzeszenie połowiczne (np. zmniejszenie o 50%) — celowo nie ma, by
  absolucja miała wagę decyzji.
