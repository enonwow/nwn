# Haunted Armory — Integracja

## Co to robi

Moduł śledzi liczbę zabójstw dokonanych każdą bronią melee. Wraz z akumulacją
krwi broń przechodzi przez 5 poziomów nawiedzenia (10 / 30 / 75 / 150 / 300
zabójstw), zyskując rosnące bonusy do ataku i obrażeń kosztem coraz silniejszych
klątw (drain Mądrości, zamęt, stałe osłabienie). Gracz może **Objąć Klątwę**
(×2 bonusy i kary) lub **Oczyścić** broń Święconą Wodą. Interfejs NUI "Kronika
Broni" pokazuje historię ofiar, aktualny poziom i dostępne akcje.

## Zależności

| Zależność       | Wymagana? | Uwagi                                          |
|-----------------|-----------|------------------------------------------------|
| NWN:EE 8193.x+  | TAK       | NUI API (`NuiCreate`, `NuiSetBind`, …)         |
| NWNX:EE         | TAK       | Moduł `NWNX_Events` do hooka OnCreatureDeath   |
| Campaign DB     | TAK       | Automatycznie tworzona jako `haunted_armory`   |

Bez NWNX kill-tracking nie zadziała. Alternatywnie można ustawić skrypt
`haunt_on_death` jako `OnDeath` każdego stworzenia ręcznie (mniej wygodne).

## Pliki skryptowe

| Plik                    | Rola                                             |
|-------------------------|--------------------------------------------------|
| `lib_haunt_def.nss`     | Stałe, ID bindów NUI, forward declarations       |
| `sql_haunt.nss`         | Warstwa SQL (Campaign DB `haunted_armory`)       |
| `lib_haunt.nss`         | Rdzeń logiki, budowa NUI, feed panel             |
| `lib_haunt_ev.nss`      | Handler eventów NUI                              |
| `sys_on_load.nss`       | Inicjalizacja tabel + subskrypcja NWNX_Events    |
| `sys_on_enter.nss`      | Reapply efektów na login                         |
| `sys_on_heartbeat.nss`  | Periodyczne save'y klątwowe co 5/10/20 ticków    |
| `haunt_on_death.nss`    | NWNX event — rejestracja zabójstwa na broni      |
| `test_haunt.nss`        | OnUsed na placeable — demo / testowanie          |
| `lib_nui.nss`           | Wspólna biblioteka NUI (kopia z Mailbox)         |
| `lib_nui_utility.nss`   | Pomocnicze funkcje NUI (kopia z Mailbox)         |

## Jak włączyć w istniejącym module

1. **Dodaj wszystkie `.nss` do HAK-a** (lub override folderu) modułu.
2. **Module OnLoad** — wywołaj `sys_on_load` lub dopisz:
   ```nss
   #include "sql_haunt"
   #include "nwnx_events"
   // ...w istniejącym OnLoad:
   HauntCreateTables();
   NWNX_Events_SubscribeEvent("NWNX_ON_CREATURE_DEATH_BEFORE", "haunt_on_death");
   ```
3. **Module OnClientEnter** — wywołaj `sys_on_enter` lub dopisz:
   ```nss
   #include "lib_haunt"
   // ...w istniejącym OnClientEnter:
   // (kod z sys_on_enter.nss)
   ```
4. **Module OnHeartbeat** — wywołaj `sys_on_heartbeat` lub dopisz jego
   zawartość do istniejącego heartbeatu. Bez tego klątwy się nie uruchamiają.
5. **Test Placeable** — stwórz dowolny Placeable, ustaw skrypt OnUsed na
   `test_haunt`. Gracz kliknie go trzymając broń w ręku, by otworzyć panel.
6. **Święcona Woda** — stwórz item (Misc Small) z tagiem `haunt_holy_water`
   (np. w palecie narzędzi) dla gracza jako komponent oczyszczenia.
7. Upewnij się że w `nwnx_config.txt` jest włączone:
   ```
   NWNX_EVENTS_ENABLED=1
   ```

## Co celowo pominięto

- **Nawiedzenie zbroi** — tylko broń śledzi zabójstwa; zbroja byłaby drugą
  warstwą mechaniki wymagającą oddzielnego UI.
- **Multiplayer PvP** — zabójstwa graczy nie są liczone (by uniknąć farmy PvP).
- **Animacje / VFX** — brak dedykowanych efektów wizualnych (wymagałoby HAK-a).
- **Crafting receptury** — nie ma systemu tworzenia Święconej Wody; to zadanie
  dla modułu Alchemii lub Pantheon.
- **Eksport danych** — brak eksportu historii ofiar do zewnętrznych systemów.
