# Daily rewards

Серверная часть ежедневных наград и промокодов плюс простое окно для проверки. Профиль игрока (Coins, LastClaimTime, Streak, UsedCodes) лежит в DataStore, награда выдаётся раз в 24 часа, после 48 часов простоя стрик сбрасывается на первый день. Если плейс не опубликован и DataStore недоступен, DataManager переключается на хранение в памяти, так что систему можно гонять в Studio без публикации.

## Установка

Готовые файлы лежат в [Releases](https://github.com/N0ctisL0ve/daily-rewards/releases/latest): пять `.rbxm` и архив с исходниками. Скачанные `.rbxm` перетаскиваются в Explorer по адресам:

```
Config.rbxm, Remotes.rbxm             -> ReplicatedStorage
DataManager.rbxm, RewardsService.rbxm -> ServerScriptService
RewardsUI.rbxm                        -> StarterPlayer.StarterPlayerScripts
```

Через Rojo: `rojo serve` в корне репозитория и подключение одноимённого плагина в Studio. Папку Remotes можно не создавать вручную, RewardsService сделает её сам.

## Раскладка в Studio

```
ReplicatedStorage
  Config            ModuleScript
  Remotes
    ClaimDaily      RemoteFunction
    RedeemCode      RemoteFunction
    DataUpdated     RemoteEvent
ServerScriptService
  DataManager       ModuleScript
  RewardsService    Script
StarterPlayer
  StarterPlayerScripts
    RewardsUI       LocalScript
```

Тестовые коды в Config: FREE100 (+100) и WEEK7 (+700), OLDCODE выключен для проверки отказа.

![Окно наград и промокодов](docs/ui.png)
