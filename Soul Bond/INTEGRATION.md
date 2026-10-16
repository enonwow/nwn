# Soul Bond — Integracja

## Co to robi

Broń gromadzi zabójstwa przez pięć rang (`Uśpiona → Przebudzona → Skuta Krwią → Spragniona → Wściekła → Wykuta z Duszy`). Każda ranga przyznaje trwałe premie (wzmocnienie, obrażenia zimnem, zastraszanie, regeneracja) przez `TagItemProperty`. Więź należy do **broni**, nie postaci — może zmienić właściciela i nadal nieść mroczny dorobek. Gracze przeglądają postęp przez okno NUI.

## Wymagania

- **NWN:EE** (engine ≥ 8193) — wymaga `TagItemProperty`, `GetItemPropertyTag`, `NuiCreate`, `GetObjectUUID`.
- **NWNX**: Niewymagany.
- **Kampania SQL**: `soulbond` (tworzona przez `sys_on_load.nss`).

## Hooki modułu

| Zdarzenie modułu      | Skrypt              |
|-----------------------|---------------------|
| OnModuleLoad          | `sys_on_load`       |
| OnClientEnter         | `sys_on_enter`      |
| OnCreatureDeath       | `sys_on_death`      |

Jeśli w module już istnieją skrypty dla tych zdarzeń, dodaj wywołanie (`ExecuteScript("sys_on_load", GetModule())` itp.) w odpowiednim miejscu, lub wstaw `#include "lib_sb"` i wywołaj funkcje bezpośrednio.

## Placeable testowy

Ustaw `test_sb` jako skrypt `OnUsed` dowolnego placeable. Gracze klikają obiekt, by otworzyć okno Więzi Duszy.

## Progi rang

| Ranga | Min. zabójstw | Premia                                              |
|-------|--------------|-----------------------------------------------------|
| 1     | 10           | Wzmocnienie +1                                      |
| 2     | 50           | Wzmocnienie +1, obrażenia zimnem +1k4               |
| 3     | 200          | Wzmocnienie +2, obrażenia zimnem +1k4               |
| 4     | 500          | Wzmocnienie +2, obrażenia zimnem +1k6, Zastr. +2    |
| 5     | 1000         | Wzmocnienie +3, obrażenia zimnem +1k6, Zastr. +4, Reg. +1 |

## Zerwanie więzi

Kosztuje 500 zk. Usuwa wszystkie premie, czyści wpis w bazie. Broń wraca do stanu „Uśpionej".

## Co celowo pominięto

- Limit broni per postać (nie ma — system jest weapon-centric).
- Animacje / efekty cząsteczkowe przy rankupie (byłyby miłe, lecz wymagają assets w HAK).
- Obraz broni w oknie NUI (brak ikony per-weapon w vanilla; można rozszerzyć przez `Get2DAString("baseitems","DefaultIcon",nBaseType)`).
- Tryb DM do ręcznego ustawiania zabójstw (można dodać konsolą przez `SqlPrepareQueryCampaign`).
