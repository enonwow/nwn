# Arena Gladiatorów — Integracja

## Opis

System areny gladiatorów z trójligowym systemem walk (Rekrut / Wojownik / Mistrz),
trwałą tabelą wyników (SQL), tytułami za próg zwycięstw i interfejsem NUI.

## Wymagania

- NWN EE 8193.36 lub nowszy (NUI, SqlPrepareQueryCampaign, JsonObject)
- Brak wymagań NWNX

## Podpinanie hooków

| Skrypt               | Zdarzenie modułu       |
|----------------------|------------------------|
| `sys_on_load.nss`    | OnModuleLoad           |
| `sys_on_enter.nss`   | OnClientEnter          |
| `lib_gla_ev.nss`     | NUI Event Script (podawany przez ArenaOpenWindow) |

## Baza danych

Kampania SQLite o nazwie `arena` tworzona automatycznie przy OnModuleLoad.
Tabela `arena_fighters` — jedno pole na gracza, idempotentna migracja.

## Placeable — tablica areny

1. Utwórz placeable z dowolnym wyglądem (np. `plc_pedestal`).
2. Ustaw skrypt OnUsed: `test_gla`.
3. Umieść go w obszarze, gdzie gracze mogą walczyć (otwarta przestrzeń
   o promieniu ~8m, by potwory mogły się swobodnie spawować).

## Skrypty HAK

Dodaj do haka (lub skopiuj do folderu scripts modułu):

```
lib_gla_def.nss
lib_gla.nss
lib_gla_ev.nss
sql_gla.nss
lib_nui.nss
lib_nui_utility.nss
sys_on_load.nss
sys_on_enter.nss
sys_on_enter.nss
test_gla.nss
```

## Flow walki

1. Gracz używa tablicy → otwiera się okno NUI.
2. Zakładka **Tabela Chwały**: top-10 graczy według infamii.
3. Zakładka **Moje Walki**: statystyki, wybór ligi, przycisk „WALCZ!".
4. Po kliknięciu „WALCZ!" system spawnuje 2–4 potwory w pobliżu gracza
   w 3 falach rosnącej trudności.
5. Co 5 s skrypt sprawdza stan walki (SmierćPC / śmierć wszystkich wrogów / timeout 180 s).
6. Wygrana → zapis do SQL, aktualizacja tabeli, opcjonalny efekt wizualny i nowy tytuł.
7. Przegrana → odliczenie kary infamii.

## Resrefy potworów

Moduł korzysta ze standardowych blueprintów NWN:
- Liga 1 (Rekrut):  `nw_goblin001`, `nw_goblina`, `nw_bandit001`, `nw_bandita`, `nw_kobold001`
- Liga 2 (Wojownik): `nw_orc001`, `nw_orca`, `nw_gnoll001`, `nw_gnollarcher`, `nw_bugbear001`
- Liga 3 (Mistrz):   `nw_ogre001`, `nw_ogrehalf001`, `nw_troll001`, `nw_gianthill001`

Jeśli blueprinty nie istnieją w module, stworzenie potwora nie powiedzie się cicho
— system odnotuje 0 wrogów i fala zostanie pominięta.

## Co celowo pominięto

- **Zakłady** — gracze nie mogą zakładać się na wynik walki (rozszerzenie przyszłości).
- **Obserwatorzy (spectators)** — brak NUI dla widzów śledzących walkę w czasie rzeczywistym.
- **Nagrody przedmiotowe** — wygrana przyznaje tylko infamię i tytuł; magistrat modułu
  może rozszerzyć `ArenaHandleWin` o przyznanie konkretnych itemów.
- **Walki PvP** — mechanika opiera się wyłącznie na PvE (PC vs. NPC).
- **Dedykowany obszar areny** — system działa w dowolnym miejscu; nie wymaga
  specjalnie przygotowanego terenu, co upraszcza setup kosztem immersji.
